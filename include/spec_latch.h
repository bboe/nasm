/* SPDX-License-Identifier: BSD-2-Clause */
/* Copyright 1996-2025 The NASM Authors - All Rights Reserved */

/*
 * spec_latch.h
 *
 * One-shot speculation latch shared by the forward self-shrink sites
 * (jmp_match, set_imm_flags, memory_mod). A site may speculate the short
 * form once per assembly; if it does not stick it reverts and stays long,
 * so speculation cannot oscillate (e.g. across an align) and relaxation
 * still converges. Sites are keyed by per-pass source order; spec_used[]
 * persists across passes.
 */

#ifndef NASM_SPEC_LATCH_H
#define NASM_SPEC_LATCH_H

#include "nasm.h"
#include "nasmlib.h"

struct spec_latch {
    int64_t nalloc;
    int64_t nused;
    int64_t pass_seen;
    uint8_t *spec_used;
};

#define SPEC_LATCH_INIT { 0, 0, -1, NULL }

/* Next site index this pass; the counter resets on a new pass. */
static inline int64_t spec_latch_site(struct spec_latch *l)
{
    int64_t i;

    if (_passn != l->pass_seen) {
        l->nused = 0;
        l->pass_seen = _passn;
    }

    i = l->nused++;
    if (i >= l->nalloc) {
        int64_t new_nalloc = l->nalloc ? l->nalloc * 2 : 256;
        size_t new_bytes;
        while (new_nalloc <= i)
            new_nalloc *= 2;
        new_bytes = (size_t)(new_nalloc - l->nalloc);
        l->spec_used = nasm_realloc(l->spec_used, (size_t)new_nalloc);
        memset(l->spec_used + l->nalloc, 0, new_bytes);
        l->nalloc = new_nalloc;
    }
    return i;
}

static inline bool spec_latch_used(const struct spec_latch *l, int64_t i)
{
    return l->spec_used && i >= 0 && i < l->nalloc && l->spec_used[i];
}

static inline void spec_latch_mark(struct spec_latch *l, int64_t i)
{
    if (l->spec_used && i >= 0 && i < l->nalloc)
        l->spec_used[i] = 1;
}

static inline void spec_latch_free(struct spec_latch *l)
{
    nasm_free(l->spec_used);
    l->spec_used = NULL;
    l->nalloc = 0;
    l->nused = 0;
    l->pass_seen = -1;
}

#endif /* NASM_SPEC_LATCH_H */
