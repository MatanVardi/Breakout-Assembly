.model small
.stack 100h

.data

	paddle_x dw 140
	paddle_y dw 80
	paddleWidth dw 35
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

x equ [bp+4]
y equ [bp+6]
drawPaddle proc
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
drawPaddle endp



main proc
	mov ax, @data
	mov ds, ax
	
	call SetGraphic
	push [paddle_y]
	push [paddle_x]
	call drawPaddle

main endp

end main