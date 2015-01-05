;	David Buff
;	CSM30
;	Program 1
;
;	The program emulates a ficticous 16 bit cpu with a set of functions based on opcodes in a binary file.
        .586
        .MODEL flat, stdcall

include Win32API.asm

        .STACK 4096

        .DATA

;---------------------
; EQUATES 
;---------------------

MAX_FILE_NAME_LEN   EQU     256
MAX_RAM             EQU     1024

_CR                 EQU     0Dh
_LF                 EQU     0Ah

;---------------------
;variables
;---------------------

errorFileOpen       byte    "ERROR:  Unable to open input file", _CR, _LF

filename            byte    "c:\machine.bin", 0

ProgramBuffer       byte    MAX_RAM dup (0)        ;max size of RAM 1K

RetCode             dword   0

BytesWritten        dword   0
BytesRead           dword   0
FileHandle          dword   0
FileSize            dword   0

hStdOut             dword   0
hStdIn              dword   0

R                   byte    6  dup(0)           ;ficticious register array

;register use breakdown
;eax - operand 1
;ebx - operand 2
;ecx - temp storage
;edx - opcode retrieval
;edi - program buffer pointer
;esi - index adjuster
;ebp - register array pointer

        .CODE

Main    Proc

        ;*********************************
        ; Get Handle to Standard output
        ;*********************************
        invoke  GetStdHandle, STD_OUTPUT_HANDLE
        mov     hStdOut,eax

        ;*********************************
        ; Get Handle to Standard input
        ;*********************************
        invoke  GetStdHandle, STD_INPUT_HANDLE
        mov     hStdIn,eax

        ;*********************************
        ; Open existing file for Reading
        ;*********************************
        invoke  CreateFileA, offset filename, GENERIC_READ, FILE_SHARE_NONE,\
                             0, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, 0
        cmp     eax,-1                  ;was open successful?
        je      OpenError               ;No....Display error and Exit
        mov     FileHandle,eax          ;Yes...then save file handle

        ;********************************************
        ; Determine the size of the file (in bytes)
        ;********************************************
        invoke  GetFileSize, FileHandle, 0
        mov     FileSize, eax

        ;****************************************
        ; Read the entire file into emulator RAM
        ;****************************************
        invoke  ReadFile, FileHandle, offset ProgramBuffer, FileSize, offset BytesRead, 0
        cmp     eax,0                   ;was it successful?
        ;je      Finish                  ;No...then Exit

        ;*********************************
        ; Close the file
        ;*********************************
        invoke  CloseHandle, FileHandle

        ;jmp Finish

        mov edi, offset ProgramBuffer   ;point to the program buffer with edi
        mov esi, 0                      ;set the index offset to 0
        mov ebp, offset R               ;register array, mostly for debugging

Interpret:
        mov edx, 0                      ;clear a register to hold opcodes
        mov dl, [edi][esi]              ;mov a byte into dh
        cmp dl, 11h                     ;test if it's the add opcode
        je AddCode                      ;if so, jump to the function.
        cmp dl, 22h                     ;check for sub code
        je SubCode                      ;jump to sub code
        cmp dl, 44h                     ;test for xor code
        je XorCode                      ;jump if true
        cmp dl, 05h                     ;test for load code
        je LoadCode                     ;jump as a result
        cmp dl, 55h                     ;check if it's loadr code
        je LoadRCode                    ;jump if it is
        cmp dl, 06h                     ;check the store code
        je StoreCode                    ;jump if it is
        cmp dl, 66h                     ;check for storer code
        je StoreRCode                   ;jump to storer code
        cmp dl, 0CCh                    ;check for out code
        je OutCode                      ;jump to outcode
        cmp dl, 0AAh                    ;check for jnz code
        je JNZCode                      ;go there
        cmp dl, 0FFh                    ;check halt code
        je Finish                       ;jump to finish
        jmp OpenError                   ;if none of the opcodes, there's something wrong.

AddCode: 
        mov eax, 0                      ;clear the register to hold operand 1
        mov ebx, 0                      ;clear the register to hold operand 2
        mov al, [edi][esi + 1]          ;grab operand 1
        mov cl, R[eax]                  ;put the value of the Reg1 operand in temporary storage
        mov bl, [edi][esi + 2]          ;grab operand 2
        add cl, R[ebx]                  ;execute
        mov R[eax], cl                  ;put the result in the fake register
        add esi, 3                      ;increment the index
        jmp Interpret                   ;continue to the next function

SubCode: 
        mov eax, 0                      ;clear the register to hold operand 1
        mov ebx, 0                      ;clear the register to hold operand 2
        mov al, [edi][esi + 1]          ;grab operand 1
        mov cl, R[eax]                  ;put the value of the Reg1 operand in temporary storage
        mov bl, [edi][esi + 2]          ;grab operand 2
        mov ch, R[ebx]
        sub cl, ch                      ;execute
        mov R[eax], cl                  ;put the result in the fake register
        add esi, 3                      ;increment the index
        jmp Interpret                   ;continue to the next function

XorCode:
        mov eax, 0                      ;clear the register to hold operand 1
        mov ebx, 0                      ;clear the register to hold operand 1
        mov ecx, 0                      ;clear the register for temp space
        mov al, [edi][esi + 1]          ;get operand 1
        mov cl, R[eax]                  ;put the first register in temporary storage
        mov bl, [edi][esi + 2]          ;get operand 2
        xor cl, R[ebx]                  ;execute
        mov R[eax], cl                  ;mov result back into register 1
        add esi, 3                      ;increase the index passed the opcode and operands
        jmp Interpret                   ;continue

LoadCode:
        mov eax, 0                      ;clear the register to hold operand 1
        mov ebx, 0                      ;clear the register to hold adress operand
        mov ecx, 0                      ;clear the register for temp storage
        mov al, [edi][esi + 1]          ;put the operand in the register
        mov bh, [edi][esi + 2]          ;put the first part of the address in the register
        mov bl, [edi][esi + 3]          ;put the second part of the address in the register
        mov cl, [edi + ebx]              ;put the value at the memory location in a temp reg
        mov R[eax], cl                  ;mov the value into the reg operand
        add esi, 4                      ;increment the index
        jmp Interpret                   ;continue

LoadRCode:
        mov eax, 0                      ;clear the register to hold operand 1
        mov ebx, 0                      ;clear the register to hold adress operand
        mov ecx, 0                      ;clear the register for temp storage
        mov al, [edi][esi + 1]          ;put the operand in the register
        mov bh, [edi][esi + 2]          ;put the first part of the address in the register
        mov bl, [edi][esi + 3]          ;put the second part of the address in the register
        add bl, R[eax]                  ;add the value in register 1 to the address in memory
        mov cl, [edi + ebx]              ;put the value at the memory location in a temp reg
        mov R[eax], cl                  ;mov the value into the reg operand
        add esi, 4                      ;increment the index
        jmp Interpret                   ;continue

StoreCode:
        mov eax, 0                      ;clear the register to hold operand 1
        mov ecx, 0                      ;clear the register for temp storage
        mov ah, [edi][esi + 1]          ;get the first part of the address
        mov al, [edi][esi + 2]          ;get the second part
        mov cl, R[0]                    ;put the contents of the first register into temp
        mov [edi + eax], cl              ;execute
        add esi, 3                      ;increment
        jmp Interpret                   ;continue

StoreRCode:
        mov eax, 0                      ;clear the register to hold operand 1
        mov ecx, 0                      ;clear the register for temp storage
        mov al, [edi][esi + 1]          ;get the first operand
        mov bh, [edi][esi + 2]          ;get the first part of the address
        mov bl, [edi][esi + 3]          ;get the second part
        mov cl, R[0]                    ;put the contents of the first register into temp
        add bl, R[eax]                  ;add the value of the operand register to the address operand
        mov [edi + ebx], cl             ;execute
        add esi, 4                      ;increment
        jmp Interpret                   ;continue

OutCode:
        mov eax, 0                      ;clear the register to hold operand 1
        mov al, [edi][esi + 1]          ;get operand 1
        invoke  WriteConsoleA, hStdOut, R[eax], SIZEOF R, OFFSET BytesWritten, 0   ;it doesn't output!
        add esi, 2                      ;increment the counter
        jmp Interpret                   ;continue

JNZCode:
        mov eax, 0                      ;clear the register to hold operand 1
        mov al, [edi][esi + 1]          ;get the reg operand
        cmp R[eax], 0                   ;compare the value in the register to 0
        jne JNZContinue                 ;if it is not zero go to the next thing
        add esi, 2                      ;else increment the index
        jmp Interpret                   ;and continue

JNZContinue:
        mov ebx, 0                      ;clear the register to hold adress operand
        mov bh, [edi][esi + 2]          ;get the first byte
        mov bl, [edi][esi + 3]          ;get the second byte of the address
        mov esi, ebx                    ;change the index for the new address
        jmp Interpret                   ;contuinue

OpenError:
        invoke  WriteConsoleA, hStdOut, OFFSET errorFileOpen, SIZEOF errorFileOpen, OFFSET BytesWritten, 0
        jmp finish

Finish:
        ;Terminate Program
        invoke  ExitProcess, RetCode

Main    endp

        END Main