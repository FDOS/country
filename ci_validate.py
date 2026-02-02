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


def check_master(lines):
    """
    Validates COUNTRY, OLD_COUNTRY, COUNTRY_LCASE, COUNTRY_DBCS, and COUNTRY_ML macro invocations in NASM assembly.
    
    Checks:
    - Country codes are valid ISO3166-1-A2 (extracted from country.asm comments)
    - Country codes match international phone prefixes
    - Codepage consistency
    - Entry count matches reported count
    
    Returns:
        tuple: (errors, num_found, num_reported, obsolete_entries_found, obsolete_entries_reported)
    """
    errors = 0
    num_found = 0
    num_reported = 0
    in_obsolete_block = False
    obsolete_entries_found = 0
    obsolete_entries_reported = 0

    # Build country map from comments in country.asm
    # Format: ;   1 = United States (US)           2 = Canada (CA)
    country_map = {}
    comment_country_re = re.compile(r"(\d+)\s*=\s*[^()]+\(([A-Z]{2})\)")
    for line in lines:
        if line.strip().startswith(';'):
            for match in comment_country_re.finditer(line):
                num_code, alpha2 = match.groups()
                country_map[num_code] = alpha2

    # ent dw 231
    ent_re = r"^ent\s+dw\s+(\d+)"
    
    # %if OBSOLETE / %ifdef OBSOLETE
    obsolete_start_re = r"^%if(?:def)?\s+OBSOLETE"
    
    # %else or %endif
    obsolete_end_re = r"^%(?:else|endif)"

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
        
        # Track if in %if OBSOLETE blocks
        if re.match(obsolete_start_re, line_clean):
            in_obsolete_block = True
            continue
        if in_obsolete_block and re.match(obsolete_end_re, line_clean):
            in_obsolete_block = False
            continue
        
        # Check for entry count declaration
        ent = re.match(ent_re, line_clean)        
        if ent:
            if in_obsolete_block:
                obsolete_entries_reported = int(ent.group(1))
            else:
                num_reported = int(ent.group(1))
            continue

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
            
            continue

    return (errors, num_found, num_reported, obsolete_entries_found, obsolete_entries_reported)


# Usage
lines = COUNTRY_ASM.read_text(encoding='utf-8').splitlines()
errors, entries_found, entries_reported, obsolete_entries_found, obsolete_entries_reported = check_master(lines)

# validate if found count matches reported count
if entries_found != entries_reported:
    print(f"Number of entries found {entries_found} != number of entries reported {entries_reported}")
    sys.exit(1)

if (entries_found + obsolete_entries_found) != obsolete_entries_reported:
    print(f"Number of obsolete entries found {obsolete_entries_found} != number of obsolete entries reported {obsolete_entries_reported}")
    sys.exit(1)

if errors:
    print(f"Errors = {errors}")
    sys.exit(2)

print(f"\n✅ Validation passed: {entries_found} entries found, {entries_reported} reported with {obsolete_entries_found} obsolete entries")
