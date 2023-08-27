![console output](https://github.com/gabrielangelcabrera/Assembly-Projects/assets/15637962/a295e4b7-e0cd-46bf-89b4-803e61a47425)
# Assembly-Projects
A repository for assembly language programs made during my time in grad school.

## Overview<br/>
**AES_128.asm:** 
<br/> - An x86 assembly language implementation of the 128-bit version of the Advanced Encryption Standard.<br/> 
<br/> 
**SHA_256_Assembly.asm:** 
<br/> - An x64 assembly language implementation of the 256-bit version of the Secure Hash Algorithm - 2.

## Summaries<br/>
### AES_128.asm<br/>
**Date:** <br/>6/28/23 - 7/13/23<br/>
**Summary:**<br/> Implemented the Advanced Encryption Standard (AES) for 128-bit cipher keys using assembly language and Microsoft Macro Assembler. A summary of the AES is found at: [Advanced Encryption Standard - Wikipedia](https://en.wikipedia.org/wiki/Advanced_Encryption_Standard)<br/>
**Code Overview:**<br/>
This code was written as an x86 program. The AES algorithm is composed of multiple steps that are repeated during the encryption of the plaintext. The AES has support for using 128-bit, 192-bit, and 256-bit cipher keys, but the assembly program written only performs encryption and decryption using a 128-bit cipher key. The assembly code written is composed of subroutines that mirror the forward steps of the AES, namely: XOR_STATE_AND_ROUND_KEY, SUBSTITUTE_STATE_BYTES, ROW_SHIFT_STATE_BYTES, COLUMN_MIX_STATE_BYTES and the inverse steps of the AES: XOR_DECRYPT_STATE_AND_ROUND_KEY, INV_SUBSTITUTE_BYTES, INV_ROW_SHIFT_BYTES, INV_COLUMN_MIX_BYTES. 
Set up of the substitution tables for the substitution steps was done within a subroutine, as well as the generation of the expanded key. The Windows Console was used to display the plaintext, cipher key, ciphertext, and decrypted plaintext; to do this Windows Console API calls were made in the program. GALOIS MULTIPLICATION for the inverse column mix step of the implementation was also done in its own subroutine.

### SHA_256_Assembly.asm<br/>
![MessageBox](https://github.com/gabrielangelcabrera/Assembly-Projects/assets/15637962/5060301e-289b-4733-af47-49ccc4fa8064)<br/>
**Date:** <br/>8/9/23 - 8/27/23<br/>
**Summary:**<br/> Implemented the 256-bit version of the SHA-2 hashing algorithm using x64 assembly. A summary of the SHA-2 Algorithm is at: https://en.wikipedia.org/wiki/SHA-2<br/>
**Code Overview:**<br/>
This code was written using x64 assembly and the Win32 API. The Win32 API was used to open dialog boxes to select a file to hash and to display the hash of the file. Win32 API functions were also used to read the bytes of the file. Aside from the base implementation of the SHA-256 algorithm, some additional logic was used to read in about 2MB of file bytes at a time while calculating the final hash value of the file. C++ struct matching in assembly was done to interface with the Win32 API functions that required a struct as a parameter.
