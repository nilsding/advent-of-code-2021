; solution for advent of code 2021, day 1
;
; platform:
;   arm64 on darwin
;
; build with:
;   as -o 01.o 01.s && ld -o 01 01.o -lSystem -syslibroot $(xcrun -sdk macosx --show-sdk-path) -e _start -arch arm64
;
; usage:
;   ./01 < file
;
; bugs:
;   plenty, i'm sure.  i think it shows that i don't usually write assembly, let alone for aarch64 :-)

.equ SYS_exit,  1
.equ SYS_read,  3
.equ SYS_write, 4

.equ STDIN, 0
.equ STDOUT, 1

.global _start
.text
.align 4

_start:

mainloop:
    bl read_buf                ; read into buffer
    cbz x0, mainloop_end       ; 0 bytes read -> we're done here, exit the main loop

    ; load address of buffer into x1
    adrp x1, buf@PAGE
    add x1, x1, buf@PAGEOFF
mainloop_readnum:
    bl readnum

    ; load address of lastnum into x24
    adrp x24, lastnum@PAGE
    add x24, x24, lastnum@PAGEOFF
    ldr x26, [x24]             ; load current value of lastnum into x26
    str x0, [x24]              ; store the read number into lastnum

    ; load address of incrcnt into x25
    adrp x25, incrcnt@PAGE
    add x25, x25, incrcnt@PAGEOFF
    ldr x27, [x25]             ; load current value of incrcnt into x27
    cmp x0, x26                ; compare previous value of lastnum (x26) with the newly read one (x0)
    b.le mainloop_readnum_tail ; branch away if comparison is less than or equal
    add x27, x27, #1           ; increment incrcnt (x27)
    str x27, [x25]             ; store incrcnt
mainloop_readnum_tail:
    cbz x2, mainloop           ; if there are no more bytes available to read (x2, ret'd from `readnum`) read moar bytez

    ; prepare registers to what readnum expects
    mov x0, x2                 ; readnum expects bytes available to read in x0

    b mainloop_readnum

mainloop_end:
    sub x0, x27, #1            ; decrement 1 from readnum as we also counted the very first number, store it in x0 for print_decimal
    bl print_decimal
    b quit

quit:
    mov x0, #0                 ; return 0
    b exit

readnum:
    ; params:
    ; x0 = number of bytes available to read
    ; x1 = the buffer
    mov x24, x0                ; bytes left to read
    mov x25, #0                ; temp value
    mov x26, #10               ; used for multiplication
    mov x0, #0                 ; will be the number being read
readnum_loop:
    ldrb w25, [x1], 1          ; load the byte value at x1 into w25, and increment x1 by 1

    subs x25, x25, #0x30       ; subtract the value from ascii '0', `subs` updates ALU flags
    b.mi readnum_done          ; exit the loop if the number is less than 0
    cmp x25, #10               ; check if the number is greater than or equal 10
    b.ge readnum_done          ; exit the loop if it is

    mul x0, x0, x26            ; multiply the number read by 10
    add x0, x0, x25            ; add the read value to x0
readnum_end: ; yeah i know this is ugly, but it works :o)
    sub x24, x24, #1           ; decrease bytes to read
    cbnz x24, readnum_loop     ; still have bytes to read -> restart loop
    b readnum_ret
readnum_done:
    sub x24, x24, #1           ; decrease bytes to read
readnum_ret:
    ; returns:
    ; x0 = the number read
    ; x1 = new buffer position
    ; x2 = bytes left to read
    mov x2, x24
    ret

exit:
    ; params:
    ; x0 = return code
    mov x16, SYS_exit
    svc #0x80                  ; do syscall
    ; no ret, program ends here

print_decimal:
    ; params:
    ; x0 = number to convert to decimal

    ; reusing the same buffer we use for reading might sound like a bad idea,
    ; and it is!  so please, please, please do NOT call this subroutine while
    ; in any readloop
    adrp x1, buf@PAGE
    add x1, x1, buf@PAGEOFF
    ; add buf_len - 1 so we can start at the end
    mov x2, buf_len
    add x1, x1, x2
    sub x1, x1, #1
    mov x2, #0                 ; this will be the buf_len that will be incremented with each iteration
    mov x23, x1

    ; store a \n at the end 
    mov x25, #0x0a             ; x25 = '\n'
    strb w25, [x23], -1        ; store the byte value at w25 into x23, and decrement x23 by 1
    add x2, x2, #1             ; increment buf_len

print_decimal_loop:
    ; arm64 doesn't do division with a remainder :-(
    mov x26, #10               ; x26 = #10
    sdiv x24, x0, x26          ; x24 = x0 / x26
    msub x25, x24, x26, x0     ; x25 = x0 - x24 * x26 (remainder)

    add x25, x25, #0x30        ; add ascii '0' to the remainder
    strb w25, [x23], -1        ; store the byte value at w25 into x23, and decrement x23 by 1
    add x2, x2, #1             ; increment buf_len
    mov x0, x24                ; store next number into x0
    cbnz x0, print_decimal_loop

    add x23, x23, 1            ; move forward 1 character
    ; prepare for printing
    ; x0 = file descriptor
    ; x1 = string to print
    ; x2 = string length
    mov x0, STDOUT
    mov x1, x23
    mov x16, SYS_write
    svc #0x80                  ; do syscall

    ret

read_buf:
    ; params:
    ; x1 = address of buffer
    ; x2 = buffer length
    mov x0, STDIN
    ; load address of buffer
    adrp x1, buf@PAGE
    add x1, x1, buf@PAGEOFF
    mov x2, buf_len
    mov x16, SYS_read
    svc #0x80
    ; returns:
    ; x0 = bytes read
    ret

.data
.align 4
lastnum: .skip 8               ; last read number
incrcnt: .skip 8               ; # of increments
buf: .skip 32767               ; big chungus buffer
buf_len = . - buf
