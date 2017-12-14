section .rodata
    b: equ 13
    a: equ 10

section .data
    z: dq 6

section .bss
    y: resb 8
    x: resb 8

section .text
global main
    main:
        push rbp
        mov  rbp, rsp

        sub  rsp, (16)
        mov  rdi, ___string0
        add  rsp, (-8)
        mov  rsi, rsp
        xor  rax, rax
        call scanf
        mov  rax, [rsp]
        add  rsp, (8)
        mov  [rbp - (8)], rax
        mov  rax, [z]
        mov  [rbp - (16)], rax
        mov  rax, [rbp - (8)]
        add  rax, [rbp - (16)]
        mov  [z], rax
        mov  rdi, ___string2
        mov  rsi, ___string1
        xor  rax, rax
        call printf
        mov  rax, [rbp - (8)]
        mov  rdi, ___string0
        mov  rsi, rax
        xor  rax, rax
        call printf
        mov  rdi, ___string2
        mov  rsi, ___string3
        xor  rax, rax
        call printf
        mov  rax, [rbp - (16)]
        mov  rdi, ___string0
        mov  rsi, rax
        xor  rax, rax
        call printf
        mov  rdi, ___string2
        mov  rsi, ___string4
        xor  rax, rax
        call printf
        mov  rax, [z]
        mov  rdi, ___string0
        mov  rsi, rax
        xor  rax, rax
        call printf
        mov  rdi, ___string2
        mov  rsi, ___string5
        xor  rax, rax
        call printf
        sub  rsp, (8)
        sub  rsp, (-8)

        sub  rsp, (-16)
        pop  rbp
        mov  rax, [z]
        ret

global sum
    sum:
        push rbp
        mov  rbp, rsp

        mov  rax, [rbp - (-8)]
        add  rax, [rbp - (-16)]

        pop  rbp
        ret


section .rodata
    ___string3: db `\ny = `, 0
    ___string5: db `\n`, 0
    ___string1: db `x = `, 0
    ___string0: db `%lld`, 0
    ___string2: db `%s`, 0
    ___string4: db `\nz = `, 0

extern printf
extern scanf
