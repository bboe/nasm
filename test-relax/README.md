# Relaxable-statement self-shrink cases

Exploration cases for the general problem hpax raised on PR #239: the
forward self-shrink that `jmp_match` was patched for also affects other
relaxable statements. Each reproducer below is a missed optimization, not
a crash. They are intentionally kept out of `make travis` because they
capture *current suboptimal* output rather than guard correct output.

The shape is always the same: a relaxable operand whose value is
`B - A`, where the relaxable instruction sits between `A` and `B`. The
short encoding is a true fixed point (the value fits once the
instruction shrinks), but NASM tests the value against the current,
longer layout and so keeps the long form.

| case | file | -Ox emits | optimal |
|------|------|-----------|---------|
| jcc/jmp rel8 (already fixed) | `travis/test/jccshrink.asm` | near (5 B) on stock | short (2 B) |
| sign-extended immediate | `imm_selfshrink.asm` | `05 81000000` imm32 (129) | `83C07F` imm8 (127) |
| push immediate | `push_selfshrink.asm` | `68 82000000` imm32 (130) | `6A7F` imm8 (127) |
| memory displacement | `disp_selfshrink.asm` | `8B81 82000000` disp32 (130) | `8B417F` disp8 (127) |

## Notes

- **Immediates (`add`, `push`) are optimistic**: a bare forward case
  already shrinks, so they only miss under the preamble that forces a
  pass to settle on the long form. The preamble (`times 43 jmp A` /
  `je A`) is borrowed from `jccshrink`.
- **Memory displacements are not optimistic**: NASM keeps disp32 for any
  forward label-difference, so `disp_selfshrink.asm` misses with no
  preamble at all. This is the cleanest reproducer.

## Reproduce

```sh
for f in test-relax/*.asm; do
    echo "== $f =="
    ./nasm -Ox -f bin -o /tmp/r.bin "$f"
    ndisasm -b32 /tmp/r.bin | grep -iE 'add eax|push|mov eax,\[' | tail -1
done
```

## Implication for a general fix

The committed `jmp_match` fix is jump-specific. A general solution would
apply the same "post-shrink displacement" reasoning to immediates and
displacements, with the same convergence guard (bounded speculation, or
proper relaxation infrastructure) so an `align` between `A` and `B`
cannot cause oscillation. These three cases plus an `align` variant of
each would be the regression set for that work.
