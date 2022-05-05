assume cs:code1, ds:dane1

dane1 segment
	text1	db "Hello world!$"
	text2	db 13, 10, "123456$"
	text3	db 13, 10, "Dobrze chlopaki robia$"
dane1 ends

code1 segment
start1:
	mov ax, seg stack1
	mov ss, ax
	mov sp, offset ws1

	mov dx, offset text1
	call txt1
	
	mov dx, offset text2
	call txt1

	mov dx, offset text3
	call txt1

	mov ax, 4c00h		; end program
	int 21h

;-------------------------------
;	in: dx = offset text do wypisania
txt1:
	mov ax, seg dane1
	mov ds, ax

	mov ah, 9
	int 21h
	ret
;-------------------------------

code1 ends

stack1 segment stack
		dw	200 dup(?)
	ws1	dw	?
stack1 ends

end start1
