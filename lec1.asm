data segment

a4	dw 12
d1	db 13, 14, 15, 16
text1	db "ABC$"

data ends

code segment

s1:	mov ax, seg stos
	mov ss, ax
	mov sp, offset ws1
	
	mov ax, seg text1
	mov ds, ax
	mov dx, offset text1
	mov ah, 9		; wypisz tekst ds:dx
	int 21h			; przerwanie DOS

	mov ax, 4c00h		; zakoncz program
	int 21h

code ends

stos segment stack

	dw	200 dup(?)
ws1	dw	?

stos segment ends

end s1
