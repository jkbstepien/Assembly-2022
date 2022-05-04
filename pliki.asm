
dane1 segment
    brak_miejsca db "Brak miejsca zerowego$"
    XX_array dw 0,100,20
    YY_array dw 0,100,10
    POINTR dw 0
    nazwa db "nazwa.txt", 0
    wsk1 dw ?
    buf1 db 300 dup("$")
dane1 ends

stos1 segment stack
        dw 200 dup(?)
    ws1 dw ?
stos1 ends

code1 segment
assume cs:code1, ds:dane1 ; mounts seg danych i inicjalizuje stos
.486



s1:
    ; ;segment danych do DS
    ; mov ax, seg dane1
    ; mov ds, ax

    ; ;inicjalizacja stosu
    mov ax,seg stos1
    mov ss,ax
    mov sp,offset ws1

    xor ax,ax
    xor bx,bx

; open
    mov ax, seg dane1
    mov ds, ax
    mov dx, offset nazwa
    mov al, 0
    mov ah, 03dh
    int 21h ; open file in nazwa
    mov word ptr ds:[wsk1], ax ; kod bledu

;read 
    mov ax, seg buf1
    mov ds, ax
    mov dx, offset buf1 ; ds:dx -> wsk na bufor
    mov cx, 299 ;czytamy max 299 znaków

    mov bx, word ptr ds:[wsk1]
    mov ah, 03fh
    int 21h ; wcyztaj znaki
    ; if CF=0 then ax = ilosc wczytanych znakow
    
; close
    mov bx, word ptr ds:[wsk1]
    mov ah, 3eh
    int 21h ; zamykanie pliku

    mov ax, seg buf1
    mov ds, ax
    mov dx, offset buf1
    mov ah, 9
    int 21h
    
    



koniec:   

    xor ax, ax
    ;koniec programu
    mov ah,4ch
    int 21h	

code1 ends


end s1
