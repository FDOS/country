/*============================================================================
 * test.c - Test Program for sample.asm Library Functions
 *============================================================================
 * This program tests the assembly functions defined in sample.asm to verify
 * that the dosazm.inc framework correctly handles calling conventions.
 *
 * Build with Open Watcom (small model, cdecl):
 *   wcc -ms -ecc test.c -fo=test.obj
 *   wlink system dos file test.obj,sample.obj name test.exe
 *
 * Run in DOS or DOSBox:
 *   test.exe
 *
 *============================================================================*/

#include <stdio.h>
#include <string.h>

/*----------------------------------------------------------------------------
 * External declarations for assembly functions
 * Note: When using -ecc (cdecl), Watcom will look for _name symbols
 *----------------------------------------------------------------------------*/

/* unsigned short add_bytes(unsigned char a, unsigned char b); */
extern unsigned short add_bytes(unsigned char a, unsigned char b);

/* unsigned short add_words(unsigned short a, unsigned short b); */
extern unsigned short add_words(unsigned short a, unsigned short b);

/* unsigned long mul_words(unsigned short a, unsigned short b); */
extern unsigned long mul_words(unsigned short a, unsigned short b);

/* unsigned short read_near_ptr(unsigned short *ptr); */
extern unsigned short read_near_ptr(unsigned short *ptr);

/* void write_near_ptr(unsigned short *ptr, unsigned short value); */
extern void write_near_ptr(unsigned short *ptr, unsigned short value);

/* unsigned short sum_array(unsigned short *arr, unsigned short count); */
extern unsigned short sum_array(unsigned short *arr, unsigned short count);

/* unsigned short str_length(const char *str); */
extern unsigned short str_length(const char *str);

/* unsigned short get_max(unsigned short a, unsigned short b); */
extern unsigned short get_max(unsigned short a, unsigned short b);

/* void swap_words(unsigned short *a, unsigned short *b); */
extern void swap_words(unsigned short *a, unsigned short *b);


/*----------------------------------------------------------------------------
 * Test helper macros
 *----------------------------------------------------------------------------*/
static int tests_passed = 0;
static int tests_failed = 0;

#define TEST(cond, name) do { \
    if (cond) { \
        printf("PASS: %s\n", name); \
        tests_passed++; \
    } else { \
        printf("FAIL: %s\n", name); \
        tests_failed++; \
    } \
} while(0)

#define TEST_EQ(expected, actual, name) do { \
    if ((expected) == (actual)) { \
        printf("PASS: %s (got %u)\n", name, (unsigned)(actual)); \
        tests_passed++; \
    } else { \
        printf("FAIL: %s (expected %u, got %u)\n", name, \
               (unsigned)(expected), (unsigned)(actual)); \
        tests_failed++; \
    } \
} while(0)

#define TEST_EQ_LONG(expected, actual, name) do { \
    if ((expected) == (actual)) { \
        printf("PASS: %s (got %lu)\n", name, (unsigned long)(actual)); \
        tests_passed++; \
    } else { \
        printf("FAIL: %s (expected %lu, got %lu)\n", name, \
               (unsigned long)(expected), (unsigned long)(actual)); \
        tests_failed++; \
    } \
} while(0)


/*----------------------------------------------------------------------------
 * Main test function
 *----------------------------------------------------------------------------*/
int main(void)
{
    unsigned short x, y, result;
    unsigned long result_long;
    unsigned short arr[5] = {10, 20, 30, 40, 50};
    const char *test_str = "Hello, DOS!";
    
    printf("===========================================\n");
    printf("Testing dosazm.inc Assembly Library\n");
    printf("===========================================\n\n");
    
    /*------------------------------------------------------------------------
     * Test add_bytes
     *------------------------------------------------------------------------*/
    printf("--- Testing add_bytes ---\n");
    
    result = add_bytes(10, 20);
    TEST_EQ(30, result, "add_bytes(10, 20)");
    
    result = add_bytes(0, 0);
    TEST_EQ(0, result, "add_bytes(0, 0)");
    
    result = add_bytes(255, 1);
    TEST_EQ(256, result, "add_bytes(255, 1) - overflow to 16-bit");
    
    result = add_bytes(100, 150);
    TEST_EQ(250, result, "add_bytes(100, 150)");
    
    printf("\n");
    
    /*------------------------------------------------------------------------
     * Test add_words
     *------------------------------------------------------------------------*/
    printf("--- Testing add_words ---\n");
    
    result = add_words(1000, 2000);
    TEST_EQ(3000, result, "add_words(1000, 2000)");
    
    result = add_words(0, 0);
    TEST_EQ(0, result, "add_words(0, 0)");
    
    result = add_words(32000, 32000);
    TEST_EQ(64000, result, "add_words(32000, 32000)");
    
    printf("\n");
    
    /*------------------------------------------------------------------------
     * Test mul_words
     *------------------------------------------------------------------------*/
    printf("--- Testing mul_words ---\n");
    
    result_long = mul_words(100, 200);
    TEST_EQ_LONG(20000UL, result_long, "mul_words(100, 200)");
    
    result_long = mul_words(1000, 1000);
    TEST_EQ_LONG(1000000UL, result_long, "mul_words(1000, 1000)");
    
    result_long = mul_words(65535, 2);
    TEST_EQ_LONG(131070UL, result_long, "mul_words(65535, 2)");
    
    result_long = mul_words(0, 12345);
    TEST_EQ_LONG(0UL, result_long, "mul_words(0, 12345)");
    
    printf("\n");
    
    /*------------------------------------------------------------------------
     * Test read_near_ptr
     *------------------------------------------------------------------------*/
    printf("--- Testing read_near_ptr ---\n");
    
    x = 12345;
    result = read_near_ptr(&x);
    TEST_EQ(12345, result, "read_near_ptr(&x) where x=12345");
    
    x = 0;
    result = read_near_ptr(&x);
    TEST_EQ(0, result, "read_near_ptr(&x) where x=0");
    
    x = 65535;
    result = read_near_ptr(&x);
    TEST_EQ(65535, result, "read_near_ptr(&x) where x=65535");
    
    printf("\n");
    
    /*------------------------------------------------------------------------
     * Test write_near_ptr
     *------------------------------------------------------------------------*/
    printf("--- Testing write_near_ptr ---\n");
    
    x = 0;
    write_near_ptr(&x, 9999);
    TEST_EQ(9999, x, "write_near_ptr(&x, 9999)");
    
    write_near_ptr(&x, 0);
    TEST_EQ(0, x, "write_near_ptr(&x, 0)");
    
    write_near_ptr(&x, 65535);
    TEST_EQ(65535, x, "write_near_ptr(&x, 65535)");
    
    printf("\n");
    
    /*------------------------------------------------------------------------
     * Test sum_array
     *------------------------------------------------------------------------*/
    printf("--- Testing sum_array ---\n");
    
    /* arr = {10, 20, 30, 40, 50}, sum = 150 */
    result = sum_array(arr, 5);
    TEST_EQ(150, result, "sum_array({10,20,30,40,50}, 5)");
    
    result = sum_array(arr, 3);
    TEST_EQ(60, result, "sum_array({10,20,30,...}, 3)");
    
    result = sum_array(arr, 1);
    TEST_EQ(10, result, "sum_array({10,...}, 1)");
    
    result = sum_array(arr, 0);
    TEST_EQ(0, result, "sum_array(arr, 0) - empty");
    
    printf("\n");
    
    /*------------------------------------------------------------------------
     * Test str_length
     *------------------------------------------------------------------------*/
    printf("--- Testing str_length ---\n");
    
    result = str_length(test_str);  /* "Hello, DOS!" = 11 chars */
    TEST_EQ(11, result, "str_length(\"Hello, DOS!\")");
    
    result = str_length("");
    TEST_EQ(0, result, "str_length(\"\") - empty string");
    
    result = str_length("A");
    TEST_EQ(1, result, "str_length(\"A\")");
    
    result = str_length("NASM Framework Test");
    TEST_EQ(19, result, "str_length(\"NASM Framework Test\")");
    
    printf("\n");
    
    /*------------------------------------------------------------------------
     * Test get_max
     *------------------------------------------------------------------------*/
    printf("--- Testing get_max ---\n");
    
    result = get_max(100, 200);
    TEST_EQ(200, result, "get_max(100, 200)");
    
    result = get_max(500, 300);
    TEST_EQ(500, result, "get_max(500, 300)");
    
    result = get_max(42, 42);
    TEST_EQ(42, result, "get_max(42, 42) - equal values");
    
    result = get_max(0, 65535);
    TEST_EQ(65535, result, "get_max(0, 65535)");
    
    printf("\n");
    
    /*------------------------------------------------------------------------
     * Test swap_words
     *------------------------------------------------------------------------*/
    printf("--- Testing swap_words ---\n");
    
    x = 111;
    y = 222;
    swap_words(&x, &y);
    TEST((x == 222 && y == 111), "swap_words(&111, &222)");
    
    x = 0;
    y = 65535;
    swap_words(&x, &y);
    TEST((x == 65535 && y == 0), "swap_words(&0, &65535)");
    
    x = 1000;
    y = 1000;
    swap_words(&x, &y);
    TEST((x == 1000 && y == 1000), "swap_words equal values");
    
    printf("\n");
    
    /*------------------------------------------------------------------------
     * Summary
     *------------------------------------------------------------------------*/
    printf("===========================================\n");
    printf("Test Summary: %d passed, %d failed\n", tests_passed, tests_failed);
    printf("===========================================\n");
    
    return tests_failed > 0 ? 1 : 0;
}
