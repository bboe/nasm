;; Convergence regression for jcc self-shrink under preprocessor coupling.
;;
;; From H. Peter Anvin's review of PR #239. The %if ($-do_mycode) < 6
;; makes the emitted code depend on the size of the je above it: shrink
;; the je to rel8 and mycode gets inlined, which pushes altcode out of
;; rel8 range. So the only valid encoding is the 6-byte near je (disp
;; 0x7e), even though 0x7e itself fits rel8.
;;
;; A naive self-shrink re-speculates every pass and never converges. The
;; one-shot latch tries short once, the %if flip makes it not fit, and it
;; reverts to near.

       bits 64
        default rel

        section .text

%macro mycode 0
        mov [pizza],eax
        mov [pasta],edx
%endmacro

do_mycode:
        test eax,eax
        je altcode
%if ($-do_mycode) < 6
        ;; Space enough to inline mycode
        mycode
%else
        ;; mycode is too large, needs to be out of line
        section .text.mycode
__mycode:
        mycode
        ret
        section .text
        call __mycode
%endif

        times 120 nop           ; Some other code
        ret

altcode:
        mov dword [pizza],0xfeedface
        mov dword [pasta],0xdeadbeef
        ret

%ifdef need_mycode
__mycode:
        mycode
        ret
%endif

        section .bss
pizza   dd ?
pasta   dd ?
