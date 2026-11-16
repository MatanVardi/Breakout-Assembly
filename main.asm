.model small
.stack 100h

.data

	paddleX dw 150
	paddleY dw 180
	ballX dw 150
	ballY dw 100
	velocityX dw 20
	velocityY dw 20
	paddleWidth dw 40
	paddleHeight dw 07h
	ballWidth dw 5
	xBoundaryRight dw 260
	xBoundaryLeft dw 10


.code 

SetGraphic proc 
	push ax
	mov ax, 13h
	int 10h
	pop ax
	ret
SetGraphic endp

ExitGame proc
	push ax
	mov ax, 3
	int 10h
	mov ax, 4C00h
	int 21h
	pop ax
	ret
ExitGame endp

CheckExit proc
    push ax
    mov ah, 01h      
    int 16h
    jz exitDone          

    cmp al, 1Bh          
    jne exitDone         

    mov ah, 00h          
    int 16h
    call ExitGame    

exitDone:
    pop ax
    ret
CheckExit endp


CheckPaddleMovement proc
	push ax
	push bx
	push dx
	
	mov ah, 01h
	int 16h
	jz ending
	
	mov ah, 00h
	int 16h
	
	cmp al, 'a'
	je move_left
	
	cmp al, 'd'
	je move_right
	
	move_left: 
		call clearScreenGraphics
		mov bx, [velocityX]
		mov dx, [xBoundaryLeft]
		cmp [paddleX], dx
		jg can_move_left
		jmp ending

		can_move_left:
			sub [paddleX], bx
			jmp ending
	
	move_right:
		call clearScreenGraphics
		mov bx, [velocityX]
		mov dx, [xBoundaryRight]
		cmp [paddleX], dx
		jl can_move_right
		jmp ending
		
		can_move_right:
			add [paddleX], bx
			jmp ending
	
	ending:
		pop dx
		pop bx 
		pop ax
		ret
CheckPaddleMovement endp


clearScreenGraphics proc
	push ax
    mov ax, 0A000h     
    mov es, ax
    xor di, di         
    mov al, 0          
    mov cx, 64000      
    cld                
    rep stosb          
	pop ax
    ret
clearScreenGraphics endp


x equ [bp+4]
y equ [bp+6]
DrawPaddle proc
	push bp
	mov bp, sp

	push dx
	push cx
	push bx 
	push ax
	
	
	mov cx, x ; X 
	mov dx, y ; Y
	
	draw_paddle:
		mov ah, 0Ch
		mov al, 0Fh
		mov bh, 00h
		int 10h
		
		inc cx
		mov ax, cx
		sub ax, x
		cmp ax, paddleWidth
		jng draw_paddle
		
		mov cx, x
		inc dx
		mov ax, dx
		sub ax, y
		cmp ax, paddleHeight
		jng draw_paddle
	pop ax
	pop bx
	pop cx
	pop dx
	pop bp
	ret 4
DrawPaddle endp

x equ [bp+4]
y equ [bp+6]
DrawBall proc
	push bp
	mov bp, sp
	
		push dx
	push cx
	push bx 
	push ax
	
	mov cx, x ; X 
	mov dx, y ; Y
	
	draw_ball:
		mov ah, 0Ch
		mov al, 0Fh
		mov bh, 00h
		int 10h
		
		inc cx
		mov ax, cx
		sub ax, x
		cmp ax, ballWidth
		jng draw_ball
		
		mov cx, x
		inc dx
		mov ax, dx
		sub ax, y
		cmp ax, ballWidth
		jng draw_ball
	pop ax
	pop bx
	pop cx
	pop dx
	pop bp
	ret 4
DrawBall endp

moveBallRightUp proc
	push ax
	push dx
	mov ax, [ballVelocityX]
	add [ballX], ax
	mov dx, [ballVelocityY]
	sub [ballY], dx
	pop dx
	pop ax
	ret
moveBallRightUp endp

moveBallRightDown proc
	push ax
	push dx
	mov ax, [ballVelocityX]
	add [ballX], ax
	mov dx, [ballVelocityY]
	add [ballY], dx
	pop dx
	pop ax
	ret
moveBallRightDown endp

moveBallLeftUp proc
	push ax
	push dx
	mov ax, [ballVelocityX]
	sub [ballX], ax
	mov dx, [ballVelocityY]
	sub [ballY], dx
	pop dx
	pop ax
	ret
moveBallLeftUp endp

moveBallLeftDown proc
	push ax
	push dx
	mov ax, [ballVelocityX]
	sub [ballX], ax
	mov dx, [ballVelocityY]
	add [ballY], dx
	pop dx
	pop ax
	ret
moveBallLeftDown endp

randomizeDirections proc
    push ax
    push cx
    
    mov ah, 00h
    int 1Ah         
    
    mov al, dl      
    shr al, 2      
    and al, 01h
    inc al         
    mov [ballDirX], al
    
    mov al, dl
    shr al, 4       
    and al, 01h
    inc al         
    mov [ballDirY], al
    
    pop cx
    pop ax
    ret
randomizeDirections endp




main proc
	mov ax, @data
	mov ds, ax
	
	call SetGraphic
	
	
game_loop:

	push [paddleY]
	push [paddleX]
	call DrawPaddle
	push [ballY]
	push [ballX]
	call DrawBall
	call CheckExit
	call CheckPaddleMovement
	
	jmp game_loop
main endp

end main