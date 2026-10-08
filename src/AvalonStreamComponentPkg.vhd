
library ieee;
use ieee.std_logic_1164.all;
use ieee.math_real.all;
library osvvm;
context osvvm.OsvvmContext;
use osvvm.ScoreboardPkg_slv.all;

library osvvm_common;
context osvvm_common.OsvvmCommonContext; -- for MIT StreamRecType

package AvalonStreamComponentPkg is
  function log2(x : positive) return natural;


  component AvalonStreamTransmitter is
    generic (
      INIT_CHANNEL                  : std_logic_vector := "";
      INIT_EMPTY                    : std_logic_vector := "";

      MODEL_ID_NAME                 : string := "";
      AVALON_STREAM_DATA_WIDTH      : integer range 1 to 8192 := 32;
      AVALON_STREAM_SYMBOL_WIDTH    : integer range 1 to AVALON_STREAM_DATA_WIDTH := 8;
      AVALON_STREAM_CHANNELS        : integer range 1 to 256 := 1;
      DEFAULT_DELAY                 : time := 1 ns;
      tpd_Clk_Data                  : time := DEFAULT_DELAY;
      tpd_Clk_Valid                 : time := DEFAULT_DELAY;
      tpd_Clk_StartOfPacket         : time := DEFAULT_DELAY;
      tpd_Clk_EndOfPacket           : time := DEFAULT_DELAY;
      tpd_Clk_Empty                 : time := DEFAULT_DELAY;
      --DEFAULT_CHANNELS            : integer := 1
      tperiod_Clk                   : time := 10 ns --todo: could be deleted
    );
    port (
      Clk            : in std_logic;
      Reset          : in std_logic;
      -- DUT signals
      Valid          : out std_logic := '0';
      Data           : out std_logic_vector(AVALON_STREAM_DATA_WIDTH - 1 downto 0);
      StartOfPacket  : out std_logic := '0';
      EndOfPacket    : out std_logic := '0';
      Empty          : out std_logic_vector(integer(ceil(log2(real(AVALON_STREAM_DATA_WIDTH) / real(AVALON_STREAM_SYMBOL_WIDTH)))) - 1 downto 0) := (others => '0');
      Ready          : in std_logic;
      Channel        : out std_logic_vector(7 downto 0) := (others => '0');

      -- OSVVM Transaction record
      TransRec       : inout StreamRecType
    );
  end component AvalonStreamTransmitter;

  component AvalonStreamReceiver is
    generic (
      INIT_CHANNEL                  : std_logic_vector := "";
      INIT_EMPTY                    : std_logic_vector := "";
      INIT_LAST                     : natural := 0;
      MODEL_ID_NAME                 : string := "";
      AVALON_STREAM_DATA_WIDTH      : integer range 1 to 8192 := 32;
      AVALON_STREAM_SYMBOL_WIDTH    : integer range 1 to AVALON_STREAM_DATA_WIDTH := 8;
      AVALON_STREAM_ERROR           : integer range 1 to 256 := 1;
      tperiod_Clk                   : time := 10 ns;
      DEFAULT_DELAY                 : time := 1 ns;
      tpd_Clk_Ready                 : time := DEFAULT_DELAY
    );
    port (
      Clk            : in std_logic;
      Reset          : in std_logic;
      -- DUT signals
      Valid          : in std_logic := '0';
      Data           : in std_logic_vector(AVALON_STREAM_DATA_WIDTH - 1 downto 0);
      Ready          : out std_logic;

      StartOfPacket  : in std_logic := '0';
      EndOfPacket    : in std_logic := '0';
      Empty          : in std_logic_vector(integer(ceil(log2(real(AVALON_STREAM_DATA_WIDTH) / real(AVALON_STREAM_SYMBOL_WIDTH)))) - 1 downto 0);
      Channel        : in std_logic_vector(7 downto 0) := (others => '0');
      -- testbench record
      TransRec       : inout StreamRecType
    );
  end component AvalonStreamReceiver;



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

  procedure DoPrepareTransmitData (
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

  procedure WaitForReady (
    signal Ready : in std_logic;
    constant TimeOut : in time := 0 sec;
    constant AlertLogID : in AlertLogIDType;
    constant Msg : in string
  );

  procedure ReverseSymbolOrder (
    variable Data : inout std_logic_vector;
    constant SymbolWidth : in integer;
    constant TotalWidth : in integer
  );

  procedure WaitForValid (
    signal Valid : in std_logic;
    constant TimeOut : in time;
    constant AlertLogID : in AlertLogIDType;
    constant Msg : in string
  );

end package AvalonStreamComponentPkg;

-- /////////////////////////////////////////////////////////////////////////////////////////
-- /////////////////////////////////////////////////////////////////////////////////////////

package body AvalonStreamComponentPkg is

  procedure DoAvalonStreamValidHandshake (
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
    signal Ready : in std_logic;
    constant TimeOut : in time := 0 sec;
    constant AlertLogID : in AlertLogIDType;
    constant Msg : in string
  ) is
    variable v_start_time : time := now;
  begin
    if TimeOut > 0 sec then
      loop
        exit when Ready = '1';
        exit when now - v_start_time >= TimeOut;
        wait for 1 ns; -- kleine Wartezeit, um Sim weiterlaufen zu lassen
      end loop;

      if Ready /= '1' then
        Alert(AlertLogID, Msg & ".  Ready: " & to_string(Ready) & "  Expected: 1", FAILURE);
      end if;
    else
      wait until Ready = '1';
    end if;
  end procedure;

  procedure WaitForValid (
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
  procedure DoPrepareTransmitData (
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

  function log2(x : positive) return natural is
    variable result : natural := 0;
    variable value : positive := x;
  begin
    while value > 1 loop
      value := value / 2;
      result := result + 1;
    end loop;
    return result;
  end function;
end package body AvalonStreamComponentPkg;