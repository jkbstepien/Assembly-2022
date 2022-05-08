; TL;DR
; Handling external files in assembly program.

assume cs:code1, ds:dane1

dane1 segment
	nazwa1	db	"dane.wej", 0
	wsk1	dw	?
	buf1	db	300 dup("$")
dane1 ends

code1 segment

start1:
	mov	ax, seg ws1
	mov	ss, ax
	mov	sp, offset ws1

;open
	mov	ax, seg nazwa1
	mov	ds, ax
	mov	dx, offset nazwa1		; ds:dx -> pointer to filename
	mov	al, 0
	mov	ah, 03dh
	int	21h				; DOS interrupt - opening file to read
	mov	word ptr ds:[wsk1], ax

;read
	mov	ax, seg buf1
	mov	ds, ax
	mov	dx, offset buf1			; ds:dx -> pointer to buffer
	mov	cx, 299
	mov	bx, word ptr ds:[wsk1]
	mov	ah, 03fh
	int	21h				; read characters from file
	; if CF=0 then ax = no of read characters

;close
	mov	bx, word ptr ds:[wsk1]
	mov	ah, 3eh
	int	21h

;print results
	mov	ax, seg buf1
	mov	ds, ax
	mov	dx, offset buf1
	mov	ah, 9
	int	21h

koniec:
	mov	ax, 4c00h			; end program
	int 	21h

code1 ends

stack1 segment stack
		dw	200 dup(?)
	ws1	dw	?
stack1 ends

end start1
