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
	text_error	db	13, 10, "Error: Invalid argument!$"
	text_err_range	db	13, 10, "Error: Out of range! Try 0-255.$"
	text_inf	db	"No root!$", 13, 10
	nl		db	13, 10, '$'
	valueA		dw	?, '$'
	valueB		dw	?, '$'
	ctr_in		dw	?
	plot_size	dw	20d ; works best between 10 and 40
	mid_point	dw	?
	text_plot_scale	db	13, 10, "One character equals 1 unit.$"
	tmp_num 	dw 	?
data1 ends

code1 segment

start1:	
	mov	ax, seg stack1			; initialize stack
	mov	ss, ax
	mov	sp, offset ws1

process_input:
	call	get_ab				; get input from user: now ax = a, bx = b
	
	call	validate_range			; validate if values of (a,b) are within correct range

	cmp	ax, 0				; check if a == 0, handling div 0 error
	jne	handle_not_zero			; if no -> jump to next point 
	
	mov	dx, offset text_inf		; if yes -> print text about no function root
	call	base_print
	jmp	print_rest			; jump to processing b value

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
				sub	al, cl

				mov	bx, word ptr ds:[valueA]
				imul	bl

				mov	bx, word ptr ds:[valueB]

				add	ax, bx

				sub	ax, [ds:ctr_in]

				add	ax, word ptr ds:[mid_point]

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
	mov	dx, offset text_plot_scale	; before exiting:
	call	base_print			; print info about plot scale

	mov	ax, 4c00h			; INT 21, 0 - program terminate
	int	21h

error_end:
	mov	dx, offset text_error		; before exiting with incorrect input:
	call	base_print			; print suitable error message

	mov	ax, 4c00h			; INT 21, 0 - program terminate
	int	21h

error_range_end:
	mov	dx, offset text_err_range	; before exiting with incorrect range of (a,b)
	call	base_print			; print suitable error message

	mov	ax, 4c00h			; INT 21, 0 - program terminate
	int	21h

validate_range:
						; ax = a, bx = b
	cmp	ax, 0				; check if a < 0 then print error else pick next cond
	jl	error_range_end
	cmp	ax, 255				; check if a > 255 then print error else next cond
	jg	error_range_end
	cmp	bx, 0				; check if b < 0 then print error else next cond
	jl	error_range_end
	cmp	bx, 255				; check if b > 255 then print error else next cond
	jg	error_range_end
	ret					; if everything's fine -> return to program main part

putchar1:
	mov	ah, 2			  	; print char stored in dl register
	int	21h
	ret

getchar1:
	mov	ah, 1				; INT 21, 1 - keyboard input with echo
	int	21h				; out: in al register is char from stdin
	ret

getnum1:
	; out: current num, sign
    	call 	getchar1			; load char to process
    	cmp 	al, 13   			; 13 represents carriage return
    	jne 	getnum1_loop			; if encountered -> return
    	ret

    	getnum1_loop:
    		cmp	al, '0'
    		jl 	error_end
    		cmp 	al, '9'
    		jg 	error_end

        	mov 	bl, al 				; we need to copy to bl as ax will be destroyed
        	mov 	ax, word ptr ds:[tmp_num] 	; store in ax partial result
        	mov 	cx, 10
        	mul 	cx          			; curr_number = curr_number * 10

        	sub 	bl, '0'     			; 'digit'-'0' = digit, in bl we store curr char
        	xor 	bh, bh				; reset bh register
        	add 	ax, bx      			; curr_num = curr_num + digit

        	mov 	word ptr ds:[tmp_num], ax 	; add new partial result
        	jmp 	getnum1     			; handle next character

printnum1:
	; in: ax = number to print
	cmp	ax, 0				; check sign
    	jge	positive_num
    	neg 	ax

    	positive_num:
    		mov 	cx, 0        
    		mov 	bl, 10       		; system base (in which be printed)

    		pushloop1:
        		div 	bl          	; al = ax / bl
                        			; ah = ax % bl

        		push	ax          	; digit pushed on stack
        
        		inc	cx          	; digit counter

        		mov	ah, 0        	; cleaning ax

        		cmp	ax, 0        	; repeat while ax != 0
        		jne 	pushloop1

    		poploop1:
        		pop	dx          	; popping digits
        		mov 	dl, dh       	; in dh (originally ah) is remainder
        		call	printdig1
	
			loop	poploop1

    	ret

printdig1:
	add	dl, 48d				; convert digit to char, stored in dl register
	call 	putchar1			; print char
	ret

get_ab:
	mov     dx, offset text_ask_a   	; prompt user for a value
	call    base_print

	mov 	word ptr ds:[tmp_num], 0	; get number and store it under valueA
    	call 	getnum1
    	mov 	ax, word ptr ds:[tmp_num]
    	mov 	word ptr [ds:valueA], ax

    	mov 	dx, offset nl       		; print text at ds:dx - here newline
    	call    base_print

    	mov 	dx, offset text_ask_b   	; prompt user for b value
    	call    base_print
    
    	mov 	word ptr ds:[tmp_num], 0	; get number and store it under valueB
    	call 	getnum1
    	mov 	ax, word ptr ds:[tmp_num]
    	mov 	word ptr [ds:valueB], ax

    	mov 	dx, offset nl			; print text at ds:dx - here newline
    	call    base_print

    	mov 	ax, word ptr [ds:valueA]	; before exit we want to have: ax=valueA, bx=valueB
    	mov 	bx, word ptr [ds:valueB]	; because we rely on it in program main part (reusing)
    	ret


base_print:
	push	ax			; base print with ax register preservation
	mov	ax, seg data1
	mov	ds, ax
	mov	ah, 9			; INT 21, 9 - print to the screen
	int	21h
	pop	ax
	ret

code1 ends

end start1
