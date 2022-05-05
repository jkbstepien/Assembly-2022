; TL;DR
; 	- How to pass arguments to our program.

assume cs:code1, ds:dane1

dane1 segment
	buff1	db	300 dup('$')	
dane1 ends

; PSP - Program Segment Prefix

code1 segment
;	ds: points to PSP
;	080h -> ilość znaków argc
;	081h -> spacja
;	082h -> string parametrow

start1:
	mov	ax, seg ws1
	mov	ss, ax
	mov	sp, offset ws1
	
	mov 	ax, seg buff1
	mov 	es, ax
	; ds = PSP
	mov 	si, 082h			; what to copy
	mov 	di, offset buff1		; where to copy
	xor 	cx, cx
	mov 	cl, byte ptr ds:[80h]		; number of elements

;p1:
;	mov	al, byte ptr ds:[si]
;	mov	byte ptr es:[di], al
;	inc	si
;	inc	di
;	loop	p1

	cld					; clear direction flag DF=0
	rep	movsb				; es:[di] <= ds:[si], si += 1, di += 1

	mov	dx, offset buff1
	call	txt1

	mov	ax, 4c00h			; end program
	int 	21h

;-------------------------------
;	in: dx = offset text do wypisania
txt1:
	mov 	ax, seg dane1
	mov 	ds, ax

	mov 	ah, 9
	int 	21h
	ret
;-------------------------------

code1 ends

stack1 segment stack
		dw	200 dup(?)
	ws1	dw	?
stack1 ends

end start1
