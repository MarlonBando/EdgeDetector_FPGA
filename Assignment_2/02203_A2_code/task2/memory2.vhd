-- -----------------------------------------------------------------------------
--
--  Title      :  Edge-Detection design project - task 2. --LITTLE ENDIAN--
--             :
--  Developers :  Edgar Lakis <s081553@student.dtu.dk>
--             :  Mathias Bruhn <113592@studnet.dtu.dk>
--             :
--  Purpose    :  Non-Synthesizable memory for task2.
--             :  Has single port for Accelerator + signal to triger saving of
--             :  the processed image to file.
--             :  File name for processed image is based on initial file name:
--             :     save_file_name = load_file_name & "_result.pgm"
--             :
--  Revision   :  1.0    8-10-09     Initial version
--             :  2.0   23-08-17     New "load from pgm" version
--
-- -----------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;
use std.textio.all;

entity memory2 is
    generic(
        -- File initialisation of the memory
        load_file_name : string
    );
    port(
        -- Read/Write port for Accelerator
        clk        : in  std_logic;
        en         : in  std_logic;
        we         : in  std_logic;
        addr       : in  std_logic_vector(15 downto 0);
        dataW      : in  std_logic_vector(31 downto 0);
        dataR      : out std_logic_vector(31 downto 0);
        -- Signal to dump processed image to file
        dump_image : in  std_logic
    );

end entity memory2;

architecture behaviour of memory2 is
    -- Where to store processed image
    constant save_file_name : string := load_file_name & "_result.pgm";

    type ram_type is array (50688 downto 0) of std_logic_vector(31 downto 0);

    impure function InitRamFromFile(RamFileName : in string) return ram_type is
        file pgmFile : text open read_mode is RamFileName;
        variable pgmLine     : line;
        variable word        : std_logic_vector(31 downto 0);
        variable byte_cnt    : std_logic_vector(1 downto 0) := "00";
        variable magicNumber : string(1 to 2);
        variable readReal    : integer;
        variable readBool    : boolean;
        variable index       : integer                      := 0;
        variable imageSize   : integer;
        variable mem         : ram_type                     := (others => (others => '0'));
    begin
        readline(pgmFile, pgmLine);     -- Read magic number
        read(pgmLine, magicNumber);
        assert magicNumber = "P2" report "PGM file not in ASCII format" severity failure;
        readline(pgmFile, pgmLine);     -- Read/skip comment
        readline(pgmFile, pgmLine);     -- Read image width and height
        read(pgmLine, readReal);
        imageSize := integer(readReal);
        read(pgmLine, readReal);
        imageSize := (imageSize * integer(readReal)) / 2;
        assert imageSize <= 101376 report "Image can't fit in memory" severity failure;
        readline(pgmFile, pgmLine);     -- Read/skip grayscale
        readline(pgmFile, pgmLine);     -- Read first image line

        while true loop
            read(pgmLine, readReal, readBool);
            if endfile(pgmFile) and not readBool then
                exit;
            elsif not readBool then
                readline(pgmFile, pgmLine);
            else
                word := std_logic_vector(to_unsigned(integer(readReal), 8)) & word(31 downto 8);
                if byte_cnt = "11" then
                    mem(index) := word;
                    index      := index + 1;
                end if;
                byte_cnt := byte_cnt + '1';
            end if;
        end loop;

        return mem;
    end function;

    signal RAM : ram_type := InitRamFromFile(load_file_name);

begin

    -----------------------------------
    -- Single-Port RAM with Read First
    process(clk)
    begin
        if clk'event and clk = '1' then
            if en = '1' then
                if we = '1' then
                    RAM(conv_integer(addr)) <= dataW;
                end if;
                dataR <= RAM(conv_integer(addr));
            end if;
        end if;
    end process;

    -----------------------------------
    -- Triger dumping of image
    process(dump_image) is
        procedure WriteImage(
            constant FileName     : in string;
            constant StartAddress : in integer;
            constant Width        : in integer;
            constant Height       : in integer) is
            file imgFile : text open write_mode is FileName;
            variable l        : line;
            variable addr     : integer := 0;
            variable lastAddr : integer := 0;
            variable tmp      : integer := 0;
            variable b        : natural := 0;
        begin
            lastAddr := StartAddress + Width / 4 * Height - 1;

            -- Write header
            write(l, string'("P2"));
            writeline(imgFile, l);
            write(l, string'("# CREATOR: VHDL Edge-Detection"));
            writeline(imgFile, l);
            write(l, string'(integer'image(Width) & " " & integer'image(Height)));
            writeline(imgFile, l);
            write(l, string'("255"));
            writeline(imgFile, l);

            -- Write content
            for addr in StartAddress to lastAddr loop
                for b in 0 to 3 loop
                    tmp := to_integer(unsigned(RAM(addr)((7 + b * 8) downto (0 + b * 8))));
                    write(l, integer'image(tmp));
                    writeline(imgFile, l);
                end loop;
            end loop;

            report "Processed image has been saved to: " & FileName severity failure;
        end WriteImage;

        constant img_width  : natural := 352;
        constant img_height : natural := 288;
        -- start address of processed image in memory
        constant mem_start  : natural := img_width / 4 * img_height;
    begin
        if dump_image = '1' then
            assert save_file_name /= ""
                report "Output image file not specified"
                severity failure;
            WriteImage(save_file_name, mem_start, img_width, img_height);
        end if;
    end process;

end architecture behaviour;
