org 0x7c00
jmp 0x0000:main



start:
    xor ax,ax
    mov es,ax
    mov ds,ax
    
    ;print
    mov ah,0xe
    mov al, 'A'
    int 10h
    ;fim do print, só é printado um caractere por chamada de comando


times 510-($-$$) db 0
dw 0xaa55