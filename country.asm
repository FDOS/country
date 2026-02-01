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
;   Slovenia (386), Croatia (384), Bosnia-Herzegovina (387),
;   Serbia (381), North Macedonia (389), Montenegro (382), Kosovo (383)
;
; ==============================================================================
; TABLE OF CONTENTS
; ==============================================================================
;
; SECTION 1: FILE STRUCTURE
;   - File Header (signature, magic bytes, entry pointer)
;   - Entry Table (index of all country/codepage combinations)
;
; SECTION 2: SUBFUNCTION HEADERS (for each country/codepage)
;   Defines which subfunctions are available for each entry
;
; SECTION 3: COUNTRY INFORMATION TABLES (Subfunction 1)
;   Date format, time format, currency symbol, separators
;
; SECTION 4: UPPERCASE/LOWERCASE TABLES (Subfunctions 2, 3, 4)
;   Character case conversion mappings for each codepage
;
; SECTION 5: FILENAME CHARACTER TABLE (Subfunction 5)
;   Characters allowed/disallowed in filenames
;
; SECTION 6: COLLATING SEQUENCES (Subfunction 6)
;   Sort order for each country/codepage combination
;
; SECTION 7: DBCS TABLES (Subfunction 7)
;   Double-Byte Character Set lead byte ranges (Japanese, Korean, Chinese)
;
; SECTION 8: YES/NO TABLES (Subfunction 35)
;   Yes/No prompt characters for each language
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
; 785 = Middle East (XX) *temp*    972 = Israel (IL)
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
;
; ==============================================================================
; SECTION 1: FILE HEADER
; ==============================================================================
;
; The file header contains the magic signature 'COUNTRY' and points to
; the entry table. Structure:
;   - Byte 0: 0FFh (signature)
;   - Bytes 1-7: 'COUNTRY' (magic string)
;   - Bytes 8-17: Reserved/undocumented
;   - Bytes 18-21: Pointer to entry table
;
db 0FFh,"COUNTRY",0,0,0,0,0,0,0,0,1,0,1 ; reserved and undocumented values
dd  ent	 ; first entry
; number of entries - don't forget to update when adding a new country
%ifdef OBSOLETE
ent dw 239
%else
ent dw 231
%endif

; ==============================================================================
; SECTION 2: ENTRY TABLE
; ==============================================================================
;
; Each entry is 14 bytes:
;   - Word:  Entry size (always 12)
;   - Word:  Country code (numeric)
;   - Word:  Codepage number
;   - DWord: Reserved (always 0,0)
;   - DWord: Offset to subfunction header
;
; Entry naming convention: __<country>_<codepage>
; Data naming convention:  _<country>_<codepage>
;
; Each country has an entry for each codepage supported.
;
; Macro: ENTRY
; Creates a country entry structure
; Parameters:
;   %1 = 2-character ISO country code (e.g., gr)
;   %2 = numerical country code (e.g., 30)
;   %3 = codepage number (e.g., 869)
;
; Note: labels use numeric country code to avoid issues, e.g. cz=42 & 420
;       previous versions used 2-char code in label

%macro ENTRY 3
__%2_%3 dw 12, %2, %3, 0, 0
        dd _%1_%3
%endmacro

; Macro: OLD_ENTRY
; Use OLD_ENTRY for deprecated country/codepage combinations:
; Conditionally creates a country entry only if OBSOLETE is defined
; Has same parameters as ENTRY
; To include obsolete entries, define OBSOLETE when assembling:
;     %define OBSOLETE
; E.g.
;     OLD_ENTRY yu, 38, 852    ; Yugoslavia - only included if OBSOLETE defined

%macro OLD_ENTRY 3
%ifdef OBSOLETE
    ENTRY %1, %2, %3
%endif
%endmacro

; ------------------------------------------------------------------------------
; Standard Countries (codes 0-999)
; ------------------------------------------------------------------------------
;
; Note: US 437 is the fallback for unknown or unsupported country/codepages
; E.g ENTRY us, 1, 437 macro expands to:
; __1_437 dw 12, 1, 437, 0, 0
;          dd _us_437

; ------------------------------------------------------------------------------
; United States - Country Code 1
; English
; ------------------------------------------------------------------------------
ENTRY us, 1, 437
ENTRY us, 1, 850
ENTRY us, 1, 858

; ------------------------------------------------------------------------------
; Canada - Country Code 2
; French Canada (Bilingual support)
; ------------------------------------------------------------------------------
ENTRY ca, 2, 863
ENTRY ca, 2, 850
ENTRY ca, 2, 858

; ------------------------------------------------------------------------------
; Latin America - Country Code 3
; Spanish-speaking Latin American countries
; ------------------------------------------------------------------------------
ENTRY la, 3, 858
ENTRY la, 3, 850
ENTRY la, 3, 437

; ------------------------------------------------------------------------------
; Russia - Country Code 7
; Russian Federation (multiple Cyrillic codepages)
; ------------------------------------------------------------------------------
ENTRY ru, 7, 866
ENTRY ru, 7, 808
ENTRY ru, 7, 855
ENTRY ru, 7, 872
ENTRY ru, 7, 852
ENTRY ru, 7, 850
ENTRY ru, 7, 858
ENTRY ru, 7, 437

; ------------------------------------------------------------------------------
; South Africa - Country Code 27
; English (South African)
; ------------------------------------------------------------------------------
ENTRY za, 27, 858
ENTRY za, 27, 850
ENTRY za, 27, 437

; ------------------------------------------------------------------------------
; Greece - Country Code 30
; Greek (multiple Greek codepages)
; ------------------------------------------------------------------------------
ENTRY gr, 30, 869
ENTRY gr, 30, 737
ENTRY gr, 30, 850
ENTRY gr, 30, 858

; ------------------------------------------------------------------------------
; Netherlands - Country Code 31
; Dutch
; ------------------------------------------------------------------------------
ENTRY nl, 31, 858
ENTRY nl, 31, 850
ENTRY nl, 31, 437

; ------------------------------------------------------------------------------
; Belgium - Country Code 32
; Belgian (multilingual)
; ------------------------------------------------------------------------------
ENTRY be, 32, 858
ENTRY be, 32, 850
ENTRY be, 32, 437

; ------------------------------------------------------------------------------
; France - Country Code 33
; French
; ------------------------------------------------------------------------------
ENTRY fr, 33, 858
ENTRY fr, 33, 850
ENTRY fr, 33, 437

; ------------------------------------------------------------------------------
; Spain - Country Code 34
; Spanish (Castilian)
; ------------------------------------------------------------------------------
ENTRY es, 34, 858
ENTRY es, 34, 850
ENTRY es, 34, 437

; ------------------------------------------------------------------------------
; Hungary - Country Code 36
; Hungarian (Magyar)
; ------------------------------------------------------------------------------
ENTRY hu, 36, 852
ENTRY hu, 36, 850
ENTRY hu, 36, 858

; ------------------------------------------------------------------------------
; Yugoslavia - Country Code 38
; ************************************************************
; ** OBSOLETE: Yugoslavia dissolved 1991-1992              **
; ** Successor states: Slovenia (386), Croatia (384),      **
; ** Bosnia-Herzegovina (387), Serbia (381), North         **
; ** Macedonia (389), Montenegro (382), Kosovo (383)       **
; ** Retained for backward compatibility only              **
; ************************************************************
; Serbo-Croatian (Latin and Cyrillic)
; ------------------------------------------------------------------------------
OLD_ENTRY yu, 38, 852
OLD_ENTRY yu, 38, 855
OLD_ENTRY yu, 38, 872
OLD_ENTRY yu, 38, 858
OLD_ENTRY yu, 38, 850

; ------------------------------------------------------------------------------
; Italy - Country Code 39
; Italian
; ------------------------------------------------------------------------------
ENTRY it, 39, 858
ENTRY it, 39, 850
ENTRY it, 39, 437

; ------------------------------------------------------------------------------
; Romania - Country Code 40
; Romanian
; ------------------------------------------------------------------------------
ENTRY ro, 40, 852
ENTRY ro, 40, 850
ENTRY ro, 40, 858

; ------------------------------------------------------------------------------
; Switzerland - Country Code 41
; Swiss (multilingual)
; ------------------------------------------------------------------------------
ENTRY ch, 41, 858
ENTRY ch, 41, 850
ENTRY ch, 41, 437

; ------------------------------------------------------------------------------
; Czechoslovakia - Country Code 42
; *** see Czech Republic (420) and Slovakia (421)
; Czech
; ------------------------------------------------------------------------------
OLD_ENTRY cz, 42, 852
OLD_ENTRY cz, 42, 850
OLD_ENTRY cz, 42, 858

; ------------------------------------------------------------------------------
; Austria - Country Code 43
; Austrian German
; ------------------------------------------------------------------------------
ENTRY at, 43, 858
ENTRY at, 43, 850
ENTRY at, 43, 437

; ------------------------------------------------------------------------------
; United Kingdom - Country Code 44
; British English
; ------------------------------------------------------------------------------
ENTRY gb, 44, 858
ENTRY gb, 44, 850
ENTRY gb, 44, 437

; ------------------------------------------------------------------------------
; Denmark - Country Code 45
; Danish
; ------------------------------------------------------------------------------
ENTRY dk, 45, 865
ENTRY dk, 45, 850
ENTRY dk, 45, 858

; ------------------------------------------------------------------------------
; Sweden - Country Code 46
; Swedish
; ------------------------------------------------------------------------------
ENTRY se, 46, 865
ENTRY se, 46, 858
ENTRY se, 46, 850
ENTRY se, 46, 437

; ------------------------------------------------------------------------------
; Norway - Country Code 47
; Norwegian
; ------------------------------------------------------------------------------
ENTRY no, 47, 865
ENTRY no, 47, 850
ENTRY no, 47, 858

; ------------------------------------------------------------------------------
; Poland - Country Code 48
; Polish
; ------------------------------------------------------------------------------
ENTRY pl, 48, 852
ENTRY pl, 48, 850
ENTRY pl, 48, 858

; ------------------------------------------------------------------------------
; Germany - Country Code 49
; German (Deutsch)
; ------------------------------------------------------------------------------
ENTRY de, 49, 858
ENTRY de, 49, 850
ENTRY de, 49, 437

; ------------------------------------------------------------------------------
; Mexico - Country Code 52
; Mexican Spanish
; ------------------------------------------------------------------------------
ENTRY mx, 52, 850
ENTRY mx, 52, 858
ENTRY mx, 52, 437

; ------------------------------------------------------------------------------
; Argentina - Country Code 54
; Argentine Spanish
; ------------------------------------------------------------------------------
ENTRY ar, 54, 858
ENTRY ar, 54, 850
ENTRY ar, 54, 437

; ------------------------------------------------------------------------------
; Brazil - Country Code 55
; Brazilian Portuguese
; ------------------------------------------------------------------------------
ENTRY br, 55, 858
ENTRY br, 55, 850
ENTRY br, 55, 437

; ------------------------------------------------------------------------------
; Malaysia - Country Code 60
; Malaysian
; ------------------------------------------------------------------------------
ENTRY my, 60, 437

; ------------------------------------------------------------------------------
; Australia - Country Code 61
; Australian English
; ------------------------------------------------------------------------------
ENTRY au, 61, 437
ENTRY au, 61, 850
ENTRY au, 61, 858

; ------------------------------------------------------------------------------
; Indonesia - Country Code 62
; Indonesian (Bahasa Indonesia)
; ------------------------------------------------------------------------------
ENTRY id, 62, 850
ENTRY id, 62, 437

; ------------------------------------------------------------------------------
; Philippines - Country Code 63
; English/Filipino
; ------------------------------------------------------------------------------
ENTRY ph, 63, 850
ENTRY ph, 63, 437

; ------------------------------------------------------------------------------
; New Zealand - Country Code 64
; English (New Zealand)
; ------------------------------------------------------------------------------
ENTRY nz, 64, 850
ENTRY nz, 64, 858
ENTRY nz, 64, 437

; ------------------------------------------------------------------------------
; Singapore - Country Code 65
; Singaporean
; ------------------------------------------------------------------------------
ENTRY sg, 65, 437

; ------------------------------------------------------------------------------
; Thailand - Country Code 66
; Thai
; ------------------------------------------------------------------------------
ENTRY th, 66, 874
ENTRY th, 66, 850
ENTRY th, 66, 437

; ------------------------------------------------------------------------------
; Japan - Country Code 81
; Japanese (includes DBCS support)
; ------------------------------------------------------------------------------
ENTRY jp, 81, 437
ENTRY jp, 81, 932

; ------------------------------------------------------------------------------
; South Korea - Country Code 82
; Korean (includes DBCS support)
; ------------------------------------------------------------------------------
ENTRY kr, 82, 437
ENTRY kr, 82, 934

; ------------------------------------------------------------------------------
; Vietnam - Country Code 84
; Vietnamese
; ------------------------------------------------------------------------------
ENTRY vn, 84, 1258
ENTRY vn, 84, 850
ENTRY vn, 84, 437

; ------------------------------------------------------------------------------
; China - Country Code 86
; Chinese Simplified (includes DBCS support)
; ------------------------------------------------------------------------------
ENTRY cn, 86, 437
ENTRY cn, 86, 936

; ------------------------------------------------------------------------------
; Turkey - Country Code 90
; Turkish
; ------------------------------------------------------------------------------
ENTRY tr, 90, 857
ENTRY tr, 90, 850
ENTRY tr, 90, 858

; ------------------------------------------------------------------------------
; India - Country Code 91
; Indian English
; ------------------------------------------------------------------------------
ENTRY in, 91, 437

; ------------------------------------------------------------------------------
; Portugal - Country Code 351
; Portuguese
; ------------------------------------------------------------------------------
ENTRY pt, 351, 860
ENTRY pt, 351, 850
ENTRY pt, 351, 858

; ------------------------------------------------------------------------------
; Luxembourg - Country Code 352
; French/German (multilingual)
; ------------------------------------------------------------------------------
ENTRY lu, 352, 850
ENTRY lu, 352, 858
ENTRY lu, 352, 437

; ------------------------------------------------------------------------------
; Ireland - Country Code 353
; English (Irish)
; ------------------------------------------------------------------------------
ENTRY ie, 353, 850
ENTRY ie, 353, 858
ENTRY ie, 353, 437

; ------------------------------------------------------------------------------
; Iceland - Country Code 354
; Icelandic
; ------------------------------------------------------------------------------
ENTRY is, 354, 861
ENTRY is, 354, 865 ; like 861 but with 0x9E/0x9F Thorn lowercase/uppercase
ENTRY is, 354, 850
ENTRY is, 354, 858

; ------------------------------------------------------------------------------
; Albania - Country Code 355
; Albanian (Shqip)
; ------------------------------------------------------------------------------
ENTRY al, 355, 852
ENTRY al, 355, 850
ENTRY al, 355, 858

; ------------------------------------------------------------------------------
; Malta - Country Code 356
; Maltese/English
; ------------------------------------------------------------------------------
ENTRY mt, 356, 850
ENTRY mt, 356, 858
ENTRY mt, 356, 437

; ------------------------------------------------------------------------------
; Cyprus - Country Code 357
; Greek
; ------------------------------------------------------------------------------
ENTRY cy, 357, 869
ENTRY cy, 357, 850
ENTRY cy, 357, 858

; ------------------------------------------------------------------------------
; Finland - Country Code 358
; Finnish
; ------------------------------------------------------------------------------
ENTRY fi, 358, 865
ENTRY fi, 358, 858
ENTRY fi, 358, 850
ENTRY fi, 358, 437

; ------------------------------------------------------------------------------
; Bulgaria - Country Code 359
; Bulgarian (Cyrillic)
; ------------------------------------------------------------------------------
ENTRY bg, 359, 855
ENTRY bg, 359, 872
ENTRY bg, 359, 850
ENTRY bg, 359, 858
ENTRY bg, 359, 866
ENTRY bg, 359, 808
ENTRY bg, 359, 849
ENTRY bg, 359, 1131
ENTRY bg, 359, 30033

; ------------------------------------------------------------------------------
; Lithuania - Country Code 370
; Lithuanian (Baltic)
; ------------------------------------------------------------------------------
ENTRY lt, 370, 775
ENTRY lt, 370, 850
ENTRY lt, 370, 858

; ------------------------------------------------------------------------------
; Latvia - Country Code 371
; Latvian (Baltic)
; ------------------------------------------------------------------------------
ENTRY lv, 371, 775
ENTRY lv, 371, 850
ENTRY lv, 371, 858

; ------------------------------------------------------------------------------
; Estonia - Country Code 372
; Estonian (Baltic)
; ------------------------------------------------------------------------------
ENTRY ee, 372, 775
ENTRY ee, 372, 850
ENTRY ee, 372, 858

; ------------------------------------------------------------------------------
; Belarus - Country Code 375
; Belarusian
; ------------------------------------------------------------------------------
ENTRY by, 375, 849
ENTRY by, 375, 1131
ENTRY by, 375, 850
ENTRY by, 375, 858

; ------------------------------------------------------------------------------
; Ukraine - Country Code 380
; Ukrainian
; ------------------------------------------------------------------------------
ENTRY ua, 380, 848
ENTRY ua, 380, 855
ENTRY ua, 380, 866
ENTRY ua, 380, 1125

; ------------------------------------------------------------------------------
; Serbia - Country Code 381
; Serbian (Latin and Cyrillic)
; ------------------------------------------------------------------------------
ENTRY rs, 381, 855  ; Serbian, Cyrillic
ENTRY rs, 381, 872
ENTRY rs, 381, 852  ; Serbian, Latin
ENTRY rs, 381, 850
ENTRY rs, 381, 858

; ------------------------------------------------------------------------------
; Montenegro - Country Code 382
; Serbian (Montenegro uses Serbian language)
; ------------------------------------------------------------------------------
ENTRY me, 382, 852
ENTRY me, 382, 855
ENTRY me, 382, 872
ENTRY me, 382, 850
ENTRY me, 382, 858

; ------------------------------------------------------------------------------
; Kosovo - Country Code 383
; Albanian/Serbian
; ------------------------------------------------------------------------------
ENTRY xk, 383, 852
ENTRY xk, 383, 855
ENTRY xk, 383, 872
ENTRY xk, 383, 850
ENTRY xk, 383, 858

; ------------------------------------------------------------------------------
; Croatia - Country Code 385
; Croatian
; ------------------------------------------------------------------------------
ENTRY hr, 385, 852  ; Croatia, Croatian
ENTRY hr, 385, 850
ENTRY hr, 385, 858

; ------------------------------------------------------------------------------
; Slovenia - Country Code 386
; Slovenian
; ------------------------------------------------------------------------------
ENTRY si, 386, 852  ; Slovenia
ENTRY si, 386, 850
ENTRY si, 386, 858

; ------------------------------------------------------------------------------
; Bosnia-Herzegovina - Country Code 387
; Bosnian
; ------------------------------------------------------------------------------
ENTRY ba, 387, 852  ; Bosnia Herzegovina
ENTRY ba, 387, 850
ENTRY ba, 387, 858
ENTRY ba, 387, 855  ; Bosnia Herzegovina, Cyrillic
ENTRY ba, 387, 872

; ------------------------------------------------------------------------------
; North Macedonia - Country Code 389
; Macedonian (Name updated from "Macedonia" per Prespa Agreement 2019)
; ------------------------------------------------------------------------------
ENTRY mk, 389, 855  ; North Macedonia
ENTRY mk, 389, 872
ENTRY mk, 389, 850
ENTRY mk, 389, 858

; ------------------------------------------------------------------------------
; Czech Republic - Country Code 420
; *** see Czechoslovakia (42) and Slovakia (421)
; Czech
; ------------------------------------------------------------------------------
ENTRY cz, 420, 852
ENTRY cz, 420, 850
ENTRY cz, 420, 858

; ------------------------------------------------------------------------------
; Slovakia - Country Code 421
; *** see Czechoslovakia (42) and Czech Republic (420)
; Slovak
; ------------------------------------------------------------------------------
ENTRY sk, 421, 852
ENTRY sk, 421, 850
ENTRY sk, 421, 858

; ------------------------------------------------------------------------------
; Middle East - Country Code 785
; *** xx is temporary place holder
; Middle Eastern (Arabic)
; ------------------------------------------------------------------------------
ENTRY xx, 785, 858
ENTRY xx, 785, 850
ENTRY xx, 785, 864

; ------------------------------------------------------------------------------
; Israel - Country Code 972
; Hebrew
; ------------------------------------------------------------------------------
ENTRY il, 972, 858
ENTRY il, 972, 850
ENTRY il, 972, 862

; ==============================================================================
; MULTILINGUAL COUNTRY ENTRIES (4x000 - 4x999)
; ==============================================================================
; These entries support multiple languages within a single country using
; a special encoding: language_variant (0-9) + country_code
; Format: 4xCCC where x = language variant (0-9), CCC = country code

; Macro: MULTILANG_ENTRY
; Creates a multilingual country entry structure
; Parameters:
;   %1 = 2-character language code (e.g., nl, fr, de)
;   %2 = 2-character country code (e.g., BE, ES, CH)
;   %3 = numerical country code (e.g., 30)
;   %4 = language variant number (0-9, prepended to country code as 4#)
;   %5 = codepage number (e.g., 850), pad with 0s e.g. 001 if less than 3 digits
;
; Example: MULTILANG_ENTRY fr, BE, 032, 1, 850
;   produces: __fr_BE_850 dw 12, 41032, 850, 0, 0
;             dd _fr_BE_850

%macro MULTILANG_ENTRY 5
__%1_%2_%5 dw 12, 4%4%3, %5, 0, 0
           dd _%1_%2_%5
%endmacro

; ------------------------------------------------------------------------------
; Belgium - Country Code 32 (Multilingual variants: 40032, 41032, 42032)
; Dutch (nl_BE), French (fr_BE), German (de_BE)
; ------------------------------------------------------------------------------
MULTILANG_ENTRY nl, BE, 032, 0, 850  ; Dutch (Flemish) Belgium
MULTILANG_ENTRY nl, BE, 032, 0, 858
MULTILANG_ENTRY nl, BE, 032, 0, 437

MULTILANG_ENTRY fr, BE, 032, 1, 850  ; French Belgium
MULTILANG_ENTRY fr, BE, 032, 1, 858
MULTILANG_ENTRY fr, BE, 032, 1, 437

MULTILANG_ENTRY de, BE, 032, 2, 850  ; German Belgium
MULTILANG_ENTRY de, BE, 032, 2, 858
MULTILANG_ENTRY de, BE, 032, 2, 437

; ------------------------------------------------------------------------------
; Spain - Country Code 34 (Multilingual variants: 40034, 41034, 42034, 43034)
; Spanish (es_ES), Catalan (ca_ES), Galician (gl_ES), Basque (eu_ES)
; ------------------------------------------------------------------------------
MULTILANG_ENTRY es, ES, 034, 0, 850  ; Spanish (Castilian) Spain
MULTILANG_ENTRY es, ES, 034, 0, 858
MULTILANG_ENTRY es, ES, 034, 0, 437

MULTILANG_ENTRY ca, ES, 034, 1, 850  ; Catalan Spain
MULTILANG_ENTRY ca, ES, 034, 1, 858
MULTILANG_ENTRY ca, ES, 034, 1, 437

MULTILANG_ENTRY gl, ES, 034, 2, 850  ; Galician Spain
MULTILANG_ENTRY gl, ES, 034, 2, 858
MULTILANG_ENTRY gl, ES, 034, 2, 437

MULTILANG_ENTRY eu, ES, 034, 3, 850  ; Basque Spain
MULTILANG_ENTRY eu, ES, 034, 3, 858
MULTILANG_ENTRY eu, ES, 034, 3, 437

; ------------------------------------------------------------------------------
; Switzerland - Country Code 41 (Multilingual variants: 40041, 41041, 42041)
; German (de_CH), French (fr_CH), Italian (it_CH)
; ------------------------------------------------------------------------------
MULTILANG_ENTRY de, CH, 041, 0, 858  ; German Switzerland
MULTILANG_ENTRY de, CH, 041, 0, 850
MULTILANG_ENTRY de, CH, 041, 0, 437

MULTILANG_ENTRY fr, CH, 041, 1, 858  ; French Switzerland
MULTILANG_ENTRY fr, CH, 041, 1, 850
MULTILANG_ENTRY fr, CH, 041, 1, 437

MULTILANG_ENTRY it, CH, 041, 2, 858  ; Italian Switzerland
MULTILANG_ENTRY it, CH, 041, 2, 850
MULTILANG_ENTRY it, CH, 041, 2, 437

; ==============================================================================
; SECTION 3: SUBFUNCTION HEADERS
; ==============================================================================
;
; Each country/codepage entry has a subfunction header that lists
; available subfunctions. 
; Structure:
;   - Word: Number of subfunctions
;   Then for each subfunction:
;     - Word: Entry size (always 6)
;     - Word: Subfunction ID (1,2,3,4,5,6,7,35)
;     - DWord: Offset to data
;
; Subfunction IDs:
;   1  = Country info (date/time/currency format)
;   2  = Uppercase table
;   3  = Lowercase table (optional, if different from uppercase)
;   4  = Filename uppercase table
;   5  = Filename character table
;   6  = Collating sequence table (sorting order)
;   7  = DBCS (Double Byte Character Set) table
;   35 = Yes/No prompt characters

; ------------------------------------------------------------------------------
; SUBFUNCTION HEADER MACROS
; ------------------------------------------------------------------------------

; Macro: SUBFUNC_HEADER
; Creates a standard subfunction header (7 subfunctions, no lowercase table)
; Parameters:
;   %1 = ISO country code (e.g., us, gr, nl)
;   %2 = codepage (e.g., 437, 850, 858)
;   %3 = collating sequence label (e.g., en_collate_437)
;   %4 = yes/no table label (e.g., en_yn, gr_yn_869)
;   %5 = DBCS table label (optional, defaults to dbcs_empty)
;
; Produces 7 subfunction entries (1,2,4,5,6,7,35)

%macro SUBFUNC_HEADER 4-5 dbcs_empty
_%1_%2 dw 7
       dw 6,1
         dd %1_%2
       dw 6,2
         dd ucase_%2
       dw 6,4
         dd ucase_%2
       dw 6,5
         dd fchar
       dw 6,6
         dd %3
       dw 6,7
         dd %5
       dw 6,35
         dd %4
%endmacro

%macro OLD_SUBFUNC_HEADER 4-5 dbcs_empty
%ifdef OBSOLETE
    SUBFUNC_HEADER %1 %2 %3 %4 %5
%endif
%endmacro

; Macro: SUBFUNC_HEADER_LCASE
; Creates a subfunction header with lowercase table (8 subfunctions)
; Parameters:
;   %1 = ISO country code (e.g., ru, bg, ua)
;   %2 = codepage (e.g., 866, 808, 849)
;   %3 = lowercase table label (e.g., lcase_866)
;   %4 = collating sequence label (e.g., ru_collate_866)
;   %5 = yes/no table label (e.g., ru_yn_866)
;   %6 = DBCS table label (optional, defaults to dbcs_empty)
;
; Produces 8 subfunction entries (1,2,3,4,5,6,7,35)

%macro SUBFUNC_HEADER_LCASE 5-6 dbcs_empty
_%1_%2 dw 8
       dw 6,1
         dd %1_%2
       dw 6,2
         dd ucase_%2
       dw 6,3
         dd %3
       dw 6,4
         dd ucase_%2
       dw 6,5
         dd fchar
       dw 6,6
         dd %4
       dw 6,7
         dd %6
       dw 6,35
         dd %5
%endmacro

; ------------------------------------------------------------------------------
; US (United States) - Country Code 1
; ------------------------------------------------------------------------------
SUBFUNC_HEADER us, 437, en_collate_437, en_yn
SUBFUNC_HEADER us, 850, en_collate_850, en_yn
SUBFUNC_HEADER us, 858, en_collate_858, en_yn

; ------------------------------------------------------------------------------
; Canada - Country Code 2
; ------------------------------------------------------------------------------
SUBFUNC_HEADER ca, 863, fr_collate_863, fr_yn
SUBFUNC_HEADER ca, 850, fr_collate_850, fr_yn
SUBFUNC_HEADER ca, 858, fr_collate_858, fr_yn

; ------------------------------------------------------------------------------
; Latin America - Country Code 3
; ------------------------------------------------------------------------------
SUBFUNC_HEADER la, 850, es_collate_850, es_yn
SUBFUNC_HEADER la, 858, es_collate_858, es_yn
SUBFUNC_HEADER la, 437, es_collate_437, es_yn

; ------------------------------------------------------------------------------
; Russia - Country Code 7
; ------------------------------------------------------------------------------
SUBFUNC_HEADER_LCASE ru, 866, lcase_866, ru_collate_866, ru_yn_866
SUBFUNC_HEADER_LCASE ru, 808, lcase_808, ru_collate_808, ru_yn_808
SUBFUNC_HEADER ru, 855, ru_collate_855, ru_yn_855
SUBFUNC_HEADER ru, 872, ru_collate_872, ru_yn_872
SUBFUNC_HEADER ru, 852, ru_collate_852, ru_yn
SUBFUNC_HEADER ru, 850, ru_collate_850, ru_yn
SUBFUNC_HEADER ru, 858, ru_collate_858, ru_yn
SUBFUNC_HEADER ru, 437, ru_collate_437, ru_yn

; ------------------------------------------------------------------------------
; South Africa - Country Code 27
; ------------------------------------------------------------------------------
SUBFUNC_HEADER za, 858, en_collate_858, en_yn
SUBFUNC_HEADER za, 850, en_collate_850, en_yn
SUBFUNC_HEADER za, 437, en_collate_437, en_yn

; ------------------------------------------------------------------------------
; Greece - Country Code 30
; ------------------------------------------------------------------------------
SUBFUNC_HEADER gr, 869, gr_collate_869, gr_yn_869
SUBFUNC_HEADER gr, 737, gr_collate_737, gr_yn_737
SUBFUNC_HEADER gr, 850, gr_collate_850, gr_yn
SUBFUNC_HEADER gr, 858, gr_collate_858, gr_yn

; ------------------------------------------------------------------------------
; Netherlands - Country Code 31
; ------------------------------------------------------------------------------
SUBFUNC_HEADER nl, 850, nl_collate_850, nl_yn
SUBFUNC_HEADER nl, 858, nl_collate_858, nl_yn
SUBFUNC_HEADER nl, 437, nl_collate_437, nl_yn

; ------------------------------------------------------------------------------
; Belgium - Country Code 32
; ------------------------------------------------------------------------------
SUBFUNC_HEADER be, 850, be_collate_850, nl_yn
SUBFUNC_HEADER be, 858, be_collate_858, nl_yn
SUBFUNC_HEADER be, 437, be_collate_437, nl_yn

; ------------------------------------------------------------------------------
; France - Country Code 33
; ------------------------------------------------------------------------------
SUBFUNC_HEADER fr, 850, fr_collate_850, fr_yn
SUBFUNC_HEADER fr, 858, fr_collate_858, fr_yn
SUBFUNC_HEADER fr, 437, fr_collate_437, fr_yn

; ------------------------------------------------------------------------------
; Spain - Country Code 34
; ------------------------------------------------------------------------------
SUBFUNC_HEADER es, 850, es_collate_850, es_yn
SUBFUNC_HEADER es, 858, es_collate_858, es_yn
SUBFUNC_HEADER es, 437, es_collate_437, es_yn

; ------------------------------------------------------------------------------
; Hungary - Country Code 36
; ------------------------------------------------------------------------------
SUBFUNC_HEADER hu, 852, hu_collate_852, hu_yn
SUBFUNC_HEADER hu, 850, hu_collate_850, hu_yn
SUBFUNC_HEADER hu, 858, hu_collate_858, hu_yn

; ------------------------------------------------------------------------------
; Yugoslavia - Country Code 38 [OBSOLETE]
; ------------------------------------------------------------------------------
OLD_SUBFUNC_HEADER yu, 852, sh_collate_852, sh_yn
OLD_SUBFUNC_HEADER yu, 855, sh_collate_855, sh_yn_855
OLD_SUBFUNC_HEADER yu, 872, sh_collate_872, sh_yn_872
OLD_SUBFUNC_HEADER yu, 850, sh_collate_850, sh_yn
OLD_SUBFUNC_HEADER yu, 858, sh_collate_858, sh_yn

; ------------------------------------------------------------------------------
; Italy - Country Code 39
; ------------------------------------------------------------------------------
SUBFUNC_HEADER it, 850, it_collate_850, it_yn
SUBFUNC_HEADER it, 858, it_collate_858, it_yn
SUBFUNC_HEADER it, 437, it_collate_437, it_yn

; ------------------------------------------------------------------------------
; Romania - Country Code 40
; ------------------------------------------------------------------------------
SUBFUNC_HEADER ro, 852, ro_collate_852, ro_yn
SUBFUNC_HEADER ro, 850, ro_collate_850, ro_yn
SUBFUNC_HEADER ro, 858, ro_collate_858, ro_yn

; ------------------------------------------------------------------------------
; Switzerland - Country Code 41
; ------------------------------------------------------------------------------
SUBFUNC_HEADER ch, 850, ch_collate_850, de_yn
SUBFUNC_HEADER ch, 858, ch_collate_858, de_yn
SUBFUNC_HEADER ch, 437, ch_collate_437, de_yn

; ------------------------------------------------------------------------------
; Czechoslovakia - Country Code 42
; *** see Czech Republic (420) and Slovakia (421)
; ------------------------------------------------------------------------------
;OLD_SUBFUNC_HEADER cz, 852, cz_collate_852, cz_yn
;OLD_SUBFUNC_HEADER cz, 850, cz_collate_850, cz_yn
;OLD_SUBFUNC_HEADER cz, 858, cz_collate_858, cz_yn

; ------------------------------------------------------------------------------
; Austria - Country Code 43
; ------------------------------------------------------------------------------
SUBFUNC_HEADER at, 850, de_collate_850, de_yn
SUBFUNC_HEADER at, 858, de_collate_858, de_yn
SUBFUNC_HEADER at, 437, de_collate_437, de_yn

; ------------------------------------------------------------------------------
; United Kingdom - Country Code 44
; ------------------------------------------------------------------------------
SUBFUNC_HEADER gb, 850, en_collate_850, en_yn
SUBFUNC_HEADER gb, 858, en_collate_858, en_yn
SUBFUNC_HEADER gb, 437, en_collate_437, en_yn

; ------------------------------------------------------------------------------
; Denmark - Country Code 45
; ------------------------------------------------------------------------------
SUBFUNC_HEADER dk, 865, dk_collate_865, dk_yn
SUBFUNC_HEADER dk, 850, dk_collate_850, dk_yn
SUBFUNC_HEADER dk, 858, dk_collate_858, dk_yn

; ------------------------------------------------------------------------------
; Sweden - Country Code 46
; ------------------------------------------------------------------------------
SUBFUNC_HEADER se, 865, se_collate_865, se_yn
SUBFUNC_HEADER se, 850, se_collate_850, se_yn
SUBFUNC_HEADER se, 858, se_collate_858, se_yn
SUBFUNC_HEADER se, 437, se_collate_437, se_yn

; ------------------------------------------------------------------------------
; Norway - Country Code 47
; ------------------------------------------------------------------------------
SUBFUNC_HEADER no, 865, no_collate_865, no_yn
SUBFUNC_HEADER no, 850, no_collate_850, no_yn
SUBFUNC_HEADER no, 858, no_collate_858, no_yn

; ------------------------------------------------------------------------------
; Poland - Country Code 48
; ------------------------------------------------------------------------------
SUBFUNC_HEADER pl, 852, pl_collate_852, pl_yn
SUBFUNC_HEADER pl, 850, pl_collate_850, pl_yn
SUBFUNC_HEADER pl, 858, pl_collate_858, pl_yn

; ------------------------------------------------------------------------------
; Germany - Country Code 49
; ------------------------------------------------------------------------------
SUBFUNC_HEADER de, 850, de_collate_850, de_yn
SUBFUNC_HEADER de, 858, de_collate_858, de_yn
SUBFUNC_HEADER de, 437, de_collate_437, de_yn

; ------------------------------------------------------------------------------
; Mexico - Country Code 52
; ------------------------------------------------------------------------------
SUBFUNC_HEADER mx, 850, es_collate_850, es_yn
SUBFUNC_HEADER mx, 858, es_collate_858, es_yn
SUBFUNC_HEADER mx, 437, es_collate_437, es_yn

; ------------------------------------------------------------------------------
; Argentina - Country Code 54
; ------------------------------------------------------------------------------
SUBFUNC_HEADER ar, 437, es_collate_437, es_yn
SUBFUNC_HEADER ar, 850, es_collate_850, es_yn
SUBFUNC_HEADER ar, 858, es_collate_858, es_yn

; ------------------------------------------------------------------------------
; Brazil - Country Code 55
; ------------------------------------------------------------------------------
SUBFUNC_HEADER br, 850, pt_collate_850, pt_yn
SUBFUNC_HEADER br, 858, pt_collate_858, pt_yn
SUBFUNC_HEADER br, 437, pt_collate_437, pt_yn

; ------------------------------------------------------------------------------
; Malaysia - Country Code 60
; ------------------------------------------------------------------------------
SUBFUNC_HEADER my, 437, en_collate_437, en_yn

; ------------------------------------------------------------------------------
; Australia - Country Code 61
; ------------------------------------------------------------------------------
SUBFUNC_HEADER au, 437, en_collate_437, en_yn
SUBFUNC_HEADER au, 850, en_collate_850, en_yn
SUBFUNC_HEADER au, 858, en_collate_858, en_yn

; ------------------------------------------------------------------------------
; Indonesia - Country Code 62
; ------------------------------------------------------------------------------
SUBFUNC_HEADER id, 850, en_collate_850, id_yn
SUBFUNC_HEADER id, 437, en_collate_437, id_yn

; ------------------------------------------------------------------------------
; Philippines - Country Code 63
; ------------------------------------------------------------------------------
SUBFUNC_HEADER ph, 850, en_collate_850, ph_yn
SUBFUNC_HEADER ph, 437, en_collate_437, ph_yn

; ------------------------------------------------------------------------------
; New Zealand - Country Code 64
; ------------------------------------------------------------------------------
SUBFUNC_HEADER nz, 850, en_collate_850, en_yn
SUBFUNC_HEADER nz, 858, en_collate_858, en_yn
SUBFUNC_HEADER nz, 437, en_collate_437, en_yn

; ------------------------------------------------------------------------------
; Singapore - Country Code 65
; ------------------------------------------------------------------------------
SUBFUNC_HEADER sg, 437, en_collate_437, en_yn

; ------------------------------------------------------------------------------
; Thailand - Country Code 66
; ------------------------------------------------------------------------------
SUBFUNC_HEADER th, 874, th_collate_874, en_yn
SUBFUNC_HEADER th, 850, en_collate_850, en_yn
SUBFUNC_HEADER th, 437, en_collate_437, en_yn

; ------------------------------------------------------------------------------
; Japan - Country Code 81
; ------------------------------------------------------------------------------
SUBFUNC_HEADER jp, 437, en_collate_437, en_yn  ; Japanese MS-DOS uses "Y" and "N" - Yuki
SUBFUNC_HEADER jp, 932, jp_collate_932, en_yn, jp_dbcs_932

; ------------------------------------------------------------------------------
; South Korea - Country Code 82
; ------------------------------------------------------------------------------
SUBFUNC_HEADER kr, 437, en_collate_437, kr_yn
SUBFUNC_HEADER kr, 934, kr_collate_934, kr_yn, kr_dbcs_934

; ------------------------------------------------------------------------------
; Vietnam - Country Code 84
; ------------------------------------------------------------------------------
SUBFUNC_HEADER vn, 1258, vn_collate_1258, vn_yn
SUBFUNC_HEADER vn, 850, en_collate_850, vn_yn
SUBFUNC_HEADER vn, 437, en_collate_437, vn_yn

; ------------------------------------------------------------------------------
; China - Country Code 86
; ------------------------------------------------------------------------------
SUBFUNC_HEADER cn, 437, en_collate_437, cn_yn
SUBFUNC_HEADER cn, 936, cn_collate_936, cn_yn_936, cn_dbcs_936

; ------------------------------------------------------------------------------
; Turkey - Country Code 90
; ------------------------------------------------------------------------------
SUBFUNC_HEADER tr, 857, tr_collate_857, tr_yn
SUBFUNC_HEADER tr, 850, tr_collate_850, tr_yn
SUBFUNC_HEADER tr, 858, tr_collate_858, tr_yn

; ------------------------------------------------------------------------------
; India - Country Code 91
; ------------------------------------------------------------------------------
SUBFUNC_HEADER in, 437, en_collate_437, en_yn

; ------------------------------------------------------------------------------
; Portugal - Country Code 351
; ------------------------------------------------------------------------------
SUBFUNC_HEADER pt, 860, pt_collate_860, pt_yn
SUBFUNC_HEADER pt, 850, pt_collate_850, pt_yn
SUBFUNC_HEADER pt, 858, pt_collate_858, pt_yn

; ------------------------------------------------------------------------------
; Luxembourg - Country Code 352
; ------------------------------------------------------------------------------
SUBFUNC_HEADER lu, 850, fr_collate_850, fr_yn
SUBFUNC_HEADER lu, 858, fr_collate_858, fr_yn
SUBFUNC_HEADER lu, 437, fr_collate_437, fr_yn

; ------------------------------------------------------------------------------
; Ireland - Country Code 353
; ------------------------------------------------------------------------------
SUBFUNC_HEADER ie, 850, en_collate_850, en_yn
SUBFUNC_HEADER ie, 858, en_collate_858, en_yn
SUBFUNC_HEADER ie, 437, en_collate_437, en_yn

; ------------------------------------------------------------------------------
; Iceland - Country Code 354
; ------------------------------------------------------------------------------
SUBFUNC_HEADER is, 861, is_collate_861, is_yn
SUBFUNC_HEADER is, 865, is_collate_865, is_yn
SUBFUNC_HEADER is, 850, is_collate_850, is_yn
SUBFUNC_HEADER is, 858, is_collate_858, is_yn

; ------------------------------------------------------------------------------
; Albania - Country Code 355
; ------------------------------------------------------------------------------
SUBFUNC_HEADER al, 852, al_collate_852, al_yn
SUBFUNC_HEADER al, 850, en_collate_850, al_yn
SUBFUNC_HEADER al, 858, en_collate_858, al_yn

; ------------------------------------------------------------------------------
; Malta - Country Code 356
; ------------------------------------------------------------------------------
SUBFUNC_HEADER mt, 850, en_collate_850, mt_yn
SUBFUNC_HEADER mt, 858, en_collate_858, mt_yn
SUBFUNC_HEADER mt, 437, en_collate_437, mt_yn

; ------------------------------------------------------------------------------
; Cyprus - Country Code 357
; ------------------------------------------------------------------------------
SUBFUNC_HEADER cy, 869, gr_collate_869, cy_yn_869
SUBFUNC_HEADER cy, 850, en_collate_850, cy_yn
SUBFUNC_HEADER cy, 858, en_collate_858, cy_yn

; ------------------------------------------------------------------------------
; Finland - Country Code 358
; ------------------------------------------------------------------------------
SUBFUNC_HEADER fi, 865, fi_collate_865, fi_yn
SUBFUNC_HEADER fi, 850, fi_collate_850, fi_yn
SUBFUNC_HEADER fi, 858, fi_collate_858, fi_yn
SUBFUNC_HEADER fi, 437, fi_collate_437, fi_yn

; ------------------------------------------------------------------------------
; Bulgaria - Country Code 359
; ------------------------------------------------------------------------------
SUBFUNC_HEADER bg, 855, bg_collate_855, bg_yn_855
SUBFUNC_HEADER bg, 872, bg_collate_872, bg_yn_872
SUBFUNC_HEADER bg, 850, bg_collate_850, bg_yn
SUBFUNC_HEADER bg, 858, bg_collate_858, bg_yn
SUBFUNC_HEADER_LCASE bg, 866, lcase_866, bg_collate_866, bg_yn_866
SUBFUNC_HEADER_LCASE bg, 808, lcase_808, bg_collate_808, bg_yn_808
SUBFUNC_HEADER_LCASE bg, 849, lcase_849, bg_collate_849, bg_yn_849
SUBFUNC_HEADER_LCASE bg, 1131, lcase_1131, bg_collate_1131, bg_yn_1131
SUBFUNC_HEADER_LCASE bg, 30033, lcase_30033, bg_collate_30033, bg_yn_30033

; ------------------------------------------------------------------------------
; Lithuania - Country Code 370
; ------------------------------------------------------------------------------
SUBFUNC_HEADER lt, 775, lt_collate_775, lt_yn
SUBFUNC_HEADER lt, 850, lt_collate_850, lt_yn
SUBFUNC_HEADER lt, 858, lt_collate_858, lt_yn

; ------------------------------------------------------------------------------
; Latvia - Country Code 371
; ------------------------------------------------------------------------------
SUBFUNC_HEADER lv, 775, lv_collate_775, lv_yn
SUBFUNC_HEADER lv, 850, lv_collate_850, lv_yn
SUBFUNC_HEADER lv, 858, lv_collate_858, lv_yn

; ------------------------------------------------------------------------------
; Estonia - Country Code 372
; ------------------------------------------------------------------------------
SUBFUNC_HEADER ee, 775, ee_collate_775, ee_yn
SUBFUNC_HEADER ee, 850, ee_collate_850, ee_yn
SUBFUNC_HEADER ee, 858, ee_collate_858, ee_yn

; ------------------------------------------------------------------------------
; Belarus - Country Code 375
; ------------------------------------------------------------------------------
SUBFUNC_HEADER_LCASE by, 849, lcase_849, by_collate_849, by_yn_849
SUBFUNC_HEADER_LCASE by, 1131, lcase_1131, by_collate_1131, by_yn_1131
SUBFUNC_HEADER by, 850, by_collate_850, by_yn
SUBFUNC_HEADER by, 858, by_collate_858, by_yn

; ------------------------------------------------------------------------------
; Ukraine - Country Code 380
; ------------------------------------------------------------------------------
SUBFUNC_HEADER_LCASE ua, 848, lcase_848, ua_collate_848, ua_yn_848
SUBFUNC_HEADER_LCASE ua, 855, lcase_855, ua_collate_855, ua_yn_848
SUBFUNC_HEADER_LCASE ua, 1125, lcase_1125, ua_collate_1125, ua_yn_1125
SUBFUNC_HEADER_LCASE ua, 866, lcase_866, ua_collate_866, ua_yn_1125

; ------------------------------------------------------------------------------
; Serbia - Country Code 381
; ------------------------------------------------------------------------------
SUBFUNC_HEADER rs, 852, sh_collate_852, sh_yn
SUBFUNC_HEADER rs, 855, sh_collate_855, sh_yn_855
SUBFUNC_HEADER rs, 872, sh_collate_872, sh_yn_872
SUBFUNC_HEADER rs, 850, sh_collate_850, sh_yn
SUBFUNC_HEADER rs, 858, sh_collate_858, sh_yn

; ------------------------------------------------------------------------------
; Montenegro - Country Code 382
; ------------------------------------------------------------------------------
SUBFUNC_HEADER me, 852, sh_collate_852, sh_yn
SUBFUNC_HEADER me, 855, sh_collate_855, sh_yn_855
SUBFUNC_HEADER me, 872, sh_collate_872, sh_yn_855
SUBFUNC_HEADER me, 850, sh_collate_850, sh_yn
SUBFUNC_HEADER me, 858, sh_collate_858, sh_yn

; ------------------------------------------------------------------------------
; Kosovo - Country Code 383
; ------------------------------------------------------------------------------
SUBFUNC_HEADER xk, 852, xk_collate_852, al_yn
SUBFUNC_HEADER xk, 855, xk_collate_855, al_yn
SUBFUNC_HEADER xk, 872, xk_collate_872, al_yn
SUBFUNC_HEADER xk, 850, xk_collate_850, al_yn
SUBFUNC_HEADER xk, 858, xk_collate_858, al_yn

; ------------------------------------------------------------------------------
; Croatia - Country Code 385
; ------------------------------------------------------------------------------
SUBFUNC_HEADER hr, 852, hr_collate_852, hr_yn
SUBFUNC_HEADER hr, 850, hr_collate_850, hr_yn
SUBFUNC_HEADER hr, 858, hr_collate_858, hr_yn

; ------------------------------------------------------------------------------
; Slovenia - Country Code 386
; ------------------------------------------------------------------------------
SUBFUNC_HEADER si, 852, si_collate_852, si_yn
SUBFUNC_HEADER si, 850, si_collate_850, si_yn
SUBFUNC_HEADER si, 858, si_collate_858, si_yn

; ------------------------------------------------------------------------------
; Bosnia-Herzegovina - Country Code 387
; ------------------------------------------------------------------------------
SUBFUNC_HEADER ba, 852, sh_collate_852, sh_yn
SUBFUNC_HEADER ba, 850, sh_collate_850, sh_yn
SUBFUNC_HEADER ba, 858, sh_collate_858, sh_yn
SUBFUNC_HEADER ba, 855, sh_collate_855, sh_yn_855
SUBFUNC_HEADER ba, 872, sh_collate_872, sh_yn_872

; ------------------------------------------------------------------------------
; North Macedonia - Country Code 389
; ------------------------------------------------------------------------------
SUBFUNC_HEADER mk, 855, mk_collate_855, mk_yn_855
SUBFUNC_HEADER mk, 872, mk_collate_872, mk_yn_872
SUBFUNC_HEADER mk, 850, mk_collate_850, mk_yn
SUBFUNC_HEADER mk, 858, mk_collate_858, mk_yn

; ------------------------------------------------------------------------------
; Czech Republic - Country Code 420
; *** see Czechoslovakia (42) and Slovakia (421)
; ------------------------------------------------------------------------------
SUBFUNC_HEADER cz, 852, cz_collate_852, cz_yn
SUBFUNC_HEADER cz, 850, cz_collate_850, cz_yn
SUBFUNC_HEADER cz, 858, cz_collate_858, cz_yn

; ------------------------------------------------------------------------------
; Slovakia - Country Code 421
; *** see Czechoslovakia (42) and Czech Republic (420)
; ------------------------------------------------------------------------------
SUBFUNC_HEADER sk, 852, sk_collate_852, sk_yn
SUBFUNC_HEADER sk, 850, sk_collate_850, sk_yn
SUBFUNC_HEADER sk, 858, sk_collate_858, sk_yn

; ------------------------------------------------------------------------------
; Middle East - Country Code 785
; ------------------------------------------------------------------------------
SUBFUNC_HEADER xx, 850, xx_collate_850, xx_yn
SUBFUNC_HEADER xx, 858, xx_collate_858, xx_yn
SUBFUNC_HEADER xx, 864, xx_collate_864, xx_yn_864

; ------------------------------------------------------------------------------
; Israel - Country Code 972
; ------------------------------------------------------------------------------
SUBFUNC_HEADER il, 850, il_collate_850, il_yn
SUBFUNC_HEADER il, 858, il_collate_858, il_yn
SUBFUNC_HEADER il, 862, il_collate_862, il_yn_862

; ==============================================================================
; MULTILINGUAL COUNTRY SUBFUNCTION HEADERS
; ==============================================================================

; ------------------------------------------------------------------------------
; Belgium Multilingual - Dutch (nl_BE)
; ------------------------------------------------------------------------------
SUBFUNC_HEADER nl_BE, 850, nl_collate_850, nl_yn
SUBFUNC_HEADER nl_BE, 858, nl_collate_858, nl_yn
SUBFUNC_HEADER nl_BE, 437, nl_collate_437, nl_yn

; ------------------------------------------------------------------------------
; Belgium Multilingual - French (fr_BE)
; ------------------------------------------------------------------------------
SUBFUNC_HEADER fr_BE, 850, fr_collate_850, fr_yn
SUBFUNC_HEADER fr_BE, 858, fr_collate_858, fr_yn
SUBFUNC_HEADER fr_BE, 437, fr_collate_437, fr_yn

; ------------------------------------------------------------------------------
; Belgium Multilingual - German (de_BE)
; ------------------------------------------------------------------------------
SUBFUNC_HEADER de_BE, 850, de_collate_850, de_yn
SUBFUNC_HEADER de_BE, 858, de_collate_858, de_yn
SUBFUNC_HEADER de_BE, 437, de_collate_437, de_yn

; ------------------------------------------------------------------------------
; Spain Multilingual - Spanish (es_ES)
; ------------------------------------------------------------------------------
SUBFUNC_HEADER es_ES, 850, es_collate_850, es_yn
SUBFUNC_HEADER es_ES, 858, es_collate_858, es_yn
SUBFUNC_HEADER es_ES, 437, es_collate_437, es_yn

; ------------------------------------------------------------------------------
; Spain Multilingual - Catalan (ca_ES)
; ------------------------------------------------------------------------------
SUBFUNC_HEADER ca_ES, 850, ca_collate_850, ca_yn
SUBFUNC_HEADER ca_ES, 858, ca_collate_858, ca_yn
SUBFUNC_HEADER ca_ES, 437, ca_collate_437, ca_yn

; ------------------------------------------------------------------------------
; Spain Multilingual - Galician (gl_ES)
; ------------------------------------------------------------------------------
SUBFUNC_HEADER gl_ES, 850, gl_collate_850, gl_yn
SUBFUNC_HEADER gl_ES, 858, gl_collate_858, gl_yn
SUBFUNC_HEADER gl_ES, 437, gl_collate_437, gl_yn

; ------------------------------------------------------------------------------
; Spain Multilingual - Basque (eu_ES)
; ------------------------------------------------------------------------------
SUBFUNC_HEADER eu_ES, 850, eu_collate_850, eu_yn
SUBFUNC_HEADER eu_ES, 858, eu_collate_858, eu_yn
SUBFUNC_HEADER eu_ES, 437, eu_collate_437, eu_yn

; ------------------------------------------------------------------------------
; Switzerland Multilingual - German (de_CH)
; ------------------------------------------------------------------------------
SUBFUNC_HEADER de_CH, 850, de_collate_850, de_yn
SUBFUNC_HEADER de_CH, 858, de_collate_858, de_yn
SUBFUNC_HEADER de_CH, 437, de_collate_437, de_yn

; ------------------------------------------------------------------------------
; Switzerland Multilingual - French (fr_CH)
; ------------------------------------------------------------------------------
SUBFUNC_HEADER fr_CH, 850, fr_collate_850, fr_yn
SUBFUNC_HEADER fr_CH, 858, fr_collate_858, fr_yn
SUBFUNC_HEADER fr_CH, 437, fr_collate_437, fr_yn

; ------------------------------------------------------------------------------
; Switzerland Multilingual - Italian (it_CH)
; ------------------------------------------------------------------------------
SUBFUNC_HEADER it_CH, 850, it_collate_850, it_yn
SUBFUNC_HEADER it_CH, 858, it_collate_858, it_yn
SUBFUNC_HEADER it_CH, 437, it_collate_437, it_yn

; ==============================================================================
; SECTION 4: COUNTRY INFORMATION TABLES (Subfunction 1 Data)
; ==============================================================================
;
; Country information defines localized date/time/currency formats.
; Each entry is created using the 'cnf' macro (country info).

%define MDY 0 ; month/day/year
%define DMY 1 ; day/month/year
%define YMD 2 ; year/month/day

%define _12 0 ; time as AM/PM
%define _24 1 ; 24-hour format

; Country ID  : international numbering
; Codepage    : codepage to use by default
; Date format : M = Month, D = Day, Y = Year (4digit); 0=USA, 1=Europe, 2=Japan
; Currency    : $ = dollar, EUR = EURO (ALT-128), UK uses the pound sign
; Thousands   : separator for 1000s (1,000,000 bytes; Dutch: 1.000.000 bytes)
; Decimals    : separator for decimals (2.5 KB; Dutch: 2,5 KB)
; Datesep     : Date separator (2/4/2004 or 2-4-2004 for example)
; Timesep     : usually ":" is used to separate hours, minutes and seconds
; Currencyf   : Currency format (bit array)
;		bit 2 = set if currency symbol replaces decimal point
;		bit 1 = number of spaces between value and currency symbol
;		bit 0 = 0 if currency symbol precedes value
;			  = 1 if currency symbol follows value
; Currencyp   : Currency precision
; Time format : 0=12 hour format (AM/PM), 1=24 hour format (4:12 PM is 16:12)

; ------------------------------------------------------------------------------
; Macro: cnf (Country Info)
; ------------------------------------------------------------------------------
;
; Parameters:
;   %1  - Country ID (international phone code)
;   %2  - Codepage number
;   %3  - Date format (MDY=0, DMY=1, YMD=2)
;   %4-8 - Currency symbol (up to 5 bytes, null-terminated)
;   %9  - Thousands separator (e.g., ',' or '.')
;   %10 - Decimal separator (e.g., '.' or ',')
;   %11 - Date separator (e.g., '/', '-', '.')
;   %12 - Time separator (usually ':')
;   %13 - Currency format flags:
;          bit 0: 0=symbol precedes value, 1=symbol follows value
;          bit 1: number of spaces between value and symbol
;          bit 2: 1=symbol replaces decimal point
;   %14 - Currency precision (decimal places)
;   %15 - Time format (0=12-hour with AM/PM, 1=24-hour)
;
; The macro generates a structure with signature 0FFh,'CTYINFO'
;

%macro cnf 15
   db 0FFh,"CTYINFO"
   dw 22              ; length
   dw %1,%2,%3        ; id, CP=codepage, DF=date format
   db %4,%5,%6,%7,%8  ; currency - 5 byte ASCIIZ and trailing 0 padded
   dw %9,%10,%11,%12  ; 1000, 0.1, DS=date separator, TS=time separator
   db %13,%14,%15     ; CF=currency format, Pr=currency precision, TF=time format
%endmacro;
;            ID CP DF  currency       1000 0.1 DS  TS CF Pr TF Country Contrib
; Note: Euro represented by "EUR" or Euro symbol 0D5h (cp 858) & 0CFh (cp 872)
; ------------------------------------------------------------------------------
us_437 cnf   1,437,MDY,"$",    0,0,0,0,",",".","-",":",0,2,_12; United States
us_850 cnf   1,850,MDY,"$",    0,0,0,0,",",".","-",":",0,2,_12; United States
us_858 cnf   1,858,MDY,"$",    0,0,0,0,",",".","-",":",0,2,_12; United States
ca_863 cnf   2,863,YMD,"$",    0,0,0,0," ",",","-",":",3,2,_24; Canada-French
ca_850 cnf   2,850,YMD,"$",    0,0,0,0," ",",","-",":",3,2,_24; Canada-French
ca_858 cnf   2,858,YMD,"$",    0,0,0,0," ",",","-",":",3,2,_24; Canada-French
la_850 cnf   3,850,DMY,"$",    0,0,0,0,",",".","/",":",0,2,_12; Latin America
la_858 cnf   3,858,DMY,"$",    0,0,0,0,",",".","/",":",0,2,_12; Latin America
la_437 cnf   3,437,DMY,"$",    0,0,0,0,",",".","/",":",0,2,_12; Latin America
ru_866 cnf   7,866,DMY,0E0h,".", 0,0,0," ",",",".",":",3,2,_24; Russia	 Arkady
ru_808 cnf   7,808,DMY,0E0h,".", 0,0,0," ",",",".",":",3,2,_24; Russia
ru_855 cnf   7,855,DMY,0E1h,".", 0,0,0," ",",",".",":",3,2,_24; Russia
ru_872 cnf   7,872,DMY,0E1h,".", 0,0,0," ",",",".",":",3,2,_24; Russia
ru_852 cnf   7,852,DMY,"R","U","B",0,0," ",",",".",":",3,2,_24; Russia
ru_850 cnf   7,850,DMY,"R","U","B",0,0," ",",",".",":",3,2,_24; Russia
ru_858 cnf   7,858,DMY,"R","U","B",0,0," ",",",".",":",3,2,_24; Russia
ru_437 cnf   7,437,DMY,"R","U","B",0,0," ",",",".",":",3,2,_24; Russia
za_858 cnf  27,858,YMD,"R",    0,0,0,0," ",",","/",":",0,2,_24; South Africa
za_850 cnf  27,850,YMD,"R",    0,0,0,0," ",",","/",":",0,2,_24; South Africa
za_437 cnf  27,437,YMD,"R",    0,0,0,0," ",",","/",":",0,2,_24; South Africa
gr_869 cnf  30,869,DMY,0A8h,0D1h,0C7h,0,0,".",",","/",":",1,2,_12; Greece
gr_737 cnf  30,737,DMY,84h,93h,90h,0,0,".",",","/",":",1,2,_12; Greece
gr_850 cnf  30,850,DMY,"E","Y","P",0,0,".",",","/",":",1,2,_12; Greece
gr_858 cnf  30,858,DMY,0D5h,   0,0,0,0,".",",","/",":",1,2,_12; Greece
nl_850 cnf  31,850,DMY,"E","U","R",0,0,".",",","-",":",0,2,_24; Netherlands Bart
nl_858 cnf  31,858,DMY,0D5h,   0,0,0,0,".",",","-",":",0,2,_24; Netherlands
nl_437 cnf  31,437,DMY,"E","U","R",0,0,".",",","-",":",0,2,_24; Netherlands
be_850 cnf  32,850,DMY,"E","U","R",0,0,".",",","/",":",0,2,_24; Belgium
be_858 cnf  32,858,DMY,0D5h,   0,0,0,0,".",",","/",":",0,2,_24; Belgium
be_437 cnf  32,437,DMY,"E","U","R",0,0,".",",","/",":",0,2,_24; Belgium
fr_850 cnf  33,850,DMY,"E","U","R",0,0," ",",",".",":",0,2,_24; France
fr_858 cnf  33,858,DMY,0D5h,   0,0,0,0," ",",",".",":",0,2,_24; France
fr_437 cnf  33,437,DMY,"E","U","R",0,0," ",",",".",":",0,2,_24; France
es_850 cnf  34,850,DMY,"E","U","R",0,0,".",",","/",":",0,2,_24; Spain	  Aitor
es_858 cnf  34,858,DMY,0D5h,   0,0,0,0,".",",","/",":",0,2,_24; Spain
es_437 cnf  34,437,DMY,"E","U","R",0,0,".",",","/",":",0,2,_24; Spain
hu_852 cnf  36,852,YMD,"F","t",	 0,0,0," ",",",".",":",3,2,_24; Hungary
hu_850 cnf  36,850,YMD,"F","t",	 0,0,0," ",",",".",":",3,2,_24; Hungary
hu_858 cnf  36,858,YMD,"F","t",	 0,0,0," ",",",".",":",3,2,_24; Hungary
%ifdef OBSOLETE
yu_852 cnf  38,852,YMD,"D","i","n",0,0,".",",","-",":",2,2,_24; Yugoslavia [OBSOLETE]
yu_855 cnf  38,855,YMD,0A7h,0B7h,0D4h,0,0,".",",","-",":",2,2,_24; Yugoslavia [OBSOLETE]
yu_872 cnf  38,872,YMD,0A7h,0B7h,0D4h,0,0,".",",","-",":",2,2,_24; Yugoslavia [OBSOLETE]
yu_850 cnf  38,850,YMD,"D","i","n",0,0,".",",","-",":",2,2,_24; Yugoslavia [OBSOLETE]
yu_858 cnf  38,858,YMD,"D","i","n",0,0,".",",","-",":",2,2,_24; Yugoslavia [OBSOLETE]
%endif
it_850 cnf  39,850,DMY,"E","U","R",0,0,".",",","/",".",0,2,_24; Italy
it_858 cnf  39,858,DMY,0D5h,   0,0,0,0,".",",","/",".",0,2,_24; Italy
it_437 cnf  39,437,DMY,"E","U","R",0,0,".",",","/",".",0,2,_24; Italy
ro_852 cnf  40,852,YMD,"L","e","i",0,0,".",",","-",":",0,2,_24; Romania
ro_850 cnf  40,850,YMD,"L","e","i",0,0,".",",","-",":",0,2,_24; Romania
ro_858 cnf  40,858,YMD,"L","e","i",0,0,".",",","-",":",0,2,_24; Romania
ch_850 cnf  41,850,DMY,"F","r",".",0,0,"'",".",".",",",2,2,_24; Switzerland
ch_858 cnf  41,858,DMY,"F","r",".",0,0,"'",".",".",",",2,2,_24; Switzerland
ch_437 cnf  41,437,DMY,"F","r",".",0,0,"'",".",".",",",2,2,_24; Switzerland
;cz_852 cnf  42,852,DMY,"K","c",  0,0,0,".",",","-",":",2,2,_24; Czechoslovakia
;cz_850 cnf  42,850,DMY,"K","c",  0,0,0,".",",","-",":",2,2,_24; Czechoslovakia
;cz_858 cnf  42,858,DMY,"K","c",  0,0,0,".",",","-",":",2,2,_24; Czechoslovakia
at_850 cnf  43,850,DMY,"E","U","R",0,0,".",",",".",".",0,2,_24; Austria
at_858 cnf  43,858,DMY,0D5h,   0,0,0,0,".",",",".",".",0,2,_24; Austria
at_437 cnf  43,437,DMY,"E","U","R",0,0,".",",",".",".",0,2,_24; Austria
gb_850 cnf  44,850,DMY,9Ch,    0,0,0,0,",",".","/",":",0,2,_24; United Kingdom
gb_858 cnf  44,858,DMY,9Ch,    0,0,0,0,",",".","/",":",0,2,_24; United Kingdom
gb_437 cnf  44,437,DMY,9Ch,    0,0,0,0,",",".","/",":",0,2,_24; United Kingdom
dk_865 cnf  45,865,DMY,"k","r",	 0,0,0,".",",","-",".",2,2,_24; Denmark
dk_850 cnf  45,850,DMY,"k","r",	 0,0,0,".",",","-",".",2,2,_24; Denmark
dk_858 cnf  45,858,DMY,"k","r",	 0,0,0,".",",","-",".",2,2,_24; Denmark
se_865 cnf  46,850,YMD,"K","r",	 0,0,0," ",",","-",".",3,2,_24; Sweden
se_850 cnf  46,850,YMD,"K","r",	 0,0,0," ",",","-",".",3,2,_24; Sweden
se_858 cnf  46,858,YMD,"K","r",	 0,0,0," ",",","-",".",3,2,_24; Sweden
se_437 cnf  46,437,YMD,"K","r",	 0,0,0," ",",","-",".",3,2,_24; Sweden
no_865 cnf  47,865,DMY,"K","r",	 0,0,0,".",",",".",":",2,2,_24; Norway
no_850 cnf  47,850,DMY,"K","r",	 0,0,0,".",",",".",":",2,2,_24; Norway
no_858 cnf  47,858,DMY,"K","r",	 0,0,0,".",",",".",":",2,2,_24; Norway
pl_852 cnf  48,852,YMD,"Z",88h,	 0,0,0,".",",","-",":",0,2,_24; Poland	 Michal
pl_850 cnf  48,850,YMD,"P","L","N",0,0,".",",","-",":",0,2,_24; Poland
pl_858 cnf  48,858,YMD,"P","L","N",0,0,".",",","-",":",0,2,_24; Poland
de_850 cnf  49,850,DMY,"E","U","R",0,0,".",",",".",":",3,2,_24; Germany	    Tom
de_858 cnf  49,858,DMY,0D5h,   0,0,0,0,".",",",".",":",3,2,_24; Germany
de_437 cnf  49,437,DMY,"E","U","R",0,0,".",",",".",":",3,2,_24; Germany
mx_850 cnf  52,850,DMY,"$",    0,0,0,0,",",".","/",":",0,2,_24; Mexico, Currency: $ - Mexican Peso
mx_858 cnf  52,858,DMY,"$",    0,0,0,0,",",".","/",":",0,2,_24; Mexico
mx_437 cnf  52,437,DMY,"$",    0,0,0,0,",",".","/",":",0,2,_24; Mexico
ar_850 cnf  54,850,DMY,"$",    0,0,0,0,".",",","/",".",0,2,_24; Argentina
ar_858 cnf  54,858,DMY,"$",    0,0,0,0,".",",","/",".",0,2,_24; Argentina
ar_437 cnf  54,437,DMY,"$",    0,0,0,0,".",",","/",".",0,2,_24; Argentina
br_850 cnf  55,850,DMY,"R","$", 0,0,0,".",",","/",":",2,2,_24; Brazil
br_858 cnf  55,858,DMY,"R","$", 0,0,0,".",",","/",":",2,2,_24; Brazil
br_437 cnf  55,437,DMY,"R","$", 0,0,0,".",",","/",":",2,2,_24; Brazil
my_437 cnf  60,437,DMY,"$",    0,0,0,0,",",".","/",":",0,2,_12; Malaysia
au_437 cnf  61,437,DMY,"$",    0,0,0,0,",",".","-",":",0,2,_12; Australia
au_850 cnf  61,850,DMY,"$",    0,0,0,0,",",".","-",":",0,2,_12; Australia
au_858 cnf  61,858,DMY,"$",    0,0,0,0,",",".","-",":",0,2,_12; Australia
id_850 cnf  62,850,DMY,"R","p", 0,0,0,".",",","/",":",0,0,_24; Indonesia
id_437 cnf  62,437,DMY,"R","p", 0,0,0,".",",","/",":",0,0,_24; Indonesia
ph_850 cnf  63,850,MDY,"P",    0,0,0,0,",",".","/",":",0,2,_12; Philippines
ph_437 cnf  63,437,MDY,"P",    0,0,0,0,",",".","/",":",0,2,_12; Philippines
nz_850 cnf  64,850,DMY,"$",    0,0,0,0,",",".","/",":",0,2,_24; New Zealand, Currency: $ - New Zealand Dollar
nz_858 cnf  64,858,DMY,"$",    0,0,0,0,",",".","/",":",0,2,_24; New Zealand
nz_437 cnf  64,437,DMY,"$",    0,0,0,0,",",".","/",":",0,2,_24; New Zealand
sg_437 cnf  65,437,DMY,"$",    0,0,0,0,",",".","/",":",0,2,_12; Singapore
th_874 cnf  66,874,DMY,"B",    0,0,0,0,",",".","/",":",0,2,_24; Thailand
th_850 cnf  66,850,DMY,"B",    0,0,0,0,",",".","/",":",0,2,_24; Thailand
th_437 cnf  66,437,DMY,"B",    0,0,0,0,",",".","/",":",0,2,_24; Thailand
jp_932 cnf  81,932,YMD,5Ch,    0,0,0,0,",",".","-",":",0,0,_24; Japan	   Yuki
jp_437 cnf  81,437,YMD,9Dh,    0,0,0,0,",",".","-",":",0,0,_24; Japan
kr_934 cnf  82,934,YMD,5Ch,    0,0,0,0,",",".",".",":",0,0,_24; Korea
kr_437 cnf  82,437,YMD,"K","R","W",0,0,",",".",".",":",0,0,_24; Korea
vn_1258 cnf 84,1258,DMY,"d",   0,0,0,0,".",",","/",":",3,0,_24; Vietnam
vn_850 cnf  84,850,DMY,"d",    0,0,0,0,".",",","/",":",3,0,_24; Vietnam
vn_437 cnf  84,437,DMY,"d",    0,0,0,0,".",",","/",":",3,0,_24; Vietnam
cn_936 cnf  86,936,YMD,5Ch,    0,0,0,0,",",".",".",":",0,2,_12; China
cn_437 cnf  86,437,YMD,9Dh,    0,0,0,0,",",".",".",":",0,2,_12; China
tr_857 cnf  90,857,DMY,"T","R","Y",0,0,".",",","/",":",4,2,_24; Turkey
tr_850 cnf  90,850,DMY,"T","R","Y",0,0,".",",","/",":",4,2,_24; Turkey
tr_858 cnf  90,858,DMY,"T","R","Y",0,0,".",",","/",":",4,2,_24; Turkey
in_437 cnf  91,437,DMY,"R","s",	 0,0,0,".",",","/",":",0,2,_24; India
pt_860 cnf 351,860,DMY,"E","U","R",0,0,".",",","-",":",0,2,_24; Portugal
pt_850 cnf 351,850,DMY,"E","U","R",0,0,".",",","-",":",0,2,_24; Portugal
pt_858 cnf 351,858,DMY,0D5h,   0,0,0,0,".",",","-",":",0,2,_24; Portugal
lu_850 cnf 352,850,DMY,"E","U","R",0,0,".",",","/",":",0,2,_24; Luxembourg
lu_858 cnf 352,858,DMY,0D5h,   0,0,0,0,".",",","/",":",0,2,_24; Luxembourg
lu_437 cnf 352,437,DMY,"E","U","R",0,0,".",",","/",":",0,2,_24; Luxembourg
ie_850 cnf 353,850,DMY,"E","U","R",0,0,",",".","/",":",0,2,_24; Ireland
ie_858 cnf 353,858,DMY,0D5h,   0,0,0,0,",",".","/",":",0,2,_24; Ireland
ie_437 cnf 353,437,DMY,"E","U","R",0,0,",",".","/",":",0,2,_24; Ireland
is_861 cnf 354,861,DMY,"kr",   0,0,0,0,".",",",".",":",3,0,_24; Iceland
is_865 cnf 354,861,DMY,"kr",   0,0,0,0,".",",",".",":",3,0,_24; Iceland
is_850 cnf 354,850,DMY,"kr",   0,0,0,0,".",",",".",":",3,0,_24; Iceland
is_858 cnf 354,858,DMY,"kr",   0,0,0,0,".",",",".",":",3,0,_24; Iceland
al_852 cnf 355,852,DMY,"L","e","k",0,0,".",",",".",":",3,2,_24; Albania
al_850 cnf 355,850,DMY,"L","e","k",0,0,".",",",".",":",3,2,_24; Albania
al_858 cnf 355,858,DMY,"L","e","k",0,0,".",",",".",":",3,2,_24; Albania
mt_850 cnf 356,850,DMY,"E","U","R",0,0,",",".","/",":",0,2,_24; Malta
mt_858 cnf 356,858,DMY,0D5h,   0,0,0,0,",",".","/",":",0,2,_24; Malta
mt_437 cnf 356,437,DMY,"E","U","R",0,0,",",".","/",":",0,2,_24; Malta
cy_869 cnf 357,869,DMY,0D5h,   0,0,0,0,".",",","/",":",0,2,_24; Cyprus
cy_850 cnf 357,850,DMY,"E","U","R",0,0,".",",","/",":",0,2,_24; Cyprus
cy_858 cnf 357,858,DMY,0D5h,   0,0,0,0,".",",","/",":",0,2,_24; Cyprus
fi_865 cnf 358,850,DMY,"E","U","R",0,0," ",",",".",".",3,2,_24; Finland
fi_850 cnf 358,850,DMY,"E","U","R",0,0," ",",",".",".",3,2,_24; Finland	   Wolf
fi_858 cnf 358,858,DMY,0D5h,   0,0,0,0," ",",",".",".",3,2,_24; Finland
fi_437 cnf 358,437,DMY,"E","U","R",0,0," ",",",".",".",3,2,_24;
;bg_855 cnf 359,855,DMY,0D0h,0EBh,".",0,0," ",",",".",",",3,2,_24; Bulgaria  Lucho&RDPK7
;bg_872 cnf 359,872,DMY,0D0h,0EBh,".",0,0," ",",",".",",",3,2,_24; Bulgaria  Lucho&RDPK7
;bg_850 cnf 359,850,DMY,"B","G","N",0,0," ",",",".",",",3,2,_24; Bulgaria  RDPK7
;bg_858 cnf 359,858,DMY,"B","G","N",0,0," ",",",".",",",3,2,_24; Bulgaria  RDPK7
;bg_866 cnf 359,866,DMY,0ABh,0A2h,".",0,0," ",",",".",",",3,2,_24; Bulgaria
;bg_808 cnf 359,808,DMY,0ABh,0A2h,".",0,0," ",",",".",",",3,2,_24; Bulgaria
;bg_849 cnf 359,849,DMY,0ABh,0A2h,".",0,0," ",",",".",",",3,2,_24; Bulgaria
;bg_1131 cnf 359,1131,DMY,0ABh,0A2h,".",0,0," ",",",".",",",3,2,_24; Bulgaria
;bg_30033 cnf 359,30033,DMY,0ABh,0A2h,".",0,0," ",",",".",",",3,2,_24; Bulgaria  RDPK7
bg_855 cnf 359,855,DMY,"E","U","R",0,0," ",",",".",",",3,2,_24; Bulgaria, 2026 Euro replaced BGN
bg_872 cnf 359,872,DMY,"E","U","R",0,0," ",",",".",",",3,2,_24; Bulgaria
bg_850 cnf 359,850,DMY,"E","U","R",0,0," ",",",".",",",3,2,_24; Bulgaria
bg_858 cnf 359,858,DMY,0D5h,   0,0,0,0," ",",",".",",",3,2,_24; Bulgaria
bg_866 cnf 359,866,DMY,"E","U","R",0,0," ",",",".",",",3,2,_24; Bulgaria
bg_808 cnf 359,808,DMY,"E","U","R",0,0," ",",",".",",",3,2,_24; Bulgaria
bg_849 cnf 359,849,DMY,"E","U","R",0,0," ",",",".",",",3,2,_24; Bulgaria
bg_1131 cnf 359,1131,DMY,"E","U","R",0,0," ",",",".",",",3,2,_24; Bulgaria
bg_30033 cnf 359,30033,DMY,"E","U","R",0,0," ",",",".",",",3,2,_24; Bulgaria
ee_775 cnf 372,775,DMY,"E","U","R",0,0," ",",",".",":",3,2,_24; Estonia
ee_850 cnf 372,850,DMY,"E","U","R",0,0," ",",",".",":",3,2,_24;
ee_858 cnf 372,858,DMY,0D5h,   0,0,0,0," ",",",".",":",3,2,_24;
lv_775 cnf 371,775,DMY,"E","U","R",0,0," ",",",".",":",3,2,_24; Latvia
lv_850 cnf 371,850,DMY,"E","U","R",0,0," ",",",".",":",3,2,_24;
lv_858 cnf 371,858,DMY,0D5h,   0,0,0,0," ",",",".",":",3,2,_24;
lt_775 cnf 370,775,YMD,"E","U","R",0,0," ",",","-",":",3,2,_24; Lithuania
lt_850 cnf 370,850,YMD,"E","U","R",0,0," ",",","-",":",3,2,_24;
lt_858 cnf 370,858,YMD,0D5h,   0,0,0,0," ",",","-",":",3,2,_24;
by_849 cnf 375,849,DMY,0E0h,0E3h,0A1h,".",0," ",",",".",":",3,2,_24;Belarus
by_1131 cnf 375,1131,DMY,0E0h,0E3h,0A1h,".",0," ",",",".",":",3,2,_24; Belarus
by_850 cnf 375,850,DMY,"B","Y","R",0,0," ",",",".",",",3,2,_24; Belarus
by_858 cnf 375,858,DMY,"B","Y","R",0,0," ",",",".",",",3,2,_24; Belarus
ua_848 cnf 380,848,DMY,0A3h,0E0h,0ADh,".",0," ",",",".",":",3,2,_24;Ukraine Oleg
ua_855 cnf 380,855,DMY,0A3h,0E0h,0ADh,".",0," ",",",".",":",3,2,_24;Ukraine
ua_1125 cnf 380,1125,DMY,0A3h,0E0h,0ADh,".",0," ",",",".",":",3,2,_24; Ukraine
ua_866 cnf 380,866,DMY,0A3h,0E0h,0ADh,".",0," ",",",".",":",3,2,_24; Ukraine
rs_855 cnf 381,855,DMY,0A7h,0B7h,0D4h,0,0,".",",",".",":",3,2,_24; Serbia
rs_872 cnf 381,872,DMY,0A7h,0B7h,0D4h,0,0,".",",",".",":",3,2,_24; Serbia
rs_852 cnf 381,852,DMY,"D","i","n",0,0,".",",",".",":",3,2,_24; Serbia
rs_850 cnf 381,850,DMY,"D","i","n",0,0,".",",",".",":",3,2,_24; Serbia
rs_858 cnf 381,858,DMY,"D","i","n",0,0,".",",",".",":",3,2,_24; Serbia
me_852 cnf 382,852,DMY,"E","U","R",0,0,".",",",".",":",0,2,_24; Montenegro
me_855 cnf 382,855,DMY,"E","U","R",0,0,".",",",".",":",0,2,_24; Montenegro
me_872 cnf 382,872,DMY,0CFh,   0,0,0,0,".",",",".",":",0,2,_24; Montenegro
me_850 cnf 382,850,DMY,"E","U","R",0,0,".",",",".",":",0,2,_24; Montenegro
me_858 cnf 382,858,DMY,0D5h,   0,0,0,0,".",",",".",":",0,2,_24; Montenegro
xk_852 cnf 383,852,DMY,"E","U","R",0,0,".",",",".",":",0,2,_24; Kosovo
xk_855 cnf 383,855,DMY,"E","U","R",0,0,".",",",".",":",0,2,_24; Kosovo
xk_872 cnf 383,872,DMY,0CFh,   0,0,0,0,".",",",".",":",0,2,_24; Kosovo
xk_850 cnf 383,850,DMY,"E","U","R",0,0,".",",",".",":",0,2,_24; Kosovo
xk_858 cnf 383,858,DMY,0D5h,   0,0,0,0,".",",",".",":",0,2,_24; Kosovo
hr_852 cnf 385,852,DMY,"E","U","R",0,0,".",",",".",".",3,2,_24; Croatia
hr_850 cnf 385,850,DMY,"E","U","R",0,0,".",",",".",".",3,2,_24; Croatia
hr_858 cnf 385,858,DMY,0D5h,   0,0,0,0,".",",",".",".",3,2,_24; Croatia
si_852 cnf 386,852,DMY,"E","U","R",0,0,".",",",".",":",3,2,_24; Slovenia
si_850 cnf 386,850,DMY,"E","U","R",0,0,".",",",".",":",3,2,_24; Slovenia
si_858 cnf 386,858,DMY,0D5h,   0,0,0,0,".",",",".",":",3,2,_24; Slovenia
ba_852 cnf 387,852,DMY,"K","M",  0,0,0,".",",",".",".",1,2,_24; Bosnia
ba_850 cnf 387,850,DMY,"K","M",  0,0,0,".",",",".",".",1,2,_24; Bosnia
ba_858 cnf 387,858,DMY,"K","M",  0,0,0,".",",",".",".",1,2,_24; Bosnia
ba_855 cnf 387,855,DMY,"K","M",  0,0,0,".",",",".",":",1,2,_24; Bosnia
ba_872 cnf 387,872,DMY,"K","M",  0,0,0,".",",",".",":",1,2,_24; Bosnia
mk_855 cnf 389,855,DMY,0A7h,0A8h,0D4h,0,0,".",",",".",":",3,2,_24; North Macedonia
mk_872 cnf 389,872,DMY,0A7h,0A8h,0D4h,0,0,".",",",".",":",3,2,_24; North Macedonia
mk_850 cnf 389,850,DMY,"D","e","n",0,0,".",",",".",":",3,2,_24; North Macedonia
mk_858 cnf 389,858,DMY,"D","e","n",0,0,".",",",".",":",3,2,_24; North Macedonia
cz_852 cnf 420,852,DMY,"K","c",  0,0,0,".",",","-",":",2,2,_24; Czech Republic
cz_850 cnf 420,850,DMY,"K","c",  0,0,0,".",",","-",":",2,2,_24; Czech Republic
cz_858 cnf 420,858,DMY,"K","c",  0,0,0,".",",","-",":",2,2,_24; Czech Republic
sk_852 cnf 421,852,DMY,"E","U","R",0,0," ",",",".",":",3,2,_24; Slovakia
sk_850 cnf 421,850,DMY,"E","U","R",0,0," ",",",".",":",3,2,_24; Slovakia
sk_858 cnf 421,858,DMY,0D5h,   0,0,0,0," ",",",".",":",3,2,_24; Slovakia
xx_864 cnf 785,864,DMY,0A4h,   0,0,0,0,".",",","/",":",1,3,_12; Middle East
xx_850 cnf 785,850,DMY,0CFh,   0,0,0,0,".",",","/",":",3,3,_12; Middle East
xx_858 cnf 785,858,DMY,0CFh,   0,0,0,0,".",",","/",":",3,3,_12; Middle East
il_862 cnf 972,862,DMY,99h,    0,0,0,0,",","."," ",":",2,2,_24; Israel
il_850 cnf 972,850,DMY,"N","I","S",0,0,",","."," ",":",2,2,_24; Israel
il_858 cnf 972,858,DMY,"N","I","S",0,0,",","."," ",":",2,2,_24; Israel
es_ES_850 cnf 40034,850,DMY,"E","U","R",0,0,".",",","/",":",0,2,_24; Spain:
es_ES_858 cnf 40034,858,DMY,0D5h,   0,0,0,0,".",",","/",":",0,2,_24;  Spanish
es_ES_437 cnf 40034,437,DMY,"E","U","R",0,0,".",",","/",":",0,2,_24
ca_ES_850 cnf 41034,850,DMY,"E","U","R",0,0,".",",","/",":",0,2,_24;  Catalan
ca_ES_858 cnf 41034,858,DMY,0D5h,   0,0,0,0,".",",","/",":",0,2,_24
ca_ES_437 cnf 41034,437,DMY,"E","U","R",0,0,".",",","/",":",0,2,_24
gl_ES_850 cnf 42034,850,DMY,"E","U","R",0,0,".",",","/",":",0,2,_24;  Galician
gl_ES_858 cnf 42034,858,DMY,0D5h,   0,0,0,0,".",",","/",":",0,2,_24
gl_ES_437 cnf 42034,437,DMY,"E","U","R",0,0,".",",","/",":",0,2,_24
eu_ES_850 cnf 43034,850,DMY,"E","U","R",0,0,".",",","/",":",0,2,_24;  Basque
eu_ES_858 cnf 43034,858,DMY,0D5h,   0,0,0,0,".",",","/",":",0,2,_24
eu_ES_437 cnf 43034,437,DMY,"E","U","R",0,0,".",",","/",":",0,2,_24
nl_BE_850 cnf 40032,850,DMY,"E","U","R",0,0,".",",","/",":",0,2,_24; Belgium:
nl_BE_858 cnf 40032,858,DMY,0D5h,   0,0,0,0,".",",","/",":",0,2,_24;  Dutch
nl_BE_437 cnf 40032,437,DMY,"E","U","R",0,0,".",",","/",":",0,2,_24
fr_BE_850 cnf 41032,850,DMY,"E","U","R",0,0,".",",","/",":",0,2,_24;  French
fr_BE_858 cnf 41032,858,DMY,0D5h,   0,0,0,0,".",",","/",":",0,2,_24
fr_BE_437 cnf 41032,437,DMY,"E","U","R",0,0,".",",","/",":",0,2,_24
de_BE_850 cnf 42032,850,DMY,"E","U","R",0,0,".",",","/",":",0,2,_24;  German
de_BE_858 cnf 42032,858,DMY,0D5h,   0,0,0,0,".",",","/",":",0,2,_24
de_BE_437 cnf 42032,437,DMY,"E","U","R",0,0,".",",","/",":",0,2,_24
de_CH_850 cnf 40041,850,DMY,"F","r",".",0,0,"'",".",".",",",2,2,_24; Switzerland
de_CH_858 cnf 40041,858,DMY,"F","r",".",0,0,"'",".",".",",",2,2,_24;  German
de_CH_437 cnf 40041,437,DMY,"F","r",".",0,0,"'",".",".",",",2,2,_24
fr_CH_850 cnf 41041,850,DMY,"F","r",".",0,0,"'",".",".",",",2,2,_24;  French
fr_CH_858 cnf 41041,858,DMY,"F","r",".",0,0,"'",".",".",",",2,2,_24
fr_CH_437 cnf 41041,437,DMY,"F","r",".",0,0,"'",".",".",",",2,2,_24
it_CH_850 cnf 42041,850,DMY,"F","r",".",0,0,"'",".",".",",",2,2,_24;  Italian
it_CH_858 cnf 42041,858,DMY,"F","r",".",0,0,"'",".",".",",",2,2,_24
it_CH_437 cnf 42041,437,DMY,"F","r",".",0,0,"'",".",".",",",2,2,_24

; ==============================================================================
; SECTION 5: UPPERCASE/LOWERCASE TABLES (Subfunctions 2, 3, 4)
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
lcase_1125 equ lcase_866

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


; ==============================================================================
; SECTION 6: FILENAME CHARACTER TABLE (Subfunction 5)
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


; ==============================================================================
; SECTION 7: COLLATING SEQUENCES (Subfunction 6)
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

; ==============================================================================
; SECTION 8: DBCS TABLES (Subfunction 7)
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

; ==============================================================================
; SECTION 9: YES/NO TABLES (Subfunction 35)
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
   %if %0 == 4
     db %2,%3,%4,%5
   %else
     db '%2',0,'%3',0
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

; ------------------------------------------------------------------------------
; Western European Languages
; ------------------------------------------------------------------------------
en_yn equ yn_yn                 ; English: Yes/No
es_yn equ yn_sn                 ; Spanish: Si/No
de_yn equ yn_jn                 ; German: Ja/Nein
nl_yn equ yn_jn                 ; Dutch: Ja/Nee
fr_yn equ yn_on                 ; French: Oui/Non
pt_yn equ yn_sn                 ; Portuguese: Sim/Nao
it_yn equ yn_sn                 ; Italian: Si/No

; ------------------------------------------------------------------------------
; Nordic Languages
; ------------------------------------------------------------------------------
se_yn equ yn_jn                 ; Swedish: Ja/Nej
no_yn equ yn_jn                 ; Norwegian: Ja/Nei
dk_yn equ yn_jn                 ; Danish: Ja/Nej
fi_yn equ yn_ke                 ; Finnish: Kylla/Ei
is_yn equ yn_jn                 ; Icelandic: Ja/Nei

; ------------------------------------------------------------------------------
; Central/Eastern European Languages
; ------------------------------------------------------------------------------
pl_yn equ yn_tn                 ; Polish: Tak/Nie
cz_yn equ yn_an                 ; Czech: Ano/Ne
sk_yn equ yn_an                 ; Slovak: Ano/Nie
hu_yn equ yn_in                 ; Hungarian: Igen/Nem
ro_yn equ yn_dn                 ; Romanian: Da/Nu
hr_yn equ yn_dn                 ; Croatian: Da/Ne
si_yn equ yn_dn                 ; Slovenian: Da/Ne
sh_yn equ yn_dn                 ; Serbo-Croatian: Da/Ne
al_yn equ yn_pj                 ; Albanian: Po/Jo

; ------------------------------------------------------------------------------
; Baltic Languages
; ------------------------------------------------------------------------------
lt_yn equ yn_tn                 ; Lithuanian: Taip/Ne
lv_yn equ yn_jn                 ; Latvian: Ja/Ne
ee_yn equ yn_je                 ; Estonian: Jah/Ei

; ------------------------------------------------------------------------------
; Other European Languages
; ------------------------------------------------------------------------------
ca_yn equ yn_sn                 ; Catalan: Si/No
gl_yn equ yn_sn                 ; Galician: Si/Non
eu_yn equ yn_be                 ; Basque: Bai/Ez
mt_yn equ yn_il                 ; Maltese: Iva/Le
cy_yn equ yn_no                 ; Cyprus (Latin): N/O
cy_yn_869 equ yn_gr_869         ; Cyprus (Greek CP869)

; ------------------------------------------------------------------------------
; Asian Languages
; ------------------------------------------------------------------------------
id_yn equ yn_yt                 ; Indonesian: Ya/Tidak
ph_yn equ yn_oh                 ; Filipino: Oo/Hindi
vn_yn equ yn_ck                 ; Vietnamese: Co/Khong

; ------------------------------------------------------------------------------
; Cyrillic Languages (Codepage-specific)
; ------------------------------------------------------------------------------
; Russian
ru_yn_866 equ yn_cyrl_866       ; CP866: (Da/Net)
ru_yn_808 equ yn_cyrl_866       ; CP808:
ru_yn_855 equ yn_cyrl_855       ; CP855:
ru_yn_872 equ yn_cyrl_872       ; CP872:
ru_yn equ yn_dn                 ; Latin fallback: D/N

; Bulgarian
bg_yn_866 equ yn_cyrl_866       ; CP866: (Da/Ne)
bg_yn_808 equ yn_cyrl_866       ; CP808:
bg_yn_855 equ yn_cyrl_855       ; CP855:
bg_yn_849 equ yn_cyrl_866       ; CP849:
bg_yn_872 equ yn_cyrl_872       ; CP872:
bg_yn_1131 equ yn_cyrl_866      ; CP1131:
bg_yn_30033 equ yn_cyrl_866     ; CP30033: (MIK)
bg_yn equ yn_dn                 ; Latin fallback: D/N

; Ukrainian
ua_yn_848 equ yn_cyrl_866       ; CP848: T/N (Tak/Ni) [Note: Uses same bytes as Da/Net]
ua_yn_1125 equ yn_cyrl_866      ; CP1125: T/N

; Belarusian
by_yn_849 equ yn_cyrl_866       ; CP849: T/N (Tak/Nie)
by_yn_1131 equ yn_cyrl_866      ; CP1131: T/N
by_yn equ yn_tn                 ; Latin fallback: T/N

; Serbian/Macedonian (Cyrillic)
sh_yn_855 equ yn_cyrl_855       ; CP855: D/N (Da/Ne)
sh_yn_872 equ yn_cyrl_872       ; CP872: D/N
mk_yn_855 equ yn_cyrl_855       ; CP855: D/N (Macedonian)
mk_yn_872 equ yn_cyrl_872       ; CP872: D/N
mk_yn equ yn_dn                 ; Latin fallback: D/N

; ------------------------------------------------------------------------------
; Greek
; ------------------------------------------------------------------------------
gr_yn_869 equ yn_gr_869         ; CP869: N/O (Nai/Oxi)
gr_yn_737 equ yn_gr_737         ; CP737: N/O
gr_yn equ yn_no                 ; Latin fallback: N/O

; ------------------------------------------------------------------------------
; Turkish
; ------------------------------------------------------------------------------
tr_yn equ yn_eh                 ; Turkish: Evet/Hayir

; ------------------------------------------------------------------------------
; Middle Eastern Languages
; ------------------------------------------------------------------------------
il_yn_862 equ yn_il_862         ; CP862 Hebrew: (Ken/Lo)
il_yn equ yn_kl                 ; Latin fallback: K/L

xx_yn_864 equ yn_xx_864        ; CP864 Arabic: (Na'am/La)
xx_yn equ yn_nl                ; Latin fallback: N/L

; ------------------------------------------------------------------------------
; Asian Languages (DBCS)
; ------------------------------------------------------------------------------
; Chinese (Simplified)
cn_yn_936 equ yn_cn_936         ; CP936: (Shi/Bushi)
cn_yn equ yn_sb                 ; ASCII fallback: S/B

; Korean
kr_yn_934 equ yn_kr_934         ; CP934: (Ye/A)
kr_yn equ yn_ya                 ; ASCII fallback: Y/A

; (Japanese MS-DOS uses English "Y" and "N" - Yuki)
jp_yn equ yn_yn

; ==============================================================================
; END OF FILE
; ==============================================================================
db "FreeDOS" ; Trailing - as recommended by the Ralf Brown Interrupt List
