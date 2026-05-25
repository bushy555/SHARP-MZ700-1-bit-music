; 	EARSHAVER ALBUM.  By Shiru.
; 	TRACK 11
;
	output "TRACK11.MZT"


; TRACK 1: ADVENTURE TIME.	12527	3201
; TRACK 2: TRAFFIC LIGHTS	8933	2351
; TRACK 3: PERFECT $@!TSTORM	8361	2181
; TRACK 4: ALPHABEARD		10675	3193
; TRACK 5: EAR SHAVER		7415	2026
; TRACK 6: SPINNING BITS	10030	2580
; TRACK 7: FACEMELTER		6854	1771
; TRACK 8: BURNING BRIGHT	9824	2291
; TRACK 9: BALLS OF STEEL	11880	3247
; TRACK 10: KINDA LOUD		14678	3068
; TRACK 11: NOISE IN MY HEAD	7603	2516

CLS:	EQU	16H		;clear screen char
PRNT:   EQU	0012H		;subroutine to print 1 char from accu

	org $5000 - 128

   	db	01								; 01 = Binary.
   	db	"TRACK11",$0d,$0d,$0d,$0d,$0d,$0d,$0d,$0d,$0d,$0d		; 16 byte filename with $0D terminator
   	dw	14000								; Length.  $800 = $2k program.  $1000=4k program
   	dw	$5000								; Load address
   	dw	$5000								; Execute address
   	ds 	104, " "           						; blank trailer space. 104 total.  32 per line.

	org 	$5000


LB079:  LD      A,CLS
        CALL    PRNT		;clear screen
        LD      DE, MSG1		
        LD      B, 40
LOOP1:  LD      A, (DE)
        CALL    PRNT		;print 
        INC     DE		;point to next 
	djnz	LOOP1
        LD      DE, MSG2		
        LD      B, 40
LOOP2:  LD      A, (DE)
        CALL    PRNT		;print 
        INC     DE		;point to next 
	djnz	LOOP2


begin:	ld hl, music_data
	call play
	ret
;                   1234567890123456789012345678901234567890
MSG1 	db	$D,"EARSHAVER BY SHIRU. MZ PORT:DAVE.  2026 ",0
;MSG2	db 	$d,"TRACK 1: ADVENTURE TIME.                ",0
;MSG2	db 	$d,"TRACK 2: TRAFFIC LIGHTS.                ",0
;MSG2	db 	$d,"TRACK 3: PERFECT $@!TSTORM.             ",0
;MSG2	db 	$d,"TRACK 4: ALPHABEARD.                    ",0
;MSG2	db 	$d,"TRACK 5: EAR SHAVER.                    ",0
;MSG2	db 	$d,"TRACK 6: SPINNING BITS.                 ",0
;MSG2	db 	$d,"TRACK 7: FACEMELTER.                    ",0
;MSG2	db 	$d,"TRACK 8: BURNING BRIGHT.                ",0
;MSG2	db 	$d,"TRACK 9: BALLS OF STEEL.                ",0
;MSG2	db 	$d,"TRACK 10: KINDA LOUD.                   ",0
MSG2	db 	$d,"TRACK 11: NOISE IN MY HEAD.             ",0




;music data format
;two bytes absolute pointer to drumParam table, then song data follows
;row length and flags byte
;%Frrrrrrr
; r=row length 0..127, F is special event flag
; 00=end of song data
;if F flag is set, check the lowest bit, it is engine change or drum pointer
; RD00EEE1 is engine change
;  R=phase reset flag (always set for engines 0 and 5)
;  E=engine number*2 (0,2,4,6,8,10,12,14)
;  D=drum flag, if set, the drum param pointer follows
; xxxxxxx0 is drum pointer, this is LSB, MSB follows
;two note fields follows after the speed byte and optional bytes:
;$00 empty field, $01 rest note, otherwise MSB/LSB word of the divider/duty/phase
;drum param table follows, entries always aligned to 2 byte (lowest bit is zero):
; 2 byte pointer to the sample data, complete with added offset in frames
; 1 byte frames to be played (may vary depending on the offset)
; 1 byte volume 0..3 *3
; 1 byte pitch 0..8 *3

OP_NOP=$00
OP_XORA=$af
OP_RLCD=$02
OP_SBCAA=$9f

play:	di
	push iy
	exx
	push hl
	exx
	ld c,(hl)
	inc hl
	ld b,(hl)
	inc hl
	ld (drumParam),bc
	push hl					;put song ptr to stack

	;hl acc1
	;de add1
	;bc sample counter
	;hl' acc2
	;de' add2
	;b' squeeker output acc
	;c' always 16
	;a' phaser output bit
	
	ld ix,0					;ModPhase lfo's, ixh=ch1 ixl=ch2
	ld hl,0					;acc2
	ld de,0					;add2
	ld b,0					;squeker output acc
	ld c,8				;output bit mask
	ld	a, 1
	exx
	ld hl,0					;acc1
	ld de,0					;add1
;	xor a
	ld	a, 1
	exa						;phaser output bit
playRow:ex (sp),hl				;get song ptr, store acc1
loopRow:ld a,(hl)				;row length and flags
	inc hl
	or a
	jp nz,setRowLen
	ld a,(hl)				;go loop
	inc hl
	ld h,(hl)
	ld l,a
	jp loopRow
setRowLen:
	push af					;row length
	jp p,readNotes
	ld a,(hl)
	inc hl
	bit 0,a
	jp nz,engineChange
	ld c,a
	jp drumCall
engineChange:
	push af
	push hl
	ld (phaseReset1),a			;>=128 means it uses phase reset
	ld (phaseReset2),a
	ld hl,engineList
	and $3e
	add a,l
	ld l,a
	jr nc,$+3
	inc h
	ld a,(hl)
	inc hl
	ld h,(hl)
	ld l,a
	ld (engineJump),hl
	pop hl
	pop af
	and $40
	jr z,readNotes
	ld c,(hl)
	inc hl
drumCall:
	call playDrum
readNotes:
	pop af
	and $7f
	ld b,a					;row time*256/4 for better time resolution
	ld c,0
	srl b
	rr c
	srl b
	rr c
	ld a,(hl)				;ch1
	inc hl
	or a
	jr z,skipCh1
	dec a
	jp nz,noteCh1
						;mute ch1
	ld (tt_duty1),a			;reset duty1
	ld (ttev_duty1),a
	ld (ttqn_duty1),a
	ld (sq_duty1),a
	ld (mod_mute1),a		;nop
	ld (mod_alt1),a
	pop de					;get acc1 off the stack
	ld d,a					;reset add1
	ld e,a
	push de					;put acc1 back to the stack, now it is zero
	jp skipCh1
noteCh1:inc a
	ld d,a
	rra						;duty1 for squeeker
	rra
	rra
	and $0e
	add a,a
	inc a
	ld (sq_duty1),a
	ld a,d
	and $f0					;duty1 for tritone
	cp $80
	jr nz,$+5				;reset phase for ModPhase's non-zero W
	ld ixh,$80
	ld (tt_duty1),a
	ld (ttev_duty1),a
	ld (ttqn_duty1),a
	add a,a
	ld (mod_alt1),a
	ld a,OP_SBCAA
	ld (mod_mute1),a
	jp z,noPhase1			;phase reset
phaseReset1=$+1
	ld a,0					;
	rla						;
	jr nc,noPhase1			;
	ld a,d					;
	and $f0					;
	sub $80					;to keep compatibility
	ex (sp),hl				;set phase
	ld h,a					;
	ld l,0					;
	ex (sp),hl				;
noPhase1:
	ld a,d
	and $0f
	ld d,a					;add1 msb
	ld e,(hl)				;add1 lsb
	inc hl
skipCh1:ld a,(hl)				;ch2
	inc hl
	or a
	jr z,skipCh2
	dec a
	jp nz,noteCh2
					;mute ch2
	ld (tt_duty2),a			;reset duty2
	ld (ttev_duty2),a
	ld (ttln_duty2),a
	ld (sq_duty2),a
	ld (mod_mute2),a		;nop
	exx
	ld h,a					;reset acc2
	ld l,a
	ld d,a					;reset add2
	ld e,a
	exx
	add a,a
	ld (mod_alt2),a
	jp skipCh2
noteCh2:inc a
	exx
	ld d,a
	rra						;duty2 for squeeker
	rra
	rra
	and $0e
	add a,a
	inc a
	ld (sq_duty2),a
	ld a,d
	and $f0					;duty2 for tritone
	cp $80
	jp nz,$+5				;reset phase for ModPhase's non-zero W
	ld ixl,$80
	ld (tt_duty2),a
	ld (ttev_duty2),a
	ld (ttln_duty2),a
	ld (mod_alt2),a
	ld a,OP_SBCAA
	ld (mod_mute2),a
	
	jp z,noPhase2			;phase reset

phaseReset2=$+1
	ld a,0					;
	rla						;
	jr nc,noPhase2			;
	ld a,d					;
	and $f0					;
	sub $80					;to keep compatibility
	ld h,a					;set phase
	ld l,0					;
	
noPhase2:

	ld a,d
	and $0f
	ld d,a					;add2 msb
	exx
	
	ld a,(hl)
	inc hl
	
	exx
	ld e,a					;add2 lsb
	exx
	
skipCh2:

	ex (sp),hl				;get acc1, store song ptr

engineJump=$+1
	jp 0

	
	
;Engine 1: EarthShaker-alike

soundLoopES:

	add hl,de				;11
	
	jr nc,soundLoopES1S		;7/12-+
;	xor a					;4    |
	ld	a, 1

	and #08
	or  #20
	ld  (0xe007), a

	jp soundLoopES1			;10---+-32t
	
soundLoopES1S:	

	jp $+3					;10   |
	jp $+3					;10---+-32t
	
soundLoopES1:

	exx						;4
	
	add hl,de				;11
	jr nc,soundLoopES2S		;7/12
	ld a,c					;4		; djm 1

	and #08
	or  #20
	ld  (0xe007), a	
        jp soundLoopES2			;10
	
soundLoopES2S:

	jp $+3					;10
	jp $+3					;10
	
soundLoopES2:

	exx						;4
	
	dec  bc					;6
	ld   a,b				;4
	or   c					;4
	jr	nz,soundLoopES		;12=120t
	
;	in a,(14)				;check keyboard
;	cpl
;	and $1f
	jp playRow
	
;	jp stopPlayer

	
	
;Engine 2: Tritone-alike with two tone channels of uneven volume (33/87t)

soundLoopTT:

	add hl,de				;11
	
	ld a,h					;4
	
tt_duty1=$+1
	cp $80					;7
	
	sbc a,a					;4
	and 8					;7
	
	exx						;4
	
	add hl,de				;11
	

	and #08
	or  #20
	ld  (0xe007), a	
	ld a,h					;4
	
tt_duty2=$+1
	cp $80					;7

	sbc a,a					;4

	and #08
	or  #20
	ld  (0xe007), a
	exx						;4

	dec  bc					;6
	ld   a,b				;4
	or   c					;4
	jp	nz,soundLoopTT		;10=120t

;	in a,(14)				;check keyboard
;	cpl
;	and $1f
	jp playRow

;	jp stopPlayer
	
	
	
;Engine 3: Tritone-alike with two tone channels with even volumes (mostly, 58/62t)

soundLoopTTEV:

	add hl,de				;11
	
	ld a,h					;4
	
ttev_duty1=$+1
	cp $80					;7
	
	sbc a,a					;4

	and #08
	or  #20
	ld  (0xe007), a	
	exx						;4
	add hl,de				;11
	ld a,h					;4
	
ttev_duty2=$+1
	cp $80					;7

	sbc a,a					;4
	and 8					;7
	
	exx						;4

	dec  bc					;6

	and #08
	or  #20
	ld  (0xe007), a
	ld   a,b				;4
	or   c					;4
	jp	nz,soundLoopTTEV	;10=120t

;	in a,(14)				;check keyboard
;	cpl
;	and $1f
	jp playRow

;	jp stopPlayer
	
	
	
;Engine 4: Tritone-alike quiet tone channel, loud noise channel

soundLoopTTLN:

	add hl,de				;11
	
	rlc h					;8
	ld a,h					;4
	exx						;4
	and c					;4
	
	add hl,de				;11
	

	and #08
	or  #20
	ld  (0xe007), a	
	ld a,h					;4
	
ttln_duty2=$+1
	cp $80					;7

	sbc a,a					;4
	and c					;4

	and #08
	or  #20
	ld  (0xe007), a
	exx						;4

	ld a,r					;9	to align to 120t
	dec  bc					;6
	ld   a,b				;4
	or   c					;4
	jp	nz,soundLoopTTLN	;10=120t

;	in a,(14)				;check keyboard
;	cpl
;	and $1f
	jp playRow

;	jp stopPlayer
	
	
	
;Engine 5: Tritone-alike quiet noise channel, loud tone channel

soundLoopTTQN:

	add hl,de				;11
	
	ld a,h					;4
	
ttqn_duty1=$+1
	cp $80					;7

	sbc a,a					;4
	exx						;4
	and c					;4
	
	add hl,de				;11
	

	and #08
	or  #20
	ld  (0xe007), a
	rlc h					;8

	ld a,h					;4
	and c					;4

	and #08
	or  #20
	ld  (0xe007), a

	exx						;4

	ld a,r					;9	to align to 120t
	dec  bc					;6
	ld   a,b				;4
	or   c					;4
	jp	nz,soundLoopTTQN	;10=120t

;	in a,(14)				;check keyboard
;	cpl
;	and $1f
	jp playRow

;	jp stopPlayer
	

	
;Engine 6: Phaser-alike, single channel, two oscillators controlled directly

soundLoopPHA:
	exa						;4
    add hl,de      	 		;11
    jr c,$+4        		;7/12-+
    jr $+4          		;7/12 |
    xor 8         	 		;7   -+19t
	
	exx						;4
    add hl,de       		;11
    jr c,$+4       			;7/12-+
    jr $+4          		;7/12 |
    xor 8         	 		;7   -+19t
	

	and #08
	or  #20
	ld  (0xe007), a
	exx						;4
	exa						;4
	ld a,r					;9	to align to 120t
	dec  bc					;6
	ld   a,b				;4
	or   c					;4
	jp	nz,soundLoopPHA		;10=120t

;	in a,(14)				;check keyboard
;	cpl
;	and $1f
	jp playRow

;	jp stopPlayer
	
	
	
;Engine 7: Squeeker-alike, two tone channels with duty control
soundLoopSQ:
    ld a,c					;correct the loop counter for the double 8-bit counter
    dec bc
    inc b
	ld c,a
soundLoopSQ1:
	add hl,de				;11
	sbc a,a					;4
sq_duty1=$+1
	and 8*2					;7 (0..7 duty*2+1)

	exx						;4

	add a,b					;4
	ld b,a					;4
	
	add hl,de				;11
	sbc a,a					;4
sq_duty2=$+1
	and 8*2					;7
	add a,b					;4

	ld b,$ff				;7
	add a,b					;4
	sbc a,b					;4
	ld b,a					;4
	sbc a,a					;4
	and c					;4

	and #08
	or  #20
	ld  (0xe007), a	
        exx						;4
	nop						;4
	dec c					;4 double 8-bit loop counter
	jp nz,soundLoopSQ1		;10=120t
	dec b					;Sqeeker-like engines are much forgiving for floating loop times,
	jp nz,soundLoopSQ1		;so this is an acceptable compromise to fit the average loop time into 120t
;	in a,(14)				;check keyboard
;	cpl
;	and $1f
	jp playRow
;	jp stopPlayer
	
	
	
;Engine 8: CrossPhase, another PWM modulation engine similar to Phaser1, single channel, two oscillators controlled directly

soundLoopCPA:
    	add hl,de      	 		;11
	ld a,h					;4
	exx						;4
    	add hl,de       		;11
	cp h					;4
	exx						;4
	sbc a,a					;4

	and #08
	or  #20
	ld  (0xe007), a

	jr $+2					;12
	jr $+2					;12
	jr $+2					;12
	dec  bc					;6
	ld   a,b				;4
	or   c					;4
	jp	nz,soundLoopCPA		;10=120t
;	in a,(14)				;check keyboard
;	cpl
;	and $1f
	jp playRow
;	jp stopPlayer
	

;Engine 9: ModPhase, PWM modulation engine, two tone channels of uneven volume with a mod alteration control

soundLoopMOD:
    	ld a,c					;correct the loop counter for the double 8-bit counter
    	dec bc
    	inc b
	ld c,a
soundLoopMOD1:
    	add hl,de      	 		;11
	ld a,h					;4
mod_alt1=$+1
	xor 0					;7
	cp ixh					;8
mod_mute1=$
	sbc a,a					;4
	exx						;4
    	add hl,de      	 		;11

	and #08
	or  #20
	ld  (0xe007), a

	ld a,h					;4
mod_alt2=$+1
	xor 0					;7
	cp ixl					;8
mod_mute2=$
	sbc a,a					;4

	and #08
	or  #20
	ld  (0xe007), a

	exx						;4
	nop						;4
	nop						;4
	dec c					;4 double 8-bit loop counter
	jp nz,soundLoopMOD1		;10=120t
	inc ixh
	inc ixl
	dec b
	jp nz,soundLoopMOD1

;	in a,(14)				;check keyboard
;	cpl
;	and $1f
	jp playRow
;	jp stopPlayer
	
	
	
stopPlayer:

	pop hl					;song pointer/acc1 word, not needed anymore
	pop hl					;restore HL'
	exx
	pop iy
	ei
	ret

	
	
engineList:

	;engines 1,6,8 use the W column/top bits for phase reset, all others use it as duty cycle
	
	dw soundLoopES		;1 EarthShaker-alike
	dw soundLoopTT		;2 Tritone-alike with uneven volumes
	dw soundLoopTTEV	;3 Tritone-alike with equal volumes
	dw soundLoopTTLN	;4 Tritone-alike with quiet tone channel, loud noise channel
	dw soundLoopTTQN	;5 Tritone-alike with quiet noise channel, loud tone channel
	dw soundLoopPHA		;6 Phaser-alike (single channel)
	dw soundLoopSQ		;7 Squeeker-alike
	dw soundLoopCPA		;8 CrossPhase
	dw soundLoopMOD		;9 ModPhase
	
	
;C=drum param number

playDrum:

	push de
	push hl

	ld b,0
	ld h,b
	ld l,c
	srl c
	add hl,hl		;C already *2, another *2
	add hl,bc		;+1 to have *5
drumParam=$+1
	ld bc,0
	add hl,bc
	
	ld a,(hl)		;drum sample pointer, complete with precalculated offset
	ld (drumPtr+0),a
	inc hl
	ld a,(hl)
	ld (drumPtr+1),a
	inc hl
	ld a,(hl)		;frames to be played
	ld (drumFrames),a
	inc hl
	ld a,(hl)		;volume*3
	ld (drumVolume),a
	inc hl
	ld a,(hl)		;pitch*8
	ld (drumPitch),a

drumVolume=$+1
	ld a,0
	ld hl,volTable
	add a,l
	ld l,a
	jr nc,$+3
	inc h
	
	ld a,(hl)
	inc hl
	ld (drumVol01),a
	ld (drumVol11),a
	ld (drumVol21),a
	ld (drumVol31),a
	ld (drumVol41),a
	ld (drumVol51),a
	ld (drumVol61),a
	ld (drumVol71),a
	ld a,(hl)
	inc hl
	ld (drumVol02),a
	ld (drumVol12),a
	ld (drumVol22),a
	ld (drumVol32),a
	ld (drumVol42),a
	ld (drumVol52),a
	ld (drumVol62),a
	ld (drumVol72),a
	ld a,(hl)
	ld (drumVol03),a
	ld (drumVol13),a
	ld (drumVol23),a
	ld (drumVol33),a
	ld (drumVol43),a
	ld (drumVol53),a
	ld (drumVol63),a
	ld (drumVol73),a
		
drumPitch=$+1
	ld a,0
	ld hl,pitchTable
	add a,l
	ld l,a
	jr nc,$+3
	inc h
	
	ld a,(hl)
	inc hl
	ld (drumShift0),a
	ld a,(hl)
	inc hl
	ld (drumShift1),a
	ld a,(hl)
	inc hl
	ld (drumShift2),a
	ld a,(hl)
	inc hl
	ld (drumShift3),a
	ld a,(hl)
	inc hl
	ld (drumShift4),a
	ld a,(hl)
	inc hl
	ld (drumShift5),a
	ld a,(hl)
	inc hl
	ld (drumShift6),a
	ld a,(hl)
	ld (drumShift7),a
drumPtr=$+1
	ld hl,0
drumFrames=$+1
	ld b,0
	ld c,0
	ld d,1
drumLoop:		;bit 0
	ld a,(hl)				;7
	and d					;4
	jr nz,$+4				;7/12-+
	jr z,$+4				;7/12 |
	ld a,8    ;32   ;   $18				;7   -+19t

	and #08
	or  #20
	ld  (0xe007), a


drumVol01=$
	nop						;4

	and #08
	or  #20
	ld  (0xe007), a
	
drumVol02=$
	nop						;4


	and #08
	or  #20
	ld  (0xe007), a

drumShift0=$+1
	rlc d					;8
	nop						;4

drumVol03=$
	nop						;4


	and #08
	or  #20
	ld  (0xe007), a
	
	nop						;4
	nop						;4
	dec c					;4
	jp $+3					;10=120t
	
;bit 1

	ld a,(hl)				;7
	
	and d					;4
	jr nz,$+4				;7/12-+
	jr z,$+4				;7/12 |
	ld a,8   ;   $18				;7   -+19t


	and #08
	or  #20
	ld  (0xe007), a

drumVol11=$
	nop						;4

	and #08
	or  #20
	ld  (0xe007), a

drumVol12=$
	nop						;4

	and #08
	or  #20
	ld  (0xe007), a
drumShift1=$+1
	rlc d					;8
	nop						;4
	
drumVol13=$
	nop						;4

	and #08
	or  #20
	ld  (0xe007), a
	
	nop						;4
	nop						;4
	dec c					;4
	jp $+3					;10=120t
	
;bit 2

	ld a,(hl)				;7
	
	and d					;4
	jr nz,$+4				;7/12-+
	jr z,$+4				;7/12 |
	ld a,8     ; $18				;7   -+19t


	and #08
	or  #20
	ld  (0xe007), a


drumVol21=$
	nop						;4

	and #08
	or  #20
	ld  (0xe007), a

drumVol22=$
	nop						;4

	and #08
	or  #20
	ld  (0xe007), a

drumShift2=$+1
	rlc d					;8
	nop						;4
	
drumVol23=$
	nop						;4

	and #08
	or  #20
	ld  (0xe007), a
	
	nop						;4
	nop						;4
	dec c					;4
	jp $+3					;10=120t
	
;bit 3

	ld a,(hl)				;7
	
	and d					;4
	jr nz,$+4				;7/12-+
	jr z,$+4				;7/12 |
	ld a,8;32     ; $18				;7   -+19t


	and #08
	or  #20
	ld  (0xe007), a

drumVol31=$
	nop						;4

	and #08
	or  #20
	ld  (0xe007), a
	
drumVol32=$
	nop						;4

	and #08
	or  #20
	ld  (0xe007), a

drumShift3=$+1
	rlc d					;8
	nop						;4
	
drumVol33=$
	nop						;4

	and #08
	or  #20
	ld  (0xe007), a

	
	nop						;4
	nop						;4
	dec c					;4
	jp $+3					;10=120t
	
;bit 4

	ld a,(hl)				;7
	
	and d					;4
	jr nz,$+4				;7/12-+
	jr z,$+4				;7/12 |
	ld a,8    ;32     ; $18				;7   -+19t


	and #08
	or  #20
	ld  (0xe007), a

drumVol41=$
	nop						;4

	and #08
	or  #20
	ld  (0xe007), a
	
drumVol42=$
	nop						;4

	and #08
	or  #20
	ld  (0xe007), a
drumShift4=$+1

	rlc d					;8
	nop						;4
	
drumVol43=$
	nop						;4

	and #08
	or  #20
	ld  (0xe007), a
	
	nop						;4
	nop						;4
	dec c					;4
	jp $+3					;10=120t
	
;bit 5

	ld a,(hl)				;7
	
	and d					;4
	jr nz,$+4				;7/12-+
	jr z,$+4				;7/12 |
	ld a,8     ; $18				;7   -+19t


	and #08
	or  #20
	ld  (0xe007), a

drumVol51=$
	nop						;4


	and #08
	or  #20
	ld  (0xe007), a
	
drumVol52=$
	nop						;4

	and #08
	or  #20
	ld  (0xe007), a
drumShift5=$+1
	rlc d					;8
	nop						;4
	
drumVol53=$
	nop						;4

	and #08
	or  #20
	ld  (0xe007), a	
	nop						;4
	nop						;4
	dec c					;4
	jp $+3					;10=120t
	
;bit 6

	ld a,(hl)				;7
	
	and d					;4
	jr nz,$+4				;7/12-+
	jr z,$+4				;7/12 |
	ld a,8     ; $18				;7   -+19t


	and #08
	or  #20
	ld  (0xe007), a

drumVol61=$
	nop						;4

	and #08
	or  #20
	ld  (0xe007), a	
drumVol62=$
	nop						;4

	and #08
	or  #20
	ld  (0xe007), a

drumShift6=$+1
	rlc d					;8
	nop						;4

drumVol63=$
	nop						;4

	and #08
	or  #20
	ld  (0xe007), a
	
	nop						;4
	nop						;4
	dec c					;4
	jp $+3					;10=120t
	
;bit 7

	ld a,(hl)				;7
	
	and d					;4
	jr nz,$+4				;7/12-+
	jr z,$+4				;7/12 |
	ld a,8     ; $18				;7   -+19t


	and #08
	or  #20
	ld  (0xe007), a

drumVol71=$
	nop						;4

	and #08
	or  #20
	ld  (0xe007), a
	
drumVol72=$
	nop						;4

	and #08
	or  #20
	ld  (0xe007), a
drumShift7=$+1
	rlc d					;8
	nop						;4

drumVol73=$
	nop						;4

	and #08
	or  #20
	ld  (0xe007), a
	
	inc hl					;6
	jp $+3					;10
	dec c					;4
	jp nz,drumLoop			;10=128t a bit longer iteration
	
	nop						;4 aligned to 8t just in case
	dec b					;4
	jp nz,drumLoop			;10

	pop hl
	pop de

	ret
	
	
	
volTable:

	db OP_XORA,OP_NOP ,OP_NOP
	db OP_NOP ,OP_XORA,OP_NOP
	db OP_NOP ,OP_NOP ,OP_XORA
	db OP_NOP ,OP_NOP ,OP_NOP
		
pitchTable:

	db OP_NOP ,OP_NOP ,OP_NOP ,OP_NOP ,OP_NOP ,OP_NOP ,OP_NOP ,OP_NOP
	db OP_RLCD,OP_NOP ,OP_NOP ,OP_NOP ,OP_NOP ,OP_NOP ,OP_NOP ,OP_NOP
	db OP_RLCD,OP_NOP ,OP_NOP ,OP_NOP ,OP_RLCD,OP_NOP ,OP_NOP ,OP_NOP
	db OP_RLCD,OP_NOP ,OP_RLCD,OP_NOP ,OP_RLCD,OP_NOP ,OP_NOP ,OP_NOP
	db OP_RLCD,OP_NOP ,OP_RLCD,OP_NOP ,OP_RLCD,OP_NOP ,OP_RLCD,OP_NOP
	db OP_RLCD,OP_RLCD,OP_NOP ,OP_RLCD,OP_RLCD,OP_NOP ,OP_RLCD,OP_NOP
	db OP_RLCD,OP_RLCD,OP_RLCD,OP_NOP ,OP_RLCD,OP_RLCD,OP_RLCD,OP_NOP
	db OP_RLCD,OP_RLCD,OP_RLCD,OP_RLCD,OP_RLCD,OP_RLCD,OP_RLCD,OP_NOP
	db OP_RLCD,OP_RLCD,OP_RLCD,OP_RLCD,OP_RLCD,OP_RLCD,OP_RLCD,OP_RLCD


	include "TRACK11.INC"
