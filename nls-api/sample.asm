;============================================================================
; sample.asm - Sample Library Demonstrating dosazm.inc Framework
;============================================================================
; This library demonstrates various argument types and calling conventions
; using the dosazm.inc macro framework.
;
; Build with:
;   nasm -f obj -DMODEL=SMALL -DCOMPILER=WATCOM sample.asm -o sample.obj
;
;============================================================================

; Configuration - can be overridden on command line with -D
%ifndef MODEL
    %define MODEL SMALL
%endif
%ifndef COMPILER
    %define COMPILER WATCOM
%endif

%include "dosazm.inc"

;============================================================================
; Code Segment
;============================================================================
SEGMENT_CODE

;----------------------------------------------------------------------------
; add_bytes - Add two unsigned char arguments
;----------------------------------------------------------------------------
; unsigned short add_bytes(unsigned char a, unsigned char b);
;
; Arguments (on stack, promoted to 16-bit):
;   [BP+ARG1] = a (low byte valid)
;   [BP+ARG2] = b (low byte valid)
;
; Returns: sum in AX
;----------------------------------------------------------------------------
PROC add_bytes
    ARG_BYTE ax, 1          ; ax = a (zero-extended)
    ARG_BYTE bx, 2          ; bx = b (zero-extended)
    add ax, bx              ; ax = a + b
ENDPROC add_bytes

;----------------------------------------------------------------------------
; add_words - Add two unsigned short arguments
;----------------------------------------------------------------------------
; unsigned short add_words(unsigned short a, unsigned short b);
;
; Arguments:
;   [BP+ARG1] = a
;   [BP+ARG2] = b
;
; Returns: sum in AX
;----------------------------------------------------------------------------
PROC add_words
    ARG_WORD ax, 1          ; ax = a
    ARG_WORD bx, 2          ; bx = b
    add ax, bx              ; ax = a + b
ENDPROC add_words

;----------------------------------------------------------------------------
; mul_words - Multiply two unsigned short arguments
;----------------------------------------------------------------------------
; unsigned long mul_words(unsigned short a, unsigned short b);
;
; Arguments:
;   [BP+ARG1] = a
;   [BP+ARG2] = b
;
; Returns: product in DX:AX (32-bit)
;----------------------------------------------------------------------------
PROC mul_words
    ARG_WORD ax, 1          ; ax = a
    ARG_WORD bx, 2          ; bx = b
    mul bx                  ; dx:ax = ax * bx
ENDPROC mul_words

;----------------------------------------------------------------------------
; read_near_ptr - Read a word through a near pointer
;----------------------------------------------------------------------------
; unsigned short read_near_ptr(unsigned short *ptr);
;
; Arguments:
;   [BP+ARG1] = ptr (near pointer, offset only)
;
; Returns: value pointed to in AX
;----------------------------------------------------------------------------
PROC read_near_ptr
    ARG_NEAR_PTR bx, 1      ; bx = ptr (offset)
    mov ax, [bx]            ; ax = *ptr
ENDPROC read_near_ptr

;----------------------------------------------------------------------------
; write_near_ptr - Write a word through a near pointer
;----------------------------------------------------------------------------
; void write_near_ptr(unsigned short *ptr, unsigned short value);
;
; Arguments:
;   [BP+ARG1] = ptr (near pointer)
;   [BP+ARG2] = value
;
; Returns: nothing
;----------------------------------------------------------------------------
PROC write_near_ptr
    ARG_NEAR_PTR bx, 1      ; bx = ptr
    ARG_WORD ax, 2          ; ax = value
    mov [bx], ax            ; *ptr = value
ENDPROC write_near_ptr

;----------------------------------------------------------------------------
; sum_array - Sum elements in a near array
;----------------------------------------------------------------------------
; unsigned short sum_array(unsigned short *arr, unsigned short count);
;
; Arguments:
;   [BP+ARG1] = arr (near pointer to array)
;   [BP+ARG2] = count (number of elements)
;
; Returns: sum in AX
;----------------------------------------------------------------------------
PROC sum_array
    SAVE_SI_DI              ; Preserve SI and DI as required
    
    ARG_NEAR_PTR si, 1      ; si = arr
    ARG_WORD cx, 2          ; cx = count
    
    xor ax, ax              ; ax = 0 (accumulator)
    jcxz .done              ; if count == 0, skip loop
    
.loop:
    add ax, [si]            ; ax += arr[i]
    add si, 2               ; si += sizeof(unsigned short)
    loop .loop              ; decrement cx, loop if not zero
    
.done:
    RESTORE_SI_DI           ; Restore preserved registers
ENDPROC sum_array

;----------------------------------------------------------------------------
; str_length - Calculate length of null-terminated string (near pointer)
;----------------------------------------------------------------------------
; unsigned short str_length(const char *str);
;
; Arguments:
;   [BP+ARG1] = str (near pointer to string)
;
; Returns: length in AX (not including null terminator)
;----------------------------------------------------------------------------
PROC str_length
    SAVE_SI_DI
    
    ARG_NEAR_PTR si, 1      ; si = str
    xor ax, ax              ; ax = 0 (length counter)
    
.loop:
    cmp byte [si], 0        ; if *si == 0
    je .done                ; we're done
    inc ax                  ; length++
    inc si                  ; si++
    jmp .loop
    
.done:
    RESTORE_SI_DI
ENDPROC str_length

;----------------------------------------------------------------------------
; get_max - Return the larger of two unsigned short values
;----------------------------------------------------------------------------
; unsigned short get_max(unsigned short a, unsigned short b);
;
; Arguments:
;   [BP+ARG1] = a
;   [BP+ARG2] = b
;
; Returns: max(a, b) in AX
;----------------------------------------------------------------------------
PROC get_max
    ARG_WORD ax, 1          ; ax = a
    ARG_WORD bx, 2          ; bx = b
    cmp ax, bx              ; compare a and b
    jae .a_is_max           ; if a >= b, a is max
    mov ax, bx              ; else ax = b
.a_is_max:
ENDPROC get_max

;----------------------------------------------------------------------------
; swap_words - Swap two values through near pointers
;----------------------------------------------------------------------------
; void swap_words(unsigned short *a, unsigned short *b);
;
; Arguments:
;   [BP+ARG1] = a (near pointer)
;   [BP+ARG2] = b (near pointer)
;
; Returns: nothing (values swapped in memory)
;----------------------------------------------------------------------------
PROC swap_words
    SAVE_SI_DI
    
    ARG_NEAR_PTR si, 1      ; si = a
    ARG_NEAR_PTR di, 2      ; di = b
    
    mov ax, [si]            ; ax = *a
    mov bx, [di]            ; bx = *b
    mov [si], bx            ; *a = bx
    mov [di], ax            ; *b = ax
    
    RESTORE_SI_DI
ENDPROC swap_words

%if DATA_FAR
;============================================================================
; Far Pointer Functions (only for models with far data)
;============================================================================

;----------------------------------------------------------------------------
; read_far_ptr - Read a word through a far pointer
;----------------------------------------------------------------------------
; unsigned short read_far_ptr(unsigned short far *ptr);
;
; Arguments:
;   [BP+ARG1] = ptr offset
;   [BP+ARG1+2] = ptr segment
;
; Returns: value pointed to in AX
;----------------------------------------------------------------------------
PROC read_far_ptr
    push es                 ; Save ES (scratch but good practice)
    ARG_FAR_PTR_LES bx, 1   ; es:bx = ptr
    mov ax, [es:bx]         ; ax = *ptr
    pop es
ENDPROC read_far_ptr

;----------------------------------------------------------------------------
; write_far_ptr - Write a word through a far pointer
;----------------------------------------------------------------------------
; void write_far_ptr(unsigned short far *ptr, unsigned short value);
;
; Arguments:
;   [BP+ARG1] to [BP+ARG1+2] = ptr (far pointer, 4 bytes)
;   [BP+ARG1+4] = value
;
; Returns: nothing
;----------------------------------------------------------------------------
PROC write_far_ptr
    push es
    ARG_FAR_PTR_LES bx, 1   ; es:bx = ptr
    mov ax, [bp + ARG1 + 4] ; ax = value (after 4-byte far ptr)
    mov [es:bx], ax         ; *ptr = value
    pop es
ENDPROC write_far_ptr

;----------------------------------------------------------------------------
; far_str_length - Calculate length of null-terminated string (far pointer)
;----------------------------------------------------------------------------
; unsigned short far_str_length(const char far *str);
;
; Arguments:
;   [BP+ARG1] = str offset
;   [BP+ARG1+2] = str segment
;
; Returns: length in AX
;----------------------------------------------------------------------------
PROC far_str_length
    push es
    SAVE_SI_DI
    
    ARG_FAR_PTR es, si, 1   ; es:si = str
    xor ax, ax              ; ax = 0
    
.loop:
    cmp byte [es:si], 0
    je .done
    inc ax
    inc si
    jmp .loop
    
.done:
    RESTORE_SI_DI
    pop es
ENDPROC far_str_length

%endif ; DATA_FAR

;============================================================================
; End of sample.asm
;============================================================================
