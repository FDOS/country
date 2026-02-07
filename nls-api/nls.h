/*============================================================================
 * nls.h - DOS National Language Support (NLS) Library Header
 *============================================================================
 * Provides C interface to DOS NLS API functions:
 *   - INT 21h AH=38h - Get/Set Country Dependent Information
 *   - INT 21h AH=65h - Get Extended Country Information (DOS 3.3+)
 *   - INT 21h AH=66h - Get/Set Global Code Page (DOS 3.3+)
 *   - INT 21h AH=59h - Get Extended Error Information (DOS 3.0+)
 *
 * All functions return 0 on success, nonzero DOS error code on failure.
 * Memory for structures is allocated/freed by caller.
 *
 * Compiler Support: Watcom, Borland, GCC-ia16, Microsoft C, Digital Mars
 * Memory Models: Tiny, Small, Compact, Medium, Large, Huge
 *
 * Author: DOS NLS Library
 * License: Public Domain
 *============================================================================*/

#ifndef NLS_H
#define NLS_H

#ifdef __cplusplus
extern "C" {
#endif

/*----------------------------------------------------------------------------
 * Compiler-specific far pointer support
 *----------------------------------------------------------------------------*/
#if defined(__WATCOMC__)
    #define NLS_FAR __far
    #define NLS_CDECL __cdecl
#elif defined(__TURBOC__) || defined(__BORLANDC__)
    #define NLS_FAR far
    #define NLS_CDECL cdecl
#elif defined(_MSC_VER)
    #define NLS_FAR __far
    #define NLS_CDECL __cdecl
#elif defined(__DMC__)
    #define NLS_FAR __far
    #define NLS_CDECL __cdecl
#elif defined(__GNUC__)
    /* GCC-ia16 uses __far for far pointers */
    #define NLS_FAR __far
    #define NLS_CDECL __attribute__((cdecl))
#else
    /* Default: assume near model */
    #define NLS_FAR
    #define NLS_CDECL
#endif

/*----------------------------------------------------------------------------
 * Basic Types
 *----------------------------------------------------------------------------*/
typedef unsigned char  nls_byte;
typedef unsigned short nls_word;
typedef unsigned long  nls_dword;

/*============================================================================
 * Date Format Constants (returned in NLS_COUNTRY_INFO.date_format)
 *============================================================================*/
#define NLS_DATE_USA      0   /* mm/dd/yy - Month, Day, Year */
#define NLS_DATE_EUROPE   1   /* dd/mm/yy - Day, Month, Year */
#define NLS_DATE_JAPAN    2   /* yy/mm/dd - Year, Month, Day */

/*============================================================================
 * Currency Format Bitfield (NLS_COUNTRY_INFO.currency_format)
 *============================================================================
 * Bit 0: Currency symbol position
 *        0 = Currency symbol precedes value ($1.23)
 *        1 = Currency symbol follows value (1.23$)
 * Bit 1: Space between currency symbol and value
 *        0 = No space ($1.23)
 *        1 = Space ($ 1.23)
 * Bit 2: Currency symbol replaces decimal point
 *        0 = No (1.23$)
 *        1 = Yes (1$23)
 *============================================================================*/
#define NLS_CURR_PRECEDES    0x00  /* Currency precedes value */
#define NLS_CURR_FOLLOWS     0x01  /* Currency follows value */
#define NLS_CURR_SPACE       0x02  /* Space between currency and value */
#define NLS_CURR_DECIMAL     0x04  /* Currency replaces decimal point */

/*============================================================================
 * Time Format (NLS_COUNTRY_INFO.time_format)
 *============================================================================
 * Bit 0: Time format
 *        0 = 12-hour clock
 *        1 = 24-hour clock
 *============================================================================*/
#define NLS_TIME_12HR        0x00  /* 12-hour clock format */
#define NLS_TIME_24HR        0x01  /* 24-hour clock format */

/*============================================================================
 * Extended Country Information Subfunctions (INT 21h AH=65h AL value)
 *============================================================================*/
#define NLS_INFO_GENERAL         0x01  /* General internationalization info */
#define NLS_INFO_UPPERCASE       0x02  /* Pointer to uppercase table */
#define NLS_INFO_LOWERCASE       0x03  /* Pointer to lowercase table (DOS 6.2+) */
#define NLS_INFO_FILENAME_UPPER  0x04  /* Pointer to filename uppercase table */
#define NLS_INFO_FILENAME_TERM   0x05  /* Pointer to filename terminator table */
#define NLS_INFO_COLLATING       0x06  /* Pointer to collating sequence table */
#define NLS_INFO_DBCS            0x07  /* Pointer to DBCS lead byte table (DOS 4+) */
#define NLS_INFO_YESNO           0x23  /* Determine yes/no character (DOS 4.0+) */

/*============================================================================
 * Special Country/Code Page Values
 *============================================================================*/
#define NLS_COUNTRY_CURRENT   0x0000  /* Use current country (GET only) */
#define NLS_COUNTRY_DEFAULT   0xFFFF  /* Use default country */
#define NLS_CODEPAGE_GLOBAL   0xFFFF  /* Use global/active code page */

/*============================================================================
 * Common Country Codes (from INT 21h AH=38h documentation)
 *============================================================================*/
#define NLS_COUNTRY_USA           1    /* United States */
#define NLS_COUNTRY_CANADA_FR     2    /* Canadian French */
#define NLS_COUNTRY_LATIN_AMER    3    /* Latin America */
#define NLS_COUNTRY_CANADA_EN     4    /* Canada (English) */
#define NLS_COUNTRY_RUSSIA        7    /* Russia */
#define NLS_COUNTRY_NETHERLANDS  31    /* Netherlands */
#define NLS_COUNTRY_BELGIUM      32    /* Belgium */
#define NLS_COUNTRY_FRANCE       33    /* France */
#define NLS_COUNTRY_SPAIN        34    /* Spain */
#define NLS_COUNTRY_HUNGARY      36    /* Hungary */
#define NLS_COUNTRY_ITALY        39    /* Italy */
#define NLS_COUNTRY_SWITZERLAND  41    /* Switzerland */
#define NLS_COUNTRY_UK           44    /* United Kingdom */
#define NLS_COUNTRY_DENMARK      45    /* Denmark */
#define NLS_COUNTRY_SWEDEN       46    /* Sweden */
#define NLS_COUNTRY_NORWAY       47    /* Norway */
#define NLS_COUNTRY_POLAND       48    /* Poland */
#define NLS_COUNTRY_GERMANY      49    /* Germany */
#define NLS_COUNTRY_BRAZIL       55    /* Brazil */
#define NLS_COUNTRY_AUSTRALIA    61    /* International English / Australia */
#define NLS_COUNTRY_JAPAN        81    /* Japan */
#define NLS_COUNTRY_KOREA        82    /* South Korea */
#define NLS_COUNTRY_CHINA        86    /* China */
#define NLS_COUNTRY_TAIWAN       88    /* Taiwan */
#define NLS_COUNTRY_TURKEY       90    /* Turkey */
#define NLS_COUNTRY_PORTUGAL    351   /* Portugal */
#define NLS_COUNTRY_FINLAND     358   /* Finland */

/*============================================================================
 * Common Code Page Values
 *============================================================================*/
#define NLS_CP_437    437    /* US English (OEM) */
#define NLS_CP_850    850    /* Multilingual Latin I */
#define NLS_CP_852    852    /* Central European (Latin II) */
#define NLS_CP_855    855    /* Cyrillic I */
#define NLS_CP_857    857    /* Turkish */
#define NLS_CP_860    860    /* Portuguese */
#define NLS_CP_861    861    /* Icelandic */
#define NLS_CP_862    862    /* Hebrew */
#define NLS_CP_863    863    /* Canadian French */
#define NLS_CP_864    864    /* Arabic */
#define NLS_CP_865    865    /* Nordic */
#define NLS_CP_866    866    /* Cyrillic II (Russian) */
#define NLS_CP_869    869    /* Greek */
#define NLS_CP_932    932    /* Japanese Shift-JIS */
#define NLS_CP_936    936    /* Simplified Chinese GBK */
#define NLS_CP_949    949    /* Korean */
#define NLS_CP_950    950    /* Traditional Chinese Big5 */

/*============================================================================
 * Error Class Values (from INT 21h AH=59h BH)
 *============================================================================*/
#define NLS_ERRCLASS_OUTOFRES    0x01  /* Out of resource (space, channels) */
#define NLS_ERRCLASS_TEMPFAIL    0x02  /* Temporary situation (not error) */
#define NLS_ERRCLASS_AUTH        0x03  /* Authorization/permission denied */
#define NLS_ERRCLASS_INTERNAL    0x04  /* Internal/system error */
#define NLS_ERRCLASS_HARDWARE    0x05  /* Hardware failure */
#define NLS_ERRCLASS_SYSTEM      0x06  /* System failure (bad config) */
#define NLS_ERRCLASS_APP         0x07  /* Application error */
#define NLS_ERRCLASS_NOTFOUND    0x08  /* Not found */
#define NLS_ERRCLASS_BADFMT      0x09  /* Bad format */
#define NLS_ERRCLASS_LOCKED      0x0A  /* Locked */
#define NLS_ERRCLASS_MEDIA       0x0B  /* Media failure */
#define NLS_ERRCLASS_EXISTS      0x0C  /* Already exists */
#define NLS_ERRCLASS_UNKNOWN     0x0D  /* Unknown */

/*============================================================================
 * Suggested Action Values (from INT 21h AH=59h BL)
 *============================================================================*/
#define NLS_ACTION_RETRY         0x01  /* Retry */
#define NLS_ACTION_DELAY_RETRY   0x02  /* Delay and retry */
#define NLS_ACTION_REENTER       0x03  /* Re-enter input */
#define NLS_ACTION_ABORT_CLEAN   0x04  /* Abort with cleanup */
#define NLS_ACTION_ABORT_NOW     0x05  /* Immediate abort */
#define NLS_ACTION_IGNORE        0x06  /* Ignore error */
#define NLS_ACTION_USER          0x07  /* User intervention required */

/*============================================================================
 * Error Locus Values (from INT 21h AH=59h CH)
 *============================================================================*/
#define NLS_LOCUS_UNKNOWN        0x01  /* Unknown */
#define NLS_LOCUS_BLOCK          0x02  /* Block device (disk) */
#define NLS_LOCUS_NETWORK        0x03  /* Network */
#define NLS_LOCUS_SERIAL         0x04  /* Serial device */
#define NLS_LOCUS_MEMORY         0x05  /* Memory */

/*============================================================================
 * DOS Error Codes (selected common ones)
 *============================================================================*/
#define NLS_ERR_NONE             0x00  /* No error */
#define NLS_ERR_INVALID_FUNC     0x01  /* Invalid function number */
#define NLS_ERR_FILE_NOT_FOUND   0x02  /* File not found */
#define NLS_ERR_PATH_NOT_FOUND   0x03  /* Path not found */
#define NLS_ERR_TOO_MANY_FILES   0x04  /* Too many open files */
#define NLS_ERR_ACCESS_DENIED    0x05  /* Access denied */
#define NLS_ERR_INVALID_HANDLE   0x06  /* Invalid handle */

/*============================================================================
 * Yes/No Response Type Values (returned by INT 21h AX=6523h)
 *============================================================================*/
#define NLS_YESNO_NO             0x00  /* Character represents "No" response */
#define NLS_YESNO_YES            0x01  /* Character represents "Yes" response */
#define NLS_YESNO_NEITHER        0x02  /* Character is neither "Yes" nor "No" */

/*============================================================================
 * NLS_COUNTRY_INFO Structure (22 bytes)
 *============================================================================
 * Country-dependent information returned by INT 21h AH=38h (DOS 2.11+)
 * and INT 21h AX=6501h.
 *
 * Note: String fields are ASCIZ (null-terminated) but sized for 2 bytes
 * each - the second byte is always 00h.
 *============================================================================*/
#pragma pack(push, 1)
typedef struct {
    nls_word  date_format;         /* 0x00: Date format (0=USA, 1=Europe, 2=Japan) */
    char      currency_symbol[5];  /* 0x02: ASCIZ currency symbol (up to 4 chars + null) */
    char      thousands_sep[2];    /* 0x07: ASCIZ thousands separator */
    char      decimal_sep[2];      /* 0x09: ASCIZ decimal separator */
    char      date_sep[2];         /* 0x0B: ASCIZ date separator */
    char      time_sep[2];         /* 0x0D: ASCIZ time separator */
    nls_byte  currency_format;     /* 0x0F: Currency format bitfield */
    nls_byte  currency_digits;     /* 0x10: Digits after decimal in currency */
    nls_byte  time_format;         /* 0x11: Time format (bit 0: 0=12hr, 1=24hr) */
    nls_dword case_map_call;       /* 0x12: FAR pointer to case map routine */
    char      data_sep[2];         /* 0x16: ASCIZ data-list separator */
    nls_byte  reserved[10];        /* 0x18: Reserved */
} NLS_COUNTRY_INFO;                /* Total: 34 bytes (0x22) */
#pragma pack(pop)

/*============================================================================
 * NLS_EXT_COUNTRY_INFO Structure
 *============================================================================
 * Extended country information returned by INT 21h AX=6501h.
 * Includes info ID, size, country code, code page, plus country-dependent info.
 *============================================================================*/
#pragma pack(push, 1)
typedef struct {
    nls_byte  info_id;             /* 0x00: Info ID (always 01h) */
    nls_word  size;                /* 0x01: Size of following data */
    nls_word  country_id;          /* 0x03: Country ID */
    nls_word  code_page;           /* 0x05: Code page */
    NLS_COUNTRY_INFO info;         /* 0x07: Country-dependent information */
} NLS_EXT_COUNTRY_INFO;            /* Total: 41 bytes */
#pragma pack(pop)

/*============================================================================
 * NLS_UPPERCASE_TABLE Structure (130 bytes)
 *============================================================================
 * Uppercase table returned by INT 21h AX=6502h.
 * Contains uppercase equivalents for characters 80h-FFh.
 *============================================================================*/
#pragma pack(push, 1)
typedef struct {
    nls_word  size;                /* 0x00: Table size (0080h = 128) */
    nls_byte  data[128];           /* 0x02: Uppercase for chars 80h-FFh */
} NLS_UPPERCASE_TABLE;             /* Total: 130 bytes */
#pragma pack(pop)

/*============================================================================
 * NLS_LOWERCASE_TABLE Structure (258 bytes)
 *============================================================================
 * Lowercase table returned by INT 21h AX=6503h (DOS 6.2+ with COUNTRY.SYS).
 * Contains lowercase equivalents for characters 00h-FFh.
 *============================================================================*/
#pragma pack(push, 1)
typedef struct {
    nls_word  size;                /* 0x00: Table size (0100h = 256) */
    nls_byte  data[256];           /* 0x02: Lowercase for chars 00h-FFh */
} NLS_LOWERCASE_TABLE;             /* Total: 258 bytes */
#pragma pack(pop)

/*============================================================================
 * NLS_FILENAME_UPPER_TABLE Structure (130 bytes)
 *============================================================================
 * Filename uppercase table returned by INT 21h AX=6504h.
 * Contains uppercase equivalents for filename characters 80h-FFh.
 *============================================================================*/
#pragma pack(push, 1)
typedef struct {
    nls_word  size;                /* 0x00: Table size (0080h = 128) */
    nls_byte  data[128];           /* 0x02: Uppercase for filename chars 80h-FFh */
} NLS_FILENAME_UPPER_TABLE;        /* Total: 130 bytes */
#pragma pack(pop)

/*============================================================================
 * NLS_FILENAME_TERM_TABLE Structure
 *============================================================================
 * Filename terminator table returned by INT 21h AX=6505h.
 * Defines characters that are invalid in filenames.
 * Variable size based on number of terminator characters.
 *============================================================================*/
#pragma pack(push, 1)
typedef struct {
    nls_word  size;                /* 0x00: Table size (not including this word) */
    nls_byte  reserved1;           /* 0x02: ??? (01h for MS-DOS 3.30-6.00) */
    nls_byte  lowest_char;         /* 0x03: Lowest permissible filename char */
    nls_byte  highest_char;        /* 0x04: Highest permissible filename char */
    nls_byte  reserved2;           /* 0x05: ??? (00h for MS-DOS 3.30-6.00) */
    nls_byte  excl_first;          /* 0x06: First excluded character in range */
    nls_byte  excl_last;           /* 0x07: Last excluded character in range */
    nls_byte  reserved3;           /* 0x08: ??? (02h for MS-DOS 3.30-6.00) */
    nls_byte  num_terminators;     /* 0x09: Number of terminator characters */
    nls_byte  terminators[32];     /* 0x0A: Characters that terminate filename */
} NLS_FILENAME_TERM_TABLE;         /* Variable size, typically ~22 bytes */
#pragma pack(pop)

/*============================================================================
 * NLS_COLLATING_TABLE Structure (258 bytes)
 *============================================================================
 * Collating sequence table returned by INT 21h AX=6506h.
 * Used for sorting characters 00h-FFh.
 *============================================================================*/
#pragma pack(push, 1)
typedef struct {
    nls_word  size;                /* 0x00: Table size (0100h = 256) */
    nls_byte  data[256];           /* 0x02: Collating values for chars 00h-FFh */
} NLS_COLLATING_TABLE;             /* Total: 258 bytes */
#pragma pack(pop)

/*============================================================================
 * NLS_DBCS_TABLE Structure
 *============================================================================
 * Double-Byte Character Set lead byte table returned by INT 21h AX=6507h.
 * Contains ranges of lead bytes for DBCS encodings (Japanese, Chinese, Korean).
 * The table consists of pairs of (start, end) bytes terminated by 0000h.
 *============================================================================*/
#pragma pack(push, 1)
typedef struct {
    nls_word  length;              /* 0x00: Length of table in bytes (ranges) */
    nls_byte  ranges[16];          /* 0x02: Start/end byte pairs, terminated by 0000h */
} NLS_DBCS_TABLE;                  /* Variable size, typically 4-10 bytes */
#pragma pack(pop)

/*============================================================================
 * NLS_TABLE_PTR Structure
 *============================================================================
 * Generic structure for returning pointer to NLS tables.
 * Used by INT 21h AH=65h subfunctions 02h-07h.
 *============================================================================*/
#pragma pack(push, 1)
typedef struct {
    nls_byte  info_id;             /* 0x00: Info ID (02h-07h) */
    void NLS_FAR *table_ptr;       /* 0x01: Far pointer to table */
} NLS_TABLE_PTR;
#pragma pack(pop)

/*============================================================================
 * NLS_EXTENDED_ERROR Structure
 *============================================================================
 * Extended error information returned by INT 21h AH=59h.
 *============================================================================*/
typedef struct {
    nls_word  error_code;          /* Extended error code (AX) */
    nls_byte  error_class;         /* Error class (BH) */
    nls_byte  suggested_action;    /* Suggested action (BL) */
    nls_byte  error_locus;         /* Error locus (CH) */
} NLS_EXTENDED_ERROR;

/*============================================================================
 * NLS_CODE_PAGE_INFO Structure
 *============================================================================
 * Code page information returned by INT 21h AX=6601h.
 *============================================================================*/
typedef struct {
    nls_word  active_codepage;     /* Active (selected) code page */
    nls_word  system_codepage;     /* System (boot) code page */
} NLS_CODE_PAGE_INFO;

/*============================================================================
 * Function Prototypes
 *============================================================================
 * All functions return 0 on success, nonzero DOS error code on failure.
 * The caller is responsible for allocating and freeing memory for structures.
 *============================================================================*/

/*----------------------------------------------------------------------------
 * nls_get_country_info
 *----------------------------------------------------------------------------
 * Get country-dependent information (INT 21h AH=38h).
 *
 * Parameters:
 *   country_code - Country code (0 = current country, 1-254 = specific,
 *                  255+ requires extended call with BX)
 *   info         - Pointer to NLS_COUNTRY_INFO structure to receive data
 *
 * Returns:
 *   0 on success, DOS error code on failure (typically 02h = invalid country)
 *
 * Notes:
 *   - For country codes >= 255, use nls_get_country_info_ex()
 *   - Requires DOS 2.11+ for full structure
 *----------------------------------------------------------------------------*/
nls_word NLS_CDECL nls_get_country_info(nls_word country_code,
                                         NLS_COUNTRY_INFO *info);

/*----------------------------------------------------------------------------
 * nls_get_country_info_ex
 *----------------------------------------------------------------------------
 * Get country-dependent information for any country code (INT 21h AH=38h).
 * Handles country codes >= 255 by setting AL=FFh and country in BX.
 *
 * Parameters:
 *   country_code - Country code (0 = current, any 16-bit value)
 *   info         - Pointer to NLS_COUNTRY_INFO structure to receive data
 *   ret_country  - Optional pointer to receive actual country code (can be NULL)
 *
 * Returns:
 *   0 on success, DOS error code on failure
 *----------------------------------------------------------------------------*/
nls_word NLS_CDECL nls_get_country_info_ex(nls_word country_code,
                                            NLS_COUNTRY_INFO *info,
                                            nls_word *ret_country);

/*----------------------------------------------------------------------------
 * nls_set_country
 *----------------------------------------------------------------------------
 * Set the current country (INT 21h AH=38h with DX=FFFFh).
 *
 * Parameters:
 *   country_code - Country code to set (must be valid, not 0)
 *
 * Returns:
 *   0 on success, DOS error code on failure
 *
 * Notes:
 *   - Country code 0 is NOT valid for SET operation
 *   - Requires appropriate COUNTRY.SYS driver for non-US countries
 *----------------------------------------------------------------------------*/
nls_word NLS_CDECL nls_set_country(nls_word country_code);

/*----------------------------------------------------------------------------
 * nls_get_ext_country_info
 *----------------------------------------------------------------------------
 * Get extended country information (INT 21h AX=6501h).
 *
 * Parameters:
 *   country_id   - Country ID (0xFFFF = current/default)
 *   code_page    - Code page (0xFFFF = global code page)
 *   info         - Pointer to NLS_EXT_COUNTRY_INFO structure to receive data
 *   buf_size     - Size of buffer (should be >= 41 bytes)
 *
 * Returns:
 *   0 on success, DOS error code on failure
 *
 * Notes:
 *   - Requires DOS 3.3+
 *   - NLSFUNC must be installed for non-default country info
 *----------------------------------------------------------------------------*/
nls_word NLS_CDECL nls_get_ext_country_info(nls_word country_id,
                                             nls_word code_page,
                                             NLS_EXT_COUNTRY_INFO *info,
                                             nls_word buf_size);

/*----------------------------------------------------------------------------
 * nls_get_uppercase_table
 *----------------------------------------------------------------------------
 * Get pointer to uppercase table (INT 21h AX=6502h).
 *
 * Parameters:
 *   country_id   - Country ID (0xFFFF = current/default)
 *   code_page    - Code page (0xFFFF = global code page)
 *   table_ptr    - Pointer to receive far pointer to NLS_UPPERCASE_TABLE
 *
 * Returns:
 *   0 on success, DOS error code on failure
 *
 * Notes:
 *   - Requires DOS 3.3+
 *   - Returns pointer to DOS internal table - do not modify!
 *   - Table contains uppercase equivalents for chars 80h-FFh
 *----------------------------------------------------------------------------*/
nls_word NLS_CDECL nls_get_uppercase_table(nls_word country_id,
                                            nls_word code_page,
                                            NLS_UPPERCASE_TABLE NLS_FAR **table_ptr);

/*----------------------------------------------------------------------------
 * nls_get_lowercase_table
 *----------------------------------------------------------------------------
 * Get pointer to lowercase table (INT 21h AX=6503h).
 *
 * Parameters:
 *   country_id   - Country ID (0xFFFF = current/default)
 *   code_page    - Code page (0xFFFF = global code page)
 *   table_ptr    - Pointer to receive far pointer to NLS_LOWERCASE_TABLE
 *
 * Returns:
 *   0 on success, DOS error code on failure
 *
 * Notes:
 *   - Requires DOS 6.2+ with COUNTRY.SYS
 *   - Only supports code page 866 in DOS 6.2x
 *   - Table contains lowercase equivalents for chars 00h-FFh
 *----------------------------------------------------------------------------*/
nls_word NLS_CDECL nls_get_lowercase_table(nls_word country_id,
                                            nls_word code_page,
                                            NLS_LOWERCASE_TABLE NLS_FAR **table_ptr);

/*----------------------------------------------------------------------------
 * nls_get_filename_upper_table
 *----------------------------------------------------------------------------
 * Get pointer to filename uppercase table (INT 21h AX=6504h).
 *
 * Parameters:
 *   country_id   - Country ID (0xFFFF = current/default)
 *   code_page    - Code page (0xFFFF = global code page)
 *   table_ptr    - Pointer to receive far pointer to NLS_FILENAME_UPPER_TABLE
 *
 * Returns:
 *   0 on success, DOS error code on failure
 *
 * Notes:
 *   - Requires DOS 3.3+
 *   - Under OS/2, identical to nls_get_uppercase_table()
 *   - Used for uppercasing filename characters 80h-FFh
 *----------------------------------------------------------------------------*/
nls_word NLS_CDECL nls_get_filename_upper_table(nls_word country_id,
                                                 nls_word code_page,
                                                 NLS_FILENAME_UPPER_TABLE NLS_FAR **table_ptr);

/*----------------------------------------------------------------------------
 * nls_get_filename_term_table
 *----------------------------------------------------------------------------
 * Get pointer to filename terminator table (INT 21h AX=6505h).
 *
 * Parameters:
 *   country_id   - Country ID (0xFFFF = current/default)
 *   code_page    - Code page (0xFFFF = global code page)
 *   table_ptr    - Pointer to receive far pointer to NLS_FILENAME_TERM_TABLE
 *
 * Returns:
 *   0 on success, DOS error code on failure
 *
 * Notes:
 *   - Requires DOS 3.3+ (documented DOS 5+)
 *   - Returns same info for all countries/code pages
 *   - Defines characters invalid in filenames: . " / \ [ ] : | < > + = ; ,
 *----------------------------------------------------------------------------*/
nls_word NLS_CDECL nls_get_filename_term_table(nls_word country_id,
                                                nls_word code_page,
                                                NLS_FILENAME_TERM_TABLE NLS_FAR **table_ptr);

/*----------------------------------------------------------------------------
 * nls_get_collating_table
 *----------------------------------------------------------------------------
 * Get pointer to collating sequence table (INT 21h AX=6506h).
 *
 * Parameters:
 *   country_id   - Country ID (0xFFFF = current/default)
 *   code_page    - Code page (0xFFFF = global code page)
 *   table_ptr    - Pointer to receive far pointer to NLS_COLLATING_TABLE
 *
 * Returns:
 *   0 on success, DOS error code on failure
 *
 * Notes:
 *   - Requires DOS 3.3+
 *   - Table contains collating (sort order) values for chars 00h-FFh
 *   - Used for sorting/comparing strings
 *----------------------------------------------------------------------------*/
nls_word NLS_CDECL nls_get_collating_table(nls_word country_id,
                                            nls_word code_page,
                                            NLS_COLLATING_TABLE NLS_FAR **table_ptr);

/*----------------------------------------------------------------------------
 * nls_get_dbcs_table
 *----------------------------------------------------------------------------
 * Get pointer to DBCS lead byte table (INT 21h AX=6507h).
 *
 * Parameters:
 *   country_id   - Country ID (0xFFFF = current/default)
 *   code_page    - Code page (0xFFFF = global code page)
 *   table_ptr    - Pointer to receive far pointer to NLS_DBCS_TABLE
 *
 * Returns:
 *   0 on success, DOS error code on failure
 *
 * Notes:
 *   - Requires DOS 4.0+
 *   - Table contains ranges of lead bytes for DBCS encodings
 *   - Empty table (length=0) for non-DBCS code pages
 *   - Used for Japanese (CP932), Chinese (CP936/950), Korean (CP949)
 *----------------------------------------------------------------------------*/
nls_word NLS_CDECL nls_get_dbcs_table(nls_word country_id,
                                       nls_word code_page,
                                       NLS_DBCS_TABLE NLS_FAR **table_ptr);

/*----------------------------------------------------------------------------
 * nls_get_code_page
 *----------------------------------------------------------------------------
 * Get the current global code page (INT 21h AX=6601h).
 *
 * Parameters:
 *   cp_info      - Pointer to NLS_CODE_PAGE_INFO structure to receive data
 *
 * Returns:
 *   0 on success, DOS error code on failure
 *
 * Notes:
 *   - Requires DOS 3.3+
 *   - active_codepage = currently selected code page
 *   - system_codepage = code page specified at boot time
 *----------------------------------------------------------------------------*/
nls_word NLS_CDECL nls_get_code_page(NLS_CODE_PAGE_INFO *cp_info);

/*----------------------------------------------------------------------------
 * nls_set_code_page
 *----------------------------------------------------------------------------
 * Set the global code page (INT 21h AX=6602h).
 *
 * Parameters:
 *   active_codepage  - New active code page
 *   system_codepage  - System code page (typically same as active)
 *
 * Returns:
 *   0 on success, DOS error code on failure
 *
 * Notes:
 *   - Requires DOS 3.3+
 *   - Requires NLSFUNC and COUNTRY.SYS to be installed
 *   - Changes code page for all devices
 *----------------------------------------------------------------------------*/
nls_word NLS_CDECL nls_set_code_page(nls_word active_codepage,
                                      nls_word system_codepage);

/*----------------------------------------------------------------------------
 * nls_get_extended_error
 *----------------------------------------------------------------------------
 * Get extended error information (INT 21h AH=59h BX=0000h).
 *
 * Parameters:
 *   error_info   - Pointer to NLS_EXTENDED_ERROR structure to receive data
 *
 * Returns:
 *   The extended error code (also stored in error_info->error_code)
 *   Returns 0 if no error has occurred
 *
 * Notes:
 *   - Requires DOS 3.0+
 *   - Must be called immediately after an error occurs
 *   - Call after any INT 21h function returns with CF set
 *   - Destroys registers CX, DX, DI, SI, BP, DS, ES
 *----------------------------------------------------------------------------*/
nls_word NLS_CDECL nls_get_extended_error(NLS_EXTENDED_ERROR *error_info);

/*----------------------------------------------------------------------------
 * nls_uppercase_char
 *----------------------------------------------------------------------------
 * Convert a single character to uppercase using the case map routine.
 *
 * Parameters:
 *   ch           - Character to convert (should be >= 80h for extended chars)
 *
 * Returns:
 *   Uppercase equivalent of the character
 *
 * Notes:
 *   - Uses the case map routine pointer from country info
 *   - For characters < 80h, returns the character unchanged (or use toupper)
 *   - For extended characters (>= 80h), calls the DOS case map routine
 *----------------------------------------------------------------------------*/
nls_byte NLS_CDECL nls_uppercase_char(nls_byte ch);

/*----------------------------------------------------------------------------
 * nls_is_dbcs_lead_byte
 *----------------------------------------------------------------------------
 * Check if a byte is a DBCS lead byte.
 *
 * Parameters:
 *   ch           - Character to check
 *
 * Returns:
 *   1 if ch is a DBCS lead byte, 0 otherwise
 *
 * Notes:
 *   - Uses the DBCS table for current code page
 *   - Always returns 0 for non-DBCS code pages (437, 850, etc.)
 *   - Used for Japanese, Chinese, Korean text processing
 *----------------------------------------------------------------------------*/
nls_word NLS_CDECL nls_is_dbcs_lead_byte(nls_byte ch);

/*----------------------------------------------------------------------------
 * nls_check_yesno_char
 *----------------------------------------------------------------------------
 * Determine if a character represents a Yes or No response (INT 21h AX=6523h).
 *
 * This function checks whether the given character (or DBCS character pair)
 * represents a "Yes" or "No" response according to the current country and
 * code page settings. This is useful for internationalized programs that
 * need to accept Yes/No input from users in their native language.
 *
 * Parameters:
 *   ch           - Character to check (single-byte or first byte of DBCS)
 *   dbcs_trail   - Second byte of DBCS character (0 for single-byte chars)
 *
 * Returns:
 *   NLS_YESNO_NO (0)      - Character represents "No" (e.g., 'N', 'n')
 *   NLS_YESNO_YES (1)     - Character represents "Yes" (e.g., 'Y', 'y')
 *   NLS_YESNO_NEITHER (2) - Character is neither Yes nor No
 *   >2                    - DOS error code on failure
 *
 * Notes:
 *   - Requires DOS 4.0+
 *   - For single-byte characters, pass dbcs_trail=0
 *   - For DBCS characters (Japanese, Chinese, Korean), pass both bytes
 *   - The Yes/No characters are country-dependent:
 *       USA/UK: Y/N, Germany: J/N, France: O/N, Spain: S/N, etc.
 *   - Supports NLSFUNC for non-default country settings
 *
 * Example:
 *   nls_word result = nls_check_yesno_char('Y', 0);
 *   if (result == NLS_YESNO_YES) {
 *       // User entered Yes
 *   } else if (result == NLS_YESNO_NO) {
 *       // User entered No
 *   } else if (result == NLS_YESNO_NEITHER) {
 *       // Invalid response, prompt again
 *   }
 *----------------------------------------------------------------------------*/
nls_word NLS_CDECL nls_check_yesno_char(nls_byte ch, nls_byte dbcs_trail);

#ifdef __cplusplus
}
#endif

#endif /* NLS_H */
