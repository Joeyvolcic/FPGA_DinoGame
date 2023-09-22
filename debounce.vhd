library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity ButtonDebounce is
    Port (
        clk     : in  STD_LOGIC;
        reset   : in  STD_LOGIC;
        button  : in  STD_LOGIC;
        debounced_button : out STD_LOGIC
    );
end ButtonDebounce;

architecture Behavioral of ButtonDebounce is
    constant debounce_time_ms : integer := 20;
    constant clock_frequency_hz : integer := 50000000;
    constant debounce_counter_max : integer := (debounce_time_ms * clock_frequency_hz) / 1000;

    type State_Type is (IDLE, COUNTING);
    signal State : State_Type;
    signal Counter : integer := 0;
    signal DebouncedButtonInternal : STD_LOGIC := '0';

begin
    process(clk, reset)
    begin
        if reset = '1' then
            State <= IDLE;
            Counter <= 0;
            DebouncedButtonInternal <= '0';
        elsif rising_edge(clk) then
            case State is
                when IDLE =>
                    if button /= DebouncedButtonInternal then
                        Counter <= 0;
                        State <= COUNTING;
                    end if;
                when COUNTING =>
                    if button /= DebouncedButtonInternal then
                        Counter <= 0;
                    else
                        if Counter < debounce_counter_max then
                            Counter <= Counter + 1;
                        else
                            DebouncedButtonInternal <= button;
                            State <= IDLE;
                        end if;
                    end if;
            end case;
        end if;
    end process;

    debounced_button <= DebouncedButtonInternal;
end Behavioral;
