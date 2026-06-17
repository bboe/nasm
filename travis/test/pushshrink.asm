; Self-shrink miss: push immediate (imm8 vs imm32).
;
; B - A spans this push plus 125 bytes. With the imm8 (2-byte) form
; B - A == 127, which fits push imm8. NASM emits the 5-byte imm32 form
; under the adversarial preamble because a pass settles on the long form
; and the value (130) is then tested against that layout.
;
;   -Ox emits : 68 82 00 00 00   push dword 0x82   (imm32, 130)  @ 0x1d9
;   optimal   : 6A 7F            push byte +0x7f   (imm8,  127)

bits 32
        times 43 jmp A
        times 256 db 0
        je A
A:
        push B - A
        times 125 db 0
B:
