; ==============================================================================
; File:     country.asm
; ==============================================================================
;
; Description:
;     FreeDOS COUNTRY.SYS - International Localization Data
;
;     This file contains country-specific localization data for FreeDOS,
;     including date/time/currency formats, uppercase/lowercase mappings,
;     collating sequences (sorting orders), filename character tables,
;     and yes/no prompt characters for multiple country and codepage
;     combinations.
;
; Purpose:
;     COUNTRY.SYS provides international support for DOS applications by
;     defining locale-specific behavior. It is loaded by the kernel at
;     boot time via CONFIG.SYS: COUNTRY=<code>,<codepage>,<filepath>
;
; Compatibility:
;     This file is binary-compatible with COUNTRY.SYS from:
;     - MS-DOS (Microsoft DOS)
;     - PC-DOS (IBM DOS)
;     - PTS-DOS
;     - OS/2
;     - Windows 9x
;
; File Format:
;     Format described in Ralf Brown's Interrupt List (RBIL)
;     Tables 2619-2622
;
; Structure Overview:
;     1. File Header       - Magic signature and entry count
;     2. Entry Table       - Index of all country/codepage combinations
;     3. Subfunction Data  - Actual localization data for each country:
;        a. Country Info   - Date/time/currency format (subfunction 1)
;        b. Uppercase      - Character case mapping (subfunction 2)
;        c. Lowercase      - Inverse case mapping (subfunction 3)
;        d. Filename Upper - Filename character mapping (subfunction 4)
;        e. Filename Chars - Valid filename characters (subfunction 5)
;        f. Collating Seq  - Sort order (subfunction 6)
;        g. DBCS Table     - Double-byte character sets (subfunction 7)
;        h. Yes/No Chars   - Prompt characters (subfunction 35)
;
; ------------------------------------------------------------------------------
; Copyright Information:
; ------------------------------------------------------------------------------
;
;                    Copyleft (G) 2004
;                    The FreeDOS Project
;
; This file is part of FreeDOS.
;
; FreeDOS is free software; you can redistribute it and/or
; modify it under the terms of the GNU General Public License
; as published by the Free Software Foundation; either
; version 2, or (at your option) any later version.
;
; FreeDOS is distributed in the hope that it will be useful,
; but WITHOUT ANY WARRANTY; without even the implied warranty
; of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
; See the GNU General Public License for more details.
;
; You should have received a copy of the GNU General Public
; License along with FreeDOS; see the file COPYING.  If not,
; write to the Free Software Foundation, Inc.,
; 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
; or go to http://www.gnu.org/licenses/gpl.html
;
; ------------------------------------------------------------------------------
; Credits:
; ------------------------------------------------------------------------------
;
; Created as a kernel table by:          Tom Ehlert
; Reformatted and commented by:          Bernd Blaauw
; Separated from the kernel by:          Luchezar Georgiev
; Case/collate tables added by:          Eduardo Casino
; Yes/No and codepage 850 table by:      Steffen Kaiser
; Amended by many contributors
;
; ------------------------------------------------------------------------------
; REFERENCES
; ------------------------------------------------------------------------------
;
; Standards used in this file:
;   - ISO 3166-1: Country codes
;     https://www.iso.org/iso-3166-country-codes.html
;   - ISO 639-1: Language codes
;     https://www.loc.gov/standards/iso639-2/php/code_list.php
;   - ISO 4217: Currency codes
;     https://www.iso.org/iso-4217-currency-codes.html
;   - Ralf Brown's Interrupt List (RBIL): DOS structures
;     https://www.ctyme.com/rbrown.htm
;   - European Central Bank: Euro adoption dates
;     https://www.ecb.europa.eu/euro/intro/html/index.en.html
;
; Euro adoption dates for reference:
;   1999: Austria, Belgium, Finland, France, Germany, Ireland, Italy,
;         Luxembourg, Netherlands, Portugal, Spain
;   2001: Greece
;   2007: Slovenia
;   2008: Cyprus, Malta
;   2009: Slovakia
;   2011: Estonia
;   2014: Latvia
;   2015: Lithuania
;   2023: Croatia
;   2026: Bulgaria
;
; Yugoslavia dissolution (1991-1992) successor states:
;   Slovenia (386), Croatia (385), Bosnia-Herzegovina (387),
;   Serbia (381), North Macedonia (389), Montenegro (382), Kosovo (383)
;
; ==============================================================================
; TABLE OF CONTENTS
; ==============================================================================
;
; 1: FILE STRUCTURE
;   [.data] File Header (signature, magic bytes, entry pointer)
;
; 2: ENTRIES (for each country/codepage)
;   - [.data1] Entry Table (index of all country/codepage combinations)
;   - [.data2] Defines which subfunctions are available for each entry
;   - [.data3] Date format, time format, currency symbol, separators,
;     the COUNTRY INFORMATION TABLES (subfunction 1)
;
; 3: UPPERCASE/LOWERCASE TABLES (Subfunctions 2, 3, 4)
;   [.data4] Character case conversion mappings for each codepage
;
; 4: FILENAME CHARACTER TABLE (Subfunction 5)
;   [.data5] Characters allowed/disallowed in filenames
;
; 5: COLLATING SEQUENCES (Subfunction 6)
;   [.data6] Sort order for each country/codepage combination
;
; 6: DBCS TABLES (Subfunction 7)
;   [.data7] Double-Byte Character Set lead byte ranges (Japanese, Korean, Chinese)
;
; 7: YES/NO TABLES (Subfunction 35)
;   [.data8] Yes/No prompt characters for each language
;
; ------------------------------------------------------------------------------
; COUNTRIES:
; Note: ISO alpha-2 character country codes are only used internally
;       All external references use international numeric country code
; ------------------------------------------------------------------------------
;
;   1 = United States (US)           2 = Canada (CA)
;   3 = Latin America (LA)           7 = Russia (RU)
;  27 = South Africa (ZA)           30 = Greece (GR)
;  31 = Netherlands (NL)            32 = Belgium (BE)
;  33 = France (FR)                 34 = Spain (ES)
;  36 = Hungary (HU)                38 = Yugoslavia (YU) [OBSOLETE]
;  39 = Italy (IT)                  40 = Romania (RO)
;  41 = Switzerland (CH)            42 = Czechoslovakia (CZ) [OBSOLETE]
;  43 = Austria (AT)                44 = United Kingdom (GB)
;  45 = Denmark (DK)                46 = Sweden (SE)
;  47 = Norway (NO)                 48 = Poland (PL)
;  49 = Germany (DE)                52 = Mexico (MX)
;  54 = Argentina (AR)              55 = Brazil (BR)
;  60 = Malaysia (MY)               61 = Australia (AU)
;  62 = Indonesia (ID)              63 = Philippines (PH)
;  64 = New Zealand (NZ)            65 = Singapore (SG)
;  66 = Thailand (TH)               81 = Japan (JP)
;  82 = South Korea (KR)            84 = Vietnam (VN)
;  86 = China (CN)                  90 = Turkey (TR)
;  91 = India (IN)                 351 = Portugal (PT)
; 352 = Luxembourg (LU)            353 = Ireland (IE)
; 354 = Iceland (IS)               355 = Albania (AL)
; 356 = Malta (MT)                 357 = Cyprus (CY)
; 358 = Finland (FI)               359 = Bulgaria (BG)
; 370 = Lithuania (LT)             371 = Latvia (LV)
; 372 = Estonia (EE)               375 = Belarus (BY)
; 380 = Ukraine (UA)               381 = Serbia (RS)
; 382 = Montenegro (ME)            383 = Kosovo (XK)
; 385 = Croatia (HR)               386 = Slovenia (SI)
; 387 = Bosnia-Herzegovina (BA)    389 = North Macedonia (MK)
; 420 = Czech Republic (CZ)        421 = Slovakia (SK)
; 785 = Middle East/Arabic (XX)    972 = Israel (IL)
;
; Multilingual (4xxxx codes):
; Belgium
;  40032 = Dutch-Belgium            
;  41032 = French-Belgium
;  42032 = German-Belgium
; Spain
;  40034 = Spanish-Spain
;  41034 = Catalan-Spain
;  42034 = Galician-Spain
;  43034 = Basque-Spain
; Switzerland
;  40041 = German-Switzerland
;  41041 = French-Switzerland
;  42041 = Italian-Switzerland
;
; ------------------------------------------------------------------------------
; CODEPAGES:
; ------------------------------------------------------------------------------
;
;  437  = US/OEM                    737  = Greek
;  775  = Baltic Rim                808  = Russian (Euro)
;  848  = Ukrainian                 849  = Belarusian
;  850  = Western European          852  = Central European
;  855  = Cyrillic                  857  = Turkish
;  858  = Western European + Euro   860  = Portuguese
;  861  = Icelandic                 862  = Hebrew
;  863  = French Canadian           864  = Arabic
;  865  = Nordic                    866  = Russian
;  869  = Greek Modern              872  = Cyrillic
;  874  = Thai                      932  = Japanese (Shift-JIS)
;  934  = Korean                    936  = Chinese Simplified
; 1125  = Ukrainian                1131  = Belarusian
; 1258  = Vietnamese              30033  = Bulgarian MIK

; ==============================================================================
; COUNTRY* MACROS
; ==============================================================================
;
; Purpose:
;   Singular macro to specify data for 3 different structures in COUNTRY.SYS
;   Each COUNTRY* macro row corresponds to a complete country/codepage set of:
;     1. Entry table record
;     2. Subfunction header
;     3. Country info structure
;
;-------------------------------------------------------------------------------
; PARAMETER REFERENCE
;-------------------------------------------------------------------------------
;
; Standard Parameters (always required)
; Warning: %2/%5 onward shift up one for COUNTRY* macros with optional params
;   %1  - Country code (numeric, international phone code, e.g., 1 for US, 49 for Germany)
;   %2  - Codepage number (e.g., 437, 850, 858)
;   %3  - Collate table label (e.g., en_collate_437)
;   %4  - Yes/No table label (e.g., en_yn)
;   %5  - Date format: (MDY=0, DMY=1, YMD=2)
;   %6-10 Currency symbol (up to 4 bytes plus null terminator, 0 padded)
;   %6  - Currency symbol char 1 (e.g., "$", 0D5h for Euro)
;   %7  - Currency symbol char 2 (or 0 if unused)
;   %8  - Currency symbol char 3 (or 0 if unused)
;   %9  - Currency symbol char 4 (or 0 if unused)
;   %10 - Currency symbol char 5 (always 0)
;   %11 - Thousands separator (e.g., ',' or '.')
;   %12 - Decimal separator (e.g., '.' or ',')
;   %13 - Date separator (e.g., '/', '-', '.')
;   %14 - Time separator (usually ':')
;   %15 - Currency format flags: (0-7)
;          bit 0: 0=symbol precedes value, 1=symbol follows value
;          bit 1: number of spaces between value and symbol
;          bit 2: 1=symbol replaces decimal point
;   %16 - Currency precision (decimal places, typically 2)
;   %17 - Time format: _12 (0=12-hour with AM/PM) or _24 (1=24-hour)
;
; Optional Parameters (handled by extended macros):
;   - %2, multilang: Language index for multilingual countries (0-9)
;   - %5, lcase: Lowercase mapping table (if different from uppercase inverse)
;   - %5, dbcs: DBCS table (defaults to dbcs_empty)
;
;-------------------------------------------------------------------------------

;-------------------------------------------------------------------------------
; CONSTANTS AND DATE FORMAT DEFINITIONS
;-------------------------------------------------------------------------------

MDY equ 0       ; Month-Day-Year (US format)
DMY equ 1       ; Day-Month-Year (European format)
YMD equ 2       ; Year-Month-Day (ISO format)

_12 equ 0       ; 12-hour clock
_24 equ 1       ; 24-hour clock

;-------------------------------------------------------------------------------
; INTERNAL MACRO: _cnf_data
;-------------------------------------------------------------------------------
; Generates the country info data structure (subfunction 1 data).
; This is the core 22-byte country info block.
;-------------------------------------------------------------------------------
%macro _cnf_data 15
    db 0FFh,"CTYINFO"           ; Signature
    dw 22                       ; Length of data
    dw %1, %2, %3               ; Country ID, Codepage, Date format
    db %4, %5, %6, %7, %8       ; Currency symbol (5 bytes)
    db %9, 0, %10, 0            ; Thousands sep, Decimal sep
    db %11, 0, %12, 0           ; Date sep, Time sep
    db %13                      ; Currency format
    db %14                      ; Decimal places
    db %15                      ; Time format
    dw 0, 0                     ; Reserved
%endmacro

;-------------------------------------------------------------------------------
; INTERNAL MACRO: _ucase_for_cp
;-------------------------------------------------------------------------------
; Returns the uppercase table label for a given codepage.
; Uses preprocessor to map codepage to ucase_XXX label.
;-------------------------------------------------------------------------------
%define _ucase(cp) ucase_ %+ cp
%define _fchar_label fchar

;-------------------------------------------------------------------------------
; MAIN MACRO: COUNTRY
;-------------------------------------------------------------------------------
;
; Creates a complete country entry with all components:
;   - Entry table record
;   - Subfunction header (7 subfunctions, use COUNTRY_LCASE if has lcase table)
;   - Country info data structure
;
; Syntax:
;   COUNTRY cc, cp, collate, yesno, datefmt, cur1,cur2,cur3,cur4,cur5, \
;           ksep, dsep, datesep, timesep, curfmt, decpl, timefmt
;
; Example:
;   COUNTRY 1, 437, en_collate_437, en_yn, MDY, "$",0,0,0,0, ",",".","-",":", 0,2,_12
;
; Generated labels (for cc=1, cp=437):
;   __e_1_437 - Entry table record
;   _h_1_437  - Subfunction header
;   ci_1_437  - Country info data
;-------------------------------------------------------------------------------

%macro COUNTRY 17
section .data1 align=1
    ; === SECTION 1: Entry Table Record ===
    ; Format: dw size, country, codepage, reserved(2); dd offset
__e_%1_%2:
    dw 12, %1, %2, 0, 0
    dd _h_%1_%2

section .data2 align=1
    ; === SECTION 2: Subfunction Header ===
    ; Count of subfunctions followed by (size, id, offset) triplets
_h_%1_%2:
    dw 7                            ; 7 standard subfunctions
    dw 6, 1                         ; Subfunction 1: Country info
      dd ci_%1_%2
    dw 6, 2                         ; Subfunction 2: Uppercase table
      dd _ucase(%2)
    dw 6, 4                         ; Subfunction 4: Filename uppercase
      dd _ucase(%2)
    dw 6, 5                         ; Subfunction 5: Filename chars
      dd fchar
    dw 6, 6                         ; Subfunction 6: Collating sequence
      dd %3
    dw 6, 7                         ; Subfunction 7: DBCS table
      dd dbcs_empty
    dw 6, 35                        ; Subfunction 35: Yes/No chars
      dd %4

section .data3 align=1
    ; === SECTION 3: Country Info Data ===
ci_%1_%2:
    _cnf_data %1, %2, %5, %6, %7, %8, %9, %10, %11, %12, %13, %14, %15, %16, %17
%endmacro

;-------------------------------------------------------------------------------
; EXTENDED MACRO: COUNTRY_LCASE
;-------------------------------------------------------------------------------
;
; Same as COUNTRY but includes a lowercase mapping table (subfunction 3).
; Use this for languages where lowercase mapping differs from uppercase inverse.
;
; Syntax:
;   COUNTRY_LCASE cc, cp, collate, yesno, lcase_table, datefmt, cur1,...
;
; Example:
;   COUNTRY_LCASE 7, 866, ru_collate_866, ru_yn_866, lcase_866, DMY, ...
;-------------------------------------------------------------------------------

%macro COUNTRY_LCASE 18
section .data1 align=1
    ; === SECTION 1: Entry Table Record ===
__e_%1_%2:
    dw 12, %1, %2, 0, 0
    dd _h_%1_%2

section .data2 align=1
    ; === SECTION 2: Subfunction Header (8 subfunctions with lcase) ===
_h_%1_%2:
    dw 8                            ; 8 subfunctions (includes lcase)
    dw 6, 1                         ; Subfunction 1: Country info
      dd ci_%1_%2
    dw 6, 2                         ; Subfunction 2: Uppercase table
      dd _ucase(%2)
    dw 6, 3                         ; Subfunction 3: Lowercase table
      dd %5
    dw 6, 4                         ; Subfunction 4: Filename uppercase
      dd _ucase(%2)
    dw 6, 5                         ; Subfunction 5: Filename chars
      dd fchar
    dw 6, 6                         ; Subfunction 6: Collating sequence
      dd %3
    dw 6, 7                         ; Subfunction 7: DBCS table
      dd dbcs_empty
    dw 6, 35                        ; Subfunction 35: Yes/No chars
      dd %4

section .data3 align=1
    ; === SECTION 3: Country Info Data ===
ci_%1_%2:
    _cnf_data %1, %2, %6, %7, %8, %9, %10, %11, %12, %13, %14, %15, %16, %17, %18
%endmacro

;-------------------------------------------------------------------------------
; EXTENDED MACRO: COUNTRY_DBCS
;-------------------------------------------------------------------------------
;
; Same as COUNTRY but with a custom DBCS table (for CJK languages).
;
; Syntax:
;   COUNTRY_DBCS cc, cp, collate, yesno, dbcs_table, datefmt, cur1,...
;-------------------------------------------------------------------------------

%macro COUNTRY_DBCS 18
section .data1 align=1
    ; === SECTION 1: Entry Table Record ===
__e_%1_%2:
    dw 12, %1, %2, 0, 0
    dd _h_%1_%2

section .data2 align=1
    ; === SECTION 2: Subfunction Header ===
_h_%1_%2:
    dw 7
    dw 6, 1
      dd ci_%1_%2
    dw 6, 2
      dd _ucase(%2)
    dw 6, 4
      dd _ucase(%2)
    dw 6, 5
      dd fchar
    dw 6, 6
      dd %3
    dw 6, 7
      dd %5                         ; Custom DBCS table
    dw 6, 35
      dd %4

section .data3 align=1
    ; === SECTION 3: Country Info Data ===
ci_%1_%2:
    _cnf_data %1, %2, %6, %7, %8, %9, %10, %11, %12, %13, %14, %15, %16, %17, %18
%endmacro

;-------------------------------------------------------------------------------
; MULTILINGUAL MACRO: COUNTRY_ML
;-------------------------------------------------------------------------------
;
; For multilingual countries (extended codes 4XNNN format).
; The country code is computed as: 40000 + (multilang_index * 1000) + base_country
;
; Syntax:
;   COUNTRY_ML base_cc, multilang_idx, cp, collate, yesno, datefmt, cur1,...
;
; Example:
;   ; Belgium/Dutch (40032) = base 32, multilang 0
;   COUNTRY_ML 32, 0, 850, nl_collate_850, nl_yn, DMY, "E","U","R",0,0, ...
;   ; Spain/Catalan (41034) = base 34, multilang 1
;   COUNTRY_ML 34, 1, 850, ca_collate_850, ca_yn, DMY, "E","U","R",0,0, ...
;-------------------------------------------------------------------------------

%macro COUNTRY_ML 18
    ; Compute extended country code: (4 multilang base = 4XNNN)
    %assign _extended_cc (40000 + (%2 * 1000) + %1)

section .data1 align=1
    ; === SECTION 1: Entry Table Record ===
__e_%[_extended_cc]_%3:
    dw 12, _extended_cc, %3, 0, 0
    dd _h_%[_extended_cc]_%3

section .data2 align=1
    ; === SECTION 2: Subfunction Header ===
_h_%[_extended_cc]_%3:
    dw 7
    dw 6, 1
      dd ci_%[_extended_cc]_%3
    dw 6, 2
      dd _ucase(%3)
    dw 6, 4
      dd _ucase(%3)
    dw 6, 5
      dd fchar
    dw 6, 6
      dd %4
    dw 6, 7
      dd dbcs_empty
    dw 6, 35
      dd %5

section .data3 align=1
    ; === SECTION 3: Country Info Data ===
ci_%[_extended_cc]_%3:
    _cnf_data _extended_cc, %3, %6, %7, %8, %9, %10, %11, %12, %13, %14, %15, %16, %17, %18
%endmacro

;-------------------------------------------------------------------------------
; OBSOLETE WRAPPER MACROS
;-------------------------------------------------------------------------------
;
; These macros wrap entries in %ifdef OBSOLETE blocks for backward
; compatibility with legacy country codes.
;-------------------------------------------------------------------------------

%define OBSOLETE

%macro OLD_COUNTRY 17
%ifdef OBSOLETE
    COUNTRY %1, %2, %3, %4, %5, %6, %7, %8, %9, %10, %11, %12, %13, %14, %15, %16, %17
%endif
%endmacro

%macro OLD_COUNTRY_LCASE 18
%ifdef OBSOLETE
    COUNTRY_LCASE %1, %2, %3, %4, %5, %6, %7, %8, %9, %10, %11, %12, %13, %14, %15, %16, %17, %18
%endif
%endmacro

%macro OLD_COUNTRY_ML 18
%ifdef OBSOLETE
    COUNTRY_ML %1, %2, %3, %4, %5, %6, %7, %8, %9, %10, %11, %12, %13, %14, %15, %16, %17, %18
%endif
%endmacro

%macro COUNTRY_ENTRIES_START 0
section .data1 align=1
country_entries_start:
%endmacro

%macro COUNTRY_ENTRIES_END 0
section .data1 align=1
country_entries_end:
%endmacro

[map all country.map]

;-------------------------------------------------------------------------------
; USAGE EXAMPLES
;-------------------------------------------------------------------------------
;
; Example 1: Standard single-language country (United States)
; -----------------------------------------------------------------
; COUNTRY 1, 437, en_collate_437, en_yn, MDY, "$",0,0,0,0, ",",".","-",":", 0,2,_12
; COUNTRY 1, 850, en_collate_850, en_yn, MDY, "$",0,0,0,0, ",",".","-",":", 0,2,_12
;
; Example 2: Country with lowercase table (Russia cp866)
; -----------------------------------------------------------------
; COUNTRY_LCASE 7, 866, ru_collate_866, ru_yn_866, lcase_866, DMY, 0E0h,".",0,0,0, " ",",",".",":", 3,2,_24
;
; Example 3: Multilingual country (Belgium/Dutch)
; -----------------------------------------------------------------
; COUNTRY_ML 32, 0, 850, nl_collate_850, nl_yn, DMY, "E","U","R",0,0, ".",",","/",":", 0,2,_24
;
; Example 4: DBCS country (Japan)
; -----------------------------------------------------------------
; COUNTRY_DBCS 81, 932, jp_collate_932, jp_yn, dbcs_japan, YMD, 5Ch,0,0,0,0, ",",".","-",":", 0,0,_24
;
; Example 5: Obsolete country (wrapped in %ifdef OBSOLETE)
; -----------------------------------------------------------------
; OLD_COUNTRY 38, 852, yu_collate_852, sh_yn, YMD, "D","i","n",0,0, ".",",","-",":", 2,2,_24


; ==============================================================================
; 1: FILE HEADER
; ==============================================================================
;
; The file header contains the magic signature 'COUNTRY' and points to
; the entry table. Structure:
;   - Byte 0: 0FFh (signature)
;   - Bytes 1-7: 'COUNTRY' (magic string)
;   - Bytes 8-17: Reserved/undocumented
;   - Bytes 18-21: Pointer to entry table
;

section .data align=1

db 0FFh,"COUNTRY",0,0,0,0,0,0,0,0,1,0,1 ; reserved and undocumented values
dd  ent     ; first entry
ent dw  (country_entries_end - country_entries_start) / 14

; ==============================================================================
; 2: COUNTRY ENTRIES
; ==============================================================================
;
; Each COUNTRY* macro generates entry table + subfunction header + country info
;

COUNTRY_ENTRIES_START

; ------------------------------------------------------------------------------
; United States - Country Code 1
; ------------------------------------------------------------------------------
COUNTRY 1, 437, en_collate_437, yn_yn, MDY, "$", 0, 0, 0, 0, ",", ".", "-", ":", 0, 2, _12 ; Currency: $ - US Dollar,, Yes / No
COUNTRY 1, 850, en_collate_850, yn_yn, MDY, "$", 0, 0, 0, 0, ",", ".", "-", ":", 0, 2, _12
COUNTRY 1, 858, en_collate_858, yn_yn, MDY, "$", 0, 0, 0, 0, ",", ".", "-", ":", 0, 2, _12

; ------------------------------------------------------------------------------
; Canada (French) - Country Code 2
; ------------------------------------------------------------------------------
COUNTRY 2, 850, fr_collate_850, yn_on, YMD, "$", 0, 0, 0, 0, " ", ",", "-", ":", 3, 2, _24 ; Oui / Non
COUNTRY 2, 858, fr_collate_858, yn_on, YMD, "$", 0, 0, 0, 0, " ", ",", "-", ":", 3, 2, _24
COUNTRY 2, 863, fr_collate_863, yn_on, YMD, "$", 0, 0, 0, 0, " ", ",", "-", ":", 3, 2, _24

; ------------------------------------------------------------------------------
; Latin America - Country Code 3
; ------------------------------------------------------------------------------
COUNTRY 3, 437, es_collate_437, yn_sn, DMY, "$", 0, 0, 0, 0, ",", ".", "/", ":", 0, 2, _12 ; Si / No
COUNTRY 3, 850, es_collate_850, yn_sn, DMY, "$", 0, 0, 0, 0, ",", ".", "/", ":", 0, 2, _12
COUNTRY 3, 858, es_collate_858, yn_sn, DMY, "$", 0, 0, 0, 0, ",", ".", "/", ":", 0, 2, _12

; ------------------------------------------------------------------------------
; Russia - Country Code 7
; ------------------------------------------------------------------------------
COUNTRY       7, 437, ru_collate_437, yn_dn,                  DMY, "R", "U", "B", 0, 0, " ", ",", ".", ":", 3, 2, _24 ; Da / Net
COUNTRY_LCASE 7, 808, ru_collate_808, yn_cyrl_866, lcase_808, DMY, 0E0h, ".",  0, 0, 0, " ", ",", ".", ":", 3, 2, _24
COUNTRY       7, 850, ru_collate_850, yn_dn,                  DMY, "R", "U", "B", 0, 0, " ", ",", ".", ":", 3, 2, _24
COUNTRY       7, 852, ru_collate_852, yn_dn,                  DMY, "R", "U", "B", 0, 0, " ", ",", ".", ":", 3, 2, _24
COUNTRY       7, 855, ru_collate_855, yn_cyrl_855,            DMY, 0E1h, ".",  0, 0, 0, " ", ",", ".", ":", 3, 2, _24
COUNTRY       7, 858, ru_collate_858, yn_dn,                  DMY, "R", "U", "B", 0, 0, " ", ",", ".", ":", 3, 2, _24
COUNTRY_LCASE 7, 866, ru_collate_866, yn_cyrl_866, lcase_866, DMY, 0E0h, ".",  0, 0, 0, " ", ",", ".", ":", 3, 2, _24
COUNTRY       7, 872, ru_collate_872, yn_cyrl_872,            DMY, 0E1h, ".",  0, 0, 0, " ", ",", ".", ":", 3, 2, _24

; ------------------------------------------------------------------------------
; South Africa - Country Code 27
; ------------------------------------------------------------------------------
COUNTRY 27, 437, en_collate_437, yn_yn, YMD, "R", 0, 0, 0, 0, " ", ",", "/", ":", 0, 2, _24 ; Yes / No
COUNTRY 27, 850, en_collate_850, yn_yn, YMD, "R", 0, 0, 0, 0, " ", ",", "/", ":", 0, 2, _24
COUNTRY 27, 858, en_collate_858, yn_yn, YMD, "R", 0, 0, 0, 0, " ", ",", "/", ":", 0, 2, _24

; ------------------------------------------------------------------------------
; Greece - Country Code 30
; ------------------------------------------------------------------------------
COUNTRY 30, 737, gr_collate_737, yn_gr_737, DMY, 84h, 93h, 90h,    0, 0, ".", ",", "/", ":", 1, 2, _12 ; Nai / Oxi
COUNTRY 30, 850, gr_collate_850, yn_no,     DMY, "E", "Y", "P",    0, 0, ".", ",", "/", ":", 1, 2, _12
COUNTRY 30, 858, gr_collate_858, yn_no,     DMY, 0D5h,       0, 0, 0, 0, ".", ",", "/", ":", 1, 2, _12
COUNTRY 30, 869, gr_collate_869, yn_gr_869, DMY, 0A8h, 0D1h, 0C7h, 0, 0, ".", ",", "/", ":", 1, 2, _12

; ------------------------------------------------------------------------------
; Netherlands - Country Code 31
; ------------------------------------------------------------------------------
COUNTRY 31, 437, nl_collate_437, yn_jn, DMY, "E", "U", "R", 0, 0, ".", ",", "-", ":", 0, 2, _24 ; Ja / Nee
COUNTRY 31, 850, nl_collate_850, yn_jn, DMY, "E", "U", "R", 0, 0, ".", ",", "-", ":", 0, 2, _24
COUNTRY 31, 858, nl_collate_858, yn_jn, DMY, 0D5h,    0, 0, 0, 0, ".", ",", "-", ":", 0, 2, _24

; ------------------------------------------------------------------------------
; Belgium - Country Code 32
; ------------------------------------------------------------------------------
COUNTRY 32,    437, be_collate_437, yn_jn, DMY, "E", "U", "R", 0, 0, ".", ",", "/", ":", 0, 2, _24 ; Ja / Nee
COUNTRY 32,    850, be_collate_850, yn_jn, DMY, "E", "U", "R", 0, 0, ".", ",", "/", ":", 0, 2, _24 ;
COUNTRY 32,    858, be_collate_858, yn_jn, DMY, 0D5h,    0, 0, 0, 0, ".", ",", "/", ":", 0, 2, _24 ;

COUNTRY_ML 32, 0, 437, nl_collate_437, yn_jn, DMY, "E", "U", "R", 0, 0, ".", ",", "/", ":", 0, 2, _24 ; Dutch, Ja / Nee
COUNTRY_ML 32, 0, 850, nl_collate_850, yn_jn, DMY, "E", "U", "R", 0, 0, ".", ",", "/", ":", 0, 2, _24
COUNTRY_ML 32, 0, 858, nl_collate_858, yn_jn, DMY, 0D5h,    0, 0, 0, 0, ".", ",", "/", ":", 0, 2, _24
COUNTRY_ML 32, 1, 437, fr_collate_437, yn_on, DMY, "E", "U", "R", 0, 0, ".", ",", "/", ":", 0, 2, _24 ; French, Oui / Non
COUNTRY_ML 32, 1, 850, fr_collate_850, yn_on, DMY, "E", "U", "R", 0, 0, ".", ",", "/", ":", 0, 2, _24
COUNTRY_ML 32, 1, 858, fr_collate_858, yn_on, DMY, 0D5h,    0, 0, 0, 0, ".", ",", "/", ":", 0, 2, _24
COUNTRY_ML 32, 2, 437, de_collate_437, yn_jn, DMY, "E", "U", "R", 0, 0, ".", ",", "/", ":", 0, 2, _24 ; German, Ja / Nein
COUNTRY_ML 32, 2, 850, de_collate_850, yn_jn, DMY, "E", "U", "R", 0, 0, ".", ",", "/", ":", 0, 2, _24
COUNTRY_ML 32, 2, 858, de_collate_858, yn_jn, DMY, 0D5h,    0, 0, 0, 0, ".", ",", "/", ":", 0, 2, _24

; ------------------------------------------------------------------------------
; France - Country Code 33
; ------------------------------------------------------------------------------
COUNTRY 33, 437, fr_collate_437, yn_on, DMY, "E", "U", "R", 0, 0, " ", ",", ".", ":", 0, 2, _24 ; Oui / Non
COUNTRY 33, 850, fr_collate_850, yn_on, DMY, "E", "U", "R", 0, 0, " ", ",", ".", ":", 0, 2, _24
COUNTRY 33, 858, fr_collate_858, yn_on, DMY, 0D5h,    0, 0, 0, 0, " ", ",", ".", ":", 0, 2, _24

; ------------------------------------------------------------------------------
; Spain - Country Code 34
; ------------------------------------------------------------------------------
COUNTRY 34,    437, es_collate_437, yn_sn, DMY, "E", "U", "R", 0, 0, ".", ",", "/", ":", 0, 2, _24 ; Si / No
COUNTRY 34,    850, es_collate_850, yn_sn, DMY, "E", "U", "R", 0, 0, ".", ",", "/", ":", 0, 2, _24
COUNTRY 34,    858, es_collate_858, yn_sn, DMY, 0D5h,    0, 0, 0, 0, ".", ",", "/", ":", 0, 2, _24

COUNTRY_ML 34, 0, 437, es_collate_437, yn_sn, DMY, "E", "U", "R", 0, 0, ".", ",", "/", ":", 0, 2, _24 ; Spanish, Si / No
COUNTRY_ML 34, 0, 850, es_collate_850, yn_sn, DMY, "E", "U", "R", 0, 0, ".", ",", "/", ":", 0, 2, _24
COUNTRY_ML 34, 0, 858, es_collate_858, yn_sn, DMY, 0D5h,    0, 0, 0, 0, ".", ",", "/", ":", 0, 2, _24
COUNTRY_ML 34, 1, 437, ca_collate_437, yn_sn, DMY, "E", "U", "R", 0, 0, ".", ",", "/", ":", 0, 2, _24 ; Catalan, Si / No
COUNTRY_ML 34, 1, 850, ca_collate_850, yn_sn, DMY, "E", "U", "R", 0, 0, ".", ",", "/", ":", 0, 2, _24
COUNTRY_ML 34, 1, 858, ca_collate_858, yn_sn, DMY, 0D5h,    0, 0, 0, 0, ".", ",", "/", ":", 0, 2, _24
COUNTRY_ML 34, 2, 437, gl_collate_437, yn_sn, DMY, "E", "U", "R", 0, 0, ".", ",", "/", ":", 0, 2, _24 ; Galician, Si / Non
COUNTRY_ML 34, 2, 850, gl_collate_850, yn_sn, DMY, "E", "U", "R", 0, 0, ".", ",", "/", ":", 0, 2, _24
COUNTRY_ML 34, 2, 858, gl_collate_858, yn_sn, DMY, 0D5h,    0, 0, 0, 0, ".", ",", "/", ":", 0, 2, _24
COUNTRY_ML 34, 3, 437, eu_collate_437, yn_be, DMY, "E", "U", "R", 0, 0, ".", ",", "/", ":", 0, 2, _24 ; Basque, Bai / Ez
COUNTRY_ML 34, 3, 850, eu_collate_850, yn_be, DMY, "E", "U", "R", 0, 0, ".", ",", "/", ":", 0, 2, _24
COUNTRY_ML 34, 3, 858, eu_collate_858, yn_be, DMY, 0D5h,    0, 0, 0, 0, ".", ",", "/", ":", 0, 2, _24

; ------------------------------------------------------------------------------
; Hungary - Country Code 36
; ------------------------------------------------------------------------------
COUNTRY 36, 850, hu_collate_850, yn_in, YMD, "F", "t", 0, 0, 0, " ", ",", ".", ":", 3, 2, _24 ; Igen / Nem
COUNTRY 36, 852, hu_collate_852, yn_in, YMD, "F", "t", 0, 0, 0, " ", ",", ".", ":", 3, 2, _24
COUNTRY 36, 858, hu_collate_858, yn_in, YMD, "F", "t", 0, 0, 0, " ", ",", ".", ":", 3, 2, _24

; ------------------------------------------------------------------------------
; Yugoslavia - Country Code 38
; [OBSOLETE]
; ------------------------------------------------------------------------------
OLD_COUNTRY 38, 850, sh_collate_850, yn_dn,       YMD, "D", "i", "n",    0, 0, ".", ",", "-", ":", 2, 2, _24 ; Da / Ne
OLD_COUNTRY 38, 852, sh_collate_852, yn_dn,       YMD, "D", "i", "n",    0, 0, ".", ",", "-", ":", 2, 2, _24
OLD_COUNTRY 38, 855, sh_collate_855, yn_cyrl_855, YMD, 0A7h, 0B7h, 0D4h, 0, 0, ".", ",", "-", ":", 2, 2, _24
OLD_COUNTRY 38, 858, sh_collate_858, yn_dn,       YMD, "D", "i", "n",    0, 0, ".", ",", "-", ":", 2, 2, _24
OLD_COUNTRY 38, 872, sh_collate_872, yn_cyrl_872, YMD, 0A7h, 0B7h, 0D4h, 0, 0, ".", ",", "-", ":", 2, 2, _24

; ------------------------------------------------------------------------------
; Italy - Country Code 39
; ------------------------------------------------------------------------------
COUNTRY 39, 437, it_collate_437, yn_sn, DMY, "E", "U", "R", 0, 0, ".", ",", "/", ".", 0, 2, _24 ; Si / No
COUNTRY 39, 850, it_collate_850, yn_sn, DMY, "E", "U", "R", 0, 0, ".", ",", "/", ".", 0, 2, _24
COUNTRY 39, 858, it_collate_858, yn_sn, DMY, 0D5h,    0, 0, 0, 0, ".", ",", "/", ".", 0, 2, _24

; ------------------------------------------------------------------------------
; Romania - Country Code 40
; ------------------------------------------------------------------------------
COUNTRY 40, 850, ro_collate_850, yn_dn, YMD, "L", "e", "i", 0, 0, ".", ",", "-", ":", 0, 2, _24 ; Da / Nu
COUNTRY 40, 852, ro_collate_852, yn_dn, YMD, "L", "e", "i", 0, 0, ".", ",", "-", ":", 0, 2, _24
COUNTRY 40, 858, ro_collate_858, yn_dn, YMD, "L", "e", "i", 0, 0, ".", ",", "-", ":", 0, 2, _24

; ------------------------------------------------------------------------------
; Switzerland - Country Code 41
; ------------------------------------------------------------------------------
COUNTRY 41,    437, ch_collate_437, yn_jn, DMY, "F", "r", ".", 0, 0, "'", ".", ".", ",", 2, 2, _24 ; Ja / Nein
COUNTRY 41,    850, ch_collate_850, yn_jn, DMY, "F", "r", ".", 0, 0, "'", ".", ".", ",", 2, 2, _24
COUNTRY 41,    858, ch_collate_858, yn_jn, DMY, "F", "r", ".", 0, 0, "'", ".", ".", ",", 2, 2, _24

COUNTRY_ML 41, 0, 437, de_collate_437, yn_jn, DMY, "F", "r", ".", 0, 0, "'", ".", ".", ",", 2, 2, _24 ; German, Ja / Nein
COUNTRY_ML 41, 0, 850, de_collate_850, yn_jn, DMY, "F", "r", ".", 0, 0, "'", ".", ".", ",", 2, 2, _24
COUNTRY_ML 41, 0, 858, de_collate_858, yn_jn, DMY, "F", "r", ".", 0, 0, "'", ".", ".", ",", 2, 2, _24
COUNTRY_ML 41, 1, 437, fr_collate_437, yn_on, DMY, "F", "r", ".", 0, 0, "'", ".", ".", ",", 2, 2, _24 ; French, Oui / Non
COUNTRY_ML 41, 1, 850, fr_collate_850, yn_on, DMY, "F", "r", ".", 0, 0, "'", ".", ".", ",", 2, 2, _24
COUNTRY_ML 41, 1, 858, fr_collate_858, yn_on, DMY, "F", "r", ".", 0, 0, "'", ".", ".", ",", 2, 2, _24
COUNTRY_ML 41, 2, 437, it_collate_437, yn_sn, DMY, "F", "r", ".", 0, 0, "'", ".", ".", ",", 2, 2, _24 ; Italian, Si / No
COUNTRY_ML 41, 2, 850, it_collate_850, yn_sn, DMY, "F", "r", ".", 0, 0, "'", ".", ".", ",", 2, 2, _24
COUNTRY_ML 41, 2, 858, it_collate_858, yn_sn, DMY, "F", "r", ".", 0, 0, "'", ".", ".", ",", 2, 2, _24

; ------------------------------------------------------------------------------
; Czechoslovakia - Country Code 42
; [OBSOLETE, see Czech Republic 420 and Slovakia 421]
; ------------------------------------------------------------------------------
OLD_COUNTRY 42, 850, cz_collate_850, yn_an, DMY, "K", "C", "s", 0, 0, ".", ",", "-", ":", 2, 2, _24 ; Ano / Ne
OLD_COUNTRY 42, 852, cz_collate_852, yn_an, DMY, "K", "C", "s", 0, 0, ".", ",", "-", ":", 2, 2, _24
OLD_COUNTRY 42, 858, cz_collate_858, yn_an, DMY, "K", "C", "s", 0, 0, ".", ",", "-", ":", 2, 2, _24

; ------------------------------------------------------------------------------
; Austria - Country Code 43
; ------------------------------------------------------------------------------
COUNTRY 43, 437, de_collate_437, yn_jn, DMY, "E", "U", "R", 0, 0, ".", ",", ".", ".", 0, 2, _24 ; Ja / Nein
COUNTRY 43, 850, de_collate_850, yn_jn, DMY, "E", "U", "R", 0, 0, ".", ",", ".", ".", 0, 2, _24
COUNTRY 43, 858, de_collate_858, yn_jn, DMY, 0D5h,    0, 0, 0, 0, ".", ",", ".", ".", 0, 2, _24

; ------------------------------------------------------------------------------
; United Kingdom - Country Code 44
; ------------------------------------------------------------------------------
COUNTRY 44, 437, en_collate_437, yn_yn, DMY, 9Ch, 0, 0, 0, 0, ",", ".", "/", ":", 0, 2, _24 ; Yes / No
COUNTRY 44, 850, en_collate_850, yn_yn, DMY, 9Ch, 0, 0, 0, 0, ",", ".", "/", ":", 0, 2, _24
COUNTRY 44, 858, en_collate_858, yn_yn, DMY, 9Ch, 0, 0, 0, 0, ",", ".", "/", ":", 0, 2, _24

; ------------------------------------------------------------------------------
; Denmark - Country Code 45
; ------------------------------------------------------------------------------
COUNTRY 45, 850, dk_collate_850, yn_jn, DMY, "k", "r", 0, 0, 0, ".", ",", "-", ".", 2, 2, _24 ; Ja / Nej
COUNTRY 45, 858, dk_collate_858, yn_jn, DMY, "k", "r", 0, 0, 0, ".", ",", "-", ".", 2, 2, _24
COUNTRY 45, 865, dk_collate_865, yn_jn, DMY, "k", "r", 0, 0, 0, ".", ",", "-", ".", 2, 2, _24

; ------------------------------------------------------------------------------
; Sweden - Country Code 46
; ------------------------------------------------------------------------------
COUNTRY 46, 437, se_collate_437, yn_jn, YMD, "K", "r", 0, 0, 0, " ", ",", "-", ".", 3, 2, _24 ; Ja / Nej
COUNTRY 46, 850, se_collate_850, yn_jn, YMD, "K", "r", 0, 0, 0, " ", ",", "-", ".", 3, 2, _24
COUNTRY 46, 858, se_collate_858, yn_jn, YMD, "K", "r", 0, 0, 0, " ", ",", "-", ".", 3, 2, _24
COUNTRY 46, 865, se_collate_865, yn_jn, YMD, "K", "r", 0, 0, 0, " ", ",", "-", ".", 3, 2, _24

; ------------------------------------------------------------------------------
; Norway - Country Code 47
; ------------------------------------------------------------------------------
COUNTRY 47, 850, no_collate_850, yn_jn, DMY, "K", "r", 0, 0, 0, ".", ",", ".", ":", 2, 2, _24 ; Ja / Nei
COUNTRY 47, 858, no_collate_858, yn_jn, DMY, "K", "r", 0, 0, 0, ".", ",", ".", ":", 2, 2, _24
COUNTRY 47, 865, no_collate_865, yn_jn, DMY, "K", "r", 0, 0, 0, ".", ",", ".", ":", 2, 2, _24

; ------------------------------------------------------------------------------
; Poland - Country Code 48
; ------------------------------------------------------------------------------
COUNTRY 48, 850, pl_collate_850, yn_tn, YMD, "P", "L", "N", 0, 0, ".", ",", "-", ":", 0, 2, _24 ; Tak / Nie
COUNTRY 48, 852, pl_collate_852, yn_tn, YMD, "Z", 88h,   0, 0, 0, ".", ",", "-", ":", 0, 2, _24
COUNTRY 48, 858, pl_collate_858, yn_tn, YMD, "P", "L", "N", 0, 0, ".", ",", "-", ":", 0, 2, _24

; ------------------------------------------------------------------------------
; Germany - Country Code 49
; ------------------------------------------------------------------------------
COUNTRY 49, 437, de_collate_437, yn_jn, DMY, "E", "U", "R", 0, 0, ".", ",", ".", ":", 3, 2, _24 ; Ja / Nein
COUNTRY 49, 850, de_collate_850, yn_jn, DMY, "E", "U", "R", 0, 0, ".", ",", ".", ":", 3, 2, _24
COUNTRY 49, 858, de_collate_858, yn_jn, DMY, 0D5h,    0, 0, 0, 0, ".", ",", ".", ":", 3, 2, _24

; ------------------------------------------------------------------------------
; Mexico - Country Code 52
; ------------------------------------------------------------------------------
COUNTRY 52, 437, es_collate_437, yn_sn, DMY, "$", 0, 0, 0, 0, ",", ".", "/", ":", 0, 2, _24 ; Currency: $ - Mexican Peso, Si / No
COUNTRY 52, 850, es_collate_850, yn_sn, DMY, "$", 0, 0, 0, 0, ",", ".", "/", ":", 0, 2, _24
COUNTRY 52, 858, es_collate_858, yn_sn, DMY, "$", 0, 0, 0, 0, ",", ".", "/", ":", 0, 2, _24

; ------------------------------------------------------------------------------
; Argentina - Country Code 54
; ------------------------------------------------------------------------------
COUNTRY 54, 437, es_collate_437, yn_sn, DMY, "$", 0, 0, 0, 0, ".", ",", "/", ".", 0, 2, _24 ; Si / No
COUNTRY 54, 850, es_collate_850, yn_sn, DMY, "$", 0, 0, 0, 0, ".", ",", "/", ".", 0, 2, _24
COUNTRY 54, 858, es_collate_858, yn_sn, DMY, "$", 0, 0, 0, 0, ".", ",", "/", ".", 0, 2, _24

; ------------------------------------------------------------------------------
; Brazil - Country Code 55
; ------------------------------------------------------------------------------
COUNTRY 55, 437, pt_collate_437, yn_sn, DMY, "R", "$", 0, 0, 0, ".", ",", "/", ":", 2, 2, _24 ; Sim / Nao
COUNTRY 55, 850, pt_collate_850, yn_sn, DMY, "R", "$", 0, 0, 0, ".", ",", "/", ":", 2, 2, _24
COUNTRY 55, 858, pt_collate_858, yn_sn, DMY, "R", "$", 0, 0, 0, ".", ",", "/", ":", 2, 2, _24

; ------------------------------------------------------------------------------
; Malaysia - Country Code 60
; ------------------------------------------------------------------------------
COUNTRY 60, 437, en_collate_437, yn_yn, DMY, "$", 0, 0, 0, 0, ",", ".", "/", ":", 0, 2, _12 ; Yes / No

; ------------------------------------------------------------------------------
; Australia - Country Code 61
; ------------------------------------------------------------------------------
COUNTRY 61, 437, en_collate_437, yn_yn, DMY, "$", 0, 0, 0, 0, ",", ".", "-", ":", 0, 2, _12 ; Yes / No
COUNTRY 61, 850, en_collate_850, yn_yn, DMY, "$", 0, 0, 0, 0, ",", ".", "-", ":", 0, 2, _12
COUNTRY 61, 858, en_collate_858, yn_yn, DMY, "$", 0, 0, 0, 0, ",", ".", "-", ":", 0, 2, _12

; ------------------------------------------------------------------------------
; Indonesia - Country Code 62
; ------------------------------------------------------------------------------
COUNTRY 62, 437, en_collate_437, yn_yt, DMY, "R", "p", 0, 0, 0, ".", ",", "/", ":", 0, 0, _24 ; Ya / Tidak
COUNTRY 62, 850, en_collate_850, yn_yt, DMY, "R", "p", 0, 0, 0, ".", ",", "/", ":", 0, 0, _24

; ------------------------------------------------------------------------------
; Philippines - Country Code 63
; ------------------------------------------------------------------------------
COUNTRY 63, 437, en_collate_437, yn_oh, MDY, "P", 0, 0, 0, 0, ",", ".", "/", ":", 0, 2, _12 ; Oo / Hindi
COUNTRY 63, 850, en_collate_850, yn_oh, MDY, "P", 0, 0, 0, 0, ",", ".", "/", ":", 0, 2, _12

; ------------------------------------------------------------------------------
; New Zealand - Country Code 64
; ------------------------------------------------------------------------------
COUNTRY 64, 437, en_collate_437, yn_yn, DMY, "$", 0, 0, 0, 0, ",", ".", "/", ":", 0, 2, _24 ; Currency: $ - New Zealand Dollar, Yes / No
COUNTRY 64, 850, en_collate_850, yn_yn, DMY, "$", 0, 0, 0, 0, ",", ".", "/", ":", 0, 2, _24
COUNTRY 64, 858, en_collate_858, yn_yn, DMY, "$", 0, 0, 0, 0, ",", ".", "/", ":", 0, 2, _24

; ------------------------------------------------------------------------------
; Singapore - Country Code 65
; ------------------------------------------------------------------------------
COUNTRY 65, 437, en_collate_437, yn_yn, DMY, "$", 0, 0, 0, 0, ",", ".", "/", ":", 0, 2, _12 ; Yes / No

; ------------------------------------------------------------------------------
; Thailand - Country Code 66
; ------------------------------------------------------------------------------
COUNTRY 66, 437, en_collate_437, yn_yn, DMY, "B", 0, 0, 0, 0, ",", ".", "/", ":", 0, 2, _24 ; Yes / No
COUNTRY 66, 850, en_collate_850, yn_yn, DMY, "B", 0, 0, 0, 0, ",", ".", "/", ":", 0, 2, _24
COUNTRY 66, 874, th_collate_874, yn_yn, DMY, "B", 0, 0, 0, 0, ",", ".", "/", ":", 0, 2, _24

; ------------------------------------------------------------------------------
; Japan - Country Code 81
; ------------------------------------------------------------------------------
COUNTRY      81, 437, en_collate_437, yn_yn,              YMD, 9Dh, 0, 0, 0, 0, ",", ".", "-", ":", 0, 0, _24 ; Yes / No
COUNTRY_DBCS 81, 932, jp_collate_932, yn_yn, jp_dbcs_932, YMD, 5Ch, 0, 0, 0, 0, ",", ".", "-", ":", 0, 0, _24

; ------------------------------------------------------------------------------
; South Korea - Country Code 82
; ------------------------------------------------------------------------------
COUNTRY      82, 437, en_collate_437, yn_ya,              YMD, "K", "R", "W", 0, 0, ",", ".", ".", ":", 0, 0, _24 ; ASCII fallback: Y / A
COUNTRY_DBCS 82, 934, kr_collate_934, yn_ya, kr_dbcs_934, YMD, 5Ch,     0, 0, 0, 0, ",", ".", ".", ":", 0, 0, _24 ; Ye / A

; ------------------------------------------------------------------------------
; Vietnam - Country Code 84
; ------------------------------------------------------------------------------
COUNTRY 84,  437,  en_collate_437, yn_ck, DMY, "d", 0, 0, 0, 0, ".", ",", "/", ":", 3, 0, _24 ; Co / Khong
COUNTRY 84,  850,  en_collate_850, yn_ck, DMY, "d", 0, 0, 0, 0, ".", ",", "/", ":", 3, 0, _24
COUNTRY 84, 1258, vn_collate_1258, yn_ck, DMY, "d", 0, 0, 0, 0, ".", ",", "/", ":", 3, 0, _24

; ------------------------------------------------------------------------------
; China - Country Code 86
; ------------------------------------------------------------------------------
COUNTRY      86, 437, en_collate_437, yn_sb,                  YMD, 9Dh, 0, 0, 0, 0, ",", ".", ".", ":", 0, 2, _12 ; ASCI fallback: S / B
COUNTRY_DBCS 86, 936, cn_collate_936, yn_cn_936, cn_dbcs_936, YMD, 5Ch, 0, 0, 0, 0, ",", ".", ".", ":", 0, 2, _12 ; Shi/Bushi

; ------------------------------------------------------------------------------
; Turkiye - Country Code 90
; ------------------------------------------------------------------------------
COUNTRY 90, 850, tr_collate_850, yn_eh, DMY, "T", "L", 0, 0, 0, ".", ",", "/", ":", 4, 2, _24 ; Evet / Hayir
COUNTRY 90, 857, tr_collate_857, yn_eh, DMY, "T", "L", 0, 0, 0, ".", ",", "/", ":", 4, 2, _24
COUNTRY 90, 858, tr_collate_858, yn_eh, DMY, "T", "L", 0, 0, 0, ".", ",", "/", ":", 4, 2, _24

; ------------------------------------------------------------------------------
; India - Country Code 91
; ------------------------------------------------------------------------------
COUNTRY 91, 437, en_collate_437, yn_yn, DMY, "R", "s", 0, 0, 0, ".", ",", "/", ":", 0, 2, _24 ; Yes / No

; ------------------------------------------------------------------------------
; Portugal - Country Code 351
; ------------------------------------------------------------------------------
COUNTRY 351, 850, pt_collate_850, yn_sn, DMY, "E", "U", "R", 0, 0, ".", ",", "-", ":", 0, 2, _24 ; Sim / Nao
COUNTRY 351, 858, pt_collate_858, yn_sn, DMY, 0D5h,    0, 0, 0, 0, ".", ",", "-", ":", 0, 2, _24
COUNTRY 351, 860, pt_collate_860, yn_sn, DMY, "E", "U", "R", 0, 0, ".", ",", "-", ":", 0, 2, _24

; ------------------------------------------------------------------------------
; Luxembourg - Country Code 352
; ------------------------------------------------------------------------------
COUNTRY 352, 437, fr_collate_437, yn_on, DMY, "E", "U", "R", 0, 0, ".", ",", "/", ":", 0, 2, _24 ; Oui / Non
COUNTRY 352, 850, fr_collate_850, yn_on, DMY, "E", "U", "R", 0, 0, ".", ",", "/", ":", 0, 2, _24
COUNTRY 352, 858, fr_collate_858, yn_on, DMY, 0D5h,    0, 0, 0, 0, ".", ",", "/", ":", 0, 2, _24

; ------------------------------------------------------------------------------
; Ireland - Country Code 353
; ------------------------------------------------------------------------------
COUNTRY 353, 437, en_collate_437, yn_yn, DMY, "E", "U", "R", 0, 0, ",", ".", "/", ":", 0, 2, _24 ; Yes / No
COUNTRY 353, 850, en_collate_850, yn_yn, DMY, "E", "U", "R", 0, 0, ",", ".", "/", ":", 0, 2, _24
COUNTRY 353, 858, en_collate_858, yn_yn, DMY, 0D5h,    0, 0, 0, 0, ",", ".", "/", ":", 0, 2, _24

; ------------------------------------------------------------------------------
; Iceland - Country Code 354
; ------------------------------------------------------------------------------
COUNTRY 354, 850, is_collate_850, yn_jn, DMY, "kr", 0, 0, 0, 0, ".", ",", ".", ":", 3, 0, _24 ; Ja / Nei
COUNTRY 354, 858, is_collate_858, yn_jn, DMY, "kr", 0, 0, 0, 0, ".", ",", ".", ":", 3, 0, _24
COUNTRY 354, 861, is_collate_861, yn_jn, DMY, "kr", 0, 0, 0, 0, ".", ",", ".", ":", 3, 0, _24
COUNTRY 354, 865, is_collate_865, yn_jn, DMY, "kr", 0, 0, 0, 0, ".", ",", ".", ":", 3, 0, _24

; ------------------------------------------------------------------------------
; Albania - Country Code 355
; ------------------------------------------------------------------------------
COUNTRY 355, 850, en_collate_850, yn_pj, DMY, "L", "e", "k", 0, 0, ".", ",", ".", ":", 3, 2, _24 ; Po / Jo
COUNTRY 355, 852, al_collate_852, yn_pj, DMY, "L", "e", "k", 0, 0, ".", ",", ".", ":", 3, 2, _24
COUNTRY 355, 858, en_collate_858, yn_pj, DMY, "L", "e", "k", 0, 0, ".", ",", ".", ":", 3, 2, _24

; ------------------------------------------------------------------------------
; Malta - Country Code 356
; ------------------------------------------------------------------------------
COUNTRY 356, 437, en_collate_437, yn_il, DMY, "E", "U", "R", 0, 0, ",", ".", "/", ":", 0, 2, _24 ; Iva / Le
COUNTRY 356, 850, en_collate_850, yn_il, DMY, "E", "U", "R", 0, 0, ",", ".", "/", ":", 0, 2, _24
COUNTRY 356, 858, en_collate_858, yn_il, DMY, 0D5h,    0, 0, 0, 0, ",", ".", "/", ":", 0, 2, _24

; ------------------------------------------------------------------------------
; Cyprus - Country Code 357
; ------------------------------------------------------------------------------
COUNTRY 357, 850, en_collate_850, yn_no,     DMY, "E", "U", "R", 0, 0, ".", ",", "/", ":", 0, 2, _24 ; Nai / Oxi
COUNTRY 357, 858, en_collate_858, yn_no,     DMY, 0D5h,    0, 0, 0, 0, ".", ",", "/", ":", 0, 2, _24
COUNTRY 357, 869, gr_collate_869, yn_gr_869, DMY, 0D5h,    0, 0, 0, 0, ".", ",", "/", ":", 0, 2, _24

; ------------------------------------------------------------------------------
; Finland - Country Code 358
; ------------------------------------------------------------------------------
COUNTRY 358, 437, fi_collate_437, yn_ke, DMY, "E", "U", "R", 0, 0, " ", ",", ".", ".", 3, 2, _24 ; Kylla / Ei
COUNTRY 358, 850, fi_collate_850, yn_ke, DMY, "E", "U", "R", 0, 0, " ", ",", ".", ".", 3, 2, _24
COUNTRY 358, 858, fi_collate_858, yn_ke, DMY, 0D5h,    0, 0, 0, 0, " ", ",", ".", ".", 3, 2, _24
COUNTRY 358, 865, fi_collate_865, yn_ke, DMY, "E", "U", "R", 0, 0, " ", ",", ".", ".", 3, 2, _24

; ------------------------------------------------------------------------------
; Bulgaria - Country Code 359
; ------------------------------------------------------------------------------
COUNTRY_LCASE 359,   808, bg_collate_808,   yn_cyrl_866, lcase_808,   DMY, "E", "U", "R", 0, 0, " ", ",", ".", ",", 3, 2, _24 ; 2026 Euro replaced BGN, Da / Net
COUNTRY_LCASE 359,   849, bg_collate_849,   yn_cyrl_866, lcase_849,   DMY, "E", "U", "R", 0, 0, " ", ",", ".", ",", 3, 2, _24
COUNTRY       359,   850, bg_collate_850,   yn_dn,                    DMY, "E", "U", "R", 0, 0, " ", ",", ".", ",", 3, 2, _24
COUNTRY       359,   855, bg_collate_855,   yn_cyrl_855,              DMY, "E", "U", "R", 0, 0, " ", ",", ".", ",", 3, 2, _24
COUNTRY       359,   858, bg_collate_858,   yn_dn,                    DMY, 0D5h,    0, 0, 0, 0, " ", ",", ".", ",", 3, 2, _24
COUNTRY_LCASE 359,   866, bg_collate_866,   yn_cyrl_866, lcase_866,   DMY, "E", "U", "R", 0, 0, " ", ",", ".", ",", 3, 2, _24
COUNTRY       359,   872, bg_collate_872,   yn_cyrl_872,              DMY, "E", "U", "R", 0, 0, " ", ",", ".", ",", 3, 2, _24
COUNTRY_LCASE 359,  1131, bg_collate_1131,  yn_cyrl_866, lcase_1131,  DMY, "E", "U", "R", 0, 0, " ", ",", ".", ",", 3, 2, _24
COUNTRY_LCASE 359, 30033, bg_collate_30033, yn_cyrl_866, lcase_30033, DMY, "E", "U", "R", 0, 0, " ", ",", ".", ",", 3, 2, _24 ; (MIK)

; ------------------------------------------------------------------------------
; Lithuania - Country Code 370
; ------------------------------------------------------------------------------
COUNTRY 370, 775, lt_collate_775, yn_tn, YMD, "E", "U", "R", 0, 0, " ", ",", "-", ":", 3, 2, _24 ; Taip / Ne
COUNTRY 370, 850, lt_collate_850, yn_tn, YMD, "E", "U", "R", 0, 0, " ", ",", "-", ":", 3, 2, _24
COUNTRY 370, 858, lt_collate_858, yn_tn, YMD, 0D5h,    0, 0, 0, 0, " ", ",", "-", ":", 3, 2, _24

; ------------------------------------------------------------------------------
; Latvia - Country Code 371
; ------------------------------------------------------------------------------
COUNTRY 371, 775, lv_collate_775, yn_jn, DMY, "E", "U", "R", 0, 0, " ", ",", ".", ":", 3, 2, _24 ; Ja / Ne
COUNTRY 371, 850, lv_collate_850, yn_jn, DMY, "E", "U", "R", 0, 0, " ", ",", ".", ":", 3, 2, _24
COUNTRY 371, 858, lv_collate_858, yn_jn, DMY, 0D5h,    0, 0, 0, 0, " ", ",", ".", ":", 3, 2, _24

; ------------------------------------------------------------------------------
; Estonia - Country Code 372
; ------------------------------------------------------------------------------
COUNTRY 372, 775, ee_collate_775, yn_je, DMY, "E", "U", "R", 0, 0, " ", ",", ".", ":", 3, 2, _24 ; Jah / Ei
COUNTRY 372, 850, ee_collate_850, yn_je, DMY, "E", "U", "R", 0, 0, " ", ",", ".", ":", 3, 2, _24
COUNTRY 372, 858, ee_collate_858, yn_je, DMY, 0D5h,    0, 0, 0, 0, " ", ",", ".", ":", 3, 2, _24

; ------------------------------------------------------------------------------
; Belarus - Country Code 375
; ------------------------------------------------------------------------------
COUNTRY_LCASE 375,  849, by_collate_849,  yn_cyrl_866, lcase_849,  DMY, 0E0h, 0E3h, 0A1h, ".", 0, " ", ",", ".", ":", 3, 2, _24 ; Tak / Nie
COUNTRY       375,  850, by_collate_850,  yn_tn,                   DMY, "B", "Y", "R",      0, 0, " ", ",", ".", ",", 3, 2, _24
COUNTRY       375,  858, by_collate_858,  yn_tn,                   DMY, "B", "Y", "R",      0, 0, " ", ",", ".", ",", 3, 2, _24
COUNTRY_LCASE 375, 1131, by_collate_1131, yn_cyrl_866, lcase_1131, DMY, 0E0h, 0E3h, 0A1h, ".", 0, " ", ",", ".", ":", 3, 2, _24

; ------------------------------------------------------------------------------
; Ukraine - Country Code 380
; ------------------------------------------------------------------------------
COUNTRY_LCASE 380,  848, ua_collate_848,  yn_cyrl_866, lcase_848,  DMY, 0A3h, 0E0h, 0ADh, ".", 0, " ", ",", ".", ":", 3, 2, _24 ; Tak / Ni [Note: Uses same bytes as Da / Net]
COUNTRY_LCASE 380,  855, ua_collate_855,  yn_cyrl_866, lcase_855,  DMY, 0A3h, 0E0h, 0ADh, ".", 0, " ", ",", ".", ":", 3, 2, _24
COUNTRY_LCASE 380,  866, ua_collate_866,  yn_cyrl_866, lcase_866,  DMY, 0A3h, 0E0h, 0ADh, ".", 0, " ", ",", ".", ":", 3, 2, _24
COUNTRY_LCASE 380, 1125, ua_collate_1125, yn_cyrl_866, lcase_1125, DMY, 0A3h, 0E0h, 0ADh, ".", 0, " ", ",", ".", ":", 3, 2, _24

; ------------------------------------------------------------------------------
; Serbia - Country Code 381
; ------------------------------------------------------------------------------
COUNTRY 381, 850, sh_collate_850, yn_dn,       DMY, "D", "i", "n",    0, 0, ".", ",", ".", ":", 3, 2, _24 ; Da / Ne
COUNTRY 381, 852, sh_collate_852, yn_dn,       DMY, "D", "i", "n",    0, 0, ".", ",", ".", ":", 3, 2, _24
COUNTRY 381, 855, sh_collate_855, yn_cyrl_855, DMY, 0A7h, 0B7h, 0D4h, 0, 0, ".", ",", ".", ":", 3, 2, _24
COUNTRY 381, 858, sh_collate_858, yn_dn,       DMY, "D", "i", "n",    0, 0, ".", ",", ".", ":", 3, 2, _24
COUNTRY 381, 872, sh_collate_872, yn_cyrl_872, DMY, 0A7h, 0B7h, 0D4h, 0, 0, ".", ",", ".", ":", 3, 2, _24

; ------------------------------------------------------------------------------
; Montenegro - Country Code 382
; ------------------------------------------------------------------------------
COUNTRY 382, 850, sh_collate_850, yn_dn,       DMY, "E", "U", "R", 0, 0, ".", ",", ".", ":", 0, 2, _24 ; Da / Ne
COUNTRY 382, 852, sh_collate_852, yn_dn,       DMY, "E", "U", "R", 0, 0, ".", ",", ".", ":", 0, 2, _24
COUNTRY 382, 855, sh_collate_855, yn_cyrl_855, DMY, "E", "U", "R", 0, 0, ".", ",", ".", ":", 0, 2, _24
COUNTRY 382, 858, sh_collate_858, yn_dn,       DMY, 0D5h,    0, 0, 0, 0, ".", ",", ".", ":", 0, 2, _24
COUNTRY 382, 872, sh_collate_872, yn_cyrl_855, DMY, 0CFh,    0, 0, 0, 0, ".", ",", ".", ":", 0, 2, _24

; ------------------------------------------------------------------------------
; Kosovo - Country Code 383
; ------------------------------------------------------------------------------
COUNTRY 383, 850, xk_collate_850, yn_pj, DMY, "E", "U", "R", 0, 0, ".", ",", ".", ":", 0, 2, _24 ; Po / Jo
COUNTRY 383, 852, xk_collate_852, yn_pj, DMY, "E", "U", "R", 0, 0, ".", ",", ".", ":", 0, 2, _24
COUNTRY 383, 855, xk_collate_855, yn_pj, DMY, "E", "U", "R", 0, 0, ".", ",", ".", ":", 0, 2, _24
COUNTRY 383, 858, xk_collate_858, yn_pj, DMY, 0D5h,    0, 0, 0, 0, ".", ",", ".", ":", 0, 2, _24
COUNTRY 383, 872, xk_collate_872, yn_pj, DMY, 0CFh,    0, 0, 0, 0, ".", ",", ".", ":", 0, 2, _24

; ------------------------------------------------------------------------------
; Croatia - Country Code 385
; ------------------------------------------------------------------------------
COUNTRY 385, 850, hr_collate_850, yn_dn, DMY, "E", "U", "R", 0, 0, ".", ",", ".", ".", 3, 2, _24 ; Da / Ne
COUNTRY 385, 852, hr_collate_852, yn_dn, DMY, "E", "U", "R", 0, 0, ".", ",", ".", ".", 3, 2, _24
COUNTRY 385, 858, hr_collate_858, yn_dn, DMY, 0D5h,    0, 0, 0, 0, ".", ",", ".", ".", 3, 2, _24

; ------------------------------------------------------------------------------
; Slovenia - Country Code 386
; ------------------------------------------------------------------------------
COUNTRY 386, 850, si_collate_850, yn_dn, DMY, "E", "U", "R", 0, 0, ".", ",", ".", ":", 3, 2, _24 ; Da / Ne
COUNTRY 386, 852, si_collate_852, yn_dn, DMY, "E", "U", "R", 0, 0, ".", ",", ".", ":", 3, 2, _24
COUNTRY 386, 858, si_collate_858, yn_dn, DMY, 0D5h,    0, 0, 0, 0, ".", ",", ".", ":", 3, 2, _24

; ------------------------------------------------------------------------------
; Bosnia-Herzegovina - Country Code 387
; ------------------------------------------------------------------------------
COUNTRY 387, 850, sh_collate_850, yn_dn,       DMY, "K", "M", 0, 0, 0, ".", ",", ".", ".", 3, 2, _24 ; Da / Ne
COUNTRY 387, 852, sh_collate_852, yn_dn,       DMY, "K", "M", 0, 0, 0, ".", ",", ".", ".", 3, 2, _24
COUNTRY 387, 855, sh_collate_855, yn_cyrl_855, DMY, "K", "M", 0, 0, 0, ".", ",", ".", ":", 3, 2, _24
COUNTRY 387, 858, sh_collate_858, yn_dn,       DMY, "K", "M", 0, 0, 0, ".", ",", ".", ".", 3, 2, _24
COUNTRY 387, 872, sh_collate_872, yn_cyrl_872, DMY, "K", "M", 0, 0, 0, ".", ",", ".", ":", 3, 2, _24

; ------------------------------------------------------------------------------
; North Macedonia - Country Code 389
; ------------------------------------------------------------------------------
COUNTRY 389, 850, mk_collate_850, yn_dn,       DMY, "D", "e", "n",    0, 0, ".", ",", ".", ":", 3, 2, _24 ; Da / Ne
COUNTRY 389, 855, mk_collate_855, yn_cyrl_855, DMY, 0A7h, 0A8h, 0D4h, 0, 0, ".", ",", ".", ":", 3, 2, _24
COUNTRY 389, 858, mk_collate_858, yn_dn,       DMY, "D", "e", "n",    0, 0, ".", ",", ".", ":", 3, 2, _24
COUNTRY 389, 872, mk_collate_872, yn_cyrl_872, DMY, 0A7h, 0A8h, 0D4h, 0, 0, ".", ",", ".", ":", 3, 2, _24

; ------------------------------------------------------------------------------
; Czech Republic - Country Code 420
; ------------------------------------------------------------------------------
COUNTRY 420, 850, cz_collate_850, yn_an, DMY, "K", "c", 0, 0, 0, ".", ",", "-", ":", 2, 2, _24 ; Ano / Ne
COUNTRY 420, 852, cz_collate_852, yn_an, DMY, "K", "c", 0, 0, 0, ".", ",", "-", ":", 2, 2, _24
COUNTRY 420, 858, cz_collate_858, yn_an, DMY, "K", "c", 0, 0, 0, ".", ",", "-", ":", 2, 2, _24

; ------------------------------------------------------------------------------
; Slovakia - Country Code 421
; ------------------------------------------------------------------------------
COUNTRY 421, 850, sk_collate_850, yn_an, DMY, "E", "U", "R", 0, 0, " ", ",", ".", ":", 3, 2, _24 ; Ano / Nie
COUNTRY 421, 852, sk_collate_852, yn_an, DMY, "E", "U", "R", 0, 0, " ", ",", ".", ":", 3, 2, _24
COUNTRY 421, 858, sk_collate_858, yn_an, DMY, 0D5h,    0, 0, 0, 0, " ", ",", ".", ":", 3, 2, _24

; ------------------------------------------------------------------------------
; Middle East / Arabic - Country Code 785
; Note that there are country specifc codes currently not included that may be better fit.
; ------------------------------------------------------------------------------
COUNTRY 785, 850, xx_collate_850, yn_nl,     DMY, 0CFh, 0, 0, 0, 0, ".", ",", "/", ":", 3, 3, _12 ; Na'am / La
COUNTRY 785, 858, xx_collate_858, yn_nl,     DMY, 0CFh, 0, 0, 0, 0, ".", ",", "/", ":", 3, 3, _12
COUNTRY 785, 864, xx_collate_864, yn_xx_864, DMY, 0A4h, 0, 0, 0, 0, ".", ",", "/", ":", 1, 3, _12

; ------------------------------------------------------------------------------
; Israel - Country Code 972
; ------------------------------------------------------------------------------
COUNTRY 972, 850, il_collate_850, yn_kl, DMY, "N", "I", "S", 0, 0, ",", ".", " ", ":", 2, 2, _24 ; Ken / Lo
COUNTRY 972, 858, il_collate_858, yn_kl, DMY, "N", "I", "S", 0, 0, ",", ".", " ", ":", 2, 2, _24
COUNTRY 972, 862, il_collate_862, yn_il_862, DMY, 99h, 0, 0, 0, 0, ",", ".", " ", ":", 2, 2, _24

COUNTRY_ENTRIES_END

section .data4 align=1
; ==============================================================================
; 3: UPPERCASE/LOWERCASE TABLES (Subfunctions 2, 3, 4)
; ==============================================================================
;
; Uppercase tables define character case mappings for each codepage.
; Uppercase equivalents of chars 80h to FFh
; Structure:
;   - Signature: 0FFh,'UCASE  ' (8 bytes)
;   - Size: Word (2 bytes)
;   - Table: 128 bytes (mappings for characters 80h-FFh)
;
; Lowercase tables (subfunction 3) are only defined when different
; from the uppercase mappings. Structure is similar:
;   - Signature: 0FFh,'LCASE  ' (8 bytes)
;   - Size: Word (2 bytes)
;   - Table: 256 bytes (mappings for characters 00h-FFh)
;
; Filename uppercase tables (subfunction 4) are usually the same as
; regular uppercase tables.

; ------------------------------------------------------------------------------
; Codepage 437 (US/OEM)
; ------------------------------------------------------------------------------

ucase_437 db 0FFh,"UCASE  "	; Same as kernel's harcoded
	  dw 128
db 128, 154,  69,  65, 142,  65, 143, 128
db  69,	 69,  69,  73,	73,  73, 142, 143
db 144, 146, 146,  79, 153,  79,  85,  85
db  89, 153, 154, 155, 156, 157, 158, 159
db  65,	 73,  79,  85, 165, 165, 166, 167
db 168, 169, 170, 171, 172, 173, 174, 175
db 176, 177, 178, 179, 180, 181, 182, 183
db 184, 185, 186, 187, 188, 189, 190, 191
db 192, 193, 194, 195, 196, 197, 198, 199
db 200, 201, 202, 203, 204, 205, 206, 207
db 208, 209, 210, 211, 212, 213, 214, 215
db 216, 217, 218, 219, 220, 221, 222, 223
db 224, 225, 226, 227, 228, 229, 230, 231
db 232, 233, 234, 235, 236, 237, 238, 239
db 240, 241, 242, 243, 244, 245, 246, 247
db 248, 249, 250, 251, 252, 253, 254, 255

ucase_874 equ ucase_437
ucase_1258 equ ucase_437

ucase_850 db 0FFh,"UCASE  "	; From Steffen Kaiser's UNF package
	  dw 128
db 128, 154, 144, 182, 142, 183, 143, 128
db 210, 211, 212, 216, 215, 222, 142, 143
db 144, 146, 146, 226, 153, 227, 234, 235
db  99, 153, 154, 157, 156, 157, 158, 159
db 181, 214, 224, 233, 165, 165, 166, 167
db 168, 169, 170, 171, 172, 173, 174, 175
db 176, 177, 178, 179, 180, 181, 182, 183
db 184, 185, 186, 187, 188, 189, 190, 191
db 192, 193, 194, 195, 196, 197, 199, 199
db 200, 201, 202, 203, 204, 205, 206, 207
db 209, 209, 210, 211, 212,  73, 214, 215
db 216, 217, 218, 219, 220, 221, 222, 223
db 224, 225, 226, 227, 229, 229, 230, 232
db 232, 233, 234, 235, 237, 237, 238, 239
db 240, 241, 242, 243, 244, 245, 246, 247
db 248, 249, 250, 251, 252, 253, 254, 255

ucase_858 db 0FFh,"UCASE  "
	  dw 128
db 128, 154, 144, 182, 142, 183, 143, 128
db 210, 211, 212, 216, 215, 222, 142, 143
db 144, 146, 146, 226, 153, 227, 234, 235
db  99, 153, 154, 157, 156, 157, 158, 159
db 181, 214, 224, 233, 165, 165, 166, 167
db 168, 169, 170, 171, 172, 173, 174, 175
db 176, 177, 178, 179, 180, 181, 182, 183
db 184, 185, 186, 187, 188, 189, 190, 191
db 192, 193, 194, 195, 196, 197, 199, 199
db 200, 201, 202, 203, 204, 205, 206, 207
db 209, 209, 210, 211, 212, 213, 214, 215
db 216, 217, 218, 219, 220, 221, 222, 223
db 224, 225, 226, 227, 229, 229, 230, 232
db 232, 233, 234, 235, 237, 237, 238, 239
db 240, 241, 242, 243, 244, 245, 246, 247
db 248, 249, 250, 251, 252, 253, 254, 255

ucase_860 db 0FFh,"UCASE  "
          dw 128		; Derived from ucase_437
db 128, 154, 144, 143, 142, 145, 134, 128
db 137, 137, 146, 139, 140, 152, 142, 143
db 144, 145, 146, 140, 153, 169, 150, 157
db 152, 153, 154, 155, 156, 157, 158, 159
db 134, 139, 159, 150, 165, 165, 166, 167
db 168, 169, 170, 171, 172, 173, 174, 175
db 176, 177, 178, 179, 180, 181, 182, 183
db 184, 185, 186, 187, 188, 189, 190, 191
db 192, 193, 194, 195, 196, 197, 198, 199
db 200, 201, 202, 203, 204, 205, 206, 207
db 208, 209, 210, 211, 212, 213, 214, 215
db 216, 217, 218, 219, 220, 221, 222, 223
db 224, 225, 226, 227, 228, 229, 230, 231
db 232, 233, 234, 235, 236, 237, 238, 239
db 240, 241, 242, 243, 244, 245, 246, 247
db 248, 249, 250, 251, 252, 253, 254, 255

ucase_857 db 0FFh,"UCASE  "	; Turkish. Needs NLSFUNC for proper uppercasing
          dw 128            ; of letter "i" (dotted i)
db 128, 154, 144, 182, 142, 183, 143, 128
db 210, 211, 212, 216, 215,  73, 142, 143
db 144, 146, 146, 226, 153, 227, 234, 235
db 152, 153, 154, 157, 156, 157, 158, 158
db 181, 214, 224, 233, 165, 165, 166, 166
db 168, 169, 170, 171, 172, 173, 174, 175
db 176, 177, 178, 179, 180, 181, 182, 183
db 184, 185, 186, 187, 188, 189, 190, 191
db 192, 193, 194, 195, 196, 197, 199, 199
db 200, 201, 202, 203, 204, 205, 206, 207
db 208, 209, 210, 211, 212, 213, 214, 215
db 216, 217, 218, 219, 220, 221, 222, 223
db 224, 225, 226, 227, 229, 229, 230, 231
db 232, 233, 234, 235, 222,  89, 238, 239
db 240, 241, 242, 243, 244, 245, 246, 247
db 248, 249, 250, 251, 252, 253, 254, 255

ucase_863 db 0FFh,"UCASE  "
          dw 128		; Derived from ucase_437
db 128, 154, 144, 132, 132, 142, 134, 128
db 146, 148, 145, 149, 168, 141, 142, 143
db 144, 145, 146, 153, 148, 149, 158, 157
db 152, 153, 154, 155, 156, 157, 158, 159
db 160, 161,  79,  85, 164, 165, 166, 167
db 168, 169, 170, 171, 172, 173, 174, 175
db 176, 177, 178, 179, 180, 181, 182, 183
db 184, 185, 186, 187, 188, 189, 190, 191
db 192, 193, 194, 195, 196, 197, 198, 199
db 200, 201, 202, 203, 204, 205, 206, 207
db 208, 209, 210, 211, 212, 213, 214, 215
db 216, 217, 218, 219, 220, 221, 222, 223
db 224, 225, 226, 227, 228, 229, 230, 231
db 232, 233, 234, 235, 236, 237, 238, 239
db 240, 241, 242, 243, 244, 245, 246, 247
db 248, 249, 250, 251, 252, 253, 254, 255

ucase_865 db 0FFh,"UCASE  "
          dw 128
db 128, 154, 144,  65, 142,  65, 143, 128
db  69,  69,  69,  73,  73,  73, 142, 143
db 144, 146, 146,  89, 153,  89,  85,  85
db  89, 153, 154, 157, 156, 157, 158, 159
db  65,  73,  79,  85, 165, 165, 166, 167
db 168, 169, 170, 171, 172, 173, 174, 175
db 176, 177, 178, 179, 180, 181, 182, 183
db 184, 185, 186, 187, 188, 189, 190, 191
db 192, 193, 194, 195, 196, 197, 198, 199
db 200, 201, 202, 203, 204, 205, 206, 207
db 208, 209, 210, 211, 212, 213, 214, 215
db 216, 217, 218, 219, 220, 221, 222, 223
db 224, 225, 226, 227, 228, 229, 230, 231
db 232, 233, 234, 235, 236, 237, 238, 239
db 240, 241, 242, 243, 244, 245, 246, 247
db 248, 249, 250, 251, 252, 253, 254, 255

ucase_866 db 0FFh,"UCASE  "
          dw 128
db 128, 129, 130, 131, 132, 133, 134, 135
db 136, 137, 138, 139, 140, 141, 142, 143
db 144, 145, 146, 147, 148, 149, 150, 151
db 152, 153, 154, 155, 156, 157, 158, 159
db 128, 129, 130, 131, 132, 133, 134, 135
db 136, 137, 138, 139, 140, 141, 142, 143
db 176, 177, 178, 179, 180, 181, 182, 183
db 184, 185, 186, 187, 188, 189, 190, 191
db 192, 193, 194, 195, 196, 197, 198, 199
db 200, 201, 202, 203, 204, 205, 206, 207
db 208, 209, 210, 211, 212, 213, 214, 215
db 216, 217, 218, 219, 220, 221, 222, 223
db 144, 145, 146, 147, 148, 149, 150, 151
db 152, 153, 154, 155, 156, 157, 158, 159
db 240, 240, 242, 242, 244, 244, 246, 246
db 248, 249, 250, 251, 252, 253, 254, 255

ucase_808 equ ucase_866

ucase_852 db 0FFh,"UCASE  "
          dw 128
db 128, 154, 144, 182, 142, 222, 143, 128
db 157, 211, 138, 138, 215, 141, 142, 143
db 144, 145, 145, 226, 153, 149, 149, 151
db 151, 153, 154, 155, 155, 157, 158, 172
db 181, 146, 224, 233, 164, 164, 166, 166
db 168, 168, 170, 141, 172, 184, 174, 175
db 176, 177, 178, 179, 180, 181, 182, 183
db 184, 185, 186, 187, 188, 189, 189, 191
db 192, 193, 194, 195, 196, 197, 198, 198
db 200, 201, 202, 203, 204, 205, 206, 207
db 209, 209, 210, 211, 210, 213, 214, 215
db 183, 217, 218, 219, 220, 221, 222, 223
db 224, 225, 226, 227, 227, 213, 230, 230
db 232, 233, 232, 235, 237, 237, 221, 239
db 240, 241, 242, 243, 244, 245, 246, 247
db 248, 249, 250, 235, 252, 252, 254, 255

ucase_855 db 0FFh,"UCASE  "
          dw 128
db 129, 129, 131, 131, 133, 133, 135, 135
db 137, 137, 139, 139, 141, 141, 143, 143
db 145, 145, 147, 147, 149, 149, 151, 151
db 153, 153, 155, 155, 157, 157, 159, 159
db 161, 161, 163, 163, 165, 165, 167, 167
db 169, 169, 171, 171, 173, 173, 174, 175
db 176, 177, 178, 179, 180, 182, 182, 184
db 184, 185, 186, 187, 188, 190, 190, 191
db 192, 193, 194, 195, 196, 197, 199, 199
db 200, 201, 202, 203, 204, 205, 206, 207
db 209, 209, 211, 211, 213, 213, 215, 215
db 221, 217, 218, 219, 220, 221, 224, 223
db 224, 226, 226, 228, 228, 230, 230, 232
db 232, 234, 234, 236, 236, 238, 238, 239
db 240, 242, 242, 244, 244, 246, 246, 248
db 248, 250, 250, 252, 252, 253, 254, 255

ucase_872 equ ucase_855

ucase_30033 db 0FFh,"UCASE  " ; MIK codepage
	  dw 128
db 128, 129, 130, 131, 132, 133, 134, 135
db 136, 137, 138, 139, 140, 141, 142, 143
db 144, 145, 146, 147, 148, 149, 150, 151
db 152, 153, 154, 155, 156, 157, 158, 159
db 128, 129, 130, 131, 132, 133, 134, 135
db 136, 137, 138, 139, 140, 141, 142, 143
db 144, 145, 146, 147, 148, 149, 150, 151
db 152, 153, 154, 155, 156, 157, 158, 159
db 192, 193, 194, 195, 196, 197, 198, 199
db 200, 201, 202, 203, 204, 205, 206, 207
db 208, 209, 210, 211, 212, 213, 214, 215
db 216, 217, 218, 219, 220, 221, 222, 223
db 224, 225, 226, 227, 228, 229, 230, 231
db 232, 233, 234, 235, 236, 237, 238, 239
db 240, 241, 242, 243, 244, 245, 246, 247
db 248, 249, 250, 251, 252, 253, 254, 255

ucase_869 db 0FFh,"UCASE  "
          dw 128
db 128, 129, 130, 131, 132, 133, 134, 135
db 136, 137, 138, 139, 140, 141, 142, 143
db 144, 145, 146, 147, 148, 149, 150, 151
db 152, 153, 154, 134, 155, 141, 143, 144
db 145, 145, 146, 149, 164, 165, 166, 167
db 168, 169, 170, 171, 172, 173, 174, 175
db 176, 177, 178, 179, 180, 181, 182, 183
db 184, 185, 186, 187, 188, 189, 190, 191
db 192, 193, 194, 195, 196, 197, 198, 199
db 200, 201, 202, 203, 204, 205, 206, 207
db 208, 209, 210, 211, 212, 213, 164, 165
db 166, 217, 218, 219, 220, 167, 168, 223
db 169, 170, 172, 173, 181, 182, 183, 184
db 189, 190, 198, 199, 207, 207, 208, 239
db 240, 241, 209, 210, 211, 245, 212, 247
db 248, 249, 213, 150, 150, 152, 254, 255

ucase_737 db 0FFh,"UCASE  "
          dw 128
db 128, 129, 130, 131, 132, 133, 134, 135
db 136, 137, 138, 139, 140, 141, 142, 143
db 144, 145, 146, 147, 148, 149, 150, 151
db 128, 129, 130, 131, 132, 133, 134, 135
db 136, 137, 138, 139, 140, 141, 142, 143
db 144, 145, 145, 146, 147, 148, 149, 150
db 176, 177, 178, 179, 180, 181, 182, 183
db 184, 185, 186, 187, 188, 189, 190, 191
db 192, 193, 194, 195, 196, 197, 198, 199
db 200, 201, 202, 203, 204, 205, 206, 207
db 208, 209, 210, 211, 212, 213, 214, 215
db 216, 217, 218, 219, 220, 221, 222, 223
db 151, 234, 235, 236, 244, 237, 238, 239
db 245, 240, 234, 235, 236, 237, 238, 239
db 240, 241, 242, 243, 244, 245, 246, 247
db 248, 249, 250, 251, 252, 253, 254, 255

ucase_932 db 0FFh,"UCASE  "
          dw 128
db 128, 129, 130, 131, 132, 133, 134, 135
db 136, 137, 138, 139, 140, 141, 142, 143
db 144, 145, 146, 147, 148, 149, 150, 151
db 152, 153, 154, 155, 156, 157, 158, 159
db 160, 161, 162, 163, 164, 165, 166, 167
db 168, 169, 170, 171, 172, 173, 174, 175
db 176, 177, 178, 179, 180, 181, 182, 183
db 184, 185, 186, 187, 188, 189, 190, 191
db 192, 193, 194, 195, 196, 197, 198, 199
db 200, 201, 202, 203, 204, 205, 206, 207
db 208, 209, 210, 211, 212, 213, 214, 215
db 216, 217, 218, 219, 220, 221, 222, 223
db 224, 225, 226, 227, 228, 229, 230, 231
db 232, 233, 234, 235, 236, 237, 238, 239
db 240, 241, 242, 243, 244, 245, 246, 247
db 248, 249, 250, 251, 252, 253, 254, 255

ucase_934 equ ucase_932
ucase_936 equ ucase_932

ucase_848 db 0FFh,"UCASE  "
          dw 128
db 128, 129, 130, 131, 132, 133, 134, 135
db 136, 137, 138, 139, 140, 141, 142, 143
db 144, 145, 146, 147, 148, 149, 150, 151
db 152, 153, 154, 155, 156, 157, 158, 159
db 128, 129, 130, 131, 132, 133, 134, 135
db 136, 137, 138, 139, 140, 141, 142, 143
db 176, 177, 178, 179, 180, 181, 182, 183
db 184, 185, 186, 187, 188, 189, 190, 191
db 192, 193, 194, 195, 196, 197, 198, 199
db 200, 201, 202, 203, 204, 205, 206, 207
db 208, 209, 210, 211, 212, 213, 214, 215
db 216, 217, 218, 219, 220, 221, 222, 223
db 144, 145, 146, 147, 148, 149, 150, 151
db 152, 153, 154, 155, 156, 157, 158, 159
db 240, 240, 242, 242, 244, 244, 246, 246
db 248, 248, 250, 251, 252, 253, 254, 255

ucase_1125 equ ucase_848

ucase_849 db 0FFh,"UCASE  "
          dw 128
db 128, 129, 130, 131, 132, 133, 134, 135
db 136, 137, 138, 139, 140, 141, 142, 143
db 144, 145, 146, 147, 148, 149, 150, 151
db 152, 153, 154, 155, 156, 157, 158, 159
db 128, 129, 130, 131, 132, 133, 134, 135
db 136, 137, 138, 139, 140, 141, 142, 143
db 176, 177, 178, 179, 180, 181, 182, 183
db 184, 185, 186, 187, 188, 189, 190, 191
db 192, 193, 194, 195, 196, 197, 198, 199
db 200, 201, 202, 203, 204, 205, 206, 207
db 208, 209, 210, 211, 212, 213, 214, 215
db 216, 217, 218, 219, 220, 221, 222, 223
db 144, 145, 146, 147, 148, 149, 150, 151
db 152, 153, 154, 155, 156, 157, 158, 159
db 240, 240, 242, 242, 244, 244, 246, 246
db 248, 248, 250, 251, 252, 252, 254, 255

ucase_1131 equ ucase_849

ucase_862 db 0FFh,"UCASE  "
	  dw 128
db 128, 129, 130, 131, 132, 133, 134, 135
db 136, 137, 138, 139, 140, 141, 142, 143
db 144, 145, 146, 147, 148, 149, 150, 151
db 152, 153, 154, 155, 156, 157, 158, 159
db  65,	 73,  79,  85, 165, 165, 166, 167
db 168, 169, 170, 171, 172, 173, 174, 175
db 176, 177, 178, 179, 180, 181, 182, 183
db 184, 185, 186, 187, 188, 189, 190, 191
db 192, 193, 194, 195, 196, 197, 198, 199
db 200, 201, 202, 203, 204, 205, 206, 207
db 208, 209, 210, 211, 212, 213, 214, 215
db 216, 217, 218, 219, 220, 221, 222, 223
db 224, 225, 226, 227, 228, 229, 230, 231
db 232, 233, 234, 235, 236, 237, 238, 239
db 240, 241, 242, 243, 244, 245, 246, 247
db 248, 249, 250, 251, 252, 253, 254, 255

ucase_864 equ ucase_932

; codepage 775 (Baltic Rim) for Estonian, Latvian, and Lithuanian
ucase_775 db 0FFh,"UCASE  "
	  dw 128
db 128, 129, 144, 160, 132, 149, 134, 128
db 136, 137, 138, 139, 161, 141, 142, 143
db 144, 145, 146, 147, 148, 149, 150, 151
db 152, 153, 154, 155, 156, 157, 158, 159
db 160, 161, 162, 163, 164, 165, 166, 167
db 168, 169, 170, 171, 172, 173, 174, 175
db 176, 177, 178, 179, 180, 181, 182, 183
db 184, 185, 186, 187, 188, 189, 190, 191
db 192, 193, 194, 195, 196, 197, 198, 199
db 200, 201, 202, 203, 204, 205, 206, 207
db 181, 182, 183, 184, 189, 190, 198, 199
db 207, 209, 210, 211, 212, 213, 214, 215
db 224, 225, 226, 227, 228, 229, 230, 231
db 232, 233, 234, 235, 236, 237, 238, 239
db 240, 241, 242, 243, 244, 245, 246, 247
db 248, 249, 250, 251, 252, 253, 254, 255

ucase_861 db 0FFh,"UCASE  "
	  dw 128
db 128, 154, 144, 182, 142, 143, 146, 128
db 136, 137, 138, 139, 140, 141, 142, 143
db 144, 146, 146, 147, 153, 149, 150, 151
db 152, 153, 154, 157, 156, 157, 158, 159
db 160, 161, 224, 163, 164, 165, 166, 167
db 168, 169, 170, 171, 172, 173, 174, 175
db 176, 177, 178, 179, 180, 181, 182, 183
db 184, 185, 186, 187, 188, 189, 190, 191
db 192, 193, 194, 195, 196, 197, 198, 199
db 200, 201, 202, 203, 204, 205, 206, 207
db 208, 209, 210, 211, 212, 213, 214, 215
db 216, 217, 218, 219, 220, 221, 222, 223
db 224, 225, 226, 227, 228, 229, 230, 231
db 232, 233, 234, 235, 236, 237, 238, 239
db 240, 241, 242, 243, 244, 245, 246, 247
db 248, 249, 250, 251, 252, 253, 254, 255

;------------------------------------------------------------------------------
; Lowercase equivalents of chars 00h to FFh
;------------------------------------------------------------------------------
lcase_866 db 0FFh,"LCASE  "
          dw 256
db   0,	  1,   2,   3,	 4,   5,   6,	7
db   8,	  9,  10,  11,	12,  13,  14,  15
db  16,	 17,  18,  19,	20,  21,  22,  23
db  24,	 25,  26,  27,	28,  29,  30,  31
db  32,	 33,  34,  35,	36,  37,  38,  39
db  40,	 41,  42,  43,	44,  45,  46,  47
db  48,	 49,  50,  51,	52,  53,  54,  55
db  56,	 57,  58,  59,	60,  61,  62,  63
db  64,	 97,  98,  99, 100, 101, 102, 103
db 104, 105, 106, 107, 108, 109, 110, 111
db 112, 113, 114, 115, 116, 117, 118, 119
db 120, 121, 122,  91,  92,  93,  94,  95
db  96,  97,  98,  99, 100, 101, 102, 103
db 104, 105, 106, 107, 108, 109, 110, 111
db 112, 113, 114, 115, 116, 117, 118, 119
db 120, 121, 122, 123, 124, 125, 126, 127
db 160, 161, 162, 163, 164, 165, 166, 167
db 168, 169, 170, 171, 172, 173, 174, 175
db 224, 225, 226, 227, 228, 229, 230, 231
db 232, 233, 234, 235, 236, 237, 238, 239
db 160, 161, 162, 163, 164, 165, 166, 167
db 168, 169, 170, 171, 172, 173, 174, 175
db 176, 177, 178, 179, 180, 181, 182, 183
db 184, 185, 186, 187, 188, 189, 190, 191
db 192, 193, 194, 195, 196, 197, 198, 199
db 200, 201, 202, 203, 204, 205, 206, 207
db 208, 209, 210, 211, 212, 213, 214, 215
db 216, 217, 218, 219, 220, 221, 222, 223
db 224, 225, 226, 227, 228, 229, 230, 231
db 232, 233, 234, 235, 236, 237, 238, 239
db 241, 241, 243, 243, 245, 245, 247, 247
db 248, 249, 250, 251, 252, 253, 254, 255

lcase_808 equ lcase_866

lcase_848 db 0FFh,"LCASE  "
          dw 256
db   0,	  1,   2,   3,	 4,   5,   6,	7
db   8,	  9,  10,  11,	12,  13,  14,  15
db  16,	 17,  18,  19,	20,  21,  22,  23
db  24,	 25,  26,  27,	28,  29,  30,  31
db  32,	 33,  34,  35,	36,  37,  38,  39
db  40,	 41,  42,  43,	44,  45,  46,  47
db  48,	 49,  50,  51,	52,  53,  54,  55
db  56,	 57,  58,  59,	60,  61,  62,  63
db  64,	 97,  98,  99, 100, 101, 102, 103
db 104, 105, 106, 107, 108, 109, 110, 111
db 112, 113, 114, 115, 116, 117, 118, 119
db 120, 121, 122,  91,  92,  93,  94,  95
db  96,  97,  98,  99, 100, 101, 102, 103
db 104, 105, 106, 107, 108, 109, 110, 111
db 112, 113, 114, 115, 116, 117, 118, 119
db 120, 121, 122, 123, 124, 125, 126, 127
db 160, 161, 162, 163, 164, 165, 166, 167
db 168, 169, 170, 171, 172, 173, 174, 175
db 224, 225, 226, 227, 228, 229, 230, 231
db 232, 233, 234, 235, 236, 237, 238, 239
db 160, 161, 162, 163, 164, 165, 166, 167
db 168, 169, 170, 171, 172, 173, 174, 175
db 176, 177, 178, 179, 180, 181, 182, 183
db 184, 185, 186, 187, 188, 189, 190, 191
db 192, 193, 194, 195, 196, 197, 198, 199
db 200, 201, 202, 203, 204, 205, 206, 207
db 208, 209, 210, 211, 212, 213, 214, 215
db 216, 217, 218, 219, 220, 221, 222, 223
db 224, 225, 226, 227, 228, 229, 230, 231
db 232, 233, 234, 235, 236, 237, 238, 239
db 241, 241, 243, 243, 245, 245, 247, 247
db 249, 249, 250, 251, 252, 253, 254, 255

lcase_1125 equ lcase_848
lcase_855 equ lcase_848

lcase_849 db 0FFh,"LCASE  "
          dw 256
db   0,	  1,   2,   3,	 4,   5,   6,	7
db   8,	  9,  10,  11,	12,  13,  14,  15
db  16,	 17,  18,  19,	20,  21,  22,  23
db  24,	 25,  26,  27,	28,  29,  30,  31
db  32,	 33,  34,  35,	36,  37,  38,  39
db  40,	 41,  42,  43,	44,  45,  46,  47
db  48,	 49,  50,  51,	52,  53,  54,  55
db  56,	 57,  58,  59,	60,  61,  62,  63
db  64,	 97,  98,  99, 100, 101, 102, 103
db 104, 105, 106, 107, 108, 109, 110, 111
db 112, 113, 114, 115, 116, 117, 118, 119
db 120, 121, 122,  91,  92,  93,  94,  95
db  96,  97,  98,  99, 100, 101, 102, 103
db 104, 105, 106, 107, 108, 109, 110, 111
db 112, 113, 114, 115, 116, 117, 118, 119
db 120, 121, 122, 123, 124, 125, 126, 127
db 160, 161, 162, 163, 164, 165, 166, 167
db 168, 169, 170, 171, 172, 173, 174, 175
db 224, 225, 226, 227, 228, 229, 230, 231
db 232, 233, 234, 235, 236, 237, 238, 239
db 160, 161, 162, 163, 164, 165, 166, 167
db 168, 169, 170, 171, 172, 173, 174, 175
db 176, 177, 178, 179, 180, 181, 182, 183
db 184, 185, 186, 187, 188, 189, 190, 191
db 192, 193, 194, 195, 196, 197, 198, 199
db 200, 201, 202, 203, 204, 205, 206, 207
db 208, 209, 210, 211, 212, 213, 214, 215
db 216, 217, 218, 219, 220, 221, 222, 223
db 224, 225, 226, 227, 228, 229, 230, 231
db 232, 233, 234, 235, 236, 237, 238, 239
db 241, 241, 243, 243, 245, 245, 247, 247
db 249, 249, 250, 251, 253, 253, 254, 255

lcase_1131 equ lcase_849

lcase_30033 db 0FFh,"LCASE  "
          dw 256
db   0,	  1,   2,   3,	 4,   5,   6,	7
db   8,	  9,  10,  11,	12,  13,  14,  15
db  16,	 17,  18,  19,	20,  21,  22,  23
db  24,	 25,  26,  27,	28,  29,  30,  31
db  32,	 33,  34,  35,	36,  37,  38,  39
db  40,	 41,  42,  43,	44,  45,  46,  47
db  48,	 49,  50,  51,	52,  53,  54,  55
db  56,	 57,  58,  59,	60,  61,  62,  63
db  64,	 97,  98,  99, 100, 101, 102, 103
db 104, 105, 106, 107, 108, 109, 110, 111
db 112, 113, 114, 115, 116, 117, 118, 119
db 120, 121, 122,  91,  92,  93,  94,  95
db  96,  97,  98,  99, 100, 101, 102, 103
db 104, 105, 106, 107, 108, 109, 110, 111
db 112, 113, 114, 115, 116, 117, 118, 119
db 120, 121, 122, 123, 124, 125, 126, 127
db 160, 161, 162, 163, 164, 165, 166, 167
db 168, 169, 170, 171, 172, 173, 174, 175
db 176, 177, 178, 179, 180, 181, 182, 183
db 184, 185, 186, 187, 188, 189, 190, 191
db 160, 161, 162, 163, 164, 165, 166, 167
db 168, 169, 170, 171, 172, 173, 174, 175
db 176, 177, 178, 179, 180, 181, 182, 183
db 184, 185, 186, 187, 188, 189, 190, 191
db 192, 193, 194, 195, 196, 197, 198, 199
db 200, 201, 202, 203, 204, 205, 206, 207
db 208, 209, 210, 211, 212, 213, 214, 215
db 216, 217, 218, 219, 220, 221, 222, 223
db 224, 225, 226, 227, 228, 229, 230, 231
db 232, 233, 234, 235, 236, 237, 238, 239
db 240, 241, 242, 243, 244, 245, 246, 247
db 248, 249, 250, 251, 252, 253, 254, 255


section .data5 align=1
; ==============================================================================
; 4: FILENAME CHARACTER TABLE (Subfunction 5)
; ==============================================================================
;
; Defines valid/invalid characters in filenames.
; Structure:
;   - Signature: 0FFh,'FCHAR  ' (8 bytes - note: FCHAR has 2 spaces)
;   - Size: Word (22 bytes for data section)
;   - Data:
;     - Byte: File characteristics (142/01h)
;     - Byte: Lowest permissible character value (0)
;     - Byte: Highest permissible character value (255)
;     - Byte: File characteristics 2 (65/00h)
;     - Byte: First excluded character in range (0)
;     - Byte: Last excluded character in range (32 = space)
;     - Byte: File characteristics 3 (238/02h)
;     - Byte: Number of individual illegal characters (14)
;     - Bytes: List of terminator characters
;
; This table is shared among all countries since filename rules are
; consistent across DOS implementations. The excluded range is 0-32
; (control characters and space), and specific terminators include:
;   . " / \ [ ] : | < > + = ; ,
;
; These characters have special meaning in DOS and cannot appear in filenames.
;
; ------------------------------------------------------------------------------
; Filename terminator table
;------------------------------------------------------------------------------
fchar db 0FFh,"FCHAR  "		; Same as kernel's hardcoded
      dw 22			; Comments from RBIL
db 142	  ; ??? (01h for MS-DOS 3.30-6.00)
db   0	  ; lowest permissible character value for filename
db 255	  ; highest permissible character value for filename
db  65	  ; ??? (00h for MS-DOS 3.30-6.00)
db   0	  ; first excluded character in range \ all characters in this
db  32	  ; last excluded character in range  / range are illegal
db 238	  ; ??? (02h for MS-DOS 3.30-6.00)
db  14	  ; number of illegal (terminator) characters
; characters which terminate a filename:
db  46,	 34,  47,  92,	91,  93,  58, 124 ; ."/\[]:|
db  60,	 62,  43,  61,	59,  44           ; <>+=;,


section .data6 align=1
; ==============================================================================
; 5: COLLATING SEQUENCES (Subfunction 6)
; ==============================================================================
;
; Collating sequences define the sort order for characters.
; Each table maps character values to sorting weights.
;
; Structure:
;   - Signature: 0FFh,'COLLATE' (8 bytes)
;   - Size: Word (256 bytes for the table)
;   - Table: 256 bytes (sorting weights for chars 00h-FFh)
;
; The collating sequence is critical for:
;   - DIR command sorting
;   - String comparisons (SORT command)
;   - File search ordering
;
; Different languages have different collating rules. For example:
;   - Spanish: CH treated as single letter after C, LL after L
;   - German: umlauts sorted like base letter or as separate
;   - Nordic: aa, ae, oe come after z
;   - Czech/Slovak: ch, diacritics have specific positions
;
; ------------------------------------------------------------------------------
; English Collating Sequences
; ------------------------------------------------------------------------------
;
; Collating sequence
;------------------------------------------------------------------------------
en_collate_437 db 0FFh,"COLLATE"		; English, CP437
	       dw 256				; Same as kernel's harcoded
db   0,	  1,   2,   3,	 4,   5,   6,	7
db   8,	  9,  10,  11,	12,  13,  14,  15
db  16,	 17,  18,  19,	20,  21,  22,  23
db  24,	 25,  26,  27,	28,  29,  30,  31
db  32,	 33,  34,  35,	36,  37,  38,  39
db  40,	 41,  42,  43,	44,  45,  46,  47
db  48,	 49,  50,  51,	52,  53,  54,  55
db  56,	 57,  58,  59,	60,  61,  62,  63
db  64,	 65,  66,  67,	68,  69,  70,  71
db  72,	 73,  74,  75,	76,  77,  78,  79
db  80,	 81,  82,  83,	84,  85,  86,  87
db  88,	 89,  90,  91,	92,  93,  94,  95
db  96,	 65,  66,  67,	68,  69,  70,  71
db  72,	 73,  74,  75,	76,  77,  78,  79
db  80,	 81,  82,  83,	84,  85,  86,  87
db  88,	 89,  90, 123, 124, 125, 126, 127
db  67,	 85,  69,  65,	65,  65,  65,  67
db  69,	 69,  69,  73,	73,  73,  65,  65
db  69,	 65,  65,  79,	79,  79,  85,  85
db  89,	 79,  85,  36,	36,  36,  36,  36
db  65,	 73,  79,  85,	78,  78, 166, 167
db  63, 169, 170, 171, 172,  33,  34,  34
db 176, 177, 178, 179, 180, 181, 182, 183
db 184, 185, 186, 187, 188, 189, 190, 191
db 192, 193, 194, 195, 196, 197, 198, 199
db 200, 201, 202, 203, 204, 205, 206, 207
db 208, 209, 210, 211, 212, 213, 214, 215
db 216, 217, 218, 219, 220, 221, 222, 223
db 224,	 83, 226, 227, 228, 229, 230, 231
db 232, 233, 234, 235, 236, 237, 238, 239
db 240, 241, 242, 243, 244, 245, 246, 247
db 248, 249, 250, 251, 252, 253, 254, 255

en_collate_850 db 0FFh,"COLLATE"		; English, CP850
	       dw 256
db   0,	  1,   2,   3,	 4,   5,   6,	7
db   8,	  9,  10,  11,	12,  13,  14,  15
db  16,	 17,  18,  19,	20,  21,  22,  23
db  24,	 25,  26,  27,	28,  29,  30,  31
db  32,	 33,  34,  35,	36,  37,  38,  39
db  40,	 41,  42,  43,	44,  45,  46,  47
db  48,	 49,  50,  51,	52,  53,  54,  55
db  56,	 57,  58,  59,	60,  61,  62,  63
db  64,	 65,  66,  67,	68,  69,  70,  71
db  72,	 73,  74,  75,	76,  77,  78,  79
db  80,	 81,  82,  83,	84,  85,  86,  87
db  88,	 89,  90,  91,	92,  93,  94,  95
db  96,	 65,  66,  67,	68,  69,  70,  71
db  72,	 73,  74,  75,	76,  77,  78,  79
db  80,	 81,  82,  83,	84,  85,  86,  87
db  88,	 89,  90, 123, 124, 125, 126, 127
db  67,	 85,  69,  65,	65,  65,  65,  67
db  69,	 69,  69,  73,	73,  73,  65,  65
db  69,	 65,  65,  79,	79,  79,  85,  85
db  89,	 79,  85,  36,	36,  36,  36,  36
db  65,	 73,  79,  85,	78,  78, 166, 167
db  63, 169, 170, 171, 172,  33,  34,  34
db 176, 177, 178, 179, 180,  65,  65,  65
db 184, 185, 186, 187, 188,  36,  36, 191
db 192, 193, 194, 195, 196, 197,  65,  65
db 200, 201, 202, 203, 204, 205, 206,  36
db  68,	 68,  69,  69,	69,  73,  73,  73
db  73, 217, 218, 219, 220, 221,  73, 223
db  79,	 83,  79,  79,	79,  79, 230, 231
db 232,	 85,  85,  85,	89,  89, 238, 239
db 240, 241, 242, 243, 244, 245, 246, 247
db 248, 249, 250,  49,	51,  50, 254, 255

en_collate_858 db 0FFh,"COLLATE"		; English, CP858
	       dw 256
db   0,	  1,   2,   3,	 4,   5,   6,	7
db   8,	  9,  10,  11,	12,  13,  14,  15
db  16,	 17,  18,  19,	20,  21,  22,  23
db  24,	 25,  26,  27,	28,  29,  30,  31
db  32,	 33,  34,  35,	36,  37,  38,  39
db  40,	 41,  42,  43,	44,  45,  46,  47
db  48,	 49,  50,  51,	52,  53,  54,  55
db  56,	 57,  58,  59,	60,  61,  62,  63
db  64,	 65,  66,  67,	68,  69,  70,  71
db  72,	 73,  74,  75,	76,  77,  78,  79
db  80,	 81,  82,  83,	84,  85,  86,  87
db  88,	 89,  90,  91,	92,  93,  94,  95
db  96,	 65,  66,  67,	68,  69,  70,  71
db  72,	 73,  74,  75,	76,  77,  78,  79
db  80,	 81,  82,  83,	84,  85,  86,  87
db  88,	 89,  90, 123, 124, 125, 126, 127
db  67,	 85,  69,  65,	65,  65,  65,  67
db  69,	 69,  69,  73,	73,  73,  65,  65
db  69,	 65,  65,  79,	79,  79,  85,  85
db  89,	 79,  85,  36,	36,  36,  36,  36
db  65,	 73,  79,  85,	78,  78, 166, 167
db  63, 169, 170, 171, 172,  33,  34,  34
db 176, 177, 178, 179, 180,  65,  65,  65
db 184, 185, 186, 187, 188,  36,  36, 191
db 192, 193, 194, 195, 196, 197,  65,  65
db 200, 201, 202, 203, 204, 205, 206,  36
db  68,	 68,  69,  69,	69,  36,  73,  73
db  73, 217, 218, 219, 220, 221,  73, 223
db  79,	 83,  79,  79,	79,  79, 230, 231
db 232,	 85,  85,  85,	89,  89, 238, 239
db 240, 241, 242, 243, 244, 245, 246, 247
db 248, 249, 250,  49,	51,  50, 254, 255

es_collate_437 db 0FFh,"COLLATE"		; Spanish, CP437
	       dw 256
db   0,	  1,   2,   3,	 4,   5,   6,	7
db   8,	  9,  10,  11,	12,  13,  14,  15
db  16,	 17,  18,  19,	20,  21,  22,  23
db  24,	 25,  26,  27,	28,  29,  30,  31
db  32,	 33,  34,  35,	36,  37,  38,  39
db  40,	 41,  42,  43,	44,  45,  46,  47
db  48,	 49,  50,  51,	52,  53,  54,  55
db  56,	 57,  58,  59,	60,  61,  62,  63
db  64,	 65,  66,  67,	69,  70,  71,  72
db  73,	 74,  75,  76,	77,  78,  79,  81
db  82,	 83,  84,  85,	87,  88,  89,  90
db  91,	 92,  93,  94,	95,  96,  97,  98
db  99,	 65,  66,  67,	69,  70,  71,  72
db  73,	 74,  75,  76,	77,  78,  79,  81
db  82,	 83,  84,  85,	87,  88,  89,  90
db  91,	 92,  93, 123, 124, 125, 126, 127
db  68,	 88,  70,  65,	65,  65,  65,  68
db  70,	 70,  70,  74,	74,  74,  65,  65
db  70,	 65,  65,  81,	81,  81,  88,  88
db  92,	 81,  88,  36,	36,  36,  36,  36
db  65,	 74,  81,  88,	80,  80,  65,  81
db  63, 169, 170, 171, 172,  33,  34,  34
db 176, 177, 178, 179, 180, 181, 182, 183
db 184, 185, 186, 187, 188, 189, 190, 191
db 192, 193, 194, 195, 196, 197, 198, 199
db 200, 201, 202, 203, 204, 205, 206, 207
db 208, 209, 210, 211, 212, 213, 214, 215
db 216, 217, 218, 219, 220, 221, 222, 223
db 224,	 86, 226, 227, 228, 229, 230, 231
db 232, 233, 234, 235, 236, 237, 238, 239
db 240, 241, 242, 243, 244, 245, 246, 247
db 248, 249, 250, 251,	79,  50, 254, 255

es_collate_850 db 0FFh,"COLLATE"		; Spanish, CP850
	       dw 256
db   0,	  1,   2,   3,	 4,   5,   6,	7
db   8,	  9,  10,  11,	12,  13,  14,  15
db  16,	 17,  18,  19,	20,  21,  22,  23
db  24,	 25,  26,  27,	28,  29,  30,  31
db  32,	 33,  34,  35,	36,  37,  38,  39
db  40,	 41,  42,  43,	44,  45,  46,  47
db  48,	 49,  50,  51,	52,  53,  54,  55
db  56,	 57,  58,  59,	60,  61,  62,  63
db  64,	 65,  66,  67,	69,  70,  71,  72
db  73,	 74,  75,  76,	77,  78,  79,  81
db  82,	 83,  84,  85,	87,  88,  89,  90
db  91,	 92,  93,  94,	95,  96,  97,  98
db  99,	 65,  66,  67,	69,  70,  71,  72
db  73,	 74,  75,  76,	77,  78,  79,  81
db  82,	 83,  84,  85,	87,  88,  89,  90
db  91,	 92,  93, 123, 124, 125, 126, 127
db  68,	 87,  70,  65,	65,  65,  65,  68
db  70,	 70,  70,  74,	74,  74,  65,  65
db  70,	 65,  65,  81,	81,  81,  88,  88
db  92,	 81,  88,  81,	36,  81, 158,  36
db  65,	 74,  81,  88,	80,  80,  65,  81
db  63, 169, 170, 171, 172,  33,  34,  34
db 176, 177, 178, 179, 180,  65,  65,  65
db 184, 185, 186, 187, 188,  36,  36, 191
db 192, 193, 194, 195, 196, 197,  65,  65
db 200, 201, 202, 203, 204, 205, 206,  36
db  69,	 69,  70,  70,	70,  74,  74,  74
db  74, 217, 218, 219, 220, 221,  74, 223
db  81,	 86,  81,  81,	81,  81, 230, 231
db 232,	 88,  88,  88,	92,  92, 238, 239
db 240, 241, 242, 243, 244, 245, 246, 247
db 248, 249, 250,  49,	51,  50, 254, 255

es_collate_858 db 0FFh,"COLLATE"		; Spanish, CP858
	       dw 256
db   0,	  1,   2,   3,	 4,   5,   6,	7
db   8,	  9,  10,  11,	12,  13,  14,  15
db  16,	 17,  18,  19,	20,  21,  22,  23
db  24,	 25,  26,  27,	28,  29,  30,  31
db  32,	 33,  34,  35,	36,  37,  38,  39
db  40,	 41,  42,  43,	44,  45,  46,  47
db  48,	 49,  50,  51,	52,  53,  54,  55
db  56,	 57,  58,  59,	60,  61,  62,  63
db  64,	 65,  66,  67,	68,  69,  70,  71
db  72,	 73,  74,  75,	76,  77,  78,  80
db  81,	 82,  83,  84,	85,  86,  87,  88
db  89,	 90,  91,  92,	93,  94,  95,  96
db  97,	 65,  66,  67,	68,  69,  70,  71
db  72,	 73,  74,  75,	76,  77,  78,  80
db  81,	 82,  83,  84,	85,  86,  87,  88
db  89,	 90,  91, 123, 124, 125, 126, 127
db  68,	 86,  69,  65,	65,  65,  65,  68
db  69,	 69,  69,  73,	73,  73,  65,  65
db  69,	 65,  65,  80,	80,  80,  86,  86
db  90,	 80,  86,  80,	36,  80, 158,  36
db  65,	 73,  80,  86,	79,  79,  65,  80
db  63, 169, 170, 171, 172,  33,  34,  34
db 176, 177, 178, 179, 180,  65,  65,  65
db 184, 185, 186, 187, 188,  36,  36, 191
db 192, 193, 194, 195, 196, 197,  65,  65
db 200, 201, 202, 203, 204, 205, 206,  36
db  68,	 68,  69,  69,	69,  36,  73,  73
db  73, 217, 218, 219, 220, 221,  73, 223
db  80,	225,  80,  80,	80,  80, 230, 231
db 232,	 86,  86,  86,	90,  90, 238, 239
db 240, 241, 242, 243, 244, 245, 246, 247
db 248, 249, 250,  49,	51,  50, 254, 255

ca_collate_850 equ en_collate_850	; Catalan, CP850
ca_collate_858 equ en_collate_858	; Catalan, CP858
ca_collate_437 equ en_collate_437	; Catalan, CP437
gl_collate_850 equ en_collate_850	; Gallegan, CP850
gl_collate_858 equ en_collate_858	; Gallegan, CP858
gl_collate_437 equ en_collate_437	; Gallegan, CP437
eu_collate_850 equ en_collate_850	; Basque, CP850
eu_collate_858 equ en_collate_858	; Basque, CP858
eu_collate_437 equ en_collate_437	; Basque, CP437

de_collate_850 equ en_collate_850	; German, CP850
de_collate_858 equ en_collate_858	; German, CP858
de_collate_437 equ en_collate_437	; German, CP437

pt_collate_860 db 0FFh,"COLLATE"	; Portuguese, CP860
	       dw 256			; Derived from English CP437
db   0,	  1,   2,   3,	 4,   5,   6,	7
db   8,	  9,  10,  11,	12,  13,  14,  15
db  16,	 17,  18,  19,	20,  21,  22,  23
db  24,	 25,  26,  27,	28,  29,  30,  31
db  32,	 33,  34,  35,	36,  37,  38,  39
db  40,	 41,  42,  43,	44,  45,  46,  47
db  48,	 49,  50,  51,	52,  53,  54,  55
db  56,	 57,  58,  59,	60,  61,  62,  63
db  64,	 65,  66,  67,	68,  69,  70,  71
db  72,	 73,  74,  75,	76,  77,  78,  79
db  80,	 81,  82,  83,	84,  85,  86,  87
db  88,	 89,  90,  91,	92,  93,  94,  95
db  96,	 65,  66,  67,	68,  69,  70,  71
db  72,	 73,  74,  75,	76,  77,  78,  79
db  80,	 81,  82,  83,	84,  85,  86,  87
db  88,	 89,  90, 123, 124, 125, 126, 127
db  67,	 85,  69,  65,	65,  65,  65,  67
db  69,	 69,  69,  73,	79,  73,  65,  65
db  69,	 65,  69,  79,	79,  79,  85,  85
db  73,	 79,  85,  36,	36,  85,  36,  79
db  65,	 73,  79,  85,	78,  78, 166, 167
db  63,  79, 170, 171, 172,  33,  34,  34
db 176, 177, 178, 179, 180, 181, 182, 183
db 184, 185, 186, 187, 188, 189, 190, 191
db 192, 193, 194, 195, 196, 197, 198, 199
db 200, 201, 202, 203, 204, 205, 206, 207
db 208, 209, 210, 211, 212, 213, 214, 215
db 216, 217, 218, 219, 220, 221, 222, 223
db 224,	 83, 226, 227, 228, 229, 230, 231
db 232, 233, 234, 235, 236, 237, 238, 239
db 240, 241, 242, 243, 244, 245, 246, 247
db 248, 249, 250, 251, 252, 253, 254, 255

pt_collate_850 equ en_collate_850	; Portuguese CP850
pt_collate_858 equ en_collate_858	; Portuguese CP858
pt_collate_437 equ en_collate_437	; Portuguese CP437


fr_collate_863 db 0FFh,"COLLATE"	; French, CP863
	       dw 256			; Derived from English CP437
db   0,	  1,   2,   3,	 4,   5,   6,	7
db   8,	  9,  10,  11,	12,  13,  14,  15
db  16,	 17,  18,  19,	20,  21,  22,  23
db  24,	 25,  26,  27,	28,  29,  30,  31
db  32,	 33,  34,  35,	36,  37,  38,  39
db  40,	 41,  42,  43,	44,  45,  46,  47
db  48,	 49,  50,  51,	52,  53,  54,  55
db  56,	 57,  58,  59,	60,  61,  62,  63
db  64,	 65,  66,  67,	68,  69,  70,  71
db  72,	 73,  74,  75,	76,  77,  78,  79
db  80,	 81,  82,  83,	84,  85,  86,  87
db  88,	 89,  90,  91,	92,  93,  94,  95
db  96,	 65,  66,  67,	68,  69,  70,  71
db  72,	 73,  74,  75,	76,  77,  78,  79
db  80,	 81,  82,  83,	84,  85,  86,  87
db  88,	 89,  90, 123, 124, 125, 126, 127
db  67,	 85,  69,  65,	65,  65, 134,  67
db  69,	 69,  69,  73,	73, 141,  65, 143
db  69,	 69,  69,  79,	69,  73,  85,  85
db  36,	 79,  85,  36,	36,  85,  85,  36
db 160,	161,  79,  85, 164, 165, 166, 167
db  63, 169, 170, 171, 172, 173,  34,  34
db 176, 177, 178, 179, 180, 181, 182, 183
db 184, 185, 186, 187, 188, 189, 190, 191
db 192, 193, 194, 195, 196, 197, 198, 199
db 200, 201, 202, 203, 204, 205, 206, 207
db 208, 209, 210, 211, 212, 213, 214, 215
db 216, 217, 218, 219, 220, 221, 222, 223
db 224,	 83, 226, 227, 228, 229, 230, 231
db 232, 233, 234, 235, 236, 237, 238, 239
db 240, 241, 242, 243, 244, 245, 246, 247
db 248, 249, 250, 251, 252, 253, 254, 255

fr_collate_850 equ en_collate_850	; French, CP850
fr_collate_858 equ en_collate_858	; French, CP858
fr_collate_437 equ en_collate_437	; French, CP437

it_collate_850 equ en_collate_850	; Italian, CP850
it_collate_858 equ en_collate_858	; Italian, CP858
it_collate_437 equ en_collate_437	; Italian, CP437

nl_collate_850 equ en_collate_850	; Dutch, CP850
nl_collate_858 equ en_collate_858	; Dutch, CP858
nl_collate_437 equ en_collate_437	; Dutch, CP437

be_collate_850 equ en_collate_850	; Belgium, CP850
be_collate_858 equ en_collate_858	; Belgium, CP858
be_collate_437 equ en_collate_437	; Belgium, CP437

tr_collate_857 db 0FFh,"COLLATE"	; Turkish, CP857 (with Euro)
	       dw 256
db   0,	  1,   2,   3,	 4,   5,   6,	7
db   8,	  9,  10,  11,	12,  13,  14,  15
db  16,	 17,  18,  19,	20,  21,  22,  23
db  24,	 25,  26,  27,	28,  29,  30,  31
db  32,	 33,  34,  35,	36,  37,  38,  39
db  40,	 41,  42,  43,	44,  45,  46,  47
db  48,	 49,  50,  51,	52,  53,  54,  55
db  56,	 57,  58,  59,	60,  61,  62,  63
db  64,  65,  66,  67,  69,  70,  71,  72
db  74,  75,  77,  78,  79,  80,  81,  82
db  84,  85,  86,  87,  89,  90,  92,  93
db  94,  95,  96,  97,  98,  99, 100, 101
db 102,  65,  66,  67,  69,  70,  71,  72
db  74,  76,  77,  78,  79,  80,  81,  82
db  84,  85,  86,  87,  89,  90,  92,  93
db  94,  95,  96, 123, 124, 125, 126, 127
db  68,  91,  70,  65,  65,  65,  65,  68
db  70,  70,  70,  76,  76,  75,  65,  65
db  70, 145, 145,  82,  83,  82,  90,  90
db  76,  83,  91, 155,  36, 155,  88,  88
db  65,  76,  82,  90,  81,  81,  73,  73
db  63, 169, 170, 171, 172,  33,  34,  34
db 176, 177, 178, 179, 180,  65,  65,  65
db 184, 185, 186, 187, 188,  36,  36, 191
db 192, 193, 194, 195, 196, 197,  65,  65
db 200, 201, 202, 203, 204, 205, 206,  36
db  82,  65,  70,  70,  70,  36,  76,  76
db  76, 217, 218, 219, 220, 221,  76, 223
db  82, 225,  82,  82,  82,  82, 230,  32
db 232,  90,  90,  90,  76,  95, 238, 239
db 240, 241,  32, 243, 244, 245, 246, 247
db 248, 249, 250,  49,  51,  50, 254, 255

tr_collate_850 db 0FFh,"COLLATE"	; Turkish, CP850
        dw 256
db   0,   1,   2,   3,   4,   5,   6,   7
db   8,   9,  10,  11,  12,  13,  14,  15
db  16,  17,  18,  19,  20,  21,  22,  23
db  24,  25,  26,  27,  28,  29,  30,  31
db  32,  33,  34,  35,  36,  37,  38,  39
db  40,  41,  42,  43,  44,  45,  46,  47
db  48,  49,  50,  51,  52,  53,  54,  55
db  56,  57,  58,  59,  60,  61,  62,  63
db  64,  65,  66,  67,  69,  70,  71,  72
db  74,  75,  77,  78,  79,  80,  81,  82
db  84,  85,  86,  87,  89,  90,  92,  93
db  94,  95,  96,  97,  98,  99, 100, 101
db 102,  65,  66,  67,  69,  70,  71,  72
db  74,  76,  77,  78,  79,  80,  81,  82
db  84,  85,  86,  87,  89,  90,  92,  93
db  94,  95,  96, 123, 124, 125, 126, 127
db  68,  91,  70,  65,  65,  65,  65,  68
db  70,  70,  70,  76,  76,  76,  65,  65
db  70, 145, 145,  82,  83,  82,  90,  90
db  95,  83,  91, 155,  36, 155,  36,  36
db  65,  76,  82,  90,  81,  81,  65,  82
db  63, 169, 170, 171, 172,  33,  34,  34
db 176, 177, 178, 179, 180,  65,  65,  65
db 184, 185, 186, 187, 188,  36,  36, 191
db 192, 193, 194, 195, 196, 197,  65,  65
db 200, 201, 202, 203, 204, 205, 206,  36
db 209, 209,  70,  70,  70,  75,  76,  76
db  76, 217, 218, 219, 220, 221,  76, 223
db  82, 225,  82,  82,  82,  82, 230, 231
db 231,  90,  90,  90,  95,  95, 238, 239
db 240, 241, 242, 243, 244, 245, 246, 247
db 248, 249, 250,  49,  51,  50, 254, 255

tr_collate_858 equ tr_collate_850

dk_collate_865 db 0FFh,"COLLATE"		; Danish, CP865
	       dw 256
db   0,   1,   2,   3,   4,   5,   6,   7
db   8,   9,  10,  11,  12,  13,  14,  15
db  16,  17,  18,  19,  20,  21,  22,  23
db  24,  25,  26,  27,  28,  29,  30,  31
db  32,  33,  34,  35,  36,  37,  38,  39
db  40,  41,  42,  43,  44,  45,  46,  47
db  48,  49,  50,  51,  52,  53,  54,  55
db  56,  57,  58,  59,  60,  61,  62,  63
db  64,  65,  66,  67,  68,  69,  70,  71
db  72,  73,  74,  75,  76,  77,  78,  79
db  80,  81,  82,  83,  84,  85,  86,  86
db  87,  88,  89,  93,  94,  95,  96,  97
db  98,  65,  66,  67,  68,  69,  70,  71
db  72,  73,  74,  75,  76,  77,  78,  79
db  80,  81,  82,  83,  84,  85,  86,  86
db  87,  88,  89, 123, 124, 125, 126, 127
db  67,  85,  69,  65,  65,  65,  92,  67
db  69,  69,  69,  73,  73,  73,  65,  92
db  69,  90,  90,  79,  79,  79,  85,  85
db  88,  79,  85,  91,  36,  91,  36,  36
db  65,  73,  79,  85,  78,  78,  65,  79
db  63, 169, 170, 171, 172,  33,  34,  36
db 176, 177, 178, 179, 180, 181, 182, 183
db 184, 185, 186, 187, 188, 189, 190, 191
db 192, 193, 194, 195, 196, 197, 198, 199
db 200, 201, 202, 203, 204, 205, 206, 207
db 208, 209, 210, 211, 212, 213, 214, 215
db 216, 217, 218, 219, 220, 221, 222, 223
db 224,  83, 226, 227, 228, 229, 230, 231
db 232, 233, 234, 235, 236, 237, 238, 239
db 240, 241, 242, 243, 244, 245, 246, 247
db 248, 249, 250, 251,  78,  50, 254, 255

dk_collate_850 db 0FFh,"COLLATE"		; Danish, CP850
	       dw 256
db   0,   1,   2,   3,   4,   5,   6,   7
db   8,   9,  10,  11,  12,  13,  14,  15
db  16,  17,  18,  19,  20,  21,  22,  23
db  24,  25,  26,  27,  28,  29,  30,  31
db  32,  33,  34,  35,  36,  37,  38,  39
db  40,  41,  42,  43,  44,  45,  46,  47
db  48,  49,  50,  51,  52,  53,  54,  55
db  56,  57,  58,  59,  60,  61,  62,  63
db  64,  65,  66,  67,  68,  69,  70,  71
db  72,  73,  74,  75,  76,  77,  78,  79
db  80,  81,  82,  83,  84,  85,  86,  86
db  87,  88,  89,  93,  94,  95,  96,  97
db  98,  65,  66,  67,  68,  69,  70,  71
db  72,  73,  74,  75,  76,  77,  78,  79
db  80,  81,  82,  83,  84,  85,  86,  86
db  87,  88,  89, 123, 124, 125, 126, 127
db  67,  85,  69,  65,  65,  65,  92,  67
db  69,  69,  69,  73,  73,  73,  65,  92
db  69,  90,  90,  79,  79,  79,  85,  85
db  88,  79,  85,  91,  36,  91,  36,  36
db  65,  73,  79,  85,  78,  78,  65,  79
db  63, 169, 170, 171, 172,  33,  34,  34
db 176, 177, 178, 179, 180,  65,  65,  65
db 169, 185, 186, 187, 188,  36,  36, 191
db 192, 193, 194, 195, 196, 197,  65,  65
db 200, 201, 202, 203, 204, 205, 206,  36
db  68,  68,  69,  69,  69,  73,  73,  73
db  73, 217, 218, 219, 220, 221,  73, 223
db  79,  83,  79,  79,  79,  79, 230, 231
db 232,  85,  85,  85,  88,  88, 238, 239
db 240, 241, 242, 243, 244, 245, 246, 247
db 248, 249, 250,  49,  51,  50, 254, 255

dk_collate_858 db 0FFh,"COLLATE"		; Danish, CP858
	       dw 256
db   0,   1,   2,   3,   4,   5,   6,   7
db   8,   9,  10,  11,  12,  13,  14,  15
db  16,  17,  18,  19,  20,  21,  22,  23
db  24,  25,  26,  27,  28,  29,  30,  31
db  32,  33,  34,  35,  36,  37,  38,  39
db  40,  41,  42,  43,  44,  45,  46,  47
db  48,  49,  50,  51,  52,  53,  54,  55
db  56,  57,  58,  59,  60,  61,  62,  63
db  64,  65,  66,  67,  68,  69,  70,  71
db  72,  73,  74,  75,  76,  77,  78,  79
db  80,  81,  82,  83,  84,  85,  86,  86
db  87,  88,  89,  93,  94,  95,  96,  97
db  98,  65,  66,  67,  68,  69,  70,  71
db  72,  73,  74,  75,  76,  77,  78,  79
db  80,  81,  82,  83,  84,  85,  86,  86
db  87,  88,  89, 123, 124, 125, 126, 127
db  67,  85,  69,  65,  65,  65,  92,  67
db  69,  69,  69,  73,  73,  73,  65,  92
db  69,  90,  90,  79,  79,  79,  85,  85
db  88,  79,  85,  91,  36,  91,  36,  36
db  65,  73,  79,  85,  78,  78,  65,  79
db  63, 169, 170, 171, 172,  33,  34,  34
db 176, 177, 178, 179, 180,  65,  65,  65
db 169, 185, 186, 187, 188,  36,  36, 191
db 192, 193, 194, 195, 196, 197,  65,  65
db 200, 201, 202, 203, 204, 205, 206,  36
db  68,  68,  69,  69,  69,  36,  73,  73
db  73, 217, 218, 219, 220, 221,  73, 223
db  79,  83,  79,  79,  79,  79, 230, 231
db 232,  85,  85,  85,  88,  88, 238, 239
db 240, 241, 242, 243, 244, 245, 246, 247
db 248, 249, 250,  49,  51,  50, 254, 255

no_collate_865 equ dk_collate_865	; Norwegian CP865
no_collate_850 equ dk_collate_850	; Norwegian CP850
no_collate_858 equ dk_collate_858	; Norwegian CP858

ru_collate_866 db 0FFh,"COLLATE"	; Russian, CP866
	       dw 256
db   0,	  1,   2,   3,	 4,   5,   6,	7
db   8,	  9,  10,  11,	12,  13,  14,  15
db  16,	 17,  18,  19,	20,  21,  22,  23
db  24,	 25,  26,  27,	28,  29,  30,  31
db  32,	 33,  34,  35,	36,  37,  38,  39
db  40,	 41,  42,  43,	44,  45,  46,  47
db  48,	 49,  50,  51,	52,  53,  54,  55
db  56,	 57,  58,  59,	60,  61,  62,  63
db  64,	 65,  66,  67,	68,  69,  70,  71
db  72,	 73,  74,  75,	76,  77,  78,  79
db  80,	 81,  82,  83,	84,  85,  86,  87
db  88,	 89,  90,  91,	92,  93,  94,  95
db  96,	 65,  66,  67,	68,  69,  70,  71
db  72,	 73,  74,  75,	76,  77,  78,  79
db  80,	 81,  82,  83,	84,  85,  86,  87
db  88,	 89,  90, 123, 124, 125, 126, 127
db 128, 129, 130, 131, 132, 135, 137, 138
db 140, 143, 145, 146, 148, 149, 151, 152
db 153, 154, 155, 158, 160, 161, 162, 163
db 165, 166, 167, 168, 169, 170, 171, 172
db 128, 129, 130, 131, 132, 135, 137, 138
db 140, 143, 145, 146, 148, 149, 151, 152
db 176, 177, 178, 179, 180, 181, 182, 183
db 184, 185, 186, 187, 188, 189, 190, 191
db 192, 193, 194, 195, 196, 197, 198, 199
db 200, 201, 202, 203, 204, 205, 206, 207
db 208, 209, 210, 211, 212, 213, 214, 215
db 216, 217, 218, 219, 220, 221, 222, 223
db 153, 154, 155, 158, 160, 161, 162, 163
db 165, 166, 167, 168, 169, 170, 171, 172
db 135, 135, 136, 136, 142, 142, 159, 159
db 248, 249, 250, 251, 252,  36, 254, 255

ru_collate_808 equ ru_collate_866	; Russian, CP808

ru_collate_852 db 0FFh,"COLLATE" 	; Russian, CP852 (with Euro)
               dw 256
db   0,	  1,   2,   3,	 4,   5,   6,	7
db   8,	  9,  10,  11,	12,  13,  14,  15
db  16,	 17,  18,  19,	20,  21,  22,  23
db  24,	 25,  26,  27,	28,  29,  30,  31
db  32,	 33,  34,  35,	36,  37,  38,  39
db  40,	 41,  42,  43,	44,  45,  46,  47
db  48,	 49,  50,  51,	52,  53,  54,  55
db  56,	 57,  58,  59,	60,  61,  62,  63
db  64,  65,  68,  69,  72,  74,  76,  77
db  78,  79,  81,  82,  83,  85,  86,  88
db  92,  93,  94,  96, 100, 102, 105, 106
db 107, 108, 109, 114, 115, 116, 117, 118
db 119,  65,  68,  69,  72,  74,  76,  77
db  78,  79,  81,  82,  83,  85,  86,  88
db  92,  93,  94,  96, 100, 102, 105, 106
db 107, 108, 109, 123, 124, 125, 126, 127
db  69, 103,  74,  65,  65, 102,  71,  69
db  84,  74,  91,  91,  80, 111,  65,  71
db  74,  83,  83,  88,  90,  83,  83,  98
db  98,  90, 103, 101, 101,  84,  36,  70
db  65,  79,  88, 102,  67,  67, 110, 110
db  75,  75,  36, 111,  70,  99,  34,  34
db 176, 177, 178, 179, 180,  65,  65,  74
db  99, 185, 186, 187, 188, 112, 112, 191
db 192, 193, 194, 195, 196, 197,  66,  66
db 200, 201, 202, 203, 204, 205, 206,  36
db  73,  73,  72,  74,  72,  86,  79,  80
db  74, 217, 218, 219, 220, 113, 102, 223
db  88, 225,  88,  87,  87,  86,  97,  97
db  94, 102,  94, 104, 108, 108, 113, 239
db 240, 241, 242, 243, 244, 245, 246, 247
db 248, 249, 250, 104,  95,  95, 254, 255

pl_collate_852 db 0FFh,"COLLATE" 	; Polish, CP852 (with Euro)
               dw 256
db   0,	  1,   2,   3,	 4,   5,   6,	7
db   8,	  9,  10,  11,	12,  13,  14,  15
db  16,	 17,  18,  19,	20,  21,  22,  23
db  24,	 25,  26,  27,	28,  29,  30,  31
db  32,	 33,  34,  35,	36,  37,  38,  39
db  40,	 41,  42,  43,	44,  45,  46,  47
db  48,	 49,  50,  51,	52,  53,  54,  55
db  56,	 57,  58,  59,	60,  61,  62,  63
db  64,  65,  68,  69,  72,  74,  76,  77
db  78,  79,  81,  82,  83,  85,  86,  88
db  92,  93,  94,  96, 100, 102, 105, 106
db 107, 108, 109, 114, 115, 116, 117, 118
db 119,  65,  68,  69,  72,  74,  76,  77
db  78,  79,  81,  82,  83,  85,  86,  88
db  92,  93,  94,  96, 100, 102, 105, 106
db 107, 108, 109, 123, 124, 125, 126, 127
db  69, 103,  74,  65,  65, 102,  71,  69
db  84,  74,  91,  91,  80, 111,  65,  71
db  74,  83,  83,  88,  90,  83,  83,  98
db  98,  90, 103, 101, 101,  84,  36,  70
db  65,  79,  89, 102,  67,  67, 110, 110
db  75,  75,  36, 111,  70,  99,  34,  34
db 176, 177, 178, 179, 180,  65,  65,  74
db  99, 185, 186, 187, 188, 112, 112, 191
db 192, 193, 194, 195, 196, 197,  66,  66
db 200, 201, 202, 203, 204, 205, 206,  36
db  73,  73,  72,  74,  72,  86,  79,  80
db  74, 217, 218, 219, 220, 113, 102, 223
db  89, 225,  88,  87,  87,  86,  97,  97
db  94, 102,  94, 104, 108, 108, 113, 239
db 240, 241, 242, 243, 244, 245, 246, 247
db 248, 249, 250, 104,  95,  95, 254, 255

pl_collate_850 db 0FFh,"COLLATE"		; Polish, CP850
	       dw 256
db   0,	  1,   2,   3,	 4,   5,   6,	7
db   8,	  9,  10,  11,	12,  13,  14,  15
db  16,	 17,  18,  19,	20,  21,  22,  23
db  24,	 25,  26,  27,	28,  29,  30,  31
db  32,	 33,  34,  35,	36,  37,  38,  39
db  40,	 41,  42,  43,	44,  45,  46,  47
db  48,	 49,  50,  51,	52,  53,  54,  55
db  56,	 57,  58,  59,	60,  61,  62,  63
db  64,	 65,  66,  67,	68,  69,  70,  71
db  72,	 73,  74,  75,	76,  77,  78,  79
db  80,	 81,  82,  83,	84,  85,  86,  87
db  88,	 89,  90,  91,	92,  93,  94,  95
db  96,	 65,  66,  67,	68,  69,  70,  71
db  72,	 73,  74,  75,	76,  77,  78,  79
db  80,	 81,  82,  83,	84,  85,  86,  87
db  88,	 89,  90, 123, 124, 125, 126, 127
db  67,	 85,  69,  65,	65,  65,  65,  67
db  69,	 69,  69,  73,	73,  73,  65,  65
db  69,	 65,  65,  79,	79,  79,  85,  85
db  89,	 79,  85,  36,	36,  36,  36,  36
db  65,	 73,  79,  85,	78,  78, 166, 167
db  63, 169, 170, 171, 172,  33,  34,  34
db 176, 177, 178, 179, 180,  65,  65,  65
db 184, 185, 186, 187, 188,  36,  36, 191
db 192, 193, 194, 195, 196, 197,  65,  65
db 200, 201, 202, 203, 204, 205, 206,  36
db  68,	 68,  69,  69,	69,  73,  73,  73
db  73, 217, 218, 219, 220, 221,  73, 223
db  79,	 66,  79,  79,	79,  79, 230,  97
db  97,	 85,  85,  85,	89,  89, 238, 239
db 240, 241, 242, 243, 244, 245, 246, 247
db 248, 249, 250,  49,	51,  50, 254, 255

pl_collate_858 db 0FFh,"COLLATE"		; Polish, CP858
	       dw 256
db   0,	  1,   2,   3,	 4,   5,   6,	7
db   8,	  9,  10,  11,	12,  13,  14,  15
db  16,	 17,  18,  19,	20,  21,  22,  23
db  24,	 25,  26,  27,	28,  29,  30,  31
db  32,	 33,  34,  35,	36,  37,  38,  39
db  40,	 41,  42,  43,	44,  45,  46,  47
db  48,	 49,  50,  51,	52,  53,  54,  55
db  56,	 57,  58,  59,	60,  61,  62,  63
db  64,	 65,  66,  67,	68,  69,  70,  71
db  72,	 73,  74,  75,	76,  77,  78,  79
db  80,	 81,  82,  83,	84,  85,  86,  87
db  88,	 89,  90,  91,	92,  93,  94,  95
db  96,	 65,  66,  67,	68,  69,  70,  71
db  72,	 73,  74,  75,	76,  77,  78,  79
db  80,	 81,  82,  83,	84,  85,  86,  87
db  88,	 89,  90, 123, 124, 125, 126, 127
db  67,	 85,  69,  65,	65,  65,  65,  67
db  69,	 69,  69,  73,	73,  73,  65,  65
db  69,	 65,  65,  79,	79,  79,  85,  85
db  89,	 79,  85,  36,	36,  36,  36,  36
db  65,	 73,  79,  85,	78,  78, 166, 167
db  63, 169, 170, 171, 172,  33,  34,  34
db 176, 177, 178, 179, 180,  65,  65,  65
db 184, 185, 186, 187, 188,  36,  36, 191
db 192, 193, 194, 195, 196, 197,  65,  65
db 200, 201, 202, 203, 204, 205, 206,  36
db  68,	 68,  69,  69,	69,  36,  73,  73
db  73, 217, 218, 219, 220, 221,  73, 223
db  79,	 66,  79,  79,	79,  79, 230,  97
db  97,	 85,  85,  85,	89,  89, 238, 239
db 240, 241, 242, 243, 244, 245, 246, 247
db 248, 249, 250,  49,	51,  50, 254, 255

ru_collate_855 db 0FFh,"COLLATE"	; Russian, CP855
	       dw 256
db   0,	  1,   2,   3,	 4,   5,   6,	7
db   8,	  9,  10,  11,	12,  13,  14,  15
db  16,	 17,  18,  19,	20,  21,  22,  23
db  24,	 25,  26,  27,	28,  29,  30,  31
db  32,	 33,  34,  35,	36,  37,  38,  39
db  40,	 41,  42,  43,	44,  45,  46,  47
db  48,	 49,  50,  51,	52,  53,  54,  55
db  56,	 57,  58,  59,	60,  61,  62,  63
db  64,	 65,  66,  67,	68,  69,  70,  71
db  72,	 73,  74,  75,	76,  77,  78,  79
db  80,	 81,  82,  83,	84,  85,  86,  87
db  88,	 89,  90,  91,	92,  93,  94,  95
db  96,	 65,  66,  67,	68,  69,  70,  71
db  72,	 73,  74,  75,	76,  77,  78,  79
db  80,	 81,  82,  83,	84,  85,  86,  87
db  88,	 89,  90, 123, 124, 125, 126, 127
db 133, 133, 134, 134, 135, 135, 136, 136
db 139, 139, 141, 141, 142, 142, 144, 144
db 147, 147, 150, 150, 156, 156, 157, 157
db 159, 159, 164, 164, 171, 171, 167, 167
db 128, 128, 129, 129, 162, 162, 132, 132
db 135, 135, 160, 160, 131, 131,  34,  34
db 176, 177, 178, 179, 180, 161, 161, 140
db 140, 185, 186, 187, 188, 143, 143, 191
db 192, 193, 194, 195, 196, 197, 145, 145
db 200, 201, 202, 203, 204, 205, 206,  36
db 146, 146, 148, 148, 149, 149, 151, 151
db 152, 217, 218, 219, 220, 152, 172, 223
db 172, 153, 153, 154, 154, 155, 155, 158
db 158, 137, 137, 130, 130, 169, 169, 239
db 240, 168, 168, 138, 138, 165, 165, 170
db 170, 166, 166, 163, 163, 253, 254, 255

ru_collate_872 equ ru_collate_855	; Russian CP872
ru_collate_850 equ en_collate_850	; Russian CP850
ru_collate_858 equ en_collate_858	; Russian CP858
ru_collate_437 equ en_collate_437	; Russian CP437

gr_collate_869 db 0FFh,"COLLATE"	; Greek, CP869 (with Euro)
	       dw 256
db   0,   1,   2,   3,   4,   5,   6,   7
db   8,   9,  10,  11,  12,  13,  14,  15
db  16,  17,  18,  19,  20,  21,  22,  23
db  24,  25,  26,  27,  28,  29,  30,  31
db  32,  33,  34,  35,  36,  37,  38,  39
db  40,  41,  42,  43,  44,  45,  46,  47
db  48,  49,  50,  51,  52,  53,  54,  55
db  56,  57,  58,  59,  60,  61,  62,  63
db  64, 117, 118, 119, 120, 121, 122, 123
db 124, 125, 126, 127, 128, 129, 130, 131
db 132, 133, 134, 135, 136, 137, 138, 139
db 140, 141, 142,  65,  66,  67,  68,  69
db  70, 117, 118, 119, 120, 121, 122, 123
db 124, 125, 126, 127, 128, 129, 130, 131
db 132, 133, 134, 135, 136, 137, 138, 139
db 140, 141, 142,  71,  72,  73,  74,  75
db  76,  77,  78,  79,  80,  81,  89,  36
db  88,  83,  84,  85,  86,  93,  87,  95
db  97,  97, 103, 147, 148, 108, 108, 151
db 112,  50,  51,  89,  36,  93,  95,  97
db  97,  97, 103, 108,  89,  90,  91,  92
db  93,  94,  95, 171,  96,  97, 174, 175
db 176, 177, 178, 179, 180,  98,  99, 100
db 101, 185, 186, 187, 188, 102, 103, 191
db 192, 193, 194, 195, 196, 197, 104, 105
db 200, 201, 202, 203, 204, 205, 206, 106
db 107, 108, 109, 110, 111, 112,  89,  90
db  91, 217, 218, 219, 220,  92,  93, 223
db  94,  95,  96,  97,  98,  99, 100, 101
db 102, 103, 104, 105, 106, 106, 107, 113
db 240, 241, 108, 109, 110, 245, 111, 114
db 115, 116, 112, 108, 108, 112, 254, 255

gr_collate_737 db 0FFh,"COLLATE"	; Greek, CP737
	       dw 256
db   0,   1,   2,   3,   4,   5,   6,   7
db   8,   9,  10,  11,  12,  13,  14,  15
db  16,  17,  18,  19,  20,  21,  22,  23
db  24,  25,  26,  27,  28,  29,  30,  31
db  32,  33,  34,  35,  36,  37,  38,  39
db  40,  41,  42,  43,  44,  45,  46,  47
db  48,  49,  50,  51,  52,  53,  54,  55
db  56,  57,  58,  59,  60,  61,  62,  63
db  64, 100, 101, 102, 103, 104, 105, 106
db 107, 108, 109, 110, 111, 112, 113, 114
db 115, 116, 117, 118, 119, 120, 121, 122
db 123, 124, 125,  65,  66,  67,  68,  69
db  70, 100, 101, 102, 103, 104, 105, 106
db 107, 108, 109, 110, 111, 112, 113, 114
db 115, 116, 117, 118, 119, 120, 121, 122
db 123, 124, 125,  71,  72,  73,  74,  75
db  76,  77,  78,  79,  80,  81,  82,  83
db  84,  85,  86,  87,  88,  89,  90,  91
db  92,  93,  94,  95,  96,  97,  98,  99
db  76,  77,  78,  79,  80,  81,  82,  83
db  84,  85,  86,  87,  88,  89,  90,  91
db  92,  93,  93,  94,  95,  96,  97,  98
db 176, 177, 178, 179, 180, 181, 182, 183
db 184, 185, 186, 187, 188, 189, 190, 191
db 192, 193, 194, 195, 196, 197, 198, 199
db 200, 201, 202, 203, 204, 205, 206, 207
db 208, 209, 210, 211, 212, 213, 214, 215
db 216, 217, 218, 219, 220, 221, 222, 223
db  99,  76,  80,  82,  84,  84,  90,  95
db  95,  99,  76,  80,  82,  84,  90,  95
db  99, 241, 242, 243,  84,  95, 246, 247
db 248, 249, 250, 251, 252, 253, 254, 255

gr_collate_850 equ pl_collate_850	; Polish, CP850
gr_collate_858 equ pl_collate_858	; Polish, CP858

hu_collate_852 equ ru_collate_852	; Hungarian, CP852
hu_collate_850 equ pl_collate_850	; Hungarian, CP850
hu_collate_858 equ pl_collate_858	; Hungarian, CP858

sh_collate_852 equ ru_collate_852	; Serbo-Croatian, CP852
sh_collate_855 equ ru_collate_855	; Serbo-Croatian, CP855
sh_collate_872 equ ru_collate_872	; Serbo-Croatian, CP872
sh_collate_850 equ pl_collate_850	; Serbo-Croatian, CP850
sh_collate_858 equ gr_collate_858	; Serbo-Croatian, CP858

ro_collate_852 equ ru_collate_852	; Romanian, CP852
ro_collate_850 equ pl_collate_850	; Romanian, CP850
ro_collate_858 equ gr_collate_858	; Romanian, CP858

ch_collate_850 equ en_collate_850	; Switzerland, CP850
ch_collate_858 equ en_collate_858	; Switzerland, CP858
ch_collate_437 equ en_collate_437	; Switzerland, CP437

cz_collate_852 equ ru_collate_852	; Czech, CP852
cz_collate_850 equ pl_collate_850	; Czech, CP850
cz_collate_858 equ gr_collate_858	; Czech, CP858

sk_collate_852 equ cz_collate_852	; Slovakia, CP852
sk_collate_850 equ cz_collate_850	; Slovakia, CP850
sk_collate_858 equ cz_collate_858	; Slovakia, CP858

se_collate_850 db 0FFh,"COLLATE"	; Swedish, CP850
	       dw 256
db   0,   1,   2,   3,   4,   5,   6,   7
db   8,   9,  10,  11,  12,  13,  14,  15
db  16,  17,  18,  19,  20,  21,  22,  23
db  24,  25,  26,  27,  28,  29,  30,  31
db  32,  33,  34,  35,  36,  37,  38,  39
db  40,  41,  42,  43,  44,  45,  46,  47
db  48,  49,  50,  51,  52,  53,  54,  55
db  56,  57,  58,  59,  60,  61,  62,  63
db  64,  65,  66,  67,  68,  69,  70,  71
db  72,  73,  74,  75,  76,  77,  78,  79
db  80,  81,  82,  83,  84,  85,  86,  86
db  87,  88,  89,  93,  94,  95,  96,  97
db  98,  65,  66,  67,  68,  69,  70,  71
db  72,  73,  74,  75,  76,  77,  78,  79
db  80,  81,  82,  83,  84,  85,  86,  86
db  87,  88,  89, 123, 124, 125, 126, 127
db  67,  88,  69,  65,  91,  65,  90,  67
db  69,  69,  69,  73,  73,  73,  91,  90
db  69,  65,  65,  79,  92,  79,  85,  85
db  88,  92,  88,  79,  36,  79,  36,  36
db  65,  73,  79,  85,  78,  78,  65,  79
db  63, 169, 170, 171, 172,  33,  34,  34
db 176, 177, 178, 179, 180,  65,  65,  65
db 169, 185, 186, 187, 188,  36,  36, 191
db 192, 193, 194, 195, 196, 197,  65,  65
db 200, 201, 202, 203, 204, 205, 206,  36
db  68,  68,  69,  69,  69,  73,  73,  73
db  73, 217, 218, 219, 220, 221,  73, 223
db  79,  83,  79,  79,  79,  79, 230, 231
db 232,  85,  85,  85,  88,  88, 238, 239
db 240, 241, 242, 243, 244, 245, 246, 247
db 248, 249, 250,  49,  51,  50, 254, 255

se_collate_858 db 0FFh,"COLLATE"	; Swedish, CP858
	       dw 256
db   0,   1,   2,   3,   4,   5,   6,   7
db   8,   9,  10,  11,  12,  13,  14,  15
db  16,  17,  18,  19,  20,  21,  22,  23
db  24,  25,  26,  27,  28,  29,  30,  31
db  32,  33,  34,  35,  36,  37,  38,  39
db  40,  41,  42,  43,  44,  45,  46,  47
db  48,  49,  50,  51,  52,  53,  54,  55
db  56,  57,  58,  59,  60,  61,  62,  63
db  64,  65,  66,  67,  68,  69,  70,  71
db  72,  73,  74,  75,  76,  77,  78,  79
db  80,  81,  82,  83,  84,  85,  86,  86
db  87,  88,  89,  93,  94,  95,  96,  97
db  98,  65,  66,  67,  68,  69,  70,  71
db  72,  73,  74,  75,  76,  77,  78,  79
db  80,  81,  82,  83,  84,  85,  86,  86
db  87,  88,  89, 123, 124, 125, 126, 127
db  67,  88,  69,  65,  91,  65,  90,  67
db  69,  69,  69,  73,  73,  73,  91,  90
db  69,  65,  65,  79,  92,  79,  85,  85
db  88,  92,  88,  79,  36,  79,  36,  36
db  65,  73,  79,  85,  78,  78,  65,  79
db  63, 169, 170, 171, 172,  33,  34,  34
db 176, 177, 178, 179, 180,  65,  65,  65
db 169, 185, 186, 187, 188,  36,  36, 191
db 192, 193, 194, 195, 196, 197,  65,  65
db 200, 201, 202, 203, 204, 205, 206,  36
db  68,  68,  69,  69,  69,  36,  73,  73
db  73, 217, 218, 219, 220, 221,  73, 223
db  79,  83,  79,  79,  79,  79, 230, 231
db 232,  85,  85,  85,  88,  88, 238, 239
db 240, 241, 242, 243, 244, 245, 246, 247
db 248, 249, 250,  49,  51,  50, 254, 255

se_collate_437 db 0FFh,"COLLATE"	; Swedish, CP437
	       dw 256
db   0,   1,   2,   3,   4,   5,   6,   7
db   8,   9,  10,  11,  12,  13,  14,  15
db  16,  17,  18,  19,  20,  21,  22,  23
db  24,  25,  26,  27,  28,  29,  30,  31
db  32,  33,  34,  35,  36,  37,  38,  39
db  40,  41,  42,  43,  44,  45,  46,  47
db  48,  49,  50,  51,  52,  53,  54,  55
db  56,  57,  58,  59,  60,  61,  62,  63
db  64,  65,  66,  67,  68,  69,  70,  71
db  72,  73,  74,  75,  76,  77,  78,  79
db  80,  81,  82,  83,  84,  85,  86,  86
db  87,  88,  89,  93,  94,  95,  96,  97
db  98,  65,  66,  67,  68,  69,  70,  71
db  72,  73,  74,  75,  76,  77,  78,  79
db  80,  81,  82,  83,  84,  85,  86,  86
db  87,  88,  89, 123, 124, 125, 126, 127
db  67,  88,  69,  65,  91,  65,  90,  67
db  69,  69,  69,  73,  73,  73,  91,  90
db  69,  65,  65,  79,  92,  79,  85,  85
db  88,  92,  88,  36,  36,  36,  36,  36
db  65,  73,  79,  85,  78,  78,  65,  79
db  63, 169, 170, 171, 172,  33,  34,  34
db 176, 177, 178, 179, 180, 181, 182, 183
db 184, 185, 186, 187, 188, 189, 190, 191
db 192, 193, 194, 195, 196, 197, 198, 199
db 200, 201, 202, 203, 204, 205, 206, 207
db 208, 209, 210, 211, 212, 213, 214, 215
db 216, 217, 218, 219, 220, 221, 222, 223
db 224,  83, 226, 227, 228, 229, 230, 231
db 232, 233, 234, 235, 236, 237, 238, 239
db 240, 241, 242, 243, 244, 245, 246, 247
db 248, 249, 250, 251,  78,  50, 254, 255

se_collate_865 equ se_collate_437

fi_collate_865 equ se_collate_865	; Finnish, CP865
fi_collate_850 equ se_collate_850	; Finnish, CP850
fi_collate_858 equ se_collate_858	; Finnish, CP858
fi_collate_437 equ se_collate_437	; Finnish, CP437

jp_collate_932 db 0FFh,"COLLATE"	; Japanese, CP932
	       dw 256
db   0,	  1,   2,   3,	 4,   5,   6,	7
db   8,	  9,  10,  11,	12,  13,  14,  15
db  16,	 17,  18,  19,	20,  21,  22,  23
db  24,	 25,  26,  27,	28,  29,  30,  31
db  32,	 33,  34,  35,	36,  37,  38,  39
db  40,	 41,  42,  43,	44,  45,  46,  47
db  48,	 49,  50,  51,	52,  53,  54,  55
db  56,	 57,  58,  59,	60,  61,  62,  63
db  64,	 65,  66,  67,	68,  69,  70,  71
db  72,	 73,  74,  75,	76,  77,  78,  79
db  80,	 81,  82,  83,	84,  85,  86,  87
db  88,	 89,  90,  91,	36,  93,  94,  95
db  96,	 65,  66,  67,	68,  69,  70,  71
db  72,	 73,  74,  75,	76,  77,  78,  79
db  80,	 81,  82,  83,	84,  85,  86,  87
db  88,	 89,  90, 123, 124, 125, 126, 127
db 128, 183, 184, 185, 186, 187, 188, 189
db 190, 191, 192, 193, 194, 195, 196, 197
db 198, 199, 200, 201, 202, 203, 204, 205
db 206, 207, 208, 209, 210, 211, 212, 213
db 129, 130, 131, 132, 133, 136, 182, 138
db 139, 140, 141, 142, 173, 174, 175, 155
db 137, 138, 139, 140, 141, 142, 143, 144
db 145, 146, 147, 148, 149, 150, 151, 152
db 153, 154, 155, 156, 157, 158, 159, 160
db 161, 162, 163, 164, 165, 166, 167, 168
db 168, 170, 171, 172, 173, 174, 175, 176
db 177, 178, 179, 180, 181, 182, 134, 135
db 224, 225, 226, 227, 228, 229, 230, 231
db 232, 233, 234, 235, 236, 237, 238, 239
db 240, 241, 242, 243, 244, 245, 246, 247
db 248, 249, 250, 251, 252, 253, 254, 255

kr_collate_934 db 0FFh,"COLLATE"	; Korean, CP934
	       dw 256
db   0,	  1,   2,   3,	 4,   5,   6,	7
db   8,	  9,  10,  11,	12,  13,  14,  15
db  16,	 17,  18,  19,	20,  21,  22,  23
db  24,	 25,  26,  27,	28,  29,  30,  31
db  32,	 33,  34,  35,	36,  37,  38,  39
db  40,	 41,  42,  43,	44,  45,  46,  47
db  48,	 49,  50,  51,	52,  53,  54,  55
db  56,	 57,  58,  59,	60,  61,  62,  63
db  64,	 65,  66,  67,	68,  69,  70,  71
db  72,	 73,  74,  75,	76,  77,  78,  79
db  80,	 81,  82,  83,	84,  85,  86,  87
db  88,	 89,  90,  91,	36,  93,  94,  95
db  96,	 65,  66,  67,	68,  69,  70,  71
db  72,	 73,  74,  75,	76,  77,  78,  79
db  80,	 81,  82,  83,	84,  85,  86,  87
db  88,	 89,  90, 123, 124, 125, 126, 127
db 128, 181, 182, 183, 184, 185, 186, 187
db 188, 189, 190, 191, 192, 193, 194, 195
db 196, 197, 198, 199, 200, 201, 202, 203
db 204, 205, 206, 207, 208, 209, 210, 211
db 212, 213, 214, 215, 216, 217, 218, 219
db 220, 221, 222, 223, 224, 225, 226, 227
db 228, 229, 230, 231, 232, 233, 234, 235
db 236, 237, 238, 239, 240, 241, 242, 243
db 129, 130, 131, 172, 132, 173, 174, 133
db 134, 135, 175, 176, 177, 178, 179, 180
db 149, 136, 137, 138, 150, 139, 140, 141
db 142, 143, 144, 145, 146, 147, 148, 244
db 245, 246, 151, 152, 153, 154, 155, 156
db 247, 248, 157, 158, 159, 160, 161, 162
db 249, 250, 163, 164, 165, 166, 167, 168
db 251, 252, 169, 170, 171, 253, 254, 255

cn_collate_936 db 0FFh,"COLLATE"	; Chinese, CP936
	       dw 256
db   0,	  1,   2,   3,	 4,   5,   6,	7
db   8,	  9,  10,  11,	12,  13,  14,  15
db  16,	 17,  18,  19,	20,  21,  22,  23
db  24,	 25,  26,  27,	28,  29,  30,  31
db  32,	 33,  34,  35,	36,  37,  38,  39
db  40,	 41,  42,  43,	44,  45,  46,  47
db  48,	 49,  50,  51,	52,  53,  54,  55
db  56,	 57,  58,  59,	60,  61,  62,  63
db  64,	 65,  66,  67,	68,  69,  70,  71
db  72,	 73,  74,  75,	76,  77,  78,  79
db  80,	 81,  82,  83,	84,  85,  86,  87
db  88,	 89,  90,  91,	36,  93,  94,  95
db  96,	 65,  66,  67,	68,  69,  70,  71
db  72,	 73,  74,  75,	76,  77,  78,  79
db  80,	 81,  82,  83,	84,  85,  86,  87
db  88,	 89,  90, 123, 124, 125, 126, 127
db  36, 129, 130, 131, 132, 133, 134, 135
db 136, 137, 138, 139, 140, 141, 142, 143
db 144, 145, 146, 147, 148, 149, 150, 151
db 152, 153, 154, 155, 156, 157, 158, 159
db 160, 161, 162, 163, 164, 165, 166, 167
db 168, 169, 170, 171, 172, 173, 174, 175
db 176, 177, 178, 179, 180, 181, 182, 183
db 184, 185, 186, 187, 188, 189, 190, 191
db 192, 193, 194, 195, 196, 197, 198, 199
db 200, 201, 202, 203, 204, 205, 206, 207
db 208, 209, 210, 211, 212, 213, 214, 215
db 216, 217, 218, 219, 220, 221, 222, 223
db 224, 225, 226, 227, 228, 229, 230, 231
db 232, 233, 234, 235, 236, 237, 238, 239
db 240, 241, 242, 243, 244, 245, 246, 247
db 248, 249, 250, 251, 252, 253, 254, 255

by_collate_849 db 0FFh,"COLLATE"	; Belarusian, CP849
	       dw 256
db   0,   1,   2,   3,   4,   5,   6,   7
db   8,   9,  10,  11,  12,  13,  14,  15
db  16,  17,  18,  19,  20,  21,  22,  23
db  24,  25,  26,  27,  28,  29,  30,  31
db  32,  33,  34,  35,  36,  37,  38,  39
db  40,  41,  42,  43,  44,  45,  46,  47
db  48,  49,  50,  51,  52,  53,  54,  55
db  56,  57,  58,  59,  60,  61,  62,  63
db  64,  65,  66,  67,  68,  69,  70,  71
db  72,  73,  74,  75,  76,  77,  78,  79
db  80,  81,  82,  83,  84,  85,  86,  87
db  88,  89,  90,  91,  92,  93,  94,  95
db  96,  65,  66,  67,  68,  69,  70,  71
db  72,  73,  74,  75,  76,  77,  78,  79
db  80,  81,  82,  83,  84,  85,  86,  87
db  88,  89,  90, 123, 124, 125, 126, 127
db 128, 129, 130, 131, 133, 134, 137, 138
db 141, 142, 143, 144, 145, 146, 147, 148
db 149, 150, 151, 152, 154, 155, 156, 157
db 158, 159, 160, 161, 162, 163, 164, 165
db 128, 129, 130, 131, 133, 134, 137, 138
db 141, 142, 143, 144, 145, 146, 147, 148
db 176, 177, 178, 179, 180, 181, 182, 183
db 184, 185, 186, 187, 188, 189, 190, 191
db 192, 193, 194, 195, 196, 197, 198, 199
db 200, 201, 201, 203, 204, 205, 206, 207
db 208, 209, 210, 211, 212, 213, 214, 215
db 216, 217, 218, 219, 220, 221, 222, 223
db 149, 150, 151, 152, 154, 155, 156, 157
db 158, 159, 160, 161, 162, 163, 164, 165
db 136, 136, 135, 135, 140, 140, 153, 153
db 139, 139, 250, 251, 132, 132, 254, 255

by_collate_1131 equ by_collate_849	; Belarusian, CP1131
by_collate_850 equ en_collate_850	; Belarusian CP850
by_collate_858 equ en_collate_858	; Belarusian CP858

bg_collate_30033 db 0FFh,"COLLATE"	; Bulgarian, MIK codepage
	       dw 256
db   0,   1,   2,   3,   4,   5,   6,   7
db   8,   9,  10,  11,  12,  13,  14,  15
db  16,  17,  18,  19,  20,  21,  22,  23
db  24,  25,  26,  27,  28,  29,  30,  31
db  32,  33,  34,  35,  36,  37,  38,  39
db  40,  41,  42,  43,  44,  45,  46,  47
db  48,  49,  50,  51,  52,  53,  54,  55
db  56,  57,  58,  59,  60,  61,  62,  63
db  64,  65,  66,  67,  68,  69,  70,  71
db  72,  73,  74,  75,  76,  77,  78,  79
db  80,  81,  82,  83,  84,  85,  86,  87
db  88,  89,  90,  91,  92,  93,  94,  95
db  96,  65,  66,  67,  68,  69,  70,  71
db  72,  73,  74,  75,  76,  77,  78,  79
db  80,  81,  82,  83,  84,  85,  86,  87
db  88,  89,  90, 123, 124, 125, 126, 127
db 128, 129, 130, 131, 132, 133, 134, 135
db 136, 137, 138, 139, 140, 141, 142, 143
db 144, 145, 146, 147, 148, 149, 150, 151
db 152, 153, 154, 155, 156, 157, 158, 159
db 128, 129, 130, 131, 132, 133, 134, 135
db 136, 137, 138, 139, 140, 141, 142, 143
db 144, 145, 146, 147, 148, 149, 150, 151
db 152, 153, 154, 155, 156, 157, 158, 159
db 192, 193, 194, 195, 196, 197, 198, 199
db 200, 201, 202, 203, 204, 205, 206, 207
db 208, 209, 210, 211, 212, 213, 214, 215
db 216, 217, 218, 219, 220, 221, 222, 223
db 224, 225, 226, 227, 228, 229, 230, 231
db 232, 233, 234, 235, 236, 237, 238, 239
db 240, 241, 242, 243, 244, 245, 246, 247
db 248, 249, 250, 251, 252, 253, 254, 255

bg_collate_855 equ ru_collate_855	; Bulgarian, CP855
bg_collate_872 equ ru_collate_872	; Bulgarian, CP872
bg_collate_850 equ en_collate_850	; Bulgarian CP850
bg_collate_858 equ en_collate_858	; Bulgarian CP858
bg_collate_866 equ ru_collate_866	; Bulgarian CP866
bg_collate_808 equ ru_collate_808	; Bulgarian CP808
bg_collate_849 equ by_collate_849	; Bulgarian CP849
bg_collate_1131 equ by_collate_1131	; Bulgarian CP1131

ua_collate_848 db 0FFh,"COLLATE"	; Ukrainian, CP848
	       dw 256
db   0,   1,   2,   3,   4,   5,   6,   7
db   8,   9,  10,  11,  12,  13,  14,  15
db  16,  17,  18,  19,  20,  21,  22,  23
db  24,  25,  26,  27,  28,  29,  30,  31
db  32,  33,  34,  35,  36,  37,  38,  39
db  40,  41,  42,  43,  44,  45,  46,  47
db  48,  49,  50,  51,  52,  53,  54,  55
db  56,  57,  58,  59,  60,  61,  62,  63
db  64,  65,  66,  67,  68,  69,  70,  71
db  72,  73,  74,  75,  76,  77,  78,  79
db  80,  81,  82,  83,  84,  85,  86,  87
db  88,  89,  90,  91,  92,  93,  94,  95
db  96,  65,  66,  67,  68,  69,  70,  71
db  72,  73,  74,  75,  76,  77,  78,  79
db  80,  81,  82,  83,  84,  85,  86,  87
db  88,  89,  90, 123, 124, 125, 126, 127
db 128, 129, 130, 131, 133, 135, 137, 138
db 140, 143, 145, 146, 148, 149, 151, 152
db 153, 154, 155, 158, 160, 161, 162, 163
db 165, 166, 167, 168, 169, 170, 171, 172
db 128, 129, 130, 131, 133, 135, 137, 138
db 140, 143, 145, 146, 148, 149, 151, 152
db 176, 177, 178, 179, 180, 181, 182, 183
db 184, 185, 186, 187, 188, 189, 190, 191
db 192, 193, 194, 195, 196, 197, 198, 199
db 200, 201, 201, 203, 204, 205, 206, 207
db 208, 209, 210, 211, 212, 213, 214, 215
db 216, 217, 218, 219, 220, 221, 222, 223
db 153, 154, 155, 158, 160, 161, 162, 163
db 165, 166, 167, 168, 169, 170, 171, 172
db 135, 135, 132, 132, 136, 136, 141, 141
db 142, 142, 250, 251, 252, 36,  254, 255

ua_collate_855 equ ua_collate_848
ua_collate_866 equ ua_collate_848
ua_collate_1125 equ ua_collate_848	; Ukrainian, CP1125

hr_collate_852 equ ru_collate_852	; Croatian, CP852
hr_collate_850 equ pl_collate_850	; Croatian, CP850
hr_collate_858 equ gr_collate_858	; Croatian, CP858

si_collate_852 equ ru_collate_852	; Slovenian, CP852
si_collate_850 equ pl_collate_850	; Slovenian, CP850
si_collate_858 equ gr_collate_858	; Slovenian, CP858

mk_collate_855 equ ru_collate_855	; Macedonian, CP855
mk_collate_872 equ ru_collate_872	; Macedonian, CP872
mk_collate_850 equ pl_collate_850	; Macedonian, CP850
mk_collate_858 equ gr_collate_858	; Macedonian, CP858

il_collate_862 db 0FFh,"COLLATE"		; Hebrew, CP862
	       dw 256
db   0,	  1,   2,   3,	 4,   5,   6,	7
db   8,	  9,  10,  11,	12,  13,  14,  15
db  16,	 17,  18,  19,	20,  21,  22,  23
db  24,	 25,  26,  27,	28,  29,  30,  31
db  32,	 33,  34,  35,	36,  37,  38,  39
db  40,	 41,  42,  43,	44,  45,  46,  47
db  48,	 49,  50,  51,	52,  53,  54,  55
db  56,	 57,  58,  59,	60,  61,  62,  63
db  64,	 65,  66,  67,	68,  69,  70,  71
db  72,	 73,  74,  75,	76,  77,  78,  79
db  80,	 81,  82,  83,	84,  85,  86,  87
db  88,	 89,  90,  91,	92,  93,  94,  95
db  96,	 65,  66,  67,	68,  69,  70,  71
db  72,	 73,  74,  75,	76,  77,  78,  79
db  80,	 81,  82,  83,	84,  85,  86,  87
db  88,	 89,  90, 123, 124, 125, 126, 127
db 128, 129, 130, 131, 132, 133, 134, 135
db 136, 137, 138, 138, 139, 140, 140, 141
db 141, 142, 143, 144, 144, 145, 145, 146
db 147, 148, 149,  36,	36,  36,  36,  36 
db  65,	 73,  79,  85,	78,  78, 166, 167
db  63, 169, 170, 171, 172,  33,  34,  34
db 176, 177, 178, 179, 180, 181, 182, 183
db 184, 185, 186, 187, 188, 189, 190, 191
db 192, 193, 194, 195, 196, 197, 198, 199
db 200, 201, 202, 203, 204, 205, 206, 207
db 208, 209, 210, 211, 212, 213, 214, 215
db 216, 217, 218, 219, 220, 221, 222, 223
db 224,	 83, 226, 227, 228, 229, 230, 231
db 232, 233, 234, 235, 236, 237, 238, 239
db 240, 241, 242, 243, 244, 245, 246, 247
db 248, 249, 250, 251, 252, 253, 254, 255

il_collate_850 equ en_collate_850
il_collate_858 equ en_collate_858

xx_collate_864 db 0FFh,"COLLATE"		; Arabic, CP864
	       dw 256
db   0,	  1,   2,   3,	 4,   5,   6,	7
db   8,	  9,  10,  11,	12,  13,  14,  15
db  16,	 17,  18,  19,	20,  21,  22,  23
db  24,	 25,  26,  27,	28,  29,  30,  31
db  32,	 33,  34,  35,	36,  37,  38,  39
db  40,	 41,  42,  43,	44,  45,  46,  47
db  48,	 49,  50,  51,	52,  53,  54,  55
db  56,	 57,  58,  59,	60,  61,  62,  63
db  64,	 65,  66,  67,	68,  69,  70,  71
db  72,	 73,  74,  75,	76,  77,  78,  79
db  80,	 81,  82,  83,	84,  85,  86,  87
db  88,	 89,  90,  91,	92,  93,  94,  95
db  96,	 65,  66,  67,	68,  69,  70,  71
db  72,	 73,  74,  75,	76,  77,  78,  79
db  80,	 81,  82,  83,	84,  85,  86,  87
db  88,	 89,  90, 123, 124, 125, 126, 127
db 128, 129, 130, 131, 132, 133, 134, 135
db 136, 137, 138, 139, 140, 141, 142, 143
db 144, 145, 146, 147, 148, 149, 150, 151
db 152, 202, 202, 153, 154, 202, 202, 155
db 156, 157, 175,  36,  36, 176, 158, 159
db 179, 180, 182, 183, 160, 184, 185, 186
db 164, 165, 166, 167, 168, 169, 170, 171
db 172, 173, 199, 161, 191, 192, 193, 162
db  36, 174, 175, 176, 177, 197, 178, 179
db 180, 181, 182, 183, 184, 185, 186, 187
db 188, 189, 190, 191, 192, 193, 194, 195
db 196, 197, 198, 219, 220, 221, 222, 197
db 163, 167, 200, 201, 202, 203, 204, 205
db 206, 207, 208, 194, 197, 198, 198, 203
db 209, 209, 204, 205, 205, 207, 208, 198
db 200, 202, 202, 202, 201, 208, 254, 255

xx_collate_850 equ en_collate_850
xx_collate_858 equ en_collate_858

; REVIEW NEEDED: Verify diacritical marks and special character ordering
is_collate_861 db 0FFh,"COLLATE"		; Icelandic, CP861
	       dw 256
db   0,   1,   2,   3,   4,   5,   6,   7
db   8,   9,  10,  11,  12,  13,  14,  15
db  16,  17,  18,  19,  20,  21,  22,  23
db  24,  25,  26,  27,  28,  29,  30,  31
db  32,  33,  34,  35,  36,  37,  38,  39
db  40,  41,  42,  43,  44,  45,  46,  47
db  48,  49,  50,  51,  52,  53,  54,  55
db  56,  57,  58,  59,  60,  61,  62,  63
db  64,  65,  67,  69,  71,  75,  77,  79
db  81,  85,  87,  89,  91,  93,  97,  99
db 101, 103, 105, 107, 109, 111, 113, 115
db 117, 119, 121, 123, 124, 125, 126, 127
db  64,  65,  67,  71,  75,  77,  79,  81
db  85,  87,  89,  91,  93,  97,  99, 101
db 103, 105, 107, 109, 111, 113, 115, 117
db 119, 121, 122, 123, 124, 125, 126, 127
db 128, 129, 130, 131, 132, 133, 134, 135
db 136, 137,  73, 139, 140,  73, 142, 143
db 144, 145, 146, 147, 148, 149, 150, 151
db 152, 153, 154, 155, 156, 157, 158, 159
db 160, 161, 162, 163, 164, 165, 166, 167
db 168, 169, 170, 171, 172, 173, 174, 175
db 176, 177, 178, 179, 180, 181, 182, 183
db 184, 185, 186, 187, 188, 189, 190, 191
db 192, 193, 194, 195, 196, 197, 198, 199
db 200, 201, 202, 203, 204, 205, 206, 207
db 208, 209, 210, 211, 212, 213, 214, 215
db 216, 217, 218, 219, 220, 221, 222, 223
db 224, 225, 226, 227, 228, 229, 230, 231
db 232, 233, 234, 235, 236, 237, 238, 239
db 240, 241, 242, 243, 244, 245, 246, 247
db 248, 249, 250, 251, 252, 253, 254, 255

is_collate_865 equ is_collate_861
is_collate_850 equ en_collate_850
is_collate_858 equ en_collate_858

; REVIEW NEEDED: Verify exact ordering of diacritical variants
ee_collate_775 db 0FFh,"COLLATE"		; Estonian, CP775
	       dw 256
db   0,   1,   2,   3,   4,   5,   6,   7
db   8,   9,  10,  11,  12,  13,  14,  15
db  16,  17,  18,  19,  20,  21,  22,  23
db  24,  25,  26,  27,  28,  29,  30,  31
db  32,  33,  34,  35,  36,  37,  38,  39
db  40,  41,  42,  43,  44,  45,  46,  47
db  48,  49,  50,  51,  52,  53,  54,  55
db  56,  57,  58,  59,  60,  61,  62,  63
db  64,  65,  67,  69,  71,  73,  75,  77
db  79,  81,  83,  85,  87,  89,  91,  93
db  95,  97,  99, 101, 103, 105, 107, 109
db 111, 113, 115, 117, 118, 119, 120, 121
db  64,  65,  67,  69,  71,  73,  75,  77
db  79,  81,  83,  85,  87,  89,  91,  93
db  95,  97,  99, 101, 103, 105, 107, 109
db 111, 113, 115, 116, 118, 119, 120, 121
db 128, 129, 130, 131, 132, 133, 134, 135
db 136, 137, 138, 139, 140, 141, 142, 143
db 144, 145, 146, 147, 148, 149, 150, 151
db 152, 153, 154, 155, 156, 157, 158, 159
db 160, 161, 162, 163, 164, 165, 166, 167
db 168, 169, 170, 171, 172, 173, 174, 175
db 176, 177, 178, 179, 180, 181, 182, 183
db 184, 185, 186, 187, 188, 189, 190, 191
db 192, 193, 194, 195, 196, 197, 198, 199
db 200, 201, 202, 203, 204, 205, 206, 207
db 208, 209, 210, 211, 212, 213, 214, 215
db 216, 217, 218, 219, 220, 221, 222, 223
db 224, 225, 226, 227, 228, 229, 230, 231
db 232, 233, 234, 235, 236, 237, 238, 239
db 240, 241, 242, 243, 244, 245, 246, 247
db 248, 249, 250, 251, 252, 253, 254, 255

ee_collate_850 equ en_collate_850
ee_collate_858 equ en_collate_858

; REVIEW NEEDED: Verify exact ordering of diacritical variants
lv_collate_775 db 0FFh,"COLLATE"		; Latvian, CP775
	       dw 256
db   0,   1,   2,   3,   4,   5,   6,   7
db   8,   9,  10,  11,  12,  13,  14,  15
db  16,  17,  18,  19,  20,  21,  22,  23
db  24,  25,  26,  27,  28,  29,  30,  31
db  32,  33,  34,  35,  36,  37,  38,  39
db  40,  41,  42,  43,  44,  45,  46,  47
db  48,  49,  50,  51,  52,  53,  54,  55
db  56,  57,  58,  59,  60,  61,  62,  63
db  64,  65,  67,  69,  71,  73,  75,  77
db  79,  81,  83,  85,  87,  89,  91,  93
db  95,  97,  99, 101, 103, 105, 107, 109
db 111, 113, 115, 117, 118, 119, 120, 121
db  64,  65,  67,  69,  71,  73,  75,  77
db  79,  81,  83,  85,  87,  89,  91,  93
db  95,  97,  99, 101, 103, 105, 107, 109
db 111, 113, 115, 116, 118, 119, 120, 121
db 128, 129, 130, 131, 132, 133, 134, 135
db 136, 137, 138, 139, 140, 141, 142, 143
db 144, 145, 146, 147, 148, 149, 150, 151
db 152, 153, 154, 155, 156, 157, 158, 159
db 160, 161, 162, 163, 164, 165, 166, 167
db 168, 169, 170, 171, 172, 173, 174, 175
db 176, 177, 178, 179, 180, 181, 182, 183
db 184, 185, 186, 187, 188, 189, 190, 191
db 192, 193, 194, 195, 196, 197, 198, 199
db 200, 201, 202, 203, 204, 205, 206, 207
db 208, 209, 210, 211, 212, 213, 214, 215
db 216, 217, 218, 219, 220, 221, 222, 223
db 224, 225, 226, 227, 228, 229, 230, 231
db 232, 233, 234, 235, 236, 237, 238, 239
db 240, 241, 242, 243, 244, 245, 246, 247
db 248, 249, 250, 251, 252, 253, 254, 255

lv_collate_850 equ en_collate_850
lv_collate_858 equ en_collate_858

; REVIEW NEEDED: Verify exact ordering of diacritical variants
lt_collate_775 db 0FFh,"COLLATE"		; Lithuanian, CP775
	       dw 256
db   0,   1,   2,   3,   4,   5,   6,   7
db   8,   9,  10,  11,  12,  13,  14,  15
db  16,  17,  18,  19,  20,  21,  22,  23
db  24,  25,  26,  27,  28,  29,  30,  31
db  32,  33,  34,  35,  36,  37,  38,  39
db  40,  41,  42,  43,  44,  45,  46,  47
db  48,  49,  50,  51,  52,  53,  54,  55
db  56,  57,  58,  59,  60,  61,  62,  63
db  64,  65,  67,  69,  71,  73,  75,  77
db  79,  81,  83,  85,  87,  89,  91,  93
db  95,  97,  99, 101, 103, 105, 107, 109
db 111, 113, 115, 117, 118, 119, 120, 121
db  64,  65,  67,  69,  71,  73,  75,  77
db  79,  81,  83,  85,  87,  89,  91,  93
db  95,  97,  99, 101, 103, 105, 107, 109
db 111, 113, 115, 116, 118, 119, 120, 121
db 128, 129, 130, 131, 132, 133, 134, 135
db 136, 137, 138, 139, 140, 141, 142, 143
db 144, 145, 146, 147, 148, 149, 150, 151
db 152, 153, 154, 155, 156, 157, 158, 159
db 160, 161, 162, 163, 164, 165, 166, 167
db 168, 169, 170, 171, 172, 173, 174, 175
db 176, 177, 178, 179, 180, 181, 182, 183
db 184, 185, 186, 187, 188, 189, 190, 191
db 192, 193, 194, 195, 196, 197, 198, 199
db 200, 201, 202, 203, 204, 205, 206, 207
db 208, 209, 210, 211, 212, 213, 214, 215
db 216, 217, 218, 219, 220, 221, 222, 223
db 224, 225, 226, 227, 228, 229, 230, 231
db 232, 233, 234, 235, 236, 237, 238, 239
db 240, 241, 242, 243, 244, 245, 246, 247
db 248, 249, 250, 251, 252, 253, 254, 255

lt_collate_850 equ en_collate_850
lt_collate_858 equ en_collate_858

th_collate_874 equ en_collate_437  ; Thai uses basic ASCII sort order for Latin characters
vn_collate_1258 equ en_collate_437  ; Vietnamese uses ASCII sort order
al_collate_852 equ ru_collate_852   ; Albanian shares Central European sort

xk_collate_852 equ al_collate_852
xk_collate_855 equ ru_collate_855
xk_collate_872 equ ru_collate_872
xk_collate_850 equ en_collate_850
xk_collate_858 equ en_collate_858

section .data7 align=1
; ==============================================================================
; 6: DBCS TABLES (Subfunction 7)
; ==============================================================================
;
; Double-Byte Character Set (DBCS) tables define lead byte ranges
; for multibyte character encodings used in Asian languages.
;
; Structure:
;   - Signature: 0FFh,'DBCS   ' (8 bytes)
;   - Size: Word (2 bytes, always 0)
;   - Ranges: Pairs of bytes (start, end) for lead byte ranges
;   - Terminator: 0,0
;
; Lead bytes indicate that the next byte should be treated as part
; of a two-byte character rather than a separate character.
;
; Examples:
;   - Japanese (CP932): Lead bytes 81h-9Fh, E0h-FCh
;   - Korean (CP934): Lead bytes 81h-FEh
;   - Chinese (CP936): Lead bytes 81h-FEh
;
; For non-DBCS codepages, this table is empty (just terminator).

dbcs_empty db 0FFh,"DBCS   "
      dw 0          ; Table length
      db 0, 0       ; Table terminator (even if length == 0)

; Japan, CP932
; Source: http://www.microsoft.com/globaldev/reference/dbcs/932.htm
jp_dbcs_932 db 0FFh,"DBCS   "
      dw 6
      db 081h, 09Fh
      db 0E0h, 0FCh
      db 000h, 000h

; Korean, CP934
kr_dbcs_934 db 0FFh,"DBCS   "
      dw 4
      db 081h, 0BFh
      db 000h, 000h

; Chinese, CP936
cn_dbcs_936 db 0FFh,"DBCS   "
      dw 4
      db 081h, 0FCh
      db 000h, 000h

section .data8 align=1
; ==============================================================================
; 7: YES/NO TABLES (Subfunction 35)
; ==============================================================================
;
; Yes/No tables define characters used for yes/no prompts.
;
; Structure:
;   - Signature: 0FFh,'YESNO  ' (8 bytes)
;   - Size: Word (2 bytes, always 4)
;   - Data: 4 bytes arranged as follows:
;     Byte 0: YES character (usually uppercase), (single byte) or leadbyte (DBCS)
;     Byte 1: YES trailing byte (0 for single-byte, DBCS trail byte)
;     Byte 2: NO character (usually uppercase), (single byte) or leadbyte (DBCS)
;     Byte 3: NO trailing byte (0 for single-byte, DBCS trail byte)
;
; Examples:
;   - English: Y/N (Yes/No)
;   - French: O/N (Oui/Non)
;   - German: J/N (Ja/Nein)
;   - Spanish: S/N (Si/No)
;   - Dutch: J/N (Ja/Nee)

;------------------------------------------------------------------------------

; Macro: YESNO_TABLE
; Creates a Yes/No prompt character table for subfunction 35
;
; Parameters:
;   %1 = table label (e.g., en_yn, es_yn, fr_yn)
;   %2 = YES character (single byte 'Y', 'S', or DBCS lead byte)
;   %3 = YES trailing byte (0 for single-byte, DBCS trail byte for DBCS)
;   %4 = NO character (single byte 'N', or DBCS lead byte)
;   %5 = NO trailing byte (0 for single-byte, DBCS trail byte for DBCS)
;
; E.g for Spanish,
; YESNO es_yn, 'S', 'N' ; Spanish
; generates:
; es_yn db 0FFh,"YESNO  "
;       dw 4
;       db 'S',0,'N',0

%macro YESNO 3-5
%1 db 0FFh,"YESNO  "
   dw 4
   %if %0 == 5
     db %2,%3,%4,%5
   %elif %0 == 3
     db %2,0,%3,0
   %else
     %error "Incorrect arguments to YESNO macro - YESNO label, 'Y', 'N' or YESNO label, 'Y', 0, 'N', 0"
   %endif
%endmacro

; ------------------------------------------------------------------------------
; Common character combinations (reusable Y/N pairs)
; ------------------------------------------------------------------------------
YESNO yn_yn, 'Y', 'N'           ; Y/N: English, etc.
YESNO yn_sn, 'S', 'N'           ; S/N: Spanish, Portuguese, Italian, Catalan, Galician
YESNO yn_jn, 'J', 'N'           ; J/N: German, Dutch, Danish, Swedish, Norwegian, Icelandic, Latvian
YESNO yn_on, 'O', 'N'           ; O/N: French
YESNO yn_tn, 'T', 'N'           ; T/N: Polish, Lithuanian
YESNO yn_an, 'A', 'N'           ; A/N: Czech, Slovak
YESNO yn_dn, 'D', 'N'           ; D/N: Romanian, Croatian, Slovenian, Serbian (Latin)
YESNO yn_in, 'I', 'N'           ; I/N: Hungarian
YESNO yn_ke, 'K', 'E'           ; K/E: Finnish
YESNO yn_je, 'J', 'E'           ; J/E: Estonian
YESNO yn_be, 'B', 'E'           ; B/E: Basque
YESNO yn_no, 'N', 'O'           ; N/O: Greek (Latin)
YESNO yn_eh, 'E', 'H'           ; E/H: Turkish
YESNO yn_kl, 'K', 'L'           ; K/L: Hebrew (Latin)
YESNO yn_nl, 'N', 'L'           ; N/L: Arabic (Latin)
YESNO yn_sb, 'S', 'B'           ; S/B: Chinese (Latin)
YESNO yn_ya, 'Y', 'A'           ; Y/A: Korean (Latin)
YESNO yn_pj, 'P', 'J'           ; P/J: Albanian (Po/Jo)
YESNO yn_yt, 'Y', 'T'           ; Y/T: Indonesian (Ya/Tidak)
YESNO yn_oh, 'O', 'H'           ; O/H: Filipino (Oo/Hindi)
YESNO yn_il, 'I', 'L'           ; I/L: Maltese (Iva/Le)
YESNO yn_ck, 'C', 'K'           ; C/K: Vietnamese (Co/Khong)

; Cyrillic codepage combinations
YESNO yn_cyrl_866,  84h, 0,  8Dh, 0    ; CP866 (Russian, Bulgarian, Belarusian, Ukrainian)
YESNO yn_cyrl_855, 0A7h, 0, 0D5h, 0    ; CP855 (Russian, Bulgarian, Serbian, Macedonian)
YESNO yn_cyrl_872, 0A7h, 0, 0D5h, 0    ; CP872 (Russian, Bulgarian, Serbian, Macedonian)

; Greek codepage combinations
YESNO yn_gr_869, 0B8h, 0, 0BEh, 0      ; N/O: CP869 (Greek)
YESNO yn_gr_737,  8Ch, 0,  8Eh, 0      ; N/O: CP737 (Greek)

; Hebrew codepage combinations
YESNO yn_il_862, 8Bh, 0, 8Ch, 0        ; CP862 (Hebrew)

; Arabic codepage combinations
YESNO yn_xx_864, 0F2h, 0, 9Dh, 0       ; CP864 (Arabic)

; Korean codepage combinations
YESNO yn_kr_934, 0BFh, 0B9h, 0BEh, 0C6h ; CP934 (Korean Hangul)

; Chinese codepage combinations
YESNO yn_cn_936, 0CAh, 0C7h, 0B2h, 0BBh ; CP936 (Chinese Simplified)


; ==============================================================================
; VERSION BLOCK, FreeDOS extension
; ==============================================================================
db 0FFh,"VERSION"
dw 4
db '2', 0, '0', 0  ; version: Major, 0, Minor, 0 (ASCIIZ 2-byte strings)

; ==============================================================================
; END OF FILE
; ==============================================================================
db "FreeDOS" ; Trailing - as recommended by the Ralf Brown Interrupt List
