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
	xBallBoundaryRight dw 300
	ballVelocityX dw 3
	ballVelocityY dw 4
	
	;Will result in either 1 or 2 for the direction
	;(can be right direction for the x and the y would either be 1 which is down and we use add or 2 for sub
	; 1 - is left or down and 2 is right or up
	ballDirX db 1
	ballDirY db 1
	
	x_blocks_pos dw 5, 50, 95, 140, 185, 230, 275
	X_COUNT equ ($ - x_blocks_pos) / 2

	y_blocks_pos dw 20, 40, 60, 80
	Y_COUNT equ ($ - y_blocks_pos) / 2

	blockWidth  equ 40
	blockHeight equ 15
	blocks_alive db X_COUNT * Y_COUNT dup(1)   ; 1 = block exists, 0 = destroyed
	blocks_left dw X_COUNT * Y_COUNT
	colors dw 28h, 2Ah, 2Ch, 2Fh
	
	topBoundary dw 5
	downBoundary dw 160
	downBoundaryCollision dw 190
	topBoundaryCollision dw 5
	
	
	player_lives dw 3
	lives_text db 'Remaining Lives: ', 0
	win_text db 'You won the game', 0
	paddle_bg_buffer db 41*8 dup(0)  
	ball_bg_buffer   db 6*6 dup(0)   
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
	jmp ending 
	
	move_left: 
		mov bx, [velocityX]
		mov dx, [xBoundaryLeft]
		cmp [paddleX], dx
		jg can_move_left
		jmp ending

		can_move_left:
			sub [paddleX], bx
			jmp ending
	
	move_right:
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


ClearScreenGraphics proc
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
ClearScreenGraphics endp


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
color equ [bp+8]
DrawBlock proc

push bp
	mov bp, sp
	push dx
	push cx
	push bx 
	push ax
	
	
	mov cx, x ; X 
	mov dx, y ; Y
	
	draw_block:
		mov ah, 0Ch
		mov al, color
		mov bh, 00h
		int 10h
		
		inc cx
		mov ax, cx
		sub ax, x
		cmp ax, blockWidth
		jng draw_block
		
		mov cx, x
		inc dx
		mov ax, dx
		sub ax, y
		cmp ax, blockHeight
		jng draw_block
	pop ax
	pop bx
	pop cx
	pop dx
	pop bp
	ret 6

DrawBlock endp


DrawBlocks proc
	push si
	push di

	xor di, di                      ; DI = index into y_blocks_pos

rows_loop:                          ; ---- outer loop: each Y ----
	xor si, si                      ; SI = index into x_blocks_pos (restart every row)

cols_loop:                          ; ---- inner loop: each X ----
	push [colors + di]
	push [y_blocks_pos + di]        ; pushed first  -> [bp+6] = y
	push [x_blocks_pos + si]        ; pushed second -> [bp+4] = x
	call DrawBlock                  ; DrawBlock does "ret 4", which removes both

	add si, 2                       ; next X (dw = 2 bytes)
	cmp si, X_COUNT * 2
	jb  cols_loop

	add di, 2                       ; next Y
	cmp di, Y_COUNT * 2
	jb  rows_loop

	pop di
	pop si
	ret
DrawBlocks endp



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

MoveBallRightUp proc
	push ax
	push dx
	mov ax, [ballVelocityX]
	add [ballX], ax
	mov dx, [ballVelocityY]
	sub [ballY], dx
	pop dx
	pop ax
	ret
MoveBallRightUp endp

MoveBallRightDown proc
	push ax
	push dx

	mov ax, [ballVelocityX]
	add [ballX], ax
	mov dx, [ballVelocityY]
	add [ballY], dx
	pop dx
	pop ax
	ret
MoveBallRightDown endp

MoveBallLeftUp proc
	push ax
	push dx
	mov ax, [ballVelocityX]
	sub [ballX], ax
	mov dx, [ballVelocityY]
	sub [ballY], dx
	pop dx
	pop ax
	ret
MoveBallLeftUp endp

MoveBallLeftDown proc
	push ax
	push dx
	mov ax, [ballVelocityX]
	sub [ballX], ax
	mov dx, [ballVelocityY]
	add [ballY], dx
	pop dx
	pop ax
	ret
MoveBallLeftDown endp

RandomizeDirections proc
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
RandomizeDirections endp

MoveBall proc
	cmp [ballDirX], 1
	je left_x_val
	jmp right_x_val
	
	left_x_val:
		cmp [ballDirY], 1
		je down_y_val
		jmp up_y_val
	
	down_y_val:
		call moveBallLeftDown
		jmp endingProc

	up_y_val:
		call moveBallLeftUp
		jmp endingProc

	right_x_val:
		cmp [ballDirY], 1
		je down_y_val_second
		jmp up_y_val_second
	
	down_y_val_second:
		call moveBallRightDown
		jmp endingProc
		
	up_y_val_second:
		call moveBallRightUp
		jmp endingProc

	endingProc:
		ret
MoveBall endp

BallCollisionHorizontalBoundaries proc
	push ax
	push bx

	mov ax, [ballY]
	cmp ax, [topBoundary]
	jle change_y_to_down
	cmp ax, [downBoundaryCollision]
	jge subtract_lives
	jmp end_ball_collision_proc

	change_y_to_down:
		mov [ballDirY], 1
		add [ballY], 1
		jmp end_ball_collision_proc

	subtract_lives:
		dec [player_lives]
		call DisplayLives
		cmp [player_lives], 0
		je end_game

		mov [ballX], 150
		mov [ballY], 100
		mov [ballDirY], 2
		jmp end_ball_collision_proc

	end_game:
		call ExitGame

	end_ball_collision_proc:
		pop bx
		pop ax
		ret
BallCollisionHorizontalBoundaries endp

BallCollisionVerticalBoundaries proc
	push ax 
	
	mov ax, [ballX]
	cmp ax, [xBallBoundaryRight]
	jge change_x_to_left
	cmp ax, [xBoundaryLeft]
	jle change_x_to_right
	jmp endBallCollisionProc
	
	change_x_to_left:
	mov [ballDirX], 1
	sub [ballX], 1
	jmp endBallCollisionProc

	change_x_to_right:
	mov [ballDirX], 2
	add [ballX], 1
	jmp endBallCollisionProc
	
	endBallCollisionProc:
	pop ax
	ret
BallCollisionVerticalBoundaries endp

CheckBlockCollision proc
	push ax
	push bx
	push si
	push di

	xor bx, bx                      
	xor di, di                      
coll_rows:
	xor si, si                      
coll_cols:
	cmp [blocks_alive + bx], 0      
	je  coll_next

	mov ax, [ballX]
	add ax, ballWidth
	cmp ax, [x_blocks_pos + si]
	jle coll_next

	mov ax, [x_blocks_pos + si]
	add ax, blockWidth
	cmp [ballX], ax
	jge coll_next

	mov ax, [ballY]
	add ax, ballWidth
	cmp ax, [y_blocks_pos + di]
	jle coll_next

	mov ax, [y_blocks_pos + di]
	add ax, blockHeight
	cmp [ballY], ax
	jge coll_next

	mov [blocks_alive + bx], 0      
	xor [ballDirY], 3                

	mov ax, 0
	push ax                         
	push [y_blocks_pos + di]       
	push [x_blocks_pos + si]        
	call DrawBlock

	dec [blocks_left]
	jnz coll_done
	call DisplayWin         


	jmp coll_done                   

coll_next:
	inc bx                         
	add si, 2                       
	cmp si, X_COUNT * 2
	jb  coll_cols

	add di, 2                       
	cmp di, Y_COUNT * 2
	jb  coll_rows

coll_done:
	pop di
	pop si
	pop bx
	pop ax
	ret
CheckBlockCollision endp

BallCollisionPaddle proc
    push ax
    push dx
    push cx

    cmp [ballDirY], 1
    jne endCollisionProc

    mov ax, [ballX]
    add ax, [ballWidth]
    cmp ax, [paddleX]
    jl endCollisionProc

    mov ax, [ballX]
    mov dx, [paddleX]
    add dx, [paddleWidth]
    cmp ax, dx
    jg endCollisionProc

    mov cx, [ballY]
    add cx, [ballWidth]
    cmp cx, [paddleY]
    jl endCollisionProc

    mov cx, [ballY]
    mov dx, [paddleY]
    add dx, [paddleHeight]
    cmp cx, dx
    jg endCollisionProc

    mov [ballDirY], 2
    mov ax, [paddleY]
    sub ax, [ballWidth]
    dec ax
    mov [ballY], ax

endCollisionProc:
    pop cx
    pop dx
    pop ax
    ret
BallCollisionPaddle endp

delay proc
    push ax
    push cx
    push dx
    mov ah, 86h
    mov cx, 0000h    
    mov dx, 8F45h    
    int 15h
    pop dx
    pop cx
    pop ax
    ret
delay endp


DisplayLives proc near
    push ax
    push bx
    push cx
    push dx
    push si
    
    ; Position cursor (Row 0, Col 0 = top-left corner)
    mov ah, 02h      ; Set cursor position
    mov bh, 0        ; Page number
    mov dh, 0        ; Row 0 (change to 24 if you still want bottom-left)
    mov dl, 0        ; Column 0
    int 10h
    
    ; Display the label using BIOS (supports custom color)
    ; Note: Make sure lives_text ends with 0 instead of '$'
    mov si, offset lives_text
    mov bl, 0Ch      ; Color: 0Ch = Light Red (0Eh = Yellow, 0Fh = White)
print_label:
    mov al, [si]
    cmp al, 0        ; Check for null terminator
    je print_num
    mov ah, 0Eh      ; BIOS Teletype output
    int 10h
    inc si
    jmp print_label

print_num:
    ; Convert lives to ASCII and display
    mov ax, [player_lives]
    call DisplayNumber
    
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret
DisplayLives endp

DisplayWin proc
    push ax
    push bx
    push cx
    push dx
    push si
    
    ; Position cursor (Row 0, Col 0 = top-left corner)
    mov ah, 02h      ; Set cursor position
    mov bh, 0        ; Page number
    mov dh, 12        ; Row 0 (change to 24 if you still want bottom-left)
    mov dl, 12        ; Column 0
    int 10h
    
    mov si, offset win_text
    mov bl, 0Fh      
print_label_of_win:
    mov al, [si]
    cmp al, 0        ; Check for null terminator
    mov ah, 0Eh      ; BIOS Teletype output
    int 10h
    inc si
    jmp print_label_of_win

    
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret
DisplayWin endp



DisplayNumber proc near
    push ax
    push bx
    push cx
    push dx
    
    mov bx, 10       ; Divisor
    xor cx, cx       ; Digit counter
    
convert_loop:
    xor dx, dx       ; Clear DX for division
    div bx           ; AX / 10, quotient in AX, remainder in DX
    push dx          ; Save remainder
    inc cx           ; Increment digit counter
    test ax, ax      ; Check if quotient is zero
    jnz convert_loop
    
    mov bl, 0Fh      ; Color for the digits (0Fh = Bright White)
    xor bh, bh       ; Page 0
display_loop:
    pop ax           ; Get digit into AL
    add al, '0'      ; Convert to ASCII
    mov ah, 0Eh      ; BIOS Teletype output (advances cursor automatically)
    int 10h
    loop display_loop

    ; Print a trailing space to erase leftover digits (e.g., 10 -> 9 )
    mov ax, 0E20h    ; AH = 0Eh, AL = ' ' (20h)
    int 10h
    
    pop dx
    pop cx
    pop bx
    pop ax
    ret
DisplayNumber endp

SaveArea proc
	push bp
	mov bp, sp
	push ax
	push cx
	push dx
	push si
	push di
	push es

	mov ax, 0A000h
	mov es, ax
	mov ax, 320
	mul word ptr [bp+6]
	add ax, [bp+4]
	mov si, ax
	mov di, [bp+12]

	mov dx, [bp+10]
save_area_row:
	push si
	mov cx, [bp+8]
save_area_col:
	mov al, es:[si]
	mov [di], al
	inc si
	inc di
	loop save_area_col
	pop si
	add si, 320
	dec dx
	jnz save_area_row

	pop es
	pop di
	pop si
	pop dx
	pop cx
	pop ax
	pop bp
	ret 10
SaveArea endp

RestoreArea proc
	push bp
	mov bp, sp
	push ax
	push cx
	push dx
	push si
	push di
	push es

	mov ax, 0A000h
	mov es, ax
	mov ax, 320
	mul word ptr [bp+6]
	add ax, [bp+4]
	mov di, ax
	mov si, [bp+12]

	mov dx, [bp+10]
restore_area_row:
	push di
	mov cx, [bp+8]
restore_area_col:
	mov al, [si]
	mov es:[di], al
	inc si
	inc di
	loop restore_area_col
	pop di
	add di, 320
	dec dx
	jnz restore_area_row

	pop es
	pop di
	pop si
	pop dx
	pop cx
	pop ax
	pop bp
	ret 10
RestoreArea endp

SavePaddleBg proc
	push ax
	mov ax, offset paddle_bg_buffer
	push ax
	mov ax, [paddleHeight]
	inc ax
	push ax
	mov ax, [paddleWidth]
	inc ax
	push ax
	push [paddleY]
	push [paddleX]
	call SaveArea
	pop ax
	ret
SavePaddleBg endp

RestorePaddleBg proc
	push ax
	mov ax, offset paddle_bg_buffer
	push ax
	mov ax, [paddleHeight]
	inc ax
	push ax
	mov ax, [paddleWidth]
	inc ax
	push ax
	push [paddleY]
	push [paddleX]
	call RestoreArea
	pop ax
	ret
RestorePaddleBg endp

SaveBallBg proc
	push ax
	mov ax, offset ball_bg_buffer
	push ax
	mov ax, [ballWidth]
	inc ax
	push ax          ; height
	push ax          ; width
	push [ballY]
	push [ballX]
	call SaveArea
	pop ax
	ret
SaveBallBg endp

RestoreBallBg proc
	push ax
	mov ax, offset ball_bg_buffer
	push ax
	mov ax, [ballWidth]
	inc ax
	push ax
	push ax
	push [ballY]
	push [ballX]
	call RestoreArea
	pop ax
	ret
RestoreBallBg endp

vsync proc
	push ax
	push dx
	mov dx, 3DAh
wait_retrace_end:
	in al, dx
	test al, 08h
	jnz wait_retrace_end
wait_retrace_start:
	in al, dx
	test al, 08h
	jz wait_retrace_start
	pop dx
	pop ax
	ret
vsync endp


main proc
	mov ax, @data
	mov ds, ax
	
	call SetGraphic
	call randomizeDirections
	call DisplayLives
	call DrawBlocks

	call SavePaddleBg
	push [paddleY]
	push [paddleX]
	call DrawPaddle
	call SaveBallBg
	push [ballY]
	push [ballX]
	call DrawBall

game_loop:
	call delay
	call vsync

	call RestoreBallBg       
	call RestorePaddleBg

	call CheckExit
	call CheckPaddleMovement
	call CheckBlockCollision
	call BallCollisionHorizontalBoundaries
	call BallCollisionVerticalBoundaries
	call BallCollisionPaddle
	call MoveBall

	call SavePaddleBg        
	push [paddleY]
	push [paddleX]
	call DrawPaddle
	
	call SaveBallBg
	push [ballY]
	push [ballX]
	call DrawBall
	jmp game_loop
main endp

end main