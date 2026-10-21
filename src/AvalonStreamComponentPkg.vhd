
library ieee;
use ieee.std_logic_1164.all;
use ieee.math_real.all;

library osvvm;
context osvvm.OsvvmContext;

library osvvm_common;
context osvvm_common.OsvvmCommonContext; -- for MIT StreamRecType

package AvalonStreamComponentPkg is
  component AvalonStreamTransmitter is
    generic (
      INIT_CHANNEL                  : std_logic_vector := "";
      INIT_EMPTY                    : std_logic_vector := "";

      MODEL_ID_NAME                 : string := "";
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
      Clk            : in  std_logic;
      Reset          : in  std_logic;
      -- DUT signals
      Valid          : out std_logic := '0';
      Data           : out std_logic_vector ;
      StartOfPacket  : out std_logic := '0';
      EndOfPacket    : out std_logic := '0';
      Empty          : out std_logic_vector;
      Ready          : in  std_logic;
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
      AVALON_STREAM_ERROR           : integer range 1 to 256 := 1;
      tperiod_Clk                   : time := 10 ns;
      DEFAULT_DELAY                 : time := 1 ns;
      tpd_Clk_Ready                 : time := DEFAULT_DELAY
    );
    port (
      Clk            : in  std_logic;
      Reset          : in  std_logic;
      -- DUT signals
      Valid          : in  std_logic := '0';
      Data           : in  std_logic_vector;
      Ready          : out std_logic;

      StartOfPacket  : in  std_logic := '0';
      EndOfPacket    : in  std_logic := '0';
      Empty          : in  std_logic_vector;
      Channel        : in  std_logic_vector(7 downto 0) := (others => '0');
      -- testbench record
      TransRec       : inout StreamRecType
    );
  end component AvalonStreamReceiver;

end package AvalonStreamComponentPkg;

