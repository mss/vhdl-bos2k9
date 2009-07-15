-----------------------------------------------------------------------
-- Copyright (c) 2009 Malte S. Stretz <http://msquadrat.de> 
--
-- Testing the parity generator.
-----------------------------------------------------------------------
-- This entity is part of the following library:
-- pragma library fhw_rs232_t
library fhw_rs232_t;
library fhw_rs232;
use fhw_rs232.rs232_globals_p.all;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library stefanvhdl;
use stefanvhdl.txt_util.all;

-----------------------------------------------------------------------

entity rs232_globals_parity_t is
end rs232_globals_parity_t;

architecture test of rs232_globals_parity_t is
  procedure t(
    word   : std_logic_vector;
    expect : std_logic) is
    variable e_p_v, e_e_v : std_logic;
    variable o_p_v, o_e_v : std_logic;
  begin
    e_e_v := expect; o_e_v := not expect;
    o_p_v := get_parity(word, '0'); assert o_p_v = o_e_v report "wrong O parity for " & str(word) & ": " & str(o_p_v) & " != " & str(o_e_v);
    e_p_v := get_parity(word, '1'); assert e_p_v = e_e_v report "wrong E parity for " & str(word) & ": " & str(e_p_v) & " != " & str(e_e_v);
  end t;
begin
  t("0", '0');
  t("1", '1');
  
  t("00", '0');
  t("01", '1');
  t("10", '1');
  t("11", '0');
  
  t("000", '0');
  t("001", '1');
  t("010", '1');
  t("011", '0');
  t("100", '1');
  t("101", '0');
  t("110", '0');
  t("111", '1');
  
  t("0000", '0');
  t("0001", '1');
  t("0010", '1');
  t("0011", '0');
  t("0100", '1');
  t("0101", '0');
  t("0110", '0');
  t("0111", '1');
  t("1000", '1');
  t("1001", '0');
  t("1010", '0');
  t("1011", '1');
  t("1100", '0');
  t("1101", '1');
  t("1110", '1');
  t("1111", '0');
end test;
