
.data

tex_snake_segment: .byte
	12 12 12 12 -1
	12 12 12 12 -1
	12 12 12 12 -1
	12 12 12 12 -1
	-1 -1 -1 -1 -1

tex_snake_head: .word
	tex_snake_head_n
	tex_snake_head_e
	tex_snake_head_s
	tex_snake_head_w

tex_snake_head_n: .byte
	 3 12 12  3 -1
	12 12 12 12 -1
	12 12 12 12 -1
	12 12 12 12 -1
	-1 -1 -1 -1 -1

tex_snake_head_e: .byte
	12 12 12  3 -1
	12 12 12 12 -1
	12 12 12 12 -1
	12 12 12  3 -1
	-1 -1 -1 -1 -1

tex_snake_head_s: .byte
	12 12 12 12 -1
	12 12 12 12 -1
	12 12 12 12 -1
	 3 12 12  3 -1
	-1 -1 -1 -1 -1

tex_snake_head_w: .byte
	 3 12 12 12 -1
	12 12 12 12 -1
	12 12 12 12 -1
	 3 12 12 12 -1
	-1 -1 -1 -1 -1

tex_apple: .byte
	-1  1  1 -1 -1
	 1  1  1  1 -1
	 1  1  1  1 -1
	-1  1  1 -1 -1
	-1 -1 -1 -1 -1