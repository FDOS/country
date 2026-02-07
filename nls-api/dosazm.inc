;============================================================================
; dosazm.inc - NASM Macro Framework for DOS 16-bit Assembly Libraries
;============================================================================
; A framework for writing DOS 16-bit real mode 8086 assembly libraries
; compatible with multiple C compilers and memory models.
;
; Supported compilers: WATCOM, GCC, BCC (Borland), MSC (Microsoft), DMC (Digital Mars)
; Supported models: TINY, SMALL, COMPACT, MEDIUM, LARGE, HUGE
;
; Usage:
;   %define MODEL SMALL      ; or TINY, COMPACT, MEDIUM, LARGE, HUGE
;   %define COMPILER WATCOM  ; or GCC, BORLAND, MSC, DMC
;   %include "dosazm.inc"
;
; Author: DOS Assembly Framework
; License: Public Domain
;============================================================================

%ifndef DOSAZM_INC
%define DOSAZM_INC

;============================================================================
; Default Configuration
;============================================================================

; Default compiler is WATCOM if not specified
%ifndef COMPILER
    %define COMPILER WATCOM
%endif

; Default model is SMALL if not specified
%ifndef MODEL
    %define MODEL SMALL
%endif

;============================================================================
; Model Configuration
; Define CODE_FAR, DATA_FAR, and return address sizes
;============================================================================

; TINY model: Near code, Near data, single 64KB segment (CS=DS=SS)
%ifidn MODEL,TINY
    %define CODE_FAR 0
    %define DATA_FAR 0
    %define RET_SIZE 2          ; Near return address size
    %define DPTR_SIZE 2         ; Near data pointer size
%endif

; SMALL model: Near code, Near data (CS separate, DS=SS)
%ifidn MODEL,SMALL
    %define CODE_FAR 0
    %define DATA_FAR 0
    %define RET_SIZE 2
    %define DPTR_SIZE 2
%endif

; COMPACT model: Near code, Far data
%ifidn MODEL,COMPACT
    %define CODE_FAR 0
    %define DATA_FAR 1
    %define RET_SIZE 2
    %define DPTR_SIZE 4         ; Far data pointer size
%endif

; MEDIUM model: Far code, Near data
%ifidn MODEL,MEDIUM
    %define CODE_FAR 1
    %define DATA_FAR 0
    %define RET_SIZE 4          ; Far return address size
    %define DPTR_SIZE 2
%endif

; LARGE model: Far code, Far data
%ifidn MODEL,LARGE
    %define CODE_FAR 1
    %define DATA_FAR 1
    %define RET_SIZE 4
    %define DPTR_SIZE 4
%endif

; HUGE model: Far code, Far data (same as LARGE for our purposes)
%ifidn MODEL,HUGE
    %define CODE_FAR 1
    %define DATA_FAR 1
    %define RET_SIZE 4
    %define DPTR_SIZE 4
%endif

; Check that model was valid
%ifndef RET_SIZE
    %error "Invalid MODEL specified. Use TINY, SMALL, COMPACT, MEDIUM, LARGE, or HUGE"
%endif

;============================================================================
; Compiler Configuration
; Define name mangling, calling convention, and register preservation
;============================================================================

; Name prefix: Most compilers use underscore prefix for cdecl
; WATCOM with watcall has no prefix, but for cdecl compatibility it does

%ifidn COMPILER,WATCOM
    ; Watcom with -ecc (cdecl) uses underscore prefix
    ; Default watcall doesn't, but we'll support cdecl for library compatibility
    %define NAME_PREFIX _
    %define CALLER_CLEANUP 1    ; cdecl: caller cleans up
    %define USE_WATCALL 0       ; Set to 1 if using native watcall
%endif

%ifidn COMPILER,GCC
    ; GCC-ia16 uses underscore prefix with cdecl
    %define NAME_PREFIX _
    %define CALLER_CLEANUP 1
    %define USE_WATCALL 0
%endif

%ifidn COMPILER,BORLAND
    ; Borland C uses underscore prefix with cdecl
    %define NAME_PREFIX _
    %define CALLER_CLEANUP 1
    %define USE_WATCALL 0
%endif

%ifidn COMPILER,MSC
    ; Microsoft C uses underscore prefix with cdecl
    %define NAME_PREFIX _
    %define CALLER_CLEANUP 1
    %define USE_WATCALL 0
%endif

%ifidn COMPILER,DMC
    ; Digital Mars C uses underscore prefix with cdecl
    %define NAME_PREFIX _
    %define CALLER_CLEANUP 1
    %define USE_WATCALL 0
%endif

; Check that compiler was valid
%ifndef NAME_PREFIX
    %error "Invalid COMPILER specified. Use WATCOM, GCC, BORLAND, MSC, or DMC"
%endif

;============================================================================
; Stack Frame Layout
;============================================================================
; After function prologue (push bp / mov bp,sp):
;
; For NEAR calls (2-byte return address):
;   [BP+0]  = old BP
;   [BP+2]  = return IP
;   [BP+4]  = first argument
;   [BP+6]  = second argument (if word-sized first arg)
;
; For FAR calls (4-byte return address):
;   [BP+0]  = old BP
;   [BP+2]  = return IP
;   [BP+4]  = return CS
;   [BP+6]  = first argument
;   [BP+8]  = second argument (if word-sized first arg)
;
;============================================================================

; Base offset to first argument after BP and return address
%define ARG_BASE (2 + RET_SIZE)

; Argument offset macros - account for pushed BP and return address
; Usage: mov ax, [bp + ARG1]
%define ARG1 ARG_BASE
%define ARG2 (ARG_BASE + 2)
%define ARG3 (ARG_BASE + 4)
%define ARG4 (ARG_BASE + 6)
%define ARG5 (ARG_BASE + 8)
%define ARG6 (ARG_BASE + 10)
%define ARG7 (ARG_BASE + 12)
%define ARG8 (ARG_BASE + 14)

; For far pointers (4 bytes), use these after the offset portion
%define ARG_FAR_OFF(n) (ARG_BASE + (n-1)*4)
%define ARG_FAR_SEG(n) (ARG_BASE + (n-1)*4 + 2)

;============================================================================
; Segment Definition Macros
;============================================================================

; Define a code segment (use at start of file)
%macro SEGMENT_CODE 0
%if CODE_FAR
    ; Far code models: each source file typically gets its own segment
    ; Use name_TEXT format for compatibility
    SECTION .text CLASS=CODE
%else
    ; Near code models: single _TEXT segment
    SECTION _TEXT CLASS=CODE
%endif
%endmacro

; Define a data segment
%macro SEGMENT_DATA 0
    SECTION _DATA CLASS=DATA
%endmacro

; Define a BSS segment (uninitialized data)
%macro SEGMENT_BSS 0
    SECTION _BSS CLASS=BSS
%endmacro

; Simplified default segment setup
%macro SEGMENT_DEFAULT 0
    SEGMENT_CODE
%endmacro

;============================================================================
; Name Mangling Macros
;============================================================================

; Create an exported symbol with proper name mangling
; Usage: GLOBAL myfunction
%macro GLOBAL 1
    global %[NAME_PREFIX]%1
%endmacro

; Create a reference to external symbol with proper name mangling
; Usage: EXTERN otherfunction
%macro EXTERN 1
    extern %[NAME_PREFIX]%1
%endmacro

; Define the label with proper name mangling (for function entry point)
; Usage: LABEL myfunction
%macro LABEL 1
%[NAME_PREFIX]%1:
%endmacro

;============================================================================
; Function Prologue/Epilogue Macros
;============================================================================

; Begin a function definition with prologue
; Creates the global symbol, label, and standard prologue
; Usage:
;   PROC myfunc
;       ; function body
;   ENDPROC myfunc
;
%macro PROC 1
    GLOBAL %1
    LABEL %1
    push bp
    mov bp, sp
%endmacro

; Alternative: PROC with local variable space
; Usage: PROC_LOCALS myfunc, 4  ; 4 bytes of locals
%macro PROC_LOCALS 2
    GLOBAL %1
    LABEL %1
    push bp
    mov bp, sp
    sub sp, %2
%endmacro

; End a function with epilogue (cdecl: no argument cleanup)
; Usage: ENDPROC myfunc
%macro ENDPROC 1
    mov sp, bp          ; Restore stack (cleans up locals if any)
    pop bp
%if CODE_FAR
    retf                ; Far return
%else
    ret                 ; Near return
%endif
%endmacro

; End function with explicit argument cleanup (for stdcall/pascal)
; Usage: ENDPROC_CLEAN myfunc, 4  ; clean 4 bytes of args
%macro ENDPROC_CLEAN 2
    mov sp, bp
    pop bp
%if CODE_FAR
    retf %2
%else
    ret %2
%endif
%endmacro

; Simple return (for functions without prologue or use in middle)
%macro RETURN 0
%if CODE_FAR
    retf
%else
    ret
%endif
%endmacro

;============================================================================
; Register Save/Restore Macros
;============================================================================
; According to calling conventions, SI, DI, BP, DS must be preserved
; AX, BX, CX, DX, ES are scratch registers

; Save registers that must be preserved (use at start after prologue)
; These match what C compilers expect to be preserved
%macro PUSHREGS 1-*
%rep %0
    push %1
%rotate 1
%endrep
%endmacro

; Restore registers (use before epilogue, reverse order)
%macro POPREGS 1-*
; Reverse the order by rotating to end first
%assign %%i %0
%rep %0
%rotate -1
    pop %1
%endrep
%endmacro

; Common register save patterns
%macro SAVE_ALL 0
    push si
    push di
    push bx
%endmacro

%macro RESTORE_ALL 0
    pop bx
    pop di
    pop si
%endmacro

%macro SAVE_SI_DI 0
    push si
    push di
%endmacro

%macro RESTORE_SI_DI 0
    pop di
    pop si
%endmacro

;============================================================================
; Argument Access Helpers
;============================================================================

; Get 8-bit argument (zero-extended to 16-bit on stack) into register
; Usage: ARG_BYTE ax, 1    ; get first byte arg into al (ax cleared)
%macro ARG_BYTE 2
    mov %1, [bp + ARG_BASE + (%2-1)*2]
    ; Note: caller promoted byte to word, we read the low byte
%endmacro

; Get 16-bit argument into register
; Usage: ARG_WORD ax, 1    ; get first word arg into ax
%macro ARG_WORD 2
    mov %1, [bp + ARG_BASE + (%2-1)*2]
%endmacro

; Get 32-bit argument (e.g., long or far pointer) into dx:ax
; Usage: ARG_DWORD 1       ; get first dword arg into dx:ax
%macro ARG_DWORD 1
    mov ax, [bp + ARG_BASE + (%1-1)*4]
    mov dx, [bp + ARG_BASE + (%1-1)*4 + 2]
%endmacro

; Load near pointer argument into register
; Usage: ARG_NEAR_PTR si, 1  ; load first pointer arg into si
%macro ARG_NEAR_PTR 2
    mov %1, [bp + ARG_BASE + (%2-1)*2]
%endmacro

; Load far pointer argument into es:register (segment:offset)
; Usage: ARG_FAR_PTR es, di, 1  ; load first far ptr into es:di
%macro ARG_FAR_PTR 3
    mov %2, [bp + ARG_BASE + (%3-1)*4]      ; offset
    mov %1, [bp + ARG_BASE + (%3-1)*4 + 2]  ; segment
%endmacro

; Load far pointer using les instruction
; Usage: ARG_FAR_PTR_LES di, 1   ; load first far ptr into es:di
%macro ARG_FAR_PTR_LES 2
    les %1, [bp + ARG_BASE + (%2-1)*4]
%endmacro

; Load far pointer using lds instruction
; Usage: ARG_FAR_PTR_LDS si, 1   ; load first far ptr into ds:si
%macro ARG_FAR_PTR_LDS 2
    lds %1, [bp + ARG_BASE + (%2-1)*4]
%endmacro

;============================================================================
; Return Value Helpers
;============================================================================
; Standard C return value conventions:
;   8-bit:  AL
;   16-bit: AX
;   32-bit: DX:AX (high:low)

; No macros needed - just use mov ax, value or mov dx:ax appropriately
; These are just documentation aliases

%define RET_BYTE al
%define RET_WORD ax
%define RET_DWORD_LO ax
%define RET_DWORD_HI dx

;============================================================================
; Utility Macros
;============================================================================

; Clear register to zero (smaller than mov reg, 0)
%macro ZERO 1
    xor %1, %1
%endmacro

; Set up DS=SS (for functions that need to access data segment)
%macro SET_DS_FROM_SS 0
    push ss
    pop ds
%endmacro

;============================================================================
; Debug/Development Helpers
;============================================================================

; Print model and compiler info as comments in listing
; %warning is not standard, using %pragma or comments instead

;============================================================================
; Output Format
;============================================================================
; Configure for OBJ output (OMF format for DOS linkers)
; This should be specified on nasm command line: nasm -f obj

;============================================================================
; End of dosazm.inc
;============================================================================

%endif ; DOSAZM_INC
