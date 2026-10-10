.text
.arch_extension sme-f64f64

.global _dasum 
.p2align 4 

_dasum:
    cmp     w1, #1096
    b.lo    _dasum_neon 

    rdsvl   x9, #1 
    cmp     x9, #32 
    b.lo    _dasum_sme4xVGx4 
    b       _dasum_sme8xVGx4 


.global _dasum_neon
.p2align 4

_dasum_neon:
    lsr     w2, w1, #3
    and     w3, w1, #7
    lsr     w3, w3, #1
    and     w4, w1, #1

    movi    v0.2d, #0 
    movi    v1.2d, #0 
    movi    v2.2d, #0 
    movi    v3.2d, #0 

    cbz     w2, .Lsimd_2

.Lsimd_8_loop:
    ldp     q4, q5, [x0], #32 
    ldp     q6, q7, [x0], #32 

    fabs    v4.2d, v4.2d
    fabs    v5.2d, v5.2d
    fabs    v6.2d, v6.2d
    fabs    v7.2d, v7.2d

    fadd    v0.2d, v0.2d, v4.2d 
    fadd    v1.2d, v1.2d, v5.2d 
    fadd    v2.2d, v2.2d, v6.2d 
    fadd    v3.2d, v3.2d, v7.2d 

    subs    w2, w2, #1 
    b.ne    .Lsimd_8_loop 

.Lsimd_2: 
    cbz     w3, .Lreduce 

.Lsimd_2_loop:
    ldr     q4, [x0], #16 

    fabs    v4.2d, v4.2d

    fadd    v0.2d, v0.2d, v4.2d 

    subs    w3, w3, #1 
    b.ne    .Lsimd_2_loop 

.Lreduce:
    fadd    v0.2d, v0.2d, v1.2d 
    fadd    v2.2d, v2.2d, v3.2d 
    fadd    v0.2d, v0.2d, v2.2d 
    faddp   d0, v0.2d

.Lscalar:
    cbz     w4, .Lneon_done

.Lscalar_loop:
    ldr     d4, [x0], #8 

    fabs    d4, d4
    fadd    d0, d0, d4 

    subs    w4, w4, #1
    b.ne    .Lscalar_loop 

.Lneon_done:
    ret 


.global _dasum_sve
.p2align 4 

_dasum_sve:
    mov     w1, w1

    sub     sp, sp, #64
    stp     d8, d9, [sp]
    stp     d10, d11, [sp, #16]
    stp     d12, d13, [sp, #32]
    stp     d14, d15, [sp, #48]

    smstart sm

    // base index 
    mov     w8, #0 
    dup     z0.d, #0

    whilelo p0.d, x8, x1
    b.none  .Lsve_reduce 

.Lsve_loop:
    ld1d    z2.d, p0/z, [x0, x8, lsl #3] 
    fabs    z2.d, p0/m, z2.d
    fadd    z0.d, p0/m, z0.d, z2.d 

    incd    x8 

    whilelo p0.d, x8, x1 
    b.first .Lsve_loop

.Lsve_reduce:
    ptrue   p0.d 
    faddv   d0, p0, z0.d 

.Lsve_done:
    fmov    x3, d0

    smstop  sm 

    fmov    d0, x3

    ldp     d8, d9, [sp], #16
    ldp     d10, d11, [sp], #16
    ldp     d12, d13, [sp], #16
    ldp     d14, d15, [sp], #16 

    ret 


.global _dasum_sme4xVGx4
.p2align 4 

_dasum_sme4xVGx4:
    mov     w1, w1 

    sub     sp, sp, #64 
    stp     d8, d9, [sp]
    stp     d10, d11, [sp, #16]
    stp     d12, d13, [sp, #32]
    stp     d14, d15, [sp, #48]

    smstart 
    zero    {za}

    cntd    x2 
    mov     w8, #0 

    // base 4xVGx4 index 
    mov     x12, #0 
    
    // number of double64's 4xVGx4 
    lsl     w3, w2, #4 
    // number of full 4xVGx4s 
    udiv    w4, w1, w3 
    cbz     w4, .Lsme4_tail_loop

    ptrue   pn8.d 

.Lsme4_full_loop:
    add     x13, x12, x2, lsl #2 
    add     x14, x13, x2, lsl #2 
    add     x15, x14, x2, lsl #2 

    ld1d    {z4.d-z7.d}, pn8/z, [x0, x12, lsl #3]
    and     z4.d, z4.d, #0x7fffffffffffffff 
    and     z5.d, z5.d, #0x7fffffffffffffff 
    and     z6.d, z6.d, #0x7fffffffffffffff 
    and     z7.d, z7.d, #0x7fffffffffffffff 

    ld1d    {z8.d-z11.d}, pn8/z, [x0, x13, lsl #3]
    and     z8.d, z8.d, #0x7fffffffffffffff 
    and     z9.d, z9.d, #0x7fffffffffffffff 
    and     z10.d, z10.d, #0x7fffffffffffffff 
    and     z11.d, z11.d, #0x7fffffffffffffff 

    ld1d    {z12.d-z15.d}, pn8/z, [x0, x14, lsl #3]
    and     z12.d, z12.d, #0x7fffffffffffffff 
    and     z13.d, z13.d, #0x7fffffffffffffff 
    and     z14.d, z14.d, #0x7fffffffffffffff 
    and     z15.d, z15.d, #0x7fffffffffffffff 

    ld1d    {z16.d-z19.d}, pn8/z, [x0, x15, lsl #3] 
    and     z16.d, z16.d, #0x7fffffffffffffff 
    and     z17.d, z17.d, #0x7fffffffffffffff 
    and     z18.d, z18.d, #0x7fffffffffffffff 
    and     z19.d, z19.d, #0x7fffffffffffffff

    fadd    za.d[w8, 0, vgx4], {z4.d-z7.d} 
    fadd    za.d[w8, 0, vgx4], {z8.d-z11.d}
    fadd    za.d[w8, 0, vgx4], {z12.d-z15.d}
    fadd    za.d[w8, 0, vgx4], {z16.d-z19.d}

    incd    x12, all, mul #16 
    subs    w4, w4, #1 
    b.ne    .Lsme4_full_loop

.Lsme4_tail_loop:
    add     x13, x12, x2, lsl #2 
    add     x14, x13, x2, lsl #2 
    add     x15, x14, x2, lsl #2 

    whilelo pn8.d, x12, x1, vlx4 
    b.none  .Lsme4_reduce 

    whilelo pn9.d, x13, x1, vlx4 
    whilelo pn10.d, x14, x1, vlx4 
    whilelo pn11.d, x15, x1, vlx4 

    ld1d    {z4.d-z7.d}, pn8/z, [x0, x12, lsl #3]
    and     z4.d, z4.d, #0x7fffffffffffffff 
    and     z5.d, z5.d, #0x7fffffffffffffff 
    and     z6.d, z6.d, #0x7fffffffffffffff 
    and     z7.d, z7.d, #0x7fffffffffffffff 

    ld1d    {z8.d-z11.d}, pn9/z, [x0, x13, lsl #3]
    and     z8.d, z8.d, #0x7fffffffffffffff 
    and     z9.d, z9.d, #0x7fffffffffffffff 
    and     z10.d, z10.d, #0x7fffffffffffffff 
    and     z11.d, z11.d, #0x7fffffffffffffff 

    ld1d    {z12.d-z15.d}, pn10/z, [x0, x14, lsl #3]
    and     z12.d, z12.d, #0x7fffffffffffffff 
    and     z13.d, z13.d, #0x7fffffffffffffff 
    and     z14.d, z14.d, #0x7fffffffffffffff 
    and     z15.d, z15.d, #0x7fffffffffffffff 

    ld1d    {z16.d-z19.d}, pn11/z, [x0, x15, lsl #3] 
    and     z16.d, z16.d, #0x7fffffffffffffff 
    and     z17.d, z17.d, #0x7fffffffffffffff 
    and     z18.d, z18.d, #0x7fffffffffffffff 
    and     z19.d, z19.d, #0x7fffffffffffffff

    fadd    za.d[w8, 0, vgx4], {z4.d-z7.d} 
    fadd    za.d[w8, 0, vgx4], {z8.d-z11.d}
    fadd    za.d[w8, 0, vgx4], {z12.d-z15.d}
    fadd    za.d[w8, 0, vgx4], {z16.d-z19.d}

    incd    x12, all, mul #16 
    b       .Lsme4_tail_loop

.Lsme4_reduce:
    mov     {z4.d-z7.d}, za.d[w8, 0, vgx4]

    fadd    z4.d, z4.d, z5.d
    fadd    z6.d, z6.d, z7.d
    fadd    z4.d, z4.d, z6.d

    ptrue   p0.d
    faddv   d0, p0, z4.d

.Lsme4_done:
    fmov    x3, d0 

    smstop 

    fmov    d0, x3 
    ldp     d8, d9, [sp], #16
    ldp     d10, d11, [sp], #16
    ldp     d12, d13, [sp], #16
    ldp     d14, d15, [sp], #16 

    ret 
        

.global _dasum_sme8xVGx4 
.p2align 4 

_dasum_sme8xVGx4:
    mov     w1, w1 

    sub     sp, sp, #64 
    stp     d8, d9, [sp]
    stp     d10, d11, [sp, #16]
    stp     d12, d13, [sp, #32]
    stp     d14, d15, [sp, #48]

    smstart
    zero    {za}

    cntd    x2 
    mov     w8, #0 
    lsr     w9, w2, #1 

    // base 8xVGx4 idx 
    mov     w5, #0 

    // number of doubles in 32 SVLs
    lsl     w3, w2, #5 

    // number of full 8xVGx4s 
    udiv    w4, w1, w3 
    cbz     w4, .Lsme8_tail_loop 

    ptrue   pn8.d

.Lsme8_full_loop:
    add     x6, x5, x2, lsl #2 
    add     x7, x6, x2, lsl #2 
    add     x10, x7, x2, lsl #2 
    add     x11, x10, x2, lsl #2 
    add     x12, x11, x2, lsl #2 
    add     x13, x12, x2, lsl #2 
    add     x14, x13, x2, lsl #2 

    ld1d    {z0.d-z3.d}, pn8/z, [x0, x5, lsl #3]
    and     z0.d, z0.d, #0x7fffffffffffffff 
    and     z1.d, z1.d, #0x7fffffffffffffff 
    and     z2.d, z2.d, #0x7fffffffffffffff 
    and     z3.d, z3.d, #0x7fffffffffffffff 

    ld1d    {z4.d-z7.d}, pn8/z, [x0, x6, lsl #3]
    and     z4.d, z4.d, #0x7fffffffffffffff 
    and     z5.d, z5.d, #0x7fffffffffffffff 
    and     z6.d, z6.d, #0x7fffffffffffffff 
    and     z7.d, z7.d, #0x7fffffffffffffff 

    ld1d    {z8.d-z11.d}, pn8/z, [x0, x7, lsl #3]
    and     z8.d, z8.d, #0x7fffffffffffffff 
    and     z9.d, z9.d, #0x7fffffffffffffff 
    and     z10.d, z10.d, #0x7fffffffffffffff 
    and     z11.d, z11.d, #0x7fffffffffffffff 

    ld1d    {z12.d-z15.d}, pn8/z, [x0, x10, lsl #3] 
    and     z12.d, z12.d, #0x7fffffffffffffff 
    and     z13.d, z13.d, #0x7fffffffffffffff 
    and     z14.d, z14.d, #0x7fffffffffffffff 
    and     z15.d, z15.d, #0x7fffffffffffffff 

    fadd    za.d[w8, 0, vgx4], {z0.d-z3.d}
    fadd    za.d[w8, 0, vgx4], {z4.d-z7.d}
    fadd    za.d[w8, 0, vgx4], {z8.d-z11.d}
    fadd    za.d[w8, 0, vgx4], {z12.d-z15.d}

    ld1d    {z0.d-z3.d}, pn8/z, [x0, x11, lsl #3]
    and     z0.d, z0.d, #0x7fffffffffffffff 
    and     z1.d, z1.d, #0x7fffffffffffffff 
    and     z2.d, z2.d, #0x7fffffffffffffff 
    and     z3.d, z3.d, #0x7fffffffffffffff 

    ld1d    {z4.d-z7.d}, pn8/z, [x0, x12, lsl #3]
    and     z4.d, z4.d, #0x7fffffffffffffff 
    and     z5.d, z5.d, #0x7fffffffffffffff 
    and     z6.d, z6.d, #0x7fffffffffffffff 
    and     z7.d, z7.d, #0x7fffffffffffffff 

    ld1d    {z8.d-z11.d}, pn8/z, [x0, x13, lsl #3]
    and     z8.d, z8.d, #0x7fffffffffffffff 
    and     z9.d, z9.d, #0x7fffffffffffffff 
    and     z10.d, z10.d, #0x7fffffffffffffff 
    and     z11.d, z11.d, #0x7fffffffffffffff 

    ld1d    {z12.d-z15.d}, pn8/z, [x0, x14, lsl #3] 
    and     z12.d, z12.d, #0x7fffffffffffffff 
    and     z13.d, z13.d, #0x7fffffffffffffff 
    and     z14.d, z14.d, #0x7fffffffffffffff 
    and     z15.d, z15.d, #0x7fffffffffffffff 

    fadd    za.d[w8, 0, vgx4], {z0.d-z3.d}
    fadd    za.d[w8, 0, vgx4], {z4.d-z7.d}
    fadd    za.d[w8, 0, vgx4], {z8.d-z11.d}
    fadd    za.d[w8, 0, vgx4], {z12.d-z15.d}

    incd    x5, all, mul #16 
    incd    x5, all, mul #16 
    subs    w4, w4, #1 
    b.ne    .Lsme8_full_loop

.Lsme8_tail_loop:
    add     x6, x5, x2, lsl #2 
    add     x7, x6, x2, lsl #2 
    add     x10, x7, x2, lsl #2 

    whilelo pn8.d, x5, x1, vlx4 
    b.none  .Lsme8_reduce 

    whilelo pn9.d, x6, x1, vlx4
    whilelo pn10.d, x7, x1, vlx4 
    whilelo pn11.d, x10, x1, vlx4

    ld1d    {z0.d-z3.d}, pn8/z, [x0, x5, lsl #3]
    and     z0.d, z0.d, #0x7fffffffffffffff 
    and     z1.d, z1.d, #0x7fffffffffffffff 
    and     z2.d, z2.d, #0x7fffffffffffffff 
    and     z3.d, z3.d, #0x7fffffffffffffff 

    ld1d    {z4.d-z7.d}, pn9/z, [x0, x6, lsl #3]
    and     z4.d, z4.d, #0x7fffffffffffffff 
    and     z5.d, z5.d, #0x7fffffffffffffff 
    and     z6.d, z6.d, #0x7fffffffffffffff 
    and     z7.d, z7.d, #0x7fffffffffffffff 

    ld1d    {z8.d-z11.d}, pn10/z, [x0, x7, lsl #3]
    and     z8.d, z8.d, #0x7fffffffffffffff 
    and     z9.d, z9.d, #0x7fffffffffffffff 
    and     z10.d, z10.d, #0x7fffffffffffffff 
    and     z11.d, z11.d, #0x7fffffffffffffff 

    ld1d    {z12.d-z15.d}, pn11/z, [x0, x10, lsl #3] 
    and     z12.d, z12.d, #0x7fffffffffffffff 
    and     z13.d, z13.d, #0x7fffffffffffffff 
    and     z14.d, z14.d, #0x7fffffffffffffff 
    and     z15.d, z15.d, #0x7fffffffffffffff 

    fadd    za.d[w8, 0, vgx4], {z0.d-z3.d}
    fadd    za.d[w8, 0, vgx4], {z4.d-z7.d}
    fadd    za.d[w8, 0, vgx4], {z8.d-z11.d}
    fadd    za.d[w8, 0, vgx4], {z12.d-z15.d}

    incd    x5, all, mul #16 
    b       .Lsme8_tail_loop 

.Lsme8_reduce:
    mov     {z0.d-z3.d}, za.d[w8, 0, vgx4]

    fadd    z0.d, z0.d, z1.d 
    fadd    z2.d, z2.d, z3.d 
    fadd    z0.d, z0.d, z2.d 

    ptrue   p0.d 
    faddv   d0, p0, z0.d 

.Lsme8_done:
    fmov    x3, d0 

    smstop 

    fmov    d0, x3 

    ldp     d8, d9, [sp], #16
    ldp     d10, d11, [sp], #16
    ldp     d12, d13, [sp], #16
    ldp     d14, d15, [sp], #16 

    ret 
