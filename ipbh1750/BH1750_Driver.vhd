
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity BH1750_Driver is
Port (
clk : in std_logic;
reset_n : in std_logic;
sda : inout std_logic;
scl : inout std_logic;
lux_data : out std_logic_vector(15 downto 0);
data_valid : out std_logic
);
end BH1750_Driver;

architecture Behavioral of BH1750_Driver is

-- Clock divider for I2C
constant CLK_FREQ : integer := 100_000_000;
constant I2C_FREQ : integer := 100_000;
constant DIVIDER : integer := CLK_FREQ / I2C_FREQ;

-- BH1750 I2C addresses
constant BH1750_ADDR_W : std_logic_vector(7 downto 0) := x"46";
constant BH1750_ADDR_R : std_logic_vector(7 downto 0) := x"47";
constant CMD_H_RES_MODE: std_logic_vector(7 downto 0) := x"10";

-- FSM states
type state_type is (
POWER_UP,
IDLE,
START_1,
SEND_ADDR_W,
ACK_1,
SEND_CMD,
ACK_2,
STOP_1,
WAIT_MEASURE,
START_2,
SEND_ADDR_R,
ACK_3,
READ_MSB,
M_ACK_1,
READ_LSB,
M_NACK,
STOP_2
);
signal state : state_type := POWER_UP;

signal clk_cnt : integer range 0 to DIVIDER := 0;
signal i2c_tick : std_logic := '0';

-- Delay counters
signal wait_timer : integer := 0;
constant WAIT_180MS : integer := 18_000_000;
constant WAIT_10MS : integer := 1_000_000;

-- Data buffers
signal bit_cnt : integer range 0 to 7 := 0;
signal shift_reg : std_logic_vector(7 downto 0) := (others => '0');
signal data_msb : std_logic_vector(7 downto 0) := (others => '0');
signal data_lsb : std_logic_vector(7 downto 0) := (others => '0');

-- I2C signals
signal sda_out : std_logic := '1';
signal sda_in_reg : std_logic := '1';
signal scl_out : std_logic := '1';

begin

-- Tri-state buffers
sda <= '0' when sda_out = '0' else 'Z';
scl <= '0' when scl_out = '0' else 'Z';

sda_in_reg <= sda;

-- I2C clock tick generator
process(clk)
begin
if rising_edge(clk) then
if reset_n = '0' then
clk_cnt <= 0;
i2c_tick <= '0';
else
if clk_cnt = (DIVIDER/4) - 1 then
clk_cnt <= 0;
i2c_tick <= '1';
else
clk_cnt <= clk_cnt + 1;
i2c_tick <= '0';
end if;
end if;
end if;
end process;

-- Main FSM
process(clk)
variable sub_state : integer range 0 to 3 := 0;
begin
if rising_edge(clk) then
if reset_n = '0' then
state <= POWER_UP;
wait_timer <= 0;
scl_out <= '1';
sda_out <= '1';
sub_state := 0;
lux_data <= (others => '0');
data_valid <= '0';
else

if state = POWER_UP or state = WAIT_MEASURE then
wait_timer <= wait_timer + 1;
else
wait_timer <= 0;
end if;

if i2c_tick = '1' then
case state is

when POWER_UP =>
if wait_timer > WAIT_10MS then
state <= IDLE;
end if;

when IDLE =>
sda_out <= '1';
scl_out <= '1';
state <= START_1;
sub_state := 0;

when START_1 =>
case sub_state is
when 0 => sda_out <= '1'; scl_out <= '1';
when 1 => sda_out <= '0';
when 2 => scl_out <= '0';
when 3 =>
state <= SEND_ADDR_W;
bit_cnt <= 7;
shift_reg <= BH1750_ADDR_W;
sub_state := 0;
when others => null;
end case;
if sub_state < 3 then sub_state := sub_state + 1; end if;

when SEND_ADDR_W | SEND_CMD | SEND_ADDR_R =>
case sub_state is
when 0 => sda_out <= shift_reg(bit_cnt); scl_out <= '0';
when 1 => scl_out <= '1';
when 2 => scl_out <= '1';
when 3 =>
scl_out <= '0';
if bit_cnt = 0 then
if state = SEND_ADDR_W then state <= ACK_1;
elsif state = SEND_CMD then state <= ACK_2;
else state <= ACK_3;
end if;
else
bit_cnt <= bit_cnt - 1;
end if;
end case;
if sub_state < 3 then sub_state := sub_state + 1; else sub_state := 0; end if;

when ACK_1 | ACK_2 | ACK_3 =>
case sub_state is
when 0 => sda_out <= '1'; scl_out <= '0';
when 1 => scl_out <= '1';
when 2 => scl_out <= '1';
when 3 =>
scl_out <= '0';
if state = ACK_1 then
state <= SEND_CMD;
shift_reg <= CMD_H_RES_MODE;
bit_cnt <= 7;
elsif state = ACK_2 then
state <= STOP_1;
else
state <= READ_MSB;
bit_cnt <= 7;
end if;
end case;
if sub_state < 3 then sub_state := sub_state + 1; else sub_state := 0; end if;

when STOP_1 =>
case sub_state is
when 0 => sda_out <= '0'; scl_out <= '0';
when 1 => scl_out <= '1';
when 2 => sda_out <= '1';
when 3 => state <= WAIT_MEASURE;
end case;
if sub_state < 3 then sub_state := sub_state + 1; else sub_state := 0; end if;

when WAIT_MEASURE =>
if wait_timer > WAIT_180MS then
state <= START_2;
sub_state := 0;
end if;

when START_2 =>
case sub_state is
when 0 => sda_out <= '1'; scl_out <= '1';
when 1 => sda_out <= '0';
when 2 => scl_out <= '0';
when 3 =>
state <= SEND_ADDR_R;
bit_cnt <= 7;
shift_reg <= BH1750_ADDR_R;
end case;
if sub_state < 3 then sub_state := sub_state + 1; else sub_state := 0; end if;

when READ_MSB | READ_LSB =>
case sub_state is
when 0 => sda_out <= '1'; scl_out <= '0';
when 1 => scl_out <= '1';
when 2 =>
if state = READ_MSB then
data_msb(bit_cnt) <= sda_in_reg;
else
data_lsb(bit_cnt) <= sda_in_reg;
end if;
when 3 =>
scl_out <= '0';
if bit_cnt = 0 then
if state = READ_MSB then state <= M_ACK_1;
else state <= M_NACK;
end if;
else
bit_cnt <= bit_cnt - 1;
end if;
end case;
if sub_state < 3 then sub_state := sub_state + 1; else sub_state := 0; end if;

when M_ACK_1 =>
case sub_state is
when 0 => sda_out <= '0'; scl_out <= '0';
when 1 => scl_out <= '1';
when 2 => scl_out <= '1';
when 3 =>
scl_out <= '0';
state <= READ_LSB;
bit_cnt <= 7;
end case;
if sub_state < 3 then sub_state := sub_state + 1; else sub_state := 0; end if;

when M_NACK =>
case sub_state is
when 0 => sda_out <= '1'; scl_out <= '0';
when 1 => scl_out <= '1';
when 2 => scl_out <= '1';
when 3 =>
scl_out <= '0';
state <= STOP_2;
end case;
if sub_state < 3 then sub_state := sub_state + 1; else sub_state := 0; end if;

when STOP_2 =>
case sub_state is
when 0 => sda_out <= '0'; scl_out <= '0';
when 1 => scl_out <= '1';
when 2 =>
sda_out <= '1';
lux_data <= data_msb & data_lsb;
data_valid <= '1';
when 3 => state <= WAIT_MEASURE;
end case;
if sub_state < 3 then sub_state := sub_state + 1; else sub_state := 0; end if;

when others =>
state <= IDLE;

end case;
end if;
end if;
end if;
end process;

end Behavioral;


