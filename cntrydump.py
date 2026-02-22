#!/usr/bin/env python3
"""
cntrydump.py - DOS COUNTRY.SYS parser/dumper

Implements the MS-DOS/PC-DOS FAMILY format described in COUNTRY.LST (Matthias Paul).

High-level layout (MS-DOS family):

  FileHeader @ 0
    +00  BYTE   signature (0xFF)
    +01  7s     magic ("COUNTRY")
    +08  8s     reserved (usually 0)
    +10  WORD   entry_table_count
    +12  BYTE   pointer_info_type (also used as a 'version' byte; usually 1)
    +13  DWORD  pointer(s) to entry table(s) (often 0000:0017h)

  EntryTable @ each entry_table_offset (P)
    WORD   entry_record_count (X)
    X times Country_Codepage_Entry

  Country_Codepage_Entry
    WORD   header_len (expected 0x000C, not counting this WORD)
    WORD   country
    WORD   codepage
    WORD   reserved1 (0)
    WORD   reserved2 (0)
    DWORD  pointer to Country_Subfunction_Header (Q)

  Country_Subfunction_Header @ Q
    WORD   subfunction_count (Y)
    Y times Subfunction_Entry

  Subfunction_Entry
    WORD   entry_len (expected 0x0006, not counting this WORD)
    WORD   subfunction_id   (authoritative identifier)
    DWORD  data_offset      (absolute) -> Tagged structure

  Tagged structure @ data_offset (R)
    BYTE   tag (usually 0xFF; ARAMODE uses 0x00)
    7s     magic (padded with ASCII spaces in some cases)
    WORD   size  (length of following payload bytes)
    size bytes of payload follow.

"""

from __future__ import annotations

import argparse
import codecs
import html
import json
import os
import struct
import sys
import unicodedata
from dataclasses import dataclass
from pathlib import Path
from typing import Any, Dict, List, Optional, Set, Tuple


# ====
# ANSI Color Support
# ====

class AnsiColors:
    """ANSI color codes for terminal output (Windows and Linux compatible)."""
    RESET = "\033[0m"
    BOLD = "\033[1m"
    RED = "\033[91m"
    GREEN = "\033[92m"
    YELLOW = "\033[93m"
    BLUE = "\033[94m"
    MAGENTA = "\033[95m"
    CYAN = "\033[96m"


def _use_colors() -> bool:
    """
    Determine if ANSI colors should be used in output.
    
    Returns:
        True if output is to a TTY (not piped/redirected), False otherwise
    
    Note:
        Checks if stdout is a TTY. If output is piped or redirected to a file,
        colors are disabled. Works on both Windows and Linux.
    """
    return sys.stdout.isatty()


def _colorize(text: str, color: str, use_colors: bool) -> str:
    """
    Apply ANSI color to text if colors are enabled.
    
    Args:
        text: Text to colorize
        color: ANSI color code
        use_colors: Whether to apply colors
    
    Returns:
        Colored text if use_colors is True, otherwise plain text
    """
    if use_colors:
        return f"{color}{text}{AnsiColors.RESET}"
    return text


# ====
# Dictionaries / Names
# ====

# Mapping of subfunction IDs to their descriptive names
SUBFUNC_NAMES = {
    1: "CTYINFO (Country Information)",
    2: "UCASE (Uppercase Table)",
    3: "LCASE (Lowercase Table)",
    4: "FUCASE (Filename Uppercase Table)",
    5: "FCHAR (Filename Terminator Table)",
    6: "COLLATE (Collating Sequence Table)",
    7: "DBCS (DBCS Lead Byte Table)",
    20: "CCTORC (Arabic/Hebrew table)",
    21: "ARAMODE (Arabic/Hebrew modes)",
    35: "YESNO (Yes/No Prompt Characters)",
}

# Date format codes used in CTYINFO
DATE_FORMAT_NAMES = {0: "MDY", 1: "DMY", 2: "YMD"}

# Time format codes used in CTYINFO
TIME_FORMAT_NAMES = {0: "12-hour", 1: "24-hour"}

# Mapping of country codes to country names
COUNTRY_NAMES = {
    1: "United States", 2: "Canada (French)", 3: "Latin America", 4: "Canada (English)",
    7: "Russia", 20: "Egypt", 27: "South Africa", 30: "Greece", 31: "Netherlands",
    32: "Belgium", 33: "France", 34: "Spain", 36: "Hungary", 38: "Yugoslavia",
    39: "Italy", 40: "Romania", 41: "Switzerland", 42: "Czechoslovakia", 43: "Austria",
    44: "United Kingdom", 45: "Denmark", 46: "Sweden", 47: "Norway", 48: "Poland",
    49: "Germany", 51: "Peru", 52: "Mexico", 54: "Argentina", 55: "Brazil",
    56: "Chile", 57: "Colombia", 58: "Venezuela", 60: "Malaysia", 61: "Australia",
    62: "Indonesia", 63: "Philippines", 64: "New Zealand", 65: "Singapore",
    66: "Thailand", 81: "Japan", 82: "South Korea", 84: "Vietnam", 86: "China (PRC)",
    90: "Turkey", 91: "India", 92: "Pakistan", 93: "Afghanistan", 94: "Sri Lanka",
    95: "Myanmar", 98: "Iran", 212: "Morocco", 213: "Algeria", 216: "Tunisia",
    218: "Libya", 220: "Gambia", 221: "Senegal", 222: "Mauritania", 223: "Mali",
    224: "Guinea", 225: "Ivory Coast", 226: "Burkina Faso", 227: "Niger", 228: "Togo",
    229: "Benin", 230: "Mauritius", 231: "Liberia", 232: "Sierra Leone", 233: "Ghana",
    234: "Nigeria", 235: "Chad", 236: "Central African Republic", 237: "Cameroon",
    238: "Cape Verde", 239: "Sao Tome and Principe", 240: "Equatorial Guinea",
    241: "Gabon", 242: "Congo", 243: "Zaire", 244: "Angola", 245: "Guinea-Bissau",
    246: "Diego Garcia", 247: "Ascension Island", 248: "Seychelles", 249: "Sudan",
    250: "Rwanda", 251: "Ethiopia", 252: "Somalia", 253: "Djibouti", 254: "Kenya",
    255: "Tanzania", 256: "Uganda", 257: "Burundi", 258: "Mozambique", 260: "Zambia",
    261: "Madagascar", 262: "Reunion", 263: "Zimbabwe", 264: "Namibia", 265: "Malawi",
    266: "Lesotho", 267: "Botswana", 268: "Swaziland", 269: "Comoros", 290: "St. Helena",
    291: "Eritrea", 297: "Aruba", 298: "Faroe Islands", 299: "Greenland", 350: "Gibraltar",
    351: "Portugal", 352: "Luxembourg", 353: "Ireland", 354: "Iceland", 355: "Albania",
    356: "Malta", 357: "Cyprus", 358: "Finland", 359: "Bulgaria", 370: "Lithuania",
    371: "Latvia", 372: "Estonia", 373: "Moldova", 374: "Armenia", 375: "Belarus",
    376: "Andorra", 377: "Monaco", 378: "San Marino", 380: "Ukraine", 381: "Serbia",
    382: "Montenegro", 385: "Croatia", 386: "Slovenia", 387: "Bosnia and Herzegovina",
    389: "Macedonia", 420: "Czech Republic", 421: "Slovakia", 423: "Liechtenstein",
    500: "Falkland Islands", 501: "Belize", 502: "Guatemala", 503: "El Salvador",
    504: "Honduras", 505: "Nicaragua", 506: "Costa Rica", 507: "Panama",
    508: "St. Pierre and Miquelon", 509: "Haiti", 590: "Guadeloupe", 591: "Bolivia",
    592: "Guyana", 593: "Ecuador", 594: "French Guiana", 595: "Paraguay",
    596: "Martinique", 597: "Suriname", 598: "Uruguay", 599: "Netherlands Antilles",
    670: "East Timor", 672: "Antarctica", 673: "Brunei", 674: "Nauru",
    675: "Papua New Guinea", 676: "Tonga", 677: "Solomon Islands", 678: "Vanuatu",
    679: "Fiji", 680: "Palau", 681: "Wallis and Futuna", 682: "Cook Islands",
    683: "Niue", 684: "American Samoa", 685: "Samoa", 686: "Kiribati",
    687: "New Caledonia", 688: "Tuvalu", 689: "French Polynesia", 690: "Tokelau",
    691: "Micronesia", 692: "Marshall Islands", 850: "North Korea", 852: "Hong Kong",
    853: "Macau", 855: "Cambodia", 856: "Laos", 880: "Bangladesh", 886: "Taiwan",
    960: "Maldives", 961: "Lebanon", 962: "Jordan", 963: "Syria", 964: "Iraq",
    965: "Kuwait", 966: "Saudi Arabia", 967: "Yemen", 968: "Oman",
    970: "Palestinian Territory", 971: "United Arab Emirates", 972: "Israel",
    973: "Bahrain", 974: "Qatar", 975: "Bhutan", 976: "Mongolia", 977: "Nepal",
}

# Mapping of country codes to ISO 3166-1 alpha-2 codes
COUNTRY_ISO_CODES = {
    1: "US", 2: "CA", 3: "LA", 4: "CA", 7: "RU", 20: "EG", 27: "ZA", 30: "GR",
    31: "NL", 32: "BE", 33: "FR", 34: "ES", 36: "HU", 38: "YU", 39: "IT", 40: "RO",
    41: "CH", 42: "CZ", 43: "AT", 44: "GB", 45: "DK", 46: "SE", 47: "NO", 48: "PL",
    49: "DE", 51: "PE", 52: "MX", 54: "AR", 55: "BR", 56: "CL", 57: "CO", 58: "VE",
    60: "MY", 61: "AU", 62: "ID", 63: "PH", 64: "NZ", 65: "SG", 66: "TH", 81: "JP",
    82: "KR", 84: "VN", 86: "CN", 90: "TR", 91: "IN", 92: "PK", 93: "AF", 94: "LK",
    95: "MM", 98: "IR", 212: "MA", 213: "DZ", 216: "TN", 218: "LY", 220: "GM",
    221: "SN", 222: "MR", 223: "ML", 224: "GN", 225: "CI", 226: "BF", 227: "NE",
    228: "TG", 229: "BJ", 230: "MU", 231: "LR", 232: "SL", 233: "GH", 234: "NG",
    235: "TD", 236: "CF", 237: "CM", 238: "CV", 239: "ST", 240: "GQ", 241: "GA",
    242: "CG", 243: "CD", 244: "AO", 245: "GW", 246: "DG", 247: "AC", 248: "SC",
    249: "SD", 250: "RW", 251: "ET", 252: "SO", 253: "DJ", 254: "KE", 255: "TZ",
    256: "UG", 257: "BI", 258: "MZ", 260: "ZM", 261: "MG", 262: "RE", 263: "ZW",
    264: "NA", 265: "MW", 266: "LS", 267: "BW", 268: "SZ", 269: "KM", 290: "SH",
    291: "ER", 297: "AW", 298: "FO", 299: "GL", 350: "GI", 351: "PT", 352: "LU",
    353: "IE", 354: "IS", 355: "AL", 356: "MT", 357: "CY", 358: "FI", 359: "BG",
    370: "LT", 371: "LV", 372: "EE", 373: "MD", 374: "AM", 375: "BY", 376: "AD",
    377: "MC", 378: "SM", 380: "UA", 381: "RS", 382: "ME", 385: "HR", 386: "SI",
    387: "BA", 389: "MK", 420: "CZ", 421: "SK", 423: "LI", 500: "FK", 501: "BZ",
    502: "GT", 503: "SV", 504: "HN", 505: "NI", 506: "CR", 507: "PA", 508: "PM",
    509: "HT", 590: "GP", 591: "BO", 592: "GY", 593: "EC", 594: "GF", 595: "PY",
    596: "MQ", 597: "SR", 598: "UY", 599: "AN", 670: "TL", 672: "AQ", 673: "BN",
    674: "NR", 675: "PG", 676: "TO", 677: "SB", 678: "VU", 679: "FJ", 680: "PW",
    681: "WF", 682: "CK", 683: "NU", 684: "AS", 685: "WS", 686: "KI", 687: "NC",
    688: "TV", 689: "PF", 690: "TK", 691: "FM", 692: "MH", 850: "KP", 852: "HK",
    853: "MO", 855: "KH", 856: "LA", 880: "BD", 886: "TW", 960: "MV", 961: "LB",
    962: "JO", 963: "SY", 964: "IQ", 965: "KW", 966: "SA", 967: "YE", 968: "OM",
    970: "PS", 971: "AE", 972: "IL", 973: "BH", 974: "QA", 975: "BT", 976: "MN",
    977: "NP",
}

# Mapping of codepage numbers to their descriptive names
CODEPAGE_NAMES = {
    437: "US/OEM", 720: "Arabic", 737: "Greek", 775: "Baltic", 850: "Western European",
    852: "Central European", 855: "Cyrillic I", 857: "Turkish", 858: "Western European + Euro",
    860: "Portuguese", 861: "Icelandic", 862: "Hebrew", 863: "French Canadian",
    864: "Arabic", 865: "Nordic", 866: "Russian Cyrillic", 869: "Greek II", 874: "Thai",
    932: "Japanese Shift-JIS", 936: "Chinese Simplified (GBK)", 949: "Korean",
    950: "Chinese Traditional (Big5)", 1250: "Windows Central European",
    1251: "Windows Cyrillic", 1252: "Windows Western",
}

# Mapping of subfunction IDs to their allowed magic strings
# Used for validation to ensure tagged structures have the correct magic
ALLOWED_MAGICS: Dict[int, Tuple[str, ...]] = {
    1: ("CTYINFO",), 2: ("UCASE",), 3: ("LCASE",), 4: ("FUCASE", "UCASE"),
    5: ("FCHAR",), 6: ("COLLATE",), 7: ("DBCS",), 20: ("CCTORC",), 21: ("ARAMODE",),
    35: ("YESNO",),
}

# Control character display glyphs (CP437 glyphs for 0x00-0x1F)
CONTROL_CHAR_GLYPHS = [
    '␀', '☺', '☻', '♥', '♦', '♣', '♠', '•',  # 0x00-0x07
    '◘', '○', '◙', '♂', '♀', '♪', '♫', '☼',  # 0x08-0x0F
    '►', '◄', '↕', '‼', '¶', '§', '▬', '↨',  # 0x10-0x17
    '↑', '↓', '→', '←', '∟', '↔', '▲', '▼',  # 0x18-0x1F
]

# Control character names
CONTROL_CHAR_NAMES = [
    "NULL", "START OF HEADING", "START OF TEXT", "END OF TEXT",
    "END OF TRANSMISSION", "ENQUIRY", "ACKNOWLEDGE", "BELL",
    "BACKSPACE", "HORIZONTAL TAB", "LINE FEED", "VERTICAL TAB",
    "FORM FEED", "CARRIAGE RETURN", "SHIFT OUT", "SHIFT IN",
    "DATA LINK ESCAPE", "DEVICE CONTROL ONE", "DEVICE CONTROL TWO", "DEVICE CONTROL THREE",
    "DEVICE CONTROL FOUR", "NEGATIVE ACKNOWLEDGE", "SYNCHRONOUS IDLE", "END OF TRANSMISSION BLOCK",
    "CANCEL", "END OF MEDIUM", "SUBSTITUTE", "ESCAPE",
    "FILE SEPARATOR", "GROUP SEPARATOR", "RECORD SEPARATOR", "UNIT SEPARATOR",
]


# ====
# Data classes
# ====

@dataclass(frozen=True)
class FarPtr:
    """
    Represents a far pointer (segment:offset) from DOS COUNTRY.SYS file.

    Attributes:
        raw_u32: The raw 32-bit value read from file
        seg: Segment portion of the far pointer
        off: Offset portion of the far pointer
        linear: Calculated linear address (seg*16 + off, or just off if seg==0)
    """
    raw_u32: int
    seg: int
    off: int
    linear: int


@dataclass
class Tagged:
    """
    Represents a tagged data structure in COUNTRY.SYS.

    Tagged structures have the format:
        BYTE tag (usually 0xFF)
        7 bytes magic string
        WORD size
        <size> bytes payload

    Attributes:
        offset: File offset where this tagged structure begins
        tag: Tag byte (usually 0xFF, but ARAMODE uses 0x00)
        magic_raw: Raw 7-byte magic string from file
        magic: Cleaned magic string (stripped of spaces/nulls)
        size: Size of payload in bytes
        payload: The actual payload data
        dbcs_dummy_word: For DBCS tables with size==0, the dummy WORD that follows
    """
    offset: int
    tag: int
    magic_raw: bytes
    magic: str
    size: int
    payload: bytes
    dbcs_dummy_word: Optional[int] = None


@dataclass
class SubfuncEntry:
    """
    Represents a subfunction entry within a country/codepage entry.

    Attributes:
        offset: File offset of this subfunction entry
        entry_len: Length of this entry (not counting the length WORD itself)
        subfunc_id: Subfunction ID (1=CTYINFO, 2=UCASE, etc.)
        data_ptr: Far pointer to the tagged data structure
        tagged: Parsed tagged structure (if available)
        decoded: Decoded/interpreted data (if applicable, e.g., CTYINFO fields)
    """
    offset: int
    entry_len: int
    subfunc_id: int
    data_ptr: FarPtr
    tagged: Optional[Tagged] = None
    decoded: Optional[Dict[str, Any]] = None


@dataclass
class CountryEntry:
    """
    Represents a country/codepage entry in COUNTRY.SYS.
    
    Attributes:
        offset: File offset of this entry
        header_len: Length of entry header (expected 0x0C)
        country: Country code
        codepage: Codepage number
        reserved1: Reserved field (should be 0)
        reserved2: Reserved field (should be 0)
        subfunc_header_ptr: Far pointer to subfunction header
        subfuncs: List of subfunction entries for this country/codepage
    """
    offset: int
    header_len: int
    country: int
    codepage: int
    reserved1: int
    reserved2: int
    subfunc_header_ptr: FarPtr
    subfuncs: List[SubfuncEntry]


@dataclass
class ParsedCountrySys:
    """
    Complete parsed representation of a COUNTRY.SYS file.

    Attributes:
        file_size: Total size of the file in bytes
        entry_table_count: Number of entry tables (usually 1)
        pointer_info_type: Pointer type/version byte (usually 1)
        entry_table_ptrs: List of far pointers to entry tables
        entries: List of all country/codepage entries
        warnings: List of warning messages generated during parsing
    """
    file_size: int
    entry_table_count: int
    pointer_info_type: int
    entry_table_ptrs: List[FarPtr]
    entries: List[CountryEntry]
    warnings: List[str]


# ====
# Helpers
# ====

class ValidationError(Exception):
    """Raised when file format validation fails."""
    pass


def _country_name(c: int) -> str:
    """
    Get the descriptive name for a country code.

    Args:
        c: Country code (may be in form 4NCCC for multi-language entries)

    Returns:
        Country name string, or "unknown" if not in dictionary

    Note:
        Multi-language entries use form 4NCCC where N is index, CCC is country code.
        We extract the base country code by taking modulo 1000.
    """
    # Handle multi-language entries: form 4NCCC where N is index, CCC is country code
    if c >= 40000:
        c = c % 1000
    return COUNTRY_NAMES.get(c, "unknown")


def _country_iso_code(c: int) -> str:
    """
    Get the ISO 3166-1 alpha-2 code for a country code.

    Args:
        c: Country code

    Returns:
        2-letter ISO code, or "XX" if not found
    """
    if c >= 40000:
        c = c % 1000
    return COUNTRY_ISO_CODES.get(c, "XX")


def _codepage_name(cp: int) -> str:
    """
    Get the descriptive name for a codepage number.

    Args:
        cp: Codepage number

    Returns:
        Codepage name string, or "unknown" if not in dictionary
    """
    return CODEPAGE_NAMES.get(cp, "unknown")


def _asciiz(b: bytes) -> str:
    """
    Convert a null-terminated byte string to a displayable ASCII string.
    
    Args:
        b: Byte string (may contain null terminator)
    
    Returns:
        String with printable ASCII characters, non-printable shown as \\xHH,
        or "<unspecified>" if empty

    Note:
        Splits at first null byte, then converts remaining bytes to ASCII.
        Non-printable characters (outside 0x20-0x7E) are shown in hex notation.
        This is used for currency symbols, separators, and other locale strings.
    """
    s = b.split(b"\x00", 1)[0]
    out = []
    for c in s:
        if 0x20 <= c < 0x7F:
            out.append(chr(c))
        else:
            out.append(f"\\x{c:02X}")
    if not out:
        out.append("<unspecified>")
    return "".join(out)


def _hex(b: bytes) -> str:
    """
    Format bytes as space-separated hex values.

    Args:
        b: Bytes to format

    Returns:
        String like "0x01 0x02 0x03"
    """
    return " ".join(f"0x{x:02X}" for x in b)


def _format_byte_table(data: bytes, per_row: int = 8) -> str:
    """
    Format bytes as decimal, 3-char wide, right-aligned, space-padded, 8 per row.

    Args:
        data: Bytes to format
        per_row: Number of values per row (default 8)

    Returns:
        Multi-line string with "db" prefix for each row, suitable for
        displaying case conversion and collation tables

    Example:
        db 128 154  69  65 142  65 143 128
        db  69  69  69  73  73  73 142 143

    Note:
        Uses decimal for easier comparison with FreeDOS country.asm source.
    """
    lines = []
    for i in range(0, len(data), per_row):
        row = data[i:i+per_row]
        formatted = " ".join(f"{b:3d}" for b in row)
        lines.append(f"    db {formatted}")
    return "\n".join(lines)


def decode_far_ptr(u32: int, file_len: int, warnings: List[str], ctx: str) -> FarPtr:
    """
    Decode a far pointer from a 32-bit value.

    Args:
        u32: Raw 32-bit pointer value from file
        file_len: Total file length (for bounds checking)
        warnings: List to append warning messages to
        ctx: Context string for warning messages

    Returns:
        FarPtr object with decoded segment, offset, and linear address

    Note:
        DOS far pointers are segment:offset pairs. Linear address is seg*16+off.
        However, COUNTRY.SYS often uses segment=0, so linear address is just offset.
        If the calculated linear address is beyond EOF but offset is valid, we use
        the offset as the linear address (common in COUNTRY.SYS files).
    """
    raw = u32 & 0xFFFFFFFF
    off = raw & 0xFFFF
    seg = (raw >> 16) & 0xFFFF
    linear = seg * 16 + off
    if seg == 0:
        linear = off
    if linear > file_len and off <= file_len:
        warnings.append(f"{ctx}: far ptr {seg:04X}:{off:04X} => {linear:#x} beyond EOF; using low16 {off:#x}")
        linear = off
    if linear > file_len:
        warnings.append(f"{ctx}: pointer {linear:#x} beyond file length {file_len}")
    if linear != off != raw:
        warnings.append(f"{ctx}: {raw:04X} != {off:04X} != {linear:#x}; using low16 {off:#x}")
        linear = off
    return FarPtr(raw_u32=raw, seg=seg, off=off, linear=linear)


def token_fit_unpack(data: bytes, fields: List[Tuple[str, str, Any]]) -> Dict[str, Any]:
    """
    Unpack a structure using "token-fit" parsing.

    Args:
        data: Byte data to parse
        fields: List of (name, format, default) tuples where format is struct format char

    Returns:
        Dictionary with field names as keys, plus "_used" (bytes consumed) and
        "_extra" (remaining unparsed bytes)

    Note:
        Token-fit pafrsing allows for variable-length structures. If there aren't
        enough bytes for a field, the default value is used instead. This handles
        different versions of COUNTRY.SYS that may have shorter CTYINFO structures
        (e.g., MS-DOS 3.x vs 6.x).
    """
    pos = 0
    out: Dict[str, Any] = {}
    for name, fmt, default in fields:
        sz = struct.calcsize("<" + fmt)
        if pos + sz <= len(data):
            out[name] = struct.unpack_from("<" + fmt, data, pos)[0]
            pos += sz
        else:
            out[name] = default
    out["_used"] = pos
    out["_extra"] = data[pos:]
    return out


# ====
# Tagged / Subfunction decoders
# ====

def parse_tagged(buf: bytes, off: int, warnings: List[str], ctx: str) -> Tagged:
    """
    Parse a tagged data structure from the file buffer.

    Args:
        buf: Complete file buffer
        off: Offset where tagged structure begins
        warnings: List to append warning messages to
        ctx: Context string for warning messages

    Returns:
        Tagged object with parsed header and payload

    Note:
        Tagged structures have format: tag(1) + magic(7) + size(2) + payload(size).
        DBCS tables with size==0 have a special dummy WORD after the header.
    """
    flen = len(buf)
    if off + 10 > flen:
        warnings.append(f"{ctx}: tagged header truncated at {off:#x}")
        return Tagged(offset=off, tag=0, magic_raw=b"", magic="", size=0, payload=b"")
    tag = buf[off]
    magic_raw = buf[off + 1: off + 8]
    size = struct.unpack_from("<H", buf, off + 8)[0]
    magic_clean = magic_raw.rstrip(b" \x00").decode("ascii", "replace")
    end = off + 10 + size
    if end > flen:
        warnings.append(f"{ctx}: payload truncated (wanted {size} bytes) at {off:#x}")
        payload = buf[off + 10: flen]
    else:
        payload = buf[off + 10: end]
    
    # DBCS tables with size==0 have a dummy WORD following the header
    dbcs_dummy = None
    if magic_clean == "DBCS" and size == 0:
        if off + 12 <= flen:
            dbcs_dummy = struct.unpack_from("<H", buf, off + 10)[0]
    
    return Tagged(offset=off, tag=tag, magic_raw=magic_raw, magic=magic_clean,
                  size=size, payload=payload, dbcs_dummy_word=dbcs_dummy)


def decode_ctyinfo(tagged: Tagged, country: int) -> Dict[str, Any]:
    """
    Decode CTYINFO (Country Information) structure.

    Args:
        tagged: Tagged structure with CTYINFO data

    Returns:
        Dictionary with decoded country information fields

    Note:
        Uses token-fit parsing to handle different CTYINFO versions across DOS releases.
        Standard fields include country ID, codepage, date/time formats,
        currency symbol, separators, etc. Extra bytes are tracked for debugging.
    """
    fields = [
        ("country_id", "H", 0), ("codepage", "H", 0), ("date_format", "H", 0),
        ("currency_symbol", "5s", b""), ("thousands_sep", "2s", b""),
        ("decimal_sep", "2s", b""), ("date_sep", "2s", b""), ("time_sep", "2s", b""),
        ("currency_format", "B", 0), ("currency_decimals", "B", 0),
        ("time_format", "B", 0), ("case_map_ptr_raw", "I", 0),
        ("data_sep", "2s", b""), ("reserved", "10s", b""),
    ]
    t = token_fit_unpack(tagged.payload, fields)
    return {
        "country_id": t["country_id"], "codepage": t["codepage"],
        "date_format": t["date_format"],
        "date_format_name": DATE_FORMAT_NAMES.get(t["date_format"], "unknown"),
        "currency_symbol": _asciiz(t["currency_symbol"]),
        "thousands_sep": _asciiz(t["thousands_sep"]),
        "decimal_sep": _asciiz(t["decimal_sep"]),
        "date_sep": _asciiz(t["date_sep"]), "time_sep": _asciiz(t["time_sep"]),
        "currency_format": t["currency_format"],
        "currency_decimals": t["currency_decimals"],
        "time_format": t["time_format"],
        "time_format_name": TIME_FORMAT_NAMES.get(t["time_format"], "unknown"),
        "case_map_ptr_raw": t["case_map_ptr_raw"],
        "data_sep": _asciiz(t["data_sep"]),
        "reserved_len": len(t["reserved"]) if isinstance(t["reserved"], (bytes, bytearray)) else 0,
        "extra_len": len(t["_extra"]),
    }


def decode_fchar(tagged: Tagged) -> Dict[str, Any]:
    """
    Decode FCHAR (Filename Character) table.

    Args:
        tagged: Tagged structure with FCHAR data

    Returns:
        Dictionary with filename character restrictions and terminator list

    Note:
        FCHAR defines which characters are valid in filenames and which
        characters terminate filename parsing. Used by DOS to validate
        8.3 filenames.
    """
    p = tagged.payload
    if len(p) < 8:
        return {"raw_hex": _hex(p)}
    characteristics, low, high, r1, ex1, ex2, r2, nterm = struct.unpack_from("<BBBBBBBB", p, 0)
    # Bounds check: ensure we don't read past payload end
    nterm = min(nterm, len(p) - 8)
    terms = p[8:8 + nterm]
    return {
        "characteristics": characteristics, "lowest_char": low, "highest_char": high,
        "excluded_first": ex1, "excluded_last": ex2, "num_terminators": nterm,
        "terminators_hex": _hex(terms),
    }


def decode_yesno(tagged: Tagged) -> Dict[str, Any]:
    """
    Decode YESNO (Yes/No prompt characters) structure.

    Args:
        tagged: Tagged structure with YESNO data

    Returns:
        Dictionary with yes/no characters

    Note:
        Some COUNTRY.SYS files (notably FreeDOS) have a bug where null bytes
        are encoded as ASCII '0' (0x30) instead of 0x00. We detect and report
        this to help identify malformed files. Note that only the first byte
        of the yes/no fields are used so file is still functionally fine unless
        field is treated as DBCS value.
    """
    p = tagged.payload
    yes = _asciiz(p[0:2]) if len(p) >= 2 else ""
    # Detect FreeDOS bug: 0x00 mis-encoded as '0' (0x30)
    if len(p) >= 2 and p[1] == 0x30:
        yes += f" ==> {chr(p[0])} followed by zero mis-encoded as \'0\' == 0x30"
    no = _asciiz(p[2:4]) if len(p) >= 4 else ""
    return {"yes": yes, "no": no, "raw_hex": _hex(p)}


def decode_dbcs(tagged: Tagged) -> Dict[str, Any]:
    """
    Decode DBCS (Double-Byte Character Set) lead byte table.

    Args:
        tagged: Tagged structure with DBCS data

    Returns:
        Dictionary with DBCS lead byte ranges

    Note:
        DBCS tables list ranges of lead bytes for double-byte character sets
        (e.g., Japanese Shift-JIS, Chinese GBK). The list is terminated by 0x00 0x00.
        Some DBCS tables have size==0 and only contain a dummy WORD (used as a
        placeholder when no DBCS support is needed for that codepage).
    """
    p = tagged.payload
    ranges = []
    i = 0
    while i + 2 <= len(p):
        start = p[i]
        end = p[i + 1]
        if start == 0 and end == 0:
            break
        ranges.append((start, end))
        i += 2
    return {"ranges": ranges, "dbcs_dummy_word": tagged.dbcs_dummy_word, "payload_len": len(p)}


def validate_magic_and_tag(subfunc_id: int, tagged: Tagged, warnings: List[str], strict: bool) -> None:
    """
    Validate that a tagged structure has the correct magic string and tag.

    Args:
        subfunc_id: Subfunction ID that should match the magic
        tagged: Tagged structure to validate
        warnings: List to append warning messages to
        strict: If True, raise ValidationError on mismatch; if False, just warn

    Raises:
        ValidationError: If strict mode and validation fails

    Note:
        Each subfunction ID has an expected magic string (e.g., sf 1 = CTYINFO).
        ARAMODE is special and uses tag 0x00 instead of 0xFF. This flags
        corrupted files or mismatched subfunction IDs.
    """
    allowed = ALLOWED_MAGICS.get(subfunc_id)
    if allowed and tagged.magic not in allowed:
        msg = f"sf {subfunc_id}: magic mismatch: got \'{tagged.magic}\', expected one of {allowed} at {tagged.offset:#x}"
        if strict:
            raise ValidationError(msg)
        warnings.append(msg)
    if tagged.magic == "ARAMODE":
        if tagged.tag != 0x00:
            msg = f"ARAMODE: expected tag 0x00, got {tagged.tag:#x} at {tagged.offset:#x}"
            if strict:
                raise ValidationError(msg)
            warnings.append(msg)
    else:
        if tagged.tag not in (0xFF, 0x00):
            msg = f"tag unusual: got {tagged.tag:#x} at {tagged.offset:#x}"
            warnings.append(msg)


# ====
# Main parser
# ====

def parse_country_sys(buf: bytes, strict: bool = False) -> ParsedCountrySys:
    """
    Parse a complete COUNTRY.SYS file.

    Args:
        buf: Complete file contents as bytes
        strict: If True, treat validation warnings as fatal errors

    Returns:
        ParsedCountrySys object with all parsed data and warnings

    Raises:
        ValidationError: If file format is invalid or strict mode validation fails

    Note:
        This is the main entry point for parsing. It validates the file header,
        parses all entry tables, country/codepage entries, subfunction entries,
        and tagged data structures. Warnings are collected rather than raising
        exceptions (unless strict mode is enabled).
    """
    warnings: List[str] = []
    flen = len(buf)
    
    # Validate minimum file size for header
    if flen < 0x17:
        raise ValidationError("File too short for COUNTRY.SYS header")
    
    # Validate signature and magic
    sig = buf[0]
    magic = buf[1:8]
    if sig != 0xFF or magic.rstrip(b"\x00") != b"COUNTRY":
        raise ValidationError("Bad signature/magic (expected 0xFF + \'COUNTRY\')")
    
    # Check reserved bytes (should be all zeros, but not fatal if not)
    reserved = buf[8:16]
    if strict and reserved != b"\x00" * 8:
        warnings.append("reserved bytes in file header are not all zero")
    
    # Parse header fields
    entry_table_count = struct.unpack_from("<H", buf, 0x10)[0]
    pointer_info_type = buf[0x12]
    
    # Parse entry table pointers
    ptrs: List[FarPtr] = []
    base = 0x13
    for i in range(entry_table_count):
        if base + i * 4 + 4 > flen:
            warnings.append("pointer array truncated")
            break
        u32 = struct.unpack_from("<I", buf, base + i * 4)[0]
        ptrs.append(decode_far_ptr(u32, flen, warnings, f"entry_table_ptr[{i}]"))
    
    # Parse all country/codepage entries
    entries: List[CountryEntry] = []
    for t_i, p in enumerate(ptrs):
        P = p.linear
        if P + 2 > flen:
            warnings.append(f"entry_table[{t_i}]: offset {P:#x} beyond EOF")
            continue
        
        X = struct.unpack_from("<H", buf, P)[0]  # Number of entries in this table
        pos = P + 2
        
        for x_i in range(X):
            if pos + 2 > flen:
                warnings.append(f"entry_table[{t_i}] entry[{x_i}]: truncated")
                break
            
            header_len = struct.unpack_from("<H", buf, pos)[0]
            if header_len == 0:
                warnings.append(f"entry_table[{t_i}] entry[{x_i}]: header_len=0 at {pos:#x}")
            
            if pos + 2 + header_len > flen:
                warnings.append(f"entry_table[{t_i}] entry[{x_i}]: header extends beyond EOF")
                break
            
            # Parse country/codepage entry fields
            country = codepage = reserved1 = reserved2 = 0
            qptr = decode_far_ptr(0, flen, warnings, f"entry[{x_i}].subfunc_header_ptr")
            
            if header_len >= 12:
                country, codepage, reserved1, reserved2, u32q = struct.unpack_from("<HHHHI", buf, pos + 2)
                qptr = decode_far_ptr(u32q, flen, warnings, f"entry[{country}:{codepage}].subfunc_header_ptr")
            else:
                warnings.append(f"entry_table[{t_i}] entry[{x_i}]: header_len {header_len} < 12 (cannot parse fields)")
            
            # Parse subfunctions for this country/codepage
            Q = qptr.linear
            subfuncs: List[SubfuncEntry] = []
            
            if Q + 2 <= flen:
                Y = struct.unpack_from("<H", buf, Q)[0]  # Number of subfunctions
                sfpos = Q + 2
                
                for y_i in range(Y):
                    if sfpos + 2 > flen:
                        warnings.append(f"subfunc_header {Q:#x}: truncated")
                        break
                    
                    entry_len = struct.unpack_from("<H", buf, sfpos)[0]
                    if entry_len == 0:
                        warnings.append(f"subfunc_header {Q:#x}: entry_len=0 at {sfpos:#x} (would stall)")
                        break
                    
                    if sfpos + 2 + entry_len > flen:
                        warnings.append(f"subfunc_header {Q:#x}: entry beyond EOF at {sfpos:#x}")
                        break
                    
                    # Parse subfunction entry fields
                    sf_id = 0
                    dptr = decode_far_ptr(0, flen, warnings, f"entry[{country}:{codepage}].sf[{y_i}].data_ptr")
                    
                    if entry_len >= 6:
                        sf_id = struct.unpack_from("<H", buf, sfpos + 2)[0]
                        u32d = struct.unpack_from("<I", buf, sfpos + 4)[0]
                        dptr = decode_far_ptr(u32d, flen, warnings, f"entry[{country}:{codepage}].sf[{sf_id}].data_ptr")
                    
                    s = SubfuncEntry(offset=sfpos, entry_len=entry_len, subfunc_id=sf_id, data_ptr=dptr)
                    
                    # Parse tagged data structure if valid
                    if sf_id != 0 and dptr.linear < flen:
                        tagged = parse_tagged(buf, dptr.linear, warnings, f"sf[{sf_id}]")
                        validate_magic_and_tag(sf_id, tagged, warnings, strict)
                        s.tagged = tagged
                    
                        # Decode known subfunction types
                        if sf_id == 1 and tagged.magic == "CTYINFO":
                            s.decoded = decode_ctyinfo(tagged, country)
                        elif sf_id == 5 and tagged.magic == "FCHAR":
                            s.decoded = decode_fchar(tagged)
                        elif sf_id == 7 and tagged.magic == "DBCS":
                            s.decoded = decode_dbcs(tagged)
                        elif sf_id == 35 and tagged.magic in ("YESNO", "ARAMODE"):
                            s.decoded = decode_yesno(tagged)
                    
                    subfuncs.append(s)
                    sfpos += 2 + entry_len
            
            entries.append(CountryEntry(
                offset=pos, header_len=header_len, country=country,
                codepage=codepage, reserved1=reserved1, reserved2=reserved2,
                subfunc_header_ptr=qptr, subfuncs=subfuncs
            ))
            pos += 2 + header_len
    
    # Warn about unusual header values (not fatal)
    if entry_table_count != 1:
        warnings.append(f"entry_table_count={entry_table_count} (normally 1); parsed all available pointers")
    if pointer_info_type != 1:
        warnings.append(f"pointer_info_type={pointer_info_type} (normally 1); continuing anyway")
    
    return ParsedCountrySys(
        file_size=flen, entry_table_count=entry_table_count,
        pointer_info_type=pointer_info_type, entry_table_ptrs=ptrs,
        entries=entries, warnings=warnings
    )


# ====
# Copyright / Version detection
# ====

def find_copyright_and_version(buf: bytes) -> Optional[Dict[str, Any]]:
    """
    Scan from end of file for copyright string and optional VERSION tag.

    Args:
        buf: Complete file contents as bytes

    Returns:
        Dictionary with 'copyright' string and optional 'version' (major.minor),
        or None if no copyright found

    Note:
        Scans backward from EOF looking for a 0x00 byte. If found, scans backward
        for a tagged structure (0xFF + magic + size). If the 0x00 is past the end
        of this structure, everything after the 0x00 is the copyright string.
        If the tagged structure has magic "VERSION" and size==4, it contains
        major and minor version WORDs. Limits search to last 1000 bytes for perf.
    """
    flen = len(buf)
    if flen < 10:
        return None

    # Scan backward from end looking for 0x00 byte (usually preceeds terminating string)
    zero_pos = None
    for i in range(flen - 1, -1, -1):
        if buf[i] == 0x00:
            zero_pos = i
            break

    if zero_pos is None:
        return None

    # Scan backward from zero_pos looking for tagged structure (0xFF byte)
    tagged_start = None
    for i in range(zero_pos - 1, max(0, zero_pos - 1000), -1):  # Limit search to 1000 bytes
        if buf[i] == 0xFF:
            # Check if this looks like a valid tagged structure
            if i + 10 <= flen:
                magic_raw = buf[i + 1: i + 8]
                size = struct.unpack_from("<H", buf, i + 8)[0]
                tagged_end = i + 10  # End of header (payload not included in check)
                # Check if zero_pos is past the tagged header
                if tagged_end < zero_pos:
                    tagged_start = i
                    break

    if tagged_start is None:
        return None

    # Extract copyright (everything after the 0x00)
    copyright_bytes = buf[zero_pos + 1:]
    copyright_str = copyright_bytes.decode("ascii", "replace").rstrip("\x00 \r\n")

    result: Dict[str, Any] = {"copyright": copyright_str}

    # Check if the tagged structure is VERSION
    magic_raw = buf[tagged_start + 1: tagged_start + 8]
    magic = magic_raw.rstrip(b" \x00").decode("ascii", "replace")
    size = struct.unpack_from("<H", buf, tagged_start + 8)[0]

    if magic == "VERSION" and size == 4:
        # Parse version: <major>\x00<minor>\x00
        payload_start = tagged_start + 10
        if payload_start + 4 <= flen:
            major = buf[payload_start:payload_start+2].decode("ascii", "replace").rstrip("\x00")
            minor = buf[payload_start+2:payload_start+4].decode("ascii", "replace").rstrip("\x00")
            result["version"] = major + "." + minor

    return result


# ====
# Compare helpers
# ====

def compare_ctyinfo(a: Dict[str, Any], b: Dict[str, Any], use_colors: bool = False) -> List[str]:
    """
    Compare two CTYINFO decoded structures and return human-readable differences.

    Args:
        a: Decoded CTYINFO from file A
        b: Decoded CTYINFO from file B
        use_colors: Whether to use ANSI colors in output

    Returns:
        List of difference strings (empty if identical)

    Note:
        Compares only decoded fields that matter to users (date/time formats,
        separators, currency, etc.). Skips internal fields like case_map_ptr_raw.
        Returns concise diffs like "date_sep: '-' in A, '/' in B".
    """
    diffs = []
    # Fields to compare (skip internal/debug fields)
    compare_fields = [
        "date_format", "date_format_name", "currency_symbol", "thousands_sep",
        "decimal_sep", "date_sep", "time_sep", "currency_format",
        "currency_decimals", "time_format", "time_format_name", "data_sep",
    ]
    for field in compare_fields:
        val_a = a.get(field, "<missing>")
        val_b = b.get(field, "<missing>")
        if val_a != val_b:
            diff_line = f"    {field}: '{val_a}' in A, '{val_b}' in B"
            diffs.append(_colorize(diff_line, AnsiColors.YELLOW, use_colors))
    return diffs


def compare_table_data(tag_a: Tagged, tag_b: Tagged, sf_id: int, use_colors: bool = False) -> Optional[str]:
    """
    Compare two table payloads (UCASE, LCASE, COLLATE, etc.) and return summary.

    Args:
        tag_a: Tagged structure from file A
        tag_b: Tagged structure from file B
        sf_id: Subfunction ID (for naming in output)
        use_colors: Whether to use ANSI colors in output

    Returns:
        Summary string if different, None if identical

    Note:
        Fast check: compare lengths first. If same, count differing bytes.
        If only 1-2 adjacent lines (8 bytes each) differ, shows the actual
        byte values in "db" format for easy comparison, with differing bytes
        highlighted in color.
    """
    pa = tag_a.payload
    pb = tag_b.payload
    
    if len(pa) != len(pb):
        msg = f"    Table sizes differ: A={len(pa)} bytes, B={len(pb)} bytes"
        return _colorize(msg, AnsiColors.RED, use_colors)
    
    # Find differing byte positions
    diff_positions = [i for i in range(len(pa)) if pa[i] != pb[i]]
    if not diff_positions:
        return None
    
    table_name = SUBFUNC_NAMES.get(sf_id, f"sf{sf_id}")
    diff_count = len(diff_positions)
    
    # Check if differences are in 1-2 adjacent lines (8 bytes per line)
    # Group diff positions by line number
    diff_lines = set(pos // 8 for pos in diff_positions)
    
    # Check if lines are adjacent (max 2 lines, consecutive)
    if len(diff_lines) <= 2:
        sorted_lines = sorted(diff_lines)
        if len(sorted_lines) == 1 or (len(sorted_lines) == 2 and sorted_lines[1] - sorted_lines[0] == 1):
            # Show detailed byte comparison for these lines
            result = [_colorize(f"  {diff_count} byte(s) differ in {table_name}:", AnsiColors.YELLOW, use_colors)]
            for line_num in sorted_lines:
                start = line_num * 8
                end = min(start + 8, len(pa))
                row_a = pa[start:end]
                row_b = pb[start:end]
                
                # Format as "db" lines with color highlighting for differing bytes
                formatted_a_parts = []
                formatted_b_parts = []
                for i, (byte_a, byte_b) in enumerate(zip(row_a, row_b)):
                    pos = start + i
                    if pos in diff_positions:
                        # Highlight differing bytes
                        formatted_a_parts.append(_colorize(f"{byte_a:3d}", AnsiColors.RED, use_colors))
                        formatted_b_parts.append(_colorize(f"{byte_b:3d}", AnsiColors.GREEN, use_colors))
                    else:
                        formatted_a_parts.append(f"{byte_a:3d}")
                        formatted_b_parts.append(f"{byte_b:3d}")
                
                formatted_a = " ".join(formatted_a_parts)
                formatted_b = " ".join(formatted_b_parts)
                
                result.append(_colorize(f"    Line {line_num} (bytes {start}-{end-1}):", AnsiColors.CYAN, use_colors))
                result.append(f"      A: db {formatted_a}")
                result.append(f"      B: db {formatted_b}")
            
            return "\n".join(result)
    
    # Default: just show count
    msg = f"  {diff_count} byte(s) differ in {table_name}"
    return _colorize(msg, AnsiColors.YELLOW, use_colors)


def compare_country_sys(doc_a: ParsedCountrySys, doc_b: ParsedCountrySys, 
                    file_a: str, file_b: str, country: Optional[int] = None, 
                    codepage: Optional[int] = None) -> None:
    """
    Compare two parsed COUNTRY.SYS files and print hierarchical diff summary.

    Args:
        doc_a: Parsed data from file A
        doc_b: Parsed data from file B
        file_a: Filename of A (for display)
        file_b: Filename of B (for display)
        country: Filter by country code (None = no filter)
        codepage: Filter by codepage (None = no filter)

    Note:
        Compare summarizes by country/codepage key to highlight real divergences fast.
        Groups by country, shows missing/extra codepages, then dives into subfunction
        diffs for shared entries. Uses sets for O(1) lookups and clear set operations.
        Output is hierarchical with bullets for easy scanning. Avoids exhaustive dumps
        unless they improve understanding (e.g., CTYINFO field diffs are shown, but
        256-byte COLLATE tables are summarized as "5 bytes differ").
        Supports ANSI colors when output is to a TTY (not piped).
    """
    use_colors = _use_colors()
    
    print(_colorize(f"# Comparing COUNTRY.SYS files", AnsiColors.BOLD + AnsiColors.CYAN, use_colors))
    print(f"# File A: {file_a} ({doc_a.file_size} bytes, {len(doc_a.entries)} entries)")
    print(f"# File B: {file_b} ({doc_b.file_size} bytes, {len(doc_b.entries)} entries)")
    
    # Show filter info if active
    if country is not None or codepage is not None:
        filter_parts = []
        if country is not None:
            filter_parts.append(f"country={country}")
        if codepage is not None:
            filter_parts.append(f"codepage={codepage}")
        print(_colorize(f"# Filter: {', '.join(filter_parts)}", AnsiColors.YELLOW, use_colors))
    
    print()

    # Apply filters to entries
    entries_a = filter_entries(doc_a.entries, country, codepage)
    entries_b = filter_entries(doc_b.entries, country, codepage)
    
    # Build lookup dicts: (country, codepage) -> CountryEntry
    # O(1) lookups for fast comparison
    map_a: Dict[Tuple[int, int], CountryEntry] = {(e.country, e.codepage): e for e in entries_a}
    map_b: Dict[Tuple[int, int], CountryEntry] = {(e.country, e.codepage): e for e in entries_b}
    
    keys_a = set(map_a.keys())
    keys_b = set(map_b.keys())
    
    only_a = keys_a - keys_b
    only_b = keys_b - keys_a
    shared = keys_a & keys_b
    
    # Report missing/extra entries
    if only_a:
        print(_colorize("## Entries only in A:", AnsiColors.BOLD + AnsiColors.RED, use_colors))
        for country, codepage in sorted(only_a):
            cname = _country_name(country)
            cpname = _codepage_name(codepage)
            print(f"  - {country}:{codepage} ({cname} / {cpname})")
        print()
    
    if only_b:
        print(_colorize("## Entries only in B:", AnsiColors.BOLD + AnsiColors.GREEN, use_colors))
        for country, codepage in sorted(only_b):
            cname = _country_name(country)
            cpname = _codepage_name(codepage)
            print(f"  - {country}:{codepage} ({cname} / {cpname})")
        print()
    
    if not shared:
        print(_colorize("## No shared entries to compare.", AnsiColors.YELLOW, use_colors))
        return
    
    # Compare shared entries
    print(_colorize(f"## Comparing {len(shared)} shared entries:", AnsiColors.BOLD + AnsiColors.BLUE, use_colors))
    print()
    
    # Group by country for hierarchical output
    # Aggregate codepages per country to show "Country X: A has [cp1,cp2], B has [cp1,cp2,cp3]"
    countries_a: Dict[int, Set[int]] = {}
    countries_b: Dict[int, Set[int]] = {}
    for country, codepage in keys_a:
        countries_a.setdefault(country, set()).add(codepage)
    for country, codepage in keys_b:
        countries_b.setdefault(country, set()).add(codepage)
    
    all_countries = sorted(set(countries_a.keys()) | set(countries_b.keys()))
    
    for country in all_countries:
        cname = _country_name(country)
        cps_a = countries_a.get(country, set())
        cps_b = countries_b.get(country, set())
        
        # Check if codepage sets differ for this country
        if cps_a != cps_b:
            only_a_cps = cps_a - cps_b
            only_b_cps = cps_b - cps_a
            shared_cps = cps_a & cps_b
            
            print(_colorize(f"### Country {country} ({cname}):", AnsiColors.BOLD + AnsiColors.MAGENTA, use_colors))
            if only_a_cps:
                print(_colorize(f"  Codepages only in A: {sorted(only_a_cps)}", AnsiColors.RED, use_colors))
            if only_b_cps:
                print(_colorize(f"  Codepages only in B: {sorted(only_b_cps)}", AnsiColors.GREEN, use_colors))
            if shared_cps:
                print(f"  Shared codepages: {sorted(shared_cps)}")
            print()
        
        # Compare subfunctions for shared (country, codepage) pairs
        for codepage in sorted(cps_a & cps_b):
            key = (country, codepage)
            if key not in shared:
                continue
            
            entry_a = map_a[key]
            entry_b = map_b[key]
            
            # Build subfunction maps: sf_id -> SubfuncEntry
            sf_map_a = {s.subfunc_id: s for s in entry_a.subfuncs if s.subfunc_id != 0}
            sf_map_b = {s.subfunc_id: s for s in entry_b.subfuncs if s.subfunc_id != 0}
            
            sf_ids_a = set(sf_map_a.keys())
            sf_ids_b = set(sf_map_b.keys())
            
            only_a_sf = sf_ids_a - sf_ids_b
            only_b_sf = sf_ids_b - sf_ids_a
            shared_sf = sf_ids_a & sf_ids_b
            
            # Check if there are any differences for this entry
            has_diffs = bool(only_a_sf or only_b_sf)
            
            # Check for data diffs in shared subfunctions
            data_diffs = []
            for sf_id in sorted(shared_sf):
                sf_a = sf_map_a[sf_id]
                sf_b = sf_map_b[sf_id]
                
                # Compare CTYINFO fields
                if sf_id == 1 and sf_a.decoded and sf_b.decoded:
                    cty_diffs = compare_ctyinfo(sf_a.decoded, sf_b.decoded, use_colors)
                    if cty_diffs:
                        data_diffs.append((sf_id, "CTYINFO", cty_diffs))
                
                # Compare table data (UCASE, LCASE, COLLATE, etc.)
                elif sf_id in (2, 3, 4, 6) and sf_a.tagged and sf_b.tagged:
                    table_diff = compare_table_data(sf_a.tagged, sf_b.tagged, sf_id, use_colors)
                    if table_diff:
                        data_diffs.append((sf_id, SUBFUNC_NAMES.get(sf_id, f"sf{sf_id}"), [table_diff]))
                
                # Compare DBCS ranges
                elif sf_id == 7 and sf_a.decoded and sf_b.decoded:
                    ranges_a = sf_a.decoded.get("ranges", [])
                    ranges_b = sf_b.decoded.get("ranges", [])
                    if ranges_a != ranges_b:
                        diff_line = f"  DBCS ranges differ: A={ranges_a}, B={ranges_b}"
                        data_diffs.append((sf_id, "DBCS", [_colorize(diff_line, AnsiColors.YELLOW, use_colors)]))
                
                # Compare YESNO
                elif sf_id == 35 and sf_a.decoded and sf_b.decoded:
                    yes_a = sf_a.decoded.get("yes", "")
                    yes_b = sf_b.decoded.get("yes", "")
                    no_a = sf_a.decoded.get("no", "")
                    no_b = sf_b.decoded.get("no", "")
                    yesno_diffs = []
                    if yes_a != yes_b:
                        diff_line = f"  yes: '{yes_a}' in A, '{yes_b}' in B"
                        yesno_diffs.append(_colorize(diff_line, AnsiColors.YELLOW, use_colors))
                    if no_a != no_b:
                        diff_line = f"  no: '{no_a}' in A, '{no_b}' in B"
                        yesno_diffs.append(_colorize(diff_line, AnsiColors.YELLOW, use_colors))
                    if yesno_diffs:
                        data_diffs.append((sf_id, "YESNO", yesno_diffs))
            
            if data_diffs:
                has_diffs = True
            
            # Only print entry header if there are differences
            if not has_diffs:
                continue
            
            cpname = _codepage_name(codepage)
            entry_header = f"### [{country}:{codepage}] {cname} / {cpname}"
            print(_colorize(entry_header, AnsiColors.BOLD + AnsiColors.CYAN, use_colors))
            
            if only_a_sf:
                sf_names_a = [f"{sf_id} ({SUBFUNC_NAMES.get(sf_id, f'sf{sf_id}')})" for sf_id in sorted(only_a_sf)]
                msg = f"  Subfunctions only in A: {', '.join(sf_names_a)}"
                print(_colorize(msg, AnsiColors.RED, use_colors))
            if only_b_sf:
                sf_names_b = [f"{sf_id} ({SUBFUNC_NAMES.get(sf_id, f'sf{sf_id}')})" for sf_id in sorted(only_b_sf)]
                msg = f"  Subfunctions only in B: {', '.join(sf_names_b)}"
                print(_colorize(msg, AnsiColors.GREEN, use_colors))
            
            # Print data diffs
            for sf_id, sf_name, diffs in data_diffs:
                diff_header = f"  Subfunction {sf_id} ({sf_name}) differs:"
                print(_colorize(diff_header, AnsiColors.MAGENTA, use_colors))
                for diff in diffs:
                    print(diff)
            
            print()
    
    # Print warnings if any
    if doc_a.warnings or doc_b.warnings:
        print(_colorize("## Warnings:", AnsiColors.BOLD + AnsiColors.YELLOW, use_colors))
        if doc_a.warnings:
            print(f"### File A ({file_a}):")
            for w in doc_a.warnings:
                print(f"  - {w}")
        if doc_b.warnings:
            print(f"### File B ({file_b}):")
            for w in doc_b.warnings:
                print(f"  - {w}")


# ====
# Output
# ====

def to_jsonable(doc: ParsedCountrySys) -> Dict[str, Any]:
    """
    Convert ParsedCountrySys to JSON-serializable dictionary.

    Args:
        doc: Parsed COUNTRY.SYS data

    Returns:
        Dictionary suitable for json.dumps()

    Note:
        Converts all dataclass instances to plain dicts. Useful for
        debugging, archiving, or feeding to other tools.
    """
    def ptr(p: FarPtr) -> Dict[str, Any]:
        return {"raw_u32": p.raw_u32, "seg": p.seg, "off": p.off, "linear": p.linear}
    
    out = {
        "file_size": doc.file_size, "entry_table_count": doc.entry_table_count,
        "pointer_info_type": doc.pointer_info_type,
        "entry_table_ptrs": [ptr(p) for p in doc.entry_table_ptrs],
        "entries": [], "warnings": doc.warnings,
    }
    
    for e in doc.entries:
        ent = {
            "offset": e.offset, "header_len": e.header_len, "country": e.country,
            "codepage": e.codepage, "subfunc_header_ptr": ptr(e.subfunc_header_ptr),
            "subfuncs": [],
        }
        for s in e.subfuncs:
            sj = {
                "offset": s.offset, "entry_len": s.entry_len, "id": s.subfunc_id,
                "data_ptr": ptr(s.data_ptr), "tagged": None, "decoded": s.decoded,
            }
            if s.tagged:
                sj["tagged"] = {
                    "offset": s.tagged.offset, "tag": s.tagged.tag, "magic": s.tagged.magic,
                    "magic_raw_hex": _hex(s.tagged.magic_raw), "size": s.tagged.size,
                    "payload_hex": _hex(s.tagged.payload),
                    "dbcs_dummy_word": s.tagged.dbcs_dummy_word,
                }
            ent["subfuncs"].append(sj)
        out["entries"].append(ent)
    
    return out


def filter_entries(entries: List[CountryEntry], country: Optional[int], codepage: Optional[int]) -> List[CountryEntry]:
    """
    Filter country entries by country code and/or codepage.

    Args:
        entries: List of all country entries
        country: Country code to filter by (None = no filter)
        codepage: Codepage to filter by (None = no filter)

    Returns:
        Filtered list of entries matching the criteria

    Note:
        Useful for extracting just one locale from a large COUNTRY.SYS.
        Filters are ANDed together if both are specified.
    """
    filtered = entries
    if country is not None:
        filtered = [e for e in filtered if e.country == country]
    if codepage is not None:
        filtered = [e for e in filtered if e.codepage == codepage]
    return filtered


def print_summary(doc: ParsedCountrySys, *, unsorted: bool, no_offsets: bool,
                  country: Optional[int], codepage: Optional[int]) -> None:
    """
    Print a concise summary of COUNTRY.SYS entries.

    Args:
        doc: Parsed COUNTRY.SYS data
        unsorted: If True, don't sort entries by (country, codepage)
        no_offsets: If True, suppress file offset information
        country: Filter by country code (None = no filter)
        codepage: Filter by codepage (None = no filter)

    Note:
        Summary format shows compact one line per entry with 
        country:codepage, names, and list of subfunction IDs.
    """
    entries = filter_entries(doc.entries, country, codepage)
    if not unsorted:
        # Sort entries by (country, codepage) for predictable output
        entries.sort(key=lambda e: (e.country, e.codepage))

    # File header info
    print(f"# COUNTRY.SYS File Header")
    print(f"# File size: {doc.file_size} bytes")
    print(f"# entry_table_count: {doc.entry_table_count}")
    print(f"# pointer_info_type: {doc.pointer_info_type}")
    for i, p in enumerate(doc.entry_table_ptrs):
        print(f"# entry_table[{i}] offset: {p.linear:#06x}")
    print(f"# Total entries: {len(entries)}\n")

    for e in entries:
        cname = _country_name(e.country)
        cpname = _codepage_name(e.codepage)
        
        # Sort subfunctions by ID for consistent display (unless --unsorted)
        subfuncs = e.subfuncs if unsorted else sorted(e.subfuncs, key=lambda s: s.subfunc_id)
        sf_ids = [s.subfunc_id for s in subfuncs if s.subfunc_id != 0]
        sf_ids_str = ",".join(str(i) for i in sf_ids)
        
        line = f"{e.country:3d}:{e.codepage:4d}  {cname} / {cpname}  subfuncs=[{sf_ids_str}]"
        print(line)
        if not no_offsets:
            print(f"  entry_off={e.offset:#06x}  subfunc_hdr={e.subfunc_header_ptr.linear:#06x}")

    if doc.warnings:
        print("\n# WARNINGS:")
        for w in doc.warnings:
            print(f"# {w}")


def print_default(doc: ParsedCountrySys, *, unsorted: bool, no_offsets: bool,
                  country: Optional[int], codepage: Optional[int]) -> None:
    """
    Print detailed information about COUNTRY.SYS entries.

    Args:
        doc: Parsed COUNTRY.SYS data
        unsorted: If True, don't sort entries or subfunctions
        no_offsets: If True, suppress file offset information
        country: Filter by country code (None = no filter)
        codepage: Filter by codepage (None = no filter)

    Note:
        Default format shows full details for each entry including all
        subfunction data, tagged structures, and decoded information.
        Case/collate tables are displayed as decimal byte tables.
        By default, subfunctions are sorted numerically by ID for easier
        scanning and diffing; use --unsorted to preserve original file order
        (useful for validating file structure or debugging).
    """
    entries = filter_entries(doc.entries, country, codepage)
    if not unsorted:
        # Sort entries by (country, codepage) for predictable output
        entries.sort(key=lambda e: (e.country, e.codepage))

    # File header info
    print(f"# COUNTRY.SYS File Header")
    print(f"# File size: {doc.file_size} bytes")
    print(f"# entry_table_count: {doc.entry_table_count}")
    print(f"# pointer_info_type: {doc.pointer_info_type}")
    for i, p in enumerate(doc.entry_table_ptrs):
        print(f"# entry_table[{i}] offset: {p.linear:#06x}")
    print(f"# Total entries: {len(entries)}\n")

    for e in entries:
        cname = _country_name(e.country)
        cpname = _codepage_name(e.codepage)
        print(f"[{e.country}:{e.codepage}]  # {cname} / {cpname}")
        if not no_offsets:
            print(f"  entry_offset={e.offset:#06x}")
            print(f"  subfunc_header_ptr={e.subfunc_header_ptr.linear:#06x}")

        # Sort subfunctions by ID for consistent display (unless --unsorted)
        # Python's sorted() is stable: if two subfunctions share an ID (rare/malformed),
        # original order is preserved. This makes diffs cleaner and grep easier.
        subfuncs = e.subfuncs if unsorted else sorted(e.subfuncs, key=lambda s: s.subfunc_id)
        
        for s in subfuncs:
            if s.subfunc_id == 0:
                continue
            
            title = SUBFUNC_NAMES.get(s.subfunc_id, f"Subfunction {s.subfunc_id}")
            print(f"  sf {s.subfunc_id}: {title}")
            if not no_offsets:
                print(f"    sf_entry_off={s.offset:#06x}  data_ptr={s.data_ptr.linear:#06x}")
            
            if s.tagged:
                print(f"    tagged: tag={s.tagged.tag:#04x} magic=\'{s.tagged.magic}\' size={s.tagged.size:#x}")
                if s.tagged.magic == "DBCS" and s.tagged.size == 0 and s.tagged.dbcs_dummy_word is not None:
                    print(f"    DBCS dummy_word={s.tagged.dbcs_dummy_word:#06x}")

                # Print byte tables for case/collate tables
                if s.subfunc_id in (2, 3, 4, 6) and s.tagged.payload:
                    print(f"    {s.tagged.magic} table ({len(s.tagged.payload)} bytes):")
                    print(_format_byte_table(s.tagged.payload))
                
                # Print raw bytes for CTYINFO section
                #if s.subfunc_id == 1 and s.tagged.payload:
                #    print(f"    {s.tagged.magic} raw bytes ({len(s.tagged.payload)} bytes):")
                #    print(_format_byte_table(s.tagged.payload))

            if s.decoded:
                for k, v in s.decoded.items():
                    print(f"    {k} = {v}")
        print()

    if doc.warnings:
        print("# WARNINGS:")
        for w in doc.warnings:
            print(f"# {w}")


# ====
# HTML Generation
# ====

def codepage_byte_to_unicode(byte_value: int, codepage_number: int) -> str:
    """
    Convert a byte value to its Unicode character using the specified codepage.
    
    Args:
        byte_value: Byte value (0-255)
        codepage_number: DOS codepage number (e.g., 437, 850)
    
    Returns:
        Unicode character string, or replacement character if conversion fails
    """
    # Map DOS codepage numbers to Python codec names
    codec_map = {
        437: 'cp437', 720: 'cp720', 737: 'cp737', 775: 'cp775',
        850: 'cp850', 852: 'cp852', 855: 'cp855', 857: 'cp857',
        858: 'cp858', 860: 'cp860', 861: 'cp861', 862: 'cp862',
        863: 'cp863', 864: 'cp864', 865: 'cp865', 866: 'cp866',
        869: 'cp869', 874: 'cp874', 932: 'cp932', 936: 'cp936',
        949: 'cp949', 950: 'cp950', 1250: 'cp1250', 1251: 'cp1251',
        1252: 'cp1252',
    }
    
    codec_name = codec_map.get(codepage_number, 'cp437')
    
    try:
        return bytes([byte_value]).decode(codec_name)
    except (UnicodeDecodeError, LookupError):
        # Fallback to CP437 for unknown codepages
        try:
            return bytes([byte_value]).decode('cp437')
        except UnicodeDecodeError:
            return '\uFFFD'  # Replacement character


def get_control_char_glyph(byte_value: int) -> str:
    """
    Return a displayable glyph for control characters (0x00-0x1F).
    
    Args:
        byte_value: Byte value (0-31)
    
    Returns:
        Displayable glyph character
    """
    if 0 <= byte_value < len(CONTROL_CHAR_GLYPHS):
        return CONTROL_CHAR_GLYPHS[byte_value]
    return '·'


def get_char_name(byte_value: int, codepage_number: int) -> str:
    """
    Return the official Unicode character name for a byte value.
    
    Args:
        byte_value: Byte value (0-255)
        codepage_number: DOS codepage number
    
    Returns:
        Character name string
    """
    # Control characters
    if byte_value < 0x20:
        return CONTROL_CHAR_NAMES[byte_value]
    
    # Space
    if byte_value == 0x20:
        return "SPACE"
    
    # DEL
    if byte_value == 0x7F:
        return "DELETE"
    
    # Get Unicode character
    char = codepage_byte_to_unicode(byte_value, codepage_number)
    
    try:
        name = unicodedata.name(char)
        return name
    except ValueError:
        # No name available
        if byte_value < 0x80:
            return f"ASCII {byte_value:#04x}"
        return f"UNDEFINED ({byte_value:#04x})"


def _glyph_to_html_entity(glyph: str) -> str:
    """
    Convert a glyph character to an HTML entity for safe rendering.
    
    Args:
        glyph: Single character glyph
    
    Returns:
        HTML entity string (numeric or named)
    """
    # Map common control character glyphs to HTML entities
    entity_map = {
        '␀': '&#9216;',  # NULL symbol
        '☺': '&#9786;',  # WHITE SMILING FACE
        '☻': '&#9787;',  # BLACK SMILING FACE
        '♥': '&hearts;',  # BLACK HEART SUIT
        '♦': '&diams;',  # BLACK DIAMOND SUIT
        '♣': '&clubs;',  # BLACK CLUB SUIT
        '♠': '&spades;',  # BLACK SPADE SUIT
        '•': '&bull;',  # BULLET
        '◘': '&#9688;',  # INVERSE BULLET
        '○': '&#9675;',  # WHITE CIRCLE
        '◙': '&#9689;',  # INVERSE WHITE CIRCLE
        '♂': '&#9794;',  # MALE SIGN
        '♀': '&#9792;',  # FEMALE SIGN
        '♪': '&#9834;',  # EIGHTH NOTE
        '♫': '&#9835;',  # BEAMED EIGHTH NOTES
        '☼': '&#9788;',  # WHITE SUN WITH RAYS
        '►': '&#9658;',  # BLACK RIGHT-POINTING POINTER
        '◄': '&#9668;',  # BLACK LEFT-POINTING POINTER
        '↕': '&#8597;',  # UP DOWN ARROW
        '‼': '&#8252;',  # DOUBLE EXCLAMATION MARK
        '¶': '&para;',  # PILCROW SIGN
        '§': '&sect;',  # SECTION SIGN
        '▬': '&#9644;',  # BLACK RECTANGLE
        '↨': '&#8616;',  # UP DOWN ARROW WITH BASE
        '↑': '&uarr;',  # UPWARDS ARROW
        '↓': '&darr;',  # DOWNWARDS ARROW
        '→': '&rarr;',  # RIGHTWARDS ARROW
        '←': '&larr;',  # LEFTWARDS ARROW
        '∟': '&#8735;',  # RIGHT ANGLE
        '↔': '&harr;',  # LEFT RIGHT ARROW
        '▲': '&#9650;',  # BLACK UP-POINTING TRIANGLE
        '▼': '&#9660;',  # BLACK DOWN-POINTING TRIANGLE
        '␡': '&#9249;',  # DELETE symbol
    }
    return entity_map.get(glyph, html.escape(glyph))


def _char_to_html_entity(char: str) -> str:
    """
    Convert a character to an HTML entity for safe rendering.
    
    Uses numeric HTML entities for non-ASCII characters.
    
    Args:
        char: Single character
    
    Returns:
        HTML entity string or escaped character
    """
    if not char:
        return ''
    
    code_point = ord(char)
    
    # ASCII printable characters (except special HTML chars) can be used directly
    if 0x20 <= code_point < 0x7F and char not in '<>&"\'':
        return char
    
    # Use HTML escaping for special HTML characters
    if char in '<>&"\'':
        return html.escape(char)
    
    # Use numeric entities for everything else
    return f'&#{code_point};'


def generate_html_file(entry: CountryEntry, output_dir: str) -> Tuple[int, str, int, str]:
    """
    Generate an HTML file for a country/codepage entry.
    
    Args:
        entry: CountryEntry object with parsed data
        output_dir: Directory to write HTML file to
    
    Returns:
        Tuple of (country_code, country_name, codepage, filename) for index generation
    """
    country_code = entry.country
    codepage = entry.codepage
    
    # Get ISO code for filename
    iso_code = _country_iso_code(country_code)
    country_name = _country_name(country_code)
    codepage_name_str = _codepage_name(codepage)
    
    # Generate filename: AA###-###.html
    filename = f"{iso_code}{country_code:03d}-{codepage:03d}.html"
    filepath = os.path.join(output_dir, filename)
    
    # Extract subfunction data
    ctyinfo_data = None
    ucase_payload = None
    collate_payload = None
    yesno_data = None
    
    for sf in entry.subfuncs:
        if sf.subfunc_id == 1 and sf.decoded:
            ctyinfo_data = sf.decoded
        elif sf.subfunc_id == 2 and sf.tagged:
            ucase_payload = sf.tagged.payload
        elif sf.subfunc_id == 6 and sf.tagged:
            collate_payload = sf.tagged.payload
        elif sf.subfunc_id == 35 and sf.decoded:
            yesno_data = sf.decoded
    
    # Build HTML content
    html_content = _build_html(
        country_code=country_code,
        country_name=country_name,
        iso_code=iso_code,
        codepage=codepage,
        codepage_name=codepage_name_str,
        ctyinfo=ctyinfo_data,
        ucase_payload=ucase_payload,
        collate_payload=collate_payload,
        yesno=yesno_data
    )
    
    # Write file
    with open(filepath, 'w', encoding='utf-8') as f:
        f.write(html_content)
    
    return (country_code, country_name, codepage, filename)


def _build_html(country_code: int, country_name: str, iso_code: str,
                codepage: int, codepage_name: str,
                ctyinfo: Optional[Dict[str, Any]],
                ucase_payload: Optional[bytes],
                collate_payload: Optional[bytes],
                yesno: Optional[Dict[str, Any]]) -> str:
    """
    Build the complete HTML document content.
    """
    title = f"{country_name} (CP{codepage})"
    
    # CSS styles
    css = '''
:root {
    --bg-color: #f8f9fa;
    --text-color: #212529;
    --heading-color: #495057;
    --table-border: #dee2e6;
    --table-header-bg: #e9ecef;
    --table-hover: #f1f3f5;
    --code-bg: #e9ecef;
    --link-color: #0d6efd;
    --control-char-color: #6c757d;
    --glyph-color: #212529;
}

[data-theme="dark"] {
    --bg-color: #1a1a2e;
    --text-color: #e9ecef;
    --heading-color: #adb5bd;
    --table-border: #495057;
    --table-header-bg: #343a40;
    --table-hover: #2d2d44;
    --code-bg: #343a40;
    --link-color: #6ea8fe;
    --control-char-color: #adb5bd;
    --glyph-color: #f8f9fa;
}

* {
    box-sizing: border-box;
}

body {
    font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 'Helvetica Neue', Arial, sans-serif;
    background-color: var(--bg-color);
    color: var(--text-color);
    line-height: 1.6;
    margin: 0;
    padding: 20px;
    max-width: 1400px;
    margin: 0 auto;
}

h1, h2, h3 {
    color: var(--heading-color);
    margin-top: 1.5em;
    margin-bottom: 0.5em;
}

h1 {
    border-bottom: 2px solid var(--table-border);
    padding-bottom: 10px;
}

.theme-toggle {
    position: fixed;
    top: 20px;
    right: 20px;
    padding: 8px 16px;
    background: var(--table-header-bg);
    border: 1px solid var(--table-border);
    border-radius: 4px;
    cursor: pointer;
    color: var(--text-color);
    font-size: 14px;
}

.theme-toggle:hover {
    background: var(--table-hover);
}

.summary-table {
    border-collapse: collapse;
    margin: 1em 0;
    background: var(--bg-color);
}

.summary-table th,
.summary-table td {
    border: 1px solid var(--table-border);
    padding: 8px 12px;
    text-align: left;
}

.summary-table th {
    background: var(--table-header-bg);
    font-weight: 600;
    white-space: nowrap;
}

.summary-table td {
    font-family: 'unscii', 'Uni VGA', 'Perfect DOS VGA 437', 'Consolas', 'Courier New', monospace;
}

.codepage-grid {
    border-collapse: collapse;
    margin: 1em 0;
    font-family: 'unscii', 'Uni VGA', 'Perfect DOS VGA 437', 'Consolas', 'Courier New', monospace;
    font-size: 14px;
}

.codepage-grid th,
.codepage-grid td {
    border: 1px solid var(--table-border);
    padding: 4px 8px;
    text-align: center;
}

.codepage-grid th {
    background: var(--table-header-bg);
    font-weight: 600;
}

.codepage-grid tr:hover td {
    background: var(--table-hover);
}

.codepage-grid .glyph {
    font-size: 18px;
    color: var(--glyph-color);
    min-width: 24px;
    display: inline-block;
}

.codepage-grid .control-char {
    color: var(--control-char-color);
    font-size: 16px;
}

.codepage-grid .char-name {
    font-size: 11px;
    color: var(--control-char-color);
    max-width: 150px;
    overflow: hidden;
    text-overflow: ellipsis;
    white-space: nowrap;
}

.char-table {
    border-collapse: collapse;
    margin: 1em 0;
    font-family: 'unscii', 'Uni VGA', 'Perfect DOS VGA 437', 'Consolas', 'Courier New', monospace;
}

.char-table th,
.char-table td {
    border: 1px solid var(--table-border);
    padding: 6px 10px;
    text-align: center;
}

.char-table th {
    background: var(--table-header-bg);
    font-weight: 600;
}

.char-table tr:hover td {
    background: var(--table-hover);
}

.ucase-table .arrow {
    color: var(--control-char-color);
    padding: 0 8px;
}

.section {
    margin: 2em 0;
    padding: 1em;
    background: var(--bg-color);
    border: 1px solid var(--table-border);
    border-radius: 8px;
}

.grid-16x16 {
    display: grid;
    grid-template-columns: auto repeat(16, 1fr);
    gap: 1px;
    background: var(--table-border);
    border: 1px solid var(--table-border);
    font-family: 'unscii', 'Uni VGA', 'Perfect DOS VGA 437', 'Consolas', 'Courier New', monospace;
    font-size: 13px;
    margin: 1em 0;
}

.grid-16x16 > div {
    background: var(--bg-color);
    padding: 4px;
    text-align: center;
    min-width: 40px;
}

.grid-16x16 .header {
    background: var(--table-header-bg);
    font-weight: 600;
}

.grid-16x16 .glyph {
    font-size: 16px;
    color: var(--glyph-color);
}

.grid-16x16 .control-char {
    color: var(--control-char-color);
}

.grid-16x16 .row-header {
    background: var(--table-header-bg);
    font-weight: 600;
}

footer {
    margin-top: 3em;
    padding-top: 1em;
    border-top: 1px solid var(--table-border);
    color: var(--control-char-color);
    font-size: 12px;
}
'''

    # JavaScript for theme toggle
    js = '''
function toggleTheme() {
    const html = document.documentElement;
    const currentTheme = html.getAttribute('data-theme');
    const newTheme = currentTheme === 'dark' ? 'light' : 'dark';
    html.setAttribute('data-theme', newTheme);
    localStorage.setItem('theme', newTheme);
    updateToggleButton(newTheme);
}

function updateToggleButton(theme) {
    const btn = document.getElementById('theme-toggle');
    btn.textContent = theme === 'dark' ? '☀️ Light Mode' : '🌙 Dark Mode';
}

document.addEventListener('DOMContentLoaded', function() {
    const savedTheme = localStorage.getItem('theme') || 'light';
    document.documentElement.setAttribute('data-theme', savedTheme);
    updateToggleButton(savedTheme);
});
'''

    # Build HTML
    parts = [f'''<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>{html.escape(title)} - DOS Codepage Reference</title>
    <style>{css}</style>
</head>
<body>
    <button id="theme-toggle" class="theme-toggle" onclick="toggleTheme()">🌙 Dark Mode</button>
    
    <h1>{html.escape(title)}</h1>
    <p>DOS Country Code: {country_code} ({iso_code}) | Codepage: {codepage} ({html.escape(codepage_name)})</p>
''']

    # Summary section
    parts.append('<div class="section">')
    parts.append('<h2>Country Information (CTYINFO)</h2>')
    
    if ctyinfo:
        parts.append('<table class="summary-table">')
        parts.append('<tr><th>Property</th><th>Value</th></tr>')
        
        info_fields = [
            ('Country ID', ctyinfo.get('country_id', 'N/A')),
            ('Codepage', ctyinfo.get('codepage', 'N/A')),
            ('Date Format', f"{ctyinfo.get('date_format', 'N/A')} ({ctyinfo.get('date_format_name', '')})"),
            ('Time Format', f"{ctyinfo.get('time_format', 'N/A')} ({ctyinfo.get('time_format_name', '')})"),
            ('Currency Symbol', ctyinfo.get('currency_symbol', 'N/A')),
            ('Currency Format', ctyinfo.get('currency_format', 'N/A')),
            ('Currency Decimals', ctyinfo.get('currency_decimals', 'N/A')),
            ('Thousands Separator', ctyinfo.get('thousands_sep', 'N/A')),
            ('Decimal Separator', ctyinfo.get('decimal_sep', 'N/A')),
            ('Date Separator', ctyinfo.get('date_sep', 'N/A')),
            ('Time Separator', ctyinfo.get('time_sep', 'N/A')),
            ('Data Separator', ctyinfo.get('data_sep', 'N/A')),
        ]
        
        for label, value in info_fields:
            parts.append(f'<tr><th>{html.escape(label)}</th><td>{html.escape(str(value))}</td></tr>')
        
        parts.append('</table>')
    else:
        parts.append('<p><em>No CTYINFO data available</em></p>')
    
    # YESNO
    if yesno:
        parts.append('<h3>Yes/No Characters (YESNO)</h3>')
        parts.append('<table class="summary-table">')
        parts.append(f'<tr><th>Yes</th><td>{html.escape(yesno.get("yes", "N/A"))}</td></tr>')
        parts.append(f'<tr><th>No</th><td>{html.escape(yesno.get("no", "N/A"))}</td></tr>')
        parts.append('</table>')
    
    parts.append('</div>')

    # Codepage table in codepoint order (16x16 grid)
    parts.append('<div class="section">')
    parts.append('<h2>Codepage Character Map (Codepoint Order)</h2>')
    parts.append('<p>16×16 grid showing all 256 byte values (0x00-0xFF)</p>')
    
    parts.append('<div class="grid-16x16">')
    # Header row
    parts.append('<div class="header"></div>')
    for col in range(16):
        parts.append(f'<div class="header">_{col:X}</div>')
    
    # Data rows
    for row in range(16):
        parts.append(f'<div class="row-header">{row:X}_</div>')
        for col in range(16):
            byte_val = row * 16 + col
            char_name = get_char_name(byte_val, codepage)
            tooltip = f"Dec: {byte_val}, Hex: 0x{byte_val:02X}, Name: {char_name}"
            if byte_val < 0x20:
                glyph = get_control_char_glyph(byte_val)
                glyph_html = _glyph_to_html_entity(glyph)
                parts.append(f'<div class="control-char" title="{html.escape(tooltip)}">{glyph_html}</div>')
            elif byte_val == 0x7F:
                parts.append(f'<div class="control-char" title="{html.escape(tooltip)}">&#9249;</div>')
            else:
                char = codepage_byte_to_unicode(byte_val, codepage)
                char_html = _char_to_html_entity(char)
                parts.append(f'<div class="glyph" title="{html.escape(tooltip)}">{char_html}</div>')
    
    parts.append('</div>')
    parts.append('</div>')

    # Collation order table
    if collate_payload and len(collate_payload) == 256:
        parts.append('<div class="section">')
        parts.append('<h2>Codepage in Collation Order</h2>')
        parts.append('<p>Characters sorted by their collation weight (sort order)</p>')
        
        # Build list of (byte_value, collation_weight)
        collation_order = [(i, collate_payload[i]) for i in range(256)]
        # Sort by collation weight, then by byte value for stability
        collation_order.sort(key=lambda x: (x[1], x[0]))
        
        parts.append('<table class="codepage-grid">')
        parts.append('<tr><th>Weight</th><th>Dec</th><th>Hex</th><th>Glyph</th><th>Character Name</th></tr>')
        
        for byte_val, weight in collation_order:
            if byte_val < 0x20:
                glyph = get_control_char_glyph(byte_val)
                glyph_html = _glyph_to_html_entity(glyph)
                glyph_class = 'control-char'
            elif byte_val == 0x7F:
                glyph_html = '&#9249;'
                glyph_class = 'control-char'
            else:
                glyph = codepage_byte_to_unicode(byte_val, codepage)
                glyph_html = _char_to_html_entity(glyph)
                glyph_class = 'glyph'
            
            char_name = get_char_name(byte_val, codepage)
            parts.append(f'<tr><td>{weight}</td><td>{byte_val}</td><td>{byte_val:02X}</td>'
                        f'<td class="{glyph_class}">{glyph_html}</td>'
                        f'<td class="char-name">{html.escape(char_name)}</td></tr>')
        
        parts.append('</table>')
        parts.append('</div>')

    # UCASE mappings table
    if ucase_payload and len(ucase_payload) >= 128:
        parts.append('<div class="section">')
        parts.append('<h2>Uppercase Mappings (UCASE)</h2>')
        parts.append('<p>Maps characters 0x80-0xFF to their uppercase equivalents</p>')
        
        parts.append('<table class="char-table ucase-table">')
        parts.append('<tr><th>From (Dec)</th><th>From (Hex)</th><th>Lowercase</th>'
                    '<th></th><th>Uppercase</th><th>To (Hex)</th><th>To (Dec)</th></tr>')
        
        for i, upper_byte in enumerate(ucase_payload[:128]):
            lower_byte = 0x80 + i
            lower_char = codepage_byte_to_unicode(lower_byte, codepage)
            upper_char = codepage_byte_to_unicode(upper_byte, codepage)
            
            # Only show if there's a mapping change
            if lower_byte != upper_byte:
                lower_html = _char_to_html_entity(lower_char)
                upper_html = _char_to_html_entity(upper_char)
                parts.append(f'<tr>'
                            f'<td>{lower_byte}</td>'
                            f'<td>{lower_byte:02X}</td>'
                            f'<td class="glyph">{lower_html}</td>'
                            f'<td class="arrow">&rarr;</td>'
                            f'<td class="glyph">{upper_html}</td>'
                            f'<td>{upper_byte:02X}</td>'
                            f'<td>{upper_byte}</td>'
                            f'</tr>')
        
        parts.append('</table>')
        parts.append('</div>')

    # Footer
    parts.append(f'''
    <footer>
        <p>Generated by countrydump.py - DOS COUNTRY.SYS Parser</p>
        <p>Country: {country_code} ({html.escape(country_name)}) | Codepage: {codepage} ({html.escape(codepage_name)})</p>
    </footer>
    
    <script>{js}</script>
</body>
</html>
''')

    return ''.join(parts)


def generate_index_html(entries: List[Tuple[int, str, int, str]], output_dir: str) -> str:
    """
    Generate an index.html file listing all country/codepage HTML files.
    
    Args:
        entries: List of (country_num, country_name, codepage, filename) tuples
        output_dir: Directory to write index.html to
    
    Returns:
        Path to the generated index.html file
    """
    # Sort entries by country number
    sorted_entries = sorted(entries, key=lambda x: (x[0], x[2]))
    
    # CSS styles (same as individual pages)
    css = '''
:root {
    --bg-color: #f8f9fa;
    --text-color: #212529;
    --heading-color: #495057;
    --table-border: #dee2e6;
    --table-header-bg: #e9ecef;
    --table-hover: #f1f3f5;
    --link-color: #0d6efd;
}

[data-theme="dark"] {
    --bg-color: #1a1a2e;
    --text-color: #e9ecef;
    --heading-color: #adb5bd;
    --table-border: #495057;
    --table-header-bg: #343a40;
    --table-hover: #2d2d44;
    --link-color: #6ea8fe;
}

* {
    box-sizing: border-box;
}

body {
    font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 'Helvetica Neue', Arial, sans-serif;
    background-color: var(--bg-color);
    color: var(--text-color);
    line-height: 1.6;
    margin: 0;
    padding: 20px;
    max-width: 1200px;
    margin: 0 auto;
}

h1 {
    color: var(--heading-color);
    border-bottom: 2px solid var(--table-border);
    padding-bottom: 10px;
}

.theme-toggle {
    position: fixed;
    top: 20px;
    right: 20px;
    padding: 8px 16px;
    background: var(--table-header-bg);
    border: 1px solid var(--table-border);
    border-radius: 4px;
    cursor: pointer;
    color: var(--text-color);
    font-size: 14px;
}

.theme-toggle:hover {
    background: var(--table-hover);
}

table {
    border-collapse: collapse;
    width: 100%;
    margin: 1em 0;
    background: var(--bg-color);
}

th, td {
    border: 1px solid var(--table-border);
    padding: 10px 15px;
    text-align: left;
}

th {
    background: var(--table-header-bg);
    font-weight: 600;
}

tr:hover td {
    background: var(--table-hover);
}

a {
    color: var(--link-color);
    text-decoration: none;
}

a:hover {
    text-decoration: underline;
}

footer {
    margin-top: 3em;
    padding-top: 1em;
    border-top: 1px solid var(--table-border);
    color: var(--heading-color);
    font-size: 12px;
}
'''

    # JavaScript for theme toggle
    js = '''
function toggleTheme() {
    const html = document.documentElement;
    const currentTheme = html.getAttribute('data-theme');
    const newTheme = currentTheme === 'dark' ? 'light' : 'dark';
    html.setAttribute('data-theme', newTheme);
    localStorage.setItem('theme', newTheme);
    updateToggleButton(newTheme);
}

function updateToggleButton(theme) {
    const btn = document.getElementById('theme-toggle');
    btn.textContent = theme === 'dark' ? '☀️ Light Mode' : '🌙 Dark Mode';
}

document.addEventListener('DOMContentLoaded', function() {
    const savedTheme = localStorage.getItem('theme') || 'light';
    document.documentElement.setAttribute('data-theme', savedTheme);
    updateToggleButton(savedTheme);
});
'''

    # Build HTML
    parts = [f'''<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>DOS Codepage Reference - Index</title>
    <style>{css}</style>
</head>
<body>
    <button id="theme-toggle" class="theme-toggle" onclick="toggleTheme()">🌙 Dark Mode</button>
    
    <h1>DOS Codepage Reference</h1>
    <p>Country and codepage information extracted from COUNTRY.SYS</p>
    
    <table>
        <tr>
            <th>Country Number</th>
            <th>Country Name</th>
            <th>Codepage</th>
            <th>Link</th>
        </tr>
''']

    for country_num, country_name, cp, filename in sorted_entries:
        parts.append(f'''        <tr>
            <td>{country_num}</td>
            <td>{html.escape(country_name)}</td>
            <td>{cp}</td>
            <td><a href="{html.escape(filename)}">{html.escape(filename)}</a></td>
        </tr>
''')

    parts.append(f'''    </table>
    
    <footer>
        <p>Generated by countrydump.py - DOS COUNTRY.SYS Parser</p>
        <p>Total entries: {len(sorted_entries)}</p>
    </footer>
    
    <script>{js}</script>
</body>
</html>
''')

    filepath = os.path.join(output_dir, 'index.html')
    with open(filepath, 'w', encoding='utf-8') as f:
        f.write(''.join(parts))
    
    return filepath


def generate_html_files(doc: ParsedCountrySys, output_dir: str,
                       country: Optional[int], codepage: Optional[int]) -> List[str]:
    """
    Generate HTML files for all (filtered) country/codepage entries.
    
    Args:
        doc: Parsed COUNTRY.SYS data
        output_dir: Directory to write HTML files to
        country: Filter by country code (None = no filter)
        codepage: Filter by codepage (None = no filter)
    
    Returns:
        List of generated file paths
    """
    # Ensure output directory exists
    os.makedirs(output_dir, exist_ok=True)
    
    entries = filter_entries(doc.entries, country, codepage)
    generated_files = []
    index_entries = []
    
    for entry in entries:
        entry_info = generate_html_file(entry, output_dir)
        country_num, country_name, cp, filename = entry_info
        filepath = os.path.join(output_dir, filename)
        generated_files.append(filepath)
        index_entries.append(entry_info)
        print(f"Generated: {filepath}")
    
    # Generate index.html
    if index_entries:
        index_path = generate_index_html(index_entries, output_dir)
        generated_files.append(index_path)
        print(f"Generated: {index_path}")
    
    return generated_files


# ====
# CLI
# ====

def main(argv: Optional[List[str]] = None) -> int:
    """
    Main entry point for command-line interface.

    Args:
        argv: Command-line arguments (None = use sys.argv)

    Returns:
        Exit code (0 = success, 1 = error)
    """
    ap = argparse.ArgumentParser(
        description="Parse and compare DOS COUNTRY.SYS files (MS-DOS family format).",
        epilog="By default, entries and subfunctions are sorted for consistent output. "
               "Use --unsorted to preserve original file order. "
               "Use --compare to diff two COUNTRY.SYS files. "
               "Use --html to generate HTML output files."
    )
    ap.add_argument("file", nargs='?', help="Path to COUNTRY.SYS (for single-file display)")
    ap.add_argument("--compare", nargs=2, metavar=("FILE1", "FILE2"),
                    help="Compare two COUNTRY.SYS files")
    ap.add_argument("--summary", action="store_true", help="Print a concise entry list")
    ap.add_argument("--json", action="store_true", help="Emit JSON")
    ap.add_argument("--html", action="store_true", help="Generate HTML output files")
    ap.add_argument("--output-dir", default=".", metavar="DIR",
                    help="Output directory for HTML files (default: current directory)")
    ap.add_argument("--unsorted", action="store_true",
                    help="Preserve original file order (default: sort by country/codepage and subfunction ID)")
    ap.add_argument("--no-offsets", action="store_true", help="Suppress offsets in output")
    ap.add_argument("--strict", action="store_true", help="Treat validation issues as fatal where possible")
    ap.add_argument("--country", type=int, help="Filter by country code")
    ap.add_argument("--codepage", type=int, help="Filter by codepage")
    args = ap.parse_args(argv)

    # Determine mode: compare or single-file display
    if args.compare:
        # Compare mode
        file_a, file_b = args.compare
        
        # Validate both files
        for fpath in [file_a, file_b]:
            path = Path(fpath)
            if not path.exists():
                print(f"Error: File not found: {fpath}", file=sys.stderr)
                return 1
            if not path.is_file():
                print(f"Error: Not a regular file: {fpath}", file=sys.stderr)
                return 1
            if path.stat().st_size == 0:
                print(f"Error: File is empty: {fpath}", file=sys.stderr)
                return 1
        
        # Parse both files
        try:
            with open(file_a, "rb") as f:
                buf_a = f.read()
            doc_a = parse_country_sys(buf_a, strict=args.strict)
            
            with open(file_b, "rb") as f:
                buf_b = f.read()
            doc_b = parse_country_sys(buf_b, strict=args.strict)
        except (OSError, ValidationError) as e:
            print(f"Error: {e}", file=sys.stderr)
            return 1
        
        # Compare and output
        compare_country_sys(doc_a, doc_b, file_a, file_b, args.country, args.codepage)
        return 0
    
    else:
        # Single-file display mode
        if not args.file:
            ap.error("the following arguments are required: file (or use --compare FILE1 FILE2)")
        
        # Input validation: check file exists, is a regular file, and is not empty
        file_path = Path(args.file)
        if not file_path.exists():
            print(f"Error: File not found: {args.file}", file=sys.stderr)
            return 1
        if not file_path.is_file():
            print(f"Error: Not a regular file: {args.file}", file=sys.stderr)
            return 1
        if file_path.stat().st_size == 0:
            print(f"Error: File is empty: {args.file}", file=sys.stderr)
            return 1

        # Read and parse file
        try:
            with open(file_path, "rb") as f:
                buf = f.read()
            doc = parse_country_sys(buf, strict=args.strict)
        except (OSError, ValidationError) as e:
            print(f"Error: {e}", file=sys.stderr)
            return 1

        # HTML output mode
        if args.html:
            generated = generate_html_files(doc, args.output_dir, args.country, args.codepage)
            print(f"\nGenerated {len(generated)} HTML file(s) in {args.output_dir}")
            return 0

        # Output in requested format
        if args.json:
            print(json.dumps(to_jsonable(doc), indent=2))
            return 0

        if args.summary:
            print_summary(doc, unsorted=args.unsorted, no_offsets=args.no_offsets,
                          country=args.country, codepage=args.codepage)
        else:
            print_default(doc, unsorted=args.unsorted, no_offsets=args.no_offsets,
                          country=args.country, codepage=args.codepage)

        # Copyright / Version detection and display
        copyright_info = find_copyright_and_version(buf)
        if copyright_info:
            print("\n# ====")
            print("# End of file string (copyright/version data)")
            print("#")
            print(f"# COPYRIGHT: {copyright_info['copyright']}")
            if "version" in copyright_info:
                print(f"# VERSION: {copyright_info['version']}")

        return 0


if __name__ == "__main__":
    raise SystemExit(main())
