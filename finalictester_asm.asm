#make_bin#

; BIN is plain binary format similar to .com format, but not limited to 1 segment;
; All values between # are directives, these values are saved into a separate .binf file.
; Before loading .bin file emulator reads .binf file with the same file name.

; All directives are optional, if you don't need them, delete them.

; set loading address, .bin file will be loaded to this address:
#LOAD_SEGMENT=0000h#
#LOAD_OFFSET=0000h#

; set entry point:
#CS=0000h#	; same as loading segment
#IP=0000h#	; same as loading offset

; set segment registers
#DS=0000h#	; same as loading segment
#ES=0000h#	; same as loading segment

; set stack
#SS=0000h#	; same as loading segment
#SP=FFFEh#	; set to top of loading segment

; set general registers (optional)
#AX=0000h#
#BX=0000h#
#CX=0000h#
#DX=0000h#
#SI=0000h#
#DI=0000h#
#BP=0000h#

; add your code here



JMP STARTPR  ;start of code

        ;data storage		
		;initialise ports
		PORT1A equ 00h
		PORT1B equ 02h
		PORT1C equ 04h
		CREG1  equ 06h
		
		PORT2A equ 10h
		PORT2B equ 12h
		PORT2C equ 14h
		CREG2  equ 16h
		
		;Hexadecimal code for keyboard
	TABLE_K  	db    0eeh, 0edh, 0ebh, 0e7h,       ;0, 1, 2, 3
				db    0deh, 0ddh, 0dBh, 0d7h,       ;4, 5, 6, 7,
				db    0beh, 0bdh, 0bbh, 0b7h,       ;8, 9, Backspace, Enter,
				db    07eh                        	;Test

	    ;Hexadecimal code for display
	TABLE_D     db    0c0h, 0f9h, 0a4h, 0b0h,     	;0, 1, 2, 3,
				db    099h, 092h, 082h, 0f8h,       ;4, 5, 6, 7,
				db    080h, 090h, 08CH, 088h,       ;8, 9, P, A,
				db    092h, 08eh, 0f9h, 0c7h,       ;S, F, I, L

        ;Database for IC 
	IC_NAND   	db '00'
	IC_AND   	db '08'
	IC_OR     	db '32'
	IC_XOR    	db '86'
	IC_XNOR    	db '747266'
	IC_START    db '74'
	
	INPUT 	    db 6 Dup(0)
	INPUT1  	db 6 Dup(0)
	DIGITS	    db 0
	FAIL_D   	db 08eh,088h,0f9h,0c7h ;display of Fail
	PASS_D   	db 08ch,088h,092h,092h ;display of Pass
  
        ;Code starts here
STARTPR:	
	;Initialise 8255 
    ;8255_1
	MOV AL,10001000B
	OUT CREG1,AL
	

	X0:		MOV AL,00H
			OUT PORT1C,AL  ;column input to the keyboard
	X1:                  
	M1:     MOV CH,DIGITS
			MOV AL,00H  
			OUT PORT1B,AL  ;disable display
			CMP CH,00H
			JE K1
			MOV BP,00H
			MOV BH,INPUT1[BP]
			MOV BL,01

	L1:     MOV    AL,00H
			OUT    PORT1B,AL ;disable display
			MOV    AL,BH ;keyboard display value shifted to al
			OUT    PORT1A,AL ;input to the display

			MOV    AL,BL
			OUT    PORT1B,AL ;enable display
			ROL    BL,01
			INC BP
			MOV BH,INPUT1[BP]
			DEC CH
			JNZ L1 ;repeat process till the number of digits entered
			
		    ;check for key release
	K1:       
			IN AL, PORT1C     ;input rows 
			AND AL,0F0H       ;mask lower nibble
			CMP AL,0F0H      ;if key release move ahead or else go back
			JNZ X1  
			
	X2:
	M2:     MOV CH,DIGITS
			MOV AL,00H
			OUT PORT1B,AL ;disable display
			CMP CH,00H
			JE K2
			MOV BP,00H
			MOV    BH,INPUT1[BP]
			MOV    BL,01
	L2:     MOV AL,00H ;repeat the display procedure as L1, as continuous display needed
			OUT PORT1B,AL 
			MOV AL,BH
			OUT PORT1A,AL
			MOV AL,BL
			OUT PORT1B,AL
			ROL BL,01
			INC BP
			MOV BH,INPUT1[BP]
			DEC CH
			JNE L2
	K2:	    MOV AL,00H
			OUT PORT1C,AL   ;Column inputs zero 
			IN AL,PORT1C    ;fetch row output
			AND AL,0F0H   
	        CMP AL,0F0H ;check for key press, if key press then check for which column it is pressed
			JZ X2   
			
            ;check for column number
			MOV AL,0EH ;column 1
			MOV BL,AL
			OUT PORT1C,AL ;input to column
			IN  AL,PORT1C ;check if any row is zero
			AND AL,0F0H   
			CMP AL,0F0H ;if key press then jump to X3
			JNZ X3

			MOV AL,0DH ;column 2
			MOV BL,AL
			OUT PORT1C,AL ;input to column
			IN AL,PORT1C  ;check if any row is zero
			AND AL,0F0H
			CMP AL,0F0H ;if key press then jump to X3
			JNZ X3

			MOV AL,0BH ;column 3
			MOV BL,AL
			OUT PORT1C,AL ;input to column
			IN  AL,PORT1C ;check if any row is zero
			AND AL,0F0H
			CMP AL,0F0H ;if key press then jump to x3
			JNZ X3

			MOV AL, 07H ;column 4
			MOV BL,AL
			OUT PORT1C,AL ;input to column
			IN  AL,PORT1C ;check if any row is zero
			AND AL,0F0H
			CMP AL,0F0H ; if still no key press then false alarm , go back
			JZ X2

	X3:     OR AL,BL ;al contains now row+column
			MOV CX,0CH ;count
			MOV DI,00H
	X4:     CMP AL,TABLE_K[DI] ;keyboard table
			JZ  X5 ;DI will contain location where the entered number is present
			INC DI
			LOOP X4

	X5:     LEA BX,TABLE_D ;display table
		    ; for backspace, enter and test other function to be used
			CMP DI,09
			JA BACK
			CMP DIGITS,06                ;check if the number of digits are less than 6 to take further input
			JE X0
			MOV DL,DIGITS
			MOV DH,00H
			MOV SI,DX ;SI has count of digits
			MOV AX,DI
			ADD AX,'0' ;convert to ascii
			MOV INPUT[SI],AL ;save input value
			MOV AL,TABLE_D[DI]
			MOV INPUT1[SI],AL ;save for display
			INC DIGITS
			JMP X0
			
			;check for backspace,enter and test
	
	BACK:       CMP DI,10                    ;location of backspace key is 10th position
				JNE ENTER_1
				CMP DIGITS,00
				JE X0                        ;to check if digits are more than 0 before pressing backspace
				DEC DIGITS
				JMP X0                       ;go to start again

	ENTER_1:     CMP DI,11                    ;location of enter key is 11th position
				 JNE X0
				;If it is enter, then we take only one key after it, that is the test key
	Y0:	        MOV AL,00H 
				OUT PORT1C,AL ;columns are made 0
	Y1:
	M3:         MOV CH,DIGITS ;display the whole number entered
				CMP CH,00
				JE ZX1
				MOV BP,00
				MOV BH,INPUT1[BP]
				MOV BL,1

	L3:         MOV AL,00
				OUT PORT1B,AL
				MOV AL,BH
				OUT PORT1A,AL
				MOV AL,BL
				OUT PORT1B,AL
				ROL BL,01
				INC BP
				MOV BH,INPUT1[BP]
				DEC CH
				JNZ L3 
	ZX1:
				IN AL, PORT1C ;take row inputs
				AND AL,0F0H
				CMP AL,0F0H ;check for key release
				JNZ Y1
				MOV AL,00H
				OUT PORT1C,AL ;make column inputs 0
	Y2:      
	M4:         MOV CH,DIGITS ;display continues
				CMP CH,00
				JE K3
				MOV BP,00
				MOV    BH,INPUT1[BP]
				MOV    BL,1
	L4:         MOV AL,00
				OUT PORT1B,AL
				MOV    AL,BH
				OUT    PORT1A,AL

				MOV    AL,BL
				OUT    PORT1B,AL
				ROL    BL,1
				INC BP
				MOV    BH,INPUT1[BP]
				DEC CH
				JNZ L4
	K3:
				MOV AL,00H 
				OUT PORT1C,AL ;columns inputs 0
				IN AL,PORT1C
				AND AL,0F0H
				CMP AL,0F0H ;check for testkey press
				JZ Y2

				;repeat the code above

			    ;check for test key
				MOV AL, 0EH ;column number of test key = 1
				MOV BL,AL
				OUT PORT1C,AL
				IN  AL,PORT1C
				AND AL,0F0H
				CMP AL,0F0H ;check if any key is pressed in column 1
				JZ Y2

	Y3:	        OR AL,BL ;al now has rows+columns
				MOV CX,0CH
				MOV DI,00H
				
                ;check for position of key entered
	Y4:	        CMP AL,TABLE_K[DI]
				JZ  Y5
				INC DI
				LOOP Y4
				
				;compare the position with the position of the test key
    Y5:         CMP DI,12
				JNE Y0
				MOV AH,DIGITS
				CMP AH,4 ;if count is 4 then move to check it with 4 word IC
				JE IC_4
				CMP AH,6 ;if count is 6 then move to check it with 6 word IC
				JE IC_6
				JMP FAIL  ;if count is not equal to 4 or 6 then display FAIL
		
		      ;Checking for 4 input IC in the database
	IC_4:          
					MOV CX,02 ;check for the first two digits to be equal to 74
	                MOV BP,00
	W1:				MOV AL,INPUT[BP]
					MOV AH,IC_START[BP]
					INC BP
					CMP AH,AL
					JNE FAIL
					DEC CX
					CMP CX,00
					JNZ W1
					
					MOV CX,02 ;load count
					MOV BP,00
	B1:             MOV AL,INPUT[BP+2] ;keyboard input loaded in al
					MOV AH,IC_NAND[BP]
					INC BP
					CMP AH,AL            ;Check bit by bit for NAND gate
					JNE B2
					DEC CX
					CMP CX,00
					JE TEST_NAND
					JMP B1   
							   
							   
	B2:             MOV BP,00
					MOV CX,02
	B3:             MOV AL,INPUT[BP+2] ;keyboard input loaded in al
					MOV AH,IC_AND[BP] 
					INC BP
					CMP AH,AL            ;Check bit by bit for AND gate
					JNE B4
					DEC CX
					CMP CX,00
					JE TEST_AND
					JMP B3

	B4:             MOV BP,0
					MOV CX,2
	B5:             MOV AL,INPUT[BP+2]  
					MOV AH,IC_OR[BP]
					INC BP
					CMP AH,AL            ;Check bit by bit for OR gate
					JNE B6
					DEC CX
					CMP CX,0
					JE TEST_OR
					JMP B5
					
	B6:             MOV BP,0
					MOV CX,2
	B7:             MOV AL,INPUT[BP+2]
					MOV AH,IC_XOR[BP]
					INC BP
					CMP AH,AL            ;Check bit by bit for XOR gate
					JNE B8
					DEC CX
					CMP CX,0
					JE TEST_XOR
					JMP B7

	B8:             JMP FAIL                ;If none of the IC in the Database match, then fail


;Check the IC number in the 6 Digit IC Database
	IC_6:	        MOV BP,0
			        MOV CX,6
	D9:	            MOV AL,INPUT[BP]
	
					MOV AH,IC_XNOR[BP]
					INC BP
					CMP AH,AL            ;Check bit by bit for XNOR gate
					JNE D10
					DEC CX
					CMP CX,00
					JE TEST_XNOR
					JMP D9

	D10:            JMP FAIL                ;If none of the IC in the Database match, then fail
	
	;To test for AND IC
	TEST_AND:
			;Control reg initialise
			MOV AL,10001010b
			OUT CREG2,AL

			;truth table
			MOV AL,00 ;00 as input
			OUT PORT2A,AL
			OUT PORT2C,AL
			IN AL,PORT2B
			AND AL,3 ;we just want the value of the last two bits, hence and with 3
			CMP AL,00 ;if output not zero then fail
			JNE FAIL
			IN AL,PORT2C 
			AND AL,30H ;here we just need the first two bits, hence and with 30h
			CMP AL,00 ; if output not zero then fail
			JNE FAIL


			MOV AL,1AH ;01 as input
			OUT PORT2A,AL
			MOV AL,2H
			OUT PORT2C,AL
			IN AL,PORT2B
			AND AL,3
			CMP AL,00 ;if output not zero then fail
			JNE FAIL
			IN AL,PORT2C
			AND AL,30H 
			CMP AL,00 ;if output not zero then fail
			JNE FAIL

			MOV AL,25H ;10 as input
			OUT PORT2A,AL
			MOV AL,1H
			OUT PORT2C,AL
			IN AL,PORT2B
			AND AL,3
			CMP AL,00 ;if output not zero then fail
			JNE FAIL
			IN AL,PORT2C
			AND AL,30H
			CMP AL,00 ;if output not zero then fail
			JNE FAIL

			MOV AL,3FH ;11 as input
			OUT PORT2A,AL
			MOV AL,3H
			OUT PORT2C,AL
			IN AL,PORT2B
			AND AL,3
			CMP AL,3 ;if output not 1 then fail
			JNE FAIL
			IN AL,PORT2C
			AND AL,30H
			CMP AL,30H ;if output not 1 then fail
			JNE FAIL

			JMP PASS ;if pass all conditions then display pass
			
			

        ;TO Test for NAND IC
	TEST_NAND:
			;Control reg initialise
			MOV AL,10001010b
			OUT CREG2,AL

            ;truth table
			MOV AL,00 ;00 input
			OUT PORT2A,AL
			OUT PORT2C,AL
			IN AL,PORT2B
			AND AL,3
			CMP AL,3 ;fail if output is not 1
			JNE FAIL
			IN AL,PORT2C
			AND AL,30H
			CMP AL,30H ;fail if output is not 1
			JNE FAIL

			MOV AL,1AH ;01 input
			OUT PORT2A,AL
			MOV AL,2H
			OUT PORT2C,AL
			IN AL,PORT2B
			AND AL,3 
			CMP AL,3 ;fail if output is not 1
			JNE FAIL
			IN AL,PORT2C
			AND AL,30H
			CMP AL,30H ;fail if output is not 1
			JNE FAIL

			MOV AL,25H ;10 input 
			OUT PORT2A,AL
			MOV AL,1H
			OUT PORT2C,AL
			IN AL,PORT2B
			AND AL,3
			CMP AL,3 ;fail if output is not 1
			JNE FAIL
			IN AL,PORT2C
			AND AL,30H
			CMP AL,30H ;fail if output is not 1
			JNE FAIL

			MOV AL,3FH ;11 input and fail if output not 0
			OUT PORT2A,AL
			MOV AL,3H
			OUT PORT2C,AL
			IN AL,PORT2B
			AND AL,3
			CMP AL,0
			JNE FAIL
			IN AL,PORT2C
			AND AL,30H
			CMP AL,0H
			JNE FAIL

			JMP PASS ;pass if all the truth table values match
			
			

      ;Test for OR IC
	TEST_OR: 
	        ;control reg initialise
			MOV AL,10001010b
			OUT CREG2,AL

            ;truth table
			MOV AL,00 ;input 00 and fail if output not 0
			OUT PORT2A,AL
			OUT PORT2C,AL
			IN AL,PORT2B
			AND AL,3
			CMP AL,0
			JNE FAIL
			IN AL,PORT2C
			AND AL,30H
			CMP AL,0H
			JNE FAIL

			MOV AL,1AH ;input 01 and fail if output not 1
			OUT PORT2A,AL
			MOV AL,2H
			OUT PORT2C,AL
			IN AL,PORT2B
			AND AL,3
			CMP AL,3
			JNE FAIL
			IN AL,PORT2C
			AND AL,30H
			CMP AL,30H
			JNE FAIL

			MOV AL,25H ;input 10 and fail if output not 1
			OUT PORT2A,AL
			MOV AL,1H
			OUT PORT2C,AL
			IN AL,PORT2B
			AND AL,3
			CMP AL,3
			JNE FAIL
			IN AL,PORT2C
			AND AL,30H
			CMP AL,30H
			JNE FAIL

			MOV AL,3FH ;input 11 and fail if output not 1
			OUT PORT2A,AL
			MOV AL,3H
			OUT PORT2C,AL
			IN AL,PORT2B
			AND AL,3
			CMP AL,3
			JNE FAIL
			IN AL,PORT2C
			AND AL,30H
			CMP AL,30H
			JNE FAIL

			JMP PASS ;pass if all the truth table values match
			
			

        ;Test for XOR IC
	TEST_XOR:
			;Creg initialise
			MOV AL,10001010b
			OUT CREG2,AL

            ;truth table
			MOV AL,00 ;input 00 and fail if output not 0
			OUT PORT2A,AL
			OUT PORT2C,AL
			IN AL,PORT2B
			AND AL,3
			CMP AL,0
			JNE FAIL
			IN AL,PORT2C
			AND AL,30H
			CMP AL,0H
			JNE FAIL

			MOV AL,1AH ;01 input and fail if output not 1
			OUT PORT2A,AL
			MOV AL,2H
			OUT PORT2C,AL
			IN AL,PORT2B
			AND AL,3
			CMP AL,3
			JNE FAIL
			IN AL,PORT2C
			AND AL,30H
			CMP AL,30H
			JNE FAIL

			MOV AL,25H ;10 input and fail if output not 1
			OUT PORT2A,AL
			MOV AL,1H
			OUT PORT2C,AL
			IN AL,PORT2B
			AND AL,3
			CMP AL,03
			JNE FAIL
			IN AL,PORT2C
			AND AL,30H
			CMP AL,30H
			JNE FAIL

			MOV AL,3FH ;11 input and fail if output not 0
			OUT PORT2A,AL
			MOV AL,3H
			OUT PORT2C,AL
			IN AL,PORT2B
			AND AL,3
			CMP AL,0
			JNE FAIL
			IN AL,PORT2C
			AND AL,30H
			CMP AL,0H
			JNE FAIL

			JMP PASS ;pass if all truth table values match
			
			

         ;Test for XNOR IC
	TEST_XNOR:
			;control reg initialise
			MOV AL,10000011b
			OUT CREG2,AL
			
			;truth table intialisation
			MOV AL,00 ;input 00 and fail if output not equal to 1
			OUT PORT2A,AL
			OUT PORT2C,AL
			IN AL,PORT2B
			AND AL,3
			CMP AL,3
			JNE FAIL
			IN AL,PORT2C
			AND AL,3H
			CMP AL,3H
			JNE FAIL

			MOV AL,1AH ;input 01 and fail if output not equal to 0
			OUT PORT2A,AL
			MOV AL,20H
			OUT PORT2C,AL
			IN AL,PORT2B
			AND AL,3
			CMP AL,0
			JNE FAIL
			IN AL,PORT2C
			AND AL,3H
			CMP AL,0H
			JNE FAIL

			MOV AL,25H ;input 10 and fail if output not equal to 0
			OUT PORT2A,AL
			MOV AL,10H
			OUT PORT2C,AL
			IN AL,PORT2B
			AND AL,3
			CMP AL,0
			JNE FAIL
			IN AL,PORT2C
			AND AL,3H
			CMP AL,0H
			JNE FAIL

			MOV AL,3FH ;input 11 and fail if output not equal to 1
			OUT PORT2A,AL
			MOV AL,30H
			OUT PORT2C,AL
			IN AL,PORT2B
			AND AL,3
			CMP AL,3
			JNE FAIL
			IN AL,PORT2C
			AND AL,3H
			CMP AL,3H
			JNE FAIL

			JMP PASS ;pass if all truth table values match




        ;To display FAIL
	FAIL:
			MOV DI,5000 ;repeat process for this much time
	A2:     MOV CH,4 ;load count value
			MOV BP,0

			MOV BH,FAIL_D[BP]
			MOV BL,1

	A1:     MOV AL,0
			OUT PORT1B,AL
			MOV AL,BH
			OUT PORT1A,AL

			MOV AL,BL
			OUT PORT1B,AL
			ROL BL,1
			INC BP
			MOV BH,FAIL_D[BP]
			DEC CH
			JNZ A1
			DEC DI
			JNZ A2

			MOV AL,0
			MOV DIGITS,AL
			JMP STARTPR

			
			
        ;To display PASS
	PASS:
			MOV DI,5000h ;repeat the process this much times
			
	A3:     MOV CH,4
			MOV BP,0

			MOV BH,PASS_D[BP]
			MOV BL,1

	A4:     MOV AL,0
			OUT PORT1B,AL
			MOV AL,BH
			OUT PORT1A,AL
			MOV AL,BL
			OUT PORT1B,AL
			ROL BL,1
			INC BP
			MOV BH,PASS_D[BP]
			DEC CH
			JNZ A4
			DEC DI
			JNZ A3

			MOV AL,0
			MOV DIGITS,AL
			JMP STARTPR














HLT           ; halt!


