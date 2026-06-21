[org 0x0100]

start:
    ; save old interrupt vector
    mov ax, 3509h
    int 21h
    mov [old_int9], bx
    mov [old_int9+2], es
	
    ; set custom isr
    push ds
    mov ax, cs
    mov ds, ax
    mov dx, keyboard_isr
    mov ax, 2509h
    int 21h
    pop ds
    
    ; Initialize video mode
    mov ax, 0003h
    int 10h
    
    ; Hide cursor
    mov ah, 01h
    mov ch, 32
    int 10h
    
    call show_welcome_screen
    
.wait_key:
    cmp byte [key_pressed], 1
    jne .wait_key
    
    cmp byte [last_key], 1Ch
    je start_game
    cmp byte [last_key], 01h
    je exit_program
    
    mov byte [key_pressed], 0
    jmp .wait_key

start_game:     ;main game loop
    call init_game
    call game_loop
    jmp exit_program

exit_program:
    ; Restore old interrupt
    push ds
    lds dx, [old_int9]
    mov ax, 2509h
    int 21h
    pop ds
    
    ; Show cursor
    mov ah, 01h
    mov ch, 6
    mov cl, 7
    int 10h
    
    ; Clear screen
    mov ax, 0003h
    int 10h
    
    mov ax, 4C00h ; Exit
    int 21h


keyboard_isr:  ; Keyboard ISR(handles keyboard inputs and detect arrow keys for paddle movement etc)
    push ax
    push bx
    push ds
    
    mov ax, cs
    mov ds, ax
    
    in al, 60h
    mov [last_key], al
    
    cmp al, 4Bh
    je .left_key
    
    cmp al, 4Dh
    je .right_key
    
    cmp al, 1Ch
    je .enter_key
    
    cmp al, 01h
    je .esc_key
    
    cmp al, 39h
    je .space_key
    
    jmp .done

.left_key:  ; Set paddle dir to left
    
    mov byte [paddle_dir], 1
    jmp .set_pressed

.right_key: ; Set paddle dir to right
    
    mov byte [paddle_dir], 2
    jmp .set_pressed

.enter_key:
.esc_key:
.space_key:
.set_pressed:
    mov byte [key_pressed], 1

.done:
    mov al, 20h
    out 20h, al
    
    pop ds
    pop bx
    pop ax
    iret

clear_screen:
    push ax
    push bx
    push cx
    push dx
    push es
    push di
    
    mov ax, 0B800h
    mov es, ax
    xor di, di
	
    mov ax, 0720h
    mov cx, 2000
    rep stosw
    
    pop di
    pop es
    pop dx
    pop cx
    pop bx
    pop ax
    ret

draw_bricks: ; Draws all active bricks on the screen(color depends on row)
    push ax
    push bx
    push cx
    push dx
    push es
    push di
    
    mov ax, 0B800h
    mov es, ax
    xor bx, bx  
    
.draw_loop:
    cmp bx, 32
    jge .done
    
    mov al, [bricks + bx]
    cmp al, 0
    je .next_brick
    
    mov ax, bx
    mov cl, 8
    div cl
    
    mov dh, al
    shl dh, 1
    add dh, 2
    mov dl, ah
    
    test al, 1
    jz .even_row
    
    shl dl, 3
    add dl, 11
    jmp .draw_brick
    
.even_row:
    shl dl, 3
    add dl, 8
    
.draw_brick:
    mov al, dh
    mov cl, 160
    mul cl
    mov di, ax
    xor dh, dh
    shl dx, 1
    add di, dx
    
    mov ax, bx
    mov cl, 8
    div cl
  
    mov ah, 04h  ; Default red for row 1 bricks
    cmp al, 1
    jne .not_row1
    mov ah, 06h  ; yellow for row 2
.not_row1:
    cmp al, 2
    jne .not_row2
    mov ah, 02h  ; green for row 3
.not_row2:
    cmp al, 3
    jne .not_row3
    mov ah, 01h  ; blue for row 4
.not_row3:
    
    mov al, 219
    mov cx, 4
.draw_char:
    stosw
    loop .draw_char
    
.next_brick:
    inc bx
    jmp .draw_loop
    
.done:
    pop di
    pop es
    pop dx
    pop cx
    pop bx
    pop ax
    ret

draw_paddle: ; draw 8 character paddle on position 
    push ax
    push bx
    push cx
    push dx
    push es
    push di
    push si
    
    mov ax, 0B800h
    mov es, ax
    
    ; Erase old paddle
    mov al, [paddle_x]
    xor ah, ah
    mov cl, 160
    mul cl
    mov di, ax
    
    mov ax, 0720h
    mov cx, 80
.erase_row:
    stosw
    loop .erase_row
    
    mov al, [paddle_x]
    xor ah, ah
    mov cl, 160
    mul cl
    mov di, ax
    mov al, [paddle_y]
    xor ah, ah
    shl ax, 1
    add di, ax
    
    mov ah, 01h ; draw paddle with block character(219)
    mov al, 219
    
    mov cl, [paddle_width] ; width=8
    xor ch, ch
.draw:
    mov [es:di], ax
    add di, 2
    loop .draw
    
    mov al, [paddle_x]
    mov [paddle_old_x], al
    mov al, [paddle_y]
    mov [paddle_old_y], al
    
    pop si
    pop di
    pop es
    pop dx
    pop cx
    pop bx
    pop ax
    ret


draw_ball: ; draw ball at new pos and remove it from previous pos
    push ax
    push bx
    push cx
    push dx
    push es
    push di
    mov ax, 0B800h
    mov es, ax
    
    mov al, [ball_old_x]   ; Erase previous ball
    mov cl, 160
    mul cl
    mov di, ax
    mov al, [ball_old_y]
    xor ah, ah
    shl ax, 1
    add di, ax
    mov ax, 0720h
    stosw
    
    mov al, [ball_x]
    mov cl, 160
    mul cl
    mov di, ax
    mov al, [ball_y]
    xor ah, ah
    shl ax, 1
    add di, ax
    
    mov ah, 0Fh  ; draw new ball
    mov al, 'O'
    stosw
    
    mov al, [ball_x]
    mov [ball_old_x], al
    mov al, [ball_y]
    mov [ball_old_y], al
    
    pop di
    pop es
    pop dx
    pop cx
    pop bx
    pop ax
    ret

draw_status:    ; draw game board status(score, lives, time etc)
    push ax
    push bx
    push cx
    push dx
    push es
    push di
    
    mov ax, 0B800h
    mov es, ax
    
    mov di, 0
    mov si, str_score
    call draw_string
    
    add di, 14
    mov ax, [score]
    call draw_number
    
    mov di, 60
    mov si, str_lives
    call draw_string
    
    add di, 14
    mov al, [lives]
    xor ah, ah
    call draw_number
    
    mov di, 120
    mov si, str_time
    call draw_string
    
    add di, 12
    mov ax, [timer_ticks]
    mov bx, 17
    xor dx, dx
    div bx
    
    mov bx, 60
    xor dx, dx
    div bx
    
    push dx
    call draw_number
    
    mov al, ':'
    mov ah, 0Fh
    stosw
    
    pop ax
    cmp ax, 10
    jge .no_leading_zero
    
    push ax
    mov al, '0'
    mov ah, 0Fh
    stosw
    pop ax
    
.no_leading_zero:
    call draw_number
    
    pop di
    pop es
    pop dx
    pop cx
    pop bx
    pop ax
    ret

draw_string:
    push ax
.loop:
    lodsb
    cmp al, 0
    je .done
    mov ah, 0Fh
    stosw
    jmp .loop
.done:
    pop ax
    ret

draw_number:
    push ax
    push bx
    push cx
    push dx
    
    mov bx, 10
    xor cx, cx
    
.divide:
    xor dx, dx
    div bx
    push dx
    inc cx
    cmp ax, 0
    jne .divide
    
.print:
    pop ax
    add al, '0'
    mov ah, 0Fh
    stosw
    loop .print
    
    pop dx
    pop cx
    pop bx
    pop ax
    ret


move_ball:  ; updates ball's pos based on ball_dx & ball_dy
    push ax
    push bx
    
    mov al, [ball_dx]
    add [ball_y], al
    
    mov al, [ball_dy]
    add [ball_x], al
    
    pop bx
    pop ax
    ret

check_wall_collision: 
    push ax
    
    cmp byte [ball_y], 1
    jle .bounce_horizontal
    
    cmp byte [ball_y], 78
    jge .bounce_horizontal
    
    cmp byte [ball_x], 1
    jle .bounce_vertical
    
    jmp .check_bounds

.bounce_horizontal:
    neg byte [ball_dx] ; Reverse direction horizontally
    call play_tone
    jmp .check_bounds
    
.bounce_vertical:
    neg byte [ball_dy] ; Reverse direction vertically
    call play_tone

.check_bounds:
    cmp byte [ball_y], 1
    jge .check_right
    mov byte [ball_y], 1
    
.check_right:
    cmp byte [ball_y], 78
    jle .check_top
    mov byte [ball_y], 78
    
.check_top:
    cmp byte [ball_x], 1
    jge .done
    mov byte [ball_x], 1

.done:
    pop ax
    ret

check_paddle_collision: ; check ball collision with paddle
    push ax
    push bx
    
    mov al, [ball_x]  
    cmp al, [paddle_x]
    jne .done
    
    mov al, [ball_y]
    mov bl, [paddle_y]
    cmp al, bl
    jl .done
    
    add bl, byte [paddle_width]
    cmp al, bl
    jg .done
    
    neg byte [ball_dy] ; Reverse dir vertically
    call play_tone
    
    mov al, [ball_y]    ; checks collision point(left r right side of paddle)
    sub al, [paddle_y]
    mov bl, byte [paddle_width]
    shr bl, 1  ; calc paddle center
    
    cmp al, bl
    jl .hit_left
	je .hit_center
    jg .hit_right
    jmp .done
    
.hit_left:
    mov byte [ball_dx], -1  ; send ball left for left side of paddle
    jmp .done
.hit_center:
	mov byte [ball_dx], 0   ; 90 degree for center
	jmp .done
.hit_right:
    mov byte [ball_dx], 1   ; send ball right for right side of paddle
    jmp .done

.done:
    pop bx
    pop ax
    ret

check_brick_collision:  ; handles brick collision
    push ax
    push bx
    push cx
    push dx
    push si
    xor bx, bx 
.check_loop:
    cmp bx, 32  ; loop for 32 bricks
    jge .done
    
    mov al, [bricks + bx]  ; skip if brick is destroyed
    cmp al, 0
    je .next_brick
    
    mov ax, bx
    mov cl, 8
    div cl
    
    mov dh, al
    shl dh, 1
    add dh, 2
    mov dl, ah
    
    test al, 1
    jz .even_row_check
    
    shl dl, 3
    add dl, 11
    jmp .check_collision
    
.even_row_check:
    shl dl, 3
    add dl, 8
    
.check_collision:
    mov al, [ball_x]
    cmp al, dh
    jne .next_brick
    
    mov al, [ball_y]
    cmp al, dl
    jl .next_brick
    
    mov cl, dl
    add cl, 4
    cmp al, cl
    jge .next_brick
   
    mov byte [bricks + bx], 0 ; Destroy brick
    
    push bx
    call erase_brick
    pop bx
    
    mov ax, [score] ; inc score
    add ax, 10 
    mov [score], ax
    
    neg byte [ball_dy] ; reverse ball vertically
    dec byte [bricks_left] 
    
    call play_tone
    jmp .done
    
.next_brick:
    inc bx
    jmp .check_loop
    
.done:
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret

erase_brick:
    push ax
    push bx
    push cx
    push dx
    push es
    push di
    
    mov ax, 0B800h
    mov es, ax
    
    mov ax, bx
    mov cl, 8
    div cl
    
    mov dh, al
    shl dh, 1
    add dh, 2
    mov dl, ah
    
    test al, 1
    jz .even_row_erase
    
    shl dl, 3
    add dl, 11
    jmp .calc_offset
    
.even_row_erase:
    shl dl, 3
    add dl, 8
    
.calc_offset:
    mov al, dh
    mov cl, 160
    mul cl
    mov di, ax
    xor dh, dh
    shl dx, 1
    add di, dx
    
    mov ax, 0720h
    mov cx, 4
.erase_loop:
    stosw
    loop .erase_loop
    
    pop di
    pop es
    pop dx
    pop cx
    pop bx
    pop ax
    ret

check_ball_lost: ; checks iif ball hits the ground and dec lives
    push ax
    cmp byte [ball_x], 24
    jl .done
    
    dec byte [lives]
    call play_lose_tone
	
    mov byte [ball_x], 20 ; reset ball and paddle pos to middle
    mov al, [paddle_y]
    add al, 3
    mov [ball_y], al
    mov byte [ball_dx], -1
    mov byte [ball_dy], -1
   
    mov byte [ball_paused], 1     ; Pause game until space
    
.done:
    pop ax
    ret


check_win:
    push ax
    cmp byte [bricks_left], 0
    jne .not_won
    
    mov byte [game_state], 2 ; Set game state to win(2)
    
.not_won:
    pop ax
    ret

check_game_over:
    push ax
    
    cmp byte [lives], 0
    jne .not_over
    
    
    mov byte [game_state], 3 ; Set game state to lose(3)
    
.not_over:
    pop ax
    ret

show_welcome_screen:
    call clear_screen
    
    push es
    push di
    
    mov ax, 0B800h
    mov es, ax
    
    mov di, 480
    mov si, str_title
    call draw_string
    
    mov di, 960
    mov si, str_rules1
    call draw_string
    
    mov di, 1120
    mov si, str_rules2
    call draw_string
    
    mov di, 1280
    mov si, str_rules3
    call draw_string
    
    mov di, 1440
    mov si, str_rules4
    call draw_string
    
    mov di, 1920
    mov si, str_start
    call draw_string
    
    mov di, 2080
    mov si, str_exit
    call draw_string
    
    pop di
    pop es
    
    mov byte [key_pressed], 0
    ret

show_game_over:
    call clear_screen
    
    push ax
    push bx
    push cx
    push dx
    push es
    push di
    
    mov ax, 0B800h
    mov es, ax
    
    mov di, 1440
    add di, 54
    mov si, str_game_over
    mov ah, 0Ch
    call draw_string_colored
    
    mov di, 1760
    add di, 52
    mov si, str_final_score
    mov ah, 0Eh
    call draw_string_colored
    
    mov ax, [score]
    call draw_number
    
    mov di, 2080
    add di, 60
    mov si, str_time_taken
    mov ah, 0Bh
    call draw_string_colored
    
    mov ax, [timer_ticks]
    mov bx, 17
    xor dx, dx
    div bx
    
    mov bx, 60
    xor dx, dx
    div bx
    
    push dx
    call draw_number
    
    mov al, ':'
    mov ah, 0Fh
    stosw
    
    pop ax
    cmp ax, 10
    jge .no_zero
    push ax
    mov al, '0'
    mov ah, 0Fh
    stosw
    pop ax
.no_zero:
    call draw_number
    
    pop di
    pop es
    pop dx
    pop cx
    pop bx
    pop ax
    ret

show_win_screen:
    call clear_screen
    
    push ax
    push bx
    push cx
    push dx
    push es
    push di
    
    mov ax, 0B800h
    mov es, ax
    
    mov di, 1440
    add di, 66
    mov si, str_you_win
    mov ah, 0Ah
    call draw_string_colored
    
    mov di, 1760
    add di, 52
    mov si, str_final_score
    mov ah, 0Eh
    call draw_string_colored
    
    mov ax, [score]
    call draw_number
    
    mov di, 2080
    add di, 60
    mov si, str_time_taken
    mov ah, 0Bh
    call draw_string_colored
    
    mov ax, [timer_ticks]
    mov bx, 17
    xor dx, dx
    div bx
    
    mov bx, 60
    xor dx, dx
    div bx
    
    push dx
    call draw_number
    
    mov al, ':'
    mov ah, 0Fh
    stosw
    
    pop ax
    cmp ax, 10
    jge .no_zero
    push ax
    mov al, '0'
    mov ah, 0Fh
    stosw
    pop ax
.no_zero:
    call draw_number
    
    pop di
    pop es
    pop dx
    pop cx
    pop bx
    pop ax
    ret

draw_string_colored: ; draws a colored null terminated string
    push ax
    push bx
    mov bl, ah
.loop:
    lodsb
    cmp al, 0
    je .done
    mov ah, bl
    stosw
    jmp .loop
.done:
    pop bx
    pop ax
    ret

init_game:  ;Main game func(initializes game vars bricks,balls, paddle etc)

    mov byte [game_state], 1  ; set game state to 1(playing)
    mov byte [lives], 3
    mov word [score], 0
    mov byte [ball_paused], 1
    mov word [timer_ticks], 0
   
    mov cx, 32
    mov di, bricks
.init_bricks:
    mov byte [di], 1
    inc di
    loop .init_bricks
    
    mov byte [bricks_left], 32
    
    mov byte [paddle_x], 22  ; paddle at center(width=8)
    mov byte [paddle_y], 35
    mov byte [paddle_old_x], 22
    mov byte [paddle_old_y], 35
    mov byte [paddle_width], 8
    mov byte [paddle_dir], 0
    
    mov byte [ball_x], 20     ; Initialize ball above paddle with vel(-1,-1)
    mov byte [ball_y], 38
    mov byte [ball_old_x], 20
    mov byte [ball_old_y], 38
    mov byte [ball_dx], -1
    mov byte [ball_dy], -1
  
    mov byte [key_pressed], 0
    call clear_screen
    ret

game_loop:  ; Main game loop(handle game physics,draw objects,check collision ad game state)
    cmp byte [game_state], 1
    jne near .end_game
    
    cmp byte [ball_paused], 0 ; skip timer update for paused ball(game started or ball respawned)
    jne .skip_timer
    inc word [timer_ticks]
    
.skip_timer:
    cmp byte [ball_paused], 1
    je .paused_mode
    
	; handle ball physics or collision
    call move_ball    
    call check_wall_collision
    call check_paddle_collision
    call check_brick_collision
    call check_ball_lost
    call check_win
    call check_game_over
    jmp .update_paddle
    
.paused_mode:   ; pauses game till space
    cmp byte [key_pressed], 1
    jne .update_paddle
    
    cmp byte [last_key], 39h
    jne .clear_key
    
    mov byte [ball_paused], 0 ; unpause at space
    
.clear_key:
    mov byte [key_pressed], 0
    
.update_paddle:  ; Process paddle movement based on input(left=1, right=2)
    cmp byte [paddle_dir], 1
    je .move_left
    cmp byte [paddle_dir], 2
    je .move_right
    jmp .no_move
    
.move_left:  ; move paddle left by 3 with boundary check
    cmp byte [paddle_y], 1  
    jle .no_move
    sub byte [paddle_y], 3
    cmp byte [paddle_y], 1
    jge .update_ball_if_paused
    mov byte [paddle_y], 1
    jmp .update_ball_if_paused
    
.move_right: ; move paddle right by 3 with boundary check
    mov al, [paddle_y]
    add al, [paddle_width]
    add al, 3
    cmp al, 79
    jge .limit_right
    add byte [paddle_y], 3
    jmp .update_ball_if_paused
    
.limit_right:  
    mov al, 79
    sub al, [paddle_width]
    mov [paddle_y], al
    jmp .update_ball_if_paused

.update_ball_if_paused: 
    cmp byte [ball_paused], 1
    jne .no_move
    mov al, [paddle_y]
    add al, 3
    mov [ball_y], al
    
.no_move:
    mov byte [paddle_dir], 0  ; Reset dir for next frame

    call draw_bricks
    call draw_paddle
    call draw_ball
    call draw_status
   
    call delay_frame ; Fram rate control
    
    jmp game_loop
    
.end_game:
    cmp byte [game_state], 2
    je .show_win
    
    call show_game_over
    jmp .wait_exit
    
.show_win:
    call show_win_screen
    
.wait_exit:
    mov byte [key_pressed], 0
.wait_key_loop:
    cmp byte [key_pressed], 1
    jne .wait_key_loop
    
    cmp byte [last_key], 01h ; wait for esc(01h)
    jne .wait_key_loop
    
    ret

delay_frame:
    push ax
    push cx
    push dx
    
    mov ah, 86h
    mov cx, 0
    mov dx, 65000   ; 65ms game speed
    int 15h
    
    pop dx
    pop cx
    pop ax
    ret

; Plays a short high pitch beep sound for ball collision
play_tone:
    push ax
    push bx
    push cx
    
    ; Configure timer for sound generation
    mov al, 0B6h
    out 43h, al
    
    ; Set frequency = 2000Hz
    mov ax, 2000
    out 42h, al
    mov al, ah
    out 42h, al
    
    ; Turn on speaker
    in al, 61h
    or al, 3
    out 61h, al
    
    ; Short tone duration
    mov cx, 1000
.wait:
    loop .wait
    
    ; Turn off speaker
    in al, 61h
    and al, 0FCh
    out 61h, al
    
    pop cx
    pop bx
    pop ax
    ret

; Plays a longer, descending pitch beep sound for life loss 
play_lose_tone:
    push ax
    push bx
    push cx

    ; Turn speaker on
    in al, 61h
    or al, 3
    out 61h, al

    ; Start frequency at 1200Hz and descend to 300Hz 
    mov bx, 1200
fall1:
    ; Configure timer for sound generation
    mov al, 0B6h
    out 43h, al

    mov ax, bx
    out 42h, al
    mov al, ah
    out 42h, al
	
    mov cx, 1000  ; Play tone at current frequency
d1:
    loop d1
    sub bx, 15     ; Decrease frequency by 15 for descending pitch effect
    cmp bx, 300
    ja fall1

    ; Turn off speaker
    in al, 61h
    and al, 0FCh
    out 61h, al

    pop cx
    pop bx
    pop ax
    ret

old_int9        dd 0
last_key        db 0
key_pressed     db 0

game_state      db 0
lives           db 3
score           dw 0
bricks_left     db 32
timer_ticks     dw 0
ball_paused     db 0

paddle_x        db 22
paddle_y        db 35
paddle_old_x    db 22
paddle_old_y    db 35
paddle_width    db 8
paddle_dir      db 0

ball_x          db 20
ball_y          db 40
ball_old_x      db 20
ball_old_y      db 40
ball_dx         db 1
ball_dy         db 1

bricks          times 32 db 1

str_title       db '    ATARI BREAKOUT    ', 0
str_rules1      db 'Use LEFT/RIGHT arrows to move paddle', 0
str_rules2      db 'Break all bricks to win!', 0
str_rules3      db 'Score: 10 points per brick', 0
str_rules4      db 'Lives: 3 | Press SPACE to launch ball', 0
str_start       db 'Press ENTER to start', 0
str_exit        db 'Press ESC to exit', 0
str_score       db 'Score: ', 0
str_lives       db 'Lives: ', 0
str_time        db 'Time: ', 0
str_game_over   db 'GAME OVER!', 0
str_you_win     db 'YOU WIN!', 0
str_final_score db 'Final Score: ', 0
str_time_taken  db 'Time: ', 0