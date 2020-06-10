        ; 8080 assembler code
        .hexfile Palindrome.hex
        .binfile Palindrome.com
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

	;This program prints a null terminated string to the screen
temp    ds 2
string:	dw 'Palindrome',00AH,00H ; null terminated string
string2:dw 'not Palindrome',00AH,00H ; null terminated string

begin:

	LXI SP,stack 	
	MVI B,10
	MVI C,10
	MVI E,9
	MOV A,E
	sta temp
	MVI E,0
	MVI D,0
	
	MVI A,READ_STR
	call GTU_OS
	LDAX B

lp:
	
	MVI B,10
	INR C
	INR D
	LDAX B
	CMP E
	JZ bit
	JMP lp
	
bit:
	MVI E,0
	MOV A,D
	MVI B,10
	MVI C,10

lp2:	
	DCR A
	CMP E
	JZ lp3
	INR C
	JMP lp2
lp3:
	MOV A,D
	DCR D
	CMP E
	JZ cont
	LDAX B
	MOV E,A
	
	lda temp
	ADI 1	
	MVI B,10
	MOV C,A	
	sta temp

	LDAX B

	CMP E
	JNZ not
	JMP bit


cont:	
	
	LXI B, string
	MVI A,PRINT_STR
	call GTU_OS
	hlt

not:
	LXI B, string2
	MVI A,PRINT_STR
	call GTU_OS
	hlt
	
	