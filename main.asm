.model small
.stack 100h

.data

	paddle_x dw 140
	paddle_y dw 150
	paddleWidth dw 40
	paddleHeight dw 07h



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
	
	draw_paddle_left_horizontal:
		mov ah, 0Ch
		mov al, 0Fh
		mov bh, 00h
		int 10h
		
		inc cx
		mov ax, cx
		sub ax, x
		cmp ax, paddleWidth
		jng draw_paddle_left_horizontal
		
		mov cx, x
		inc dx
		mov ax, dx
		sub ax, y
		cmp ax, paddleHeight
		jng draw_paddle_left_horizontal
	pop ax
	pop bx
	pop cx
	pop dx
	pop bp
	ret 4
DrawPaddle endp



main proc
	mov ax, @data
	mov ds, ax
	
	call SetGraphic
	
	
game_loop:
	push [paddle_y]
	push [paddle_x]
	call DrawPaddle
	
	call CheckExit
	jmp game_loop
main endp

end main