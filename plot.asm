assume cs:code1, ds:data1

stack1 segment stack
		dw	200 dup(?)
	ws1	dw	?
stack1 ends

data1 segment
	buffer		db	200 dup('$')
	text_ask_a	db	"Input a (range: -128 - 127): $"
	text_ask_b	db	"Input b (range: -128 - 127): $"
	text_result_x	db	"f(x) = 0 when x = $"
	text_result_y	db	"f(0) = $"
	text_slash	db	"/$"
	text_error	db	13, 10, "Error: Invalid argument!$"
	text_err_range	db	13, 10, "Error: Out of range! Try -128 - 127.$"
	text_inf	db	"No root!$", 13, 10
	nl		db	13, 10, '$'
	valueA		dw	?, '$'
	valueB		dw	?, '$'
	ctr_in		dw	?
	plot_size	dw	20d ; works best between 10 and 40
	mid_point	dw	?
	text_plot_scale	db	13, 10, "One character equals 1 unit.$"
	part_res 	dw 	?
	part_sgn	db	?
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
		mov	dx, offset text_result_x	; print message for f(x)=0
		call	base_print

		neg  	ax 			; because we want to print -bx/ax 

		cmp 	ax, 0
		jge 	positive_ax

		cmp 	bx, 0
		jge	negative_ax_positive_bx

		jmp 	negative_ax_negative_bx

		positive_ax:
			cmp 	bx, 0
			jge	positive_ax_positive_bx

			jmp  	positive_ax_negative_bx

		negative_ax_positive_bx:
		positive_ax_negative_bx: 		; the same as negative_ax_positive_bx
			call	abs			; we don't know which parameter is negative/positive
			xchg	ax, bx			; so we call abs to obtain absolute value for both
			call 	abs
			xchg 	ax, bx			; xchg swaps values in ax, bx

			; ax = abs(ax), bx = abs(bx)

			; write minus sign
			mov 	dl, '-'
			push 	ax
			call 	write_char
			pop  	ax

			jmp positive_ax_positive_bx	; we handled minus sign so we can use another etiquette to
							; print whole result

		negative_ax_negative_bx:
			call 	abs
			xchg 	ax, bx
			call 	abs
			xchg 	ax, bx

			; ax = abs(ax), bx = abs(bx)

			jmp	positive_ax_positive_bx	; we don't need to print minus as a*b > 0

		positive_ax_positive_bx:
		cmp	bx, 0 				; we don't want to print 0/1
		je     	b_bigger_than_a

		cmp	ax, bx
		jg	print_frac			; case abs(ax) > abs(bx)

		; case abs(ax) <= abs(bx)
		b_bigger_than_a:

			xchg	ax, bx

			; ax and bx are now non negative
			div	bl				; ah - rem, al - res

			push	ax 				; ax will be destroyed
			mov	ah, 0				; round out number down
			call 	abs
			call	write_number			; print result of division
			pop	ax

			cmp	ah, 0				; no remainder -> process b
			je	print_rest

			mov	al, ah				; otherwise, print remainder as: "a/b"
			mov	ah, 0

			mov	dl, ' '				; add space after div result
			push	ax
			call	write_char			; write space
			pop	ax
			call	write_number			; write first number
			mov	dl, '/'
			call	write_char			; write '/'
			mov	ax, word ptr ds:[valueA]	; restore ax with valueA
			call 	abs 	 			; ax = abs(ax)
			call	write_number			; write second number

			mov	bx, word ptr ds:[valueB]	; restore bx with valueB
			jmp	print_rest

	print_frac:
		mov	ax, word ptr ds:[valueB]		; print result in form of: "a/b"
		call 	abs
		call	write_number

		mov	dl, '/'
		call	write_char

		mov	ax, word ptr ds:[valueA]
		call  	abs
		call	write_number

	print_rest:
		mov	dx, offset nl			; print newline
		call	base_print
		mov	dx, offset text_result_y	; print message for f(x) when x=0
		call	base_print

		mov	ax, word ptr ds:[valueB]	; print valueB
		call	write_number

		mov	dx, offset nl			; print newline
		call	base_print

		xor	ax, ax				; clear ax
		xor	bx, bx				; clear bx

plot:
	mov	ax, word ptr ds:[plot_size]		; calculate midpoint of a plot
	mov	bx, 2
	idiv	bl
	cbw						; cbw sign-extends a byte into word.
	mov	word ptr ds:[mid_point], ax

	mov	dx, seg buffer				; initialize buffer using extra segment es
	mov	es, dx
	mov	di, offset buffer

	mov	cx, word ptr ds:[plot_size]		; set outer counter
	loop1:
		push 	cx				; preserve outer cx
		mov	word ptr ds:[ctr_in], cx	; ctr_in = current row
		mov	cx, word ptr ds:[plot_size]	; cx = current column

		loop2:
			mov	byte ptr es:[di], ' '			; by default we print whitespace
			
			check0:
				cmp	cx, word ptr ds:[mid_point]	; check if cx lies on OY
				jne	check1				; no -> check next condition
				mov	byte ptr es:[di], '#'		; yes -> set "#" to be printed
			
			check1:
				mov	dx, word ptr ds:[ctr_in]
				cmp	dx, word ptr ds:[mid_point]	; check if ctr_in lies on OX
				jne	check2				; no -> check next condition
				mov	byte ptr es:[di], '#'		; yes -> set "#" to be printed
			
			; check if point lies on function plot:
			; 	(mid_point - curr_column) * valueA + valueB = curr_row - mid_point
			;	(mid_point - curr_column) * valueA + valueB - curr_row + mid_point = 0
			check2:
				xor	ax, ax				; clear ax
				xor	bx, bx				; clear bx
				
				; mid_point - curr_column
				mov	ax, word ptr ds:[mid_point]
				sub	al, cl
				
				; (mid_point - curr_column) * valueA
				mov	bx, word ptr ds:[valueA]
				imul	bl

				mov	bx, word ptr ds:[valueB]
				; (mid_point - curr_column) * valueA + valueB
				add	ax, bx
				
				; result - curr_row
				sub	ax, word ptr ds:[ctr_in]
				
				; result + mid_point
				add	ax, word ptr ds:[mid_point]

				cmp	ax, 0				; compare to 0
				jne	end_loop2			; no -> jump to end condition
				mov	byte ptr es:[di], '*'		; yes -> set "*" to be printed

			end_loop2:
				mov	dx, offset buffer		; print what's now in buffer
				call	base_print
				loop	loop2

		mov	dx, offset nl			; print newline
		call	base_print

		pop	cx				; restore outer cx
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
	; cmp checks if values passed by user are in valid range
	cmp	ax, -128
	jl	error_range_end
	cmp	ax, 127
	jg	error_range_end
	cmp	bx, -128
	jl	error_range_end
	cmp	bx, 127
	jg	error_range_end
	ret					; if everything's fine -> return to program main part

write_char:
	mov	ah, 2			  	; print char stored in dl register
	int	21h
	ret

read_char:
	mov	ah, 1				; INT 21, 1 - keyboard input with echo
	int	21h				; out: in al register is char from stdin
	ret


read_number:
; in: ax, out: part_res
; cleans part_res and part_sgn, 
; calls read_number_util
; changes sign
	mov	word ptr ds:[part_res], 0
	mov	byte ptr ds:[part_sgn], 0
	call	read_number_util

	mov	al, byte ptr ds:[part_sgn]
	cmp	al, 1
	je	change_sgn
	ret

	change_sgn:
		neg	 word ptr ds:[part_res]
		ret


read_number_util:
	; out: part_res, part_sgn
    	call 	read_char			; load char to process
    	cmp 	al, 13   			; 13 represents carriage return
    	jne 	read_number_loop		; if encountered -> return
    	ret

    	read_number_loop:
    		cmp 	al, '-'				; check if input is a minus sign
    		jne 	no_sgn				; no -> process positive value
    		mov 	byte ptr ds:[part_sgn], 1	; yes -> set part_sign as 1: that means input is negative
    		jmp	read_number_util		; repeat process until read whole number

    		no_sgn:				
    		cmp	al, '0'				; check if input represents a digit.
    		jl 	error_end			; if input is lesser than '0' it can't be a number
    		cmp 	al, '9'				; check if input represents a digit
    		jg 	error_end			; if input is greater than '9' it can't be a number

        	mov 	bl, al 				; we need to copy to bl as ax will be destroyed
        	mov 	ax, word ptr ds:[part_res] 	; store in ax partial result
        	mov 	cx, 10
        	imul 	cx          			; curr_number = curr_number * 10

        	sub 	bl, '0'     			; dig = 'dig' - '0', in bl we store curr char
        	xor 	bh, bh				; reset bh register
        	add 	ax, bx      			; curr_num = curr_num + digit

        	mov 	word ptr ds:[part_res], ax 	; add new partial result
        	jmp 	read_number_util     		; handle next character

write_number:
	; in: ax = number to print
	cmp	ax, 0				; check sign
	jge	positive_num
	mov	dl, '-'

	push 	ax				; write_char destroys ax
	call 	write_char
	pop  	ax
	neg 	ax				; we already handled minus sign so there is no need to work on
						; negative number

    	positive_num:
   		mov 	cx, 0        		; digit counter
    		mov 	bl, 10       		; system base (in which be printed)

    		loop_push:
        		div 	bl          	; al = ax / bl
                        				; ah = ax % bl

        		push	ax          	; digit pushed on stack
        
        		inc	cx          	; digit counter

        		mov	ah, 0        	; cleaning ax

        		cmp	ax, 0        	; repeat while ax != 0
        		jne 	loop_push

    		loop_pop:
        		pop	dx          	; popping digits
        		mov 	dl, dh       	; in dh (originally ah) is remainder
        		call	printdig1
	
			loop	loop_pop

    	ret

printdig1:
	add	dl, 48d				; convert digit to char, stored in dl register
	call 	write_char			; print char
	ret

get_ab:
	mov     dx, offset text_ask_a   	; prompt user for a value
	call    base_print

	call 	read_number 			; get number and store it under valueA
	mov 	ax, word ptr ds:[part_res]
	mov 	word ptr ds:[valueA], ax

	mov 	dx, offset nl       		; print text at ds:dx - here newline
	call    base_print

	mov 	dx, offset text_ask_b   	; prompt user for b value
	call    base_print

	call 	read_number 			; get number and store it under valueB
	mov 	ax, word ptr ds:[part_res]
	mov 	word ptr [ds:valueB], ax

	mov 	dx, offset nl			; print text at ds:dx - here newline
	call    base_print

	mov 	ax, word ptr ds:[valueA]	; before exit we want to have: ax=valueA, bx=valueB
	mov 	bx, word ptr ds:[valueB]	; because we rely on it in program main part (reusing)
	ret


abs:
; in ax, out ax
	cmp 	ax, 0			; check if ax is lesser than 0
	jl 	negative		; yes -> negate ax and return
	ret				; no -> we don't need to modify ax

	negative:
		neg 	ax
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
