#!/usr/bin/python

import re
import iso3166
import phonenumbers
import sys



from pathlib import Path

COUNTRY_ASM = Path('country.asm')


def is_alpha2(code):
    if code.upper() == 'XX':                   # Middle East
        return True
    if code.upper() == 'YU':                   # Yugoslavia
        return True
    return code.upper() in iso3166._by_alpha2

def is_country(code, pnum):
    if code.upper() == 'CA' and pnum =='2':    # French speaking Canada
        return True
    if code.upper() == 'LA' and pnum =='3':    # Latin America
        return True
    if code.upper() == 'XX' and pnum =='785':  # Middle East
        return True
    if code.upper() == 'YU' and pnum =='38':   # Yugoslavia
        return True
    if code.upper() == 'CZ' and pnum =='42':   # Czechoslovakia
        return True
    return code.upper() in phonenumbers.region_codes_for_country_code(int(pnum, 10))


def extract_known_codepages(lines):
    """
    Extract known codepages from the CODEPAGES comment block in country.asm.
    
    Returns:
        set: Set of known valid codepage numbers as strings
    """
    known_codepages = set()
    in_codepages_block = False
    
    for line in lines:
        stripped = line.strip()
        # Start of CODEPAGES block
        if stripped == '; CODEPAGES:':
            in_codepages_block = True
            continue
        # End of block (next section starts with ; ==)
        if in_codepages_block and stripped.startswith('; =='):
            break
        # Parse codepage numbers from comment lines
        if in_codepages_block and stripped.startswith(';'):
            # Match patterns like "437  = US/OEM" or "30033  = Bulgarian MIK"
            for match in re.finditer(r'\b(\d+)\s*=\s*\w', stripped):
                known_codepages.add(match.group(1))
    
    return known_codepages


def check_master(lines, known_codepages):
    """
    Validates COUNTRY, OLD_COUNTRY, COUNTRY_LCASE, COUNTRY_DBCS, and COUNTRY_ML macro invocations in NASM assembly.
    
    Checks:
    - Country codes are valid ISO3166-1-A2 (extracted from country.asm comments)
    - Country codes match international phone prefixes
    
    Returns:
        tuple: (errors, num_found, obsolete_entries_found)
    """
    errors = 0
    num_found = 0
    obsolete_entries_found = 0

    # Build country map from comments in country.asm
    # Format: ;   1 = United States (US)           2 = Canada (CA)
    country_map = {}
    comment_country_re = re.compile(r"(\d+)\s*=\s*[^()]+\(([A-Z]{2})\)")
    for line in lines:
        if line.strip().startswith(';'):
            for match in comment_country_re.finditer(line):
                num_code, alpha2 = match.groups()
                country_map[num_code] = alpha2

    # COUNTRY 1, 437, ...
    # OLD_COUNTRY 38, 852, ...
    # COUNTRY_LCASE 7, 808, ...
    # COUNTRY_DBCS 81, 932, ...
    country_re = r"^(OLD_)?COUNTRY(?:_LCASE|_DBCS)?\s+(\d+)\s*,\s*(\d+)"
    
    # COUNTRY_ML 32, 0, 850, ...
    country_ml_re = r"^(OLD_)?COUNTRY_ML\s+(\d+)\s*,\s*(\d+)\s*,\s*(\d+)"

    for lineNo, line in enumerate(lines, start=1):
        # Strip comments and whitespace
        line_clean = line.split(';')[0].strip()
        
        # Check standard COUNTRY macros
        country_match = re.match(country_re, line_clean)
        if country_match:
            is_old = country_match.group(1) == "OLD_"
            numeric_country = country_match.group(2)
            codepage = country_match.group(3)
            
            if is_old:
                obsolete_entries_found += 1
            else:
                num_found += 1
            
            # Lookup alpha2 code
            country_code = country_map.get(numeric_country)
            if not country_code:
                print(f"Line {lineNo}: Numeric country code {numeric_country} not found in country map")
                errors += 1
                continue
            
            # Validate country code is ISO3166-1-A2
            if not is_alpha2(country_code):
                print(f"Line {lineNo}: Country ISO3166-1-A2 ({country_code}) invalid in '{line_clean}'")
                errors += 1
                continue
            
            # Validate country code matches numeric country code
            if not is_country(country_code, numeric_country):
                print(f"Line {lineNo}: Country ISO3166-1-A2 ({country_code}) mismatch with International Phone Prefix ({numeric_country}) in '{line_clean}'")
                errors += 1
                continue

            # validate codepage is at least within known set of codepages
            if codepage and codepage not in known_codepages:
                print(f"Line {lineNo}: New codepage found {codepage}, update CODEPAGES comment block in country.asm or correct country.asm with correct codepage if it was just a typo.")
                errors += 1
                continue

            continue

        # Check COUNTRY_ML
        ml_match = re.match(country_ml_re, line_clean)
        if ml_match:
            is_old = ml_match.group(1) == "OLD_"
            base_cc = ml_match.group(2)
            ml_idx = ml_match.group(3)
            codepage = ml_match.group(4)
            
            # Compute extended country code: 40000 + (ml_idx * 1000) + base_cc
            numeric_country = str(40000 + (int(ml_idx) * 1000) + int(base_cc))
            
            if is_old:
                obsolete_entries_found += 1
            else:
                num_found += 1
            
            # For ML, we validate against the base country code for the alpha2 lookup
            country_code = country_map.get(base_cc)
            if not country_code:
                print(f"Line {lineNo}: Base numeric country code {base_cc} not found in country map")
                errors += 1
                continue
            
            # Validate country code is ISO3166-1-A2
            if not is_alpha2(country_code):
                print(f"Line {lineNo}: Country ISO3166-1-A2 ({country_code}) invalid in '{line_clean}'")
                errors += 1
                continue
            
            # Validate country code matches numeric country code
            # Note: for ML, we check the base country code against the alpha2
            if not is_country(country_code, base_cc):
                print(f"Line {lineNo}: Country ISO3166-1-A2 ({country_code}) mismatch with International Phone Prefix ({base_cc}) in '{line_clean}'")
                errors += 1
                continue
            
            # validate codepage is at least within known set of codepages
            if codepage and codepage not in known_codepages:
                print(f"Line {lineNo}: New codepage found {codepage}, update CODEPAGES comment block in country.asm or correct country.asm with correct codepage if it was just a typo.")
                errors += 1
                continue

            continue

    return (errors, num_found, obsolete_entries_found)


# Usage
lines = COUNTRY_ASM.read_text(encoding='utf-8').splitlines()

# gather codepage list from source comment instead of hard coding set
known_codepages = extract_known_codepages(lines)

# Country code validation
errors, entries_found, obsolete_entries_found = check_master(lines, known_codepages)

if errors:
    print(f"Errors = {errors}")
    sys.exit(2)

print(f"\n✅ Validation passed: {entries_found} entries found, with {obsolete_entries_found} obsolete entries; {len(known_codepages)} codepages")
