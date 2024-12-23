.data
a:      .float 2.0
bi:     .float 3.0
A:      .float 1.0
B:      .float 5.0
tol:    .float 0.0001
sum:    .float 0.0
msg_result: .asciz "Интеграл: "
msg_prec:   .asciz "Недостаточная точность, продолжаем вычисления...\n"
n:        .float 10.0

.text
    .globl main
main:
    la      t1, a
    flw     f0, 0(t1)
    la      t1, bi
    flw     f1, 0(t1)
    la      t1, A
    flw     f2, 0(t1)
    la      t1, B
    flw     f3, 0(t1)
    la      t1, tol
    flw     f4, 0(t1)
    la      t1, n
    flw     f6, 0(t1)

    la      t1, sum
    flw     f5, 0(t1)

loop:
    fsub.s  f7, f3, f2
    fdiv.s  f8, f7, f6

    jal     calculate_function
    fadd.s  f9, f0, f1

    fadd.s  f10, f2, f3
    fmul.s  f10, f10, f8
    jal     calculate_function

    fmul.s  f11, f4, f5
    fadd.s  f9, f9, f11

    fmul.s  f12, f8, f9
    fmul.s  f12, f12, f8

    li      a7, 2
    fmv.s   fa0, f12
    ecall

    fsub.s  f13, f12, f5
    fabs.s  f13, f13
    feq.s   s1, f13, f4
    bnez    s1, loop

finish:
    li      a7, 10
    ecall

calculate_function:
    fmul.s  f5, f0, f0
    fdiv.s  f6, f1, f5
    fadd.s  f0, f0, f6
    jr      ra
