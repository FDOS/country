/*============================================================================
 * nlstest.c - Test Program for DOS NLS Library
 *============================================================================
 * Demonstrates all NLS library functions:
 *   - Country information retrieval
 *   - Extended country information
 *   - Code page get/set
 *   - Character case mapping
 *   - Collating sequence
 *   - DBCS detection
 *   - Extended error information
 *
 * Build with Open Watcom:
 *   wcc -ms -ecc -zq -0 nlstest.c
 *   nasm -f obj -DMODEL=SMALL -DCOMPILER=WATCOM nls.asm -o nls.obj
 *   wlink system dos file nlstest.obj,nls.obj name nlstest.exe
 *
 * Or simply: make nls
 *
 * Author: DOS NLS Library
 * License: Public Domain
 *============================================================================*/

#include <stdio.h>
#include <string.h>
#include "nls.h"

/*----------------------------------------------------------------------------
 * Helper Functions
 *----------------------------------------------------------------------------*/

/* Print a separator line */
static void print_separator(void)
{
    printf("----------------------------------------\n");
}

/* Print date format name */
static const char *get_date_format_name(nls_word fmt)
{
    switch (fmt) {
        case NLS_DATE_USA:    return "USA (mm/dd/yy)";
        case NLS_DATE_EUROPE: return "Europe (dd/mm/yy)";
        case NLS_DATE_JAPAN:  return "Japan (yy/mm/dd)";
        default:              return "Unknown";
    }
}

/* Print error class name */
static const char *get_error_class_name(nls_byte cls)
{
    switch (cls) {
        case NLS_ERRCLASS_OUTOFRES:  return "Out of resource";
        case NLS_ERRCLASS_TEMPFAIL:  return "Temporary";
        case NLS_ERRCLASS_AUTH:      return "Authorization";
        case NLS_ERRCLASS_INTERNAL:  return "Internal";
        case NLS_ERRCLASS_HARDWARE:  return "Hardware";
        case NLS_ERRCLASS_SYSTEM:    return "System";
        case NLS_ERRCLASS_APP:       return "Application";
        case NLS_ERRCLASS_NOTFOUND:  return "Not found";
        case NLS_ERRCLASS_BADFMT:    return "Bad format";
        case NLS_ERRCLASS_LOCKED:    return "Locked";
        case NLS_ERRCLASS_MEDIA:     return "Media";
        case NLS_ERRCLASS_EXISTS:    return "Already exists";
        default:                     return "Unknown";
    }
}

/* Print suggested action name */
static const char *get_action_name(nls_byte action)
{
    switch (action) {
        case NLS_ACTION_RETRY:       return "Retry";
        case NLS_ACTION_DELAY_RETRY: return "Delay retry";
        case NLS_ACTION_REENTER:     return "Re-enter input";
        case NLS_ACTION_ABORT_CLEAN: return "Abort (cleanup)";
        case NLS_ACTION_ABORT_NOW:   return "Abort (immediate)";
        case NLS_ACTION_IGNORE:      return "Ignore";
        case NLS_ACTION_USER:        return "User intervention";
        default:                     return "Unknown";
    }
}

/* Print locus name */
static const char *get_locus_name(nls_byte locus)
{
    switch (locus) {
        case NLS_LOCUS_UNKNOWN: return "Unknown";
        case NLS_LOCUS_BLOCK:   return "Block device";
        case NLS_LOCUS_NETWORK: return "Network";
        case NLS_LOCUS_SERIAL:  return "Serial device";
        case NLS_LOCUS_MEMORY:  return "Memory";
        default:                return "Unknown";
    }
}

/*----------------------------------------------------------------------------
 * Test Functions
 *----------------------------------------------------------------------------*/

/* Test nls_get_country_info */
static void test_get_country_info(void)
{
    NLS_COUNTRY_INFO info;
    nls_word result;
    
    printf("\n=== Test: nls_get_country_info ===\n");
    print_separator();
    
    /* Get current country info */
    result = nls_get_country_info(0, &info);
    
    if (result == 0) {
        printf("Current Country Information:\n");
        printf("  Date format:       %s\n", get_date_format_name(info.date_format));
        printf("  Currency symbol:   '%s'\n", info.currency_symbol);
        printf("  Thousands sep:     '%s'\n", info.thousands_sep);
        printf("  Decimal sep:       '%s'\n", info.decimal_sep);
        printf("  Date sep:          '%s'\n", info.date_sep);
        printf("  Time sep:          '%s'\n", info.time_sep);
        printf("  Currency format:   0x%02X\n", info.currency_format);
        printf("    - Position:      %s\n", 
               (info.currency_format & NLS_CURR_FOLLOWS) ? "After" : "Before");
        printf("    - Space:         %s\n", 
               (info.currency_format & NLS_CURR_SPACE) ? "Yes" : "No");
        printf("  Currency digits:   %d\n", info.currency_digits);
        printf("  Time format:       %s\n", 
               (info.time_format & NLS_TIME_24HR) ? "24-hour" : "12-hour");
        printf("  Case map routine:  %04lX:%04lX\n", 
               (unsigned long)(info.case_map_call >> 16),
               (unsigned long)(info.case_map_call & 0xFFFF));
        printf("  Data separator:    '%s'\n", info.data_sep);
    } else {
        printf("ERROR: nls_get_country_info failed with code %u\n", result);
    }
}

/* Test nls_get_country_info_ex with specific country */
static void test_get_country_info_ex(void)
{
    NLS_COUNTRY_INFO info;
    nls_word ret_country;
    nls_word result;
    
    printf("\n=== Test: nls_get_country_info_ex (Germany) ===\n");
    print_separator();
    
    result = nls_get_country_info_ex(NLS_COUNTRY_GERMANY, &info, &ret_country);
    
    if (result == 0) {
        printf("Germany (country %u) Information:\n", ret_country);
        printf("  Date format:       %s\n", get_date_format_name(info.date_format));
        printf("  Currency symbol:   '%s'\n", info.currency_symbol);
        printf("  Thousands sep:     '%s'\n", info.thousands_sep);
        printf("  Decimal sep:       '%s'\n", info.decimal_sep);
    } else {
        printf("ERROR: Failed with code %u (may need NLSFUNC installed)\n", result);
    }
}

/* Test nls_get_ext_country_info */
static void test_get_ext_country_info(void)
{
    NLS_EXT_COUNTRY_INFO ext_info;
    nls_word result;
    
    printf("\n=== Test: nls_get_ext_country_info ===\n");
    print_separator();
    
    result = nls_get_ext_country_info(NLS_COUNTRY_DEFAULT, NLS_CODEPAGE_GLOBAL,
                                       &ext_info, sizeof(ext_info));
    
    if (result == 0) {
        printf("Extended Country Information:\n");
        printf("  Info ID:           %u\n", ext_info.info_id);
        printf("  Size:              %u bytes\n", ext_info.size);
        printf("  Country ID:        %u\n", ext_info.country_id);
        printf("  Code Page:         %u\n", ext_info.code_page);
        printf("  Date format:       %s\n", 
               get_date_format_name(ext_info.info.date_format));
        printf("  Currency symbol:   '%s'\n", ext_info.info.currency_symbol);
    } else {
        printf("ERROR: Failed with code %u (requires DOS 3.3+)\n", result);
    }
}

/* Test nls_get_code_page */
static void test_get_code_page(void)
{
    NLS_CODE_PAGE_INFO cp_info;
    nls_word result;
    
    printf("\n=== Test: nls_get_code_page ===\n");
    print_separator();
    
    result = nls_get_code_page(&cp_info);
    
    if (result == 0) {
        printf("Code Page Information:\n");
        printf("  Active code page:  %u\n", cp_info.active_codepage);
        printf("  System code page:  %u\n", cp_info.system_codepage);
        
        /* Print code page name */
        printf("  Code page name:    ");
        switch (cp_info.active_codepage) {
            case NLS_CP_437: printf("US English (OEM)\n"); break;
            case NLS_CP_850: printf("Multilingual Latin I\n"); break;
            case NLS_CP_852: printf("Central European\n"); break;
            case NLS_CP_866: printf("Cyrillic (Russian)\n"); break;
            default:         printf("Unknown\n"); break;
        }
    } else {
        printf("ERROR: Failed with code %u (requires DOS 3.3+)\n", result);
    }
}

/* Test nls_get_uppercase_table */
static void test_get_uppercase_table(void)
{
    NLS_UPPERCASE_TABLE NLS_FAR *table_ptr;
    nls_word result;
    int i;
    
    printf("\n=== Test: nls_get_uppercase_table ===\n");
    print_separator();
    
    result = nls_get_uppercase_table(NLS_COUNTRY_DEFAULT, NLS_CODEPAGE_GLOBAL,
                                      &table_ptr);
    
    if (result == 0) {
        printf("Uppercase Table (first 16 entries for chars 80h-8Fh):\n");
        printf("  Table size: %u bytes\n", table_ptr->size);
        printf("  ");
        for (i = 0; i < 16 && i < table_ptr->size; i++) {
            printf("%02X ", table_ptr->data[i]);
        }
        printf("\n");
        
        /* Show some example mappings */
        printf("\n  Sample uppercase mappings:\n");
        for (i = 0; i < 8; i++) {
            nls_byte ch = 0x80 + i;
            nls_byte upper = table_ptr->data[i];
            if (ch != upper) {
                printf("    %02Xh -> %02Xh\n", ch, upper);
            }
        }
    } else {
        printf("ERROR: Failed with code %u\n", result);
    }
}

/* Test nls_get_collating_table */
static void test_get_collating_table(void)
{
    NLS_COLLATING_TABLE NLS_FAR *table_ptr;
    nls_word result;
    int i;
    
    printf("\n=== Test: nls_get_collating_table ===\n");
    print_separator();
    
    result = nls_get_collating_table(NLS_COUNTRY_DEFAULT, NLS_CODEPAGE_GLOBAL,
                                      &table_ptr);
    
    if (result == 0) {
        printf("Collating Table (first 32 entries):\n");
        printf("  Table size: %u bytes\n", table_ptr->size);
        
        /* Show collating values for A-Z */
        printf("\n  Collating values for A-Z:\n    ");
        for (i = 'A'; i <= 'Z'; i++) {
            printf("%02X ", table_ptr->data[i]);
        }
        printf("\n");
        
        /* Show collating values for a-z */
        printf("  Collating values for a-z:\n    ");
        for (i = 'a'; i <= 'z'; i++) {
            printf("%02X ", table_ptr->data[i]);
        }
        printf("\n");
    } else {
        printf("ERROR: Failed with code %u\n", result);
    }
}

/* Test nls_get_dbcs_table */
static void test_get_dbcs_table(void)
{
    NLS_DBCS_TABLE NLS_FAR *table_ptr;
    nls_word result;
    int i;
    
    printf("\n=== Test: nls_get_dbcs_table ===\n");
    print_separator();
    
    result = nls_get_dbcs_table(NLS_COUNTRY_DEFAULT, NLS_CODEPAGE_GLOBAL,
                                 &table_ptr);
    
    if (result == 0) {
        printf("DBCS Lead Byte Table:\n");
        printf("  Table length: %u bytes\n", table_ptr->length);
        
        if (table_ptr->length == 0) {
            printf("  (No DBCS ranges - single-byte code page)\n");
        } else {
            printf("  Lead byte ranges:\n");
            for (i = 0; i < table_ptr->length && i < 16; i += 2) {
                if (table_ptr->ranges[i] == 0 && table_ptr->ranges[i+1] == 0) {
                    break;
                }
                printf("    %02Xh - %02Xh\n", 
                       table_ptr->ranges[i], table_ptr->ranges[i+1]);
            }
        }
    } else {
        printf("ERROR: Failed with code %u (requires DOS 4.0+)\n", result);
    }
}

/* Test nls_get_filename_term_table */
static void test_get_filename_term_table(void)
{
    NLS_FILENAME_TERM_TABLE NLS_FAR *table_ptr;
    nls_word result;
    int i;
    
    printf("\n=== Test: nls_get_filename_term_table ===\n");
    print_separator();
    
    result = nls_get_filename_term_table(NLS_COUNTRY_DEFAULT, NLS_CODEPAGE_GLOBAL,
                                          &table_ptr);
    
    if (result == 0) {
        printf("Filename Terminator Table:\n");
        printf("  Table size:        %u bytes\n", table_ptr->size);
        printf("  Lowest char:       %02Xh (%c)\n", 
               table_ptr->lowest_char, 
               (table_ptr->lowest_char >= 32) ? table_ptr->lowest_char : '?');
        printf("  Highest char:      %02Xh\n", table_ptr->highest_char);
        printf("  Excluded range:    %02Xh - %02Xh\n", 
               table_ptr->excl_first, table_ptr->excl_last);
        printf("  Num terminators:   %u\n", table_ptr->num_terminators);
        printf("  Terminators:       ");
        for (i = 0; i < table_ptr->num_terminators && i < 20; i++) {
            nls_byte ch = table_ptr->terminators[i];
            if (ch >= 32 && ch < 127) {
                printf("%c ", ch);
            } else {
                printf("[%02X] ", ch);
            }
        }
        printf("\n");
    } else {
        printf("ERROR: Failed with code %u\n", result);
    }
}

/* Test nls_uppercase_char */
static void test_uppercase_char(void)
{
    printf("\n=== Test: nls_uppercase_char ===\n");
    print_separator();
    
    printf("Character uppercase conversion:\n");
    printf("  'a' -> '%c'\n", nls_uppercase_char('a'));
    printf("  'z' -> '%c'\n", nls_uppercase_char('z'));
    printf("  'A' -> '%c'\n", nls_uppercase_char('A'));
    printf("  '5' -> '%c'\n", nls_uppercase_char('5'));
    printf("  81h -> %02Xh (extended char)\n", nls_uppercase_char(0x81));
    printf("  84h -> %02Xh (extended char)\n", nls_uppercase_char(0x84));
}

/* Test nls_is_dbcs_lead_byte */
static void test_is_dbcs_lead_byte(void)
{
    printf("\n=== Test: nls_is_dbcs_lead_byte ===\n");
    print_separator();
    
    printf("DBCS lead byte check:\n");
    printf("  'A' (41h):  %s\n", nls_is_dbcs_lead_byte('A') ? "Yes" : "No");
    printf("  80h:        %s\n", nls_is_dbcs_lead_byte(0x80) ? "Yes" : "No");
    printf("  81h:        %s\n", nls_is_dbcs_lead_byte(0x81) ? "Yes" : "No");
    printf("  9Fh:        %s\n", nls_is_dbcs_lead_byte(0x9F) ? "Yes" : "No");
    printf("  E0h:        %s\n", nls_is_dbcs_lead_byte(0xE0) ? "Yes" : "No");
    printf("  (Results depend on current code page)\n");
}

/* Test nls_get_extended_error */
static void test_get_extended_error(void)
{
    NLS_EXTENDED_ERROR err;
    nls_word result;
    
    printf("\n=== Test: nls_get_extended_error ===\n");
    print_separator();
    
    /* First, get error info (should show no error or last error) */
    result = nls_get_extended_error(&err);
    
    printf("Extended Error Information:\n");
    printf("  Error code:        %u (0x%04X)\n", err.error_code, err.error_code);
    printf("  Error class:       %u - %s\n", 
           err.error_class, get_error_class_name(err.error_class));
    printf("  Suggested action:  %u - %s\n", 
           err.suggested_action, get_action_name(err.suggested_action));
    printf("  Error locus:       %u - %s\n", 
           err.error_locus, get_locus_name(err.error_locus));
    
    if (err.error_code == 0) {
        printf("\n  (No error has occurred)\n");
    }
}

/* Test with invalid country to generate an error */
static void test_error_generation(void)
{
    NLS_COUNTRY_INFO info;
    NLS_EXTENDED_ERROR err;
    nls_word result;
    
    printf("\n=== Test: Error Generation ===\n");
    print_separator();
    
    /* Try to get info for an invalid country code */
    printf("Attempting to get country info for invalid country 999...\n");
    result = nls_get_country_info(999, &info);
    
    if (result != 0) {
        printf("  Got error code: %u\n", result);
        
        /* Now get extended error info */
        nls_get_extended_error(&err);
        
        printf("  Extended error:\n");
        printf("    Error code:        %u\n", err.error_code);
        printf("    Error class:       %s\n", get_error_class_name(err.error_class));
        printf("    Suggested action:  %s\n", get_action_name(err.suggested_action));
        printf("    Error locus:       %s\n", get_locus_name(err.error_locus));
    } else {
        printf("  Unexpectedly succeeded!\n");
    }
}

/*----------------------------------------------------------------------------
 * Main Program
 *----------------------------------------------------------------------------*/

int main(void)
{
    printf("================================================\n");
    printf("   DOS NLS Library Test Program\n");
    printf("================================================\n");
    printf("Testing National Language Support functions...\n");
    
    /* Run all tests */
    test_get_country_info();
    test_get_country_info_ex();
    test_get_ext_country_info();
    test_get_code_page();
    test_get_uppercase_table();
    test_get_collating_table();
    test_get_dbcs_table();
    test_get_filename_term_table();
    test_uppercase_char();
    test_is_dbcs_lead_byte();
    test_get_extended_error();
    test_error_generation();
    
    printf("\n================================================\n");
    printf("   All tests completed!\n");
    printf("================================================\n");
    
    return 0;
}
