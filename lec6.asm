; TL;DR
; Accessing video memory directly - this time in text mode.
; Using devices through ports;

assume cs:code1

code1 segment

start1:
	mov	ax, seg ws1
	mov	ss, ax
	mov	sp, offset ws1

	mov	ax, 0b800h			; cleaning screen
	mov	es, ax
	mov	di, 0;				; es:di -> first cell on the screen
	mov	cx, 2000
	mov	ah, 00011111b			; attribute
	mov	al, 'x'				; char
	cld
	rep	stosw

	mov	ax, 0b800h			; first memory cell in text mode
	mov	es, ax
	mov	si, 12*160+40*2			; es:si -> cell on the screen

	mov	al, 65				; ASCII
	mov	ah, 01001111b			; attribute
	mov	word ptr es:[si], ax

p1:	
	in	al, 060h			; read from keyboard SCANCODE
	cmp	al, byte ptr cs:[k1]
	jz	p1
	mov	byte ptr cs:[k1], al

	cmp	al, 1				; ESC
	jz	koniec				; jump if flag = 0

	mov	byte ptr es:[si], ' '		; char
	mov	byte ptr es:[si+1], 00000000b	; attribute

	cmp	al, 75				; left
	jnz	p2
	sub	si, 2

p2:
	cmp	al, 77				; right
	jnz	p3
	add	si, 2

p3:
	cmp	al, 72				; up
	jnz	p4
	sub	si, 160

p4:
	cmp	al, 80				; down
	jnz	p5
	add	si, 160

p5:
	mov	byte ptr es:[si], 1		; char
	mov	byte ptr es:[si+1], 01001111b	; attribute
	jmp	p1

koniec:
	mov	ax, 4c00h			; end program
	int 	21h

k1	db	?				; last pressed keycap

code1 ends

stack1 segment stack
		dw	200 dup(?)
	ws1	dw	?
stack1 ends

end start1
