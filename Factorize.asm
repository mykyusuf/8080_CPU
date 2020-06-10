; 8080 assembler code
        .hexfile Factorize.hex
        .binfile Factorize.com
        ; try "hex" for downloading in hex format
        .download bin  
        .objcopy gobjcopy
        .postbuild echo "OK!"
        ;.nodump

	; OS call list
PRINT_B		equ 4
PRINT_MEM	equ 3
READ_B		equ 7
READ_MEM	equ 2
PRINT_STR	equ 1
READ_STR	equ 8

	; Position for stack pointer
stack   equ 0F000h

	org 000H
	jmp begin

	; Start of our Operating System
GTU_OS:	PUSH D
	push D
	push H
	push psw
	nop	; This is where we run our OS in C++, see the CPU8080::isSystemCall()
		; function for the detail.
	pop psw
	pop h
	pop d
	pop D
	ret
	; ---------------------------------------------------------------
	; YOU SHOULD NOT CHANGE ANYTHING ABOVE THIS LINE        

	;This program adds numbers from 0 to 10. The result is stored at variable
	; sum. The results is also printed on the screen.

begin:
	LXI SP,stack 	; always initialize the stack pointer
			
	MVI A,READ_B
	call GTU_OS

	MOV D,B
	MOV C, B
	MVI E, 0	
	MVI A, PRINT_B
	call GTU_OS	
loop:
	MOV A, D
	DCR C
	
bigger:
	SUB C
	JZ zero
	JNC bigger
	JC loop

zero:
	MOV B, C
	INR E
	MVI A, PRINT_B
	call GTU_OS

	DCR b
	JNZ loop

	hlt
	
	
	