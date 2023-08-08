# MARK KRAUS
# MRK133

# Cardinal directions.
.eqv DIR_N 0
.eqv DIR_E 1
.eqv DIR_S 2
.eqv DIR_W 3

# Game grid dimensions.
.eqv GRID_CELL_SIZE 4 # pixels
.eqv GRID_WIDTH  16 # cells
.eqv GRID_HEIGHT 14 # cells
.eqv GRID_CELLS 224 #= GRID_WIDTH * GRID_HEIGHT

# How long the snake can possibly be.
.eqv SNAKE_MAX_LEN GRID_CELLS # segments

# How many frames (1/60th of a second) between snake movements.
.eqv SNAKE_MOVE_DELAY 12 # frames

# How many apples the snake needs to eat to win the game.
.eqv APPLES_NEEDED 20

# ------------------------------------------------------------------------------------------------
.data

# set to 1 when the player loses the game (running into the walls/other part of the snake).
lost_game: .word 0

# the direction the snake is facing (one of the DIR_ constants).
snake_dir: .word DIR_N

# how long the snake is (how many segments).
snake_len: .word 2

# parallel arrays of segment coordinates. index 0 is the head.
snake_x: .byte 0:SNAKE_MAX_LEN
snake_y: .byte 0:SNAKE_MAX_LEN

# used to keep track of time until the next time the snake can move.
snake_move_timer: .word 0

# 1 if the snake changed direction since the last time it moved.
snake_dir_changed: .word 0

# how many apples have been eaten.
apples_eaten: .word 0

# coordinates of the (one) apple in the world.
apple_x: .word 3
apple_y: .word 2

# A pair of arrays, indexed by direction, to turn a direction into x/y deltas.
# e.g. direction_delta_x[DIR_E] is 1, because moving east increments X by 1.
#                         N  E  S  W
direction_delta_x: .byte  0  1  0 -1
direction_delta_y: .byte -1  0  1  0

.text

# ------------------------------------------------------------------------------------------------

# these .includes are here to make these big arrays come *after* the interesting
# variables in memory. it makes things easier to debug.
.include "display_2211_0822.asm"
.include "textures.asm"

# ------------------------------------------------------------------------------------------------

.text
.globl main
main:
	jal setup_snake
	jal wait_for_game_start

	# main game loop
	_loop:
		jal check_input
		jal update_snake
		jal draw_all
		jal display_update_and_clear
		jal wait_for_next_frame
	jal check_game_over
	beq v0, 0, _loop

	# when the game is over, show a message
	jal show_game_over_message
syscall_exit

# ------------------------------------------------------------------------------------------------
# Misc game logic
# ------------------------------------------------------------------------------------------------

# ------------------------------------------------------------------------------------------------

# waits for the user to press a key to start the game (so the snake doesn't go barreling
# into the wall while the user ineffectually flails attempting to click the display (ask
# me how I know that that happens))
wait_for_game_start:
enter
	_loop:
		jal draw_all
		jal display_update_and_clear
		jal wait_for_next_frame
	jal input_get_keys_pressed
	beq v0, 0, _loop
leave

# ------------------------------------------------------------------------------------------------

# returns a boolean (1/0) of whether the game is over. 1 means it is.
check_game_over:
enter
	li v0, 0

	# if they've eaten enough apples, the game is over.
	lw t0, apples_eaten
	blt t0, APPLES_NEEDED, _endif
		li v0, 1
		j _return
	_endif:

	# if they lost the game, the game is over.
	lw t0, lost_game
	beq t0, 0, _return
		li v0, 1
_return:
leave

# ------------------------------------------------------------------------------------------------

show_game_over_message:
enter
	# first clear the display
	jal display_update_and_clear

	# then show different things depending on if they won or lost
	lw t0, lost_game
	bne t0, 0, _lost
		# they finished successfully!
		li   a0, 7
		li   a1, 25
		lstr a2, "yay! you"
		li   a3, COLOR_GREEN
		jal  display_draw_colored_text

		li   a0, 12
		li   a1, 31
		lstr a2, "did it!"
		li   a3, COLOR_GREEN
		jal  display_draw_colored_text
	j _endif
	_lost:
		# they... didn't...
		li   a0, 5
		li   a1, 30
		lstr a2, "oh no :("
		li   a3, COLOR_RED
		jal  display_draw_colored_text
	_endif:

	jal display_update_and_clear
leave

# ------------------------------------------------------------------------------------------------
# Snake
# ------------------------------------------------------------------------------------------------

# sets up the snake so the first two segments are in the middle of the screen.
setup_snake:
enter
	# snake head in the middle, tail below it
	li  t0, GRID_WIDTH
	div t0, t0, 2
	sb  t0, snake_x
	sb  t0, snake_x + 1

	li  t0, GRID_HEIGHT
	div t0, t0, 2
	sb  t0, snake_y
	add t0, t0, 1
	sb  t0, snake_y + 1
leave

# ------------------------------------------------------------------------------------------------

# checks for the arrow keys to change the snake's direction.
check_input:
enter s0, s1, s2
	
	# s2 = snake_dir_changed
	lw s2, snake_dir_changed

	# if(snake_dir_changed != 0) { break }
	bne s2, 0, _break
	
	# input_get_keys_held()
	jal input_get_keys_held
	
	# s0 = v0, s1 = snake_dir
	move s0, v0
	lw s1, snake_dir
	
	# switch(){
	beq s0, KEY_U, _north
	beq s0, KEY_D, _south
	beq s0, KEY_R, _east
	beq s0, KEY_L, _west
	j _break
		# north()
		_north:
			# if(snake_dir == DIR_(N or S)) { break }
			beq s1, DIR_N, _break
			beq s1, DIR_S, _break
			
			# snake_dir = DIR_N
			li s1, DIR_N
			sw s1, snake_dir
			
			# snake_dir_changed = 1
			li s2, 1
			sw s2, snake_dir_changed
		
			j _break
		
		# south()
		_south:
			# if(snake_dir == DIR_(S or N)) { break }
			beq s1, DIR_S, _break
			beq s1, DIR_N, _break
			
			# snake_dir = DIR_S
			li s1, DIR_S
			sw s1, snake_dir
			
			# snake_dir_changed = 1
			li s2, 1
			sw s2, snake_dir_changed
		
			j _break
		# east()
		_east:
			# if(snake_dir == DIR_(E or W)) { break }
			beq s1, DIR_E, _break
			beq s1, DIR_W, _break
			
			# snake_dir = DIR_E
			li s1, DIR_E
			sw s1, snake_dir
			
			# snake_dir_changed = 1
			li s2, 1
			sw s2, snake_dir_changed
			
			j _break
		# west()
		_west:
			# if(snake_dir == DIR_(W or E)) { break }
			beq s1, DIR_W, _break
			beq s1, DIR_E, _break
			
			# snake_dir = DIR_W
			li s1, DIR_W
			sw s1, snake_dir
			
			# snake_dir_changed = 1
			li s2, 1
			sw s2, snake_dir_changed
	# }
	_break:
	
leave s0, s1, s2

# ------------------------------------------------------------------------------------------------

# update the snake.
update_snake:
enter s0, s1

	#if(snake_move_timer != 0) { snake_move_timer-- }
	lw s0, snake_move_timer
	_if:
		beq s0, 0, _else
		
		sub s0, s0, 1
		sw s0, snake_move_timer
		
		j _break
	#else{
	_else:
		# snake_move_timer = SNAKE_MOVE_DELAY
		li s0, SNAKE_MOVE_DELAY
		sw s0, snake_move_timer
		
		# snake_dir_changed = 0
		lw s1, snake_dir_changed
		li s1, 0
		sw s1, snake_dir_changed
		
		# move_snake()
		jal move_snake
	_break:
	
leave s0, s1

# ------------------------------------------------------------------------------------------------

move_snake:
enter s0, s1, s2, s3
	# compute_next_snake_pos()
	jal compute_next_snake_pos
	
	# s0 = v0, s1 = v1
	move s0, v0
	move s1, v1
	
	
	
	
	# switch() {
	blt s0, 0, _game_over			# v0 < 0
	bge s0, GRID_WIDTH, _game_over		# v0 >= GRID_WIDTH
	blt s1, 0, _game_over			# v1 < 0
	bge s1, GRID_HEIGHT, _game_over		# v1 >= GRID_WIDTH
	move a0, s0
	move a1, s1
	jal is_point_on_snake
	beq v0, 1, _game_over
	# s2 = apple_x, s3 = apple_y
	lw t0, apple_x
	lw t1, apple_y
	bne s0, t0, _move_forward		# v0 != apple_x
	bne s1, t1, _move_forward		# v1 != apple_y
	j _eat_apple
	
		_game_over:
			# lost_game = 1
			lw t0, lost_game
			li t0, 1
			sw t0, lost_game
			j _break
			
		_move_forward:
			# shift_snake_segments(), snake_x = s0, snake_y = s1
			jal shift_snake_segments
			sb s0, snake_x
			sb s1, snake_y
			j _break
		
		_eat_apple:
			# apples_eaten++
			lw t0, apples_eaten
			add, t0, t0, 1
			sw t0, apples_eaten
			
			# snake_len++
			lw t0, snake_len
			add t0, t0, 1
			sw t0, snake_len
			
			# shift_snake_segments()
			jal shift_snake_segments
			
			# snake_x = s0, snake_y = s1
			sb s0, snake_x
			sb s1, snake_y
			
			# move_ apple()
			jal move_apple
	# }
	_break:		
	
leave s0, s1 s2, s3

# ------------------------------------------------------------------------------------------------

shift_snake_segments:
enter
	# t0 = i
	# i = snake_len - 1
	lw t0, snake_len
	sub t0, t0, 1
	
	# for(i >= 1; i--){ 
	_loop:
		blt t0, 1, _break
		
		# snake_x[i] = snake_x[i - 1];
		move t1, t0		# t1 = i
		sub t1, t1, 1		# t1 = i - 1
		lb t2, snake_x(t1)	# t2 = snake_x[i-1]
		sb t2, snake_x(t0)	# snake_x[i] = snake_x[i-1]
		
		# snake_x[i] = snake_x[i - 1];
		move t1, t0		# t1 = i
		sub t1, t1, 1		# t1 = i - 1
		lb t2, snake_y(t1)	# t2 = snake_y[i-1]
		sb t2, snake_y(t0)	# snake_y[i] = snake_y[i-1]
		
		sub t0, t0, 1 # i = i - 1
		j _loop
	# }
	_break:
	
leave

# ------------------------------------------------------------------------------------------------

move_apple:
enter s0, s1

	_loop:
		# [0, GRID_WIDTH - 1]
		li a0, 0
		li a1, GRID_WIDTH
		li v0, 42
		syscall
		
		# s0 = X
		move s0, v0
		
		# [0, GRID-HEIGHT - 1]
		li a0, 0
		li a1, GRID_HEIGHT
		li v0, 42
		syscall
		
		# s1 = Y
		move s1, v0
		
		# a0 = X, a1 = Y
		move a0, s0
		move a1, s1
		
		# is_point_on_snake()
		jal is_point_on_snake
		
		# while(v0 == 1) { do }
		beq v0, 1, _loop
	#}
		
	# X = apple_x
	sw s0, apple_x
	
	# Y = apple_y
	sw s1, apple_y
		
leave s0, s1

# ------------------------------------------------------------------------------------------------

compute_next_snake_pos:
enter
	# t9 = direction
	lw t9, snake_dir

	# v0 = direction_delta_x[snake_dir]
	lb v0, snake_x
	lb t0, direction_delta_x(t9)
	add v0, v0, t0

	# v1 = direction_delta_y[snake_dir]
	lb v1, snake_y
	lb t0, direction_delta_y(t9)
	add v1, v1, t0
leave

# ------------------------------------------------------------------------------------------------

# takes a coordinate (x, y) in a0, a1.
# returns a boolean (1/0) saying whether that coordinate is part of the snake or not.
is_point_on_snake:
enter
	# for i = 0 to snake_len
	li t9, 0
	_loop:
		lb t0, snake_x(t9)
		bne t0, a0, _differ
		lb t0, snake_y(t9)
		bne t0, a1, _differ

			li v0, 1
			j _return

		_differ:
	add t9, t9, 1
	lw  t0, snake_len
	blt t9, t0, _loop

	li v0, 0

_return:
leave

# ------------------------------------------------------------------------------------------------
# Drawing functions
# ------------------------------------------------------------------------------------------------

draw_all:
enter
	# if we haven't lost...
	lw t0, lost_game
	bne t0, 0, _return

		# draw everything.
		jal draw_snake
		jal draw_apple
		jal draw_hud
_return:
leave

# ------------------------------------------------------------------------------------------------

draw_snake:
enter s0, s1, s2
	# i = 0, snake_len = t0
	li s0, 0
	lw s1, snake_len
	
	_loop: # while(s0 < snake_len) { a0 = snake_x[s0] * GRID_CELL_SIZE, a1 = snake_y[s0] * GRID_CELL_SIZE }
		bge s0, s1, _break
	
		lb a0, snake_x(s0)
		mul a0, a0, GRID_CELL_SIZE
		
		lb a1, snake_y(s0)
		mul a1, a1, GRID_CELL_SIZE
		
		
		
		_if: # if(s0 == 0) { tex_snake_head[snake_dir * 4] }
			bne s0, 0, _else
			
			lw s2, snake_dir
			mul s2, s2, 4
			lw a2, tex_snake_head(s2)
			
			j _break2
			
		_else: # else { a2 = tex_snake_segment }
			la a2, tex_snake_segment
			
		#}
		_break2:
		
		# display_blit_5x5_trans()
		jal display_blit_5x5_trans
		
		add s0, s0, 1 #i++
		j _loop
		
	# }
	_break:
	
leave s0, s1, s2

# ------------------------------------------------------------------------------------------------

draw_apple:
enter
	# a0 = apple_x * GRID_CELL_SIZE, a1 = apple_y * GRID_CELL_SIZE, a2 = tex_apple
	lw a0, apple_x 
	mul a0, a0, GRID_CELL_SIZE
	
	lw a1, apple_y
	mul a1, a1, GRID_CELL_SIZE
	
	la a2, tex_apple
	
	# display_blit_5x5_trans()
	jal display_blit_5x5_trans
leave

# ------------------------------------------------------------------------------------------------

draw_hud:
enter
	# draw a horizontal line above the HUD showing the lower boundary of the playfield
	li  a0, 0
	li  a1, GRID_HEIGHT
	mul a1, a1, GRID_CELL_SIZE
	li  a2, DISPLAY_W
	li  a3, COLOR_WHITE
	jal display_draw_hline

	# draw apples collected out of remaining
	li a0, 1
	li a1, 58
	lw a2, apples_eaten
	jal display_draw_int

	li a0, 13
	li a1, 58
	li a2, '/'
	jal display_draw_char

	li a0, 19
	li a2, 58
	li a2, APPLES_NEEDED
	jal display_draw_int
leave
