				; 8080 assembler code
	        .hexfile Primes.hex
	        .binfile Primes.com
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
PRINT_WHOLE	equ 10d	
	
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

NUM equ 255
nl: dw 00AH
prime:	dw ' prime',00H
mem: dw 'a',00H

	;; print 0 and 1
	;; initialize other registers
initial:
	LXI B,0
	MVI A,PRINT_B
	call GTU_OS
	
	LXI B,nl
	MVI A,PRINT_STR
	call GTU_OS

	MVI B,1
	MVI A,PRINT_B
	call GTU_OS
	
	LXI B,nl
	MVI A,PRINT_STR
	call GTU_OS
	
	LXI B,num
	LXI D,2
	ret
	

begin:
	;; LXI SP,stack
				;always initialize the stack pointer
	call initial

	
	;; main label to go through
	;; from 0 to 1000
main:
	PUSH D
	MVI A,0

	MOV B,D
	MOV C,E
	call print_num
	POP D

	MOV B,D			
	MOV C,E
	
	MVI H,0
	MVI L,1
	call is_prime		

	LXI B,nl
	MVI A,PRINT_STR
	call GTU_OS
	LXI B,num
	
	MOV A,D
	INX D
	CMP B
	JNZ main

	MOV A,E
	CMP C
	JNZ main
	JMP exit

;; BC stores current number
;; HL stores counter
is_prime:
	INX H

	MOV A,H
	CMP B
	JNZ is_prime_c

	MOV A,L
	CMP C
	JNZ is_prime_c
	jmp print_prime

;; 
print_prime:
	LXI B,prime
	MVI A,PRINT_STR
	call GTU_OS
	ret

;; continue for is_prime
is_prime_c:	
	
	PUSH B
	PUSH H
	PUSH D
	call prime_helper

	MVI A,0
	CMP H
	JNZ is_prime_cont

	CMP L
	JNZ is_prime_cont

	POP D
	POP H
	POP B
	ret
;; check if counter is bigger than or equal to number
is_prime_cont:	
	POP D
	POP H
	POP B
	
	MOV A,H
	CMP B

	JNZ is_prime

	MOV A,L
	CMP C
	JNZ is_prime
	ret
;; divide the number stored in DE
;; by BC
prime_helper:
	MOV D,B
	MOV E,C
	MOV B,H
	MOV C,L
	call division
	ret
;; print the number
print_num:
	MOV H,A	;move the counter to store
	
	MOV A,B
	CPI 0
	JNZ print_helper

	MOV A,C
	CPI 0
	JNZ print_helper

	MOV A,H
	jmp print
	;; calculate modulo by 10
	;; push it to stack for later use
print_helper:	
	MOV D,B
	MOV E,C
	
	LXI B,10

	INR H
	PUSH H	;increase and store counter
	
	call division

	POP D
	MOV A,D	;store back the counter

	MOV H,L
	MVI L,0	
	PUSH H	;push the remainder to print

	JMP print_num
	;; return label
return:
	ret
;; print the number using helpers
print:
	CPI 0
	JZ return
	POP B	;get the next digit

	
	DCR A
	MOV D,A ;store counter

	MVI A,PRINT_B
	call GTU_OS

	MOV A,D
	JMP print
	
	
;;; 	------
;;;	division code is taken from
;;;	geeksforgeeks
;;;	------
division:
	MOV H,B	;divisor previously stored in BC
	MOV L,C
	
	;POP H			
	;MVI L,128		

	MOV B,D	;hide quotient
	MOV C,E
	
	XCHG
	
	MOV H,B	;quotient previously stored in BC
	MOV L,C

	LXI B,0000H

	;POP H
	;LXI H,num		
	call loop
	ret
loop:
	MOV A,L
	SUB E
	MOV L,A

	MOV A,H
	SBB D
	MOV H,A

	JC label
	INX B
	JMP loop
	
label:
	DAD D
	SHLD mem
	ret
	
exit:		
	MVI A,0
	LXI B,NUM
	call print_num

	LXI B,nl
	MVI A,PRINT_STR
	call GTU_OS

	
	MVI A,PROCESS_EXIT
	call GTU_OS

