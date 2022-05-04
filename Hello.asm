assume cs:code, ds:dane

dane segment
	napis	db "Hello world!$"
dane ends

code segment
start:
	mov ax, seg stack1
	mov ss, ax
	mov sp, offset ws1

	mov ax, seg napis
	mov ds, ax
	mov dx, offset napis
	mov ah, 9		; print text ds:dx
	int 21h			; DOS interrupt
	mov ah, 4ch		; end program
	int 21h
code ends

stack1 segment stack
		dw	200 dup(?)
	ws1	dw	?
stack1 ends

end start
