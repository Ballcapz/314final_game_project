%include "/usr/local/share/csc314/asm_io.inc"


; the file that stores the initial state
%define BOARD_FILE 'board.txt'

; how to represent everything
%define WALL_CHAR '#'
%define PLAYER_CHAR 'O'
%define	PLAYER_2_CHAR 'X'
%define GOLD_CHAR '$'
%define EMPTY_CHAR ' '
%define TICK 100000	; 1/10th of a second
%define MONSTER_CHAR 'M'
%define SPIKE '^'
%define Z_TP 'Z'
%define T_TP 'T'
%define B_TP 'B'
%define WIN_TP '@'
%define WIN_CHAR '*'

; the size of the game screen in characters
%define HEIGHT 20
%define WIDTH 40

; the player starting position.
; top left is considered (0,0)
%define STARTX 1
%define STARTY 1
%define STARTX_2 38
%define STARTY_2 18

%define MONSTERX 12
%define MONSTERY 14

; these keys do things
%define EXITCHAR 'x'
%define UPCHAR 'w'
%define LEFTCHAR 'a'
%define DOWNCHAR 's'
%define RIGHTCHAR 'd'

%define UPCHAR_2 'k'
%define LEFTCHAR_2 'h'
%define DOWNCHAR_2 'j'
%define RIGHTCHAR_2 'l'


segment .data

	; used to fopen() the board file defined above
	board_file			db BOARD_FILE,0

	; used to change the terminal mode
	mode_r				db "r",0
	raw_mode_on_cmd		db "stty raw -echo",0
	raw_mode_off_cmd	db "stty -raw echo",0

	; called by system() to clear/refresh the screen
	clear_screen_cmd	db "clear",0

	; things the program will print
	help_str			db 13,10,"Controls For Player 1 (O): ", \
							UPCHAR,"=UP / ", \
							LEFTCHAR,"=LEFT / ", \
							DOWNCHAR,"=DOWN / ", \
							RIGHTCHAR,"=RIGHT / ", \
							EXITCHAR,"=EXIT", \
							13,10,10,0
	
	help_str_2			db 13,10,"Controls For Player 2 (X): ", \
							UPCHAR_2,"=UP / ", \
							LEFTCHAR_2,"=LEFT / ", \
							DOWNCHAR_2,"=DOWN / ", \
							RIGHTCHAR_2,"=RIGHT / ", \
							EXITCHAR,"=EXIT", \
							13,10,10,0
	
	
	wincon_str			db 13,10,"Get to the *'s to win",13,10,10,0

	gold_counter_1 		dd 0
	gold_counter_2 		dd 0
	
	gold_fmt_1 			db "Player 1 Score: %d",13,10,0
	gold_fmt_2 			db "Player 2 Score: %d",13,10,0
	

	
	health_fmt			db "Health: %c%c%c",13,10,0
	health_counter		dd  2
	
	p1_won				db 13,10,"Player 1 wins with a score of %d!",13,10,10,0
	p2_won				db 13,10,"Player 2 wins with a score of %d!",13,10,10,0

segment .bss

	; this array stores the current rendered gameboard (HxW)
	board	resb	(HEIGHT * WIDTH)

	; these variables store the current player position
	xpos	resd	1
	ypos	resd	1
	
	; these variables store the current player 2 position
	xpos_2	resd	38
	ypos_2	resd	18
	
	; these vars store the monster's position

segment .text

	global	asm_main
	global  raw_mode_on
	global  raw_mode_off
	global  init_board
	global  render

	extern	system
	extern	putchar
	extern	getchar
	extern	printf
	extern	fopen
	extern	fread
	extern	fgetc
	extern	fclose

	extern  usleep
	extern	fcntl


asm_main:
	enter	0,0
	pusha
	;***************CODE STARTS HERE***************************

	; put the terminal in raw mode so the game works nicely
	call	raw_mode_on

	; read the game board file into the global variable
	call	init_board

	; set the player at the proper start position
	mov		DWORD [xpos], STARTX
	mov		DWORD [ypos], STARTY

	; set the player2 at the proper start position
	mov		DWORD [xpos_2], STARTX_2
	mov		DWORD [ypos_2], STARTY_2

	; the game happens in this loop
	; the steps are...
	;   1. render (draw) the current board
	;   2. get a character from the user
	;	3. store current xpos,ypos in esi,edi
	;	4. update xpos,ypos based on character from user
	;	5. check what's in the buffer (board) at new xpos,ypos
	;	6. if it's a wall, reset xpos,ypos to saved esi,edi
	;	7. otherwise, just continue! (xpos,ypos are ok)
	game_loop:

		push TICK
		call usleep
		add  esp, 4
		

		; draw the game board
		call	render

		; get an action from the user
;		call	getchar
		call 	nonblocking_getchar
		cmp 	al, -1
		je		game_loop

; Above this runs continously
;;;;;;;;;;;;;;;;-------------------------------;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;-----------------------
;******************* PLAYER 1 **********************
		; store the current position
		; we will test if the new position is legal
		; if not, we will restore these for PLAYER 1
		mov		esi, [xpos]
		mov		edi, [ypos]
		mov		ebx, [xpos_2]
		mov		ecx, [ypos_2]

		; choose what to do
		cmp		eax, EXITCHAR
		je		game_loop_end
		cmp		eax, UPCHAR
		je 		move_up
		cmp		eax, LEFTCHAR
		je		move_left
		cmp		eax, DOWNCHAR
		je		move_down
		cmp		eax, RIGHTCHAR
		je		move_right
		cmp		eax, UPCHAR_2
		je		move_up_2
		cmp 	eax, LEFTCHAR_2
		je		move_left_2
		cmp		eax, DOWNCHAR_2
		je		move_down_2
		cmp 	eax, RIGHTCHAR_2
		je		move_right_2
		jmp		input_end			; or just do nothing

		; move the player according to the input character
		move_up:
			dec		DWORD [ypos]
			jmp		input_end
		move_left:
			dec		DWORD [xpos]
			jmp		input_end
		move_down:
			inc		DWORD [ypos]
			jmp		input_end
		move_right:
			inc		DWORD [xpos]
			jmp 	input_end
		move_up_2:
			dec		DWORD [ypos_2]
			jmp		input_end
		move_left_2:
			dec		DWORD [xpos_2]
			jmp		input_end
		move_down_2:
			inc		DWORD [ypos_2]
			jmp		input_end
		move_right_2:
			inc		DWORD [xpos_2]
		input_end:

		; (W * y) + x = pos

		; compare the current position to the wall character
;	Player 1
		mov		eax, WIDTH
		mul		DWORD [ypos]
		add		eax, [xpos]
		lea		eax, [board + eax]
		cmp		BYTE [eax], WALL_CHAR
		jne		valid_move
			; opps, that was an invalid move, reset
			mov		DWORD [xpos], esi
			mov		DWORD [ypos], edi
		valid_move:
; check if the player has won			
			cmp BYTE [eax], WIN_CHAR
			jne not_won_1
				jmp player_1_win
			not_won_1:

			cmp BYTE [eax], GOLD_CHAR
			jne not_gold
				add DWORD [gold_counter_1], 100
				mov BYTE [eax], EMPTY_CHAR
			not_gold:
; check if p1 needs to tp
			cmp BYTE [eax], Z_TP
			je	z_tp_1
			cmp	BYTE [eax], B_TP
			je	b_tp_1
			cmp	BYTE [eax], T_TP
			je	t_tp_1
			cmp BYTE [eax], WIN_TP
			je	win_tp_1
			jmp no_tp_1

; completes the tp	
			z_tp_1:
				mov		DWORD [xpos], 10
				mov		DWORD [ypos], 18
				; remove other z
				mov		eax, 18
				mov		ebx, WIDTH
				mul 	ebx
				add		eax, 18 
				mov		BYTE [board + eax], EMPTY_CHAR
				jmp		no_tp_1
			b_tp_1:
				mov		DWORD [xpos], 10
				mov		DWORD [ypos], 16
				; remove other b
				mov		eax, 5 
				mov		ebx, WIDTH
				mul 	ebx
				add		eax, 34 
				mov		BYTE [board + eax], EMPTY_CHAR
				jmp		no_tp_1
			t_tp_1:
				mov		DWORD [xpos], 1
				mov		DWORD [ypos], 1
				; remove other t
				mov		eax, 14 
				mov		ebx, WIDTH
				mul 	ebx
				add		eax, 35 
				mov		BYTE [board + eax], EMPTY_CHAR
				jmp		no_tp_1
			win_tp_1:
				mov		DWORD [xpos], 19
				mov		DWORD [ypos], 11

			no_tp_1:

;	Player 2
		mov		eax, WIDTH
		mul		DWORD [ypos_2]
		add		eax, [xpos_2]
		lea		eax, [board + eax]
		cmp		BYTE [eax], WALL_CHAR
		jne		valid_move_2
			; opps, that was an invalid move, reset
			mov		DWORD [xpos_2], ebx
			mov		DWORD [ypos_2], ecx
		valid_move_2:
		
			cmp BYTE [eax], WIN_CHAR
			jne not_won_2
				jmp player_2_win
			not_won_2:
	
			cmp BYTE [eax], GOLD_CHAR
			jne not_gold_2
				add DWORD [gold_counter_2], 100
				mov BYTE [eax], EMPTY_CHAR
			not_gold_2:

; check if p2 needs to tp
			cmp BYTE [eax], Z_TP
			je	z_tp_2
			cmp	BYTE [eax], B_TP
			je	b_tp_2
			cmp	BYTE [eax], T_TP
			je	t_tp_2
			cmp BYTE [eax], WIN_TP
			je	win_tp_2
			jmp no_tp_2

; completes the tp	
			z_tp_2:
				mov		DWORD [xpos_2], 36
				mov		DWORD [ypos_2], 16
				; remove other z
				mov		eax, 1
				mov		ebx, WIDTH
				mul 	ebx
				add		eax, 38 
				mov		BYTE [board + eax], EMPTY_CHAR
				jmp		no_tp_2
			b_tp_2:
				mov		DWORD [xpos_2], 36
				mov		DWORD [ypos_2], 12
				; remove other b
				mov		eax, 7 
				mov		ebx, WIDTH
				mul 	ebx
				add		eax, 10 
				mov		BYTE [board + eax], EMPTY_CHAR
				jmp		no_tp_2
			t_tp_2:
				mov		DWORD [xpos_2], 38
				mov		DWORD [ypos_2], 18
				; remove other t
				mov		eax, 18 
				mov		ebx, WIDTH
				mul 	ebx
				add		eax, 5 
				mov		BYTE [board + eax], EMPTY_CHAR
				jmp		no_tp_2
			win_tp_2:
				mov		DWORD [xpos_2], 19
				mov		DWORD [ypos_2], 12

			no_tp_2:			; or does nothing


	jmp		game_loop

	player_1_win:
		add		DWORD [gold_counter_1], 500
		push 	DWORD [gold_counter_1]
		push	p1_won
		call	printf
		add		esp, 8
	jmp 	game_loop_end

	player_2_win:
		add		DWORD [gold_counter_2], 500
		push 	DWORD [gold_counter_2]
		push	p2_won
		call	printf
		add		esp, 8
	game_loop_end:

	; restore old terminal functionality
	call raw_mode_off

	;***************CODE ENDS HERE*****************************
	popa
	mov		eax, 0
	leave
	ret

; === FUNCTION ===
raw_mode_on:

	push	ebp
	mov		ebp, esp

	push	raw_mode_on_cmd
	call	system
	add		esp, 4

	mov		esp, ebp
	pop		ebp
	ret

; === FUNCTION ===
raw_mode_off:

	push	ebp
	mov		ebp, esp

	push	raw_mode_off_cmd
	call	system
	add		esp, 4

	mov		esp, ebp
	pop		ebp
	ret

; === FUNCTION ===
init_board:

	push	ebp
	mov		ebp, esp

	; FILE* and loop counter
	; ebp-4, ebp-8
	sub		esp, 8

	; open the file
	push	mode_r
	push	board_file
	call	fopen
	add		esp, 8
	mov		DWORD [ebp-4], eax

	; read the file data into the global buffer
	; line-by-line so we can ignore the newline characters
	mov		DWORD [ebp-8], 0
	read_loop:
	cmp		DWORD [ebp-8], HEIGHT
	je		read_loop_end

		; find the offset (WIDTH * counter)
		mov		eax, WIDTH
		mul		DWORD [ebp-8]
		lea		ebx, [board + eax]

		; read the bytes into the buffer
		push	DWORD [ebp-4]
		push	WIDTH
		push	1
		push	ebx
		call	fread
		add		esp, 16

		; slurp up the newline
		push	DWORD [ebp-4]
		call	fgetc
		add		esp, 4

	inc		DWORD [ebp-8]
	jmp		read_loop
	read_loop_end:

	; close the open file handle
	push	DWORD [ebp-4]
	call	fclose
	add		esp, 4

	mov		esp, ebp
	pop		ebp
	ret

; === FUNCTION ===
render:

	push	ebp
	mov		ebp, esp

	; two ints, for two loop counters
	; ebp-4, ebp-8
	sub		esp, 8

	; clear the screen
	push	clear_screen_cmd
	call	system
	add		esp, 4

	; print the help information
	push	help_str
	call	printf
	add		esp, 4
	
	push 	help_str_2
	call	printf
	add		esp, 4

	; print winning instruction
	push	wincon_str
	call	printf
	add		esp, 4

	; print the score p1
	push 	DWORD [gold_counter_1]
	push 	gold_fmt_1
	call 	printf
	add 	esp, 8
	; p2	
	push 	DWORD [gold_counter_2]
	push 	gold_fmt_2
	call 	printf
	add 	esp, 8

	; outside loop by height
	; i.e. for(c=0; c<height; c++)
	mov		DWORD [ebp-4], 0
	y_loop_start:
	cmp		DWORD [ebp-4], HEIGHT
	je		y_loop_end

		; inside loop by width
		; i.e. for(c=0; c<width; c++)
		mov		DWORD [ebp-8], 0
		x_loop_start:
		cmp		DWORD [ebp-8], WIDTH
		je 		x_loop_end


			; check if (xpos_2, ypos_2)= (x,y)
			mov		eax, [xpos_2]
			cmp		eax, DWORD [ebp-8]
			jne   	end_check_player_2
			mov		eax, [ypos_2]
			cmp 	eax, DWORD [ebp-4]
			jne		end_check_player_2
				; if both were =, print the second player
				push 	PLAYER_2_CHAR
				jmp 	print_end
			end_check_player_2:

			; check if (xpos,ypos)=(x,y)
			mov		eax, [xpos]
			cmp		eax, DWORD [ebp-8]
			jne		print_board
			mov		eax, [ypos]
			cmp		eax, DWORD [ebp-4]
			jne		print_board
				; if both were equal, print the player
				push	PLAYER_CHAR
				jmp		print_end
			print_board:
				; otherwise print whatever's in the buffer
				mov		eax, [ebp-4]
				mov		ebx, WIDTH
				mul		ebx
				add		eax, [ebp-8]
				mov		ebx, 0
				mov		bl, BYTE [board + eax]
				push	ebx
			print_end:
			call	putchar
			add		esp, 4

		inc		DWORD [ebp-8]
		jmp		x_loop_start
		x_loop_end:

		; write a carriage return (necessary when in raw mode)
		push	0x0d
		call 	putchar
		add		esp, 4

		; write a newline
		push	0x0a
		call	putchar
		add		esp, 4

	inc		DWORD [ebp-4]
	jmp		y_loop_start
	y_loop_end:

	mov		esp, ebp
	pop		ebp
	ret


nonblocking_getchar:

; returns -1 on no-data
; returns char on success

; magic values
%define F_GETFL 3
%define F_SETFL 4
%define O_NONBLOCK 2048
%define STDIN 0

	push	ebp
	mov		ebp, esp

	; single int used to hold flags
	; single character (aligned to 4 bytes) return
	sub		esp, 8

	; get current stdin flags
	; flags = fcntl(stdin, F_GETFL, 0)
	push	0
	push	F_GETFL
	push	STDIN
	call	fcntl
	add		esp, 12
	mov		DWORD [ebp-4], eax

	; set non-blocking mode on stdin
	; fcntl(stdin, F_SETFL, flags | O_NONBLOCK)
	or		DWORD [ebp-4], O_NONBLOCK
	push	DWORD [ebp-4]
	push	F_SETFL
	push	STDIN
	call	fcntl
	add		esp, 12

	call	getchar
	mov		DWORD [ebp-8], eax

	; restore blocking mode
	; fcntl(stdin, F_SETFL, flags ^ O_NONBLOCK
	xor		DWORD [ebp-4], O_NONBLOCK
	push	DWORD [ebp-4]
	push	F_SETFL
	push	STDIN
	call	fcntl
	add		esp, 12

	mov		eax, DWORD [ebp-8]

	mov		esp, ebp
	pop		ebp
	ret


























