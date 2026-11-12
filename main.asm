.model small
.stack 100h


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


main proc
	mov ax, @data
	mov ds, ax
	
	call SetGraphic
	call ExitGame
main endp

end main