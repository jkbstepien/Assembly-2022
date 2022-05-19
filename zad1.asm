assume cs:code1, ds:data1

stack1 segment stack
		dw	200 dup(?)
	ws1	dw	?
stack1 ends

data1 segment
	buffer		db	200 dup('$')
	text_ask_a	db	"Input a (range: 1-8): $"
	text_ask_b	db	"Input b (range: 1-8): $"
	text_result_x	db	"f(x) = 0 when x = $"
	text_result_y	db	"f(0) = $"
	text_minus_sign	db	"-$"
	text_test	db	"TEST", 13, 10, '$'
	nl		db	13, 10, '$'
	valueA		dw	?, '$'
	valueB		dw	?, '$'
	root		db	?
	ctr_in		dw	?
	text_plot_scale	db	13, 10, "One character equals 1 unit.$"
data1 ends

code1 segment

start1:	
	mov	ax, seg stack1		; initialize stack
	mov	ss, ax
	mov	sp, offset ws1

process_input:
	call	get_ab

	xchg	ax, bx			; xchg exchanges values (now a = bx, b = ax)

	neg	al			; negate al, then unfold al to ax
	cbw
	idiv	bl			; ah - remainder, al = result

	mov	dx, offset text_result_x ; print answer for f(x)=0
	call	base_print
	
	cmp	al, 0
	jge	nonnegative

	mov	dx, offset text_minus_sign
	call	base_print

	neg	al
;	xchg	ax, bx

nonnegative:
	add	ax, 48d
	mov	[ds:valueA], ax

	mov	dx, offset valueA
	call	base_print

	mov	dx, offset nl		; print answer for y when x=0
	call	base_print
	mov	dx, offset text_result_y
	call	base_print
	mov	dx, offset valueA
	call	base_print

	sub	ax, 48d
	mov	[ds:valueA], ax

	mov	dx, offset nl
	call	base_print

plot:
	mov	dx, seg buffer
	mov	es, dx
	mov	di, offset buffer

	mov	byte ptr es:[di + 1], '$'

	mov	cx, 20d
	loop1:
		push	cx
		mov	[ds:ctr_in], cx
		mov	cx, 20d

		loop2:
			mov	byte ptr es:[di], ' '
			check0:
				cmp	cx, 10d
				jne	check1
				mov	byte ptr es:[di], '#'
			check1:
				cmp	[ds:ctr_in], 10d
				jne	check2
				mov	byte ptr es:[di], '#'
			check2:
				xor	ax, ax
				xor	bx, bx

				mov	ax, 10d
				mov	bx, [ds:valueA]
				sub	ax, cx
				imul	bl
				mov	bx, [ds:valueB]
				add	ax, bx
				sub	ax, [ds:ctr_in]
				add	ax, 10d

				cmp	ax, 0
				jne	end_loop2
				mov	byte ptr es:[di], '*'

			end_loop2:
				mov	dx, offset buffer
				call	base_print
				loop	loop2

		mov	dx, offset nl
		call	base_print
		pop	cx
		loop	loop1

end1:
	mov	dx, offset text_plot_scale
	call	base_print

	mov	ax, 4c00h
	int	21h

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
	push	ax
	mov	ax, seg data1
	mov	ds, ax
	mov	ah, 9
	int	21h
	pop	ax
	ret

print_regs:
    mov dx, offset nl
    call base_print
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
