;============================================================================
; nls.asm - DOS National Language Support (NLS) Library Implementation
;============================================================================
; Provides NASM implementation of DOS NLS API wrappers using dosazm.inc.
;
; Implements:
;   - INT 21h AH=38h - Get/Set Country Dependent Information
;   - INT 21h AH=65h - Get Extended Country Information (DOS 3.3+)
;   - INT 21h AH=66h - Get/Set Global Code Page (DOS 3.3+)
;   - INT 21h AH=59h - Get Extended Error Information (DOS 3.0+)
;
; Build with:
;   nasm -f obj -DMODEL=SMALL -DCOMPILER=WATCOM nls.asm -o nls.obj
;
; Author: DOS NLS Library
; License: Public Domain
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
; Additional Macros for Mixed-Size Arguments
;============================================================================
; These macros help with functions that have a mix of word and pointer args.
; In far data models, pointers are 4 bytes; words remain 2 bytes.

; Calculate offset for argument N where previous args have specified sizes
; Usage: %define MY_ARG1 ARG_BASE
;        %define MY_ARG2 (MY_ARG1 + 2)   ; after word arg
;        %define MY_ARG3 (MY_ARG2 + DPTR_SIZE)  ; after pointer arg

;============================================================================
; DOS Function Numbers
;============================================================================
%define DOS_GET_COUNTRY        38h    ; AH=38h: Get/Set Country Info
%define DOS_GET_EXT_ERROR      59h    ; AH=59h: Get Extended Error
%define DOS_GET_EXT_COUNTRY    65h    ; AH=65h: Get Extended Country Info
%define DOS_GET_SET_CODEPAGE   66h    ; AH=66h: Get/Set Code Page

;============================================================================
; Subfunction Numbers
;============================================================================
%define NLS_SUBF_GET_GENERAL   01h    ; Get general country info
%define NLS_SUBF_GET_UPPER     02h    ; Get uppercase table ptr
%define NLS_SUBF_GET_LOWER     03h    ; Get lowercase table ptr
%define NLS_SUBF_GET_FN_UPPER  04h    ; Get filename uppercase table ptr
%define NLS_SUBF_GET_FN_TERM   05h    ; Get filename terminator table ptr
%define NLS_SUBF_GET_COLLATE   06h    ; Get collating table ptr
%define NLS_SUBF_GET_DBCS      07h    ; Get DBCS table ptr
%define NLS_SUBF_YESNO         23h    ; Determine yes/no character (DOS 4.0+)

%define CODEPAGE_GET           01h    ; AL=01h: Get code page
%define CODEPAGE_SET           02h    ; AL=02h: Set code page

;============================================================================
; Code Segment
;============================================================================
SEGMENT_CODE

;----------------------------------------------------------------------------
; nls_get_country_info
;----------------------------------------------------------------------------
; Get country-dependent information (INT 21h AH=38h).
;
; C Prototype:
;   nls_word nls_get_country_info(nls_word country_code, 
;                                  NLS_COUNTRY_INFO *info);
;
; Arguments (stack layout):
;   [BP+ARG_BASE+0] = country_code (word)
;   [BP+ARG_BASE+2] = info pointer (near: 2 bytes, far: 4 bytes)
;
; DOS INT 21h AH=38h:
;   Input:
;     AH = 38h
;     AL = 00h for current country, 01h-FEh for specific country code
;     AL = FFh if country code >= 255 (code in BX)
;     BX = country code (if AL=FFh)
;     DS:DX = pointer to 34-byte buffer
;   Output:
;     CF clear: success, buffer filled
;     CF set: AX = error code (02h = invalid country)
;     BX = country code (DOS 3.0+)
;
; Returns: 0 on success, error code on failure
;----------------------------------------------------------------------------
PROC nls_get_country_info
    push ds                     ; Save DS (required to be preserved)
    
    ; Load arguments
    ; Arg1: country_code at [bp + ARG_BASE]
    ; Arg2: info pointer at [bp + ARG_BASE + 2]
    mov ax, [bp + ARG_BASE]     ; ax = country_code
    
%if DATA_FAR
    ; Far data model: info is a far pointer
    lds dx, [bp + ARG_BASE + 2] ; ds:dx = info (far pointer)
%else
    ; Near data model: info is a near pointer
    mov dx, [bp + ARG_BASE + 2] ; dx = info (near pointer, ds unchanged)
%endif

    ; Set up for INT 21h AH=38h
    ; If country_code < 255, use AL=country_code
    ; If country_code >= 255, use AL=FFh, BX=country_code
    cmp ax, 255
    jae .use_extended
    
    ; country_code < 255: use AL directly
    mov ah, DOS_GET_COUNTRY     ; AH = 38h
    ; AL already has country_code (low byte of AX)
    jmp .do_call

.use_extended:
    ; country_code >= 255: use AL=FFh, BX=country_code
    mov bx, ax                  ; BX = country_code
    mov ax, (DOS_GET_COUNTRY << 8) | 0FFh  ; AH=38h, AL=FFh

.do_call:
    int 21h
    
    jc .error                   ; CF set = error
    xor ax, ax                  ; Return 0 for success
    jmp .done
    
.error:
    ; AX already contains error code
    
.done:
    pop ds                      ; Restore DS
ENDPROC nls_get_country_info

;----------------------------------------------------------------------------
; nls_get_country_info_ex
;----------------------------------------------------------------------------
; Get country info for any country code, optionally return actual code.
;
; C Prototype:
;   nls_word nls_get_country_info_ex(nls_word country_code,
;                                     NLS_COUNTRY_INFO *info,
;                                     nls_word *ret_country);
;
; Arguments (near data model):
;   [BP+ARG_BASE+0] = country_code (word)
;   [BP+ARG_BASE+2] = info pointer 
;   [BP+ARG_BASE+2+DPTR_SIZE] = ret_country pointer (can be NULL)
;
; Returns: 0 on success, error code on failure
;----------------------------------------------------------------------------
PROC nls_get_country_info_ex
    push ds
    SAVE_SI_DI
    
    ; Load country_code
    mov ax, [bp + ARG_BASE]     ; ax = country_code
    
%if DATA_FAR
    ; Far pointers: info at +2 (4 bytes), ret_country at +6 (4 bytes)
    lds dx, [bp + ARG_BASE + 2]      ; ds:dx = info
    les si, [bp + ARG_BASE + 6]      ; es:si = ret_country (may be NULL)
    
    ; Check if ret_country is NULL (both offset and segment are 0)
    mov di, es
    or di, si
%else
    ; Near pointers: info at +2 (2 bytes), ret_country at +4 (2 bytes)
    mov dx, [bp + ARG_BASE + 2]      ; dx = info
    mov si, [bp + ARG_BASE + 4]      ; si = ret_country (may be NULL)
    mov di, si                        ; save for NULL check
%endif

    ; Set up for INT 21h AH=38h
    cmp ax, 255
    jae .use_extended
    
    mov ah, DOS_GET_COUNTRY
    jmp .do_call

.use_extended:
    mov bx, ax
    mov ax, (DOS_GET_COUNTRY << 8) | 0FFh

.do_call:
    int 21h
    
    jc .error
    
    ; Success - store returned country code if pointer not NULL
%if DATA_FAR
    ; di contains es | si
    test di, di
%else
    test di, di
%endif
    jz .no_store
    
%if DATA_FAR
    mov [es:si], bx             ; *ret_country = actual country code
%else
    mov [si], bx                ; *ret_country = actual country code
%endif

.no_store:
    xor ax, ax                  ; Return 0 for success
    jmp .done
    
.error:
    ; AX already contains error code
    
.done:
    RESTORE_SI_DI
    pop ds
ENDPROC nls_get_country_info_ex

;----------------------------------------------------------------------------
; nls_set_country
;----------------------------------------------------------------------------
; Set the current country (INT 21h AH=38h with DX=FFFFh).
;
; C Prototype:
;   nls_word nls_set_country(nls_word country_code);
;
; Arguments:
;   [BP+ARG_BASE] = country_code (word)
;
; DOS INT 21h AH=38h (SET):
;   Input:
;     AH = 38h
;     AL = country code (01h-FEh) or FFh if code >= 255
;     BX = country code (if AL=FFh)
;     DX = FFFFh (indicates SET operation)
;   Output:
;     CF clear: success
;     CF set: AX = error code
;
; Returns: 0 on success, error code on failure
;----------------------------------------------------------------------------
PROC nls_set_country
    mov ax, [bp + ARG_BASE]     ; ax = country_code
    mov dx, 0FFFFh              ; DX=FFFFh indicates SET operation
    
    cmp ax, 255
    jae .use_extended
    
    mov ah, DOS_GET_COUNTRY     ; AH = 38h
    jmp .do_call

.use_extended:
    mov bx, ax
    mov ax, (DOS_GET_COUNTRY << 8) | 0FFh

.do_call:
    int 21h
    
    jc .error
    xor ax, ax                  ; Return 0 for success
    jmp .done
    
.error:
    ; AX already contains error code
    
.done:
ENDPROC nls_set_country

;----------------------------------------------------------------------------
; nls_get_ext_country_info
;----------------------------------------------------------------------------
; Get extended country information (INT 21h AX=6501h).
;
; C Prototype:
;   nls_word nls_get_ext_country_info(nls_word country_id,
;                                      nls_word code_page,
;                                      NLS_EXT_COUNTRY_INFO *info,
;                                      nls_word buf_size);
;
; Arguments (near data model):
;   [BP+ARG_BASE+0] = country_id (word)
;   [BP+ARG_BASE+2] = code_page (word)
;   [BP+ARG_BASE+4] = info pointer
;   [BP+ARG_BASE+4+DPTR_SIZE] = buf_size (word)
;
; DOS INT 21h AH=65h AL=01h:
;   Input:
;     AH = 65h
;     AL = 01h (get general info)
;     BX = code page (FFFFh = global)
;     DX = country ID (FFFFh = current)
;     ES:DI = buffer pointer
;     CX = buffer size (>= 5)
;   Output:
;     CF clear: success, CX = size of returned data
;     CF set: AX = error code
;
; Returns: 0 on success, error code on failure
;----------------------------------------------------------------------------
PROC nls_get_ext_country_info
    push es
    SAVE_SI_DI
    
    ; Load arguments
    mov dx, [bp + ARG_BASE]           ; dx = country_id
    mov bx, [bp + ARG_BASE + 2]       ; bx = code_page
    
%if DATA_FAR
    les di, [bp + ARG_BASE + 4]       ; es:di = info (far pointer)
    mov cx, [bp + ARG_BASE + 8]       ; cx = buf_size (after 4-byte ptr)
%else
    mov di, [bp + ARG_BASE + 4]       ; di = info (near pointer)
    push ds
    pop es                             ; es = ds for near model
    mov cx, [bp + ARG_BASE + 6]       ; cx = buf_size
%endif

    mov ax, (DOS_GET_EXT_COUNTRY << 8) | NLS_SUBF_GET_GENERAL
    int 21h
    
    jc .error
    xor ax, ax
    jmp .done
    
.error:
    ; AX already contains error code
    
.done:
    RESTORE_SI_DI
    pop es
ENDPROC nls_get_ext_country_info

;----------------------------------------------------------------------------
; Internal helper: _nls_get_table_ptr
;----------------------------------------------------------------------------
; Common code for getting table pointers (INT 21h AH=65h AL=02h-07h).
;
; Input:
;   AL = subfunction (02h-07h)
;   country_id, code_page, table_ptr on stack
;
; The table pointer functions all have the same signature:
;   nls_word func(nls_word country_id, nls_word code_page, void far **table_ptr);
;
; Stack layout:
;   [BP+ARG_BASE+0] = country_id (word)
;   [BP+ARG_BASE+2] = code_page (word)
;   [BP+ARG_BASE+4] = table_ptr (pointer to far pointer)
;
; DOS returns:
;   ES:DI buffer filled with: info_id (byte) + far pointer (dword)
;
; We extract the far pointer and store it at *table_ptr.
;----------------------------------------------------------------------------

%macro GET_TABLE_PTR_IMPL 1
    ; %1 = subfunction number (02h-07h)
    push es
    SAVE_SI_DI
    
    ; Allocate 8 bytes on stack for DOS buffer
    sub sp, 8
    mov di, sp                         ; DI points to stack buffer
    push ss
    pop es                             ; ES:DI = stack buffer
    
    ; Load arguments
    mov dx, [bp + ARG_BASE]           ; dx = country_id
    mov bx, [bp + ARG_BASE + 2]       ; bx = code_page
    mov cx, 5                          ; buffer size

    mov ax, (DOS_GET_EXT_COUNTRY << 8) | %1
    int 21h
    
    jc .error
    
    ; Success - extract far pointer from buffer and store to table_ptr
    ; Stack buffer contains: [info_id byte][offset word][segment word]
    ; We need to store the far pointer at *table_ptr
    
    ; Read offset and segment from stack buffer
    mov ax, [ss:di + 1]               ; offset (at buffer+1)
    mov cx, [ss:di + 3]               ; segment (at buffer+3)
    
%if DATA_FAR
    ; table_ptr is a far pointer to a far pointer
    les di, [bp + ARG_BASE + 4]       ; es:di = table_ptr
    mov [es:di], ax                    ; store offset
    mov [es:di + 2], cx                ; store segment
%else
    ; table_ptr is a near pointer to a far pointer
    mov di, [bp + ARG_BASE + 4]       ; di = table_ptr
    mov [di], ax                       ; store offset
    mov [di + 2], cx                   ; store segment
%endif

    xor ax, ax                         ; Return 0 for success
    jmp .done
    
.error:
    ; AX already contains error code
    
.done:
    add sp, 8                          ; Free stack buffer
    RESTORE_SI_DI
    pop es
%endmacro

;----------------------------------------------------------------------------
; nls_get_uppercase_table
;----------------------------------------------------------------------------
; Get pointer to uppercase table (INT 21h AX=6502h).
;
; C Prototype:
;   nls_word nls_get_uppercase_table(nls_word country_id,
;                                     nls_word code_page,
;                                     NLS_UPPERCASE_TABLE far **table_ptr);
;----------------------------------------------------------------------------
PROC nls_get_uppercase_table
    GET_TABLE_PTR_IMPL NLS_SUBF_GET_UPPER
ENDPROC nls_get_uppercase_table

;----------------------------------------------------------------------------
; nls_get_lowercase_table
;----------------------------------------------------------------------------
; Get pointer to lowercase table (INT 21h AX=6503h).
; Note: Requires DOS 6.2+ with COUNTRY.SYS
;
; C Prototype:
;   nls_word nls_get_lowercase_table(nls_word country_id,
;                                     nls_word code_page,
;                                     NLS_LOWERCASE_TABLE far **table_ptr);
;----------------------------------------------------------------------------
PROC nls_get_lowercase_table
    GET_TABLE_PTR_IMPL NLS_SUBF_GET_LOWER
ENDPROC nls_get_lowercase_table

;----------------------------------------------------------------------------
; nls_get_filename_upper_table
;----------------------------------------------------------------------------
; Get pointer to filename uppercase table (INT 21h AX=6504h).
;
; C Prototype:
;   nls_word nls_get_filename_upper_table(nls_word country_id,
;                                          nls_word code_page,
;                                          NLS_FILENAME_UPPER_TABLE far **table_ptr);
;----------------------------------------------------------------------------
PROC nls_get_filename_upper_table
    GET_TABLE_PTR_IMPL NLS_SUBF_GET_FN_UPPER
ENDPROC nls_get_filename_upper_table

;----------------------------------------------------------------------------
; nls_get_filename_term_table
;----------------------------------------------------------------------------
; Get pointer to filename terminator table (INT 21h AX=6505h).
;
; C Prototype:
;   nls_word nls_get_filename_term_table(nls_word country_id,
;                                         nls_word code_page,
;                                         NLS_FILENAME_TERM_TABLE far **table_ptr);
;----------------------------------------------------------------------------
PROC nls_get_filename_term_table
    GET_TABLE_PTR_IMPL NLS_SUBF_GET_FN_TERM
ENDPROC nls_get_filename_term_table

;----------------------------------------------------------------------------
; nls_get_collating_table
;----------------------------------------------------------------------------
; Get pointer to collating sequence table (INT 21h AX=6506h).
;
; C Prototype:
;   nls_word nls_get_collating_table(nls_word country_id,
;                                     nls_word code_page,
;                                     NLS_COLLATING_TABLE far **table_ptr);
;----------------------------------------------------------------------------
PROC nls_get_collating_table
    GET_TABLE_PTR_IMPL NLS_SUBF_GET_COLLATE
ENDPROC nls_get_collating_table

;----------------------------------------------------------------------------
; nls_get_dbcs_table
;----------------------------------------------------------------------------
; Get pointer to DBCS lead byte table (INT 21h AX=6507h).
; Note: Requires DOS 4.0+
;
; C Prototype:
;   nls_word nls_get_dbcs_table(nls_word country_id,
;                                nls_word code_page,
;                                NLS_DBCS_TABLE far **table_ptr);
;----------------------------------------------------------------------------
PROC nls_get_dbcs_table
    GET_TABLE_PTR_IMPL NLS_SUBF_GET_DBCS
ENDPROC nls_get_dbcs_table

;----------------------------------------------------------------------------
; nls_get_code_page
;----------------------------------------------------------------------------
; Get the current global code page (INT 21h AX=6601h).
;
; C Prototype:
;   nls_word nls_get_code_page(NLS_CODE_PAGE_INFO *cp_info);
;
; Arguments:
;   [BP+ARG_BASE] = cp_info pointer
;
; DOS INT 21h AX=6601h:
;   Input:
;     AX = 6601h
;   Output:
;     CF clear: BX = active code page, DX = system code page
;     CF set: AX = error code
;
; Returns: 0 on success, error code on failure
;----------------------------------------------------------------------------
PROC nls_get_code_page
    push ds
    SAVE_SI_DI
    
    mov ax, (DOS_GET_SET_CODEPAGE << 8) | CODEPAGE_GET
    int 21h
    
    jc .error
    
    ; Store results to cp_info structure
%if DATA_FAR
    lds si, [bp + ARG_BASE]           ; ds:si = cp_info
    mov [si], bx                       ; cp_info->active_codepage = BX
    mov [si + 2], dx                   ; cp_info->system_codepage = DX
%else
    mov si, [bp + ARG_BASE]           ; si = cp_info
    mov [si], bx                       ; cp_info->active_codepage = BX
    mov [si + 2], dx                   ; cp_info->system_codepage = DX
%endif

    xor ax, ax
    jmp .done
    
.error:
    ; AX already contains error code
    
.done:
    RESTORE_SI_DI
    pop ds
ENDPROC nls_get_code_page

;----------------------------------------------------------------------------
; nls_set_code_page
;----------------------------------------------------------------------------
; Set the global code page (INT 21h AX=6602h).
;
; C Prototype:
;   nls_word nls_set_code_page(nls_word active_codepage,
;                               nls_word system_codepage);
;
; Arguments:
;   [BP+ARG_BASE+0] = active_codepage (word)
;   [BP+ARG_BASE+2] = system_codepage (word)
;
; DOS INT 21h AX=6602h:
;   Input:
;     AX = 6602h
;     BX = active code page
;     DX = system code page
;   Output:
;     CF clear: success
;     CF set: AX = error code
;
; Returns: 0 on success, error code on failure
;----------------------------------------------------------------------------
PROC nls_set_code_page
    mov bx, [bp + ARG_BASE]           ; bx = active_codepage
    mov dx, [bp + ARG_BASE + 2]       ; dx = system_codepage
    
    mov ax, (DOS_GET_SET_CODEPAGE << 8) | CODEPAGE_SET
    int 21h
    
    jc .error
    xor ax, ax
    jmp .done
    
.error:
    ; AX already contains error code
    
.done:
ENDPROC nls_set_code_page

;----------------------------------------------------------------------------
; nls_get_extended_error
;----------------------------------------------------------------------------
; Get extended error information (INT 21h AH=59h BX=0000h).
;
; C Prototype:
;   nls_word nls_get_extended_error(NLS_EXTENDED_ERROR *error_info);
;
; Arguments:
;   [BP+ARG_BASE] = error_info pointer
;
; DOS INT 21h AH=59h:
;   Input:
;     AH = 59h
;     BX = 0000h (version for DOS 3.0+)
;   Output:
;     AX = extended error code (0 = no error)
;     BH = error class
;     BL = suggested action
;     CH = error locus
;     (CL, DX, DI, SI, ES, DS destroyed)
;
; Returns: The extended error code
;
; Note: This function destroys many registers. We save/restore what we need.
;----------------------------------------------------------------------------
PROC nls_get_extended_error
    push ds
    SAVE_SI_DI
    
    ; Save pointer before call (registers will be destroyed)
%if DATA_FAR
    push word [bp + ARG_BASE + 2]     ; Save segment
    push word [bp + ARG_BASE]         ; Save offset
%else
    push word [bp + ARG_BASE]         ; Save pointer
%endif
    
    ; Make the DOS call
    mov ah, DOS_GET_EXT_ERROR
    xor bx, bx                         ; BX = 0000h
    int 21h
    
    ; Save results to error_info structure
    ; AX = error code, BH = class, BL = action, CH = locus
%if DATA_FAR
    pop si                             ; Restore offset
    pop ds                             ; Restore segment (into DS)
    mov [si], ax                       ; error_info->error_code = AX
    mov [si + 2], bh                   ; error_info->error_class = BH
    mov [si + 3], bl                   ; error_info->suggested_action = BL
    mov [si + 4], ch                   ; error_info->error_locus = CH
%else
    pop si                             ; Restore pointer
    mov [si], ax                       ; error_info->error_code = AX
    mov [si + 2], bh                   ; error_info->error_class = BH
    mov [si + 3], bl                   ; error_info->suggested_action = BL
    mov [si + 4], ch                   ; error_info->error_locus = CH
%endif

    ; Return value is the error code (already in AX)
    
    RESTORE_SI_DI
    pop ds
ENDPROC nls_get_extended_error

;----------------------------------------------------------------------------
; nls_uppercase_char
;----------------------------------------------------------------------------
; Convert a character to uppercase using the case map routine.
;
; C Prototype:
;   nls_byte nls_uppercase_char(nls_byte ch);
;
; Arguments:
;   [BP+ARG_BASE] = ch (byte, promoted to word on stack)
;
; This function uses INT 21h AH=65h AL=20h-22h (DOS 4.0+) for capitalizing,
; or gets the case map routine pointer and calls it directly.
;
; For simplicity and compatibility, we use INT 21h AX=6520h which
; capitalizes a single character in DL.
;
; DOS INT 21h AX=6520h (DOS 4.0+):
;   Input:
;     AX = 6520h
;     DL = character to capitalize
;   Output:
;     DL = uppercase character
;
; Returns: Uppercase character in AL
;----------------------------------------------------------------------------
PROC nls_uppercase_char
    mov dl, [bp + ARG_BASE]           ; dl = ch
    
    ; For characters < 80h, use simple ASCII uppercase
    cmp dl, 80h
    jb .ascii_check
    
    ; Extended character - use DOS function
    mov ax, 6520h                      ; AX = 6520h (capitalize char)
    int 21h
    ; DL now contains uppercase character
    jmp .return_dl
    
.ascii_check:
    ; ASCII character - check if lowercase a-z
    cmp dl, 'a'
    jb .return_dl
    cmp dl, 'z'
    ja .return_dl
    ; Convert lowercase to uppercase
    sub dl, 20h                        ; 'a'-'A' = 32 = 20h
    
.return_dl:
    xor ax, ax
    mov al, dl                         ; Return character in AL
ENDPROC nls_uppercase_char

;----------------------------------------------------------------------------
; nls_is_dbcs_lead_byte
;----------------------------------------------------------------------------
; Check if a byte is a DBCS lead byte.
;
; C Prototype:
;   nls_word nls_is_dbcs_lead_byte(nls_byte ch);
;
; Arguments:
;   [BP+ARG_BASE] = ch (byte, promoted to word on stack)
;
; This function gets the DBCS table and checks if ch falls within
; any of the lead byte ranges.
;
; Returns: 1 if DBCS lead byte, 0 otherwise
;----------------------------------------------------------------------------
PROC nls_is_dbcs_lead_byte
    push ds
    push es
    SAVE_SI_DI
    
    ; Allocate 8 bytes on stack for buffer
    sub sp, 8
    mov di, sp
    push ss
    pop es                             ; ES:DI = stack buffer
    
    ; Get the DBCS table pointer
    mov cx, 8
    mov dx, 0FFFFh                     ; Current country
    mov bx, 0FFFFh                     ; Global code page
    mov ax, (DOS_GET_EXT_COUNTRY << 8) | NLS_SUBF_GET_DBCS
    int 21h
    
    jc .not_lead                       ; Error - assume not DBCS
    
    ; Got the table pointer at buffer+1 (4 bytes)
    ; Load it into DS:SI
    lds si, [ss:di + 1]                ; ds:si = DBCS table
    
    ; Table format: [length word][start1][end1][start2][end2]...[0000h]
    ; Check if length is 0 (no DBCS)
    mov cx, [si]                        ; cx = length
    test cx, cx
    jz .not_lead
    
    ; Get the character to check
    mov al, [bp + ARG_BASE]            ; al = ch
    add si, 2                          ; Skip length word
    
.check_loop:
    mov ah, [si]                       ; ah = range start
    test ah, ah                        ; Check for terminator (0)
    jz .not_lead
    mov dl, [si + 1]                   ; dl = range end
    
    ; Check if al >= start && al <= end
    cmp al, ah
    jb .next_range
    cmp al, dl
    jbe .is_lead                       ; Within range - is a lead byte
    
.next_range:
    add si, 2                          ; Move to next range
    jmp .check_loop
    
.is_lead:
    mov ax, 1
    jmp .done
    
.not_lead:
    xor ax, ax
    
.done:
    add sp, 8                          ; Free stack buffer
    RESTORE_SI_DI
    pop es
    pop ds
ENDPROC nls_is_dbcs_lead_byte

;----------------------------------------------------------------------------
; nls_check_yesno_char
;----------------------------------------------------------------------------
; Determine if a character represents a Yes or No response (INT 21h AX=6523h).
;
; C Prototype:
;   nls_word nls_check_yesno_char(nls_byte ch, nls_byte dbcs_trail);
;
; Arguments:
;   [BP+ARG_BASE+0] = ch (byte, promoted to word - character to check)
;   [BP+ARG_BASE+2] = dbcs_trail (byte, promoted to word - DBCS 2nd byte, 0 if single-byte)
;
; DOS INT 21h AX=6523h (DOS 4.0+):
;   Input:
;     AX = 6523h
;     DL = character to check
;     DH = second byte of DBCS character (if applicable, 0 otherwise)
;   Output:
;     CF clear: success
;       AX = type:
;         00h = character represents "No" response
;         01h = character represents "Yes" response
;         02h = character is neither Yes nor No
;     CF set: error
;       AX = error code
;
; Returns:
;   0 (NLS_YESNO_NO) if character is "No"
;   1 (NLS_YESNO_YES) if character is "Yes"
;   2 (NLS_YESNO_NEITHER) if neither
;   >2 = DOS error code on failure
;
; Notes:
;   - Requires DOS 4.0+
;   - The Yes/No characters are country-dependent
;   - Supports DBCS characters for Japanese/Chinese/Korean locales
;   - Supported by Novell DOS 7 (with kernel variant dependency pre-Update 14)
;----------------------------------------------------------------------------
PROC nls_check_yesno_char
    ; Load arguments
    ; ch is at [bp + ARG_BASE] (low byte of word)
    ; dbcs_trail is at [bp + ARG_BASE + 2] (low byte of word)
    
    mov dl, [bp + ARG_BASE]           ; DL = character to check
    mov dh, [bp + ARG_BASE + 2]       ; DH = DBCS trail byte (0 if single-byte)
    
    ; Call INT 21h AX=6523h
    mov ax, (DOS_GET_EXT_COUNTRY << 8) | NLS_SUBF_YESNO
    int 21h
    
    ; On success: CF clear, AX = type (0=no, 1=yes, 2=neither)
    ; On error: CF set, AX = error code
    ; Both cases: AX already has the correct return value
    
ENDPROC nls_check_yesno_char

;============================================================================
; End of nls.asm
;============================================================================
