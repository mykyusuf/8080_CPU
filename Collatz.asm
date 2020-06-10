				; 8080 assembler code
        .hexfile Collatz.hex
        .binfile Collatz.com
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
LOAD_EXEC 	equ 5
PROCESS_EXIT	equ 9
SET_QUANTUM 	equ 6
	
	
	; Position for stack pointer
stack   equ 0F000h

	org 000H
	jmp begin

	; Start of our Operating System
GTU_OS:
	DI
	PUSH D
	push D
	push H
	push psw
	nop	; This is where we run our OS in C++, see the CPU8080::isSystemCall()
		; function for the detail.
	pop psw
	pop h
	pop d
	pop D
	EI
	ret
	; ---------------------------------------------------------------
	; YOU SHOULD NOT CHANGE ANYTHING ABOVE THIS LINE        

	;This program adds numbers from 0 to 10. The result is stored at variable
	; sum. The results is also printed on the screen.

NUM equ 25
nl: dw 00AH,00H
space: dw ' ',00H
semi:	dw ' : ',00H
	
begin:
	;; LXI SP,stack 	; always initialize the stack pointer

	LXI B,NUM
	MOV A,C
loop:
	PUSH PSW

	MOV B,A
	MVI A,PRINT_B
	call GTU_OS


	MOV D,B
	LXI B,semi
	MVI A,PRINT_STR
	call GTU_OS
	MOV A,D
	
	call find_collatz

	LXI B,nl
	MVI A,PRINT_STR
	call GTU_OS

	POP PSW
	
	DCR A
	CPI 0
	JNZ loop

	MVI A,PROCESS_EXIT
	call GTU_OS
	

find_collatz:
	CPI 1d
	RZ		;Return if num becomes 1

	PUSH PSW	;Store A for later use
	call is_even	;Stores 1 in B if num in A is even,0 othwerise
	MOV A,B
	CPI 1d		;Compare result with 1
	jz call_handle_even
	jmp call_handle_odd


call_handle_even:	
	POP PSW

	MVI L,2d
	MVI H,0
	jmp handle_even
call_handle_odd:
	POP PSW

	MVI L,2d
	MVI H,0
	jmp handle_odd	
	
print_and_return:
	MOV B,A
	MVI A,PRINT_B
	call GTU_OS


	MOV D,B
	LXI B,space
	MVI A,PRINT_STR
	call GTU_OS	

	MOV A,D
	jmp find_collatz
before_print:
	MOV A,H
	jmp print_and_return
	
handle_even:
	INR H
	CMP L
	JZ before_print
	MVI D,2d
	MOV C,A
	MOV A,L
	ADD D
	MOV L,A
	MOV A,C
	jmp handle_even

	;; Gets the 3*A + 1 in A
handle_odd:
	MOV B,A
	ADD B
	ADD B
	INR A
	jmp print_and_return
	;; MOV A,B
	;; DCR A
	;; CPI 0
	;; jnz find_collatz
	ret
is_even:
	MVI B,2d
	SUB B	;A -> A - 2
	CPI 0d	;Compare A with 0
	jz put_even
	CPI 1d
	jz put_odd
	jmp is_even

	;; put B 1 as stating even
	;; and return
put_even:
	MVI B,1d
	ret
	;; put B 0 as stating odd
	;; and return	
put_odd:
	MVI B,0d
	ret
