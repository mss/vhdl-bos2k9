----------------------------------------------------------------------------------------------------
--	Master für die SPI Schnittstelle.
--	Sobald das Startflag für eine Periode des Basistaktes gesetzt ist, werden die Daten am
--	parallelen Eingang txData eingelesen und anschließend übertragen. Während der Übertragung ist
--	das Busyflag gesetzt.
--	Sobald das Busyflag gelöscht wird, stehen die empfangenen Daten am parallenen Ausgang rxData zur
--	Verfügung.
--	
--	Generics:
--		gMode:
--			Definiert den Übertragungsmodus der Schnittstelle.
--
--		gDataWidth:
--			Definiert die Breite der zu übertragenden Daten in Bit.
--
--		gClkDiv:
--			Definiert die Übertragungsgeschwindigkeit abhängig vom Basistakt.
--			clk_data = clk / gClkDiv
--
--
--	Port:
--		rst		: asynchroner Reset, high-aktiv
--		clk		: Basistakt
--		txData	: Zu sendende Daten
--		start	: Startflag, beginnt die Übertragung
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
