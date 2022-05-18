assume cs:code1, ds:data1

stack1 segment stack
		dw	200 dup(?)
	ws1	dw	?
stack1 ends

data1 segment
	buffer		db	200 dup('$')
	text_ask_a	db	"Input a (range: 0-8): $"
	text_ask_b	db	"Input b (range: 0-8): $"
	text_result_x	db	"f(x) = 0 when x = $"
	text_result_y	db	"f(0) = $"
	nl		db	13, 10, '$'
	valueA		dw	?
	valueB		dw	?
	root		db	?
	axis_size	db	20
data1 ends

code1 segment

start1:	
	mov	ax, seg stack1		; initialize stack
	mov	ss, ax
	mov	sp, offset ws1

	call	process_input

	mov	ax, 4c00h		; end program
	int	21h

process_input:
	call	get_ab

	xchg	ax, bx			; xchg exchanges values (now a = bx, b = ax)

	neg	al			; negate al, then unfold al to ax
	cbw
	idiv	bl			; ah - remainder, al = result

	add	al, 48d
	call	print_regs

	mov	dx, seg buffer
	mov	es, dx
	mov	di, offset buffer

	mov	byte ptr es:[di], al
	mov	byte ptr es:[di + 1], 13d
	mov	byte ptr es:[di + 2], 10d
	mov	byte ptr es:[di + 3], '$'
	
	mov	dx, offset buffer
	call	base_print
	
	mov	dx, offset text_result_x
	call	base_print

	mov	dx, offset nl
	call	base_print

	call	print_regs
	ret

get_ab:
	mov 	dx, offset text_ask_a	; prompt user for a value
	call	base_print

	mov	ah, 1			; int 21,1 - keyboard input with echo
	int	21h
	xor	ah, ah			; clear ah register (al = a value)

	sub	ax, 48d			; convert to integer
	
	mov	word ptr [ds:valueA], ax

	mov	dx, offset nl		; print text at ds:dx - here newline
	call	base_print

	mov	dx, offset text_ask_b	; prompt user for b value
	call	base_print
	
	mov	ah, 1
	int	21h
	xor	ah, ah

	sub	ax, 48d
	mov	word ptr [ds:valueB], ax

	mov	dx, offset nl
	call	base_print

	mov	ax, word ptr [ds:valueA]
	mov	bx, word ptr [ds:valueB]
	ret

base_print:
	mov	ax, seg data1
	mov	ds, ax
	mov	ah, 9
	int	21h
	ret

print_regs:
    ; save registers
    push ax
    push bx
    push cx
    push dx

    push dx
    mov dx, seg buffer 
    mov es, dx ; setup extended segment
    mov di, offset buffer ; save offset to di
    pop dx

    ; --------- print ax
    push ax ; push arg to stack
    call byte_to_decimal_string

    mov ax, offset buffer
    push ax ; push arg to stack
    call print1

    ; --------- print bx
    push bx ; push arg to stack
    call byte_to_decimal_string

    mov ax, offset buffer
    push ax ; push arg to stack
    call print1

    ; --------- print cx
    push cx ; push arg to stack
    call byte_to_decimal_string

    mov ax, offset buffer
    push ax ; push arg to stack
    call print1

    ; --------- print dx
    push dx ; push arg to stack
    call byte_to_decimal_string

    mov ax, offset buffer
    push ax ; push arg to stack
    call print1

    ; print newline
    push dx
    mov dx, offset nl
    push dx ; push arg to stack
    call print1
    pop dx

    ; load saved registers
    pop dx
    pop cx
    pop bx
    pop ax
    ret

byte_to_decimal_string:
    push bp ; save old base pointer on stack
    mov bp, sp ; set new base pointer in place of stack pointer
    push ax
    push bx
    push dx


    mov ax, word ptr ss:[bp + 4] ; get arg
    mov bx, 10d

    mov dx, 0
    div bx ; ax = (dx ax) / bx, dx = remainder
    add dl, 48d ; add 48d to remainder so it encodes ascii char
    mov byte ptr es:[di + 4], dl ; return  remainder as it is char to display

    mov dx, 0
    div bx ; ax = (dx ax) / bx, dx = remainder
    add dx, 48d ; add 48d to remainder so it encodes ascii char
    mov byte ptr es:[di + 3], dl ; return  remainder as it is char to display

    mov dx, 0
    div bx ; (dx ax) = ax / bx, dx = remainder
    add dx, 48d ; add 48d to remainder so it encodes ascii char
    mov byte ptr es:[di + 2], dl ; return  remainder as it is char to display

    mov dx, 0
    div bx ; ax = (dx ax) / bx, dx = remainder
    add dx, 48d ; add 48d to remainder so it encodes ascii char
    mov byte ptr es:[di + 1], dl ; return  remainder as it is char to display

    mov dx, 0
    div bx ; ax = (dx ax) / bx, dx = remainder
    add dx, 48d ; add 48d to remainder so it encodes ascii char
    mov byte ptr es:[di], dl ; return  remainder as it is char to display

    ; add newlines and terminate char
    mov byte ptr es:[di + 5], 10d 
    mov byte ptr es:[di + 6], 13d 
    mov byte ptr es:[di + 7], '$'

    pop dx
    pop bx
    pop ax
    mov sp, bp ; delete local variables - not needed here
    pop bp ; retrive old base pointer
    ret 2d

print1:
    push bp ; save old base pointer on stack
    mov bp, sp ; set new base pointer in place of stack pointer
    push ax
    push dx
    ; stack looks like this:
    ; 0:1 -> bp
    ; 2:3 -> return address
    ; 4:5 -> arguments start

    mov dx, word ptr ss:[bp + 4] ; get arg from stack
    mov ax, seg data1 
    mov ds, ax ; put data1 segment pointer into ds
    mov ah, 9 ; print text command id
    int 21h ; DOS interupt

    pop dx
    pop ax
    mov sp, bp ; delete local variables - not needed here
    pop bp ; retrive old base pointer

    ret 2d ; we return two so sp = sp - 2, so arguemnt is poped off stack

code1 ends

end start1
