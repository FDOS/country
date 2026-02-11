# COUNTRY.SYS

## Description:

     FreeDOS COUNTRY.SYS - International Localization Data
    
     This file contains country-specific localization data for FreeDOS,
     including date/time/currency formats, uppercase/lowercase mappings,
     collating sequences (sorting orders), filename character tables,
     and yes/no prompt characters for multiple country and codepage
     combinations.
    
     COUNTRY.SYS provides the data that is returned by DOS API calls: 
     INT21h/38h, INT21h/6501h-6507h and INT2Fh/1400h-14FFh

## Purpose:

     COUNTRY.SYS provides international support for DOS applications by
     defining locale-specific behavior. It is loaded by the kernel at
     boot time via CONFIG.SYS: COUNTRY=<code>,<codepage>,<filepath>

## Compatibility:

     This file is binary-compatible with COUNTRY.SYS from:
     - MS-DOS (Microsoft DOS)
     - PC-DOS (IBM DOS)
     - PTS-DOS
     - OS/2 *** 
     - Windows 9x

  *** COUNTRY.SYS format is largely unchanged since MS-DOS 3.x
  The YESNO tables are unused except in FreeDOS and OS/2 (W95 unknown),
  However, unlike the OS/2 one, FreeDOS only provides 1st character as an 
  ASCIIZ string, "Y" or "N", while OS/2 provides full words "YES" or "NO".
  It is unknown if Windows 95 uses this and if it is in a compatible format.

## Basic Usage:

    Add a COUNTRY= entry in CONFIG.SYS which refers to the COUNTRY.SYS file.
        COUNTRY=<country #>,<codepage #>,C:\DOS\COUNTRY.SYS
    
    For example, United States (1) with codepage 850:
        COUNTRY=1,850,C:\DOS\COUNTRY.SYS

## File Format:

     Format described in Ralf Brown's Interrupt List (RBIL)
     Tables 2619-2622

## Structure Overview:

     1. File Header       - Magic signature and entry count
     2. Entry Table       - Index of all country/codepage combinations
     3. Subfunction Data  - Actual localization data for each country:
        a. Country Info   - Date/time/currency format (subfunction 1)
        b. Uppercase      - Character case mapping (subfunction 2)
        c. Lowercase      - Inverse case mapping (subfunction 3)
        d. Filename Upper - Filename character mapping (subfunction 4)
        e. Filename Chars - Valid filename characters (subfunction 5)
        f. Collating Seq  - Sort order (subfunction 6)
        g. DBCS Table     - Double-byte character sets (subfunction 7)
        h. Yes/No Chars   - Prompt characters (subfunction 35)

## Copyright Information:

    Copyright 2004, The FreeDOS Project
    
    COUNTRY.SYS is free software; you can redistribute it and/or
    modify it under the terms of the GNU General Public License
    as published by the Free Software Foundation; either
    version 2, or (at your option) any later version.
    
    It is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty
    of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
    See the GNU General Public License for more details.
    
    You should have received a copy of the GNU General Public
    License along with FreeDOS; see the file COPYING.  If not,
    write to the Free Software Foundation, Inc.,
    59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
    or go to http://www.gnu.org/licenses/gpl.html

## Credits:

    * Created as a kernel table by:          Tom Ehlert
    * Reformatted and commented by:          Bernd Blaauw
    * Separated from the kernel by:          Luchezar Georgiev
    * Case/collate tables added by:          Eduardo Casino
    * Yes/No and codepage 850 table by:      Steffen Kaiser
    * Amended by many contributors

## REFERENCES

    See Matthias Paul's extensive COUNTRY.SYS documentation file: COUNTRY.LST
    
    ### Standards used in this file:
    
    - ISO 3166-1: Country codes
      https://www.iso.org/iso-3166-country-codes.html
    - ISO 639-1: Language codes
      https://www.loc.gov/standards/iso639-2/php/code_list.php
    - ISO 4217: Currency codes
      https://www.iso.org/iso-4217-currency-codes.html
    - Ralf Brown's Interrupt List (RBIL): DOS structures
      https://www.ctyme.com/rbrown.htm
    - European Central Bank: Euro adoption dates
      https://www.ecb.europa.eu/euro/intro/html/index.en.html
