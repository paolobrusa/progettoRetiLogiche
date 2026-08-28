library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use IEEE.std_logic_unsigned.all;
entity project_reti_logiche is
    port (
        i_clk : in std_logic;
        i_rst : in std_logic;
        i_start : in std_logic;
        i_add : in std_logic_vector(15 downto 0);
        o_done : out std_logic;
        o_mem_addr : out std_logic_vector(15 downto 0);
        i_mem_data : in std_logic_vector(7 downto 0);
        o_mem_data : out std_logic_vector(7 downto 0);
        o_mem_we : out std_logic;
        o_mem_en : out std_logic
    );
end project_reti_logiche;

architecture Behavioral of project_reti_logiche is

    type state is (s0, s1, s1wait, s2, s3, s4, s5, s6, s7f3, s7f5, s8, s9, s9wait, s9read, s10);
    signal s: state;
    signal k1, k2: unsigned(7 downto 0);
    signal k: integer range 0 to 65535;
    signal f: std_logic;
    signal sum: signed (19 downto 0);
    signal last: integer range 0 to 7;
    type coeff_3 is array(0 to 6) of signed(7 downto 0);
    signal coeff3: coeff_3;
    type coeff_5 is array(0 to 6) of signed(7 downto 0);
    signal coeff5: coeff_5;
    type data is array(0 to 7) of signed(7 downto 0);
    signal W: data;

    signal count3: integer range 0 to 6;
    signal count5: integer range 0 to 6;
    signal kcount: integer range 0 to 65535;
    signal count: integer range 0 to 7;

begin
process(i_clk, i_rst)
begin
if i_rst = '1' then
    o_mem_en <= '0';
    o_mem_we <= '0'; 
    o_done <= '0';
    o_mem_addr <= (others=>'0');
    o_mem_data <= (others=>'0');
    s <= s0;
    
elsif i_clk'event and i_clk = '1' then
    if s = s0 then
        if i_start = '1' then
            o_mem_en <= '1';
            o_mem_addr <= i_add;
            o_mem_we <= '0';
            o_done <= '0';
            count3 <= 0;
            count5 <= 0;
            kcount <= 0;
            count <= 0;
            sum <= (others=>'0');
            k <= 0;
            k1 <= (others=>'0');
            k2 <= (others=>'0');
            f <= '0';
            coeff3 <= (others => (others=>'0'));
            coeff5 <= (others => (others=>'0'));
            W <= (others => (others=>'0'));
            last <= 0;
            s <= s1wait;
        else 
            s <= s0;
        end if;
        
    elsif s = s1wait then
        o_mem_en <= '1';
        o_mem_addr <= i_add + 1;
        o_mem_we <= '0';
        o_done <= '0';
        s <= s1;
        
    elsif s = s1 then
        k1 <= unsigned(i_mem_data);
        o_mem_en <= '1';
        o_mem_addr <= i_add + 2;
        o_mem_we <= '0';
        o_done <= '0';
        s <= s2;
        
    elsif s = s2 then
        k2 <= unsigned(i_mem_data);
        o_mem_en <= '1';
        o_mem_addr <= i_add + 3;
        o_mem_we <= '0';
        o_done <= '0';
        s <= s3;
    
    elsif s = s3 then
        f <= i_mem_data(0);
        k <= TO_INTEGER(k1 & k2);
        o_mem_en <= '1';
        o_mem_addr <= i_add + 4;
        o_mem_we <= '0';
        o_done <= '0';
        count3 <= 0;
        s <= s4;
        
    elsif s = s4 then
        coeff3(count3) <= signed(i_mem_data);
        o_mem_en <= '1';
        o_mem_addr <= i_add + 5 + count3;
        o_mem_we <= '0';
        o_done <= '0';
        if count3 = 6 then
            count5 <= 0;
            s <= s5;
        else
            count3 <= count3 + 1;
            s <= s4;
        end if;
        
    elsif s = s5 then -- si puo accorporare in un unico stato probabilmente
        coeff5(count5) <= signed(i_mem_data);
        o_mem_en <= '1';
        o_mem_addr <= i_add + 12 + count5;
        o_mem_we <= '0';
        o_done <= '0';
        if count5 = 6 then
            kcount <= 0;
            s <= s6;
        else
            count5 <= count5 + 1;
            s <= s5;
        end if;
    
    elsif s = s6 then
        W(kcount) <= signed(i_mem_data);
        o_mem_en <= '1';
        o_mem_addr <= i_add + 19 + kcount;
        o_mem_we <= '0';
        o_done <= '0';
        if kcount = 7 then
            count <= 0;
            if f = '0' then
                s <= s7f3;
            else
                s <= s7f5;
            end if;
        else
            kcount <= kcount + 1;
            s <= s6;
        end if;
    
    elsif s = s7f3 then --filtro 3
        o_mem_en <= '1';
        o_mem_we <= '0';
        if count = 0 then
            if kcount <= 10 then
                sum <= resize(coeff3(3)*W(count),      sum'length)
                    + resize(coeff3(4)*W(count+1),    sum'length)
                    + resize(coeff3(5)*W(count+2),    sum'length);
            elsif kcount >= k and last = 1 then
                sum <= resize(coeff3(1)*W(6),    sum'length)
                    + resize(coeff3(2)*W(7),    sum'length)
                    + resize(coeff3(3)*W(count),      sum'length)
                    + resize(coeff3(4)*W(count+1),    sum'length);
            elsif kcount > k and last = 0 then
                sum <= resize(coeff3(1)*W(6),    sum'length)
                    + resize(coeff3(2)*W(7),    sum'length)
                    + resize(coeff3(3)*W(count),      sum'length);
            else
                sum <= resize(coeff3(1)*W(6),    sum'length)
                    + resize(coeff3(2)*W(7),    sum'length)
                    + resize(coeff3(3)*W(count),      sum'length)
                    + resize(coeff3(4)*W(count+1),    sum'length)
                    + resize(coeff3(5)*W(count+2),    sum'length);
            end if;
            if kcount > 10 then
                W(5) <= signed(i_mem_data);
            end if;
            count <= count + 1;
        
        elsif count = 1 then
            if kcount <= 10 then
                sum <= resize(coeff3(2)*W(count-1),    sum'length)
                    + resize(coeff3(3)*W(count),      sum'length)
                    + resize(coeff3(4)*W(count+1),    sum'length)
                    + resize(coeff3(5)*W(count+2),    sum'length);
            elsif kcount >= k and last = 2 then
                sum <= resize(coeff3(1)*W(7),    sum'length)
                    + resize(coeff3(2)*W(count-1),    sum'length)
                    + resize(coeff3(3)*W(count),      sum'length)
                    + resize(coeff3(4)*W(count+1),    sum'length);
            elsif kcount > k and last = 1 then
                sum <= resize(coeff3(1)*W(7),    sum'length)
                    + resize(coeff3(2)*W(count-1),    sum'length)
                    + resize(coeff3(3)*W(count),      sum'length);
            else
                sum <= resize(coeff3(1)*W(7),    sum'length)
                    + resize(coeff3(2)*W(count-1),    sum'length)
                    + resize(coeff3(3)*W(count),      sum'length)
                    + resize(coeff3(4)*W(count+1),    sum'length)
                    + resize(coeff3(5)*W(count+2),    sum'length);
            end if;
            if kcount > 10 then
                W(6) <= signed(i_mem_data);
            end if;
            count <= count + 1; 
           
        elsif count = 2 then
            if kcount >= k and last = 3 then
                sum <= resize(coeff3(1)*W(count-2),    sum'length)
                 + resize(coeff3(2)*W(count-1),    sum'length)
                 + resize(coeff3(3)*W(count),      sum'length)
                 + resize(coeff3(4)*W(count+1),    sum'length);
            elsif kcount > k and last = 2 then
                sum <= resize(coeff3(1)*W(count-2),    sum'length)
                 + resize(coeff3(2)*W(count-1),    sum'length)
                 + resize(coeff3(3)*W(count),      sum'length);
            else
                sum <= resize(coeff3(1)*W(count-2),    sum'length)
                 + resize(coeff3(2)*W(count-1),    sum'length)
                 + resize(coeff3(3)*W(count),      sum'length)
                 + resize(coeff3(4)*W(count+1),    sum'length)
                 + resize(coeff3(5)*W(count+2),    sum'length);
            end if;
            if kcount > 10 then
                W(7) <= signed(i_mem_data);
            end if;
            count <= count + 1;
            
        elsif count = 3 then
            if kcount >= k and last = 4 then
                sum <= resize(coeff3(1)*W(count-2),    sum'length)
                 + resize(coeff3(2)*W(count-1),    sum'length)
                 + resize(coeff3(3)*W(count),      sum'length)
                 + resize(coeff3(4)*W(count+1),    sum'length);
            elsif kcount > k and last = 3 then
                sum <= resize(coeff3(1)*W(count-2),    sum'length)
                 + resize(coeff3(2)*W(count-1),    sum'length)
                 + resize(coeff3(3)*W(count),      sum'length);
            else
                sum <= resize(coeff3(1)*W(count-2),    sum'length)
                 + resize(coeff3(2)*W(count-1),    sum'length)
                 + resize(coeff3(3)*W(count),      sum'length)
                 + resize(coeff3(4)*W(count+1),    sum'length)
                 + resize(coeff3(5)*W(count+2),    sum'length);
            end if;
            W(count-3) <= signed(i_mem_data);
            count <= count + 1;
            
        elsif count = 4 then
            if kcount >= k and last = 5 then
                sum <= resize(coeff3(1)*W(count-2),    sum'length)
                 + resize(coeff3(2)*W(count-1),    sum'length)
                 + resize(coeff3(3)*W(count),      sum'length)
                 + resize(coeff3(4)*W(count+1),    sum'length);
            elsif kcount > k and last = 4 then
                sum <= resize(coeff3(1)*W(count-2),    sum'length)
                 + resize(coeff3(2)*W(count-1),    sum'length)
                 + resize(coeff3(3)*W(count),      sum'length);
            else
                sum <= resize(coeff3(1)*W(count-2),    sum'length)
                 + resize(coeff3(2)*W(count-1),    sum'length)
                 + resize(coeff3(3)*W(count),      sum'length)
                 + resize(coeff3(4)*W(count+1),    sum'length)
                 + resize(coeff3(5)*W(count+2),    sum'length);
            end if;
            W(count-3) <= signed(i_mem_data);
            count <= count + 1;
            
        elsif count = 5 then
            if kcount >= k and last = 6 then
                sum <= resize(coeff3(1)*W(count-2),    sum'length)
                 + resize(coeff3(2)*W(count-1),    sum'length)
                 + resize(coeff3(3)*W(count),      sum'length)
                 + resize(coeff3(4)*W(count+1),    sum'length);
            elsif kcount > k and last = 5 then
                sum <= resize(coeff3(1)*W(count-2),    sum'length)
                 + resize(coeff3(2)*W(count-1),    sum'length)
                 + resize(coeff3(3)*W(count),      sum'length);
            else
                sum <= resize(coeff3(1)*W(count-2),    sum'length)
                 + resize(coeff3(2)*W(count-1),    sum'length)
                 + resize(coeff3(3)*W(count),      sum'length)
                 + resize(coeff3(4)*W(count+1),    sum'length)
                 + resize(coeff3(5)*W(count+2),    sum'length);
            end if;
            W(count-3) <= signed(i_mem_data);
            count <= count + 1;
            
        elsif count = 6 then
            if kcount >= k and last = 7 then
                sum <= resize(coeff3(1)*W(count-2),    sum'length)
                    + resize(coeff3(2)*W(count-1),    sum'length)
                    + resize(coeff3(3)*W(count),      sum'length)
                    + resize(coeff3(4)*W(count+1),    sum'length);
            elsif kcount > k and last = 6 then
                sum <= resize(coeff3(1)*W(count-2),    sum'length)
                 + resize(coeff3(2)*W(count-1),    sum'length)
                 + resize(coeff3(3)*W(count),      sum'length);
            else
                sum <= resize(coeff3(1)*W(count-2),    sum'length)
                    + resize(coeff3(2)*W(count-1),    sum'length)
                    + resize(coeff3(3)*W(count),      sum'length)
                    + resize(coeff3(4)*W(count+1),    sum'length)
                    + resize(coeff3(5)*W(0),    sum'length);
            end if;
            W(3) <= signed(i_mem_data);
            count <= count + 1; 
        else
            if kcount >= k and last = 0 then
                sum <= resize(coeff3(1)*W(count-2),    sum'length)
                    + resize(coeff3(2)*W(count-1),    sum'length)
                    + resize(coeff3(3)*W(count),      sum'length)
                    + resize(coeff3(4)*W(0),    sum'length);
            elsif kcount > k and last = 7 then
                sum <= resize(coeff3(1)*W(count-2),    sum'length)
                    + resize(coeff3(2)*W(count-1),    sum'length)
                    + resize(coeff3(3)*W(count),      sum'length);
            else
                sum <= resize(coeff3(1)*W(count-2),    sum'length)
                    + resize(coeff3(2)*W(count-1),    sum'length)
                    + resize(coeff3(3)*W(count),      sum'length)
                    + resize(coeff3(4)*W(0),    sum'length)
                    + resize(coeff3(5)*W(1),    sum'length);
            end if;
            W(4) <= signed(i_mem_data);
            count <= 0;
        end if;  
        s <= s8;
    
    elsif s = s7f5 then
        o_mem_en <= '1';
        o_mem_we <= '0';
        if count = 0 then
            if kcount <= 10 then
                sum <= resize(coeff5(3)*W(count),      sum'length)
                    + resize(coeff5(4)*W(count+1),    sum'length)
                    + resize(coeff5(5)*W(count+2),    sum'length)
                    + resize(coeff5(6)*W(count+3),    sum'length);
            elsif kcount >= k and last = 1 then
                sum <= resize(coeff5(0)*W(5),    sum'length)
                    + resize(coeff5(1)*W(6),    sum'length)
                    + resize(coeff5(2)*W(7),      sum'length)
                    + resize(coeff5(3)*W(count),    sum'length)
                    + resize(coeff5(4)*W(count+1),    sum'length);
            elsif kcount >= k and last = 2 then
                sum <= resize(coeff5(0)*W(5),    sum'length)
                    + resize(coeff5(1)*W(6),    sum'length)
                    + resize(coeff5(2)*W(7),      sum'length)
                    + resize(coeff5(3)*W(count),    sum'length)
                    + resize(coeff5(4)*W(count+1),    sum'length)
                    + resize(coeff5(5)*W(count+2),    sum'length);
            elsif kcount > k and last = 0 then
                sum <= resize(coeff5(0)*W(5),    sum'length)
                    + resize(coeff5(1)*W(6),    sum'length)
                    + resize(coeff5(2)*W(7),      sum'length)
                    + resize(coeff5(3)*W(count),    sum'length);
            else
                sum <= resize(coeff5(0)*W(5),    sum'length)
                    + resize(coeff5(1)*W(6),    sum'length)
                    + resize(coeff5(2)*W(7),      sum'length)
                    + resize(coeff5(3)*W(count),    sum'length)
                    + resize(coeff5(4)*W(count+1),    sum'length)
                    + resize(coeff5(5)*W(count+2),    sum'length)
                    + resize(coeff5(6)*W(count+3),    sum'length);
            end if;
            if kcount > 10 then
                W(4) <= signed(i_mem_data);
            end if;
            count <= count + 1;
            
        elsif count = 1 then
            if kcount <= 10 then
                sum <= resize(coeff5(2)*W(count-1),    sum'length)
                    + resize(coeff5(3)*W(count),      sum'length)
                    + resize(coeff5(4)*W(count+1),    sum'length)
                    + resize(coeff5(5)*W(count+2),    sum'length)
                    + resize(coeff5(6)*W(count+3),    sum'length);
            elsif kcount >= k and last = 2 then
                sum <= resize(coeff5(0)*W(6),    sum'length)
                    + resize(coeff5(1)*W(7),    sum'length)
                    + resize(coeff5(2)*W(count-1),    sum'length)
                    + resize(coeff5(3)*W(count),      sum'length)
                    + resize(coeff5(4)*W(count+1),    sum'length);
            elsif kcount >= k and last = 3 then
                sum <= resize(coeff5(0)*W(6),    sum'length)
                    + resize(coeff5(1)*W(7),    sum'length)
                    + resize(coeff5(2)*W(count-1),    sum'length)
                    + resize(coeff5(3)*W(count),      sum'length)
                    + resize(coeff5(4)*W(count+1),    sum'length)
                    + resize(coeff5(5)*W(count+2),    sum'length);
            elsif kcount >= k and last = 1 then
                sum <= resize(coeff5(0)*W(6),    sum'length)
                    + resize(coeff5(1)*W(7),    sum'length)
                    + resize(coeff5(2)*W(count-1),    sum'length)
                    + resize(coeff5(3)*W(count),      sum'length);
            else
                sum <= resize(coeff5(0)*W(6),    sum'length)
                    + resize(coeff5(1)*W(7),    sum'length)
                    + resize(coeff5(2)*W(count-1),    sum'length)
                    + resize(coeff5(3)*W(count),      sum'length)
                    + resize(coeff5(4)*W(count+1),    sum'length)
                    + resize(coeff5(5)*W(count+2),    sum'length)
                    + resize(coeff5(6)*W(count+3),    sum'length);
            end if;
            if kcount > 10 then
                W(5) <= signed(i_mem_data);
            end if;
            count <= count + 1;
            
        elsif count = 2 then
            if kcount <= 10 then
                sum <= resize(coeff5(1)*W(count-2),    sum'length)
                    + resize(coeff5(2)*W(count-1),    sum'length)
                    + resize(coeff5(3)*W(count),      sum'length)
                    + resize(coeff5(4)*W(count+1),    sum'length)
                    + resize(coeff5(5)*W(count+2),    sum'length)
                    + resize(coeff5(6)*W(count+3),    sum'length);
            elsif kcount >= k and last = 3 then
                sum <= resize(coeff5(0)*W(7),    sum'length)
                    + resize(coeff5(1)*W(count-2),    sum'length)
                    + resize(coeff5(2)*W(count-1),    sum'length)
                    + resize(coeff5(3)*W(count),      sum'length)
                    + resize(coeff5(4)*W(count+1),    sum'length);
            elsif kcount >= k and last = 4 then
                sum <= resize(coeff5(0)*W(7),    sum'length)
                    + resize(coeff5(1)*W(count-2),    sum'length)
                    + resize(coeff5(2)*W(count-1),    sum'length)
                    + resize(coeff5(3)*W(count),      sum'length)
                    + resize(coeff5(4)*W(count+1),    sum'length)
                    + resize(coeff5(5)*W(count+2),    sum'length);
            elsif kcount >= k and last = 2 then
                    sum <= resize(coeff5(0)*W(7),    sum'length)
                    + resize(coeff5(1)*W(count-2),    sum'length)
                    + resize(coeff5(2)*W(count-1),    sum'length)
                    + resize(coeff5(3)*W(count),      sum'length);
            else
                sum <= resize(coeff5(0)*W(7),    sum'length)
                    + resize(coeff5(1)*W(count-2),    sum'length)
                    + resize(coeff5(2)*W(count-1),    sum'length)
                    + resize(coeff5(3)*W(count),      sum'length)
                    + resize(coeff5(4)*W(count+1),    sum'length)
                    + resize(coeff5(5)*W(count+2),    sum'length)
                    + resize(coeff5(6)*W(count+3),    sum'length);
            end if;
            if kcount > 10 then
                W(6) <= signed(i_mem_data);
            end if;
            count <= count + 1;    
        elsif count = 3 then
            if kcount >= k and last = 4 then
                sum <= resize(coeff5(0)*W(count-3),    sum'length)
                 + resize(coeff5(1)*W(count-2),    sum'length)
                 + resize(coeff5(2)*W(count-1),    sum'length)
                 + resize(coeff5(3)*W(count),      sum'length)
                 + resize(coeff5(4)*W(count+1),    sum'length);
            elsif kcount >= k and last = 5 then
                sum <= resize(coeff5(0)*W(count-3),    sum'length)
                 + resize(coeff5(1)*W(count-2),    sum'length)
                 + resize(coeff5(2)*W(count-1),    sum'length)
                 + resize(coeff5(3)*W(count),      sum'length)
                 + resize(coeff5(4)*W(count+1),    sum'length)
                 + resize(coeff5(5)*W(count+2),    sum'length);
            elsif kcount >= k and last = 3 then
                sum <= resize(coeff5(0)*W(count-3),    sum'length)
                 + resize(coeff5(1)*W(count-2),    sum'length)
                 + resize(coeff5(2)*W(count-1),    sum'length)
                 + resize(coeff5(3)*W(count),      sum'length);
            else
                sum <= resize(coeff5(0)*W(count-3),    sum'length)
                 + resize(coeff5(1)*W(count-2),    sum'length)
                 + resize(coeff5(2)*W(count-1),    sum'length)
                 + resize(coeff5(3)*W(count),      sum'length)
                 + resize(coeff5(4)*W(count+1),    sum'length)
                 + resize(coeff5(5)*W(count+2),    sum'length)
                 + resize(coeff5(6)*W(count+3),    sum'length);
            end if;
            if kcount > 10 then
                W(7) <= signed(i_mem_data);
            end if;
            count <= count + 1;
                     
        elsif count = 4 then
            if kcount >= k and last = 5 then
                sum <= resize(coeff5(0)*W(count-3),    sum'length)
                 + resize(coeff5(1)*W(count-2),    sum'length)
                 + resize(coeff5(2)*W(count-1),    sum'length)
                 + resize(coeff5(3)*W(count),      sum'length)
                 + resize(coeff5(4)*W(count+1),    sum'length);
            elsif kcount >= k and last = 6 then
                sum <= resize(coeff5(0)*W(count-3),    sum'length)
                 + resize(coeff5(1)*W(count-2),    sum'length)
                 + resize(coeff5(2)*W(count-1),    sum'length)
                 + resize(coeff5(3)*W(count),      sum'length)
                 + resize(coeff5(4)*W(count+1),    sum'length)
                 + resize(coeff5(5)*W(count+2),    sum'length);
            elsif kcount >= k and last = 4 then
                sum <= resize(coeff5(0)*W(count-3),    sum'length)
                 + resize(coeff5(1)*W(count-2),    sum'length)
                 + resize(coeff5(2)*W(count-1),    sum'length)
                 + resize(coeff5(3)*W(count),      sum'length);
            else
                sum <= resize(coeff5(0)*W(count-3),    sum'length)
                 + resize(coeff5(1)*W(count-2),    sum'length)
                 + resize(coeff5(2)*W(count-1),    sum'length)
                 + resize(coeff5(3)*W(count),      sum'length)
                 + resize(coeff5(4)*W(count+1),    sum'length)
                 + resize(coeff5(5)*W(count+2),    sum'length)
                 + resize(coeff5(6)*W(count+3),    sum'length);
            end if;
            W(count-4) <= signed(i_mem_data);
            count <= count + 1;
                 
        elsif count = 5 then
            if kcount >= k and last = 6 then
                sum <= resize(coeff5(0)*W(count-3),    sum'length)
                 + resize(coeff5(1)*W(count-2),    sum'length)
                 + resize(coeff5(2)*W(count-1),    sum'length)
                 + resize(coeff5(3)*W(count),      sum'length)
                 + resize(coeff5(4)*W(count+1),    sum'length);
            elsif kcount >= k and last = 7 then
                sum <= resize(coeff5(0)*W(count-3),    sum'length)
                 + resize(coeff5(1)*W(count-2),    sum'length)
                 + resize(coeff5(2)*W(count-1),    sum'length)
                 + resize(coeff5(3)*W(count),      sum'length)
                 + resize(coeff5(4)*W(count+1),    sum'length)
                 + resize(coeff5(5)*W(count+2),    sum'length);
            elsif kcount >= k and last = 5 then
                sum <= resize(coeff5(0)*W(count-3),    sum'length)
                 + resize(coeff5(1)*W(count-2),    sum'length)
                 + resize(coeff5(2)*W(count-1),    sum'length)
                 + resize(coeff5(3)*W(count),      sum'length);
            else
                sum <= resize(coeff5(0)*W(count-3),    sum'length)
                 + resize(coeff5(1)*W(count-2),    sum'length)
                 + resize(coeff5(2)*W(count-1),    sum'length)
                 + resize(coeff5(3)*W(count),      sum'length)
                 + resize(coeff5(4)*W(count+1),    sum'length)
                 + resize(coeff5(5)*W(count+2),    sum'length)
                 + resize(coeff5(6)*W(0),    sum'length);
            end if;
            W(1) <= signed(i_mem_data);
            count <= count + 1; 
                 
        elsif count = 6 then
            if kcount >= k and last = 7 then
                sum <= resize(coeff5(0)*W(count-3),    sum'length)
                 + resize(coeff5(1)*W(count-2),    sum'length)
                 + resize(coeff5(2)*W(count-1),    sum'length)
                 + resize(coeff5(3)*W(count),      sum'length)
                 + resize(coeff5(4)*W(count+1),    sum'length);
            elsif kcount >= k and last = 0 then
                sum <= resize(coeff5(0)*W(count-3),    sum'length)
                 + resize(coeff5(1)*W(count-2),    sum'length)
                 + resize(coeff5(2)*W(count-1),    sum'length)
                 + resize(coeff5(3)*W(count),      sum'length)
                 + resize(coeff5(4)*W(count+1),    sum'length)
                 + resize(coeff5(5)*W(0),    sum'length);
            elsif kcount >= k and last = 6 then
                sum <= resize(coeff5(0)*W(count-3),    sum'length)
                 + resize(coeff5(1)*W(count-2),    sum'length)
                 + resize(coeff5(2)*W(count-1),    sum'length)
                 + resize(coeff5(3)*W(count),      sum'length);
            else
                sum <= resize(coeff5(0)*W(count-3),    sum'length)
                 + resize(coeff5(1)*W(count-2),    sum'length)
                 + resize(coeff5(2)*W(count-1),    sum'length)
                 + resize(coeff5(3)*W(count),      sum'length)
                 + resize(coeff5(4)*W(count+1),    sum'length)
                 + resize(coeff5(5)*W(0),    sum'length)
                 + resize(coeff5(6)*W(1),    sum'length);
            end if;
            W(2) <= signed(i_mem_data);
            count <= count + 1;
                
        else
            if kcount >= k and last = 0 then
                sum <= resize(coeff5(0)*W(count-3),    sum'length)
                 + resize(coeff5(1)*W(count-2),    sum'length)
                 + resize(coeff5(2)*W(count-1),    sum'length)
                 + resize(coeff5(3)*W(count),      sum'length)
                 + resize(coeff5(4)*W(0),    sum'length);
            elsif kcount >= k and last = 1 then
                sum <= resize(coeff5(0)*W(count-3),    sum'length)
                 + resize(coeff5(1)*W(count-2),    sum'length)
                 + resize(coeff5(2)*W(count-1),    sum'length)
                 + resize(coeff5(3)*W(count),      sum'length)
                 + resize(coeff5(4)*W(0),    sum'length)
                 + resize(coeff5(5)*W(1),    sum'length);
            elsif kcount >= k and last = 7 then
                sum <= resize(coeff5(0)*W(count-3),    sum'length)
                 + resize(coeff5(1)*W(count-2),    sum'length)
                 + resize(coeff5(2)*W(count-1),    sum'length)
                 + resize(coeff5(3)*W(count),      sum'length);
            else
                sum <= resize(coeff5(0)*W(count-3),    sum'length)
                 + resize(coeff5(1)*W(count-2),    sum'length)
                 + resize(coeff5(2)*W(count-1),    sum'length)
                 + resize(coeff5(3)*W(count),      sum'length)
                 + resize(coeff5(4)*W(0),    sum'length)
                 + resize(coeff5(5)*W(1),    sum'length)
                 + resize(coeff5(6)*W(2),    sum'length);
            end if;
            W(3) <= signed(i_mem_data);
            count <= 0;
        end if;
        s <= s8;
    elsif s = s8 then
        o_mem_en <= '1';
        o_mem_we <= '0';
        if f = '0' then
            if sum < 0 then
                sum <= (shift_right(sum, 4)+1) + (shift_right(sum, 6)+1) + (shift_right(sum, 8)+1) + (shift_right(sum, 10)+1);
            else
                sum <= (sum srl 4) + (sum srl 6) + (sum srl 8) + (sum srl 10);
            end if;
        else
            if sum < 0 then
                sum <= (shift_right(sum, 6)+1) + (shift_right(sum, 10)+1);
            else
                sum <= (sum srl 6) + (sum srl 10);
            end if;
        end if;
        o_mem_addr <= i_add + 10 + k + kcount;
        s <= s9;
        
    elsif s = s9 then
        o_mem_en <= '1';
        o_mem_we <= '1';
        if sum > 127 then
            o_mem_data <= std_logic_vector(TO_SIGNED(127, 8));
        elsif sum < -128 then
            o_mem_data <= std_logic_vector(TO_SIGNED(-128, 8));
        else
            o_mem_data <= std_logic_vector(sum(7 downto 0));
        end if;
    
        if kcount = k+6 then
            s <= s10;
        else
            kcount <= kcount + 1;
            s <= s9wait;
        end if;
        
    elsif s = s9wait then
        o_mem_en <= '1';
        o_mem_we <= '0';
        if f = '0' then
            o_mem_addr <= i_add + 15 + kcount;
        else
            o_mem_addr <= i_add + 14 + kcount;
        end if;
        if kcount = k+1 then
            last <= (k-1) mod 8;
        end if;
        s <= s9read;
        
    elsif s = s9read then
        o_mem_en <= '1';
        o_mem_we <= '0';
        if f = '0' then
            s <= s7f3;
        else
            s <= s7f5;
        end if;
        
    elsif s = s10 then
        if i_start = '0' then
            o_mem_en <= '0';
            o_mem_we <= '0';
            o_done <= '0';
            s <= s0;
        else
            o_mem_en <= '0';
            o_mem_we <= '0';
            o_done <= '1';
            s <= s10;
        end if;
        
    end if;
end if;
end process;
end Behavioral;