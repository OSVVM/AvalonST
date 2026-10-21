
library ieee ;
  use ieee.std_logic_1164.all ;
  use ieee.numeric_std.all ;
  use ieee.numeric_std_unsigned.all ;
  use ieee.math_real.all ;

  use std.textio.all ;

library OSVVM ;
  context OSVVM.OsvvmContext ;

use osvvm.ScoreboardPkg_slv.all;

library osvvm_common;
context osvvm_common.OsvvmCommonContext; -- for MIT StreamRecType


package AvalonStreamTbPkg is
  ------------------------------------------------------------
  function UpdateOptions (
  ------------------------------------------------------------
    Param     : std_logic_vector ;
    ParamChannel   : std_logic_vector ;
    ParamEmpty : std_logic_vector ;
    Count     : integer
  ) return std_logic_vector ;

  function log2(x : positive) return natural;

  ------------------------------------------------------------
  procedure DoAvalonStreamValidHandshake (
  ------------------------------------------------------------
    signal Clk : in std_logic;
    signal Valid : out std_logic;
    signal Ready : in std_logic;
    constant tpd_Clk_Valid : in time;
    constant AlertLogID : in AlertLogIDType := ALERTLOG_DEFAULT_ID;
    constant TimeOutMessage : in string := "";
    constant TimeOutPeriod : in time := -1 sec
  );

  ------------------------------------------------------------
  procedure DoAvalonStreamReadyHandshake (
  ------------------------------------------------------------
    signal Clk : in std_logic;
    signal Valid : in std_logic;
    signal Ready : inout std_logic;
    constant WordRequestCount : in integer;
    signal WordReceiveCount : inout integer;
    constant tpd_Clk_Ready : in time;
    constant AlertLogID : in AlertLogIDType := ALERTLOG_DEFAULT_ID;
    constant TimeOutMessage : in string := "";
    constant TimeOutPeriod : in time := -1 sec
  );

  -------------------------------------------------------------
  procedure DoPrepareTransmitData (
  -------------------------------------------------------------
    signal Data : out std_logic_vector;
    signal Channel : out std_logic_vector;
    signal Empty : out std_logic_vector;
    signal TransmitFifo : inout ScoreboardIdType;
    variable EmptyBeats : inout integer;
    constant BurstFifoMode : in StreamFifoBurstModeType;
    constant BeatsPerCycle : in integer;
    constant SymbolOrder : in boolean;
    constant WordWidth : in integer;
    constant SymbolWidth : in integer
  );

  -------------------------------------------------------------
  procedure WaitForReady (
  -------------------------------------------------------------
    signal Ready : in std_logic;
    constant TimeOut : in time := 0 sec;
    constant AlertLogID : in AlertLogIDType;
    constant Msg : in string
  );

  -------------------------------------------------------------
  procedure ReverseSymbolOrder (
  -------------------------------------------------------------
    variable Data : inout std_logic_vector;
    constant SymbolWidth : in integer;
    constant TotalWidth : in integer
  );

  -------------------------------------------------------------
  procedure WaitForValid (
  -------------------------------------------------------------
    signal Valid : in std_logic;
    constant TimeOut : in time;
    constant AlertLogID : in AlertLogIDType;
    constant Msg : in string
  );

end AvalonStreamTbPkg ;

package body AvalonStreamTbPkg is

  ------------------------------------------------------------
  function UpdateOptions (
  ------------------------------------------------------------
    Param     : std_logic_vector ;
    ParamChannel   : std_logic_vector ;
    ParamEmpty : std_logic_vector ;
    Count     : integer
  ) return std_logic_vector is
    constant PARAM_LEN : integer := Param'length ;
    constant Channel_LEN    : integer := ParamChannel'length ;
    constant Empty_LEN  : integer := ParamEmpty'length ;
    variable ResultParam : std_logic_vector(PARAM_LEN -1 downto 0) ;

    constant Channel_RIGHT    : integer := Empty_LEN;
    constant Empty_RIGHT  : integer := 0 ;
  begin
    ResultParam := Param ;

    if Channel_LEN > 0 and ResultParam(Channel_RIGHT) = '-' then
      ResultParam(PARAM_LEN-1 downto Channel_RIGHT) := ParamChannel ;
    end if ;

    if Empty_LEN > 0 and ResultParam(Empty_RIGHT) = '-' then
      ResultParam(Channel_RIGHT-1 downto Empty_RIGHT) := ParamEmpty ;
    end if ;

    return ResultParam ;
  end function UpdateOptions ;

  -------------------------------------------------------------
  procedure DoAvalonStreamValidHandshake (
  -------------------------------------------------------------
    signal Clk : in std_logic;
    signal Valid : out std_logic;
    signal Ready : in std_logic;
    constant tpd_Clk_Valid : in time;
    constant AlertLogID : in AlertLogIDType := ALERTLOG_DEFAULT_ID;
    constant TimeOutMessage : in string := "";
    constant TimeOutPeriod : in time := -1 sec
  ) is
  begin
    if (Ready /= '1') then -- source has to assert valid before ready
      Valid <= '1' after tpd_Clk_Valid;
      WaitForReady(Ready, TimeOutPeriod, AlertLogID, TimeOutMessage);
    else
      Valid <= '1' after tpd_Clk_Valid;
    end if;
    wait on clk until Clk = '1';
  end procedure;

  ------------------------------------------------------------
  procedure DoAvalonStreamReadyHandshake (
  ------------------------------------------------------------
    signal Clk : in std_logic;
    signal Valid : in std_logic;
    signal Ready : inout std_logic;
    constant WordRequestCount : in integer;
    signal WordReceiveCount : inout integer;
    constant tpd_Clk_Ready : in time;
    constant AlertLogID : in AlertLogIDType := ALERTLOG_DEFAULT_ID;
    constant TimeOutMessage : in string := "";
    constant TimeOutPeriod : in time := -1 sec
  ) is
  begin
    if (Valid /= '1') then
      WaitForValid(Valid, TimeOutPeriod, AlertLogID, TimeOutMessage);
    end if;
    Ready <= '1' after tpd_Clk_Ready;
    wait on clk until clk = '1';
  end procedure DoAvalonStreamReadyHandshake;

  -------------------------------------------------------------
  procedure WaitForReady (
  -------------------------------------------------------------
    signal Ready : in std_logic;
    constant TimeOut : in time := 0 sec;
    constant AlertLogID : in AlertLogIDType;
    constant Msg : in string
  ) is
    variable v_start_time : time := now;
  begin
    if TimeOut > 0 sec then
      wait until Ready = '1' for TimeOut ;
      if now - v_start_time >= TimeOut then
        Alert(AlertLogID, Msg & ".  Ready: " & to_string(Ready) & "  Expected: 1", FAILURE);
      end if;
    else
      wait until Ready = '1';
    end if;
  end procedure;

  -------------------------------------------------------------
  procedure WaitForValid (
  -------------------------------------------------------------
    signal Valid : in std_logic;
    constant TimeOut : in time;
    constant AlertLogID : in AlertLogIDType;
    constant Msg : in string
  ) is
    variable v_start_time : time := now;
  begin
    if TimeOut > 0 sec then
      loop
        exit when Valid = '1';
        exit when now - v_start_time >= TimeOut;
        wait for 1 ns;
      end loop;

      if Valid /= '1' then
        Alert(AlertLogID, Msg & ".  Valid: " & to_string(Valid) & "  Expected: 1", FAILURE);
      end if;
    else
      wait until Valid = '1';
    end if;
  end procedure;

  -------------------------------------------------------------
  procedure ReverseSymbolOrder (
  -------------------------------------------------------------
    variable Data : inout std_logic_vector;
    constant SymbolWidth : in integer;
    constant TotalWidth : in integer
  ) is
    variable SymbolCount : integer;
    variable vDataReversed : std_logic_vector(Data'range) := (others => 'X');
  begin
    SymbolCount := TotalWidth / SymbolWidth;
    for i in 0 to SymbolCount - 1 loop
      vDataReversed((SymbolCount - i) * SymbolWidth - 1 downto (SymbolCount - i - 1) * SymbolWidth) :=
                                                                                                      Data((i + 1) * SymbolWidth - 1 downto i * SymbolWidth);
    end loop;
    Data := vDataReversed;
  end procedure;

  -------------------------------------------------------------
  procedure DoPrepareTransmitData (
  -------------------------------------------------------------
    signal Data : out std_logic_vector;
    signal Channel : out std_logic_vector;
    signal Empty : out std_logic_vector;
    signal TransmitFifo : inout ScoreboardIdType;
    variable EmptyBeats : inout integer;
    constant BurstFifoMode : in StreamFifoBurstModeType;
    constant BeatsPerCycle : in integer;
    constant SymbolOrder : in boolean;
    constant WordWidth : in integer;
    constant SymbolWidth : in integer
  ) is
    variable vData : std_logic_vector(WordWidth - 1 downto 0) := (others => 'U');
    variable vEmptyBeats : integer := 0;
    variable vChannel : std_logic_vector(Channel'range);
    variable vEmpty : std_logic_vector(Empty'range);
  begin
    (vData, vChannel, vEmpty) := Pop(TransmitFifo);
    if (SymbolOrder = true and BurstFifoMode = STREAM_BURST_BYTE_MODE) then
      ReverseSymbolOrder(vData, SymbolWidth, WordWidth);
    end if;
    Data <= vData;
    Channel <= vChannel;
    Empty <= vEmpty;
    EmptyBeats := vEmptyBeats;
  end procedure;

  -------------------------------------------------------------
  function log2(x : positive) return natural is
  -------------------------------------------------------------
    variable result : natural := 0;
    variable value : positive := x;
  begin
    while value > 1 loop
      value := value / 2;
      result := result + 1;
    end loop;
    return result;
  end function;

end AvalonStreamTbPkg ;
