; Self-shrink miss: sign-extended immediate (imm8 vs imm32).
;
; Same shape as travis/test/jccshrink, but the relaxable target is an
; immediate (add r/m32, imm) instead of a jump. B - A spans this
; instruction plus 124 bytes. With the imm8 (3-byte) form B - A == 127,
; which fits a sign-extended imm8. NASM emits the 5-byte imm32 form
; because the current (imm32) layout makes the value 129, and it never
; accounts for the 2 bytes the target moves when the instruction shrinks.
;
; Immediates are optimistic, so a bare forward case shrinks fine; the
; preamble (backward jumps that relax) is what forces a pass to settle
; on the long form and expose the miss.
;
;   -Ox emits : 05 81 00 00 00   add eax,0x81   (imm32, 129)  @ 0x1d9
;   optimal   : 83 C0 7F         add eax,+0x7f  (imm8,  127)

bits 32
        times 43 jmp A
        times 256 db 0
        je A
A:
        add eax, B - A
        times 124 db 0
B:
