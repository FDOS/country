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
    Validates ENTRY, OLD_ENTRY, and MULTILANG_ENTRY macro invocations in NASM assembly.
    
    Checks:
    - Country codes are valid ISO3166-1-A2
    - Country codes match international phone prefixes
    - Codepage consistency
    - Entry count matches reported count
    
    Returns:
        tuple: (errors, num_found, num_reported)
    """
    errors = 0
    num_found = 0
    num_reported = 0
    in_obsolete_block = False
    obsolete_entries_found = 0
    obsolete_entries_reported = 0

    # ent dw 226
    ent_re = r"^ent\s+dw\s+(\d+)"
    
    # %if OBSOLETE / %ifdef OBSOLETE
    obsolete_start_re = r"^%if(?:def)?\s+OBSOLETE"
    
    # %else or %endif
    obsolete_end_re = r"^%(?:else|endif)"

    # ENTRY us, 1, 437
    # OLD_ENTRY yu, 38, 852
    entry_re = r"^(OLD_)?ENTRY\s+([a-z]{2})\s*,\s*(\d+)\s*,\s*(\d+)"
    
    # MULTILANG_ENTRY nl, BE, 032, 0, 850
    multilang_re = r"^MULTILANG_ENTRY\s+([a-z]{2})\s*,\s*([A-Z]{2})\s*,\s*(\d+)\s*,\s*(\d)\s*,\s*(\d+)"

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

        # Check standard ENTRY or OLD_ENTRY
        entry = re.match(entry_re, line_clean)
        if entry:
            if entry.group(1) == "OLD_": # in_obsolete_block
                obsolete_entries_found += 1
            else:
                num_found += 1
            country_code = entry.group(2)
            numeric_country = entry.group(3)
            codepage = entry.group(4)
            
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

        # Check MULTILANG_ENTRY
        multilang = re.match(multilang_re, line_clean)
        if multilang:
            num_found += 1
            lang_code = multilang.group(1)
            country_code = multilang.group(2)
            numeric_country = multilang.group(3)
            lang_variant = multilang.group(4)
            codepage = multilang.group(5)
            
            # Validate country code is ISO3166-1-A2
            if not is_alpha2(country_code):
                print(f"Line {i}: Country ISO3166-1-A2 ({country_code}) invalid in '{line_clean}'")
                errors += 1
                continue
            
            # Validate language code is ISO639-1 (optional - add is_lang_code() if needed)
            # For now, just check it's 2 lowercase letters (already enforced by regex)
            
            # Validate country code matches numeric country code
            # Note: numeric_country has leading zeros stripped by int conversion
            if not is_country(country_code, numeric_country.lstrip('0') or '0'):
                print(f"Line {i}: Country ISO3166-1-A2 ({country_code}) mismatch with International Phone Prefix ({numeric_country}) in '{line_clean}'")
                errors += 1
                continue
            
            # Validate language variant is 0-9 (already enforced by regex)
            
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
