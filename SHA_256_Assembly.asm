extrn ExitProcess: PROC
extrn GetOpenFileNameA: PROC		; A Win32 API function to open a window to select a file
extrn CreateFileA: PROC				; A Win32 API function to open a file
extrn GetFileSizeEx: PROC			; A Win32 API function to get the file size in bytes
extrn ReadFile: PROC				; A Win32 API function to get bytes of the file
extrn CloseHandle: PROC				; A Win32 API function to close the handle of the opened file
extrn MessageBoxA: PROC				; A Win32 API function to display a message window

.data
; ---------------------------------------------  GetOpenFileNameA Parameters       -----------------------------------------------
	; define the struct required for the GetOpenFileNameA function, using an
		; aligning parameter (8) to align struct parameters along multiples of 8 bytes.
		; https://learn.microsoft.com/en-us/cpp/build/x64-software-conventions?view=msvc-170#x64-aggregate-and-union-layout
		; This matches the OPENFILENAMEA structure (commdlg.h) from
		; https://learn.microsoft.com/en-us/windows/win32/api/commdlg/ns-commdlg-openfilenamea
tagOFNA STRUCT 8
	lStructSize       dd 0		; 0		- dword
	hwndOwner         dq 0		; 4		- qword
	hInstance         dq 0		; 12	- qword
	lpstrFilter       dq 0		; 20	- qword
	lpstrCustomFilter dq 0		; 28	- qword
	nMaxCustFilter    dd 0		; 36	- dword
	nFilterIndex      dd 0		; 40	- dword
	lpstrFile  dq offset filename ; 44	- qword	
	nMaxFile          dd 512		; 52	- dword
	lpstrFileTitle    dq 0		; 56	- qword
	nMaxFileTitle     dd 0		; 64	- dword
	lpstrInitialDir   dq 0		; 68	- qword
	lpstrTitle        dq 0		; 76	- qword
	Flags             dd 00001800h; 84	- dword-sets the bit flags: OFN_PATHMUSTEXIST and OFN_FILEMUSTEXIST
	nFileOffset       dw 0		; 88	- word
	nFileExtension    dw 0		; 90	- word
	lpstrDefExt       dq 0		; 92	- qword
	lCustData         dq 0		; 100	- qword
	lpfnHook          dq 0		; 108	- qword
	lpTemplateName    dq 0		; 116	- qword
	pvReserved        dq 0		; 124	- qword
	dwReserved        dd 0		; 132	- dword
	FlagsEx           dd 0		; 136	- dword
tagOFNA ENDS

	; declare an instance of the struct required for the open file dialog
		; and set the lStructSize parameter (first parameter) to the struct size
open_file_struct tagOFNA <sizeof tagOFNA>

filename db 512 dup(0)			; memory location to hold the file name


; ---------------------------------------------  CreateFileA Parameters            -----------------------------------------------
	; declare the CreateFileA function parameters to be used to open the file
file_handle dq 0				; a handle to the file
dwDesiredAccess dd 080000000h	; set GENERIC_READ as the bitmask
dwShareMode dd 000000001h		; set FILE_SHARE_READ as the bitmask to allow shared access
lpSecurityAttributes dq 0		; set this parameter to null
dwCreationDisposition dq 3		; set OPEN_EXISTING to open the file, only if it exists, made quadword to align in stack
dwFlagsAndAttributes dq 080h	; set FILE_ATTRIBUTE_NORMAL to not set any attributes, made quadword to align in stack
hTemplateFile dq 0				; this parameter is ignored for read accesses


; ---------------------------------------------  GetFileSizeEx Parameters          -----------------------------------------------
	; parameters for GetFileSizeEx() function
file_size dq 0	; the size of the file

; ---------------------------------------------  ReadFile Parameters               -----------------------------------------------
	; parameters for the ReadFile() function
OVERLAPPED STRUCT
  Internal       dq 0
  InternalHigh   dq 0
  Pointer        dq 0
  hEvent         dq 0
OVERLAPPED ENDS
overlapped_struct OVERLAPPED <>	; declare an instance of the overlapped struct


; ---------------------------------------------  SHA-256 Algorithm Parameters      -----------------------------------------------
	; declare the round constants
round_constants	  dq	071374491428A2F98h, 0E9B5DBA5B5C0FBCFh, 059F111F13956C25Bh, 0AB1C5ED5923F82A4h,
						012835B01D807AA98h, 0550C7DC3243185BEh, 080DEB1FE72BE5D74h, 0C19BF1749BDC06A7h,
						0EFBE4786E49B69C1h, 0240CA1CC0FC19DC6h, 04A7484AA2DE92C6Fh, 076F988DA5CB0A9DCh,
						0A831C66D983E5152h, 0BF597FC7B00327C8h, 0D5A79147C6E00BF3h, 01429296706CA6351h
				  dq	02E1B213827B70A85h, 053380D134D2C6DFCh, 0766A0ABB650A7354h, 092722C8581C2C92Eh,
						0A81A664BA2BFE8A1h, 0C76C51A3C24B8B70h, 0D6990624D192E819h, 0106AA070F40E3585h,
						01E376C0819A4C116h, 034B0BCB52748774Ch, 04ED8AA4A391C0CB3h, 0682E6FF35B9CCA4Fh,
						078A5636F748F82EEh, 08CC7020884C87814h, 0A4506CEB90BEFFFAh, 0C67178F2BEF9A3F7h

	; declare the working variables
a db 0
b db 0
c db 0
d db 0
e db 0
f db 0
g db 0
h db 0

	; declare the intermediate hash values with initial values
int_hash_val_0 dd 06A09E667h
int_hash_val_1 dd 0BB67AE85h
int_hash_val_2 dd 03C6EF372h
int_hash_val_3 dd 0A54FF53Ah
int_hash_val_4 dd 0510E527Fh
int_hash_val_5 dd 09B05688Ch
int_hash_val_6 dd 01F83D9ABh
int_hash_val_7 dd 05BE0CD19h

	; declare the padding parameters
unpadded_message_length dq 0				; the length of the message in bits
number_of_0_bytes_to_add dq 0				; the number of 0 bytes to place after a 1 byte immediately following the last message byte
alignment_code db 0							; 0 if message_occupies_entire_block, 1 if message_1byte_0bytes_and_L_fit_in_block, 2 if L_does_not_fit_in_block

	; general algorithm parameters and memory stores
number_of_blocks dq 0						; the number of blocks for the SHA-256 algorithm to execute on
current_message_schedule db 256 dup(0)		; memory allocated to store the message schedule for the current block, 64 x 32 bits
current_message_blocks db 2097216 dup(?)	; memory allocated to store a subset of the total blocks to process, 32768 x 512 bits and an extra 512 bits for last block padding
current_message_blocks_end dq 0				; the offset to the last message byte loaded into current_message_blocks by the ReadFile function
final_message_digest db 32 dup(0)			; the raw bytes version of the message digest


; ---------------------------------------------  Message Box Parameters            -----------------------------------------------
window_title db 'SHA-256 Message Digest', 0	; the window title for the message box
final_message_digest_ASCII db 65 dup(0)		; the ascii version of the message digest for display
ascii_look_up_table db 030H, 031H, 032H, 033H, 034H, 035H, 036H, 037H, 038H, 039H, 041H, 042H, 043H, 044H, 045H, 046H

.code
main PROC
	sub rsp, 28h							; reserve shadow space and align stack simultaneously
	lea  rcx, open_file_struct				; place pointer to struct in rcx, for use by GetOpenFileNameA()
	call GetOpenFileNameA					; GetOpenFileNameA() takes a pointer to a struct as a parameter
	cmp rax, 0								; user closed or canceled the dialog
	je clo									; jump to close out program

	mov rcx, open_file_struct.lpstrFile		; place CreateFileA() parameters into registers stack
	mov edx, dwDesiredAccess					; according to Windows x64 calling convention
	mov r8d, dwShareMode
	mov r9, lpSecurityAttributes
	sub rsp, 8								; align stack pre-emptively
	push hTemplateFile						; push function parameters onto stack in reverse order
	push dwFlagsAndAttributes
	push dwCreationDisposition
	sub rsp, 20h							; reserve shadow space
	call CreateFileA						; get a file handle to the file
	mov file_handle, rax					; move the return value, which is the file handle, into file_handle
	
	mov rcx, file_handle					; get the file size and store it in file_size
	lea rdx, file_size
	call GetFileSizeEx					

	; PRE-PROCESSING STAGE
	mov rax, file_size						; file size is in bytes
	mov unpadded_message_length, rax		; to use for padding the end of the last block

	mov rdx, 0								; prepare for division
	mov r8, 64								; divide by 512 bits (64 bytes)
	div r8									; get quotient and remainder in rax, rdx
	inc rax

	cmp rdx, 0								; 3 different cases to address, covers all values of Remainder
	je message_occupies_entire_block
	cmp rdx, 55
	jle message_1byte_0bytes_and_L_fit_in_block
	cmp rdx, 63
	jle L_does_not_fit_in_block


message_occupies_entire_block:				; the 2nd to last block is only message bytes, the last block 
	mov rbx, 55									; is a 1 byte, 0 bytes, and the message length bytes
	mov number_of_0_bytes_to_add, rbx		; set the total number of 0 bytes to pad with
	mov number_of_blocks, rax				; save the total number of blocks
	mov alignment_code, 0
	jmp HASH_COMPUTATION_STAGE
message_1byte_0bytes_and_L_fit_in_block:	; the last block has message bytes, 1 byte, 0 bytes, and the message
	mov rbx, 64									; length bytes
	sub rbx, 9
	sub rbx, rdx
	mov number_of_0_bytes_to_add, rbx		; set the total number of 0 bytes to pad with
	mov number_of_blocks, rax				; save the total number of blocks
	mov alignment_code, 1
	jmp HASH_COMPUTATION_STAGE
L_does_not_fit_in_block:					; the 2nd to last block fits only the message bytes and 1 byte
	mov alignment_code, 2
	inc rax
	mov number_of_blocks, rax				; save the total number of blocks
	mov rbx, 119
	sub rbx, rdx
	mov number_of_0_bytes_to_add, rbx		; set the total number of 0 bytes to pad with
	; determine if ends at end of chunk and decrement 1 if it is
	mov rcx, 32768							; chunk size in blocks
	mov rdx, 0								; zero out rdx for division
	mov rax, number_of_blocks
	div rcx
	cmp rdx, 1
	jne HASH_COMPUTATION_STAGE
	mov rbx, 55
	mov number_of_0_bytes_to_add, rbx		; set the total number of 0 bytes to pad with
	jmp HASH_COMPUTATION_STAGE


HASH_COMPUTATION_STAGE:
	mov rcx, 0								; block processing loop counter
HASH_CALCULATION_LOOP:
	mov r10, rcx							; check if new blocks are needed from storage
	and r10, 32767							; find the value of the current block counter modulo 32768
	;and r10, 3								; find the value of the current block counter modulo 4
	cmp r10, 0								; if previous block was the last block in chunk of blocks, read
	jne	PRE_MS_LOOP							; in the next 32768 blocks into memory, else skip to MESSAGE_SCHEDULE_LOOP
	push rcx
	push rdx								; conserve register values
	push r9
	push rbx

	push rcx
	push rdx
	mov rcx, 0								; zero out loop
	lea rdx, current_message_blocks
ZERO_OUT_LOOP: 
	mov qword ptr [rdx + rcx], 0
	add rcx, 8
	cmp rcx, 2097216
	jl ZERO_OUT_LOOP
	pop rdx
	pop rcx

	shl rcx, 6								; convert block index to block memory offset: block0 = 0, block1 = 64
	mov overlapped_struct.Pointer, rcx
	shr rcx, 6
	mov rcx, file_handle					; read next 2,097,152 bytes into memory
	lea rdx, current_message_blocks			; store in current_message_blocks
	mov r8, 2097152							; read in 2097152 bytes
	;mov r8, 256								; read in 256 bytes
	lea r9, current_message_blocks_end		; location to store end index of data read in, aka lpNumberOfBytesRead
	push 0
	lea r10, overlapped_struct
	push r10								; push pointer to overlapped struct
	sub rsp, 20h							; reserve shadow space
	call ReadFile	
	add rsp, 30h							; move stack pointer back to start location
	pop rbx
	pop r9									; restore register values
	pop rdx
	pop rcx



PRE_MS_LOOP:
	; check if in penultimate block
	add rcx, 2
	cmp rcx, number_of_blocks				
	je PAD_PENULTIMATE_BLOCK
RETURN_FROM_PAD_PENULTIMATE_BLOCK:
	sub rcx, 2

	; check if in last block
	inc rcx
	cmp rcx, number_of_blocks
	je PAD_LAST_BLOCK
RETURN_FROM_PAD_LAST_BLOCK:
	dec rcx

	; STEP 1
	mov r8, 0								; message schedule generation loop counter
MESSAGE_SCHEDULE_LOOP:	
	cmp r8, 15								; start of message schedule generation loop, counter = t
	jg c2									
	mov rbx, rcx							; case 1: 0 <= t <= 15 | W_t = M_t
	;and rbx, 3
	and rbx, 32767							; find the value of the current block counter modulo 32768
	shl rbx, 6								; get index to the start of the ith block in memory
	shl r8, 2								; get t to be in multiples of 4 bytes (32 bit words)
	lea r11, current_message_blocks
	add r11, rbx
	add r11, r8
	mov r10d, dword ptr [r11]
	lea r11, current_message_schedule
	add r11, r8
	shr r8, 2								; get t back into range 0 to 63
	mov dword ptr [r11], r10d				; place W_t into current_message_schedule
	jmp em									; end of case 1, jump to em
c2:	mov r10, r8								; case 2: 16 <= t <= 63 | s1(W_t-2) + W_t-7 + s0(W_t-15) + W_t-16
	mov r11, r8								
	mov r12, r8								; get t
	mov r13, r8
	sub r10, 2								; get t-2
	sub r11, 7								; get t-7
	sub r12, 15								; get t-15
	sub r13, 16								; get t-16
	shl r10, 2								; get the memory offset to the t-2 32 bit word
	shl r11, 2
	shl r12, 2
	shl r13, 2
	lea r9, current_message_schedule		; get the base address of the current message schedule
	add r10, r9								; add the base address and the memory offset
	add r11, r9
	add r12, r9
	add r13, r9
	mov r10d, dword ptr [r10]				; get W_t-2 into r10
	mov r11d, dword ptr [r11]				; get W_t-7 into r11
	mov r12d, dword ptr [r12]				; get W_t-15 into r12
	mov r13d, dword ptr [r13]				; get W_t-16 into r13
	bswap r10d
	bswap r11d
	bswap r12d
	bswap r13d
	mov r14, r10							; execute lower_case_sigma_1
	mov r15, r10
	ror r10d, 17
	ror r14d, 19
	shr r15d, 10
	xor r10, r14
	xor r10, r15
	mov r14, r12							; execute lower_case_sigma_0
	mov r15, r12
	ror r12d, 7
	ror r14d, 18
	shr r15d, 3
	xor r12, r14
	xor r12, r15
	add r10d, r11d							; add up the terms modulo 2^32
	add r10d, r12d
	add r10d, r13d							; save W_t into r10d
	lea r11, current_message_schedule
	shl r8, 2
	add r11, r8
	shr r8, 2
	bswap r10d
	mov dword ptr [r11], r10d				; place W_t into current_message_schedule
em:	inc r8									
	cmp r8, 64
	jl MESSAGE_SCHEDULE_LOOP				; end of message generation loop


	; STEP 2
	push rax								; conserve register values
	push rbx
	push rcx
	push rdx
	push r8
	mov r8d, int_hash_val_0					; a initialize working variables
	mov r9d, int_hash_val_1					; b
	mov r10d, int_hash_val_2				; c
	mov r11d, int_hash_val_3				; d
	mov r12d, int_hash_val_4				; e
	mov r13d, int_hash_val_5				; f
	mov r14d, int_hash_val_6				; g
	mov r15d, int_hash_val_7				; h

	; STEP 3
	mov rcx, 0								; rcx as loop counter, t
s3:	lea rax, current_message_schedule
	shl rcx, 2
	add rax, rcx							; add offset to memory location of 32bit word t
	shr rcx, 2
	mov eax, dword ptr [rax]				; get W_t
	bswap eax
	add r15d, eax							; T_1 = W_t + h, save into h

	mov rax, r12							; execute uppercase_sigma_1(e)
	mov rbx, r12
	ror eax, 6
	ror ebx, 11
	xor eax, ebx
	mov rbx, r12
	ror ebx, 25
	xor eax, ebx							
	add r15d, eax							; T_1 = W_t + h + uppercase_sigma_1(e), save into h

	mov rax, r12							; execute Ch(e,f,g) = (e ^ f)XOR(~e ^ g)
	and eax, r13d
	mov rbx, r12
	not ebx
	and ebx, r14d
	xor eax, ebx
	add r15d, eax							; T_1 = W_t + h + uppercase_sigma_1(e) + Ch(e), save into h

	lea rax, round_constants				; load in K_t
	shl rcx, 2
	add rax, rcx							; add offset to memory location of 32bit word t
	shr rcx, 2
	mov eax, dword ptr [rax]				; get K_t
	add r15d, eax							; T_1 = W_t + h + uppercase_sigma_1(e) + Ch(e) + K_t, save into h (r15d)

	mov rax, r8								; execute uppercase_sigma_0(a)
	mov rbx, r8
	ror eax, 2
	ror ebx, 13
	xor eax, ebx
	mov rbx, r8
	ror ebx, 22
	xor eax, ebx							
	mov rdx, rax							; T_2 = uppercase_sigma_0(a), save into edx
	
	mov rax, r8								; (a)		; execute Maj(a,b,c)
	and eax, r9d							; (a ^ b)
	mov rbx, r8								; (a)
	and ebx, r10d							; (a ^ c)
	xor eax, ebx							; (a ^ b)xor(a ^ c)
	mov rbx, r9								; (b)
	and ebx, r10d							; (b ^ c)
	xor eax, ebx							; (a ^ b)xor(a ^ c)xor(b ^ c)
	add edx, eax							; T_2 =  uppercase_sigma_0(a) + Maj(a,b,c), save into edx

	mov rax, r15							; move T_1 to rax, will now assign value into h (r15d)
	mov r15, r14							; h = g
	mov r14, r13							; g = f
	mov r13, r12							; f = e
	mov r12, r11							; e = d
	add r12d, eax							; e = d + T_1
	mov r11, r10							; d = c
	mov r10, r9								; c = b
	mov r9, r8								; b = a
	mov r8, rax								; a = T_1
	add r8d, edx							; a = T_1 + T_2

	inc rcx
	cmp rcx, 64
	jl s3									; jump to step 3 while counter < 63

	; STEP 4								; save new intermediate hash values to memory
	mov eax, int_hash_val_0					; H_0 = a + H_0
	add eax, r8d
	mov int_hash_val_0, eax
	mov eax, int_hash_val_1					; H_1 = b + H_1
	add eax, r9d
	mov int_hash_val_1, eax
	mov eax, int_hash_val_2					; H_2 = c + H_2
	add eax, r10d
	mov int_hash_val_2, eax
	mov eax, int_hash_val_3					; H_3 = d + H_3
	add eax, r11d
	mov int_hash_val_3, eax
	mov eax, int_hash_val_4					; H_4 = e + H_4
	add eax, r12d
	mov int_hash_val_4, eax
	mov eax, int_hash_val_5					; H_5 = f + H_5
	add eax, r13d
	mov int_hash_val_5, eax
	mov eax, int_hash_val_6					; H_6 = g + H_6
	add eax, r14d
	mov int_hash_val_6, eax
	mov eax, int_hash_val_7					; H_7 = h + H_7
	add eax, r15d
	mov int_hash_val_7, eax


	mov r8d, int_hash_val_0					; a initialize working variables
	mov r9d, int_hash_val_1					; b
	mov r10d, int_hash_val_2				; c
	mov r11d, int_hash_val_3				; d
	mov r12d, int_hash_val_4				; e
	mov r13d, int_hash_val_5				; f
	mov r14d, int_hash_val_6				; g
	mov r15d, int_hash_val_7				; h


	pop r8									; restore register values
	pop rdx
	pop rcx
	pop rbx
	pop rax




	inc rcx
	cmp rcx, number_of_blocks
	jl HASH_CALCULATION_LOOP				; jump to HASH_CALCULATION_LOOP to continue hash computation loop
	jmp FINISH_LOOP							; jump to FINISH_LOOP if finished processing last block
	
PAD_PENULTIMATE_BLOCK:						; the 1 byte needs to be placed in the penultimate block whenever the message length
	cmp alignment_code, 2						; quadword doesn't fit within the last message block
	jne RETURN_FROM_PAD_PENULTIMATE_BLOCK
	push rcx
	lea rcx, current_message_blocks			; current_message_blocks[current_message_blocks_end] = 1
	add rcx, current_message_blocks_end
	mov byte ptr [rcx], 080h				; place 80 byte
	pop rcx
	jmp RETURN_FROM_PAD_PENULTIMATE_BLOCK


PAD_LAST_BLOCK:
	push rcx
	push rdx

	cmp alignment_code, 2					; the 1 byte has been placed in the penultimate block already whenever the message length
	je skip_1byte								; quadword doesn't fit within the last message block

	lea rcx, current_message_blocks			; current_message_blocks[current_message_blocks_end] = 1
	add rcx, current_message_blocks_end
	mov byte ptr [rcx], 080h				; place 80 byte

	
skip_1byte:
	lea rcx, current_message_blocks			; current_message_blocks[current_message_blocks_end + number_of_0_bytes_to_add + 1] = unpadded_message_length
	add rcx, current_message_blocks_end
	add rcx, number_of_0_bytes_to_add
	add rcx, 1
	mov rdx, unpadded_message_length
	shl rdx, 3								; convert bytes to bits
	bswap rdx
	mov qword ptr [rcx], rdx				; place L bits

	pop rdx
	pop rcx
	mov r8, 0								; jump back to loop
	jmp RETURN_FROM_PAD_LAST_BLOCK

FINISH_LOOP:	
	lea rax, final_message_digest			; end of loop
	mov r8d, int_hash_val_0					
	mov r9d, int_hash_val_1					
	mov r10d, int_hash_val_2				
	mov r11d, int_hash_val_3				
	mov r12d, int_hash_val_4				
	mov r13d, int_hash_val_5				
	mov r14d, int_hash_val_6				
	mov r15d, int_hash_val_7
	
	bswap r8d
	bswap r9d
	bswap r10d
	bswap r11d
	bswap r12d
	bswap r13d
	bswap r14d
	bswap r15d

	
	mov dword ptr [rax], r8d				; save the concatenated hash values into a contiguous memory
	add rax, 4									; block labeled final_message_digest
	mov dword ptr [rax], r9d
	add rax, 4
	mov dword ptr [rax], r10d
	add rax, 4
	mov dword ptr [rax], r11d
	add rax, 4
	mov dword ptr [rax], r12d
	add rax, 4
	mov dword ptr [rax], r13d
	add rax, 4
	mov dword ptr [rax], r14d
	add rax, 4
	mov dword ptr [rax], r15d


	mov rcx, file_handle					; place the file handle as the parameter to CloseHandle()
	call CloseHandle						; returns non zero if successful

	lea rax, final_message_digest			; create an ascii version of the message digest
	lea rbx, ascii_look_up_table
	mov rcx, 0
	lea rdx, final_message_digest_ASCII
	mov r10, 0
CONVERT_TO_ASCII:
	mov r8b, byte ptr [rax + rcx]
	mov r9b, r8b
	and r8, 0F0h
	and r9, 00Fh
	ror r8, 4
	mov r8b, byte ptr [rbx + r8]
	mov r9b, byte ptr [rbx + r9]
	mov byte ptr [rdx + r10], r8b
	mov byte ptr [rdx + r10 + 1], r9b
	inc rcx
	add r10, 2
	cmp rcx, 32
	jl CONVERT_TO_ASCII

	sub rsp, 20h
	mov rcx, 0
	lea rdx, final_message_digest_ASCII
	lea r8, window_title
	mov r9d, 0
	call MessageBoxA

clo:mov rcx, rax							; place the exit code of CloseHandle() as the parameter to ExitProcess()
	call ExitProcess						; returns 1 if successful
main ENDP
end