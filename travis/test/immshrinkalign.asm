bits 32
        times 43 jmp A
        times 256 db 0
        je A
A:
        add eax, B - A
        align 2
        times 124 db 0
B:
