TITLE AES-128
COMMENT *Uses the Advanced Encryption Standard with 128 bit cipher keys
		to encrypt and decrypt a 128 bit message*
.MODEL FLAT,STDCALL
.STACK 4096

; ------------------------------------ Windows Console API Calls Function Declarations ------------------------------------
				; Function calls to the Windows Console system, in order to display on screen
				; the key, plaintext, cipher, and decrypted message
STD_OUTPUT_HANDLE EQU -11
GetStdHandle PROTO, nStdHandle:DWORD						; declaring functions to be used
SetConsoleMode PROTO, hConsoleHandle:DWORD, dwMode:DWORD	
WriteConsoleA PROTO, handle:DWORD, lpBuffer:PTR BYTE, nNumberOfCharsToWrite:DWORD, lpNumberOfCharsWritten:PTR DWORD, lpReserved:DWORD
ExitProcess PROTO, dwExitCode:DWORD

.data
; ------------------------------------ Windows Console API Calls Data ------------------------------------
				; Data used as parameters for the function calls into the Windows Console system
dw_mode DWORD 1
console_out_handle DWORD ?
bytes_written DWORD ?
plaintext_message_start DB "PLAINTEXT BYTES: "
plaintext_message_start_length DD 17
plaintext_message_content BYTE 32 DUP(?)
plaintext_message_content_length DD 32
key_message_start DB	"KEY BYTES:       ";
key_message_start_length DD 17
key_message_content BYTE 32 DUP(?)
key_message_content_length DD 32
cipher_message_start DB "ENCRYPTED BYTES: "
cipher_message_start_length DD 17
cipher_message_content BYTE 32 DUP(?)
cipher_message_content_length DD 32
decrypted_text_message_start DB "DECRYPTED BYTES: "
decrypted_text_message_start_length DD 17
decrypted_text_message_content BYTE 32 DUP(?)
decrypted_text_message_content_length DD 32
carriage_return_new_line DB 13, 10
carriage_return_new_line_length DD 2

; ------------------------------------------------ AES-128 Data ------------------------------------------------
				; Data for the substitution tables, the raw hex to ascii conversion, and 
				; the AES-128 algorithm
PLAINTEXT DWORD 0E2BEC16BH, 0969F402EH, 0117E3DE9H, 02A179373H
KEY DWORD		016157E2BH, 0A6D2AE28H, 08815F7ABH, 03C4FCF09H

PLAINTEXT_ASCII BYTE 32 DUP(?)
KEY_ASCII BYTE 32 DUP(?)
EXPANDED_KEY BYTE 16*11 DUP(?)
CIPHER BYTE 16 DUP(?)
CIPHER_ASCII BYTE 32 DUP(?)
DECRYPTED_TEXT BYTE 16 DUP(?)
DECRYPTED_TEXT_ASCII BYTE 32 DUP(?)
HEX_TO_ASCII BYTE 030H, 031H, 032H, 033H, 034H, 035H, 036H, 037H, 038H, 039H, 041H, 042H, 043H, 044H, 045H, 046H
ROUND_CONST DWORD 08040201H, 80402010H, 0000361BH
F_SBOX_01 QWORD 0C56F6BF27B777C63H, 076ABD7FE2B670130H, 0F04759FA7DC982CAH, 0C072A49CAFA2D4ADH
F_SBOX_23 QWORD 0CCF73F362693FDB7H, 01531D871F1E5A534H, 09A059618C323C704H, 075B227EBE2801207H
F_SBOX_45 QWORD 0A05A6E1B1A2C8309H, 0842FE329B3D63B52H, 05BB1FC20ED00D153H, 0CF584C4A39BECB6AH
F_SBOX_67 QWORD 085334D43FBAAEFD0H, 0A89F3C507F02F945H, 0F5389D928F40A351H, 0D2F3FF1021DAB6BCH
F_SBOX_89 QWORD 01744975FEC130CCDH, 073195D643D7EA7C4H, 088902A22DC4F8160H, 0DB0B5EDE14B8EE46H
F_SBOX_AB QWORD 05C2406490A3A32E0H, 079E4959162ACD3C2H, 0A94ED58D6D37C8E7H, 008AE7A65EAF4566CH
F_SBOX_CD QWORD 0C6B4A61C2E2578BAH, 08A8BBD4B1F74DDE8H, 00EF6034866B53E70H, 09E1DC186B9573561H
F_SBOX_EF QWORD 0948ED9691198F8E1H, 0DF2855CEE9871E9BH, 06842E6BF0D89A18CH, 016BB54B00F2D9941H
FWD_SBOX_ADDR DWORD F_SBOX_01, F_SBOX_23, F_SBOX_45, F_SBOX_67, F_SBOX_89, F_SBOX_AB, F_SBOX_CD, F_SBOX_EF
FWD_SBOX BYTE 256 DUP(?)
I_SBOX_01 QWORD 038A53630D56A0952H, 0FBD7F3819EA340BFH, 087FF2F9B8239E37CH, 0CBE9DEC444438E34H
I_SBOX_23 QWORD 03D23C2A632947B54H, 04EC3FA420B954CEEH, 0B224D92866A12E08H, 025D18B6D49A25B76H
I_SBOX_45 QWORD 01698688664F6F872H, 092B6655DCC5CA4D4H, 0DAB9EDFD5048706CH, 0849D8DA75746155EH
I_SBOX_67 QWORD 00AD3BC8C00ABD890H, 00645B3B80558E4F7H, 0020F3FCA8F1E2CD0H, 06B8A130103BDAFC1H
I_SBOX_89 QWORD 0EADC674F4111913AH, 073E6B4F0CECFF297H, 08535ADE72274AC96H, 06EDF751CE837F9E2H
I_SBOX_AB QWORD 089C5291D711AF147H, 01BBE18AA0E62B76FH, 02079D2C64B3E56FCH, 0F45ACD78FEC0DB9AH
I_SBOX_CD QWORD 031C7078833A8DD1FH, 05FEC8027591012B1H, 00D4AB519A97F5160H, 0EF9CC9939F7AE52DH
I_SBOX_EF QWORD 0B0F52AAE4D3BE0A0H, 0619953833CBBEBC8H, 026D677BA7E042B17H, 07D0C2155631469E1H
INV_SBOX_ADDR DWORD I_SBOX_01, I_SBOX_23, I_SBOX_45, I_SBOX_67, I_SBOX_89, I_SBOX_AB, I_SBOX_CD, I_SBOX_EF
INV_SBOX BYTE 256 DUP(?)

.code
main proc
; ------------------------ SET UP STEP ------------------------
CALL SETUP_SBOXES       ; Set Up Substitution Boxes
CALL GEN_EXPANDED_KEY   ; Set Up Expanded Key

; ------------------------ ENCRYPTION STEP ------------------------
     MOV EAX, DWORD PTR PLAINTEXT[00H]     ; Set Up Intermediate State
     MOV EBX, DWORD PTR PLAINTEXT[04H]
     MOV ECX, DWORD PTR PLAINTEXT[08H]
     MOV EDX, DWORD PTR PLAINTEXT[0CH]
     MOV DWORD PTR CIPHER[00H], EAX
     MOV DWORD PTR CIPHER[04H], EBX
     MOV DWORD PTR CIPHER[08H], ECX
     MOV DWORD PTR CIPHER[0CH], EDX
     MOV ESI, 0                            ; Initial Round (ROUND KEY 0)
     CALL XOR_STATE_AND_ROUND_KEY
     MOV ECX, 0H                           ; Intermediate Rounds (ROUND KEY 1 TO 9)
ROUND_LOOP:  INC ECX
             MOV ESI, ECX
             CALL SUBSTITUTE_STATE_BYTES	
             CALL ROW_SHIFT_STATE_BYTES	
             CALL COLUMN_MIX_STATE_BYTES	
             CALL XOR_STATE_AND_ROUND_KEY
             CMP ECX, 9H
             JL ROUND_LOOP
     CALL SUBSTITUTE_STATE_BYTES          ; Final Round (ROUND KEY 10)
     CALL ROW_SHIFT_STATE_BYTES
     MOV ESI, 0AH
     CALL XOR_STATE_AND_ROUND_KEY

; ------------------------ DECRYPTION STEP ------------------------
     MOV EAX, DWORD PTR CIPHER[00H]       ; Set Up Inverse Intermediate State
     MOV EBX, DWORD PTR CIPHER[04H]
     MOV ECX, DWORD PTR CIPHER[08H]
     MOV EDX, DWORD PTR CIPHER[0CH]
     MOV DWORD PTR DECRYPTED_TEXT[00H], EAX
     MOV DWORD PTR DECRYPTED_TEXT[04H], EBX
     MOV DWORD PTR DECRYPTED_TEXT[08H], ECX
     MOV DWORD PTR DECRYPTED_TEXT[0CH], EDX
      
     MOV ESI, 0AH                         ; Invert Final Round
     CALL XOR_DECRYPT_STATE_AND_ROUND_KEY
     CALL INV_ROW_SHIFT_BYTES
     CALL INV_SUBSTITUTE_BYTES
     MOV ECX, 0AH                         ; Invert Intermediate Rounds
INV_ROUND_LOOP:	DEC ECX
                MOV ESI, ECX
                CALL XOR_DECRYPT_STATE_AND_ROUND_KEY
                CALL INV_COLUMN_MIX_BYTES
                CALL INV_ROW_SHIFT_BYTES
                CALL INV_SUBSTITUTE_BYTES
                CMP ECX, 1H
                JG INV_ROUND_LOOP
      MOV ESI, 0                          ; Invert Initial Round
      CALL XOR_DECRYPT_STATE_AND_ROUND_KEY

		; ------------------------------------------   Windows Console API Calls   ---------------------------------------------------------------------------
				invoke GetStdHandle, STD_OUTPUT_HANDLE	; places the value of the output handle in EAX, https://learn.microsoft.com/en-us/windows/console/getstdhandle
				MOV console_out_handle, EAX
				MOV EDX, offset plaintext_message_start
				MOV EAX, plaintext_message_start_length
				invoke WriteConsoleA, console_out_handle, EDX, EAX, offset bytes_written, 0	; https://learn.microsoft.com/en-us/windows/console/writeconsole
				CALL CONVERT_PLAINTEXT_TO_ASCII
				MOV EDX, offset PLAINTEXT_ASCII
				MOV EAX, plaintext_message_content_length
				invoke WriteConsoleA, console_out_handle, EDX, EAX, offset bytes_written, 0
				MOV EDX, offset carriage_return_new_line
				MOV EAX, carriage_return_new_line_length
				invoke WriteConsoleA, console_out_handle, EDX, EAX, offset bytes_written, 0
				MOV EDX, offset carriage_return_new_line
				MOV EAX, carriage_return_new_line_length
				invoke WriteConsoleA, console_out_handle, EDX, EAX, offset bytes_written, 0
				MOV EDX, offset key_message_start
				MOV EAX, key_message_start_length
				invoke WriteConsoleA, console_out_handle, EDX, EAX, offset bytes_written, 0
				CALL CONVERT_KEY_TO_ASCII
				MOV EDX, offset KEY_ASCII
				MOV EAX, key_message_content_length
				invoke WriteConsoleA, console_out_handle, EDX, EAX, offset bytes_written, 0
				MOV EDX, offset carriage_return_new_line
				MOV EAX, carriage_return_new_line_length
				invoke WriteConsoleA, console_out_handle, EDX, EAX, offset bytes_written, 0
				MOV EDX, offset carriage_return_new_line
				MOV EAX, carriage_return_new_line_length
				invoke WriteConsoleA, console_out_handle, EDX, EAX, offset bytes_written, 0
				MOV EDX, offset cipher_message_start
				MOV EAX, cipher_message_start_length
				invoke WriteConsoleA, console_out_handle, EDX, EAX, offset bytes_written, 0
				CALL CONVERT_NIBBLES_TO_ASCII
				MOV EDX, offset CIPHER_ASCII
				MOV EAX, cipher_message_content_length
				invoke WriteConsoleA, console_out_handle, EDX, EAX, offset bytes_written, 0
				MOV EDX, offset carriage_return_new_line
				MOV EAX, carriage_return_new_line_length
				invoke WriteConsoleA, console_out_handle, EDX, EAX, offset bytes_written, 0
				MOV EDX, offset carriage_return_new_line
				MOV EAX, carriage_return_new_line_length
				invoke WriteConsoleA, console_out_handle, EDX, EAX, offset bytes_written, 0
				MOV EDX, offset decrypted_text_message_start
				MOV EAX, decrypted_text_message_start_length
				invoke WriteConsoleA, console_out_handle, EDX, EAX, offset bytes_written, 0
				CALL CONVERT_DECRYPT_NIBBLES_TO_ASCII
				MOV EDX, offset DECRYPTED_TEXT_ASCII
				MOV EAX, decrypted_text_message_content_length
				invoke WriteConsoleA, console_out_handle, EDX, EAX, offset bytes_written, 0
				MOV EDX, offset carriage_return_new_line
				MOV EAX, carriage_return_new_line_length
				invoke WriteConsoleA, console_out_handle, EDX, EAX, offset bytes_written, 0

				invoke ExitProcess, 0


SETUP_SBOXES PROC NEAR	; Set Up Substitution Tables
     MOV ESI, 0         ; index for source     ; Set Up Forward Substitution Box
     MOV EBX, 0         ; index for addresses			
ADDR_LOOP:     MOV EAX, DWORD PTR FWD_SBOX_ADDR[EBX]
               MOV EDI, 0   ; index for destination
  MOVE_LOOP:        MOV ECX, DWORD PTR [EAX + EDI]
                    MOV DWORD PTR FWD_SBOX[ESI], ECX
                    ADD EDI, 04H
                    ADD ESI, 04H
                    CMP EDI, 1CH
                    JLE MOVE_LOOP
               ADD EBX, 04H
               CMP EBX, 1CH
               JLE ADDR_LOOP
     MOV ESI, 0          ; index for source    ; Set Up Inverse Substitution Box
     MOV EBX, 0          ; index for addresses			
INV_ADDR_LOOP: MOV EAX, DWORD PTR INV_SBOX_ADDR[EBX]
               MOV EDI, 0    ; index for destination
     INV_M_LOOP:    MOV ECX, DWORD PTR [EAX + EDI]
                    MOV DWORD PTR INV_SBOX[ESI], ECX
                    ADD EDI, 04H
                    ADD ESI, 04H
                    CMP EDI, 1CH
                    JLE INV_M_LOOP
               ADD EBX, 04H
               CMP EBX, 1CH
               JLE INV_ADDR_LOOP
     RET
SETUP_SBOXES ENDP

GEN_EXPANDED_KEY PROC NEAR
     MOV EAX, DWORD PTR KEY[00H] ; the key is round key 0
     MOV EBX, DWORD PTR KEY[04H]
     MOV ECX, DWORD PTR KEY[08H]
     MOV EDX, DWORD PTR KEY[0CH]
     MOV DWORD PTR EXPANDED_KEY[0H + 00H], EAX
     MOV DWORD PTR EXPANDED_KEY[0H + 04H], EBX
     MOV DWORD PTR EXPANDED_KEY[0H + 08H], ECX
     MOV DWORD PTR EXPANDED_KEY[0H + 0CH], EDX
     MOV ECX, 028H ; CX = 39->0     (39 -> 0) INCLUSIVE
EXPAND_LOOP:   MOV EDX, 02CH       ; DX = i     (4 -> 43) INCLUSIVE
               SUB EDX, ECX			
               MOV EAX, EDX
               AND EAX, 00000003H  ; AND with 3, and if there's anything 
               MOV EBX, EDX        ;      left over, that's the remainder after modulo 4
               SHL EBX, 2          ; EBX is i*4
               CMP EAX, 0          ; if (i % 4 == 0) go to 2nd case else go to default case
               JZ SECOND_CASE
DEFAULT_CASE:  PUSH ECX
               MOV EAX, DWORD PTR EXPANDED_KEY[EBX - 004H]
               MOV ECX, DWORD PTR EXPANDED_KEY[EBX - 010H]
               XOR EAX, ECX
               MOV DWORD PTR EXPANDED_KEY[EBX], EAX
               POP ECX
               JMP EXPND_LOOP_END
SECOND_CASE:   MOV EAX, DWORD PTR EXPANDED_KEY[EBX - 004H]
               ROR EAX, 08H        ; Rotate word
               PUSH ECX
               MOV ECX, 0          ; Substitute word
               MOV CL, AL
               MOV AL, BYTE PTR FWD_SBOX[ECX]					
               ROR EAX, 08H
               MOV CL, AL
               MOV AL, BYTE PTR FWD_SBOX[ECX]
               ROR EAX, 08H
               MOV CL, AL
               MOV AL, BYTE PTR FWD_SBOX[ECX]
               ROR EAX, 08H
               MOV CL, AL
               MOV AL, BYTE PTR FWD_SBOX[ECX]
               ROR EAX, 08H
               MOV ECX, DWORD PTR EXPANDED_KEY[EBX - 010H]   ; XOR first and second term
               XOR EAX, ECX
               MOV ECX, EDX
               SHR ECX, 2
               DEC ECX
               PUSH EBX
               MOV EBX, 0                                    ; XOR result with third term
               MOV BL, BYTE PTR ROUND_CONST[ECX]
               XOR EAX, EBX
               POP EBX
               POP ECX
               MOV DWORD PTR EXPANDED_KEY[EBX], EAX          ; Store result
EXPND_LOOP_END:DEC ECX
               CMP ECX, 0
               JNE EXPAND_LOOP
               RET
GEN_EXPANDED_KEY ENDP

XOR_STATE_AND_ROUND_KEY PROC NEAR ; preload ESI with round key number
     PUSHAD
     MOV EBX, 0
     SHL ESI, 4
XOR_LOOP: MOV EAX, DWORD PTR CIPHER[EBX]
          MOV ECX, DWORD PTR EXPANDED_KEY[ESI + EBX]
          XOR EAX, ECX
          MOV DWORD PTR CIPHER[EBX], EAX
          ADD EBX, 04H
          CMP EBX, 0CH
          JLE XOR_LOOP
     POPAD
     RET
XOR_STATE_AND_ROUND_KEY ENDP

XOR_DECRYPT_STATE_AND_ROUND_KEY PROC NEAR ; preload ESI with round key number
     PUSHAD
     MOV EBX, 0
     SHL ESI, 4
DEC_XOR_LOOP: MOV EAX, DWORD PTR DECRYPTED_TEXT[EBX]
              MOV ECX, DWORD PTR EXPANDED_KEY[ESI + EBX]
              XOR EAX, ECX
              MOV DWORD PTR DECRYPTED_TEXT[EBX], EAX
              ADD EBX, 04H
              CMP EBX, 0CH
              JLE DEC_XOR_LOOP
     POPAD
     RET
XOR_DECRYPT_STATE_AND_ROUND_KEY ENDP

SUBSTITUTE_STATE_BYTES PROC NEAR
     PUSHAD
     MOV EBX, 0
SUB_LOOP: MOV EAX, 0
          MOV AL, BYTE PTR CIPHER[EBX]
          MOV AL, BYTE PTR FWD_SBOX[EAX]
          MOV BYTE PTR CIPHER[EBX], AL
          INC EBX
          CMP EBX, 0FH
          JLE SUB_LOOP
     POPAD
     RET
SUBSTITUTE_STATE_BYTES ENDP

INV_SUBSTITUTE_BYTES PROC NEAR
     PUSHAD
     MOV EBX, 0
INV_SUB_LOOP: MOV EAX, 0
              MOV AL, BYTE PTR DECRYPTED_TEXT[EBX]
              MOV AL, BYTE PTR INV_SBOX[EAX]
              MOV BYTE PTR DECRYPTED_TEXT[EBX], AL
              INC EBX
              CMP EBX, 0FH
              JLE INV_SUB_LOOP
     POPAD
     RET
INV_SUBSTITUTE_BYTES ENDP

ROW_SHIFT_STATE_BYTES PROC NEAR
     PUSHAD
     MOV EAX, DWORD PTR CIPHER[00H] ; EAX: [ b0  b1  b2  b3 ] -> EAX: [ b0  b5  bA  bB ]
     MOV EBX, DWORD PTR CIPHER[04H] ; EBX: [ b4  b5  b6  b7 ] -> EBX: [ b4  b9  bE  bF ]
     MOV ECX, DWORD PTR CIPHER[08H] ; ECX: [ b8  b9  bA  bB ] -> ECX: [ b8  bD  b2  b3 ]
     MOV EDX, DWORD PTR CIPHER[0CH] ; EDX: [ bC  bD  bE  bF ] -> EDX: [ bC  b1  b6  b7 ]
     ROR EAX, 8H								
     ROR EBX, 8H								
     ROR ECX, 8H								
     ROR EDX, 8H								
     MOV BYTE PTR CIPHER[0DH], AL
     MOV BYTE PTR CIPHER[0AH], AH
     MOV BYTE PTR CIPHER[01H], BL
     MOV BYTE PTR CIPHER[0EH], BH
     MOV BYTE PTR CIPHER[05H], CL
     MOV BYTE PTR CIPHER[02H], CH
     MOV BYTE PTR CIPHER[09H], DL
     MOV BYTE PTR CIPHER[06H], DH
     ROR EAX, 010H							
     ROR EBX, 010H							
     ROR ECX, 010H							
     ROR EDX, 010H							
     MOV BYTE PTR CIPHER[07H], AL	
     MOV BYTE PTR CIPHER[0BH], BL	
     MOV BYTE PTR CIPHER[0FH], CL	
     MOV BYTE PTR CIPHER[03H], DL	
     POPAD
     RET
ROW_SHIFT_STATE_BYTES ENDP

INV_ROW_SHIFT_BYTES PROC NEAR
     PUSHAD
     MOV EAX, DWORD PTR DECRYPTED_TEXT[00H] ; EAX: [ b0  b1  b2  b3 ] -> EAX: [ b0  bD  bA  b7 ]
     MOV EBX, DWORD PTR DECRYPTED_TEXT[04H] ; EBX: [ b4  b5  b6  b7 ] -> EBX: [ b4  b1  bE  bB ]
     MOV ECX, DWORD PTR DECRYPTED_TEXT[08H] ; ECX: [ b8  b9  bA  bB ] -> ECX: [ b8  b5  b2  bF ]
     MOV EDX, DWORD PTR DECRYPTED_TEXT[0CH] ; EDX: [ bC  bD  bE  bF ] -> EDX: [ bC  b9  b6  b3 ]
     ROR EAX, 8H								
     ROR EBX, 8H								
     ROR ECX, 8H								
     ROR EDX, 8H								
     MOV BYTE PTR DECRYPTED_TEXT[05H], AL
     MOV BYTE PTR DECRYPTED_TEXT[0AH], AH
     MOV BYTE PTR DECRYPTED_TEXT[09H], BL
     MOV BYTE PTR DECRYPTED_TEXT[0EH], BH
     MOV BYTE PTR DECRYPTED_TEXT[0DH], CL
     MOV BYTE PTR DECRYPTED_TEXT[02H], CH
     MOV BYTE PTR DECRYPTED_TEXT[01H], DL
     MOV BYTE PTR DECRYPTED_TEXT[06H], DH
     ROR EAX, 010H							
     ROR EBX, 010H							
     ROR ECX, 010H							
     ROR EDX, 010H							
     MOV BYTE PTR DECRYPTED_TEXT[0FH], AL
     MOV BYTE PTR DECRYPTED_TEXT[03H], BL
     MOV BYTE PTR DECRYPTED_TEXT[07H], CL
     MOV BYTE PTR DECRYPTED_TEXT[0BH], DL
     POPAD
     RET
INV_ROW_SHIFT_BYTES ENDP

COLUMN_MIX_STATE_BYTES PROC NEAR
     PUSHAD
     MOV EBX, 0                 ; OUTER LOOP COUNTER -> EBX
COL_LOOP: MOV EDX, DWORD PTR CIPHER[EBX] ; INNER LOOP CURRENT 4 BYTES -> EDX
          MOV ECX, 0
          PUSH EBX	
          MOV EBX, 0
          MOV ESI, 0            ; INNER LOOP COUNTER -> ESI
INNER_COL_LOOP: MOV AL, DL      ; TEMP USE -> EAX
                SAR AL, 7								
                AND AL, 01
                POP EDI         ; POP WHAT WAS IN EBX INTO EDI
                ADD ESI, EDI
                MOV BL, BYTE PTR CIPHER[ESI]
                SUB ESI, EDI
                SHL BL, 1								
                PUSH EDI        ; POP WHAT WAS IN EDI INTO WHAT WILL BE POPPED INTO EBX
                MOV AH, 01BH
                MUL AH									
                XOR BL, AL      ; BL = B[i] ^= H * 1B
                ROR EDX, 8
                ROR EBX, 8
                INC ESI
                CMP ESI, 3
                JLE INNER_COL_LOOP
          MOV ECX, EDX          ; A ARRAY -> ECX
          MOV EAX, EBX          ; EAX IS NOW THE B ARRAY
          POP EBX
          MOV ESI, 0            ; OTHER INNER LOOP COUNTER
    PLACE_LOOP: MOV BYTE PTR CIPHER[EBX + ESI], AL     ; R[0] = B[0] <- THE INDICES ROTATE
                ROL ECX, 8			; CL = A[3]        ;           TO THE CORRECT VALUES EVERY LOOP
                XOR BYTE PTR CIPHER[EBX + ESI], CL     ; R[0] = B[0] ^ A[3]
                ROL ECX, 8			; CL = A[2]
                XOR BYTE PTR CIPHER[EBX + ESI], CL     ; R[0] = B[0] ^ A[3] ^ A[2]
                ROR EAX, 8			; AL = B[1]
                XOR BYTE PTR CIPHER[EBX + ESI], AL     ; R[0] = B[0] ^ A[3] ^ A[2] ^ B[1]
                ROL ECX, 8			; CL = A[1]
                XOR BYTE PTR CIPHER[EBX + ESI], CL     ; R[0] = B[0] ^ A[3] ^ A[2] ^ B[1] ^ A[1]
                INC ESI
                CMP ESI, 3
                JLE PLACE_LOOP
          ADD EBX, 04H
          CMP EBX, 0CH
          JLE COL_LOOP
     POPAD
     RET
COLUMN_MIX_STATE_BYTES ENDP

INV_COLUMN_MIX_BYTES PROC NEAR
     PUSHAD
     MOV EBX, 0     ; OUTER LOOP COUNTER -> EBX
INV_COL_LOOP: MOV EDX, DWORD PTR DECRYPTED_TEXT[EBX] ; CURRENT 4 BYTES -> EDX
              PUSH EBX          ; save the outer loop counter's value for use later
              MOV ESI, 0        ; COL_BYTE_LOOP COUNTER -> ESI
   COL_BYTE_LOOP: MOV EAX, 0090D0B0EH     ; START STATE OF B ARRAY
                  MOV ECX, ESI
                  SHL ECX, 3
                  ROL EAX, CL             ; ROTATE THE MULTIPLYING ARRAY BY 1 BYTE EVERY TURN
                  MOV ECX, EDX            ; START STATE OF A ARRAY
                  MOV EBX, 0              ; START STATE OF P ARRAY
                  CALL GALOIS_MULTIPLICATION ; STORE THE PRODUCT OF GALOIS MULTIPLICATION EVERY TURN
                  ROR EAX, 8
                  ROR ECX, 8
                  ROR EBX, 8
                  CALL GALOIS_MULTIPLICATION
                  ROR EAX, 8
                  ROR ECX, 8
                  ROR EBX, 8
                  CALL GALOIS_MULTIPLICATION
                  ROR EAX, 8
                  ROR ECX, 8
                  ROR EBX, 8
                  CALL GALOIS_MULTIPLICATION
                  ROR EAX, 8
                  ROR ECX, 8
                  ROR EBX, 8
                  MOV ECX, EBX     ; XOR ALL THE STORED GALOIS PRODUCTS TOGETHER AND
                  ROR EBX, 8       ; PLACE INTO MEMORY
                  XOR CL, BL
                  ROR EBX, 8
                  XOR CL, BL
                  ROR EBX, 8
                  XOR CL, BL
                  ROR EBX, 8       ; CL NOW CONTAINS R[0]
                  POP EBX
                  MOV BYTE PTR DECRYPTED_TEXT[EBX + ESI], CL ; NEW BYTE IS NOW SAVED INTO MEMORY
                  PUSH EBX         ; ORIGINAL STATE IS STILL IN EDX
                  INC ESI          ; NOW GO MAKE ANOTHER P ARRAY FOR THE NEXT BYTE LOCATION
                  CMP ESI, 4
                  JL COL_BYTE_LOOP
              POP EBX
              ADD EBX, 04H
              CMP EBX, 0CH
              JLE INV_COL_LOOP
     POPAD
     RET
INV_COLUMN_MIX_BYTES ENDP

GALOIS_MULTIPLICATION PROC NEAR ; INPUT: a->CL, b->AL
     PUSH ECX ; OUTPUT: p->BL
     PUSH EAX
     PUSH ESI
     MOV BL, 0
     MOV ESI, 0							
P_VAL_LOOP:	   PUSH EAX
               AND AL, 01
               CMP AL, 00
               POP EAX
               JZ SKIP_1
               XOR BL, CL
       SKIP_1: PUSH ECX
               AND CL, 80H
               CMP CL, 00
               POP ECX
               JZ SKIP_2
               SHL CL, 1
               XOR CL, 1BH
               JMP SKIP_SHL
       SKIP_2: SHL CL, 1
     SKIP_SHL: SAR AL, 1
               INC ESI
               CMP ESI, 8
               JL P_VAL_LOOP
     POP ESI
     POP EAX
     POP ECX
     RET
GALOIS_MULTIPLICATION ENDP

CONVERT_NIBBLES_TO_ASCII PROC NEAR	; converts 16 bytes to 32 bytes of ascii characters
			PUSHAD
				MOV EAX, 0
				MOV EDX, 0
				MOV ECX, 0FH
		BYTE_LOOP:	MOV AL, BYTE PTR CIPHER[ECX]
					MOV DL, BYTE PTR CIPHER[ECX]
					AND AL, 00FH		; AB -> AL=0B	; split the nibbles into separate bytes
					AND DL, 0F0H		; AB -> DL=A0
					SHR DL, 4			; A0 -> DL=0A
					MOV AL, BYTE PTR HEX_TO_ASCII[EAX]	; convert the high and low bytes to ascii
					MOV DL, BYTE PTR HEX_TO_ASCII[EDX]
					SHL ECX, 1
					MOV BYTE PTR CIPHER_ASCII[ECX + 1], AL
					MOV BYTE PTR CIPHER_ASCII[ECX + 0], DL
					SHR ECX, 1
					DEC ECX
					CMP ECX, 0
					JGE BYTE_LOOP
			POPAD
				RET
CONVERT_NIBBLES_TO_ASCII ENDP

CONVERT_DECRYPT_NIBBLES_TO_ASCII PROC NEAR	; converts 16 bytes to 32 bytes of ascii characters
			PUSHAD
				MOV EAX, 0
				MOV EDX, 0
				MOV ECX, 0FH
	INV_BYTE_LOOP:	MOV AL, BYTE PTR DECRYPTED_TEXT[ECX]
					MOV DL, BYTE PTR DECRYPTED_TEXT[ECX]
					AND AL, 00FH		; AB -> AL=0B	; split the nibbles into separate bytes
					AND DL, 0F0H		; AB -> DL=A0
					SHR DL, 4			; A0 -> DL=0A
					MOV AL, BYTE PTR HEX_TO_ASCII[EAX]	; convert the high and low bytes to ascii
					MOV DL, BYTE PTR HEX_TO_ASCII[EDX]
					SHL ECX, 1
					MOV BYTE PTR DECRYPTED_TEXT_ASCII[ECX + 1], AL
					MOV BYTE PTR DECRYPTED_TEXT_ASCII[ECX + 0], DL
					SHR ECX, 1
					DEC ECX
					CMP ECX, 0
					JGE INV_BYTE_LOOP
			POPAD
				RET
CONVERT_DECRYPT_NIBBLES_TO_ASCII ENDP

CONVERT_PLAINTEXT_TO_ASCII PROC NEAR	; converts 16 bytes to 32 bytes of ascii characters
			PUSHAD
				MOV EAX, 0
				MOV EDX, 0
				MOV ECX, 0FH
	PT_BYTE_LOOP:	MOV AL, BYTE PTR PLAINTEXT[ECX]
					MOV DL, BYTE PTR PLAINTEXT[ECX]
					AND AL, 00FH		; AB -> AL=0B	; split the nibbles into separate bytes
					AND DL, 0F0H		; AB -> DL=A0
					SHR DL, 4			; A0 -> DL=0A
					MOV AL, BYTE PTR HEX_TO_ASCII[EAX]	; convert the high and low bytes to ascii
					MOV DL, BYTE PTR HEX_TO_ASCII[EDX]
					SHL ECX, 1
					MOV BYTE PTR PLAINTEXT_ASCII[ECX + 1], AL
					MOV BYTE PTR PLAINTEXT_ASCII[ECX + 0], DL
					SHR ECX, 1
					DEC ECX
					CMP ECX, 0
					JGE PT_BYTE_LOOP
			POPAD
				RET
CONVERT_PLAINTEXT_TO_ASCII ENDP

CONVERT_KEY_TO_ASCII PROC NEAR	; converts 16 bytes to 32 bytes of ascii characters
			PUSHAD
				MOV EAX, 0
				MOV EDX, 0
				MOV ECX, 0FH
	KEY_BYTE_LOOP:	MOV AL, BYTE PTR KEY[ECX]
					MOV DL, BYTE PTR KEY[ECX]
					AND AL, 00FH		; AB -> AL=0B	; split the nibbles into separate bytes
					AND DL, 0F0H		; AB -> DL=A0
					SHR DL, 4			; A0 -> DL=0A
					MOV AL, BYTE PTR HEX_TO_ASCII[EAX]	; convert the high and low bytes to ascii
					MOV DL, BYTE PTR HEX_TO_ASCII[EDX]
					SHL ECX, 1
					MOV BYTE PTR KEY_ASCII[ECX + 1], AL
					MOV BYTE PTR KEY_ASCII[ECX + 0], DL
					SHR ECX, 1
					DEC ECX
					CMP ECX, 0
					JGE KEY_BYTE_LOOP
			POPAD
				RET
CONVERT_KEY_TO_ASCII ENDP

main endp
end main
