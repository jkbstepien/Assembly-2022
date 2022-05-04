dane1   segment
buf1    db      300 dup('$')
dane1   ends

;PSP

code1   segment
;       ds: <= PSP
;       080h -> ilosc znakow
;       081h -> spacja
;       082h -> string parametrow
start1:
    mov     ax, seg ws1
    mov     ss, ax
    mov     sp, offset ws1

    mov     ax, seg buf1
    mov     es, ax
    
    mov     si, 082h
    mov     di, offset buf1

    xor     cx, cx ; = 0
    mov     cl, byte ptr ds:[080h]

; p1:
;     mov     al, byte ptr ds:[si]
;     mov     byte ptr es:[di], al

;     inc     si
;     inc     di
;     loop    p1      ; cx = cx - 1, if cx != 0 then goto p1

    cld                 ; clear direction flag DF = 0
    rep movsb               ; es:[di] <= ds:[si], si = si


    mov     dx, offset buf1
    call    printf
    mov     ax, 4c00h
    int     21h


printf:         ; in: dx = offset text1
    mov     ax, seg dane1    
    mov     ds, ax           
    mov     ah, 9      
    int     21h             
    ret                 


code1   ends

stos1   segment stack
            dw      200 dup(?)
    ws1     dw      ? 
stos1   ends

end     start1 