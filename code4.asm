; TL;DR
; 	- Drawing colors.

assume cs:code1

code1 segment

start1:
	mov	ax, seg ws1
	mov	ss, ax
	mov	sp, offset ws1

	mov	al, 13h				; graphic mode 320x200 256 colours
	mov	ah, 0				; change mode of VGA card
	int	10h
	
	mov	word ptr cs:[x], 0
	mov	word ptr cs:[y], 50
	mov	byte ptr cs:[k], 15
	mov	cx, 70

p0:	push	cx
;-----------------------------------------
	mov	cx, 255
p1:
	push	cx
	mov	al, byte ptr cs:[x]
	mov	byte ptr cs:[k], al
	call 	point
	inc	word ptr cs:[x]
	pop	cx
	loop	p1

;-----------------------------------------
	mov	word ptr cs:[x], 0
	inc	word ptr cs:[y]
	pop	cx
	loop	p0

	xor	ax, ax
	int	16h				; wait for keyboard

koniec:
	mov	al, 3				; text mode
	mov	ah, 0				; change mode of VGA card
	int	10h
	
	mov	ax, 4c00h			; end program
	int 	21h

;-----------------------------------------
; Parameters used for drawing colours:
x	dw	?				; x position
y	dw	?				; y position
k	db	?				; desired colour

point:
	mov	ax, 0a000h
	mov	es, ax
	mov	bx, 320
	mov	ax, word ptr cs:[y]
	mul	bx				; dx:ax = ax*bx -> ax = 320*y
	mov	bx, word ptr cs:[x]
	add	bx, ax				; -> bx = 320*y + x
	mov	al, byte ptr cs:[k]
	mov	byte ptr es:[bx], al		; colour point on the screen
	ret
;-----------------------------------------

code1 ends

stack1 segment stack
		dw	200 dup(?)
	ws1	dw	?
stack1 ends

end start1
