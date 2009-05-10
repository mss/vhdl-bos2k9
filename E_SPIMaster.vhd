----------------------------------------------------------------------------------------------------
--	Master f�r die SPI Schnittstelle.
--	Sobald das Startflag f�r eine Periode des Basistaktes gesetzt ist, werden die Daten am
--	parallelen Eingang txData eingelesen und anschlie�end �bertragen. W�hrend der �bertragung ist
--	das Busyflag gesetzt.
--	Sobald das Busyflag gel�scht wird, stehen die empfangenen Daten am parallenen Ausgang rxData zur
--	Verf�gung.
--	
--	Generics:
--		gMode:
--			Definiert den �bertragungsmodus der Schnittstelle.
--
--		gDataWidth:
--			Definiert die Breite der zu �bertragenden Daten in Bit.
--
--		gClkDiv:
--			Definiert die �bertragungsgeschwindigkeit abh�ngig vom Basistakt.
--			clk_data = clk / gClkDiv
--
--
--	Port:
--		rst		: asynchroner Reset, high-aktiv
--		clk		: Basistakt
--		txData	: Zu sendende Daten
--		start	: Startflag, beginnt die �bertragung
--		miso	: SPI master in slave out
--		rxData	: Empfangene Daten
--		busy	: Busyflag
--		mosi	: SPI master out slave in
--		sck		: SPI Takt
--
--	Autor: xxx
--	Datum: xxx
----------------------------------------------------------------------------------------------------
entity E_SPIMaster is
	generic(
		gMode		: integer range 0 to 3;
		gDataWidth	: positive;
		gClkDiv		: positive	
	);
	
	port (
		rst		: in std_logic;
		clk		: in std_logic;
		txData	: in std_logic_vector(gDataWidth - 1 downto 0);
		start	: in std_logic;
		miso	: in std_logic;
		rxData	: out std_logic_vector(gDataWidth - 1 downto 0);
		busy	: out std_logic;
		mosi	: out std_logic;
		sck		: out std_logic
	);
end E_SPIMaster;
