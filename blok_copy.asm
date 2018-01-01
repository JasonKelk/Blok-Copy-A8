;
; BLOK COPY :: ATARI 8-BIT EDITION
;

; Code and graphics by Jason Kelk
; PETSCII graphics by Doug Roberts and Jason Kelk
; Music by Andy Vaisey and Sean Connolly


; This source is formatted for the Xasm cross assembler from
; https://github.com/pfusik/xasm
; Compression is handled with Exomizer which can be downloaded at
; http://csdb.dk/release/?id=141402

; build.bat will call both to create an assembled file and then the
; crunched release version.


; MEMORY MAP
; $3400 - $5eff		music
; $5f00 - $5fff		display lists
; $6000 - $73ff		code
; $7400 - $77ff		screen RAM
; $7800 - $7fff		sprites
; $8000 - $83ff		titles characters
; $8400 - $87ff		titles logo characters
; $8800 - $8bff		in-game characters - block 1
; $8c00 - $8fff		in-game characters - block 2


; A8 register declarations
		icl "includes/registers.asm"

; Constants: game shuffle values
shuffle_init	equ $03
shuffle_num	equ $0a		; $01 will give one level, $0a for ten

; Constants: colours for the main playfield
ingame_col_1	equ $78
ingame_col_2	equ $38

; General purpose labels
sync		equ $0640
rnd_seed	equ $0641
rnd_seed_2	equ $0642

rt_store_1	equ $0643
rt_store_2	equ $0644
rt_store_3	equ $0645
rt_store_4	equ $0646

; Titles screen labels
ttl_scrl_cnt	equ $0647
ttl_scrl_nudge	equ $0648
ttl_scrl_col_1	equ $0649
ttl_scrl_col_2	equ $064a
ttl_col_cnt	equ $064b
ttl_pulse_cnt	equ $064c
ttl_pulse_tmr	equ $064d

; In-game labels
diff_level	equ $064e
game_over_flag	equ $064f

cursor_x	equ $0650
cursor_y	equ $0651
joy_reg		equ $0652
joy_delay	equ $0653

; Player status labels
score		equ $0654		; $05 bytes used
highscore	equ $0659		; $05 bytes used
time		equ $065e		; $04 bytes used
level		equ $0662		; $02 bytes used

; End screen labels
gd_wipe_cnt	equ $0667

; End screen effect buffer
gd_buffer	equ $0668		; $28 bytes used

; Where to find the sprite and screen RAM in memory
spr_buffer	equ $9000
screen_ram 	equ $9800


; Load the binary data
		org $3400
		opt h-
music		ins "data/sporting.xex"
		opt h+

		org $8000
ttl_chars	ins "data/titles.chr"

		org $8800
ingame_chars	ins "data/ingame.chr"


; Display list - screen hidden
		org $5f00
dlist_scrn_off	dta $70,$70,$30+$80

		dta $41,<dlist_scrn_on,>dlist_scrn_on

; Display list - screen visible
dlist_scrn_on	dta $70,$70,$30+$80

		dta $44,<screen_ram,>screen_ram
		dta $04,$04,$04,$04,$04,$04,$04,$04
		dta $04,$04,$04,$04,$04,$04,$04,$04
		dta $04,$04,$04,$04,$04,$04,$04,$04

		dta $41,<dlist_scrn_on,>dlist_scrn_on


; Code entry point at $6000
		run $6000
		org $6000

; Copy the playfield graphics to second in-game font
		ldx #$00
font_copy	lda ingame_chars+$1a0,x
		sta ingame_chars+$5a0,x
		lda ingame_chars+$200,x
		sta ingame_chars+$600,x
		lda ingame_chars+$300,x
		sta ingame_chars+$700,x
		inx
		bne font_copy

; Set up the music driver
		lda #$00
		ldx #$00
		ldy #$40
		jsr music+$00

; Set up vertical blank interrupt
		sei
		lda #$06
		ldx #>vblank
		ldy #<vblank
		jsr $e45c

; Initialise the titles Display List and DLI
		jsr dlist_off
		cli

; Reset the label space
		ldx #$00
		txa
nuke_labels	sta $0600,x
		inx
		bne nuke_labels

; Set a couple of labels to specific values
		lda #$01
		sta game_over_flag
		sta highscore+$01

; Clear the screen RAM
		ldx #$00
		txa
clear_screen	sta screen_ram+$000,x
		sta screen_ram+$100,x
		sta screen_ram+$200,x
		sta screen_ram+$2e8,x
		inx
		bne clear_screen

; Set up the hardware sprites and a few other registers
		lda #>spr_buffer
		sta pm_base

		lda #$3e
		sta dma_ctrl_s

		lda #$03
		sta gra_ctrl
		lda #$21
		sta priority_s

		jsr spr_clear


; Entry point for the titles

; Initialise the titles Display List and DLI
ttl_init

;jsr sync_wait
		jsr dlist_off

		lda #<ttl_dli
		sta dli_vector+$00
		lda #>ttl_dli
		sta dli_vector+$01
		lda #$c0
		sta nmi_en

; Draw in the title page
		ldx #$00
ttl_text_draw	ldy ttl_screen+$000,x
		lda char_decode,y
		sta screen_ram+$000,x

		ldy ttl_screen+$028,x
		lda char_decode,y
		sta screen_ram+$190,x

		ldy ttl_screen+$050,x
		lda char_decode,y
		sta screen_ram+$1b8,x

		ldy ttl_screen+$078,x
		lda char_decode,y
		sta screen_ram+$1e0,x

		ldy ttl_screen+$0a0,x
		lda char_decode,y
		sta screen_ram+$208,x


		ldy ttl_screen+$0c8,x
		lda char_decode,y
		sta screen_ram+$258,x

		ldy ttl_screen+$0f0,x
		lda char_decode,y
		sta screen_ram+$280,x

		ldy ttl_screen+$118,x
		lda char_decode,y
		sta screen_ram+$2a8,x

		ldy ttl_screen+$168,x
		lda char_decode,y
		sta screen_ram+$2f8,x

		ldy ttl_screen+$190,x
		lda char_decode,y
		sta screen_ram+$320,x

		ldy ttl_screen+$1b8,x
		lda char_decode,y
		sta screen_ram+$3c0,x
		inx
		cpx #$28
		beq *+$05
		jmp ttl_text_draw

; Draw in the title logo
		ldx #$00
ttl_logo_init	lda ttl_logo_l1,x
		sta screen_ram+$054,x

		lda ttl_logo_l2,x
		sta screen_ram+$07c,x

		lda ttl_logo_l3,x
		sta screen_ram+$0a4,x

		lda ttl_logo_l4,x
		sta screen_ram+$0cc,x

		lda ttl_logo_l5,x
		sta screen_ram+$0f4,x

		lda ttl_logo_l6,x
		sta screen_ram+$11c,x

		lda ttl_logo_l7,x
		sta screen_ram+$144,x
		inx
		cpx #$20
		bne ttl_logo_init

; Draw in the Cosine "logo"
		ldx #$00
		ldy #$52
		clc
ttl_cos_draw	tya
		ora #$80
		sta screen_ram+$1b4,x
		adc #$04
		sta screen_ram+$1dc,x
		adc #$04
		sta screen_ram+$204,x
		adc #$04
		sta screen_ram+$22c,x
		iny
		inx
		cpx #$04
		bne ttl_cos_draw

; Draw in the joystick image
		ldx #$00
		ldy #$62
		clc
ttl_joy_draw	tya
		ora #$80
		sta screen_ram+$258,x
		adc #$05
		sta screen_ram+$280,x
		adc #$05
		sta screen_ram+$2a8,x
		adc #$05
		sta screen_ram+$2d0,x
		adc #$05
		sta screen_ram+$2f8,x
		adc #$05
		sta screen_ram+$320,x
		iny
		inx
		cpx #$05
		bne ttl_joy_draw

; Set the last and high scores up in the scroller, then reset the scroll
		ldx #$00
ttl_score_mv	lda score,x
		ora #$10
		sta ttl_last_score,x
		lda highscore,x
		ora #$10
		sta ttl_high_score,x
		inx
		cpx #$05
		bne ttl_score_mv

		jsr ttl_reset
		lda #$00
		sta ttl_scrl_cnt

; Set up titles-specific video registers
		lda #>ttl_chars
		sta char_base_s

		lda #$00
		sta col_bgnd_s
		lda #$04
		sta col_pfield0_s
		lda #$0c
		sta col_pfield1_s
		lda #$08
		sta col_pfield2_s
		lda #$b8
		sta col_pfield2_s

; Set some labels
		lda #$01
		sta game_over_flag
		lda #$00
		sta ttl_col_cnt
		sta ttl_pulse_cnt
		sta ttl_pulse_tmr
		lda #$18
		sta ttl_scrl_col_1
		sta ttl_scrl_col_2

; Wait for a second before turning on the screen
		ldy #$32
		jsr sync_wait_long
		jsr dlist_on

; Main title loop
ttl_loop	jsr sync_wait
		sty rt_store_1
		jsr ttl_move_scrl
		ldy rt_store_1

		jsr random

		jsr sync_wait
		jsr ttl_move_scrl

		jsr random

; Check the fire button
		lda $d010
		lsr @
		bcc ttl_exit
		jmp ttl_loop

; Clear the screen and get the game ready to go
ttl_exit	jsr wipe_screen
		jmp main_first_init

; Scroller management subs
ttl_move_scrl	lda ttl_scrl_cnt
		cmp #$28
		bcs ttl_no_scrl

		ldx #$00
ttl_ms_loop	lda screen_ram+$0371,x
		sta screen_ram+$0370,x
		inx
		cpx #$27
		bne ttl_ms_loop

		lda #$20
		ldy ttl_scrl_cnt
		cpy #$01
		bcc ttl_okay_2
		cpy #$27
		bcs ttl_okay_2

ttl_mread	lda ttl_scroll
		cmp #$ff
		bne ttl_okay
		jsr ttl_reset
		jmp ttl_mread

ttl_okay	inc ttl_mread+$01
		bne *+$05
		inc ttl_mread+$02

ttl_okay_2	tay
		lda char_decode,y
		ora ttl_scrl_nudge
		sta screen_ram+$0397

ttl_no_scrl	inc ttl_scrl_cnt

		ldx ttl_scrl_cnt
		cpx #$2c
		bne ttl_no_colchng

		ldx ttl_col_cnt
		inx
		cpx #$0d
		bne *+$04
		ldx #$00
		stx ttl_col_cnt
		inx
		txa
		asl @
		asl @
		asl @
		asl @
		ora #$08

		ldy #$00
		ldx ttl_scrl_nudge
		cpx #$80
		bcs *+$03
		iny
		sta ttl_scrl_col_1,y

		lda ttl_scrl_nudge
		eor #$80
		sta ttl_scrl_nudge

ttl_no_colchng	rts

; Self mod reset for the title page scroller
ttl_reset	lda #<ttl_scroll
		sta ttl_mread+$01
		lda #>ttl_scroll
		sta ttl_mread+$02
		rts


; Initial entry point for main game

; Set how many shuffles for the first level
main_first_init	lda #shuffle_init
		sta diff_level

; Set up game-specific video register set-ups
		lda #>ingame_chars
		sta char_base_s
		lda #$04
		sta col_pfield0_s
		lda #$0c
		sta col_pfield1_s
		lda #$08
		sta col_pfield2_s
		lda #$d8
		sta col_pfield3_s

; Reset the status bar
		ldx #$00
		txa
clear_score	sta score,x
		inx
		cpx #$05
		bne clear_score

		lda #$00
		sta level+$00
		lda #$01
		sta level+$01

		jsr screen_init

; Entry point for main game
main_init

; Reset the playfield
		ldx #$00
rp_loop		txa
		and #$07
		sta play_area,x
		inx
		cpx #$28
		bne rp_loop

; Initialise the titles Display List and DLI
		lda #<dli
		sta dli_vector+$00
		lda #>dli
		sta dli_vector+$01
		lda #$c0
		sta nmi_en

; Set up the hardware sprites for the sides
		ldx #$00
		ldy #$00
spr_data_draw	lda sprite_data_1,y
		sta spr_buffer+$42c,x
		sta spr_buffer+$62c,x
		lda sprite_data_2,y
		sta spr_buffer+$52c,x
		sta spr_buffer+$72c,x
		iny
		cpy #$20
		bne *+$04
		ldy #$00
		inx
		cpx #$a8
		bne spr_data_draw

; Turn the screen on and position the hardware sprites
		lda #$04
		sta pm0_colour_s
		sta pm2_colour_s

		lda #$08
		sta pm1_colour_s
		sta pm3_colour_s

		jsr sync_wait
		jsr dlist_on

		jsr sync_wait

		lda #$30
		sta pm0_xpos
		sta pm1_xpos

		lda #$ac
		sta pm2_xpos
		sta pm3_xpos

; Pause for a second
		ldy #$32
ss_loop		jsr sync_wait
		jsr house_keep
		dey
		bne ss_loop

; Set the cursor X and Y positions
		lda #$03
		sta cursor_x
		lda #$02
		sta cursor_y

; Scramble the play area depending on difficulty level
		ldx #$00
		stx rt_store_2
scramble	stx rt_store_3
		jsr sync_wait

		jsr random

		lda rnd_seed
		and #$0f
		tax
		ldy cursor_x
scram_x_move	iny
		cpy #$07
		bne *+$04
		ldy #$00
		dex
		bne scram_x_move
		sty cursor_x

		jsr random
		lda rnd_seed
		and #$0f
		tax
		ldy cursor_y
scram_y_move	iny
		cpy #$05
		bne *+$04
		ldy #$00
		dex
		bne scram_y_move
		sty cursor_y

		lda rt_store_2
		and #$03
		tax
		lda scram_joy,x
		sta joy_reg
		jsr joy_fire_up
		inc rt_store_2

; Pause after each move
		ldy #$20
		jsr sync_wait_long

		ldx rt_store_3
		inx
		cpx diff_level
		bne scramble

; Set the level timer
		lda #$01
		sta time+$00
		lda #$05
		sta time+$01
		lda #$00
		sta time+$02
		lda #$32
		sta time+$03

		jsr sync_wait
		jsr house_keep

; Reset the player cursor
		lda #$00
		sta cursor_x
		sta cursor_y

; Display the Get Ready message
		lda level+$00
		ora #$10
		sta levnum_text+$07
		lda level+$01
		ora #$10
		sta levnum_text+$08

; Type out the Get Ready message
		ldx #$00
		ldy #$08
gr_message	stx rt_store_2
		sty rt_store_3

		ldy #$04
		jsr sync_wait_long

		ldx rt_store_2
		ldy getrdy_text,x
		lda char_decode,y
		sta screen_ram+$19c,x

		ldx rt_store_3
		ldy levnum_text,x
		lda char_decode,y
		sta screen_ram+$23c,x

		ldx rt_store_2
		ldy rt_store_3
		dey
		inx
		cpx #$09
		bne gr_message

; Pause for a second
		ldy #$32
		jsr sync_wait_long

		ldx #$00
		ldy #$08
gr_clear	stx rt_store_2
		sty rt_store_3

; Clear the Get Ready message
		ldy #$04
		jsr sync_wait_long

		ldx rt_store_2
		ldy rt_store_3

		lda #$00
		sta screen_ram+$19c,x
		sta screen_ram+$23c,y
		dey
		inx
		cpx #$09
		bne gr_clear

; Set some final labels
		lda #$00
		sta game_over_flag
		jsr sync_wait
		jsr house_keep

		jsr cursor_draw

; Main game loop
main_loop	jsr sync_wait
		jsr house_keep

		jsr cursor_clear
		jsr joy_scan
		jsr cursor_draw

; Check to see if the level is done and react accordingly
		ldx #$00
scan_loop	txa
		and #$07
		cmp play_area,x
		bne scan_out
		inx
		cpx #$28
		bne scan_loop

		jmp level_done

; Check to see if the game over flag is set
scan_out	lda game_over_flag
		bne game_over

		jmp main_loop

; Game Over sequence
game_over	jsr cursor_clear

; Type out the Game Over message
		ldx #$00
		ldy #$08
go_message	stx rt_store_2
		sty rt_store_3

		ldy #$04
		jsr sync_wait_long

		ldx rt_store_2
		ldy gamovr_text,x
		lda char_decode,y
		sta screen_ram+$19c,x

		ldx rt_store_3
		ldy levnum_text,x
		lda char_decode,y
		sta screen_ram+$23c,x

		ldx rt_store_2
		ldy rt_store_3
		dey
		inx
		cpx #$09
		bne go_message

; Pause for a second
		ldy #$96
		jsr sync_wait_long

; Clear the screen and jump to the titles page
		jsr wipe_screen

		jmp ttl_init

; Level Complete sequence - no text, just adds a time bonus
level_done	jsr cursor_clear

; Wait for half a second
		ldy #$19
		jsr sync_wait_long

; Add the remaining time as a score bonus
ld_bonus_loop	jsr sync_wait
		jsr house_keep

		jsr score_bump_10

		ldx #$02
ld_bonus_count	lda time,x
		sec
		sbc #$01
		sta time,x
		cmp #$ff
		bne ld_bonus_out
		lda #$09
		sta time,x
		dex
		cpx #$ff
		bne ld_bonus_count

ld_bonus_out	ldx #$00
		lda time,x
		bne ld_bonus_loop
		inx
		cpx #$02
		bne ld_bonus_out+$02

; Zero the time counter
		lda #$00
		sta time+$00
		sta time+$01
		sta time+$02
		lda #$fc
		sta time+$03

; Bump the level counter and, if that wasn't the last stage, move on
ld_bonus_done	jsr sync_wait
		jsr house_keep

		inc diff_level

		lda diff_level
		cmp #shuffle_init+shuffle_num
		beq game_done

		ldx level+$01
		inx
		cpx #$0a
		bne lc_bump_xb
		ldx #$00
		inc level+$00
lc_bump_xb	stx level+$01

		jmp main_init


; Game completion sequence
game_done	ldx #$02
		ldy #$1e

; Wipe the playfield area
gd_clear	jsr sync_wait

		lda #$00
		sta screen_ram+$078,x
		sta screen_ram+$0a0,y
		sta screen_ram+$0c8,x
		sta screen_ram+$0f0,y
		sta screen_ram+$118,x

		sta screen_ram+$140,y
		sta screen_ram+$168,x
		sta screen_ram+$190,y
		sta screen_ram+$1b8,x
		sta screen_ram+$1e0,y

		sta screen_ram+$208,x
		sta screen_ram+$230,y
		sta screen_ram+$258,x
		sta screen_ram+$280,y
		sta screen_ram+$2a8,x

		sta screen_ram+$2d0,y
		sta screen_ram+$2f8,x
		sta screen_ram+$320,y
		sta screen_ram+$348,x

		dey
		inx
		cpx #$1f
		bne gd_clear

; Pause for a second
		ldy #$32
		jsr sync_wait_long

; Completion effect
		lda #$00
		jsr gd_buffer_clr

; Display the completion message
		ldx #$00
gd_message	ldy gd_text,x
		lda char_decode,y
		sta screen_ram+$1e2,x
		inx
		cpx #$1d
		bne gd_message

		lda #$1c
		sta rt_store_1
		lda #$00
		sta gd_wipe_cnt

; Completion effect loop
gd_loop		jsr sync_wait
		jsr sync_wait

; Update the logo
		ldx #$00
gd_logo_1	lda gd_buffer+$06,x
		ldy gd_logo+$00,x
		beq *+$05
		sta screen_ram+$0cf,x
		ldy gd_logo+$28,x
		beq *+$05
		sta screen_ram+$0f7,x
		eor #$80
		ldy gd_logo+$50,x
		beq *+$05
		sta screen_ram+$11f,x
		eor #$80
		ldy gd_logo+$78,x
		beq *+$05
		sta screen_ram+$147,x
		eor #$80
		ldy gd_logo+$a0,x
		beq *+$05
		sta screen_ram+$16f,x
		ldy gd_logo+$c8,x
		beq *+$05
		sta screen_ram+$197,x
		inx
		cpx #$13
		bne gd_logo_1

		ldx #$00
gd_logo_2	lda gd_buffer,x
		ldy gd_logo+$14,x
		beq *+$05
		sta screen_ram+$237,x
		ldy gd_logo+$3c,x
		beq *+$05
		sta screen_ram+$25f,x
		eor #$80
		ldy gd_logo+$64,x
		beq *+$05
		sta screen_ram+$287,x
		eor #$80
		ldy gd_logo+$8c,x
		beq *+$05
		sta screen_ram+$2af,x
		eor #$80
		ldy gd_logo+$b4,x
		beq *+$05
		sta screen_ram+$2d7,x
		ldy gd_logo+$dc,x
		beq *+$05
		sta screen_ram+$2ff,x
		inx
		cpx #$13
		bne gd_logo_2

		jsr gd_buffer_move

; Check for the fire button and exit
		lda $d030
		and #$01
		bne gd_no_fire
		jmp gd_out

gd_no_fire	jmp gd_loop

; Clear the screen and head back to the titles page
gd_out		jsr wipe_screen
		jmp ttl_init


; Draw the top and bottom two lines
screen_init	ldx #$00
sss_loop_1	lda scr_top_edge+$000,x
		sta screen_ram+$000,x
		sta screen_ram+$398,x
		inx
		cpx #$50
		bne sss_loop_1

; Draw the seperators between tile rows
		ldx #$00
sss_loop_2	lda scr_sep,x
		sta screen_ram+$050,x
		sta screen_ram+$0f0,x
		sta screen_ram+$190,x
		sta screen_ram+$230,x
		sta screen_ram+$2d0,x
		sta screen_ram+$370,x
		inx
		cpx #$28
		bne sss_loop_2

; Draw the tile rows
		ldx #$00
sss_loop_3	lda scr_tiles,x
		sta screen_ram+$078,x
		sta screen_ram+$118,x
		sta screen_ram+$1b8,x
		sta screen_ram+$258,x
		sta screen_ram+$2f8,x
		inx
		cpx #$78
		bne sss_loop_3

; Set the score bar and colour
		ldx #$00
sss_loop_4	ldy scr_score_text,x
		lda char_decode,y
		sta screen_ram+$09a,x

		ldy scr_high_text,x
		lda char_decode,y
		sta screen_ram+$112,x

		ldy scr_timer_text,x
		lda char_decode,y
		sta screen_ram+$18a,x
		inx
		cpx #$05
		bne sss_loop_4

; Set the Blok Copy logo up
		ldx #$00
sss_loop_5	lda scr_logo_1,x
		sta screen_ram+$279,x
		lda scr_logo_2,x
		sta screen_ram+$2a1,x
		lda scr_logo_3,x
		sta screen_ram+$2c9,x
		lda scr_logo_4,x
		sta screen_ram+$2f1,x
		lda scr_logo_5,x
		sta screen_ram+$319,x
		lda scr_logo_6,x
		sta screen_ram+$341,x
		lda scr_logo_7,x
		sta screen_ram+$369,x

		inx
		cpx #$07
		bne sss_loop_5

		rts

; Read and interpret the joystick values
joy_scan	lda $d300
		sta joy_reg

; Check to see if the fire button is down
		lda $d010
		lsr @
		bcs *+$05
		jmp joy_fire_up

; Decrease the joystick delay
		ldx joy_delay
		dex
		stx joy_delay
		cpx #$ff
		beq joy_go
		rts

; Joystick controls
joy_go		inc joy_delay

; Joystick up - without fire button
joy_up		lsr joy_reg
		bcs joy_down

		ldx cursor_y
		dex
		cpx #$ff
		bne *+$04
		ldx #$04
		stx cursor_y

		jsr cursor_draw

		ldy #$06
		sty joy_delay

; Joystick down - without fire button
joy_down	lsr joy_reg
		bcs joy_left

		ldx cursor_y
		inx
		cpx #$05
		bne *+$04
		ldx #$00
		stx cursor_y

		jsr cursor_draw

		ldy #$06
		sty joy_delay

; Joystick left - without fire button
joy_left	lsr joy_reg
		bcs joy_right

		ldx cursor_x
		dex
		cpx #$ff
		bne *+$04
		ldx #$06
		stx cursor_x

		jsr cursor_draw

		ldy #$06
		sty joy_delay

; Joystick right - without fire button
joy_right	lsr joy_reg
		bcs joy_out

		ldx cursor_x
		inx
		cpx #$07
		bne *+$04
		ldx #$00
		stx cursor_x

		jsr cursor_draw

		ldy #$06
		sty joy_delay

joy_out		rts

; Joystick up - with fire button
joy_fire_up	lsr joy_reg
		bcs joy_fire_down

		jsr move_up
		ldy #$10
		sty joy_delay

; Joystick down - with fire button
joy_fire_down	lsr joy_reg
		bcs joy_fire_left

		jsr move_down
		ldy #$10
		sty joy_delay

; Joystick left - with fire button
joy_fire_left	lsr joy_reg
		bcs joy_fire_right

		jsr move_left
		ldy #$10
		sty joy_delay

; Joystick right - with fire button
joy_fire_right	lsr joy_reg
		bcs joy_fire_out

		jsr move_right
		ldy #$10
		sty joy_delay

joy_fire_out	rts

; Display the player's cursors
cursor_draw	lda cursor_x
		asl @
		asl @
		asl @
		asl @
		clc
		adc #$3c
		sta pm4_xpos
		sta pm5_xpos
		clc
		adc #$04
		sta pm6_xpos
		sta pm7_xpos

		lda cursor_y
		asl @
		asl @
		asl @
		asl @
		asl @
		tay
		ldx #$00
cd_loop		lda cursor_data,x
		sta spr_buffer+$32c,y
		sta spr_buffer+$34c,y
		iny
		inx
		cpx #$08
		bne cd_loop

		lda #$ff
		sta pmm_expand

		rts

; Clear the player's cursors
cursor_clear	lda cursor_y
		asl @
		asl @
		asl @
		asl @
		asl @
		tay
		ldx #$00
		txa
cc_loop		sta spr_buffer+$32c,y
		sta spr_buffer+$34c,y
		iny
		inx
		cpx #$08
		bne cc_loop

		rts

; Playfield shuffle - current column upwards
move_up		ldx #$00
mu_loop		stx rt_store_1

		jsr sync_wait
		jsr house_keep

		jsr shunt_up
		ldx rt_store_1
		inx
		cpx #$04
		bne mu_loop

		ldx cursor_x
		ldy play_area+$00,x
		lda play_area+$08,x
		sta play_area+$00,x
		lda play_area+$10,x
		sta play_area+$08,x
		lda play_area+$18,x
		sta play_area+$10,x
		lda play_area+$20,x
		sta play_area+$18,x
		tya
		sta play_area+$20,x

		rts

; Playfield shuffle - current column downwards
move_down	ldx #$00
md_loop		stx rt_store_1

		jsr sync_wait
		jsr house_keep

		jsr shunt_down
		ldx rt_store_1
		inx
		cpx #$04
		bne md_loop

		ldx cursor_x
		ldy play_area+$20,x
		lda play_area+$18,x
		sta play_area+$20,x
		lda play_area+$10,x
		sta play_area+$18,x
		lda play_area+$08,x
		sta play_area+$10,x
		lda play_area+$00,x
		sta play_area+$08,x
		tya
		sta play_area+$00,x

		rts

; Playfield shuffle - current row left
move_left	ldx #$00
ml_loop		stx rt_store_1

		jsr sync_wait
		jsr house_keep

		jsr shunt_left
		ldx rt_store_1
		inx
		cpx #$04
		bne ml_loop

		lda cursor_y
		asl @
		asl @
		asl @
		tay
		lda play_area,y
		pha
		sty rt_store_2
		ldx #$00
pa_left_loop	lda play_area+$01,y
		sta play_area+$00,y
		iny
		inx
		cpx #$06
		bne pa_left_loop
		pla
		ldy rt_store_2
		sta play_area+$06,y

		rts

; Playfield shuffle - current row right
move_right	ldx #$00
mr_loop		stx rt_store_1

		jsr sync_wait
		jsr house_keep

		jsr shunt_right
		ldx rt_store_1
		inx
		cpx #$04
		bne mr_loop

		lda cursor_y
		asl @
		asl @
		asl @
		tay
		lda play_area+$06,y
		pha
		sty rt_store_2
		tya
		clc
		adc #$05
		tay
		ldx #$05
pa_right_loop	lda play_area+$00,y
		sta play_area+$01,y
		dey
		dex
		cpx #$ff
		bne pa_right_loop
		pla
		ldy rt_store_2
		sta play_area,y

		rts

; Screen RAM update - move column of tiles upwards
shunt_up	ldx cursor_x
		ldy cur_x_off,x

; Screen RAM shunt
		ldx #$00
shup_loop	lda screen_ram+$078,y
		sta screen_ram+$050,y
		lda screen_ram+$0a0,y
		sta screen_ram+$078,y
		lda screen_ram+$0c8,y
		sta screen_ram+$0a0,y
		lda screen_ram+$0f0,y
		sta screen_ram+$0c8,y
		lda screen_ram+$118,y
		sta screen_ram+$0f0,y

		lda screen_ram+$140,y
		sta screen_ram+$118,y
		lda screen_ram+$168,y
		sta screen_ram+$140,y
		lda screen_ram+$190,y
		sta screen_ram+$168,y
		lda screen_ram+$1b8,y
		sta screen_ram+$190,y
		lda screen_ram+$1e0,y
		sta screen_ram+$1b8,y

		lda screen_ram+$208,y
		sta screen_ram+$1e0,y
		lda screen_ram+$230,y
		sta screen_ram+$208,y
		lda screen_ram+$258,y
		sta screen_ram+$230,y
		lda screen_ram+$280,y
		sta screen_ram+$258,y
		lda screen_ram+$2a8,y
		sta screen_ram+$280,y

		lda screen_ram+$2d0,y
		sta screen_ram+$2a8,y
		lda screen_ram+$2f8,y
		sta screen_ram+$2d0,y
		lda screen_ram+$320,y
		sta screen_ram+$2f8,y
		lda screen_ram+$348,y
		sta screen_ram+$320,y
		lda screen_ram+$370,y
		sta screen_ram+$348,y

		lda screen_ram+$050,y
		sta screen_ram+$370,y

		iny
		inx
		cpx #$03
		beq *+$05
		jmp shup_loop

		rts

; Screen RAM update - move column of tiles downwards
shunt_down	ldx cursor_x
		ldy cur_x_off,x

; Screen RAM shunt
		ldx #$00
shdown_loop	lda screen_ram+$348,y
		sta screen_ram+$370,y
		lda screen_ram+$320,y
		sta screen_ram+$348,y
		lda screen_ram+$2f8,y
		sta screen_ram+$320,y
		lda screen_ram+$2d0,y
		sta screen_ram+$2f8,y
		lda screen_ram+$2a8,y
		sta screen_ram+$2d0,y

		lda screen_ram+$280,y
		sta screen_ram+$2a8,y
		lda screen_ram+$258,y
		sta screen_ram+$280,y
		lda screen_ram+$230,y
		sta screen_ram+$258,y
		lda screen_ram+$208,y
		sta screen_ram+$230,y
		lda screen_ram+$1e0,y
		sta screen_ram+$208,y

		lda screen_ram+$1b8,y
		sta screen_ram+$1e0,y
		lda screen_ram+$190,y
		sta screen_ram+$1b8,y
		lda screen_ram+$168,y
		sta screen_ram+$190,y
		lda screen_ram+$140,y
		sta screen_ram+$168,y
		lda screen_ram+$118,y
		sta screen_ram+$140,y

		lda screen_ram+$0f0,y
		sta screen_ram+$118,y
		lda screen_ram+$0c8,y
		sta screen_ram+$0f0,y
		lda screen_ram+$0a0,y
		sta screen_ram+$0c8,y
		lda screen_ram+$078,y
		sta screen_ram+$0a0,y
		lda screen_ram+$050,y
		sta screen_ram+$078,y

		lda screen_ram+$370,y
		sta screen_ram+$050,y

		iny
		inx
		cpx #$03
		beq *+$05
		jmp shdown_loop

		rts

; Screen RAM update - move row of tiles left
shunt_left	lda cursor_y
		asl @
		clc
		adc cursor_y
		tax

		lda cur_y_off_low+$00,x
		sta sl_loop+$01
		sta sl_loop+$04
		sta sl_write+$01
		sta sl_write+$04

		lda cur_y_off_high+$00,x
		sta sl_loop+$02
		sta sl_loop+$05
		sta sl_write+$02
		sta sl_write+$05

		lda cur_y_off_low+$01,x
		sta sl_loop+$07
		sta sl_loop+$0a
		sta sl_write+$07
		sta sl_write+$0a

		lda cur_y_off_high+$01,x
		sta sl_loop+$08
		sta sl_loop+$0b
		sta sl_write+$08
		sta sl_write+$0b

		lda cur_y_off_low+$02,x
		sta sl_loop+$0d
		sta sl_loop+$10
		sta sl_write+$0d
		sta sl_write+$10

		lda cur_y_off_high+$02,x
		sta sl_loop+$0e
		sta sl_loop+$11
		sta sl_write+$0e
		sta sl_write+$11

; Screen RAM copy
		ldx #$02
		ldy #$03
sl_loop		lda screen_ram+$78,y
		sta screen_ram+$78,x
		lda screen_ram+$a0,y
		sta screen_ram+$a0,x
		lda screen_ram+$c8,y
		sta screen_ram+$c8,x

		iny
		inx
		cpx #$1f
		bne sl_loop

; Copy the left edge over to the right
		ldx #$02
		ldy #$1e
sl_write	lda screen_ram+$78,x
		sta screen_ram+$78,y
		lda screen_ram+$a0,x
		sta screen_ram+$a0,y
		lda screen_ram+$c8,x
		sta screen_ram+$c8,y

		rts

; Screen RAM update - move row of tiles right
shunt_right	lda cursor_y
		asl @
		clc
		adc cursor_y
		tax

		lda cur_y_off_low+$00,x
		sta sr_loop+$01
		sta sr_loop+$04
		sta sr_write+$01
		sta sr_write+$04

		lda cur_y_off_high+$00,x
		sta sr_loop+$02
		sta sr_loop+$05
		sta sr_write+$02
		sta sr_write+$05

		lda cur_y_off_low+$01,x
		sta sr_loop+$07
		sta sr_loop+$0a
		sta sr_write+$07
		sta sr_write+$0a

		lda cur_y_off_high+$01,x
		sta sr_loop+$08
		sta sr_loop+$0b
		sta sr_write+$08
		sta sr_write+$0b

		lda cur_y_off_low+$02,x
		sta sr_loop+$0d
		sta sr_loop+$10
		sta sr_write+$0d
		sta sr_write+$10

		lda cur_y_off_high+$02,x
		sta sr_loop+$0e
		sta sr_loop+$11
		sta sr_write+$0e
		sta sr_write+$11

; Screen and colour RAM copy
		ldx #$1d
		ldy #$1e
sr_loop		lda screen_ram+$78,x
		sta screen_ram+$78,y
		lda screen_ram+$a0,x
		sta screen_ram+$a0,y
		lda screen_ram+$c8,x
		sta screen_ram+$c8,y

		dey
		dex
		cpx #$01
		bne sr_loop

; Copy the right edge over to the left
		ldx #$1e
		ldy #$02
sr_write	lda screen_ram+$78,x
		sta screen_ram+$78,y
		lda screen_ram+$a0,x
		sta screen_ram+$a0,y
		lda screen_ram+$c8,x
		sta screen_ram+$c8,y

		rts

; Raster synchronisation wait
sync_wait	lda #$00
		sta sync
sw_loop		cmp sync
		beq sw_loop

		rts

; Wait for Y frames
sync_wait_long	jsr sync_wait
		dey
		bne sync_wait_long

		rts

; Decrease the timer
house_keep	jsr down_time
		sty rt_store_4

; Update the on-screen score and high score
		ldx #$00
score_copy	lda score,x
		ora #$10
		tay
		lda char_decode,y
		sta screen_ram+$0c2,x
		lda highscore,x
		ora #$10
		tay
		lda char_decode,y
		sta screen_ram+$13a,x
		inx
		cpx #$05
		bne score_copy

		lda time+$00
		ora #$10
		tay
		lda char_decode,y
		sta screen_ram+$1b3

		lda time+$01
		ora #$10
		tay
		lda char_decode,y
		sta screen_ram+$1b4

		lda time+$02
		ora #$10
		tay
		lda char_decode,y
		sta screen_ram+$1b5

		ldy rt_store_4

		rts

; Time updater
down_time	lda game_over_flag
		beq *+$03
		rts

		ldx time+$03
		dex
		cpx #$ff
		bne t3_xb

		jsr score_bump
		jsr score_bump

		ldx #$02
dt_loop		lda time,x
		sec
		sbc #$01
		sta time,x
		cmp #$ff
		bne dtl_out
		lda #$09
		sta time,x
		dex
		cpx #$ff
		bne dt_loop

dtl_out		ldx #$00

		ldx #$31
t3_xb		stx time+$03

		ldx #$00
dt_scan		lda time,x
		bne dts_out
		inx
		cpx #$04
		bne dt_scan

		lda #$01
		sta game_over_flag

dts_out		rts

; Score handling - add 10 points
score_bump_10	ldx #$03
		jmp bs_loop

; Score handling - add 1 point
score_bump	ldx #$04
bs_loop		lda score,x
		clc
		adc #$01
		sta score,x
		cmp #$0a
		bne bsl_out
		lda #$00
		sta score,x
		dex
		cpx #$ff
		bne bs_loop

; Compare the score and high score
bsl_out		ldx #$00
score_scan	lda score,x
		cmp highscore,x
		bcc xx_cs
		beq no_cs
		bcs copy_score
no_cs		inx
		cpx #$05
		bne score_scan
xx_cs		rts

; The score is greater, so overwrite the high score
copy_score	ldx #$00
cs_loop		lda score,x
		sta highscore,x
		inx
		cpx #$05
		bne cs_loop

		rts

; Pseudo random number generator
random		lda rnd_seed
		clc
		adc #$69
		eor rnd_seed_2
		sta rnd_seed

		tax
		lda rnd_seed_2
		adc $0900,x
		sta rnd_seed_2

		rts

; Clear the hardware sprites
spr_clear	ldx #$00
		txa
sc_loop		sta spr_buffer+$300,x
		sta spr_buffer+$400,x
		sta spr_buffer+$500,x
		sta spr_buffer+$600,x
		sta spr_buffer+$700,x
		inx
		bne sc_loop

		rts

; Wipe the playfield between titles and game
wipe_screen	ldx #$00
		stx pm0_xpos
		stx pm1_xpos
		stx pm2_xpos
		stx pm3_xpos
		stx pm4_xpos
		stx pm5_xpos
		stx pm6_xpos
		stx pm7_xpos

		ldy #$27
ws_loop		jsr sync_wait

		lda #$00
		sta screen_ram+$000,x
		sta screen_ram+$028,y
		sta screen_ram+$050,x
		sta screen_ram+$078,y
		sta screen_ram+$0a0,x

		sta screen_ram+$0c8,y
		sta screen_ram+$0f0,x
		sta screen_ram+$118,y
		sta screen_ram+$140,x
		sta screen_ram+$168,y

		sta screen_ram+$190,x
		sta screen_ram+$1b8,y
		sta screen_ram+$1e0,x
		sta screen_ram+$208,y
		sta screen_ram+$230,x

		sta screen_ram+$258,y
		sta screen_ram+$280,x
		sta screen_ram+$2a8,y
		sta screen_ram+$2d0,x
		sta screen_ram+$2f8,y

		sta screen_ram+$320,x
		sta screen_ram+$348,y
		sta screen_ram+$370,x
		sta screen_ram+$398,y
		sta screen_ram+$3c0,x
		dey
		inx
		cpx #$28
		bne ws_loop

; Turn the screen off
		jsr sync_wait
		jsr dlist_off

; Wait for a couple of seconds
		ldy #$64
		jsr sync_wait_long

; Debounce the fire button
ws_fire_db	jsr sync_wait

		lda $d010
		lsr @
		bcc ws_fire_db

		rts

; Completion screen effect handling
gd_buffer_move	ldx #$26
gd_bm_loop	lda gd_buffer+$00,x
		sta gd_buffer+$01,x
		dex
		cpx #$ff
		bne gd_bm_loop

; Update game completion effect
gd_upd_standard	ldx gd_wipe_cnt
		lda gd_wipe,x
		sta gd_buffer
		inx
		cpx #$0a
		bne *+$04
		ldx #$00
		stx gd_wipe_cnt

		rts

; Clear the completion screen buffer
gd_buffer_clr	ldx #$00
gd_bc_loop	sta gd_buffer,x
		inx
		cpx #$28
		bne gd_bc_loop

		lda #$00
		sta gd_wipe_cnt
		rts

; Set up the hiding display list
dlist_off	lda #<dlist_scrn_off
		sta dlist_vector+$00
		lda #>dlist_scrn_off
		sta dlist_vector+$01

		lda #$00
		sta pm0_xpos
		sta pm1_xpos
		sta pm2_xpos
		sta pm3_xpos
		sta pm4_xpos
		sta pm5_xpos
		sta pm6_xpos
		sta pm7_xpos

		rts

; Set up the visible display list
dlist_on	lda #<dlist_scrn_on
		sta dlist_vector+$00
		lda #>dlist_scrn_on
		sta dlist_vector+$01

		rts


; Vertical blank interrupt
vblank		lda #$00
		sta attract_timer

; Play the music
		jsr music+$03

; Exit the vertical blank interrupt
		jmp $e45f


; Move to the start of the next page boundary
		org [[*/$100]+$01]*$100

; Titles Display List Interrupt
ttl_dli		pha
		txa
		pha
		tya
		pha

; Set up the character set and wait for the first colour split
		lda #>ttl_chars
		sta char_base

		sta wsync

		ldx #$02
		dex
		bne *-$01
		nop

		lda #$b8
		sta col_pfield3

; Split the colours for the Cosine Systems text
		ldx #$00
ttl_txt_splt_1	lda #$38
		sta col_pfield2
		ldy #$06
		dey
		bne *-$01
		lda #$78
		sta col_pfield2
		ldy #$01
		dey
		bne *-$01
		nop
		nop
		inx
		cpx #$06
		bne ttl_txt_splt_1

		lda #$08
		sta col_pfield2

; Wait for the top of the logo
		ldx #$00
ttl_dli_wait_1	sta wsync
		inx
		cpx #$0a
		bne ttl_dli_wait_1

; Change video registers for the logo
		lda #>ttl_chars+$04
		sta char_base
		lda #$14
		sta col_pfield0

; Split a playfield colour for the logo
		ldx #$00
ttl_logo_split	lda ttl_logo_colour,x
		sta wsync
		sta col_pfield3
		inx
		cpx #$38
		bne ttl_logo_split

; Change video registers for the first text area
		lda #>ttl_chars
		sta char_base
		lda #$04
		sta col_pfield0
		lda #$28
		sta col_pfield2
		lda #$08
		sta col_pfield3

		ldx #$00
ttl_dli_wait_2	sta wsync
		inx
		cpx #$07
		bne ttl_dli_wait_2

		lda #$d8
		sta col_pfield2
		lda #$18
		sta col_pfield3

		bit $ea
		nop
		nop

; Split the second text line
		ldx #$00
ttl_txt_splt_02	lda #$04
		sta col_pfield0
		ldy #$08
		dey
		bne *-$01
		lda #$14
		sta col_pfield0
		inx
		cpx #$06
		bne ttl_txt_splt_02

		sta wsync

		lda #$b8
		sta col_pfield2
		lda #$28
		sta col_pfield3

		bit $ea
		bit $ea
		bit $ea
		nop
		nop

; Split the third text line
		ldx #$00
ttl_txt_splt_03	lda #$04
		sta col_pfield0
		ldy #$08
		dey
		bne *-$01
		lda #$14
		sta col_pfield0
		inx
		cpx #$06
		bne ttl_txt_splt_03

		lda #$94
		sta col_pfield0

		sta wsync

		lda #$98
		sta col_pfield2
		lda #$68
		sta col_pfield3

		bit $ea
		bit $ea
		bit $ea
		nop
		nop

; Split the fourth text line
		ldx #$00
ttl_txt_splt_04	lda #$04
		sta col_pfield0
		ldy #$08
		dey
		bne *-$01
		lda #$84
		sta col_pfield0
		inx
		cpx #$06
		bne ttl_txt_splt_04

		sta wsync

		lda #$78
		sta col_pfield2
		lda #$68
		sta col_pfield3

		bit $ea
		bit $ea
		bit $ea
		nop
		nop

; Split the fifth text line
		ldx #$00
ttl_txt_splt_05	lda #$04
		sta col_pfield0
		ldy #$08
		dey
		bne *-$01
		lda #$84
		sta col_pfield0
		inx
		cpx #$06
		bne ttl_txt_splt_05

		sta wsync
		sta wsync
		sta wsync
		sta wsync
		lda #$04
		sta col_pfield0
		sta wsync
		sta wsync
		sta wsync
		sta wsync
		sta wsync

		lda #$58
		sta col_pfield2
		lda #$08
		sta col_pfield3

		ldy #$04
		dey
		bne *-$01
		nop
		nop
		nop

; Split the sixth text line
		ldx #$00
ttl_txt_splt_06	lda #$04
		sta col_pfield0
		bit $ea
		nop
		lda #$84
		sta col_pfield0
		ldy #$07
		dey
		bne *-$01
		inx
		cpx #$06
		bne ttl_txt_splt_06

		lda #$04
		sta col_pfield0

		sta wsync

		lda #$38
		sta col_pfield2
		lda #$08
		sta col_pfield3

		ldx #$04
		dex
		bne *-$01
		nop
		nop
		nop

; Split the seventh text line
		ldx #$00
ttl_txt_splt_07	lda #$04
		sta col_pfield0
		bit $ea
		nop
		lda #$84
		sta col_pfield0
		ldy #$07
		dey
		bne *-$01
		inx
		cpx #$06
		bne ttl_txt_splt_07

		lda #$04
		sta col_pfield0

		sta wsync

		lda #$18
		sta col_pfield2
		lda #$08
		sta col_pfield3

		ldx #$04
		dex
		bne *-$01
		nop
		nop
		nop

; Split the eighth text line
		ldx #$00
ttl_txt_splt_08	lda #$04
		sta col_pfield0
		bit $ea
		nop
		lda #$84
		sta col_pfield0
		ldy #$07
		dey
		bne *-$01
		inx
		cpx #$06
		bne ttl_txt_splt_08

		lda #$04
		sta col_pfield0

		sta wsync
		sta wsync
		sta wsync
		sta wsync
		sta wsync
		sta wsync
		sta wsync
		sta wsync
		sta wsync

		lda #$e8
		sta col_pfield2
		lda #$08
		sta col_pfield3

		ldx #$04
		dex
		bne *-$01
		nop
		nop
		nop

; Split the ninth text line
		ldx #$00
ttl_txt_splt_09	lda #$04
		sta col_pfield0
		bit $ea
		nop
		lda #$84
		sta col_pfield0
		ldy #$07
		dey
		bne *-$01
		inx
		cpx #$06
		bne ttl_txt_splt_09

		lda #$04
		sta col_pfield0

		sta wsync

		lda #$c8
		sta col_pfield2
		lda #$08
		sta col_pfield3

		ldx #$04
		dex
		bne *-$01
		nop
		nop
		nop

; Split the tenth text line
		ldx #$00
ttl_txt_splt_10	lda #$04
		sta col_pfield0
		bit $ea
		nop
		lda #$84
		sta col_pfield0
		ldy #$06
		dey
		bne *-$01
		bit $ea
		nop
		inx
		cpx #$06
		bne ttl_txt_splt_10

		lda #$04
		sta col_pfield0

; Set playfield colours for the scroller
		sta wsync
		sta wsync
		sta wsync
		sta wsync

		lda #$04
		sta col_pfield0
		lda ttl_scrl_col_1
		sta col_pfield2
		lda ttl_scrl_col_2
		sta col_pfield3

; Set playfield colour for the press fire message
		ldx #$00
ttl_dli_wait_3	stx wsync
		inx
		cpx #$0c
		bne ttl_dli_wait_3

; Make the Press Fire message glow
		ldx ttl_pulse_cnt
		ldy ttl_pulse_tmr
		iny
		cpy #$04
		bne ttl_ptyb
		inx
		cpx #$0d
		bne *+$04
		ldx #$00
		ldy #$00
ttl_ptyb	sty ttl_pulse_tmr
		stx ttl_pulse_cnt
		inx
		txa
		asl @
		asl @
		asl @
		asl @
		ora #$08
		sta col_pfield2

; Send a signal to the runtime code
		lda #$01
		sta sync

; Exit the DLI
		pla
		tay
		pla
		tax
		pla
		rti


; Move to the start of the next page boundary
		org [[*/$100]+$01]*$100

; In-game Display List Interrupt
dli		pha
		txa
		pha
		tya
		pha

		ldx #$00
dli_wait_1	stx wsync
		inx
		cpx #$11
		bne dli_wait_1

; Change video registers for the main playfield
		lda #$14
		sta col_pfield0
		lda #$0c
		sta col_pfield1
		lda #ingame_col_1
		sta col_pfield2
		lda #ingame_col_2
		sta col_pfield3

		ldx #$00
dli_wait_2	stx wsync
		inx
		cpx #$07
		bne dli_wait_2

		ldx #$03
		dex
		bne *-$01
		nop
		nop
		nop

; Split the first status line
		ldx #$00
dli_stat_splt_1	lda #ingame_col_1
		sta col_pfield2
		ldy #$06
		dey
		bne *-$01
		bit $ea
		nop
		lda #$28
		sta col_pfield2
		bit $ea
		nop
		inx
		cpx #$06
		bne dli_stat_splt_1

		lda #ingame_col_1
		sta col_pfield2

		ldy #$0f
		dey
		bne *-$01
		nop
		nop

; Split the second status line
		ldx #$00
dli_stat_splt_2	lda #ingame_col_1
		sta col_pfield2
		ldy #$06
		dey
		bne *-$01
		bit $ea
		nop
		lda #$38
		sta col_pfield2
		bit $ea
		nop
		inx
		cpx #$06
		bne dli_stat_splt_2

		lda #ingame_col_1
		sta col_pfield2

		sta wsync
		sta wsync
		sta wsync
		sta wsync
		sta wsync
		sta wsync
		sta wsync
		sta wsync

		ldy #$11
		dey
		bne *-$01
		nop

; Split the third status line
		ldx #$00
dli_stat_splt_3	lda #ingame_col_1
		sta col_pfield2
		ldy #$06
		dey
		bne *-$01
		bit $ea
		nop
		lda #$68
		sta col_pfield2
		bit $ea
		nop
		inx
		cpx #$06
		bne dli_stat_splt_3

		lda #ingame_col_1
		sta col_pfield2

		ldy #$0f
		dey
		bne *-$01
		bit $ea
		nop

; Split the fourth status line
		ldx #$00
dli_stat_splt_4	lda #ingame_col_1
		sta col_pfield2
		ldy #$06
		dey
		bne *-$01
		nop
		nop
		lda #$78
		sta col_pfield2
		bit $ea
		bit $ea
		inx
		cpx #$06
		bne dli_stat_splt_4

		lda #ingame_col_1
		sta col_pfield2

		sta wsync
		sta wsync
		sta wsync
		sta wsync
		sta wsync
		sta wsync
		sta wsync
		sta wsync

		ldy #$11
		dey
		bne *-$01
		nop

; Split the fifth status line
		ldx #$00
dli_stat_splt_5	lda #ingame_col_1
		sta col_pfield2
		ldy #$06
		dey
		bne *-$01
		bit $ea
		nop
		lda #$a8
		sta col_pfield2
		bit $ea
		nop
		inx
		cpx #$06
		bne dli_stat_splt_5

		lda #ingame_col_1
		sta col_pfield2

		ldy #$0f
		dey
		bne *-$01
		nop
		nop

; Split the sixth status line
		ldx #$00
dli_stat_splt_6	lda #ingame_col_1
		sta col_pfield2
		ldy #$06
		dey
		bne *-$01
		bit $ea
		nop
		lda #$b8
		sta col_pfield2
		bit $ea
		nop
		inx
		cpx #$06
		bne dli_stat_splt_6

		lda #ingame_col_1
		sta col_pfield2

; Wait until the logo so we can switch character set
		ldx #$00
dli_wait_3	stx wsync
		inx
		cpx #$21
		bne dli_wait_3

		lda #>ingame_chars+$04
		sta char_base

; Wait until the logo so we can switch character set
		ldx #$00
dli_wait_4	stx wsync
		inx
		cpx #$3f
		bne dli_wait_4

		lda #>ingame_chars
		sta char_base

		ldx #$06
		dex
		bne *-$01

		lda #$04
		ldx #$08
		ldy #$d8
		sta col_pfield0
		stx col_pfield2
		sty col_pfield3

; Send a signal to the runtime code
		lda #$01
		sta sync

; Exit the DLI
		pla
		tay
		pla
		tax
		pla
		rti


; Character decoding table (for text and numbers)
char_decode	dta $00,$1b,$00,$00,$00,$00,$00,$00	; space to '
		dta $00,$00,$2c,$00,$1c,$1e,$1d,$00	; ( to /
		dta $20,$21,$22,$23,$24,$25,$26,$27	; 0 to 7
		dta $28,$29,$2a,$2b,$00,$00,$00,$1f	; 8 to ?

		dta $00,$01,$02,$03,$04,$05,$06,$07	; @ to G
		dta $08,$09,$0a,$0b,$0c,$0d,$0e,$0f	; H to O
		dta $10,$11,$12,$13,$14,$15,$16,$17	; P to W
		dta $18,$19,$1a,$00,$00,$00,$00,$00	; X to _

		dta $00,$00,$00,$00,$00,$00,$00,$00
		dta $00,$00,$00,$00,$00,$00,$00,$00
		dta $00,$00,$00,$00,$00,$00,$00,$00
		dta $00,$00,$00,$00,$00,$00,$00,$00

		dta $00,$81,$82,$83,$84,$85,$86,$87	; diamond to g
		dta $88,$89,$8a,$8b,$8c,$8d,$8e,$8f	; h to o
		dta $90,$91,$92,$93,$94,$95,$96,$97	; p to w
		dta $98,$99,$9a,$00,$00,$00,$00,$00	; x to right arrow

; In-game message text
gamovr_text	dta d"game over"
levnum_text	dta d"LEVEL  00"
getrdy_text	dta d"get ready"

; In-game status area text
scr_score_text	dta d"SCORE"
scr_high_text	dta d" TOP "
scr_timer_text	dta d"TIMER"

; In-game cursor offsets
cur_x_off	dta $03,$07,$0b,$0f,$13,$17,$1b

cur_y_off_low	dta <[screen_ram+$078]
		dta <[screen_ram+$0a0]
		dta <[screen_ram+$0c8]

		dta <[screen_ram+$118]
		dta <[screen_ram+$140]
		dta <[screen_ram+$168]

		dta <[screen_ram+$1b8]
		dta <[screen_ram+$1e0]
		dta <[screen_ram+$208]

		dta <[screen_ram+$258]
		dta <[screen_ram+$280]
		dta <[screen_ram+$2a8]

		dta <[screen_ram+$2f8]
		dta <[screen_ram+$320]
		dta <[screen_ram+$348]

cur_y_off_high	dta >[screen_ram+$078]
		dta >[screen_ram+$0a0]
		dta >[screen_ram+$0c8]

		dta >[screen_ram+$118]
		dta >[screen_ram+$140]
		dta >[screen_ram+$168]

		dta >[screen_ram+$1b8]
		dta >[screen_ram+$1e0]
		dta >[screen_ram+$208]

		dta >[screen_ram+$258]
		dta >[screen_ram+$280]
		dta >[screen_ram+$2a8]

		dta >[screen_ram+$2f8]
		dta >[screen_ram+$320]
		dta >[screen_ram+$348]

; Graphics data for the player's cursor
cursor_data	dta $00,$ff,$ff,$cc,$cc,$33,$33,$00

; In-game "joystick" commands used by the playfield scrambling routine
scram_joy	dta $f7,$fe,$fb,$fd

; In-game playfield RAM
play_area	dta $00,$00,$00,$00,$00,$00,$00,$00
		dta $00,$00,$00,$00,$00,$00,$00,$00
		dta $00,$00,$00,$00,$00,$00,$00,$00
		dta $00,$00,$00,$00,$00,$00,$00,$00
		dta $00,$00,$00,$00,$00,$00,$00,$00

; Sprite definition data for the sides of the playfield
sprite_data_1	dta $00,$10,$10,$28,$28,$28,$28,$28
		dta $72,$5a,$2c,$2c,$2c,$2c,$5a,$72
		dta $2c,$2c,$2c,$2c,$2c,$2c,$2c,$2c
		dta $72,$5a,$2c,$2c,$2c,$2c,$5a,$72

sprite_data_2	dta $00,$00,$00,$10,$10,$10,$10,$10
		dta $7e,$20,$72,$72,$72,$72,$20,$7e
		dta $72,$72,$72,$72,$72,$72,$72,$72
		dta $7e,$20,$72,$72,$72,$72,$20,$7e

; Source files for data used to build the various screens
		icl "includes/title_screen.asm"
		icl "includes/ingame_screen.asm"
		icl "includes/end_screen.asm"
