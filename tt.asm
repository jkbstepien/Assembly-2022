assume cs:code1, ds:data1

stack1 segment stack
		dw	200 dup(?)
	ws1	dw	?
stack1 ends

data1 segment
	buffer		db	200 dup('$')
	text_ask_a	db	"Input a (range: 0-255): $"
	text_ask_b	db	"Input b (range: 0-255): $"
	text_result_x	db	"f(x) = 0 when x = $"
	text_result_y	db	"f(0) = $"
	text_minus_sign	db	"-$"
	text_slash	db	"/$"
	text_test	db	"TEST", 13, 10, '$'
	text_inf	db	"No root!$", 13, 10
	nl		db	13, 10, '$'
	valueA		dw	?, '$'
	valueB		dw	?, '$'
	root		db	?
	div_res		dw	?, '$'
	ctr_in		dw	?
	plot_size	dw	20d ; works best between 10 and 40
	mid_point	dw	?
	text_plot_scale	db	13, 10, "One character equals 1 unit.$"
	tmp_num 	dw 	?
data1 ends

code1 segment

start1:	
	mov	ax, seg stack1		; initialize stack
	mov	ss, ax
	mov	sp, offset ws1

process_input:
	call	get_ab			; now ax = a, bx = b

	cmp	ax, 0
	jne	handle_not_zero
	mov	dx, offset text_inf
	call	base_print
	jmp	print_rest

	handle_not_zero:
	cmp	ax, bx
	jg	print_frac		; case ax > bx

	;case ax <= bx
	xchg	ax, bx

	div	bl			; ah - rem, al - res
	
	mov	dx, offset text_result_x
	call	base_print
	mov	dx, offset text_minus_sign
	call	base_print
	
	push	ax

	mov	ah, 0			; round down
	call	printnum1

	pop	ax

	cmp	ah, 0
	je	print_rest

	mov	al, ah
	mov	ah, 0

	mov	dl, ' '
	push	ax
	call	putchar1
	pop	ax
	call	printnum1
	mov	dl, '/'
	call	putchar1
	mov	ax, word ptr ds:[valueA]
	call	printnum1

	mov	bx, word ptr ds:[valueB]
	jmp	print_rest

	print_frac:
		
		mov	dx, offset text_result_x ; print answer for f(x)=0
		call	base_print
		mov	dx, offset text_minus_sign
		call	base_print

		mov	ax, word ptr ds:[valueB]
		call	printnum1
		mov	dl, '/'
		call	putchar1
		mov	ax, word ptr ds:[valueA]
		call	printnum1

	print_rest:
	mov	dx, offset nl		; print answer for y when x=0
	call	base_print
	mov	dx, offset text_result_y
	call	base_print

	mov	ax, word ptr ds:[valueB]
	call	printnum1

;	sub	ax, 48d
;	sub	bx, 48d
;	mov	word ptr ds:[div_res], ax
;	mov	word ptr ds:[valueB], bx

	mov	dx, offset nl
	call	base_print

	xor	ax, ax
	xor	bx, bx

plot:
	mov	ax, word ptr ds:[plot_size]
	mov	bx, 2
	idiv	bl
	cbw
	mov	word ptr ds:[mid_point], ax

	mov	dx, seg buffer
	mov	es, dx
	mov	di, offset buffer

	mov	cx, word ptr ds:[plot_size]
	loop1:
		push	cx
		mov	[ds:ctr_in], cx			; row
		mov	cx, word ptr ds:[plot_size]	; column

		loop2:
			mov	byte ptr es:[di], ' '
			check0:
				cmp	cx, word ptr ds:[mid_point]
				jne	check1
				mov	byte ptr es:[di], '#'
			check1:
				mov	dx, [ds:ctr_in]
				cmp	dx, word ptr ds:[mid_point]
				jne	check2
				mov	byte ptr es:[di], '#'
			check2:
				xor	ax, ax
				xor	bx, bx
				mov	ax, word ptr ds:[mid_point]
;				call	 print_regs
				sub	al, cl

				mov	bx, word ptr ds:[valueA]
				imul	bl
;				call	 print_regs

				mov	bx, word ptr ds:[valueB]
;				call	 print_regs

				add	ax, bx
;				call	 print_regs

				sub	ax, [ds:ctr_in]
;				call	 print_regs

				add	ax, word ptr ds:[mid_point]
;				call	 print_regs
;				jmp	end1

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

putchar1:
; in = dl, character to output
	mov	ah, 2	; print char from dl
	int	21h
	ret

getchar1:
; out: al = character from standard input device
    mov ah, 1  ; INT 21,1 - Keyboard Input with Echo
    int 21h
    ret

getnum1:
; out: tmp_num, tmp_sign
    call getchar1
    cmp al, 13      
    jne getnum1_loop 
    ; if entered carriage return
    ret

    getnum1_loop:
        mov bl, al
        mov ax, word ptr ds:[tmp_num]
        mov cx, 10
        mul cx          ; tmp_num = tmp_num * 10

        sub bl, '0'     ; 'digit' - '0' = digit
        xor bh, bh
        add ax, bx      ; tmp_num = tmp_num + digit

        mov word ptr ds:[tmp_num], ax
        jmp getnum1     ; handle next character
;getnum1

printnum1:  ; in: ax = number to print
    cmp	ax, 0
    jge	positive_num
      neg ax

    positive_num:
    push cx          ; cx can be used
    mov cx, 0        
    mov bl, 10       ; system base (in which be printed)

    pushloop1:
        div bl          ; al = ax / bl
                        ; ah = ax % bl

        push ax          ; digit pushed on stack
        
        inc cx          ; digit counter

        mov ah, 0        ; cleaning ax

        cmp ax, 0        ; repeat while ax != 0
        jne pushloop1
    ;pushloop1

    poploop1:
        pop dx          ; popping digits
        mov dl, dh       ; in dh (originally ah) is remainder
        call printdig1

        dec cx          ; decrease digit count
        cmp cx, 0        ; repeat while cx > 0
        ja poploop1
    ;poploop1

    pop     cx
    ret
;printnum1

printdig1:
	; in = dl - digit to print
	add	dl, 48d
	call 	putchar1
	ret

get_ab:
    mov     dx, offset text_ask_a   ; prompt user for a value
    call    base_print

    mov word ptr ds:[tmp_num], 0
    call getnum1
    mov ax, word ptr ds:[tmp_num]
    mov word ptr [ds:valueA], ax

    mov dx, offset nl       ; print text at ds:dx - here newline
    call    base_print

    mov dx, offset text_ask_b   ; prompt user for b value
    call    base_print
    
    mov word ptr ds:[tmp_num], 0
    call getnum1
    mov ax, word ptr ds:[tmp_num]
    mov word ptr [ds:valueB], ax

    mov dx, offset nl
    call    base_print

    mov ax, word ptr [ds:valueA]
    mov bx, word ptr [ds:valueB]
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
