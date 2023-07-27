![console output](https://github.com/gabrielangelcabrera/Assembly-Projects/assets/15637962/a295e4b7-e0cd-46bf-89b4-803e61a47425)
# Assembly-Projects
A repository for assembly language programs made during my time in grad school.

## Overview<br/>
**AES_128.asm:**<br/> 
- An x86 assembly language implementation of the 128-bit version of the Advanced Encryption Standard.

### AES_128.asm<br/>
**Date:** <br/>6/28/23 - 7/13/23<br/>
**Summary:**<br/> Implemented the Advanced Encryption Standard (AES) for 128-bit cipher keys using assembly language and Microsoft Macro Assembler. A summary of the AES is found at: [Advanced Encryption Standard - Wikipedia](https://en.wikipedia.org/wiki/Advanced_Encryption_Standard)<br/>
**Code Overview:**<br/>
This code was written as an x86 program. The AES algorithm is composed of multiple steps that are repeated during the encryption of the plaintext. The AES has support for using 128-bit, 192-bit, and 256-bit cipher keys, but the assembly program written only performs encryption and decryption using a 128-bit cipher key. The assembly code written is composed of subroutines that mirror the forward steps of the AES, namely: XOR_STATE_AND_ROUND_KEY, SUBSTITUTE_STATE_BYTES, ROW_SHIFT_STATE_BYTES, COLUMN_MIX_STATE_BYTES and the inverse steps of the AES: XOR_DECRYPT_STATE_AND_ROUND_KEY, INV_SUBSTITUTE_BYTES, INV_ROW_SHIFT_BYTES, INV_COLUMN_MIX_BYTES. 
Set up of the substitution tables for the substitution steps was done within a subroutine, as well as the generation of the expanded key. The Windows Console was used to display the plaintext, cipher key, ciphertext, and decrypted plaintext; to do this Windows Console API calls were made in the program. GALOIS MULTIPLICATION for the inverse column mix step of the implementation was also done in its own subroutine.
