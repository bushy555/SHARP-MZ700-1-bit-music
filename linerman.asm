; LinerMan, by AER.
; SquatM engine, by Shiru.
; DieHard Summer 2025 1bit compo.
;


; assemble with SJASMPLUS
;	sjasmplus LinerMan.asm
;	rbinary LinerMan.obj LinerMan.vz


 output "LinerMan.bin"

	org $5000


begin:		out 	($E0), a
		out	($E3), a

    		ld 	hl, $E008 	;sound on
 	   	ld 	(hl), $01




	ld hl,music_data
	call play
	ret
	
	
	
	;engine code

;SquatM by Shiru, 08'21 (minor mods for the original Squat 06'17)
;Squeeker like, just without the output value table
;4 channels of tone with different duty cycle
;sample drums, non-interrupting
;customizeable noise percussion, interrupting


;music data is all 16-bit words, first control then a few optional ones

;control word is PSSSSSSS DDDN4321, where P=percussion,S=speed, D=drum, N=noise mode, 4321=channels
;D triggers non-interruping sample drum
;P trigger
;if 1, channel 1 freq follows
;if 2, channel 2 freq follows
;if 3, channel 3 freq follows
;if 4, channel 4 freq follows
;if N, channel 4 mode follows, it is either #0000 (normal) or #04cb (noise)
;if P, percussion follows, LSB=volume, MSB=pitch



RLC_H=#04cb			;to enable noise mode
NOP_2=#0000			;to disable noise mode
RLC_HL=#06cb		;to enable sample reading
ADD_IX_IX=#29dd		;to disable sample reading


play

	di
	
	ld e,(hl)
	inc hl
	ld d,(hl)
	inc hl
	ld (pattern_ptr),de
	
	ld e,(hl)
	inc hl
	ld d,(hl)
	
	ld (loop_ptr),de

	dec hl
	ld (sample_list),hl
	
	ld hl,ADD_IX_IX
	ld (sample_read),hl
	ld hl,NOP_2					;normal mode
	ld (noise_mode),hl
	
	ld ix,0						;needs to be 0 to skip sample reading

	ld c,0
	exx
	ld de,#0808					;sample bit counter and reload value

play_loop

pattern_ptr=$+1
	ld sp,0
	
return_loop

	pop bc						;control word
								;B=duration of the row (0=loop)
								;C=flags DDDN4321 (Drum, Noise, 1-4 channel update)
	ld a,b
	or a
	jp nz,no_loop
	
loop_ptr=$+1
	ld sp,0
	
	jp return_loop
	
no_loop

	ld a,c
	
	rra
	jr nc,skip_note_0
	
	pop hl
	ld (ch0_add),hl
	
skip_note_0

	rra
	jr nc,skip_note_1

	pop hl
	ld (ch1_add),hl
	
skip_note_1

	rra
	jr nc,skip_note_2
	
	pop hl
	ld (ch2_add),hl
	
skip_note_2

	rra
	jr nc,skip_note_3
	
	pop hl
	ld (ch3_add),hl
	
skip_note_3

	rra
	jr nc,skip_mode_change
	
	pop hl						;nop:nop or rlc h
	ld (noise_mode),hl

skip_mode_change

	and 7
	jp z,skip_drum
	
sample_list=$+1
	ld hl,0						;sample_list-2
	add a,a
	add a,l
	ld l,a
	ld a,(hl)
	inc l
	ld h,(hl)
	ld l,a
	ld (sample_ptr),hl
	ld hl,RLC_HL
	ld (sample_read),hl

skip_drum

	bit 7,b						;check percussion flag
	jp z,skip_percussion

	res 7,b						;clear percussion flag

	ld (noise_bc),bc
	ld (noise_de),de

	pop hl						;read percussion parameters

	ld a,l						;noise volume
	ld (noise_volume),a
	ld b,h						;noise pitch
	ld c,h
	ld de,#2174					;utz's rand seed			
	exx
	ld bc,429					;noise duration, takes as long as inner sound loop

noise_loop

	exx							;4
	dec c						;4
	jr nz,noise_skip			;7/12
	ld c,b						;4
	add hl,de					;11
	rlc h						;8		utz's noise generator idea
	inc d						;4		improves randomness
	jp noise_next				;10
	
noise_skip

	jr $+2						;12
	jr $+2						;12
	nop							;4
	nop							;4
	
noise_next

	ld a,h						;4
	
noise_volume=$+1
	cp #80						;7
	sbc a,a						;4
	and 	$08		; SHARP MZ700
	or  	$20		; SHARP MZ700
	ld  	($e007), a	; SHARP MZ700

	exx							;4

	dec bc						;6
	ld a,b						;4
	or c						;4
	jp nz,noise_loop			;10=106t

	exx

noise_bc=$+1
	ld bc,0
noise_de=$+1
	ld de,0



skip_percussion

	ld (pattern_ptr),sp

sample_ptr=$+1
	ld hl,0

sound_loop0

	ld c,64						;internal loop runs 64 times

sound_loop

sample_read=$
	rlc (hl)					;15 	rotate sample bits in place, rl (hl) or add ix,ix (dummy operation)
	sbc a,a						;4		sbc a,a to make bit into 0 or 255, or xor a to keep it 0

	dec e						;4--+	count bits
	jp z,sample_cycle			;10 |
	jp sample_next				;10

sample_cycle

	ld e,d						;4	|	reload counter
	inc hl						;6--+	advance pointer --24t

sample_next

	exx							;4		squeeker type unrolled code
	ld b,a						;4		sample mask
	xor a						;4
	
	ld sp,sound_list			;10
		
	pop de						;10		ch0_acc
	pop hl						;10		ch0_add
	add hl,de					;11
	rla							;4
	ld (ch0_acc),hl				;16
						
	pop de						;10		ch1_acc
	pop hl						;10		ch1_add
	add hl,de					;11
	rla							;4
	ld (ch1_acc),hl				;16
	
	pop de						;10		ch2_acc
	pop hl						;10		ch2_add
	add hl,de					;11
	rla							;4
	ld (ch2_acc),hl				;16

	pop de						;10		ch3_acc
	pop hl						;10		ch3_add
	add hl,de					;11
	
noise_mode=$
	ds 2,0						;8		rlc h for noise effects

	rla							;4
	ld (ch3_acc),hl				;16

	add a,c						;4		no table like in Squeeker, channels summed as is, for uneven 'volume'
	add a,#ff					;7
	sbc a,#ff					;7
	ld c,a						;4
	sbc a,a						;4

	or b						;4		mix sample
	
	and 	$08		; SHARP MZ700
	or  	$20		; SHARP MZ700
	ld  	($e007), a	; SHARP MZ700

		
	exx							;4

	dec c						;4
	jp nz,sound_loop			;10=336t


	dec hl						;last byte of a 64 byte sample packet is #80 means it was the last packet
	ld a,(hl)
	inc hl
	cp #80
	jr nz,sample_no_stop

	ld hl,ADD_IX_IX
	ld (sample_read),hl			;disable sample reading

sample_no_stop

	djnz sound_loop0

	ld (sample_ptr),hl
	
	jp play_loop
	
	
		
;variables in the sound_list can't be reordered because of stack-based fetching

sound_list

ch0_add		dw 0
ch0_acc		dw 0
ch1_add		dw 0
ch1_acc		dw 0
ch2_add		dw 0
ch2_acc		dw 0
ch3_add		dw 0
ch3_acc		dw 0


;compiled music data

	align 2

music_data:
	dw .pattern
	dw .loop
;sample data

.sample_list:
	dw .sample_1
	dw .sample_2
	dw .sample_3
	dw .sample_4
	dw .sample_5
	dw .sample_6
	dw .sample_7
	align 256

	align 64/8

.sample_1:
	db 15,195,255,0,0,28,1,255
	db 255,160,0,0,0,0,0,5
	db 255,255,255,240,0,0,0,0
	db 1,255,255,255,240,0,0,0
	db 0,0,0,0,0,0,3,255
	db 255,224,0,195,255,248,0,0
	db 0,127,255,248,0,0,0,0
	db 0,15,255,255,255,254,0,0
	db 0,0,0,0,63,255,255,255
	db 224,0,0,0,0,0,7,255
	db 255,255,255,255,255,255,0,0
	db 0,0,0,0,0,0,0,128
.sample_2:
	db 59,96,32,0,223,159,128,0
	db 0,0,255,255,192,0,0,127
	db 248,0,4,30,240,13,3,255
	db 192,0,7,252,16,1,3,255
	db 192,0,0,255,112,11,119,176
	db 0,0,23,255,148,12,16,64
	db 19,125,11,87,0,0,0,143
	db 255,176,7,240,1,0,67,123
	db 120,0,48,192,105,194,63,129
	db 246,128,0,5,106,190,232,192
	db 0,6,184,79,200,6,144,0
	db 81,224,0,1,47,224,0,128
.sample_3:
	db 0,1,0,0,64,0,20,0
	db 1,0,136,0,0,0,0,0
	db 0,69,0,0,4,0,19,42
	db 0,0,0,0,0,0,0,128
.sample_4:
.sample_5:
.sample_6:
.sample_7:


.pattern:
.loop:
	dw #c1f,#0,#2b4,#0,#0,NOP_2
	dw #c00
	dw #c0a,#0,#2b4
	dw #c00
	dw #c0a,#2b4,#0
	dw #c00
	dw #c0a,#0,#2b4
	dw #c00
	dw #c0a,#337,#0
	dw #c00
	dw #c08,#337
	dw #c00
	dw #c02,#0
	dw #c00
	dw #c0a,#19b,#0
	dw #c00
	dw #c0a,#2b4,#19b
	dw #c00
	dw #c0a,#0,#2b4
	dw #c00
	dw #c0a,#2b4,#0
	dw #c00
	dw #c0a,#0,#2b4
	dw #c00
	dw #c0a,#337,#0
	dw #c00
	dw #c0a,#0,#337
	dw #c00
	dw #c0a,#308,#0
	dw #c00
	dw #c0a,#0,#308
	dw #c00
	dw #c0a,#206,#0
	dw #c00
	dw #c0a,#0,#206
	dw #c00
	dw #c0a,#206,#0
	dw #c00
	dw #c0a,#0,#206
	dw #c00
	dw #c0a,#268,#0
	dw #c00
	dw #c08,#268
	dw #c00
	dw #c02,#0
	dw #c00
	dw #c0a,#134,#0
	dw #c00
	dw #c0a,#206,#134
	dw #c00
	dw #c0a,#0,#206
	dw #c00
	dw #c0a,#206,#0
	dw #c00
	dw #c0a,#0,#206
	dw #c00
	dw #c0a,#268,#0
	dw #c00
	dw #c0a,#0,#268
	dw #c00
	dw #c0a,#245,#0
	dw #c00
	dw #c0a,#0,#245
	dw #c00
	dw #c0f,#0,#2b4,#0,#0
	dw #c00
	dw #c0a,#0,#2b4
	dw #c00
	dw #c0a,#2b4,#0
	dw #c00
	dw #c0a,#0,#2b4
	dw #c00
	dw #c0a,#337,#0
	dw #c00
	dw #c08,#337
	dw #c00
	dw #c02,#0
	dw #c00
	dw #c0a,#19b,#0
	dw #c00
	dw #c0a,#2b4,#19b
	dw #c00
	dw #c0a,#0,#2b4
	dw #c00
	dw #c0a,#2b4,#0
	dw #c00
	dw #c0a,#0,#2b4
	dw #c00
	dw #c0a,#337,#0
	dw #c00
	dw #c0a,#0,#337
	dw #c00
	dw #c0a,#308,#0
	dw #c00
	dw #c0a,#0,#308
	dw #c00
	dw #c0a,#206,#0
	dw #c00
	dw #c0a,#0,#206
	dw #c00
	dw #c0a,#206,#0
	dw #c00
	dw #c0a,#0,#206
	dw #c00
	dw #c0a,#268,#0
	dw #c00
	dw #c08,#268
	dw #c00
	dw #c02,#0
	dw #c00
	dw #c0a,#134,#0
	dw #c00
	dw #c0a,#206,#134
	dw #c00
	dw #c0a,#0,#206
	dw #c00
	dw #c0a,#206,#0
	dw #c00
	dw #c0a,#0,#206
	dw #c00
	dw #c0a,#268,#0
	dw #c00
	dw #c0a,#0,#268
	dw #c00
	dw #c0a,#245,#0
	dw #c00
	dw #c0a,#0,#245
	dw #c00
	dw #c0f,#2b4,#2b4,#0,#0
	dw #c00
	dw #c0b,#2b4,#0,#2b4
	dw #c00
	dw #c0b,#568,#2b4,#0
	dw #c00
	dw #c0b,#2b4,#0,#2b4
	dw #c00
	dw #c0b,#4d1,#337,#0
	dw #c00
	dw #c09,#568,#337
	dw #c00
	dw #c03,#2b4,#0
	dw #c00
	dw #c0b,#568,#19b,#0
	dw #c00
	dw #c0b,#2b4,#2b4,#19b
	dw #c00
	dw #c0b,#2b4,#0,#2b4
	dw #c00
	dw #c0b,#66e,#2b4,#0
	dw #c00
	dw #c0b,#2b4,#0,#2b4
	dw #c00
	dw #c0b,#568,#337,#0
	dw #c00
	dw #c0b,#2b4,#0,#337
	dw #c00
	dw #c0b,#4d1,#308,#0
	dw #c00
	dw #c0b,#568,#0,#308
	dw #c00
	dw #c0b,#206,#206,#0
	dw #c00
	dw #c0b,#206,#0,#206
	dw #c00
	dw #c0b,#40c,#206,#0
	dw #c00
	dw #c0b,#206,#0,#206
	dw #c00
	dw #c0b,#39b,#268,#0
	dw #c00
	dw #c09,#40c,#268
	dw #c00
	dw #c03,#206,#0
	dw #c00
	dw #c0b,#40c,#134,#0
	dw #c00
	dw #c0b,#206,#206,#134
	dw #c00
	dw #c0b,#206,#0,#206
	dw #c00
	dw #c0b,#4d1,#206,#0
	dw #c00
	dw #c0b,#206,#0,#206
	dw #c00
	dw #c0b,#40c,#268,#0
	dw #c00
	dw #c0b,#206,#0,#268
	dw #c00
	dw #c0b,#39b,#245,#0
	dw #c00
	dw #c0b,#40c,#0,#245
	dw #c00
	dw #c0f,#2b4,#2b4,#0,#0
	dw #c00
	dw #c0b,#2b4,#0,#2b4
	dw #c00
	dw #c0b,#568,#2b4,#0
	dw #c00
	dw #c0b,#2b4,#0,#2b4
	dw #c00
	dw #c0b,#4d1,#337,#0
	dw #c00
	dw #c09,#568,#337
	dw #c00
	dw #c03,#2b4,#0
	dw #c00
	dw #c0b,#568,#19b,#0
	dw #c00
	dw #c0b,#2b4,#2b4,#19b
	dw #c00
	dw #c0b,#2b4,#0,#2b4
	dw #c00
	dw #c0b,#66e,#2b4,#0
	dw #c00
	dw #c0b,#2b4,#0,#2b4
	dw #c00
	dw #c0b,#568,#337,#0
	dw #c00
	dw #c0b,#2b4,#0,#337
	dw #c00
	dw #c0b,#4d1,#308,#0
	dw #c00
	dw #c0b,#568,#0,#308
	dw #c00
	dw #c0b,#206,#206,#0
	dw #c00
	dw #c0b,#206,#0,#206
	dw #c00
	dw #c0b,#40c,#206,#0
	dw #c00
	dw #c0b,#206,#0,#206
	dw #c00
	dw #c0b,#39b,#268,#0
	dw #c00
	dw #c09,#40c,#268
	dw #c00
	dw #c03,#206,#0
	dw #c00
	dw #c0b,#40c,#134,#0
	dw #c00
	dw #c0b,#206,#206,#134
	dw #c00
	dw #c0b,#206,#0,#206
	dw #c00
	dw #c0b,#4d1,#206,#0
	dw #c00
	dw #c0b,#206,#0,#206
	dw #c00
	dw #c0b,#40c,#268,#0
	dw #c00
	dw #c0b,#206,#0,#268
	dw #c00
	dw #c0b,#39b,#245,#0
	dw #c00
	dw #c0b,#40c,#0,#245
	dw #c00
	dw #c2f,#2b4,#2b4,#0,#0
	dw #c00
	dw #c0b,#2b4,#0,#2b4
	dw #c00
	dw #c0b,#568,#2b4,#0
	dw #c00
	dw #c0b,#2b4,#0,#2b4
	dw #c00
	dw #c2b,#4d1,#337,#0
	dw #c00
	dw #c09,#568,#337
	dw #c00
	dw #c03,#2b4,#0
	dw #c00
	dw #c0b,#568,#19b,#0
	dw #c00
	dw #c2b,#2b4,#2b4,#19b
	dw #c00
	dw #c0b,#2b4,#0,#2b4
	dw #c00
	dw #c0b,#66e,#2b4,#0
	dw #c00
	dw #c0b,#2b4,#0,#2b4
	dw #c00
	dw #c2b,#568,#337,#0
	dw #c00
	dw #c0b,#2b4,#0,#337
	dw #c00
	dw #c0b,#4d1,#308,#0
	dw #c00
	dw #c0b,#568,#0,#308
	dw #c00
	dw #c2b,#206,#206,#0
	dw #c00
	dw #c0b,#206,#0,#206
	dw #c00
	dw #c0b,#40c,#206,#0
	dw #c00
	dw #c0b,#206,#0,#206
	dw #c00
	dw #c2b,#39b,#268,#0
	dw #c00
	dw #c09,#40c,#268
	dw #c00
	dw #c03,#206,#0
	dw #c00
	dw #c0b,#40c,#134,#0
	dw #c00
	dw #c2b,#206,#206,#134
	dw #c00
	dw #c0b,#206,#0,#206
	dw #c00
	dw #c0b,#4d1,#206,#0
	dw #c00
	dw #c0b,#206,#0,#206
	dw #c00
	dw #c2b,#40c,#268,#0
	dw #c00
	dw #c0b,#206,#0,#268
	dw #c00
	dw #c0b,#39b,#245,#0
	dw #c00
	dw #c0b,#40c,#0,#245
	dw #c00
	dw #c2f,#2b4,#2b4,#0,#0
	dw #c00
	dw #c0b,#2b4,#0,#2b4
	dw #c00
	dw #c0b,#568,#2b4,#0
	dw #c00
	dw #c0b,#2b4,#0,#2b4
	dw #c00
	dw #c2b,#4d1,#337,#0
	dw #c00
	dw #c09,#568,#337
	dw #c00
	dw #c03,#2b4,#0
	dw #c00
	dw #c0b,#568,#19b,#0
	dw #c00
	dw #c2b,#2b4,#2b4,#19b
	dw #c00
	dw #c0b,#2b4,#0,#2b4
	dw #c00
	dw #c0b,#66e,#2b4,#0
	dw #c00
	dw #c0b,#2b4,#0,#2b4
	dw #c00
	dw #c2b,#568,#337,#0
	dw #c00
	dw #c0b,#2b4,#0,#337
	dw #c00
	dw #c0b,#4d1,#308,#0
	dw #c00
	dw #c0b,#568,#0,#308
	dw #c00
	dw #c2b,#206,#206,#0
	dw #c00
	dw #c0b,#206,#0,#206
	dw #c00
	dw #c0b,#40c,#206,#0
	dw #c00
	dw #c0b,#206,#0,#206
	dw #c00
	dw #c2b,#39b,#268,#0
	dw #c00
	dw #c09,#40c,#268
	dw #c00
	dw #c03,#206,#0
	dw #c00
	dw #c0b,#40c,#134,#0
	dw #c00
	dw #c2b,#206,#206,#134
	dw #c00
	dw #c0b,#206,#0,#206
	dw #c00
	dw #c0b,#4d1,#206,#0
	dw #c00
	dw #c0b,#206,#0,#206
	dw #c00
	dw #c2b,#40c,#268,#0
	dw #c00
	dw #c0b,#0,#0,#268
	dw #c00
	dw #c0a,#0,#0
	dw #c00
	dw #c0a,#0,#0
	dw #c00
	dw #c2f,#2b4,#2b4,#819,#0
	dw #c00
	dw #c0b,#2b4,#0,#2b4
	dw #c00
	dw #c6f,#568,#2b4,#a88,#0
	dw #c04,#aa0
	dw #c0f,#2b4,#0,#ab0,#819
	dw #c04,#ab8
	dw #c27,#4d1,#337,#ad0
	dw #c00
	dw #c0d,#568,#9a2,#a88
	dw #c08,#aa0
	dw #c6f,#2b4,#0,#737,#ab0
	dw #c08,#ab8
	dw #c0f,#568,#19b,#819,#ac0
	dw #c00
	dw #c2f,#2b4,#2b4,#9a2,#992
	dw #c00
	dw #c0b,#2b4,#0,#727
	dw #c00
	dw #c6f,#66e,#2b4,#cdc,#809
	dw #c00
	dw #c0b,#2b4,#0,#992
	dw #c00
	dw #c27,#568,#337,#1033
	dw #c00
	dw #c0b,#2b4,#0,#ccc
	dw #c00
	dw #c67,#4d1,#308,#cdc
	dw #c00
	dw #c0f,#568,#0,#e6e,#1023
	dw #c00
	dw #c27,#206,#206,#1344
	dw #c00
	dw #c0f,#206,#0,#1033,#ccc
	dw #c00
	dw #c6f,#40c,#206,#15a0,#e5e
	dw #c00
	dw #c0f,#206,#0,#e6e,#1334
	dw #c00
	dw #c2f,#39b,#268,#1033,#1023
	dw #c00
	dw #c09,#40c,#1590
	dw #c00
	dw #c6f,#206,#0,#102b,#e5e
	dw #c00
	dw #c0f,#40c,#134,#1023,#1023
	dw #c00
	dw #c27,#206,#206,#101b
	dw #c00
	dw #c0f,#206,#0,#1013,#102b
	dw #c00
	dw #c6f,#4d1,#206,#100b,#1023
	dw #c00
	dw #c0f,#206,#0,#1003,#101b
	dw #c00
	dw #c2f,#40c,#268,#ffb,#1013
	dw #c00
	dw #c0f,#206,#0,#ff3,#100b
	dw #c00
	dw #c6f,#39b,#245,#feb,#1003
	dw #c00
	dw #c0b,#40c,#0,#ffb
	dw #c00
	dw #c2f,#2b4,#2b4,#ad0,#ff3
	dw #c00
	dw #c0b,#2b4,#0,#feb
	dw #c00
	dw #c67,#568,#2b4,#bdb
	dw #c04,#bf3
	dw #c0f,#2b4,#0,#c03,#ac0
	dw #c04,#c0b
	dw #c27,#4d1,#337,#c23
	dw #c00
	dw #c0d,#568,#cdc,#bdb
	dw #c08,#bf3
	dw #c6f,#2b4,#0,#c23,#c03
	dw #c08,#c0b
	dw #c0f,#568,#19b,#ad0,#c13
	dw #c00
	dw #c2f,#2b4,#2b4,#9a2,#ccc
	dw #c00
	dw #c0f,#2b4,#0,#ad0,#c13
	dw #c00
	dw #c6f,#66e,#2b4,#c23,#ac0
	dw #c00
	dw #c0f,#2b4,#0,#66e,#992
	dw #c00
	dw #c2f,#568,#337,#819,#ac0
	dw #c00
	dw #c0b,#2b4,#0,#c13
	dw #c00
	dw #c6b,#4d1,#308,#65e
	dw #c00
	dw #c0b,#568,#0,#809
	dw #c00
	dw #c23,#206,#206
	dw #c00
	dw #c03,#206,#0
	dw #c00
	dw #c63,#40c,#206
	dw #c00
	dw #c03,#206,#0
	dw #c00
	dw #c23,#39b,#268
	dw #c00
	dw #c01,#40c
	dw #c00
	dw #c67,#206,#0,#811
	dw #c00
	dw #c07,#40c,#134,#809
	dw #c00
	dw #c27,#206,#206,#801
	dw #c00
	dw #c0f,#206,#0,#7f9,#811
	dw #c00
	dw #c6f,#4d1,#206,#7f1,#809
	dw #c00
	dw #c0f,#206,#0,#7e9,#801
	dw #c00
	dw #c2f,#40c,#268,#7e1,#7f9
	dw #c00
	dw #c0f,#206,#0,#7d9,#7f1
	dw #c00
	dw #c6f,#39b,#245,#7d1,#7e9
	dw #c00
	dw #c0b,#40c,#0,#7e1
	dw #c00
	dw #c2f,#28d,#28d,#7a5,#0
	dw #c00
	dw #c0b,#28d,#0,#28d
	dw #c00
	dw #c6f,#51a,#28d,#9ec,#0
	dw #c04,#a04
	dw #c0f,#28d,#0,#a14,#7a5
	dw #c04,#a1c
	dw #c47,#48b,#308,#a34
	dw #c00
	dw #c0d,#51a,#917,#9ec
	dw #c08,#a04
	dw #c6f,#28d,#0,#6cf,#a14
	dw #c08,#a1c
	dw #c0f,#51a,#184,#7a5,#a24
	dw #c00
	dw #c2f,#28d,#28d,#917,#907
	dw #c00
	dw #c0b,#28d,#0,#6bf
	dw #c00
	dw #c6f,#611,#28d,#c23,#795
	dw #c00
	dw #c0b,#28d,#0,#907
	dw #c00
	dw #c47,#51a,#308,#f4a
	dw #c00
	dw #c0b,#28d,#0,#c13
	dw #c00
	dw #c67,#48b,#2dd,#c23
	dw #c00
	dw #c0f,#51a,#0,#d9f,#f3a
	dw #c00
	dw #c27,#1e9,#1e9,#122f
	dw #c00
	dw #c0f,#1e9,#0,#f4a,#c13
	dw #c00
	dw #c6f,#3d2,#1e9,#1469,#d8f
	dw #c00
	dw #c0f,#1e9,#0,#d9f,#121f
	dw #c00
	dw #c4f,#367,#245,#f4a,#f3a
	dw #c00
	dw #c09,#3d2,#1459
	dw #c00
	dw #c6f,#1e9,#0,#f42,#d8f
	dw #c00
	dw #c0f,#3d2,#122,#f3a,#f3a
	dw #c00
	dw #c27,#1e9,#1e9,#f32
	dw #c00
	dw #c0f,#1e9,#0,#f2a,#f42
	dw #c00
	dw #c6f,#48b,#1e9,#f22,#f3a
	dw #c00
	dw #c0f,#1e9,#0,#f1a,#f32
	dw #c00
	dw #c4f,#3d2,#245,#f12,#f2a
	dw #c00
	dw #c0f,#1e9,#0,#f0a,#f22
	dw #c00
	dw #c6f,#367,#225,#f02,#f1a
	dw #c00
	dw #c0b,#3d2,#0,#f12
	dw #c00
	dw #c2f,#28d,#28d,#a34,#f0a
	dw #c00
	dw #c0b,#28d,#0,#f02
	dw #c00
	dw #c67,#51a,#28d,#b2c
	dw #c04,#b44
	dw #c0f,#28d,#0,#b54,#a24
	dw #c04,#b5c
	dw #c47,#48b,#308,#b74
	dw #c00
	dw #c0d,#51a,#c23,#b2c
	dw #c08,#b44
	dw #c6f,#28d,#0,#b74,#b54
	dw #c08,#b5c
	dw #c0f,#51a,#184,#a34,#b64
	dw #c00
	dw #c2f,#28d,#28d,#917,#c13
	dw #c00
	dw #c0f,#28d,#0,#a34,#b64
	dw #c00
	dw #c6f,#611,#28d,#b74,#a24
	dw #c00
	dw #c0f,#28d,#0,#611,#907
	dw #c00
	dw #c4f,#51a,#308,#7a5,#a24
	dw #c00
	dw #c0b,#28d,#0,#b64
	dw #c00
	dw #c6b,#48b,#2dd,#601
	dw #c00
	dw #c0b,#51a,#0,#795
	dw #c00
	dw #c23,#1e9,#1e9
	dw #c00
	dw #c03,#1e9,#0
	dw #c00
	dw #c63,#3d2,#1e9
	dw #c00
	dw #c03,#1e9,#0
	dw #c00
	dw #c43,#367,#245
	dw #c00
	dw #c01,#3d2
	dw #c00
	dw #c67,#1e9,#0,#79d
	dw #c00
	dw #c07,#3d2,#122,#795
	dw #c00
	dw #c27,#1e9,#1e9,#78d
	dw #c00
	dw #c0f,#1e9,#0,#785,#79d
	dw #c00
	dw #c6f,#48b,#1e9,#77d,#795
	dw #c00
	dw #c0f,#1e9,#0,#775,#78d
	dw #c00
	dw #c4f,#3d2,#245,#76d,#785
	dw #c00
	dw #c0f,#1e9,#0,#765,#77d
	dw #c00
	dw #c6f,#367,#225,#75d,#775
	dw #c00
	dw #c0b,#3d2,#0,#76d
	dw #c00
	dw #c0d,#0,#9a2,#0
	dw #c00
	dw #c08,#337
	dw #c00
	dw #c0c,#c94,#0
	dw #c04,#cac
	dw #c0c,#cbc,#9a2
	dw #c04,#cc4
	dw #c04,#cdc
	dw #c00
	dw #c0c,#b74,#c94
	dw #c08,#cac
	dw #c0c,#895,#cbc
	dw #c08,#cc4
	dw #c0c,#9a2,#ccc
	dw #c00
	dw #c0c,#b74,#b64
	dw #c00
	dw #c08,#885
	dw #c00
	dw #c0c,#f4a,#992
	dw #c00
	dw #c08,#b64
	dw #c00
	dw #c04,#1344
	dw #c00
	dw #c08,#f3a
	dw #c00
	dw #c04,#f4a
	dw #c00
	dw #c0f,#66e,#0,#112a,#1334
	dw #c00
	dw #c47,#268,#268,#16e9
	dw #c00
	dw #c4f,#268,#0,#1344,#f3a
	dw #c00
	dw #c6f,#4d1,#268,#19b8,#111a
	dw #c00
	dw #c0f,#268,#0,#112a,#16d9
	dw #c00
	dw #c4f,#44a,#2dd,#1344,#1334
	dw #c00
	dw #c09,#4d1,#19a8
	dw #c00
	dw #c6f,#268,#0,#133c,#111a
	dw #c00
	dw #c0f,#4d1,#16e,#1334,#1334
	dw #c00
	dw #c27,#268,#268,#132c
	dw #c00
	dw #c0f,#268,#0,#1324,#133c
	dw #c00
	dw #c6f,#5ba,#268,#131c,#1334
	dw #c00
	dw #c0f,#268,#0,#1314,#132c
	dw #c00
	dw #c4f,#4d1,#2dd,#130c,#1324
	dw #c00
	dw #c0f,#268,#0,#1304,#131c
	dw #c00
	dw #c6f,#44a,#2b4,#12fc,#1314
	dw #c00
	dw #c0b,#4d1,#0,#130c
	dw #c00
	dw #c2f,#337,#337,#cdc,#1304
	dw #c00
	dw #c0b,#337,#0,#12fc
	dw #c00
	dw #c67,#66e,#337,#e26
	dw #c04,#e3e
	dw #c0f,#337,#0,#e4e,#ccc
	dw #c04,#e56
	dw #c47,#5ba,#3d2,#e6e
	dw #c00
	dw #c0d,#66e,#f4a,#e26
	dw #c08,#e3e
	dw #c6f,#337,#0,#e6e,#e4e
	dw #c08,#e56
	dw #c0f,#66e,#1e9,#cdc,#e5e
	dw #c00
	dw #c2f,#337,#337,#b74,#f3a
	dw #c00
	dw #c0f,#337,#0,#cdc,#e5e
	dw #c00
	dw #c6f,#7a5,#337,#e6e,#ccc
	dw #c00
	dw #c0f,#337,#0,#7a5,#b64
	dw #c00
	dw #c4f,#66e,#3d2,#9a2,#ccc
	dw #c00
	dw #c0b,#337,#0,#e5e
	dw #c00
	dw #c6b,#5ba,#39b,#795
	dw #c00
	dw #c0b,#66e,#0,#992
	dw #c00
	dw #c23,#268,#268
	dw #c00
	dw #c03,#268,#0
	dw #c00
	dw #c63,#4d1,#268
	dw #c00
	dw #c03,#268,#0
	dw #c00
	dw #c43,#44a,#2dd
	dw #c00
	dw #c01,#4d1
	dw #c00
	dw #c67,#268,#0,#99a
	dw #c00
	dw #c07,#4d1,#16e,#992
	dw #c00
	dw #c27,#268,#268,#98a
	dw #c00
	dw #c0f,#268,#0,#982,#99a
	dw #c00
	dw #c6f,#5ba,#268,#97a,#992
	dw #c00
	dw #c0f,#268,#0,#972,#98a
	dw #c00
	dw #c4f,#4d1,#2dd,#96a,#982
	dw #c00
	dw #c0f,#268,#0,#962,#97a
	dw #c00
	dw #c6f,#44a,#2b4,#95a,#972
	dw #c00
	dw #c0b,#4d1,#0,#96a
	dw #c00
	dw #c2f,#337,#337,#9a2,#0
	dw #c00
	dw #c0b,#337,#0,#337
	dw #c00
	dw #c6f,#66e,#337,#c94,#0
	dw #c04,#cac
	dw #c0f,#337,#0,#cbc,#9a2
	dw #c04,#cc4
	dw #c47,#5ba,#3d2,#cdc
	dw #c00
	dw #c0d,#66e,#b74,#c94
	dw #c08,#cac
	dw #c6f,#337,#0,#895,#cbc
	dw #c08,#cc4
	dw #c0f,#66e,#1e9,#9a2,#ccc
	dw #c00
	dw #c2f,#337,#337,#b74,#b64
	dw #c00
	dw #c0b,#337,#0,#885
	dw #c00
	dw #c6f,#7a5,#337,#f4a,#992
	dw #c00
	dw #c0b,#337,#0,#b64
	dw #c00
	dw #c47,#66e,#3d2,#1344
	dw #c00
	dw #c0b,#337,#0,#f3a
	dw #c00
	dw #c67,#5ba,#39b,#f4a
	dw #c00
	dw #c0f,#66e,#0,#112a,#1334
	dw #c00
	dw #c27,#268,#268,#16e9
	dw #c00
	dw #c0f,#268,#0,#1344,#f3a
	dw #c00
	dw #c6f,#4d1,#268,#19b8,#111a
	dw #c00
	dw #c0f,#268,#0,#112a,#16d9
	dw #c00
	dw #c4f,#44a,#2dd,#1344,#1334
	dw #c00
	dw #c09,#4d1,#19a8
	dw #c00
	dw #c6f,#268,#0,#133c,#111a
	dw #c00
	dw #c0f,#4d1,#16e,#1334,#1334
	dw #c00
	dw #c27,#268,#268,#132c
	dw #c00
	dw #c0f,#268,#0,#1324,#133c
	dw #c00
	dw #c6f,#5ba,#268,#131c,#1334
	dw #c00
	dw #c0f,#268,#0,#1314,#132c
	dw #c00
	dw #c4f,#4d1,#2dd,#130c,#1324
	dw #c00
	dw #c0f,#268,#0,#1304,#131c
	dw #c00
	dw #c6f,#44a,#2b4,#12fc,#1314
	dw #c00
	dw #c0b,#4d1,#0,#130c
	dw #c00
	dw #c2f,#337,#337,#cdc,#1304
	dw #c00
	dw #c0b,#337,#0,#12fc
	dw #c00
	dw #c67,#66e,#337,#e26
	dw #c04,#e3e
	dw #c0f,#337,#0,#e4e,#ccc
	dw #c04,#e56
	dw #c47,#5ba,#3d2,#e6e
	dw #c00
	dw #c0d,#66e,#f4a,#e26
	dw #c08,#e3e
	dw #c6f,#337,#0,#e6e,#e4e
	dw #c08,#e56
	dw #c0f,#66e,#1e9,#cdc,#e5e
	dw #c00
	dw #c2f,#337,#337,#b74,#f3a
	dw #c00
	dw #c0f,#337,#0,#cdc,#e5e
	dw #c00
	dw #c6f,#7a5,#337,#e6e,#ccc
	dw #c00
	dw #c0f,#337,#0,#7a5,#b64
	dw #c00
	dw #c4f,#66e,#3d2,#9a2,#ccc
	dw #c00
	dw #c0b,#337,#0,#e5e
	dw #c00
	dw #c6b,#5ba,#39b,#795
	dw #c00
	dw #c0b,#66e,#0,#992
	dw #c00
	dw #c23,#268,#268
	dw #c00
	dw #c03,#268,#0
	dw #c00
	dw #c63,#4d1,#268
	dw #c00
	dw #c03,#268,#0
	dw #c00
	dw #c43,#44a,#2dd
	dw #c00
	dw #c01,#4d1
	dw #c00
	dw #c67,#268,#0,#99a
	dw #c00
	dw #c07,#4d1,#16e,#992
	dw #c00
	dw #c27,#268,#268,#98a
	dw #c00
	dw #c0f,#268,#0,#982,#99a
	dw #c00
	dw #c6f,#5ba,#268,#97a,#992
	dw #c00
	dw #c0f,#268,#0,#972,#98a
	dw #c00
	dw #c4f,#4d1,#2dd,#96a,#982
	dw #c00
	dw #c0f,#268,#0,#962,#97a
	dw #c00
	dw #c6f,#44a,#2b4,#95a,#972
	dw #c00
	dw #c0b,#4d1,#0,#96a
	dw #c00
	dw #c27,#2b4,#2b4,#568
	dw #c04,#9a2
	dw #c07,#2b4,#0,#ad0
	dw #c04,#568
	dw #c67,#568,#2b4,#9a2
	dw #c04,#ad0
	dw #c0f,#2b4,#0,#568,#568
	dw #c0c,#9a2,#9a2
	dw #c2f,#4d1,#337,#ad0,#ad0
	dw #c0c,#568,#568
	dw #c0d,#568,#9a2,#9a2
	dw #c0c,#ad0,#ad0
	dw #c6f,#2b4,#0,#568,#568
	dw #c0c,#9a2,#9a2
	dw #c0f,#568,#19b,#ad0,#ad0
	dw #c0c,#568,#568
	dw #c2f,#2b4,#2b4,#9a2,#9a2
	dw #c0c,#ad0,#ad0
	dw #c0f,#2b4,#0,#568,#568
	dw #c0c,#9a2,#9a2
	dw #c6f,#66e,#2b4,#ad0,#ad0
	dw #c0c,#568,#568
	dw #c0f,#2b4,#0,#9a2,#9a2
	dw #c0c,#ad0,#ad0
	dw #c2f,#568,#337,#611,#568
	dw #c0c,#ad0,#9a2
	dw #c0f,#2b4,#0,#c23,#ad0
	dw #c0c,#611,#568
	dw #c6f,#4d1,#308,#ad0,#9a2
	dw #c0c,#c23,#ad0
	dw #c0f,#568,#0,#611,#611
	dw #c0c,#ad0,#ad0
	dw #c2f,#206,#206,#40c,#c23
	dw #c0c,#737,#611
	dw #c0f,#206,#0,#819,#ad0
	dw #c0c,#40c,#c23
	dw #c6f,#40c,#206,#737,#611
	dw #c0c,#819,#ad0
	dw #c0f,#206,#0,#40c,#40c
	dw #c0c,#737,#737
	dw #c2f,#39b,#268,#819,#819
	dw #c0c,#40c,#40c
	dw #c0d,#40c,#737,#737
	dw #c0c,#819,#819
	dw #c6f,#206,#0,#40c,#40c
	dw #c0c,#4d1,#737
	dw #c0f,#40c,#134,#895,#819
	dw #c0c,#9a2,#40c
	dw #c2f,#206,#206,#4d1,#737
	dw #c0c,#895,#819
	dw #c0f,#206,#0,#9a2,#40c
	dw #c0c,#4d1,#4d1
	dw #c6f,#4d1,#206,#895,#895
	dw #c0c,#9a2,#9a2
	dw #c0f,#206,#0,#4d1,#4d1
	dw #c0c,#895,#895
	dw #c2f,#40c,#268,#9a2,#9a2
	dw #c0c,#4d1,#4d1
	dw #c0f,#206,#0,#895,#895
	dw #c0c,#9a2,#9a2
	dw #c6f,#39b,#245,#4d1,#4d1
	dw #c0c,#4d1,#895
	dw #c0f,#40c,#0,#895,#9a2
	dw #c0c,#9a2,#4d1
	dw #c2f,#2b4,#2b4,#611,#895
	dw #c0c,#ad0,#9a2
	dw #c0f,#2b4,#0,#c23,#4d1
	dw #c0c,#611,#4d1
	dw #c6f,#568,#2b4,#ad0,#895
	dw #c0c,#c23,#9a2
	dw #c0f,#2b4,#0,#611,#611
	dw #c0c,#ad0,#ad0
	dw #c2f,#4d1,#337,#c23,#c23
	dw #c0c,#611,#611
	dw #c0d,#568,#ad0,#ad0
	dw #c0c,#c23,#c23
	dw #c6f,#2b4,#0,#611,#611
	dw #c0c,#c23,#ad0
	dw #c0f,#568,#19b,#ad0,#c23
	dw #c0c,#611,#611
	dw #c2f,#2b4,#2b4,#66e,#ad0
	dw #c0c,#c23,#c23
	dw #c0f,#2b4,#0,#cdc,#611
	dw #c0c,#66e,#c23
	dw #c6f,#66e,#2b4,#c23,#ad0
	dw #c0c,#cdc,#611
	dw #c0f,#2b4,#0,#66e,#66e
	dw #c0c,#c23,#c23
	dw #c2f,#568,#337,#cdc,#cdc
	dw #c0c,#66e,#66e
	dw #c0f,#2b4,#0,#c23,#c23
	dw #c0c,#cdc,#cdc
	dw #c6f,#4d1,#308,#66e,#66e
	dw #c0c,#c23,#c23
	dw #c0f,#568,#0,#cdc,#cdc
	dw #c0c,#66e,#66e
	dw #c2f,#206,#206,#4d1,#c23
	dw #c0c,#895,#cdc
	dw #c0f,#206,#0,#9a2,#66e
	dw #c0c,#4d1,#c23
	dw #c6f,#40c,#206,#895,#cdc
	dw #c0c,#9a2,#66e
	dw #c0f,#206,#0,#4d1,#4d1
	dw #c0c,#895,#895
	dw #c2f,#39b,#268,#9a2,#9a2
	dw #c0c,#4d1,#4d1
	dw #c0d,#40c,#895,#895
	dw #c0c,#9a2,#9a2
	dw #c6f,#206,#0,#4d1,#4d1
	dw #c0c,#895,#895
	dw #c0f,#40c,#134,#9a2,#9a2
	dw #c0c,#4d1,#4d1
	dw #c2f,#206,#206,#40c,#895
	dw #c0c,#737,#9a2
	dw #c0f,#206,#0,#819,#4d1
	dw #c0c,#40c,#895
	dw #c6f,#4d1,#206,#737,#9a2
	dw #c0c,#819,#4d1
	dw #c0f,#206,#0,#40c,#40c
	dw #c0c,#737,#737
	dw #c2f,#40c,#268,#819,#819
	dw #c0c,#40c,#40c
	dw #c0f,#206,#0,#737,#737
	dw #c0c,#819,#819
	dw #c6f,#39b,#245,#40c,#40c
	dw #c0c,#819,#737
	dw #c0f,#40c,#0,#40c,#819
	dw #c0c,#737,#40c
	dw #c2f,#2b4,#2b4,#568,#737
	dw #c0c,#ad0,#819
	dw #c0f,#2b4,#0,#568,#40c
	dw #c0c,#ad0,#819
	dw #c6f,#568,#2b4,#568,#40c
	dw #c0c,#ad0,#737
	dw #c0f,#2b4,#0,#568,#568
	dw #c0c,#611,#ad0
	dw #c2f,#4d1,#337,#c23,#568
	dw #c0c,#66e,#ad0
	dw #c0d,#568,#cdc,#568
	dw #c0c,#737,#ad0
	dw #c6f,#2b4,#0,#e6e,#568
	dw #c0c,#7a5,#611
	dw #c0f,#568,#19b,#1033,#c23
	dw #c0c,#e6e,#66e
	dw #c2f,#2b4,#2b4,#cdc,#cdc
	dw #c0c,#c23,#737
	dw #c0f,#2b4,#0,#ad0,#e6e
	dw #c0c,#9a2,#7a5
	dw #c6f,#66e,#2b4,#895,#1033
	dw #c0c,#819,#e6e
	dw #c0f,#2b4,#0,#737,#cdc
	dw #c0c,#66e,#c23
	dw #c2f,#568,#337,#337,#ad0
	dw #c0c,#39b,#9a2
	dw #c0f,#2b4,#0,#40c,#895
	dw #c0c,#44a,#819
	dw #c6f,#4d1,#308,#4d1,#737
	dw #c0c,#568,#66e
	dw #c0f,#568,#0,#611,#337
	dw #c0c,#66e,#39b
	dw #c2f,#206,#206,#66e,#40c
	dw #c0c,#66e,#44a
	dw #c0f,#206,#0,#cdc,#4d1
	dw #c0c,#66e,#568
	dw #c6f,#40c,#206,#611,#611
	dw #c0c,#611,#66e
	dw #c0f,#206,#0,#c23,#66e
	dw #c0c,#611,#66e
	dw #c2f,#39b,#268,#568,#cdc
	dw #c0c,#568,#66e
	dw #c0d,#40c,#ad0,#611
	dw #c0c,#568,#611
	dw #c6f,#206,#0,#4d1,#c23
	dw #c0c,#4d1,#611
	dw #c0f,#40c,#134,#9a2,#568
	dw #c0c,#4d1,#568
	dw #c2f,#206,#206,#44a,#ad0
	dw #c0c,#44a,#568
	dw #c0f,#206,#0,#895,#4d1
	dw #c0c,#44a,#4d1
	dw #c6f,#4d1,#206,#40c,#9a2
	dw #c0c,#40c,#4d1
	dw #c0f,#206,#0,#819,#44a
	dw #c0c,#40c,#44a
	dw #c2f,#40c,#268,#39b,#895
	dw #c0c,#39b,#44a
	dw #c0f,#206,#0,#737,#40c
	dw #c0c,#39b,#40c
	dw #c6f,#39b,#245,#337,#819
	dw #c0c,#337,#40c
	dw #c0f,#40c,#0,#66e,#39b
	dw #c0c,#337,#39b
	dw #c2f,#2b4,#2b4,#568,#737
	dw #c0c,#568,#39b
	dw #c0f,#2b4,#0,#ad0,#337
	dw #c0c,#568,#337
	dw #c6f,#568,#2b4,#9a2,#66e
	dw #c0c,#ad0,#337
	dw #c0f,#2b4,#0,#568,#568
	dw #c0c,#ad0,#568
	dw #c2f,#4d1,#337,#568,#ad0
	dw #c0c,#568,#568
	dw #c0d,#568,#568,#9a2
	dw #c0c,#ad0,#ad0
	dw #c6f,#2b4,#0,#568,#568
	dw #c0c,#9a2,#ad0
	dw #c0f,#568,#19b,#ad0,#568
	dw #c0c,#568,#568
	dw #c2f,#2b4,#2b4,#611,#568
	dw #c0c,#611,#ad0
	dw #c0f,#2b4,#0,#c23,#568
	dw #c0c,#611,#9a2
	dw #c6f,#66e,#2b4,#ad0,#ad0
	dw #c0c,#c23,#568
	dw #c0f,#2b4,#0,#611,#611
	dw #c0c,#c23,#611
	dw #c2f,#568,#337,#ad0,#c23
	dw #c0c,#611,#611
	dw #c0f,#2b4,#0,#ad0,#ad0
	dw #c0c,#c23,#c23
	dw #c6f,#4d1,#308,#611,#611
	dw #c0c,#c23,#c23
	dw #c0f,#568,#0,#611,#ad0
	dw #c0c,#c23,#611
	dw #c2f,#206,#206,#66e,#ad0
	dw #c0c,#66e,#c23
	dw #c0f,#206,#0,#cdc,#611
	dw #c0c,#66e,#c23
	dw #c6f,#40c,#206,#c23,#611
	dw #c0c,#cdc,#c23
	dw #c0f,#206,#0,#66e,#66e
	dw #c0c,#cdc,#66e
	dw #c2f,#39b,#268,#66e,#cdc
	dw #c0c,#c23,#66e
	dw #c0d,#40c,#c23,#c23
	dw #c0c,#cdc,#cdc
	dw #c6f,#206,#0,#66e,#66e
	dw #c0c,#cdc,#cdc
	dw #c0f,#40c,#134,#66e,#66e
	dw #c0c,#cdc,#c23
	dw #c2f,#206,#206,#40c,#c23
	dw #c0c,#40c,#cdc
	dw #c0f,#206,#0,#819,#66e
	dw #c0c,#40c,#cdc
	dw #c6f,#4d1,#206,#737,#66e
	dw #c0c,#819,#cdc
	dw #c0f,#206,#0,#40c,#40c
	dw #c0c,#737,#40c
	dw #c2f,#40c,#268,#819,#819
	dw #c0c,#0,#40c
	dw #c2b,#0,#0,#737
	dw #c08,#819
	dw #c08,#0
	dw #c00
	dw #c00
	dw #c00
	dw #c2f,#2b4,#2b4,#7e1,#0
	dw #c00
	dw #c0b,#2b4,#0,#2b4
	dw #c00
	dw #c6f,#568,#2b4,#a88,#0
	dw #c04,#aa0
	dw #c0f,#2b4,#0,#ab0,#819
	dw #c04,#ab8
	dw #c27,#4d1,#337,#ad0
	dw #c00
	dw #c0d,#568,#9a2,#a88
	dw #c08,#aa0
	dw #c6f,#2b4,#0,#737,#ab0
	dw #c08,#ab8
	dw #c0f,#568,#19b,#819,#ac0
	dw #c00
	dw #c2f,#2b4,#2b4,#9a2,#992
	dw #c00
	dw #c0b,#2b4,#0,#727
	dw #c00
	dw #c6f,#66e,#2b4,#cdc,#809
	dw #c00
	dw #c0b,#2b4,#0,#992
	dw #c00
	dw #c27,#568,#337,#1033
	dw #c00
	dw #c0b,#2b4,#0,#ccc
	dw #c00
	dw #c67,#4d1,#308,#cdc
	dw #c00
	dw #c0f,#568,#0,#e6e,#1023
	dw #c00
	dw #c27,#206,#206,#1344
	dw #c00
	dw #c0f,#206,#0,#1033,#ccc
	dw #c00
	dw #c6f,#40c,#206,#15a0,#e5e
	dw #c00
	dw #c0f,#206,#0,#e6e,#1334
	dw #c00
	dw #c2f,#39b,#268,#1033,#1023
	dw #c00
	dw #c09,#40c,#1590
	dw #c00
	dw #c6f,#206,#0,#102b,#e5e
	dw #c00
	dw #c0f,#40c,#134,#1023,#1023
	dw #c00
	dw #c27,#206,#206,#101b
	dw #c00
	dw #c0f,#206,#0,#1013,#102b
	dw #c00
	dw #c6f,#4d1,#206,#100b,#1023
	dw #c00
	dw #c0f,#206,#0,#1003,#101b
	dw #c00
	dw #c2f,#40c,#268,#ffb,#1013
	dw #c00
	dw #c0f,#206,#0,#ff3,#100b
	dw #c00
	dw #c6f,#39b,#245,#feb,#1003
	dw #c00
	dw #c0b,#40c,#0,#ffb
	dw #c00
	dw #c2f,#2b4,#2b4,#ad0,#ff3
	dw #c00
	dw #c0b,#2b4,#0,#feb
	dw #c00
	dw #c67,#568,#2b4,#bdb
	dw #c04,#bf3
	dw #c0f,#2b4,#0,#c03,#ac0
	dw #c04,#c0b
	dw #c27,#4d1,#337,#c23
	dw #c00
	dw #c0d,#568,#cdc,#bdb
	dw #c08,#bf3
	dw #c6f,#2b4,#0,#c23,#c03
	dw #c08,#c0b
	dw #c0f,#568,#19b,#ad0,#c13
	dw #c00
	dw #c2f,#2b4,#2b4,#9a2,#ccc
	dw #c00
	dw #c0f,#2b4,#0,#ad0,#c13
	dw #c00
	dw #c6f,#66e,#2b4,#c23,#ac0
	dw #c00
	dw #c0f,#2b4,#0,#66e,#992
	dw #c00
	dw #c2f,#568,#337,#819,#ac0
	dw #c00
	dw #c0b,#2b4,#0,#c13
	dw #c00
	dw #c6b,#4d1,#308,#65e
	dw #c00
	dw #c0b,#568,#0,#809
	dw #c00
	dw #c23,#206,#206
	dw #c00
	dw #c03,#206,#0
	dw #c00
	dw #c63,#40c,#206
	dw #c00
	dw #c03,#206,#0
	dw #c00
	dw #c23,#39b,#268
	dw #c00
	dw #c01,#40c
	dw #c00
	dw #c67,#206,#0,#811
	dw #c00
	dw #c07,#40c,#134,#809
	dw #c00
	dw #c27,#206,#206,#801
	dw #c00
	dw #c0f,#206,#0,#7f9,#811
	dw #c00
	dw #c6f,#4d1,#206,#7f1,#809
	dw #c00
	dw #c0f,#206,#0,#7e9,#801
	dw #c00
	dw #c2f,#40c,#268,#7e1,#7f9
	dw #c00
	dw #c0f,#206,#0,#7d9,#7f1
	dw #c00
	dw #c6f,#39b,#245,#7d1,#7e9
	dw #c00
	dw #c0b,#40c,#0,#7e1
	dw #c00
	dw #c2f,#28d,#28d,#7a5,#0
	dw #c00
	dw #c0b,#28d,#0,#28d
	dw #c00
	dw #c6f,#51a,#28d,#9ec,#0
	dw #c04,#a04
	dw #c0f,#28d,#0,#a14,#7a5
	dw #c04,#a1c
	dw #c47,#48b,#308,#a34
	dw #c00
	dw #c0d,#51a,#917,#9ec
	dw #c08,#a04
	dw #c6f,#28d,#0,#6cf,#a14
	dw #c08,#a1c
	dw #c0f,#51a,#184,#7a5,#a24
	dw #c00
	dw #c2f,#28d,#28d,#917,#907
	dw #c00
	dw #c0b,#28d,#0,#6bf
	dw #c00
	dw #c6f,#611,#28d,#c23,#795
	dw #c00
	dw #c0b,#28d,#0,#907
	dw #c00
	dw #c47,#51a,#308,#f4a
	dw #c00
	dw #c0b,#28d,#0,#c13
	dw #c00
	dw #c67,#48b,#2dd,#c23
	dw #c00
	dw #c0f,#51a,#0,#d9f,#f3a
	dw #c00
	dw #c27,#1e9,#1e9,#122f
	dw #c00
	dw #c0f,#1e9,#0,#f4a,#c13
	dw #c00
	dw #c6f,#3d2,#1e9,#1469,#d8f
	dw #c00
	dw #c0f,#1e9,#0,#d9f,#121f
	dw #c00
	dw #c4f,#367,#245,#f4a,#f3a
	dw #c00
	dw #c09,#3d2,#1459
	dw #c00
	dw #c6f,#1e9,#0,#f42,#d8f
	dw #c00
	dw #c0f,#3d2,#122,#f3a,#f3a
	dw #c00
	dw #c27,#1e9,#1e9,#f32
	dw #c00
	dw #c0f,#1e9,#0,#f2a,#f42
	dw #c00
	dw #c6f,#48b,#1e9,#f22,#f3a
	dw #c00
	dw #c0f,#1e9,#0,#f1a,#f32
	dw #c00
	dw #c4f,#3d2,#245,#f12,#f2a
	dw #c00
	dw #c0f,#1e9,#0,#f0a,#f22
	dw #c00
	dw #c6f,#367,#225,#f02,#f1a
	dw #c00
	dw #c0b,#3d2,#0,#f12
	dw #c00
	dw #c2f,#28d,#28d,#a34,#f0a
	dw #c00
	dw #c0b,#28d,#0,#f02
	dw #c00
	dw #c67,#51a,#28d,#b2c
	dw #c04,#b44
	dw #c0f,#28d,#0,#b54,#a24
	dw #c04,#b5c
	dw #c47,#48b,#308,#b74
	dw #c00
	dw #c0d,#51a,#c23,#b2c
	dw #c08,#b44
	dw #c6f,#28d,#0,#b74,#b54
	dw #c08,#b5c
	dw #c0f,#51a,#184,#a34,#b64
	dw #c00
	dw #c2f,#28d,#28d,#917,#c13
	dw #c00
	dw #c0f,#28d,#0,#a34,#b64
	dw #c00
	dw #c6f,#611,#28d,#b74,#a24
	dw #c00
	dw #c0f,#28d,#0,#611,#907
	dw #c00
	dw #c4f,#51a,#308,#7a5,#a24
	dw #c00
	dw #c0b,#28d,#0,#b64
	dw #c00
	dw #c6b,#48b,#2dd,#601
	dw #c00
	dw #c0b,#51a,#0,#795
	dw #c00
	dw #c23,#1e9,#1e9
	dw #c00
	dw #c03,#1e9,#0
	dw #c00
	dw #c63,#3d2,#1e9
	dw #c00
	dw #c03,#1e9,#0
	dw #c00
	dw #c43,#367,#245
	dw #c00
	dw #c01,#3d2
	dw #c00
	dw #c67,#1e9,#0,#79d
	dw #c00
	dw #c07,#3d2,#122,#795
	dw #c00
	dw #c27,#1e9,#1e9,#78d
	dw #c00
	dw #c0f,#1e9,#0,#785,#79d
	dw #c00
	dw #c6f,#48b,#1e9,#77d,#795
	dw #c00
	dw #c0f,#1e9,#0,#775,#78d
	dw #c00
	dw #c4f,#3d2,#245,#76d,#785
	dw #c00
	dw #c0f,#1e9,#0,#765,#77d
	dw #c00
	dw #c6f,#367,#225,#75d,#775
	dw #c00
	dw #c0b,#3d2,#0,#76d
	dw #c00
	dw #c0d,#0,#9a2,#0
	dw #c00
	dw #c08,#337
	dw #c00
	dw #c0c,#c94,#0
	dw #c04,#cac
	dw #c0c,#cbc,#9a2
	dw #c04,#cc4
	dw #c04,#cdc
	dw #c00
	dw #c0c,#b74,#c94
	dw #c08,#cac
	dw #c0c,#895,#cbc
	dw #c08,#cc4
	dw #c0c,#9a2,#ccc
	dw #c00
	dw #c0c,#b74,#b64
	dw #c00
	dw #c08,#885
	dw #c00
	dw #c0c,#f4a,#992
	dw #c00
	dw #c08,#b64
	dw #c00
	dw #c04,#1344
	dw #c00
	dw #c08,#f3a
	dw #c00
	dw #c04,#f4a
	dw #c00
	dw #c0f,#66e,#0,#112a,#1334
	dw #c00
	dw #c47,#268,#268,#16e9
	dw #c00
	dw #c4f,#268,#0,#1344,#f3a
	dw #c00
	dw #c6f,#4d1,#268,#19b8,#111a
	dw #c00
	dw #c0f,#268,#0,#112a,#16d9
	dw #c00
	dw #c4f,#44a,#2dd,#1344,#1334
	dw #c00
	dw #c09,#4d1,#19a8
	dw #c00
	dw #c6f,#268,#0,#133c,#111a
	dw #c00
	dw #c0f,#4d1,#16e,#1334,#1334
	dw #c00
	dw #c27,#268,#268,#132c
	dw #c00
	dw #c0f,#268,#0,#1324,#133c
	dw #c00
	dw #c6f,#5ba,#268,#131c,#1334
	dw #c00
	dw #c0f,#268,#0,#1314,#132c
	dw #c00
	dw #c4f,#4d1,#2dd,#130c,#1324
	dw #c00
	dw #c0f,#268,#0,#1304,#131c
	dw #c00
	dw #c6f,#44a,#2b4,#12fc,#1314
	dw #c00
	dw #c0b,#4d1,#0,#130c
	dw #c00
	dw #c2f,#337,#337,#cdc,#1304
	dw #c00
	dw #c0b,#337,#0,#12fc
	dw #c00
	dw #c67,#66e,#337,#e26
	dw #c04,#e3e
	dw #c0f,#337,#0,#e4e,#ccc
	dw #c04,#e56
	dw #c47,#5ba,#3d2,#e6e
	dw #c00
	dw #c0d,#66e,#f4a,#e26
	dw #c08,#e3e
	dw #c6f,#337,#0,#e6e,#e4e
	dw #c08,#e56
	dw #c0f,#66e,#1e9,#cdc,#e5e
	dw #c00
	dw #c2f,#337,#337,#b74,#f3a
	dw #c00
	dw #c0f,#337,#0,#cdc,#e5e
	dw #c00
	dw #c6f,#7a5,#337,#e6e,#ccc
	dw #c00
	dw #c0f,#337,#0,#7a5,#b64
	dw #c00
	dw #c4f,#66e,#3d2,#9a2,#ccc
	dw #c00
	dw #c0b,#337,#0,#e5e
	dw #c00
	dw #c6b,#5ba,#39b,#795
	dw #c00
	dw #c0b,#66e,#0,#992
	dw #c00
	dw #c23,#268,#268
	dw #c00
	dw #c03,#268,#0
	dw #c00
	dw #c63,#4d1,#268
	dw #c00
	dw #c03,#268,#0
	dw #c00
	dw #c43,#44a,#2dd
	dw #c00
	dw #c01,#4d1
	dw #c00
	dw #c67,#268,#0,#99a
	dw #c00
	dw #c07,#4d1,#16e,#992
	dw #c00
	dw #c27,#268,#268,#98a
	dw #c00
	dw #c0f,#268,#0,#982,#99a
	dw #c00
	dw #c6f,#5ba,#268,#97a,#992
	dw #c00
	dw #c0f,#268,#0,#972,#98a
	dw #c00
	dw #c4f,#4d1,#2dd,#96a,#982
	dw #c00
	dw #c0f,#268,#0,#962,#97a
	dw #c00
	dw #c6f,#44a,#2b4,#95a,#972
	dw #c00
	dw #c0b,#4d1,#0,#96a
	dw #c00
	dw #c2f,#337,#337,#9a2,#0
	dw #c00
	dw #c0b,#337,#0,#337
	dw #c00
	dw #c6f,#66e,#337,#c94,#0
	dw #c04,#cac
	dw #c0f,#337,#0,#cbc,#9a2
	dw #c04,#cc4
	dw #c47,#5ba,#3d2,#cdc
	dw #c00
	dw #c0d,#66e,#b74,#c94
	dw #c08,#cac
	dw #c6f,#337,#0,#895,#cbc
	dw #c08,#cc4
	dw #c0f,#66e,#1e9,#9a2,#ccc
	dw #c00
	dw #c2f,#337,#337,#b74,#b64
	dw #c00
	dw #c0b,#337,#0,#885
	dw #c00
	dw #c6f,#7a5,#337,#f4a,#992
	dw #c00
	dw #c0b,#337,#0,#b64
	dw #c00
	dw #c47,#66e,#3d2,#1344
	dw #c00
	dw #c0b,#337,#0,#f3a
	dw #c00
	dw #c67,#5ba,#39b,#f4a
	dw #c00
	dw #c0f,#66e,#0,#112a,#1334
	dw #c00
	dw #c27,#268,#268,#16e9
	dw #c00
	dw #c0f,#268,#0,#1344,#f3a
	dw #c00
	dw #c6f,#4d1,#268,#19b8,#111a
	dw #c00
	dw #c0f,#268,#0,#112a,#16d9
	dw #c00
	dw #c4f,#44a,#2dd,#1344,#1334
	dw #c00
	dw #c09,#4d1,#19a8
	dw #c00
	dw #c6f,#268,#0,#133c,#111a
	dw #c00
	dw #c0f,#4d1,#16e,#1334,#1334
	dw #c00
	dw #c27,#268,#268,#132c
	dw #c00
	dw #c0f,#268,#0,#1324,#133c
	dw #c00
	dw #c6f,#5ba,#268,#131c,#1334
	dw #c00
	dw #c0f,#268,#0,#1314,#132c
	dw #c00
	dw #c4f,#4d1,#2dd,#130c,#1324
	dw #c00
	dw #c0f,#268,#0,#1304,#131c
	dw #c00
	dw #c6f,#44a,#2b4,#12fc,#1314
	dw #c00
	dw #c0b,#4d1,#0,#130c
	dw #c00
	dw #c2f,#337,#337,#cdc,#1304
	dw #c00
	dw #c0b,#337,#0,#12fc
	dw #c00
	dw #c67,#66e,#337,#e26
	dw #c04,#e3e
	dw #c0f,#337,#0,#e4e,#ccc
	dw #c04,#e56
	dw #c47,#5ba,#3d2,#e6e
	dw #c00
	dw #c0d,#66e,#f4a,#e26
	dw #c08,#e3e
	dw #c6f,#337,#0,#e6e,#e4e
	dw #c08,#e56
	dw #c0f,#66e,#1e9,#cdc,#e5e
	dw #c00
	dw #c2f,#337,#337,#b74,#f3a
	dw #c00
	dw #c0f,#337,#0,#cdc,#e5e
	dw #c00
	dw #c6f,#7a5,#337,#e6e,#ccc
	dw #c00
	dw #c0f,#337,#0,#7a5,#b64
	dw #c00
	dw #c4f,#66e,#3d2,#9a2,#ccc
	dw #c00
	dw #c0b,#337,#0,#e5e
	dw #c00
	dw #c6b,#5ba,#39b,#795
	dw #c00
	dw #c0b,#66e,#0,#992
	dw #c00
	dw #c23,#268,#268
	dw #c00
	dw #c03,#268,#0
	dw #c00
	dw #c63,#4d1,#268
	dw #c00
	dw #c03,#268,#0
	dw #c00
	dw #c43,#44a,#2dd
	dw #c00
	dw #c01,#4d1
	dw #c00
	dw #c67,#268,#0,#99a
	dw #c00
	dw #c07,#4d1,#16e,#992
	dw #c00
	dw #c27,#268,#268,#98a
	dw #c00
	dw #c0f,#268,#0,#982,#99a
	dw #c00
	dw #c6f,#5ba,#268,#97a,#992
	dw #c00
	dw #c0f,#268,#0,#972,#98a
	dw #c00
	dw #c4f,#4d1,#2dd,#96a,#982
	dw #c00
	dw #c0f,#268,#0,#962,#97a
	dw #c00
	dw #c6f,#44a,#2b4,#95a,#972
	dw #c00
	dw #c6b,#4d1,#0,#96a
	dw #c60
	dw #c6f,#0,#0,#819,#0
	dw #c00
	dw #c08,#2b4
	dw #c00
	dw #c0c,#a88,#0
	dw #c04,#aa0
	dw #c0c,#ab0,#819
	dw #c04,#ab8
	dw #c04,#ad0
	dw #c00
	dw #c0c,#9a2,#a88
	dw #c08,#aa0
	dw #c0c,#737,#ab0
	dw #c08,#ab8
	dw #c0c,#819,#ac0
	dw #c00
	dw #c0c,#9a2,#992
	dw #c00
	dw #c08,#727
	dw #c00
	dw #c0c,#cdc,#809
	dw #c00
	dw #c08,#992
	dw #c00
	dw #c04,#1033
	dw #c00
	dw #c08,#ccc
	dw #c00
	dw #c04,#cdc
	dw #c00
	dw #c0c,#e6e,#1023
	dw #c00
	dw #c04,#1344
	dw #c00
	dw #c0c,#1033,#ccc
	dw #c00
	dw #c0c,#15a0,#e5e
	dw #c00
	dw #c0c,#e6e,#1334
	dw #c00
	dw #c0c,#1033,#1023
	dw #c00
	dw #c08,#1590
	dw #c00
	dw #c0c,#102b,#e5e
	dw #c00
	dw #c0c,#1023,#1023
	dw #c00
	dw #c04,#101b
	dw #c00
	dw #c0c,#1013,#102b
	dw #c00
	dw #c0c,#100b,#1023
	dw #c00
	dw #c0c,#1003,#101b
	dw #c00
	dw #c0c,#ffb,#1013
	dw #c00
	dw #c0c,#ff3,#100b
	dw #c00
	dw #c0c,#feb,#1003
	dw #c00
	dw #c08,#ffb
	dw #c00
	dw #c0c,#ad0,#ff3
	dw #c00
	dw #c08,#feb
	dw #c00
	dw #c04,#bdb
	dw #c04,#bf3
	dw #c0c,#c03,#ac0
	dw #c04,#c0b
	dw #c04,#c23
	dw #c00
	dw #c0c,#cdc,#bdb
	dw #c08,#bf3
	dw #c0c,#c23,#c03
	dw #c08,#c0b
	dw #c0c,#ad0,#c13
	dw #c00
	dw #c0c,#9a2,#ccc
	dw #c00
	dw #c0c,#ad0,#c13
	dw #c00
	dw #c0c,#c23,#ac0
	dw #c00
	dw #c0c,#66e,#992
	dw #c00
	dw #c0c,#819,#ac0
	dw #c00
	dw #c08,#c13
	dw #c00
	dw #c08,#65e
	dw #c00
	dw #c08,#809
	dw #c00
	dw #c00
	dw #c00
	dw #c00
	dw #c00
	dw #c00
	dw #c00
	dw #c00
	dw #c00
	dw #c00
	dw #c00
	dw #c00
	dw #c00
	dw #c04,#811
	dw #c00
	dw #c04,#809
	dw #c00
	dw #c04,#801
	dw #c00
	dw #c0c,#7f9,#811
	dw #c00
	dw #c0c,#7f1,#809
	dw #c00
	dw #c0c,#7e9,#801
	dw #c00
	dw #c0c,#7e1,#7f9
	dw #c00
	dw #c0c,#7d9,#7f1
	dw #c00
	dw #c0c,#7d1,#7e9
	dw #c00
	dw #c08,#7e1
	dw #c00
	dw #c00
	dw #c00
	dw #c60
	dw #c60
	dw #c6c,#811,#ab0
	dw #c00
	dw #c04,#7f9
	dw #c00
	dw #c0c,#7e9,#aa8
	dw #c00
	dw #c04,#7d9
	dw #c00
	dw #c0c,#7d1,#aa0
	dw #c00
	dw #c04,#7d1
	dw #c00
	dw #c0c,#0,#0
	dw #c00
	dw #400c,#0,#0
	dw #4000
	dw 0
