#!/usr/bin/python

import re
import iso3166
import phonenumbers
import sys



from pathlib import Path

COUNTRY_ASM = Path('country.asm')


def is_alpha2(code):
    return code.upper() in iso3166._by_alpha2

def is_country(code, pnum):
    if code.upper() == 'CA' and pnum =='2':  # French speaking Canada
        return True
    if code.upper() == 'LA' and pnum =='3':  # Latin America
        return True
    return code.upper() in phonenumbers.region_codes_for_country_code(int(pnum, 10))


def check_master(lines):
    errors = 0
    num_found = 0
    num_reported = 0

    # ent dw 171;
    ent_re = r"^ent\s+dw\s+(\d+)"

    # __us_437 dw 12,  1,437,0,0
    mas_re = r"^__([a-z]{2})_([0-9]+)\s+dw\s12,\s*(\d+),\s*(\d+)"

    # Countries 4x000 - 4x999 (Multilingual)
    # __nl_BE_850 dw 12, 40032,850,0,0
    mlt_re = r"^__([a-z]{2})_([A-Z]{2})_([0-9]+)\s+dw\s12,\s*(\d+),\s*(\d+)"

    for i, line in enumerate(lines):
        ent = re.match(ent_re, line)
        if ent:
            num_reported = int(ent.group(1))

        mas = re.match(mas_re, line)
        if mas:
            num_found += 1
            if not is_alpha2(mas.group(1)):
                print(f"Country ISO3166-1-A2 ({mas.group(1)}) invalid at line {i} '{line}'")
                errors += 1
                continue
            if not mas.group(2) == mas.group(4):
                print(f"Codepage mismatch ({mas.group(2)}) at line {i} '{line}'")
                errors += 1
                continue
            if not is_country(mas.group(1), mas.group(3)):
                print(f"Country ISO3166-1-A2 ({mas.group(1)}) mismatch with International Phone Prefix at line {i} '{line}'")
                errors += 1
                continue

        mlt = re.match(mlt_re, line)
        if mlt:
            num_found += 1
            if not is_alpha2(mlt.group(2)):
                print(f"Country ISO3166-1-A2 ({mlt.group(2)}) invalid at line {i} '{line}'")
                errors += 1
                continue
            if not mlt.group(3) == mlt.group(5):
                print(f"Codepage mismatch ({mlt.group(3)}) at line {i} '{line}'")
                errors += 1
                continue
            if not is_country(mlt.group(2), mlt.group(4)[2:]):
                print(f"Country ISO3166-1-A2 ({mlt.group(2)}) mismatch with International Phone Prefix at line {i} '{line}'")
                errors += 1
                continue

    return (errors, num_found, num_reported)


lines = COUNTRY_ASM.read_text(encoding='utf-8').splitlines()
errors, entries_found, entries_reported = check_master(lines)

if entries_found != entries_reported:
    print(f"Number of entries found {entries_found} != number of entries reported {entries_reported}")
    sys.exit(1)

if errors:
    print(f"Errors = {errors}")
    sys.exit(2)

