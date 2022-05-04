code1 segment

start1:
    mov ax, seg ws1
    mov ss, ax
    mov sp, offset ws1


; czyszczenie ekranu
    mov ax, 0b800h ; pamięc w trybie tekstowym
    mov es, ax
    mov di, 0 ; es:di poczatek ekranu
    mov cx, 2000
    mov al, 'x' ; kod znaku
    mov ah, 10011111b; atrybut 
           ;MRGBWRGB
    cld
    rep stosw

    mov ax, 0b800h ; pamięc w trybie tekstowym
    mov es, ax
    mov si, 12*160 + 40*2 ; es:si -> pole ekranu

    mov al, 65
    mov ah, 01001111b ; attr
           ;MRGBWRGB
    mov word ptr es:[si], ax

p1:
    in al, 060h ; odczyt z klawiatury SCANCODE
    cmp al, byte ptr cs:[k1]
    jz p1

    mov byte ptr cs:[k1], al

    cmp al, 1 ; escape
    jz koniec

    mov byte ptr es:[si], ' '
    mov byte ptr es:[si+1], 00000000b ; attr
                           ;MRGBWRGB


    cmp al, 75 ; left
    jnz p2  
    sub si, 2

p2:
    cmp al, 77 ; right
    jnz p3  
    add si, 2

p3:
    cmp al, 72 ; up
    jnz p4  
    sub si, 160
p4:
    cmp al, 80 ; down
    jnz p5  
    add si, 160

p5:
    mov byte ptr es:[si], 1 ; znak
    mov byte ptr es:[si+1], 01001111b ; attr
                           ;MRGBWRGB

    jmp p1

koniec:
    mov ax, 4c00h ; end program
    int 21h

    k1 db ? ; ostatni wcisniety klawisz

code1 ends


stos1 segment stack
        dw 200 dup(?)
    ws1 dw ? 
stos1 ends

end start1 
