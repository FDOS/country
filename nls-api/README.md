# DOS NASM Assembly Framework

A NASM macro framework for writing DOS 16-bit real mode 8086 assembly libraries compatible with multiple C compilers and memory models.

## Features

- **Multi-compiler support**: Open Watcom, GCC-ia16, Borland/Turbo C, Microsoft C, Digital Mars C
- **Memory model support**: TINY, SMALL, COMPACT, MEDIUM, LARGE, HUGE
- **Automatic name mangling**: Underscore prefix for cdecl compatibility
- **Near/Far call handling**: Correct RET/RETF based on memory model
- **Argument access macros**: Account for return address size (2 bytes near, 4 bytes far)
- **Register preservation helpers**: PUSHREGS/POPREGS macros

## Files

- `dosazm.inc` - The NASM macro framework include file
- `sample.asm` - Sample library demonstrating various argument types
- `test.c` - C test program that calls the assembly functions
- `Makefile` - Build automation

## Calling Convention Summary

All compilers use **cdecl** calling convention for interoperability:

| Compiler | Name Prefix | Stack Cleanup | Register Preservation |
|----------|-------------|---------------|----------------------|
| WATCOM   | `_`         | Caller        | SI, DI, BP, DS       |
| GCC      | `_`         | Caller        | SI, DI, BP, DS       |
| BCC      | `_`         | Caller        | SI, DI, BP, DS       |
| MSC      | `_`         | Caller        | SI, DI, BP, DS       |
| DMC      | `_`         | Caller        | SI, DI, BP, DS       |

**Scratch registers** (can be freely modified): AX, BX, CX, DX, ES

## Memory Model Details

| Model   | Code   | Data   | RET Size | Data Ptr Size |
|---------|--------|--------|----------|---------------|
| TINY    | Near   | Near   | 2 bytes  | 2 bytes       |
| SMALL   | Near   | Near   | 2 bytes  | 2 bytes       |
| COMPACT | Near   | Far    | 2 bytes  | 4 bytes       |
| MEDIUM  | Far    | Near   | 4 bytes  | 2 bytes       |
| LARGE   | Far    | Far    | 4 bytes  | 4 bytes       |
| HUGE    | Far    | Far    | 4 bytes  | 4 bytes       |

## Usage

### Basic Assembly File Structure

```nasm
; mylib.asm
%define MODEL SMALL
%define COMPILER WATCOM
%include "dosazm.inc"

SEGMENT_CODE

; Simple function: unsigned short add(unsigned short a, unsigned short b)
PROC add
    ARG_WORD ax, 1      ; ax = first argument
    ARG_WORD bx, 2      ; bx = second argument
    add ax, bx          ; ax = a + b
ENDPROC add
```

### Available Macros

#### Configuration
- `%define MODEL SMALL` - Set memory model (TINY/SMALL/COMPACT/MEDIUM/LARGE/HUGE)
- `%define COMPILER WATCOM` - Set target compiler (WATCOM/GCC/BCC/MSC/DMC)

#### Segments
- `SEGMENT_CODE` - Define code segment
- `SEGMENT_DATA` - Define data segment
- `SEGMENT_BSS` - Define BSS segment

#### Function Definition
- `PROC name` - Begin function with prologue (GLOBAL, label, push bp, mov bp,sp)
- `PROC_LOCALS name, size` - Function with local variable space
- `ENDPROC name` - End function with epilogue (restore bp, ret/retf)

#### Argument Access
- `ARG_BYTE reg, n` - Load nth byte argument (1-based)
- `ARG_WORD reg, n` - Load nth word argument
- `ARG_DWORD n` - Load nth dword into DX:AX
- `ARG_NEAR_PTR reg, n` - Load nth near pointer
- `ARG_FAR_PTR seg, off, n` - Load nth far pointer into seg:off
- `ARG_FAR_PTR_LES reg, n` - Load nth far pointer into ES:reg
- `ARG_FAR_PTR_LDS reg, n` - Load nth far pointer into DS:reg

#### Register Preservation
- `PUSHREGS reg1, reg2, ...` - Push multiple registers
- `POPREGS reg1, reg2, ...` - Pop in reverse order
- `SAVE_SI_DI` / `RESTORE_SI_DI` - Common pattern
- `SAVE_ALL` / `RESTORE_ALL` - Save SI, DI, BX

#### Stack Frame Offsets
- `ARG1` through `ARG8` - Direct offsets for [bp + ARGn]
- `ARG_BASE` - Base offset to first argument

## Building

### With Open Watcom (Linux cross-compile)

```bash
# Set environment
export WATCOM=/opt/watcom
export PATH=$WATCOM/binl64:$PATH
export INCLUDE=$WATCOM/h

# Assemble (SMALL model)
nasm -f obj -DMODEL=SMALL -DCOMPILER=WATCOM sample.asm -o sample.obj

# Compile C code (SMALL model, cdecl)
wcc -ms -ecc -zq -0 -i=$WATCOM/h test.c -fo=test.obj

# Link
wlink system dos file test.obj,sample.obj name test.exe
```

### With Make

```bash
make              # Build SMALL model
make medium       # Build MEDIUM model
make large        # Build LARGE model
make clean        # Remove build artifacts
```

## Stack Frame Layout

After standard prologue (`push bp` / `mov bp, sp`):

**Near calls (TINY, SMALL, COMPACT):**
```
[BP+0]  = saved BP
[BP+2]  = return IP
[BP+4]  = first argument (ARG1)
[BP+6]  = second argument (ARG2)
...
```

**Far calls (MEDIUM, LARGE, HUGE):**
```
[BP+0]  = saved BP
[BP+2]  = return IP
[BP+4]  = return CS
[BP+6]  = first argument (ARG1)
[BP+8]  = second argument (ARG2)
...
```

## Testing

The test program runs in DOS/DOSBox and verifies all assembly functions work correctly:

```
===========================================
Testing dosazm.inc Assembly Library
===========================================

--- Testing add_bytes ---
PASS: add_bytes(10, 20) (got 30)
...

--- Testing mul_words ---
PASS: mul_words(100, 200) (got 20000)
...

===========================================
Test Summary: X passed, 0 failed
===========================================
```

## C Function Prototypes

```c
extern unsigned short add_bytes(unsigned char a, unsigned char b);
extern unsigned short add_words(unsigned short a, unsigned short b);
extern unsigned long mul_words(unsigned short a, unsigned short b);
extern unsigned short read_near_ptr(unsigned short *ptr);
extern void write_near_ptr(unsigned short *ptr, unsigned short value);
extern unsigned short sum_array(unsigned short *arr, unsigned short count);
extern unsigned short str_length(const char *str);
extern unsigned short get_max(unsigned short a, unsigned short b);
extern void swap_words(unsigned short *a, unsigned short *b);
```

## Known Limitations

1. Default configuration targets cdecl calling convention. Native watcall (register-based) is not currently implemented.
2. Far pointer functions are only assembled when `DATA_FAR` is set (COMPACT, LARGE, HUGE models).
3. Segment naming follows Watcom/Microsoft conventions (_TEXT, _DATA, _BSS).

## License

Public Domain - Use freely for any purpose.
