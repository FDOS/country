/*============================================================================
 * nlsdump.c - DOS NLS Information Dump Utility
 *============================================================================
 * Comprehensive utility for dumping DOS National Language Support information.
 * Useful for testing, documentation, and comparing NLS data across systems.
 *
 * Usage: nlsdump [-c] [country_code] [codepage]
 *   -c           CSV output mode (single line with key fields)
 *   country_code Numeric country code (1=US, 49=Germany, etc.)
 *   codepage     Numeric code page (437, 850, etc.)
 *
 * Examples:
 *   nlsdump              - Dump current country/codepage (detailed)
 *   nlsdump -c           - Dump current country/codepage (CSV)
 *   nlsdump 49           - Dump Germany with current codepage
 *   nlsdump 1 437        - Dump US with codepage 437
 *   nlsdump -c 49 850    - Dump Germany with CP850 (CSV)
 *
 * Compiler Support: Watcom, Borland, GCC-ia16, Microsoft C, Digital Mars
 * Memory Models: Small, Medium (recommended)
 *
 * Author: NLS Library
 * License: Public Domain
 *============================================================================*/

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "nls.h"

/*============================================================================
 * Version Information
 *============================================================================*/
#define NLSDUMP_VERSION "1.0"

/*============================================================================
 * Country Name Mapping
 *============================================================================
 * Maps country codes to human-readable names.
 * Based on DOS INT 21h AH=38h documentation and common usage.
 *============================================================================*/
typedef struct {
    nls_word code;
    const char *name;
} COUNTRY_NAME;

static const COUNTRY_NAME country_names[] = {
    {   1, "United States" },
    {   2, "Canadian French" },
    {   3, "Latin America" },
    {   4, "Canada (English)" },
    {   7, "Russia" },
    {  20, "Egypt" },
    {  27, "South Africa" },
    {  30, "Greece" },
    {  31, "Netherlands" },
    {  32, "Belgium" },
    {  33, "France" },
    {  34, "Spain" },
    {  35, "Bulgaria" },
    {  36, "Hungary" },
    {  38, "Yugoslavia" },
    {  39, "Italy" },
    {  40, "Romania" },
    {  41, "Switzerland" },
    {  42, "Czech Republic" },
    {  43, "Austria" },
    {  44, "United Kingdom" },
    {  45, "Denmark" },
    {  46, "Sweden" },
    {  47, "Norway" },
    {  48, "Poland" },
    {  49, "Germany" },
    {  51, "Peru" },
    {  52, "Mexico" },
    {  53, "Cuba" },
    {  54, "Argentina" },
    {  55, "Brazil" },
    {  56, "Chile" },
    {  57, "Colombia" },
    {  58, "Venezuela" },
    {  60, "Malaysia" },
    {  61, "Australia" },
    {  62, "Indonesia" },
    {  63, "Philippines" },
    {  64, "New Zealand" },
    {  65, "Singapore" },
    {  66, "Thailand" },
    {  81, "Japan" },
    {  82, "South Korea" },
    {  84, "Vietnam" },
    {  86, "China" },
    {  88, "Taiwan" },
    {  90, "Turkey" },
    {  91, "India" },
    {  92, "Pakistan" },
    {  93, "Afghanistan" },
    {  94, "Sri Lanka" },
    {  98, "Iran" },
    { 102, "Israel (Hebrew)" },
    { 212, "Morocco" },
    { 213, "Algeria" },
    { 216, "Tunisia" },
    { 218, "Libya" },
    { 220, "Gambia" },
    { 221, "Senegal" },
    { 222, "Mauritania" },
    { 223, "Mali" },
    { 224, "Guinea" },
    { 225, "Ivory Coast" },
    { 226, "Burkina Faso" },
    { 227, "Niger" },
    { 228, "Togo" },
    { 229, "Benin" },
    { 230, "Mauritius" },
    { 231, "Liberia" },
    { 232, "Sierra Leone" },
    { 233, "Ghana" },
    { 234, "Nigeria" },
    { 235, "Chad" },
    { 236, "Central African Republic" },
    { 237, "Cameroon" },
    { 238, "Cape Verde" },
    { 239, "Sao Tome" },
    { 240, "Equatorial Guinea" },
    { 241, "Gabon" },
    { 242, "Congo" },
    { 243, "Zaire" },
    { 244, "Angola" },
    { 245, "Guinea-Bissau" },
    { 246, "Diego Garcia" },
    { 247, "Ascension Island" },
    { 248, "Seychelles" },
    { 249, "Sudan" },
    { 250, "Rwanda" },
    { 251, "Ethiopia" },
    { 252, "Somalia" },
    { 253, "Djibouti" },
    { 254, "Kenya" },
    { 255, "Tanzania" },
    { 256, "Uganda" },
    { 257, "Burundi" },
    { 258, "Mozambique" },
    { 260, "Zambia" },
    { 261, "Madagascar" },
    { 262, "Reunion" },
    { 263, "Zimbabwe" },
    { 264, "Namibia" },
    { 265, "Malawi" },
    { 266, "Lesotho" },
    { 267, "Botswana" },
    { 268, "Swaziland" },
    { 269, "Comoros" },
    { 290, "St. Helena" },
    { 291, "Eritrea" },
    { 297, "Aruba" },
    { 298, "Faroe Islands" },
    { 299, "Greenland" },
    { 350, "Gibraltar" },
    { 351, "Portugal" },
    { 352, "Luxembourg" },
    { 353, "Ireland" },
    { 354, "Iceland" },
    { 355, "Albania" },
    { 356, "Malta" },
    { 357, "Cyprus" },
    { 358, "Finland" },
    { 359, "Bulgaria" },
    { 370, "Lithuania" },
    { 371, "Latvia" },
    { 372, "Estonia" },
    { 373, "Moldova" },
    { 374, "Armenia" },
    { 375, "Belarus" },
    { 376, "Andorra" },
    { 377, "Monaco" },
    { 378, "San Marino" },
    { 379, "Vatican City" },
    { 380, "Ukraine" },
    { 381, "Serbia" },
    { 382, "Montenegro" },
    { 385, "Croatia" },
    { 386, "Slovenia" },
    { 387, "Bosnia and Herzegovina" },
    { 389, "Macedonia" },
    { 420, "Czech Republic" },
    { 421, "Slovakia" },
    { 500, "Falkland Islands" },
    { 501, "Belize" },
    { 502, "Guatemala" },
    { 503, "El Salvador" },
    { 504, "Honduras" },
    { 505, "Nicaragua" },
    { 506, "Costa Rica" },
    { 507, "Panama" },
    { 508, "St. Pierre" },
    { 509, "Haiti" },
    { 590, "Guadeloupe" },
    { 591, "Bolivia" },
    { 592, "Guyana" },
    { 593, "Ecuador" },
    { 594, "French Guiana" },
    { 595, "Paraguay" },
    { 596, "Martinique" },
    { 597, "Suriname" },
    { 598, "Uruguay" },
    { 599, "Netherlands Antilles" },
    { 670, "Saipan" },
    { 672, "Norfolk Island" },
    { 673, "Brunei" },
    { 674, "Nauru" },
    { 675, "Papua New Guinea" },
    { 676, "Tonga" },
    { 677, "Solomon Islands" },
    { 678, "Vanuatu" },
    { 679, "Fiji" },
    { 680, "Palau" },
    { 681, "Wallis and Futuna" },
    { 682, "Cook Islands" },
    { 683, "Niue" },
    { 684, "American Samoa" },
    { 685, "Western Samoa" },
    { 686, "Kiribati" },
    { 687, "New Caledonia" },
    { 688, "Tuvalu" },
    { 689, "French Polynesia" },
    { 690, "Tokelau" },
    { 691, "Micronesia" },
    { 692, "Marshall Islands" },
    { 785, "Arabic" },
    { 852, "Hong Kong" },
    { 853, "Macau" },
    { 855, "Cambodia" },
    { 856, "Laos" },
    { 880, "Bangladesh" },
    { 886, "Taiwan" },
    { 960, "Maldives" },
    { 961, "Lebanon" },
    { 962, "Jordan" },
    { 963, "Syria" },
    { 964, "Iraq" },
    { 965, "Kuwait" },
    { 966, "Saudi Arabia" },
    { 967, "Yemen" },
    { 968, "Oman" },
    { 971, "United Arab Emirates" },
    { 972, "Israel" },
    { 973, "Bahrain" },
    { 974, "Qatar" },
    { 975, "Bhutan" },
    { 976, "Mongolia" },
    { 977, "Nepal" },
    { 993, "Turkmenistan" },
    { 994, "Azerbaijan" },
    { 995, "Georgia" },
    { 996, "Kyrgyzstan" },
    { 998, "Uzbekistan" },
    {   0, NULL }  /* Terminator */
};

/*============================================================================
 * Get Country Name
 *============================================================================*/
static const char *get_country_name(nls_word code) {
    const COUNTRY_NAME *p;
    for (p = country_names; p->name != NULL; p++) {
        if (p->code == code) {
            return p->name;
        }
    }
    return "Unknown";
}

/*============================================================================
 * Print Escaped Character (7-bit ASCII clean)
 *============================================================================
 * Non-printable and high-bit characters are output as \xHH
 *============================================================================*/
static void print_escaped_char(int ch) {
    if (ch >= 32 && ch <= 126) {
        putchar(ch);
    } else {
        printf("\\x%02X", ch & 0xFF);
    }
}

/*============================================================================
 * Print Escaped String (7-bit ASCII clean)
 *============================================================================*/
static void print_escaped_string(const char *str) {
    while (*str) {
        print_escaped_char((unsigned char)*str);
        str++;
    }
}

/*============================================================================
 * Print Currency (7-bit ASCII clean)
 *============================================================================*/
static void print_currency(const char str[5]) {
    int ch;
    int ndx;  /* currency is always 5 bytes, should be 0 padded */
    for (ndx = 0; ndx < 5; ndx++) {
        ch = *str;
        if (ch >= 32 && ch <= 126) {
            printf("\"%c\"", ch);
        } else {
            if (ch)
                printf("0x%02X", ch & 0xFF);
            else
                printf("0");
        }
        if (ndx < 4) printf(", ");
        str++;
    }
}

/*============================================================================
 * Print Hex Table (16 bytes per line)
 *============================================================================*/
static void print_hex_table(const char *name, const nls_byte NLS_FAR *data, int size) {
    int i;
    printf("%s=", name);
    for (i = 0; i < size; i++) {
        if (i > 0) {
            putchar(',');
        }
        printf("%02X", data[i]);
    }
    putchar('\n');
}

/*============================================================================
 * Print db Table (8 bytes per line)  -- same format as config.asm source
 *============================================================================*/
static void print_db_table(const char *name, const nls_byte NLS_FAR *data, int size) {
    int i;
    printf("%s=\n", name);
    for (i = 0; i < size; i++) {
        if (!(i%8)) { /* start of a new line */
            if (i > 0) putchar('\n');
            printf("db ");
        } else { /* middle of a line */
            putchar(',');
        }
        printf("%3u", data[i]);
    }
    putchar('\n');
}

/*============================================================================
 * Print Date Format Name
 *============================================================================*/
static const char *get_date_format_name(nls_word fmt) {
    switch (fmt) {
        case NLS_DATE_USA:    return "mm/dd/yy";
        case NLS_DATE_EUROPE: return "dd/mm/yy";
        case NLS_DATE_JAPAN:  return "yy/mm/dd";
        default:              return "unknown";
    }
}

static const char *get_date_format_name_short(nls_word fmt) {
    switch (fmt) {
        case NLS_DATE_USA:    return "MDY";
        case NLS_DATE_EUROPE: return "DMY";
        case NLS_DATE_JAPAN:  return "YMD";
        default:              return "UNK";
    }
}

/*============================================================================
 * Print Time Format Name
 *============================================================================*/
static const char *get_time_format_name(nls_byte fmt) {
    return (fmt & NLS_TIME_24HR) ? "24-hour" : "12-hour";
}

static const char *get_time_format_name_short(nls_byte fmt) {
    return (fmt & NLS_TIME_24HR) ? "_24" : "_12";
}

/*============================================================================
 * Detect Yes/No Characters
 *============================================================================
 * Scans ASCII 1-255 and collects characters recognized as Yes or No.
 *============================================================================*/
static void detect_yesno_chars(char *yes_chars, char *no_chars, int max_len) {
    int ch;
    int yes_idx = 0, no_idx = 0;
    nls_word result;
    
    memset(yes_chars, 0, max_len);
    memset(no_chars, 0, max_len);

    for (ch = 1; ch <= 255; ch++) {
        result = nls_check_yesno_char((nls_byte)ch, 0);
        if (result == NLS_YESNO_YES && (yes_idx < max_len - 1)) {
            yes_chars[yes_idx++] = (char)ch;
        } else if (result == NLS_YESNO_NO && (no_idx < max_len - 1)) {
            no_chars[no_idx++] = (char)ch;
        }
    }
    yes_chars[yes_idx] = '\0';
    no_chars[no_idx] = '\0';
}

/*============================================================================
 * Print Yes/No Characters (escaped)
 *============================================================================*/
static void print_yesno_chars(const char *name, const char *chars) {
    printf("%s=", name);
    while (*chars) {
        print_escaped_char((unsigned char)*chars);
        chars++;
    }
    putchar('\n');
}

/*============================================================================
 * Dump NLS Information - Detailed Mode
 *============================================================================*/
static int dump_detailed(nls_word country_id, nls_word code_page) {
    NLS_EXT_COUNTRY_INFO ext_info;
    NLS_COUNTRY_INFO basic_info;
    NLS_CODE_PAGE_INFO cp_info;
    NLS_UPPERCASE_TABLE NLS_FAR *upper_table = NULL;
    NLS_LOWERCASE_TABLE NLS_FAR *lower_table = NULL;
    NLS_COLLATING_TABLE NLS_FAR *collate_table = NULL;
    NLS_DBCS_TABLE NLS_FAR *dbcs_table = NULL;
    NLS_FILENAME_UPPER_TABLE NLS_FAR *fn_upper_table = NULL;
    NLS_FILENAME_TERM_TABLE NLS_FAR *fn_term_table = NULL;
    char yes_chars[32], no_chars[32];
    nls_word err;
    nls_word actual_country;

    /* Version header */
    printf("NLS_DUMP_VERSION=%s\n", NLSDUMP_VERSION);

    /* Get code page info first */
    err = nls_get_code_page(&cp_info);
    if (err) {
        printf("ERROR_GET_CODEPAGE=%u\n", err);
    } else {
        printf("CODEPAGE_ACTIVE=%u\n", cp_info.active_codepage);
        printf("CODEPAGE_SYSTEM=%u\n", cp_info.system_codepage);
    }

    /* Get extended country info */
    err = nls_get_ext_country_info(country_id, code_page, &ext_info, sizeof(ext_info));
    if (err) {
        printf("ERROR_GET_COUNTRY_INFO=%u\n", err);
        /* Try basic country info as fallback */
        err = nls_get_country_info_ex(country_id, &basic_info, &actual_country);
        if (err) {
            printf("ERROR_GET_COUNTRY_INFO_BASIC=%u\n", err);
            return 1;
        }
        printf("COUNTRY_CODE=%u\n", actual_country);
        printf("COUNTRY_NAME=%s\n", get_country_name(actual_country));
        printf("DATE_FORMAT=%u\n", basic_info.date_format);
        printf("DATE_FORMAT_NAME=%s\n", get_date_format_name(basic_info.date_format));
        printf("DATE_SEPARATOR=");
        print_escaped_string(basic_info.date_sep);
        printf("\n");
        printf("TIME_FORMAT=%u\n", basic_info.time_format);
        printf("TIME_FORMAT_NAME=%s\n", get_time_format_name(basic_info.time_format));
        printf("TIME_SEPARATOR=");
        print_escaped_string(basic_info.time_sep);
        printf("\n");
        printf("CURRENCY_SYMBOL=");
        print_currency(basic_info.currency_symbol);
        printf("\n");
        printf("CURRENCY_FORMAT=%u\n", basic_info.currency_format);
        printf("CURRENCY_DIGITS=%u\n", basic_info.currency_digits);
        printf("THOUSANDS_SEPARATOR=");
        print_escaped_string(basic_info.thousands_sep);
        printf("\n");
        printf("DECIMAL_SEPARATOR=");
        print_escaped_string(basic_info.decimal_sep);
        printf("\n");
        printf("DATA_SEPARATOR=");
        print_escaped_string(basic_info.data_sep);
        printf("\n");
    } else {
        printf("COUNTRY_CODE=%u\n", ext_info.country_id);
        printf("COUNTRY_NAME=%s\n", get_country_name(ext_info.country_id));
        printf("INFO_CODEPAGE=%u\n", ext_info.code_page);
        printf("DATE_FORMAT=%u\n", ext_info.info.date_format);
        printf("DATE_FORMAT_NAME=%s\n", get_date_format_name(ext_info.info.date_format));
        printf("DATE_SEPARATOR=");
        print_escaped_string(ext_info.info.date_sep);
        printf("\n");
        printf("TIME_FORMAT=%u\n", ext_info.info.time_format);
        printf("TIME_FORMAT_NAME=%s\n", get_time_format_name(ext_info.info.time_format));
        printf("TIME_SEPARATOR=");
        print_escaped_string(ext_info.info.time_sep);
        printf("\n");
        printf("CURRENCY_SYMBOL=");
        print_currency(ext_info.info.currency_symbol);
        printf("\n");
        printf("CURRENCY_FORMAT=%u\n", ext_info.info.currency_format);
        printf("CURRENCY_DIGITS=%u\n", ext_info.info.currency_digits);
        printf("THOUSANDS_SEPARATOR=");
        print_escaped_string(ext_info.info.thousands_sep);
        printf("\n");
        printf("DECIMAL_SEPARATOR=");
        print_escaped_string(ext_info.info.decimal_sep);
        printf("\n");
        printf("DATA_SEPARATOR=");
        print_escaped_string(ext_info.info.data_sep);
        printf("\n");
        printf("CASE_MAP_ROUTINE=0x%08lX\n", ext_info.info.case_map_call);
    }

    /* Detect Yes/No characters */
    detect_yesno_chars(yes_chars, no_chars, sizeof(yes_chars));
    print_yesno_chars("YES_CHARS", yes_chars);
    print_yesno_chars("NO_CHARS", no_chars);

    /* Uppercase table */
    err = nls_get_uppercase_table(country_id, code_page, &upper_table);
    if (err) {
        printf("ERROR_GET_UPPERCASE_TABLE=%u\n", err);
    } else if (upper_table) {
        printf("UPPERCASE_TABLE_SIZE=%u\n", upper_table->size);
        print_db_table("UPPERCASE_TABLE", upper_table->data, 128);
    }

    /* Lowercase table (DOS 6.2+) */
    err = nls_get_lowercase_table(country_id, code_page, &lower_table);
    if (err) {
        printf("LOWERCASE_TABLE=N/A (error %u)\n", err);
    } else if (lower_table) {
        printf("LOWERCASE_TABLE_SIZE=%u\n", lower_table->size);
        print_db_table("LOWERCASE_TABLE", lower_table->data, 256);
    }

    /* Filename uppercase table */
    err = nls_get_filename_upper_table(country_id, code_page, &fn_upper_table);
    if (err) {
        printf("ERROR_GET_FILENAME_UPPER_TABLE=%u\n", err);
    } else if (fn_upper_table) {
        printf("FILENAME_UPPER_TABLE_SIZE=%u\n", fn_upper_table->size);
        print_db_table("FILENAME_UPPER_TABLE", fn_upper_table->data, 128);
    }

    /* Filename terminator table */
    err = nls_get_filename_term_table(country_id, code_page, &fn_term_table);
    if (err) {
        printf("ERROR_GET_FILENAME_TERM_TABLE=%u\n", err);
    } else if (fn_term_table) {
        printf("FILENAME_TERM_SIZE=%u\n", fn_term_table->size);
        printf("FILENAME_LOWEST_CHAR=0x%02X\n", fn_term_table->lowest_char);
        printf("FILENAME_HIGHEST_CHAR=0x%02X\n", fn_term_table->highest_char);
        printf("FILENAME_EXCL_FIRST=0x%02X\n", fn_term_table->excl_first);
        printf("FILENAME_EXCL_LAST=0x%02X\n", fn_term_table->excl_last);
        printf("FILENAME_NUM_TERMINATORS=%u\n", fn_term_table->num_terminators);
        if (fn_term_table->num_terminators > 0) {
            print_db_table("FILENAME_TERMINATORS", fn_term_table->terminators,
                            fn_term_table->num_terminators);
        }
    }

    /* Collating table */
    err = nls_get_collating_table(country_id, code_page, &collate_table);
    if (err) {
        printf("ERROR_GET_COLLATING_TABLE=%u\n", err);
    } else if (collate_table) {
        printf("COLLATING_TABLE_SIZE=%u\n", collate_table->size);
        print_db_table("COLLATING_TABLE", collate_table->data, 256);
    }

    /* DBCS table */
    err = nls_get_dbcs_table(country_id, code_page, &dbcs_table);
    if (err) {
        printf("DBCS_TABLE=N/A (error %u)\n", err);
    } else if (dbcs_table) {
        printf("DBCS_TABLE_LENGTH=%u\n", dbcs_table->length);
        if (dbcs_table->length > 0) {
            int range_count = 0;
            int i;
            /* Count ranges (pairs of bytes until 0000h) */
            for (i = 0; i < (int)dbcs_table->length && i < 16; i += 2) {
                if (dbcs_table->ranges[i] == 0 && dbcs_table->ranges[i+1] == 0) {
                    break;
                }
                range_count++;
            }
            printf("DBCS_RANGES=%d\n", range_count);
            for (i = 0; i < range_count; i++) {
                printf("DBCS_RANGE_%d=0x%02X-0x%02X\n", i,
                       dbcs_table->ranges[i*2], dbcs_table->ranges[i*2+1]);
            }
        } else {
            printf("DBCS_RANGES=0\n");
        }
    }

    return 0;
}

/*============================================================================
 * Dump NLS Information - CSV Mode
 *============================================================================
 * Output format: country_id,country_name,codepage,currency_symbol,
 *                date_format,time_format,yes_chars,no_chars
 *============================================================================*/
static int dump_csv(nls_word country_id, nls_word code_page) {
    NLS_EXT_COUNTRY_INFO ext_info;
    NLS_COUNTRY_INFO basic_info;
    NLS_CODE_PAGE_INFO cp_info;
    /* NLS_UPPERCASE_TABLE NLS_FAR *upper_table = NULL; */
    NLS_LOWERCASE_TABLE NLS_FAR *lower_table = NULL;
    /* NLS_COLLATING_TABLE NLS_FAR *collate_table = NULL; */
    NLS_DBCS_TABLE NLS_FAR *dbcs_table = NULL;
    /* NLS_FILENAME_UPPER_TABLE NLS_FAR *fn_upper_table = NULL; */
    /* NLS_FILENAME_TERM_TABLE NLS_FAR *fn_term_table = NULL; */
    char yes_chars[32], no_chars[32];
    nls_word err;
    nls_word actual_country;
    nls_word codepage_to_print;


    /* Get code page info */
    err = nls_get_code_page(&cp_info);
    if (err) {
        codepage_to_print = 0;
    } else {
        codepage_to_print = cp_info.active_codepage;
    }

    /* Get extended country info */
    err = nls_get_ext_country_info(country_id, code_page, &ext_info, sizeof(ext_info));
    if (err) {
        /* Try basic country info as fallback */
        err = nls_get_country_info_ex(country_id, &basic_info, &actual_country);
        if (err) {
            fprintf(stderr, "FATAL: Cannot get country info, error %u\n", err);
            return 1;
        }

        detect_yesno_chars(yes_chars, no_chars, sizeof(yes_chars));

        /* Print CSV: country_id,country_name,codepage,currency_symbol,date_format,time_format,yes_chars,no_chars */
        printf("%u,", actual_country);
        printf("%s,", get_country_name(actual_country));
        printf("%u,", codepage_to_print);
        print_currency(basic_info.currency_symbol);
        printf(",%u,%u,", basic_info.date_format, basic_info.time_format);
        print_escaped_string(yes_chars);
        putchar(',');
        print_escaped_string(no_chars);
        putchar('\n');
    } else {
        detect_yesno_chars(yes_chars, no_chars, sizeof(yes_chars));

        /* Print CSV: country_name,country_id,codepage*,lcase/blank,y,n,date_format code,string,currency_symbol,thousands separator,decimal separator,date separator,time separator, currency_flags,currency_precision,time_format code,string,dbcs_empty/dbcs */
        /* * mulit-lang codepages currently not split */
        printf("%s, ", get_country_name(ext_info.country_id));
        printf("%u, ", ext_info.country_id);
        printf("%u, ", ext_info.code_page ? ext_info.code_page : codepage_to_print);

        /* Lowercase table (DOS 6.2+) */
        err = nls_get_lowercase_table(country_id, code_page, &lower_table);
        if (!err && lower_table && lower_table->size) {
            printf("lcase(%u), ", lower_table->size);
        } else {
            printf("N/A, ");
        }
        print_escaped_string(yes_chars);
        printf(", ");
        print_escaped_string(no_chars);

        printf(", %u=", ext_info.info.date_format);
        printf("%s, ", get_date_format_name_short(ext_info.info.date_format));

        print_currency(ext_info.info.currency_symbol);

        printf(", \"");
        print_escaped_string(ext_info.info.thousands_sep);
        printf("\", \"");
        print_escaped_string(ext_info.info.decimal_sep);
        printf("\", \"");
        print_escaped_string(ext_info.info.date_sep);
        printf("\", \"");
        print_escaped_string(ext_info.info.time_sep);
        printf("\", ");

        printf("%u, ", ext_info.info.currency_format);
        printf("%u, ", ext_info.info.currency_digits);

        printf("%u=", ext_info.info.time_format);
        printf("%s, ", get_time_format_name_short(ext_info.info.time_format));

        /* DBCS table */
        err = nls_get_dbcs_table(country_id, code_page, &dbcs_table);
        if (err || !dbcs_table) {
            printf("dbcs_error, ");
        } else {
            if (dbcs_table->length)
                printf("dbcs(%u), ", dbcs_table->length);
            else
                printf("dbcs_empty, ");
        }

        printf("DATA_SEPARATOR=\'");
        print_escaped_string(ext_info.info.data_sep);
        printf("\'\n");
    }

    return 0;
}

/*============================================================================
 * Print Usage Information
 *============================================================================*/
static void print_usage(const char *prog) {
    printf("NLS Dump Utility v%s\n", NLSDUMP_VERSION);
    printf("Usage: %s [-c] [country_code] [codepage]\n", prog);
    printf("\n");
    printf("Options:\n");
    printf("  -c            CSV output mode (single line)\n");
    printf("  country_code  Numeric country code (1=US, 49=Germany, etc.)\n");
    printf("  codepage      Numeric code page (437, 850, etc.)\n");
    printf("\n");
    printf("If no country/codepage specified, uses current settings.\n");
    printf("\n");
    printf("Examples:\n");
    printf("  %s              Dump current settings (detailed)\n", prog);
    printf("  %s -c           Dump current settings (CSV)\n", prog);
    printf("  %s 49           Dump Germany with current codepage\n", prog);
    printf("  %s 1 437        Dump US with codepage 437\n", prog);
    printf("  %s -c 49 850    Dump Germany CP850 (CSV)\n", prog);
}

/*============================================================================
 * Main Entry Point
 *============================================================================*/
int main(int argc, char *argv[]) {
    int csv_mode = 0;
    nls_word country_id = NLS_COUNTRY_DEFAULT;
    nls_word code_page = NLS_CODEPAGE_GLOBAL;
    int arg_idx = 1;

    /* Parse arguments */
    while (arg_idx < argc) {
        if (strcmp(argv[arg_idx], "-c") == 0) {
            csv_mode = 1;
            arg_idx++;
        } else if (strcmp(argv[arg_idx], "-h") == 0 ||
                   strcmp(argv[arg_idx], "-?") == 0 ||
                   strcmp(argv[arg_idx], "--help") == 0) {
            print_usage(argv[0]);
            return 0;
        } else if (argv[arg_idx][0] == '-') {
            fprintf(stderr, "FATAL: Unknown option: %s\n", argv[arg_idx]);
            return 1;
        } else {
            /* Numeric argument - country code or codepage */
            unsigned int val = (unsigned int)atoi(argv[arg_idx]);
            if (country_id == NLS_COUNTRY_DEFAULT) {
                country_id = (nls_word)val;
            } else if (code_page == NLS_CODEPAGE_GLOBAL) {
                code_page = (nls_word)val;
            } else {
                fprintf(stderr, "FATAL: Too many arguments\n");
                return 1;
            }
            arg_idx++;
        }
    }

    /* Execute dump */
    if (csv_mode) {
        return dump_csv(country_id, code_page);
    } else {
        return dump_detailed(country_id, code_page);
    }
}
