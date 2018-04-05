org 0x500
jmp 0x0000:start




linha1 db "-> Carregando o kernel", 13, 10, 0
linha2 db "-> Configurando o modo protegido", 13, 10, 0
linha3 db "-> Carregando o kernel na memoria", 13, 10, 0
linha4 db "-> Preparando a quadra", 13, 10, 0
linha5 db "-> Procurando as raquetes", 13, 10, 0
linha7 db "-> Contratando gandulas", 13, 10, 0
linha6 db "     Pressione Enter para iniciar",13,10,0




start:
    xor ax, ax
    mov ds, ax
    mov es, ax

    mov ax, 0x7e0 ;0x7e0<<1 = 0x7e00 (início de kernel.asm)
    mov es, ax
    xor bx, bx    ;posição es<<1+bx

    jmp reset

reset:
    mov ah, 00h ;reseta o controlador de disco
    mov dl, 0   ;floppy disk
    int 13h

    jc reset    ;se o acesso falhar, tenta novamente

    jmp load

load:
    mov ah, 02h ;lê um setor do disco
    mov al, 20  ;quantidade de setores ocupados pelo kernel
    mov ch, 0   ;track 0
    mov cl, 3   ;sector 3
    mov dh, 0   ;head 0
    mov dl, 0   ;drive 0
    int 13h

    jc load     ;se o acesso falhar, tenta novamente

    


    mov AH, 0
	mov AL, 13h
	int 10h

    mov ah, 0bh
    mov bh, 00h
    mov bl, 0
    int 10h

    mov bl, 15
    
  
	
	mov si, linha1
    call print_no_delay
    call Apaga
    call Loading
    

    mov si, linha2
    call print_no_delay
    
    call Apaga
    call Loading

    

    mov si, linha3
    call print_no_delay
    call Apaga
    call Loading

    

    mov si,linha4
    call print_no_delay
    call Apaga
    call Loading

    

    mov si,linha5
    call print_no_delay
    call Apaga
    call Loading

     mov si,linha7
    call print_no_delay
    call Apaga
    call Loading

    
    call new_line
    call new_line
    mov si,linha6
    call print

    .continuar:
		mov ah, 00h 				;le o input do usuario
		int 16h
		cmp al, 13
		jne .continuar
	
	jmp 0x7e00    ;pula para o setor de endereco 0x7e00 (start do boot2)


Loading:
    

mov cx, 120 
mov dx, 60

.C1_Draw: ;printa a barrinha vermelha, usando o delay para dar a sensaçao de movimento



    .l3:
        .l4:
            mov ah, 0xC
            mov bh, 0
            mov al, 0x4
            int 10h

            inc dx
            cmp dx, 65
            jl .l4
            mov bx,cx

            call delay
            mov cx,bx

        mov dx, 60
        add cx,1
        cmp cx, 200
        jl .l3


            .end:
                ret
Apaga: ;desenha a barrinha branca
    

mov cx, 120 
mov dx, 60

.C1_Draw: 



    .l3:
        .l4:
            mov ah, 0xC
            mov bh, 0
            mov al, 0xF
            int 10h

            inc dx
            cmp dx, 65
            jl .l4
            

        mov dx, 60
        inc cx
        cmp cx, 200
        jl .l3


            .end:
                ret

print: ;printa com um efeito de delay, letra por letra
    
    lodsb       
    cmp al, 0                   
    je .prnt
    mov ah, 0eh
    mov bl,0xF  ;branco              
    int 10h
    call delay
    call delay
    jmp print

    .prnt:        
        ret

print_no_delay:;printa 
    
    lodsb       
    cmp al, 0                   
    je .prnt
    mov ah, 0eh                 
    mov bl,0xF ;branco
    int 10h

    jmp print_no_delay

    .prnt:        
        ret

new_line: ;pula linhas
    mov al, 13
    mov ah, 0eh                 
    int 10h                     
    mov al, 10
    mov ah, 0eh                 
    int 10h 
    mov al, 13
    mov ah, 0eh                 
    int 10h                     
    mov al, 10
    mov ah, 0eh                 
    int 10h                    
    call delay

    ret

delay:
    mov     cx, 0
    mov     dx, 7FFFh
    mov     ah, 86H
    int     15H
    ret