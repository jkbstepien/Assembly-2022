assume cs:code1, ds:data1

data1 segment

a4	dw	12
d1	db	13, 14, 15, 16
text1	db	"ABC$" 

data1 ends

code1 segment
start1:
	mov ax, seg ws1
	mov ss, ax
	mov sp, offset ws1

	mov ax, seg text1
	mov ds, ax
	mov dx, offset text1

	mov ah, 9
	int 21h
	mov ax, 4c00h
	int 21h

code1 ends

stack1 segment stack

	dw	200 dup(?)
ws1 	dw 	?

stack1 ends

end start1
