; Self-shrink miss: memory displacement (disp8 vs disp32).
;
; B - A spans this instruction plus 124 bytes. With a disp8 (3-byte)
; encoding B - A == 127, which fits a sign-extended disp8. NASM instead
; emits the 6-byte disp32 form because it tests the displacement against
; the current (disp32) layout, where the value is 130, and never
; accounts for the 3 bytes the target moves when the instruction itself
; shrinks.
;
; No preamble is needed: unlike immediates, NASM is not optimistic about
; forward label-difference displacements, so even this simple forward
; case misses.
;
;   -Ox emits : 8B 81 82 00 00 00   mov eax,[ecx+0x82]   (disp32, 130)
;   optimal   : 8B 41 7F            mov eax,[ecx+0x7f]   (disp8,  127)

bits 32
A:
        mov eax, [ecx + B - A]
        times 124 db 0
B:
