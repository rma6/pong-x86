org 0x7e00
jmp 0x0000:start

leftpadPos db 87
rightpadPos db 87
ballPosX dw 157
ballPosY db 97
ballDiri dw 0
ballDir dw 0
gameflags db 0 ;vertDir,horDir,Status,Keys[3:0]
time db 0

start:
	xor ax, ax
	xor cx, cx
	mov ds, ax
	mov es, ax
	mov fs, ax
	mov sp, 0x8e00

	;seta a frequencia do PIT
	mov al, 0x36
	out 0x43, al
	mov ax, 8948 ;multiplicador do timer
	out 0x40, al
	mov al, ah
	out 0x40, al

	;set inicial directions	
	mov AH, 3
	mov AL, 1
	mov DI, ballDiri
	stosw

	mov DI, ballDir
	stosw

	;inicia video
	mov AH, 0
	mov AL, 13
	int 0x10

	;inicia graficos
	mov cx, 10 ;Xi
	mov dx, 87;Yi
	.l0: ;pad esquerdo
		.l1:
			mov ah, 0xC
			mov bh, 0
			mov al, 0xF
			int 10h

			inc cx
			cmp cx, 15
			jl .l0

		mov cx, 10
		inc dx
		cmp dx, 112
		jle .l1

	mov cx, 305 ;Xi
	mov dx, 87;Yi
	.l2: ;pad direito
		.l3:
			mov ah, 0xC
			mov bh, 0
			mov al, 0xF
			int 10h

			inc cx
			cmp cx, 310
			jl .l2

		mov cx, 305
		inc dx
		cmp dx, 112
		jle .l3

	mov cx, 0 ;Xi
	mov dx, 0;Yi
	.l4: ;borda superior
		.l5:
			mov ah, 0xC
			mov bh, 0
			mov al, 0xF
			int 10h

			inc cx
			cmp cx, 320
			jl .l4

		mov cx, 0
		inc dx
		cmp dx, 5
		jle .l5

	mov cx, 0 ;Xi
	mov dx, 195;Yi
	.l6: ;borda inferior
		.l7:
			mov ah, 0xC
			mov bh, 0
			mov al, 0xF
			int 10h

			inc cx
			cmp cx, 320
			jl .l6

		mov cx, 0
		inc dx
		cmp dx, 200
		jle .l7

	mov cx, 157 ;Xi
	mov dx, 97;Yi
	.l8: ;bola
		.l9:
			mov ah, 0xC
			mov bh, 0
			mov al, 0xF
			int 10h

			inc cx
			cmp cx, 162
			jl .l8

		mov cx, 157
		inc dx
		cmp dx, 101
		jle .l9

	;interruptions
	mov [fs:0x08*4], word timer
	mov [fs:0x08*4+2], ds
	mov [fs:0x09*4], word keyboard
	mov [fs:0x09*4+2], ds

main:
	hlt
	jmp main

keyboard:
	in AL, 0x60
	mov ah, 0xE

	.up:
	cmp al, 0x48 ;up
	jne .down
		mov DI, gameflags
		mov SI, gameflags
		push AX
		lodsb
		mov AH, 0000001b
		or AL, AH
		stosb
		pop AX

	.down:
	cmp al, 0x50 ;down
	jne .w
		mov DI, gameflags
		mov SI, gameflags
		push AX
		lodsb
		mov AH, 0000010b
		or AL, AH
		stosb
		pop AX

	.w:
	cmp al, 0x11 ;w
	jne .s
		mov DI, gameflags
		mov SI, gameflags
		push AX
		lodsb
		mov AH, 0000100b
		or AL, AH
		stosb
		pop AX

	.s:
	cmp al, 0x1F ;s
	jne .upEND
		mov DI, gameflags
		mov SI, gameflags
		push AX
		lodsb
		mov AH, 0001000b
		or AL, AH
		stosb
		pop AX

	.upEND:
	cmp al, 0xC8 ;up
	jne .downEND
		mov DI, gameflags
		mov SI, gameflags
		push AX
		lodsb
		mov AH, 1111110b
		and AL, AH
		stosb
		pop AX

	.downEND:
	cmp al, 0xD0 ;down
	jne .wEND
		mov DI, gameflags
		mov SI, gameflags
		push AX
		lodsb
		mov AH, 1111101b
		and AL, AH
		stosb
		pop AX

	.wEND:
	cmp al, 0x91 ;w
	jne .sEND
		mov DI, gameflags
		mov SI, gameflags
		push AX
		lodsb
		mov AH, 1111011b
		and AL, AH
		stosb
		pop AX

	.sEND:
	cmp al, 0x9F ;s
	jne .space
		mov DI, gameflags
		mov SI, gameflags
		push AX
		lodsb
		mov AH, 1110111b
		and AL, AH
		stosb
		pop AX

	.space:
	cmp al, 0x39 ;space
	jne .end
		call reset

	.end:
	mov al, 0x61
	out 0x20, al
	iret

timer:
	int 0x70

	mov SI, time
	mov DI, time
	lodsb
	inc AL
	stosb

	mov SI, gameflags
	lodsb

	;check game status
	mov AH, 0010000b
	and AH, AL
	cmp AH, 0
	jne .end

	;get directions
	mov AH, 0100000b
	and AH, AL
	cmp AH, 0
	jne .horNeg

	mov BL, 0
	jmp .getver
	.horNeg:
		mov BL, 1

	.getver:
	mov AH, 1000000b
	and AH, AL
	cmp AH, 0
	jne .verNeg

	mov BH, 0
	jmp .ball
	.verNeg:
		mov BH, 1

	.ball:
		push AX
		mov SI, ballDir
		lodsw

		cmp AH, AL
		je .diag

		.card:
			.Up:
				cmp BL, 0
				jne .Down
				cmp AH, AL
				jg .Down

				call updateBallUp
				dec AL

				jmp .endb

			.Down:
				cmp BL, 1
				jne .Right
				cmp AH, AL
				jg .Right

				call updateBallDown
				dec AL

				jmp .endb

			.Right:
				cmp BH, 1
				jne .Left
				cmp AH, AL
				jl .Left

				call updateBallRight
				dec AH

				jmp .endb

			.Left:
				cmp BH, 0
				jne .endb
				cmp AH, AL
				jl .endb

				call updateBallLeft
				dec AH

				jmp .endb

		.diag:
			.UR:
				cmp BL, 0
				jne .UL
				cmp BH, 1
				jne .UL

				
				call updateBallUp
				call updateBallRight
				dec AL
				dec AH

				jmp .endb

			.UL:
				cmp BL, 0
				jne .DR
				cmp BH, 0
				jne .DR

				call updateBallUp
				call updateBallLeft
				dec AL
				dec AH

				jmp .endb

			.DR:
				cmp BL, 1
				jne .DwL
				cmp BH, 1
				jne .DwL

				call updateBallDown
				call updateBallRight
				dec AL
				dec AH

				jmp .endb

			.DwL:
				cmp BL, 1
				jne .endb
				cmp BH, 0
				jne .endb

				call updateBallDown
				call updateBallLeft
				dec AL
				dec AH

				jmp .endb


		.endb:
			.if0:cmp AH, 0
				je .if1
				jmp .endrd
			.if1:cmp AL, 0
				je .resetDir
				jmp .endrd

			.resetDir:
				mov SI, ballDiri
				lodsw
			.endrd:

			mov DI, ballDir
			stosw
			pop AX

	.up:
		mov AH, 0000001b
		and AH, AL
		cmp AH, 0
		je .down
		call updateRightPadUp

	.down:
		mov AH, 0000010b
		and AH, AL
		cmp AH, 0
		je .w
		call updateRightPadDown

	.w:
		mov AH, 0000100b
		and AH, AL
		cmp AH, 0
		je .s
		call updateLeftPadUp

	.s:
		mov AH, 0001000b
		and AH, AL
		cmp AH, 0
		je .end
		call updateLeftPadDown

	.end:
		iret

updateRightPadUp:
	push AX
	mov DI, rightpadPos
	mov SI, rightpadPos
	lodsb

	cmp AL, 6 ;limita movimento
	je .end

	mov AH, 0
	mov DX, AX
	dec DX ;Y

	mov cx, 305 ;Xi
	.l0: ;atualiza em cima
		mov ah, 0xC
		mov bh, 0
		mov al, 0xF
		int 10h

		inc cx
		cmp cx, 310
		jl .l0

	add DX, 26
	mov cx, 305 ;Xi
	.l1: ;atualiza em baixo
		mov ah, 0xC
		mov bh, 0
		mov al, 0x0
		int 10h

		inc cx
		cmp cx, 310
		jl .l1

	sub DX, 26
	mov AX, DX
	stosb

	.end:
		pop AX
		ret

updateRightPadDown:
	push AX
	mov DI, rightpadPos
	mov SI, rightpadPos
	lodsb

	cmp AL, 169 ;limita movimento
	je .end

	mov AH, 0
	mov DX, AX ;Y

	mov cx, 305 ;Xi
	.l0: ;atualiza em cima
		mov ah, 0xC
		mov bh, 0
		mov al, 0x0
		int 10h

		inc cx
		cmp cx, 310
		jl .l0

	
	add DX, 26
	mov cx, 305 ;Xi
	.l1: ;atualiza em baixo
		mov ah, 0xC
		mov bh, 0
		mov al, 0xF
		int 10h

		inc cx
		cmp cx, 310
		jl .l1

	inc DX
	sub DX, 26
	mov AX, DX
	stosb

	.end:
		pop AX
		ret

updateLeftPadUp:
	push AX
	mov DI, leftpadPos
	mov SI, leftpadPos
	lodsb

	cmp AL, 6 ;limita movimento
	je .end

	mov AH, 0
	mov DX, AX
	dec DX ;Y

	mov cx, 10 ;Xi
	.l0: ;atualiza em cima
		mov ah, 0xC
		mov bh, 0
		mov al, 0xF
		int 10h

		inc cx
		cmp cx, 15
		jl .l0

	add DX, 26
	mov cx, 10 ;Xi
	.l1: ;atualiza em baixo
		mov ah, 0xC
		mov bh, 0
		mov al, 0x0
		int 10h

		inc cx
		cmp cx, 15
		jl .l1

	sub DX, 26
	mov AX, DX
	stosb

	.end:
		pop AX
		ret

updateLeftPadDown:
	push AX
	mov DI, leftpadPos
	mov SI, leftpadPos
	lodsb

	cmp AL, 169 ;limita movimento
	je .end

	mov AH, 0
	mov DX, AX ;Y

	mov cx, 10 ;Xi
	.l0: ;atualiza em cima
		mov ah, 0xC
		mov bh, 0
		mov al, 0x0
		int 10h

		inc cx
		cmp cx, 15
		jl .l0

	
	add DX, 26
	mov cx, 10 ;Xi
	.l1: ;atualiza em baixo
		mov ah, 0xC
		mov bh, 0
		mov al, 0xF
		int 10h

		inc cx
		cmp cx, 15
		jl .l1

	inc DX
	sub DX, 26
	mov AX, DX
	stosb

	.end:
		pop AX
		ret

updateBallRight:
	push AX
	mov SI, ballPosY
	lodsb
	mov AH, 0
	mov DX, AX ;Y

	mov SI, ballPosX
	lodsw
	mov CX, AX ;X

	cmp AX, 300
	je .goCheck
	jmp .l0

	.goCheck:
		mov SI, rightpadPos
		lodsb
		mov AH, 0

		sub AX, 5
		cmp DX, AX
		jle .gameover

		add AX, 32
		cmp DX, AX
		jge .gameover

		.reflect:
			mov SI, gameflags
			mov DI, gameflags
			lodsb
			mov AH, 0111111b
			and AL, AH
			stosb
			call random


		jmp .end

	.l0: ;atualiza a esquerda
		mov ah, 0xC
		mov bh, 0
		mov al, 0x0
		int 10h

		inc DX

		mov ah, 0xC
		mov bh, 0
		mov al, 0x0
		int 10h

		inc DX

		mov ah, 0xC
		mov bh, 0
		mov al, 0x0
		int 10h

		inc DX

		mov ah, 0xC
		mov bh, 0
		mov al, 0x0
		int 10h

		inc DX

		mov ah, 0xC
		mov bh, 0
		mov al, 0x0
		int 10h

	add CX, 5
	sub DX, 4
	.l1: ;atualiza a direita
		mov ah, 0xC
		mov bh, 0
		mov al, 0xF
		int 10h

		inc DX

		mov ah, 0xC
		mov bh, 0
		mov al, 0xF
		int 10h

		inc DX

		mov ah, 0xC
		mov bh, 0
		mov al, 0xF
		int 10h

		inc DX

		mov ah, 0xC
		mov bh, 0
		mov al, 0xF
		int 10h

		inc DX

		mov ah, 0xC
		mov bh, 0
		mov al, 0xF
		int 10h

	sub CX, 4
	sub DX, 4

	mov AX, DX
	mov DI, ballPosY
	stosb

	mov AX, CX
	mov DI, ballPosX
	stosw

	.end:
		pop AX
		ret

	.gameover:
		mov DI, gameflags
		mov SI, gameflags
		lodsb
		mov AH, 0010000b
		or AL, AH
		stosb
		call drawRightX
		jmp .end

updateBallLeft:
	push AX
	mov SI, ballPosY
	lodsb

	mov AH, 0
	mov DX, AX ;Y

	mov SI, ballPosX
	lodsw
	mov CX, AX
	dec CX ;X

	cmp AX, 15
	je .goCheck
	jmp .l0

	.goCheck:
		mov SI, leftpadPos
		lodsb
		mov AH, 0

		sub AX, 5
		cmp DX, AX
		jle .gameover

		add AX, 32
		cmp DX, AX
		jge .gameover

		.reflect:
			mov SI, gameflags
			mov DI, gameflags
			lodsb
			mov AH, 1000000b
			or AL, AH
			stosb
			call random

		jmp .end

	.l0: ;atualiza a esquerda
		mov ah, 0xC
		mov bh, 0
		mov al, 0xF
		int 10h

		inc DX

		mov ah, 0xC
		mov bh, 0
		mov al, 0xF
		int 10h

		inc DX

		mov ah, 0xC
		mov bh, 0
		mov al, 0xF
		int 10h

		inc DX

		mov ah, 0xC
		mov bh, 0
		mov al, 0xF
		int 10h

		inc DX

		mov ah, 0xC
		mov bh, 0
		mov al, 0xF
		int 10h

	add CX, 5
	sub DX, 4
	.l1: ;atualiza a direita
		mov ah, 0xC
		mov bh, 0
		mov al, 0x0
		int 10h

		inc DX

		mov ah, 0xC
		mov bh, 0
		mov al, 0x0
		int 10h

		inc DX

		mov ah, 0xC
		mov bh, 0
		mov al, 0x0
		int 10h

		inc DX

		mov ah, 0xC
		mov bh, 0
		mov al, 0x0
		int 10h

		inc DX

		mov ah, 0xC
		mov bh, 0
		mov al, 0x0
		int 10h

	sub CX, 5
	sub DX, 4

	mov AX, DX
	mov DI, ballPosY
	stosb

	mov AX, CX
	mov DI, ballPosX
	stosw

	.end:
		pop AX
		ret

	.gameover:
		mov DI, gameflags
		mov SI, gameflags
		lodsb
		mov AH, 0010000b
		or AL, AH
		stosb
		call drawLeftX
		jmp .end

updateBallUp:
	push AX
	mov SI, ballPosY
	lodsb

	cmp AL, 6 ;limita movimento
	je .reflect ;reflete (atualizar vetor de direcao)

	mov AH, 0
	mov DX, AX
	dec DX ;Y

	mov SI, ballPosX
	lodsw

	mov CX, AX ;X

	.l0: ;atualiza em cima
		mov ah, 0xC
		mov bh, 0
		mov al, 0xF
		int 10h

		inc cx

		mov ah, 0xC
		mov bh, 0
		mov al, 0xF
		int 10h

		inc cx

		mov ah, 0xC
		mov bh, 0
		mov al, 0xF
		int 10h

		inc cx

		mov ah, 0xC
		mov bh, 0
		mov al, 0xF
		int 10h

		inc cx

		mov ah, 0xC
		mov bh, 0
		mov al, 0xF
		int 10h

	sub CX, 4
	add DX, 5
	.l1: ;atualiza em baixo
		mov ah, 0xC
		mov bh, 0
		mov al, 0x0
		int 10h

		inc cx

		mov ah, 0xC
		mov bh, 0
		mov al, 0x0
		int 10h

		inc cx

		mov ah, 0xC
		mov bh, 0
		mov al, 0x0
		int 10h

		inc cx

		mov ah, 0xC
		mov bh, 0
		mov al, 0x0
		int 10h

		inc cx

		mov ah, 0xC
		mov bh, 0
		mov al, 0x0
		int 10h

	sub CX, 4
	sub DX, 5

	mov AX, DX
	mov DI, ballPosY
	stosb

	mov AX, CX
	mov DI, ballPosX
	stosw

	.end:
		pop AX
		ret

	.reflect:
		mov SI, gameflags
		mov DI, gameflags
		lodsb
		mov AH, 0100000b
		or AL, AH
		stosb
		jmp .end

updateBallDown:
	push AX
	mov SI, ballPosY
	lodsb

	cmp AL, 190 ;limita movimento
	je .reflect ;reflete (atualizar vetor de direcao)

	mov AH, 0
	mov DX, AX ;Y

	mov SI, ballPosX
	lodsw

	mov CX, AX ;X

	.l0: ;atualiza em cima
		mov ah, 0xC
		mov bh, 0
		mov al, 0x0
		int 10h

		inc cx

		mov ah, 0xC
		mov bh, 0
		mov al, 0x0
		int 10h

		inc cx

		mov ah, 0xC
		mov bh, 0
		mov al, 0x0
		int 10h

		inc cx

		mov ah, 0xC
		mov bh, 0
		mov al, 0x0
		int 10h

		inc cx

		mov ah, 0xC
		mov bh, 0
		mov al, 0x0
		int 10h

	sub CX, 4
	add DX, 5
	.l1: ;atualiza em baixo
		mov ah, 0xC
		mov bh, 0
		mov al, 0xF
		int 10h

		inc cx

		mov ah, 0xC
		mov bh, 0
		mov al, 0xF
		int 10h

		inc cx

		mov ah, 0xC
		mov bh, 0
		mov al, 0xF
		int 10h

		inc cx

		mov ah, 0xC
		mov bh, 0
		mov al, 0xF
		int 10h

		inc cx

		mov ah, 0xC
		mov bh, 0
		mov al, 0xF
		int 10h

	sub CX, 4
	sub DX, 4

	mov AX, DX
	mov DI, ballPosY
	stosb

	mov AX, CX
	mov DI, ballPosX
	stosw

	.end:
		pop AX
		ret

	.reflect:
		mov SI, gameflags
		mov DI, gameflags
		lodsb
		mov AH, 1011111b
		and AL, AH
		stosb
		jmp .end

reset:
	;set inicial directions	
	call random

	mov SI, time
	lodsb
	mov BX, AX 
	mov AL, 00000011b
	and AL, bl
	ror AL, 3

	mov DI, gameflags
	stosb

	;inicia video
	mov AH, 0
	mov AL, 13
	int 0x10

	;inicia graficos
	mov cx, 10 ;Xi
	mov dx, 87;Yi
	.l0: ;pad esquerdo
		.l1:
			mov ah, 0xC
			mov bh, 0
			mov al, 0xF
			int 10h

			inc cx
			cmp cx, 15
			jl .l0

		mov cx, 10
		inc dx
		cmp dx, 112
		jle .l1

	mov cx, 305 ;Xi
	mov dx, 87;Yi
	.l2: ;pad direito
		.l3:
			mov ah, 0xC
			mov bh, 0
			mov al, 0xF
			int 10h

			inc cx
			cmp cx, 310
			jl .l2

		mov cx, 305
		inc dx
		cmp dx, 112
		jle .l3

	mov cx, 0 ;Xi
	mov dx, 0;Yi
	.l4: ;borda superior
		.l5:
			mov ah, 0xC
			mov bh, 0
			mov al, 0xF
			int 10h

			inc cx
			cmp cx, 320
			jl .l4

		mov cx, 0
		inc dx
		cmp dx, 5
		jle .l5

	mov cx, 0 ;Xi
	mov dx, 195;Yi
	.l6: ;borda inferior
		.l7:
			mov ah, 0xC
			mov bh, 0
			mov al, 0xF
			int 10h

			inc cx
			cmp cx, 320
			jl .l6

		mov cx, 0
		inc dx
		cmp dx, 200
		jle .l7

	mov cx, 157 ;Xi
	mov dx, 97;Yi
	.l8: ;bola
		.l9:
			mov ah, 0xC
			mov bh, 0
			mov al, 0xF
			int 10h

			inc cx
			cmp cx, 162
			jl .l8

		mov cx, 157
		inc dx
		cmp dx, 101
		jle .l9

	;reset variables
	mov DI, leftpadPos
	mov AL, 87
	stosb
	mov Di, rightpadPos
	mov AL, 87
	stosb
	mov DI, ballPosX
	mov AX, 157
	stosw
	mov DI, ballPosY
	mov AL, 97
	stosb

	ret

drawLeftX:

	mov cx, 54 ;cordenada em [45,35]
	mov dx, 75
	mov bx, 55

	.l1_Draw: ;pixel na coordenada [cx, dx]

		.l8:
			.l9:
				mov ah, 0xC
				mov bh, 0
				mov al, 0x4
				int 10h

				inc cx
				cmp cx, bx
				jl .l9

			inc bx
			inc dx
			cmp dx, 125
			jl .l8



			mov dx,75
		
	.l2_Draw: ;pixel na coordenada [cx, dx]

		.l10:
			.l11:
				mov ah, 0xC
				mov bh, 0
				mov al, 0x4
				int 10h

				sub cx,1
				cmp cx, bx
				jg .l11

			inc bx
			inc dx
			cmp dx, 125
			jl .l10

			.end:
				ret
drawRightX:
	
	mov cx, 214 ;cordenada em [45,35]
	mov dx, 75
	mov bx, 215

	.l3_Draw: ;pixel na coordenada [cx, dx]

		.l12:
			.l13:
				mov ah, 0xC
				mov bh, 0
				mov al, 0x4
				int 10h

				inc cx
				cmp cx, bx
				jl .l13

			inc bx
			inc dx
			cmp dx, 125
			jl .l12
		
			mov dx,75
		
	.l4_Draw: ;pixel na coordenada [cx, dx]

		.l14:
			.l15:
				mov ah, 0xC
				mov bh, 0
				mov al, 0x4
				int 10h

				sub cx,1
				cmp cx, bx
				jl .l15

			inc bx
			inc dx
			cmp dx, 125
			jl .l14

			.end:
				ret

random:
	mov SI, time
	lodsb
	mov BX, AX 

	mov AL, 00000111b
	and AL, bl

	mov AH, 00000111b
	and AH, bL

    cmp AH, 0
    jne .end
    inc AH

	.end:
		mov DI, ballDiri
		stosw

		mov DI, ballDir
		stosw

		ret

done:
	jmp $