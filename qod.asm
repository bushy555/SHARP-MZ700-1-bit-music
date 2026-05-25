; QUANTUM OF DESTRUCTION by UTZ
;
; Squeeker Plus - VZ200 port
; ZX Spectrum beeper engine by utz, based on Squeeker by zilogat0r
; Microbee port: speaker output via OUT(2) - bit 2 by bushy555.
; MZ700 port:    speaker output via $E008  - bit 3 by bushy555.  sounds ok.  25/5/2026
; ZX             speaker output via OUT(FE)- bit 4. Original by Utz.
; VZ200 port:    speaker output via $6800  - bit 5 by bushy555.
;
;
; Register usage:
;   HL  = add counter ch1
;   DE  = add counter ch2
;   IX  = add counter ch3
;   IY  = add counter ch4
;   BC  = basefreq ch1-4
;   SP  = buffer pointer (music data)


	org	$5000

        out ($e0), a
	out ($e3), a
        ld hl,$e008 ;sound on
        ld (hl),1




init
		di
		exx
		push	hl			;preserve HL' for return to BASIC
		ld	(oldSP),sp
		ld	hl,musicData
		ld	(seqpntr),hl

;******************************************************************
rdseq
seqpntr		equ	$+1
		ld	sp,0
		xor	a
		pop	de			;pattern pointer to DE
		or	d
		ld	(seqpntr),sp
		jr	nz,rdptn0
		ld	sp,loop			;get loop point
		jr	rdseq+3

;******************************************************************
rdptn0
		ex	de,hl
		ld	sp,hl
		ld	iy,0
rdptn
		pop	af
		jr	z,rdseq
		ld	i,a
		exx
		pop	hl
		ld	a,h
		ld	(noise1),a
		ld	a,l
		ld	(noise2),a
		jr	c,ld2
		pop	hl
		ld	(fch1),hl
		pop	hl
		ld	(envset1),hl
		ld	a,(hl)
		ld	(duty1),a
		exx
		ld	hl,0
		exx
ld2
		jp	pe,ld3
		pop	hl
		ld	(fch2),hl
		pop	hl
		ld	(envset2),hl
		ld	a,(hl)
		ld	(duty2),a
		exx
		ld	de,0
		exx
ld3
		jp	m,ld4
		pop	hl
		ld	(fch3),hl
		pop	hl
		ld	(envset3),hl
		ld	a,(hl)
		ld	(duty3),a
		ld	ix,0
ld4
		pop	af
		jr	z,ldx
		pop	hl
		ld	(fch4),hl		;freq 4
		ld	iy,0
		ld	de,0
		ld	a,slideskip-jrcalc-1
		jr	nc,nokick
		ld	a,d			;A=0
		ex	de,hl
nokick
		ld	(jrcalc),a
		pop	hl
		ld	(envset4),hl
		ld	a,(hl)
		ld	(duty4),a
ldx
		jp	pe,drum1
		jp	m,drum2
		xor	a
		ld	c,a
drumret
		ex	af,af'
		ld	b,$80
		exx

;******************************************************************
playNote
fch1		equ	$+1
		ld	bc,0			;10
		add	hl,bc			;11
noise1
		db	$00,$04			;8  (replaced with $CB,$04 = rlc h, for noise)
duty1		equ	$+1
		ld	a,0			;7
		add	a,h			;4
		exx				;4
		rl	c			;8
		exx				;4
		ex	de,hl			;4
fch2		equ	$+1
		ld	bc,0			;10
		add	hl,bc			;11
noise2
		db	$00,$04			;8
duty2		equ	$+1
		ld	a,0			;7
		add	a,h			;4
		ex	de,hl			;4
		exx				;4
		rl	c			;8
		exx				;4
fch3		equ	$+1
		ld	bc,0			;10
		add	ix,bc			;15
duty3		equ	$+1
		ld	a,0			;7
		add	a,ixh			;8
		exx				;4
		rl	c			;8
		exx				;4
fch4		equ	$+1
		ld	bc,0			;10
		add	iy,bc			;15
duty4		equ	$+1
		ld	a,0			;7
		add	a,iyh			;8
		exx				;4
		ld	a,$0F			;7
		adc	a,c			;4
		ld	c,0			;7
		exx				;4
;		and	$10			;VZ200: isolate bit 4
;		add	a,a			;VZ200: shift to bit 5
;		ld	($6800),a		;VZ200: write to latch

	and #08					; MZ700
	or  #20					; MZ700
	ld  (0xe007), a				; MZ700


		ex	af,af'			;4
		dec	a			;4
		jp	z,updateTimer		;10
		ex	af,af'			;4
		ex	(sp),hl			;19
		ex	(sp),hl			;19
		ex	(sp),hl			;19
		ex	(sp),hl			;19
		jp	playNote		;10

;******************************************************************
updateTimer
		ex	af,af'
		exx
envset1		equ	$+1			;update duty envelope pointers
		ld	hl,0
		inc	hl
		ld	a,(hl)
		cp	b			;check for envelope end (b=$80)
		jr	z,e2
		ld	(duty1),a
		ld	(envset1),hl
e2
envset2		equ	$+1
		ld	hl,0
		inc	hl
		ld	a,(hl)
		cp	b
		jr	z,e3
		ld	(duty2),a
		ld	(envset2),hl
e3
envset3		equ	$+1
		ld	hl,0
		inc	hl
		ld	a,(hl)
		cp	b
		jr	z,e4
		ld	(duty3),a
		ld	(envset3),hl
e4
envset4		equ	$+1
		ld	hl,0
		inc	hl
		ld	a,(hl)
		cp	b
		jr	z,eex
		ld	(duty4),a
		ld	(envset4),hl
eex
jrcalc		equ	$+1
		jr	slideskip
		ld	hl,(fch4)		;update ch4 pitch slide
		srl	d
		rr	e
		sbc	hl,de
		ld	(fch4),hl
		ld	iy,0
slideskip
		exx
		ld	a,i
		dec	a
		jp	z,rdptn
		ld	i,a
		jp	playNote

;******************************************************************
exit
oldSP		equ	$+1
		ld	sp,0
		pop	hl
		exx
		ei
		ret

;******************************************************************
drum2
		ld	hl,hat1
		ld	b,hat1end-hat1
		jr	drentry
drum1
		ld	hl,kick1		;10
		ld	b,kick1end-kick1	;7
drentry
		xor	a			;4
_s2
;		xor	$20			;7  toggle bit5 (speaker bit) directly
	xor 	8
		ld	c,(hl)			;7
		inc	hl			;6
_s1
;		ld	($6800),a		;VZ200: write to latch

	and #08					; MZ700
	or  #20					; MZ700
	ld  (0xe007), a				; MZ700

		dec	c			;4
		jr	nz,_s1			;12/7
		djnz	_s2			;13/8
		ld	a,$6D			;7  correct tempo
		jp	drumret			;10

kick1
		ds	4,$10
		ds	4,$20
		ds	4,$40
		ds	4,$80
		ds	4,$00
kick1end

hat1
		db	$10,$03,$0C,$06,$09,$14,$04,$08,$02,$0E,$09,$11,$05,$08,$0C,$04
		db	$07,$10,$0D,$16,$05,$03,$10,$03,$0C,$06,$09,$14,$04,$08,$02,$0E
		db	$09,$11,$05,$08,$0C,$04,$07,$10,$0D,$16,$05,$03,$0C,$08,$01,$18
		db	$06,$07,$04,$09,$12,$0C,$08,$03,$0B,$07,$05,$08,$03,$11,$09,$0F
		db	$16,$06,$05,$08,$0B,$0D,$04,$08,$0C,$09,$02,$04,$07,$08,$0C,$06
		db	$07,$04,$13,$16,$01,$09,$06,$1B,$04,$03,$0B,$05,$08,$0E,$02,$0B
		db	$0D,$05,$09,$02,$11,$0A,$03,$07,$13,$04,$03,$08,$02,$09,$0B,$04
		db	$11,$06,$04,$09,$0E,$02,$16,$08,$04,$13,$02,$03,$05,$0B,$01,$10
		db	$14,$04,$07,$08,$09,$04,$0C,$02,$08,$0E,$03,$07,$07,$0D,$09,$0F
		db	$01,$08,$04,$11,$03,$16,$04,$08,$0B,$04,$15,$09,$06,$0C,$04,$03
		db	$08,$07,$11,$05,$09,$02,$0B,$11,$04,$09,$03,$02,$16,$04,$07,$03
		db	$08,$09,$04,$0B,$08,$05,$09,$02,$06,$02,$08,$08,$03,$0B,$05,$03
		db	$09,$06,$07,$04,$08
hat1end

env0
		db	$00,$80

musicData
loop
		;sequence table
		dw	ptn14
		dw	ptn2
		dw	ptn0
		dw	ptn3
		dw	ptn1
		dw	ptn8
		dw	ptn9
		dw	ptn10
		dw	ptn11
		dw	ptn12
		dw	ptn11
		dw	ptn13
		dw	ptn4
		dw	ptn5
		dw	ptn6
		dw	ptn7
		dw	ptn16
		dw	ptn17
		dw	ptn15
		dw	$0000			;end of sequence

		;==== Pattern Data ====

ptn0
		dw	$0300,$0000,$0A14,envE,$06BA,envE,$01AE,envF,$0005,$06BA,envS_40
		dw	$0385,$0000,$0005,$06BA,envS_40
		dw	$0385,$0000,$0005,$06BA,envS_40
		dw	$0380,$0000,$0A14,envE,$06BA,envE,$0000,$0000,env0
		dw	$0385,$0000,$0040
		dw	$0385,$0000,$0040
		dw	$0380,$0000,$0A14,envE,$06BA,envE,$0005,$06BA,envS_40
		dw	$0385,$0000,$0005,$06BA,envS_40
		dw	$0385,$0000,$0001,$06BA,envS_40
		dw	$0380,$0000,$0A14,envE,$06BA,envE,$0000,$0000,env0
		dw	$0385,$0000,$0005,$06BA,envS_40
		dw	$0385,$0000,$0005,$06BA,envS_40
		dw	$0380,$0000,$0A14,envE,$06BA,envE,$0005,$06BA,envS_40
		dw	$0380,$0000,$0AAE,envE,$0721,envE,$0000,$0000,env0
		dw	$0385,$0000,$0005,$06BA,envS_40
		dw	$0385,$0000,$0000,$0000,env0
		dw	$0380,$0000,$0A14,envE,$087A,envE,$0005,$06BA,envS_40
		dw	$0385,$0000,$0005,$06BA,envS_40
		dw	$0385,$0000,$0005,$06BA,envS_40
		dw	$0380,$0000,$0A14,envE,$087A,envE,$0000,$0000,env0
		dw	$0385,$0000,$0040
		dw	$0385,$0000,$0040
		dw	$0380,$0000,$0A14,envE,$087A,envE,$0005,$06BA,envS_40
		dw	$0385,$0000,$0005,$06BA,envS_40
		dw	$0385,$0000,$0001,$06BA,envS_40
		dw	$0380,$0000,$0A14,envE,$087A,envE,$0000,$0000,env0
		dw	$0385,$0000,$0005,$06BA,envS_40
		dw	$0385,$0000,$0005,$06BA,envS_40
		dw	$0380,$0000,$0A14,envE,$087A,envE,$0005,$06BA,envS_40
		dw	$0380,$0000,$0AAE,envE,$0721,envE,$0000,$0000,env0
		dw	$0385,$0000,$0005,$06BA,envS_40
		dw	$0385,$0000,$0000,$0000,env0
		dw	$0380,$0000,$0AAE,envE,$08FB,envE,$0005,$06BA,envS_40
		dw	$0385,$0000,$0005,$06BA,envS_40
		dw	$0385,$0000,$0005,$06BA,envS_40
		dw	$0380,$0000,$0AAE,envE,$08FB,envE,$0000,$0000,env0
		dw	$0385,$0000,$0040
		dw	$0385,$0000,$0040
		dw	$0380,$0000,$0AAE,envE,$08FB,envE,$0005,$06BA,envS_40
		dw	$0385,$0000,$0005,$06BA,envS_40
		dw	$0385,$0000,$0001,$06BA,envS_40
		dw	$0380,$0000,$0AAE,envE,$08FB,envE,$0000,$0000,env0
		dw	$0385,$0000,$0005,$06BA,envS_40
		dw	$0385,$0000,$0005,$06BA,envS_40
		dw	$0380,$0000,$0AAE,envE,$08FB,envE,$0005,$06BA,envS_40
		dw	$0380,$0000,$0A14,envE,$087A,envE,$0000,$0000,env0
		dw	$0385,$0000,$0005,$06BA,envS_40
		dw	$0385,$0000,$0000,$0000,env0
		dw	$0380,$0000,$0A14,envE,$0721,envE,$0005,$06BA,envS_40
		dw	$0380,$0000,$0A14,envE,$0721,envE,$0005,$06BA,envS_40
		dw	$0380,$0000,$0A14,envE,$0721,envE,$0005,$06BA,envS_40
		dw	$0385,$0000,$0000,$0000,env0
		dw	$0385,$0000,$0044
		dw	$0385,$0000,$0044
		dw	$0380,$0000,$0A14,envE,$0721,envE,$0005,$06BA,envS_40
		dw	$0380,$0000,$0A14,envE,$0721,envE,$0001,$06BA,envS_40
		dw	$0380,$0000,$0A14,envE,$0721,envE,$0005,$06BA,envS_40
		dw	$0385,$0000,$0004,$0000,env0
		dw	$0380,$0000,$0721,envE,$06BA,envE,$0081,$06BA,envS_40
		dw	$0380,$0000,$0721,envE,$06BA,envE,$0001,$06BA,envS_40
		dw	$0380,$0000,$0721,envE,$06BA,envE,$0005,$06BA,envS_40
		dw	$0385,$0000,$0004,$0000,env0
		dw	$0385,$0000,$0081,$06BA,envS_40
		dw	$0385,$0000,$0000,$0000,env0
		dw	$0040

ptn1
		dw	$0300,$0000,$0E41,envH,$06BA,envE,$01AE,envF,$0005,$06BA,envS_40
		dw	$0384,$0000,$10F4,envH,$0005,$06BA,envS_40
		dw	$0384,$0000,$0E41,envH,$0005,$06BA,envS_40
		dw	$0300,$0000,$0D74,envH,$06BA,envE,$01AE,envF,$0000,$0000,env0
		dw	$0385,$0000,$0040
		dw	$0385,$0000,$0040
		dw	$0300,$0000,$0D74,envH,$06BA,envE,$01AE,envF,$0005,$06BA,envS_40
		dw	$0385,$0000,$0005,$06BA,envS_40
		dw	$0384,$0000,$1429,envH,$0081,$06BA,envS_40
		dw	$0301,$0000,$06BA,envE,$01AE,envF,$0000,$0000,env0
		dw	$0384,$0000,$0D74,envH,$0005,$06BA,envS_40
		dw	$0385,$0000,$0005,$06BA,envS_40
		dw	$0300,$0000,$155C,envH,$06BA,envE,$01AE,envF,$0005,$06BA,envS_40
		dw	$0301,$0000,$0721,envE,$01C8,envF,$0000,$0000,env0
		dw	$0384,$0000,$0D74,envH,$0005,$06BA,envS_40
		dw	$0385,$0000,$0000,$0000,env0
		dw	$0300,$0000,$17F9,envH,$087A,envE,$01AE,envF,$0005,$06BA,envS_40
		dw	$0385,$0000,$0005,$06BA,envS_40
		dw	$0384,$0000,$0D74,envH,$0005,$06BA,envS_40
		dw	$0301,$0000,$087A,envE,$01AE,envF,$0000,$0000,env0
		dw	$0384,$0000,$155C,envH,$0040
		dw	$0385,$0000,$0040
		dw	$0300,$0000,$0D74,envH,$087A,envE,$01AE,envF,$0005,$06BA,envS_40
		dw	$0385,$0000,$0005,$06BA,envS_40
		dw	$0384,$0000,$155C,envH,$0081,$06BA,envS_40
		dw	$0301,$0000,$087A,envE,$01AE,envF,$0000,$0000,env0
		dw	$0384,$0000,$0D74,envH,$0005,$06BA,envS_40
		dw	$0385,$0000,$0005,$06BA,envS_40
		dw	$0300,$0000,$1429,envH,$087A,envE,$023F,envF,$0005,$06BA,envS_40
		dw	$0301,$0000,$0721,envE,$01C8,envF,$0000,$0000,env0
		dw	$0384,$0000,$0D74,envH,$0005,$06BA,envS_40
		dw	$0385,$0000,$0000,$0000,env0
		dw	$0300,$0000,$1429,envH,$08FB,envE,$01AE,envF,$0005,$06BA,envS_40
		dw	$0384,$0000,$155C,envH,$0005,$06BA,envS_40
		dw	$0384,$0000,$1429,envH,$0005,$06BA,envS_40
		dw	$0300,$0000,$11F6,envH,$08FB,envE,$01AE,envF,$0000,$0000,env0
		dw	$0384,$0000,$1429,envH,$0040
		dw	$0385,$0000,$0040
		dw	$0300,$0000,$0D74,envH,$08FB,envE,$01AE,envF,$0005,$06BA,envS_40
		dw	$0385,$0000,$0005,$06BA,envS_40
		dw	$0384,$0000,$10F4,envH,$0081,$06BA,envS_40
		dw	$0301,$0000,$08FB,envE,$01AE,envF,$0000,$0000,env0
		dw	$0384,$0000,$0D74,envH,$0005,$06BA,envS_40
		dw	$0385,$0000,$0005,$06BA,envS_40
		dw	$0300,$0000,$0E41,envH,$08FB,envE,$01AE,envF,$0005,$06BA,envS_40
		dw	$0301,$0000,$087A,envE,$01C8,envF,$0000,$0000,env0
		dw	$0384,$0000,$0D74,envH,$0005,$06BA,envS_40
		dw	$0385,$0000,$0000,$0000,env0
		dw	$0300,$0000,$10F4,envH,$0721,envE,$0261,envF,$0005,$06BA,envS_40
		dw	$0301,$0000,$0721,envE,$0261,envF,$0005,$06BA,envS_40
		dw	$0300,$0000,$0D74,envH,$0721,envE,$0261,envF,$0005,$06BA,envS_40
		dw	$0385,$0000,$0000,$0000,env0
		dw	$0384,$0000,$0E41,envH,$0005,$06BA,envS_40
		dw	$0385,$0000,$0005,$06BA,envS_40
		dw	$0300,$0000,$0D74,envH,$0721,envE,$0261,envF,$0005,$06BA,envS_40
		dw	$0301,$0000,$0721,envE,$0261,envF,$0000,$0000,env0
		dw	$0300,$0000,$0E41,envH,$0721,envE,$0261,envF,$0005,$06BA,envS_40
		dw	$0385,$0000,$0005,$06BA,envS_40
		dw	$0300,$0000,$0D74,envH,$06BA,envE,$023F,envF,$0081,$06BA,envS_40
		dw	$0301,$0000,$06BA,envE,$023F,envF,$0000,$0000,env0
		dw	$0300,$0000,$0BFD,envH,$06BA,envE,$023F,envF,$0005,$06BA,envS_40
		dw	$0384,$0000,$0D74,envH,$0005,$06BA,envS_40
		dw	$0384,$0000,$0E41,envH,$0081,$06BA,envS_40
		dw	$0384,$0000,$10F4,envH,$0000,$0000,env0
		dw	$0040

ptn2
		dw	$0300,$0000,$0A14,envE,$06BA,envE,$01AE,envF,$0000,$0000,env0
		dw	$0385,$0000,$0040
		dw	$0385,$0000,$0040
		dw	$0380,$0000,$0A14,envE,$06BA,envE,$0040
		dw	$0385,$0000,$0040
		dw	$0385,$0000,$0040
		dw	$0380,$0000,$0A14,envE,$06BA,envE,$0040
		dw	$0385,$0000,$0040
		dw	$0385,$0000,$0040
		dw	$0380,$0000,$0A14,envE,$06BA,envE,$0040
		dw	$0385,$0000,$0040
		dw	$0385,$0000,$0040
		dw	$0380,$0000,$0A14,envE,$06BA,envE,$0040
		dw	$0380,$0000,$0AAE,envE,$0721,envE,$0040
		dw	$0385,$0000,$0040
		dw	$0385,$0000,$0040
		dw	$0380,$0000,$0A14,envE,$087A,envE,$0040
		dw	$0385,$0000,$0040
		dw	$0385,$0000,$0040
		dw	$0380,$0000,$0A14,envE,$087A,envE,$0040
		dw	$0385,$0000,$0040
		dw	$0385,$0000,$0040
		dw	$0380,$0000,$0A14,envE,$087A,envE,$0040
		dw	$0385,$0000,$0040
		dw	$0385,$0000,$0040
		dw	$0380,$0000,$0A14,envE,$087A,envE,$0040
		dw	$0385,$0000,$0040
		dw	$0385,$0000,$0040
		dw	$0380,$0000,$0A14,envE,$087A,envE,$0040
		dw	$0380,$0000,$0AAE,envE,$0721,envE,$0040
		dw	$0385,$0000,$0040
		dw	$0385,$0000,$0040
		dw	$0380,$0000,$0AAE,envE,$08FB,envE,$0040
		dw	$0385,$0000,$0040
		dw	$0385,$0000,$0040
		dw	$0380,$0000,$0AAE,envE,$08FB,envE,$0040
		dw	$0385,$0000,$0040
		dw	$0385,$0000,$0040
		dw	$0380,$0000,$0AAE,envE,$08FB,envE,$0040
		dw	$0385,$0000,$0040
		dw	$0385,$0000,$0040
		dw	$0380,$0000,$0AAE,envE,$08FB,envE,$0040
		dw	$0385,$0000,$0040
		dw	$0385,$0000,$0040
		dw	$0380,$0000,$0AAE,envE,$08FB,envE,$0040
		dw	$0380,$0000,$0A14,envE,$087A,envE,$0040
		dw	$0385,$0000,$0040
		dw	$0385,$0000,$0040
		dw	$0380,$0000,$0A14,envE,$087A,envE,$0040
		dw	$0385,$0000,$0040
		dw	$0385,$0000,$0040
		dw	$0380,$0000,$0A14,envE,$087A,envE,$0040
		dw	$0385,$0000,$0040
		dw	$0385,$0000,$0040
		dw	$0380,$0000,$0A14,envE,$087A,envE,$0040
		dw	$0385,$0000,$0040
		dw	$0385,$0000,$0040
		dw	$0380,$0000,$0A14,envE,$087A,envE,$0040
		dw	$0385,$0000,$0040
		dw	$0385,$0000,$0040
		dw	$0380,$0000,$0A14,envE,$087A,envE,$0040
		dw	$0380,$0000,$0AAE,envE,$0721,envE,$0040
		dw	$0385,$0000,$0040
		dw	$0385,$0000,$0040
		dw	$0040

ptn3
		dw	$0300,$0000,$1AE9,envH,$06BA,envE,$01AE,envF,$0005,$06BA,envS_40
		dw	$0384,$0000,$17F9,envH,$0005,$06BA,envS_40
		dw	$0384,$0000,$155C,envH,$0005,$06BA,envS_40
		dw	$0300,$0000,$1429,envH,$06BA,envE,$01AE,envF,$0000,$0000,env0
		dw	$0385,$0000,$0040
		dw	$0385,$0000,$0040
		dw	$0300,$0000,$0D74,envH,$06BA,envE,$01AE,envF,$0005,$06BA,envS_40
		dw	$0385,$0000,$0005,$06BA,envS_40
		dw	$0384,$0000,$1429,envH,$0081,$06BA,envS_40
		dw	$0301,$0000,$06BA,envE,$01AE,envF,$0000,$0000,env0
		dw	$0384,$0000,$0D74,envH,$0005,$06BA,envS_40
		dw	$0385,$0000,$0005,$06BA,envS_40
		dw	$0300,$0000,$155C,envH,$06BA,envE,$01AE,envF,$0005,$06BA,envS_40
		dw	$0301,$0000,$0721,envE,$01C8,envF,$0000,$0000,env0
		dw	$0384,$0000,$0D74,envH,$0005,$06BA,envS_40
		dw	$0385,$0000,$0000,$0000,env0
		dw	$0300,$0000,$17F9,envH,$087A,envE,$01AE,envF,$0005,$06BA,envS_40
		dw	$0385,$0000,$0005,$06BA,envS_40
		dw	$0384,$0000,$0D74,envH,$0005,$06BA,envS_40
		dw	$0301,$0000,$087A,envE,$01AE,envF,$0000,$0000,env0
		dw	$0384,$0000,$155C,envH,$0040
		dw	$0385,$0000,$0040
		dw	$0300,$0000,$0D74,envH,$087A,envE,$01AE,envF,$0005,$06BA,envS_40
		dw	$0385,$0000,$0005,$06BA,envS_40
		dw	$0384,$0000,$155C,envH,$0081,$06BA,envS_40
		dw	$0301,$0000,$087A,envE,$01AE,envF,$0000,$0000,env0
		dw	$0384,$0000,$0D74,envH,$0005,$06BA,envS_40
		dw	$0385,$0000,$0005,$06BA,envS_40
		dw	$0300,$0000,$1429,envH,$087A,envE,$023F,envF,$0005,$06BA,envS_40
		dw	$0301,$0000,$0721,envE,$01C8,envF,$0000,$0000,env0
		dw	$0384,$0000,$0D74,envH,$0005,$06BA,envS_40
		dw	$0385,$0000,$0000,$0000,env0
		dw	$0300,$0000,$1429,envH,$08FB,envE,$01AE,envF,$0005,$06BA,envS_40
		dw	$0384,$0000,$155C,envH,$0005,$06BA,envS_40
		dw	$0384,$0000,$1429,envH,$0005,$06BA,envS_40
		dw	$0300,$0000,$11F6,envH,$08FB,envE,$01AE,envF,$0000,$0000,env0
		dw	$0384,$0000,$1429,envH,$0040
		dw	$0385,$0000,$0040
		dw	$0300,$0000,$0D74,envH,$08FB,envE,$01AE,envF,$0005,$06BA,envS_40
		dw	$0385,$0000,$0005,$06BA,envS_40
		dw	$0384,$0000,$10F4,envH,$0081,$06BA,envS_40
		dw	$0301,$0000,$08FB,envE,$01AE,envF,$0000,$0000,env0
		dw	$0384,$0000,$0D74,envH,$0005,$06BA,envS_40
		dw	$0385,$0000,$0005,$06BA,envS_40
		dw	$0300,$0000,$11F6,envH,$08FB,envE,$01AE,envF,$0005,$06BA,envS_40
		dw	$0301,$0000,$087A,envE,$01C8,envF,$0000,$0000,env0
		dw	$0384,$0000,$0D74,envH,$0005,$06BA,envS_40
		dw	$0385,$0000,$0000,$0000,env0
		dw	$0300,$0000,$10F4,envH,$087A,envE,$01AE,envF,$0005,$06BA,envS_40
		dw	$0385,$0000,$0005,$06BA,envS_40
		dw	$0384,$0000,$0D74,envH,$0005,$06BA,envS_40
		dw	$0301,$0000,$087A,envE,$01AE,envF,$0000,$0000,env0
		dw	$0384,$0000,$0E41,envH,$0044
		dw	$0385,$0000,$0044
		dw	$0300,$0000,$0D74,envH,$087A,envE,$01AE,envF,$0005,$06BA,envS_40
		dw	$0385,$0000,$0001,$06BA,envS_40
		dw	$0384,$0000,$11F6,envH,$0005,$06BA,envS_40
		dw	$0301,$0000,$087A,envE,$01AE,envF,$0004,$0000,env0
		dw	$0384,$0000,$0D74,envH,$0081,$06BA,envS_40
		dw	$0385,$0000,$0001,$06BA,envS_40
		dw	$0300,$0000,$10F4,envH,$087A,envE,$01AE,envF,$0005,$06BA,envS_40
		dw	$0301,$0000,$0721,envE,$01C8,envF,$0004,$0000,env0
		dw	$0384,$0000,$0D74,envH,$0081,$06BA,envS_40
		dw	$0385,$0000,$0000,$0000,env0
		dw	$0040

ptn4
		dw	$0300,$00CB,$06BA,envC,$2175,envA,$01AE,envB,$0004,$0000,env0
		dw	$0305,$00CB,$01AE,envB,$0044
		dw	$0304,$00CB,$0721,envC,$01AE,envB,$0044
		dw	$0305,$00CB,$0000,env0,$0040
		dw	$0384,$00CB,$087A,envC,$0040
		dw	$0385,$00CB,$0040
		dw	$0300,$00CB,$08FB,envC,$2175,envA,$01AE,envB,$0044
		dw	$0305,$00CB,$01AE,envB,$0044
		dw	$0304,$00CB,$0A14,envC,$01AE,envB,$0044
		dw	$0305,$00CB,$0000,env0,$0040
		dw	$0300,$00CB,$0AAE,envC,$2175,envA,$01AE,envB,$0044
		dw	$0305,$00CB,$01AE,envB,$0044
		dw	$0304,$00CB,$0A14,envC,$01AE,envB,$0044
		dw	$0305,$00CB,$0000,env0,$0040
		dw	$0300,$00CB,$08FB,envC,$2175,envD,$01AE,envB,$0044
		dw	$0301,$00CB,$2175,envD,$0000,env0,$0040
		dw	$0300,$00CB,$087A,envC,$2175,envA,$01AE,envB,$0044
		dw	$0305,$00CB,$01AE,envB,$0044
		dw	$0304,$00CB,$08FB,envC,$01AE,envB,$0044
		dw	$0305,$00CB,$0000,env0,$0040
		dw	$0384,$00CB,$087A,envC,$0040
		dw	$0385,$00CB,$0040
		dw	$0300,$00CB,$0721,envC,$2175,envA,$01AE,envB,$0044
		dw	$0305,$00CB,$01AE,envB,$0044
		dw	$0304,$00CB,$08FB,envC,$01AE,envB,$0044
		dw	$0305,$00CB,$0000,env0,$0040
		dw	$0300,$00CB,$087A,envC,$2175,envA,$01AE,envB,$0044
		dw	$0305,$00CB,$01AE,envB,$0044
		dw	$0300,$00CB,$0721,envC,$2175,envA,$01AE,envB,$0044
		dw	$0305,$00CB,$0000,env0,$0040
		dw	$0300,$00CB,$087A,envC,$2175,envA,$01AE,envB,$0044
		dw	$0305,$00CB,$0000,env0,$0040
		dw	$0300,$00CB,$06BA,envC,$2175,envA,$01AE,envB,$0004,$035D,envC
		dw	$0305,$00CB,$01AE,envB,$0044
		dw	$0304,$00CB,$0721,envC,$01AE,envB,$0004,$0390,envC
		dw	$0305,$00CB,$0000,env0,$0040
		dw	$0384,$00CB,$087A,envC,$0000,$043D,envC
		dw	$0385,$00CB,$0040
		dw	$0300,$00CB,$08FB,envC,$2175,envA,$01AE,envB,$0004,$047D,envC
		dw	$0305,$00CB,$01AE,envB,$0044
		dw	$0304,$00CB,$0A14,envC,$01AE,envB,$0004,$050A,envC
		dw	$0305,$00CB,$0000,env0,$0040
		dw	$0300,$00CB,$0AAE,envC,$2175,envA,$01AE,envB,$0004,$0557,envC
		dw	$0305,$00CB,$01AE,envB,$0044
		dw	$0304,$00CB,$0A14,envC,$01AE,envB,$0004,$050A,envC
		dw	$0305,$00CB,$0000,env0,$0040
		dw	$0300,$00CB,$08FB,envC,$2175,envA,$01AE,envB,$0004,$047D,envC
		dw	$0305,$00CB,$0000,env0,$0040
		dw	$0300,$00CB,$087A,envC,$2175,envA,$01AE,envB,$0004,$043D,envC
		dw	$0305,$00CB,$01AE,envB,$0044
		dw	$0304,$00CB,$08FB,envC,$01AE,envB,$0004,$047D,envC
		dw	$0305,$00CB,$0000,env0,$0040
		dw	$0384,$00CB,$087A,envC,$0000,$043D,envC
		dw	$0385,$00CB,$0040
		dw	$0300,$00CB,$0721,envC,$2175,envA,$01AE,envB,$0004,$0390,envC
		dw	$0305,$00CB,$01AE,envB,$0044
		dw	$0304,$00CB,$06BA,envC,$01AE,envB,$0004,$035D,envC
		dw	$0305,$00CB,$0000,env0,$0040
		dw	$0301,$00CB,$2175,envA,$01AE,envB,$0044
		dw	$0305,$00CB,$01AE,envB,$0044
		dw	$0301,$00CB,$2175,envA,$01AE,envB,$0044
		dw	$0305,$00CB,$0000,env0,$0040
		dw	$0301,$00CB,$2175,envA,$01AE,envB,$0044
		dw	$0305,$00CB,$0000,env0,$0040
		dw	$0040

ptn5
		dw	$0300,$00CB,$06BA,envC,$2175,envA,$01AE,envB,$0004,$0000,env0
		dw	$0305,$00CB,$01AE,envB,$0044
		dw	$0304,$00CB,$0721,envC,$01AE,envB,$0044
		dw	$0305,$00CB,$0000,env0,$0040
		dw	$0384,$00CB,$087A,envC,$0040
		dw	$0385,$00CB,$0040
		dw	$0300,$00CB,$08FB,envC,$2175,envA,$01AE,envB,$0044
		dw	$0305,$00CB,$01AE,envB,$0044
		dw	$0304,$00CB,$0A14,envC,$01AE,envB,$0044
		dw	$0305,$00CB,$0000,env0,$0040
		dw	$0300,$00CB,$0AAE,envC,$2175,envA,$01AE,envB,$0044
		dw	$0305,$00CB,$01AE,envB,$0044
		dw	$0304,$00CB,$0A14,envC,$01AE,envB,$0044
		dw	$0305,$00CB,$0000,env0,$0040
		dw	$0300,$00CB,$08FB,envC,$2175,envD,$01AE,envB,$0044
		dw	$0301,$00CB,$2175,envD,$0000,env0,$0040
		dw	$0300,$00CB,$087A,envC,$2175,envA,$01AE,envB,$0044
		dw	$0305,$00CB,$01AE,envB,$0044
		dw	$0304,$00CB,$08FB,envC,$01AE,envB,$0044
		dw	$0305,$00CB,$0000,env0,$0040
		dw	$0384,$00CB,$087A,envC,$0040
		dw	$0385,$00CB,$0040
		dw	$0300,$00CB,$0721,envC,$2175,envA,$01AE,envB,$0044
		dw	$0305,$00CB,$01AE,envB,$0044
		dw	$0304,$00CB,$08FB,envC,$01AE,envB,$0044
		dw	$0305,$00CB,$0000,env0,$0040
		dw	$0300,$00CB,$087A,envC,$2175,envA,$01AE,envB,$0044
		dw	$0305,$00CB,$01AE,envB,$0044
		dw	$0300,$00CB,$0721,envC,$2175,envA,$01AE,envB,$0044
		dw	$0305,$00CB,$0000,env0,$0040
		dw	$0300,$00CB,$087A,envC,$2175,envA,$01AE,envB,$0044
		dw	$0305,$00CB,$0000,env0,$0040
		dw	$0300,$00CB,$06BA,envC,$2175,envA,$01AE,envB,$0004,$035D,envC
		dw	$0305,$00CB,$01AE,envB,$0044
		dw	$0304,$00CB,$0721,envC,$01AE,envB,$0004,$0390,envC
		dw	$0305,$00CB,$0000,env0,$0040
		dw	$0384,$00CB,$087A,envC,$0000,$043D,envC
		dw	$0385,$00CB,$0040
		dw	$0300,$00CB,$08FB,envC,$2175,envA,$01AE,envB,$0004,$047D,envC
		dw	$0305,$00CB,$01AE,envB,$0044
		dw	$0304,$00CB,$0A14,envC,$01AE,envB,$0004,$050A,envC
		dw	$0305,$00CB,$0000,env0,$0040
		dw	$0300,$00CB,$0AAE,envC,$2175,envA,$01AE,envB,$0004,$0557,envC
		dw	$0305,$00CB,$01AE,envB,$0044
		dw	$0304,$00CB,$0A14,envC,$01AE,envB,$0004,$050A,envC
		dw	$0305,$00CB,$0000,env0,$0040
		dw	$0300,$00CB,$08FB,envC,$2175,envA,$01AE,envB,$0004,$047D,envC
		dw	$0305,$00CB,$0000,env0,$0040
		dw	$0300,$00CB,$087A,envC,$2175,envA,$01AE,envB,$0004,$043D,envC
		dw	$0305,$00CB,$01AE,envB,$0044
		dw	$0304,$00CB,$08FB,envC,$01AE,envB,$0004,$047D,envC
		dw	$0305,$00CB,$0000,env0,$0040
		dw	$0384,$00CB,$087A,envC,$0000,$043D,envC
		dw	$0385,$00CB,$0040
		dw	$0300,$00CB,$06BA,envC,$2175,envA,$01AE,envB,$0004,$035D,envC
		dw	$0305,$00CB,$01AE,envB,$0044
		dw	$0304,$00CB,$08FB,envC,$023F,envB,$0004,$023F,envC
		dw	$0305,$00CB,$0000,env0,$0040
		dw	$0301,$00CB,$2175,envA,$023F,envB,$0044
		dw	$0305,$00CB,$023F,envB,$0044
		dw	$0301,$00CB,$2175,envA,$023F,envB,$0044
		dw	$0305,$00CB,$0000,env0,$0040
		dw	$0301,$00CB,$2175,envA,$023F,envB,$0044
		dw	$0305,$00CB,$0000,env0,$0040
		dw	$0040

ptn6
		dw	$0300,$00CB,$0AAE,envC,$2175,envA,$023F,envB,$0004,$0557,envC
		dw	$0305,$00CB,$023F,envB,$0044
		dw	$0304,$00CB,$0A14,envC,$023F,envB,$0004,$050A,envC
		dw	$0385,$00CB,$0040
		dw	$0300,$00CB,$0BFD,envC,$2175,envD,$023F,envB,$0004,$05FE,envC
		dw	$0305,$00CB,$023F,envB,$0044
		dw	$0304,$00CB,$0AAE,envC,$023F,envB,$0004,$0557,envC
		dw	$0385,$00CB,$0040
		dw	$0300,$00CB,$0A14,envC,$2175,envD,$023F,envB,$0004,$050A,envC
		dw	$0305,$00CB,$023F,envB,$0044
		dw	$0304,$00CB,$08FB,envC,$023F,envB,$0004,$047D,envC
		dw	$0385,$00CB,$0040
		dw	$0300,$00CB,$0AAE,envC,$2175,envD,$023F,envB,$0004,$0557,envC
		dw	$0305,$00CB,$023F,envB,$0044
		dw	$0304,$00CB,$0A14,envC,$023F,envB,$0004,$050A,envC
		dw	$0385,$00CB,$0040
		dw	$0300,$00CB,$08FB,envC,$2175,envD,$023F,envB,$0004,$047D,envC
		dw	$0305,$00CB,$023F,envB,$0044
		dw	$0304,$00CB,$087A,envC,$023F,envB,$0004,$043D,envC
		dw	$0385,$00CB,$0040
		dw	$0300,$00CB,$0A14,envC,$2175,envD,$023F,envB,$0004,$050A,envC
		dw	$0305,$00CB,$023F,envB,$0044
		dw	$0304,$00CB,$08FB,envC,$023F,envB,$0004,$047D,envC
		dw	$0385,$00CB,$0040
		dw	$0300,$00CB,$087A,envC,$2175,envD,$023F,envB,$0004,$043D,envC
		dw	$0305,$00CB,$023F,envB,$0044
		dw	$0304,$00CB,$08FB,envC,$023F,envB,$0004,$047D,envC
		dw	$0385,$00CB,$0040
		dw	$0300,$00CB,$087A,envC,$2175,envD,$023F,envB,$0004,$043D,envC
		dw	$0305,$00CB,$023F,envB,$0044
		dw	$0304,$00CB,$06BA,envC,$023F,envB,$0004,$035D,envC
		dw	$0385,$00CB,$0040
		dw	$0300,$00CB,$0AAE,envC,$2175,envA,$021E,envB,$0004,$0557,envC
		dw	$0305,$00CB,$021E,envB,$0044
		dw	$0304,$00CB,$0A14,envC,$021E,envB,$0004,$050A,envC
		dw	$0385,$00CB,$0040
		dw	$0300,$00CB,$0BFD,envC,$2175,envD,$021E,envB,$0004,$05FE,envC
		dw	$0305,$00CB,$021E,envB,$0044
		dw	$0304,$00CB,$0AAE,envC,$021E,envB,$0004,$0557,envC
		dw	$0385,$00CB,$0040
		dw	$0300,$00CB,$0A14,envC,$2175,envD,$021E,envB,$0004,$050A,envC
		dw	$0305,$00CB,$021E,envB,$0044
		dw	$0304,$00CB,$08FB,envC,$021E,envB,$0004,$047D,envC
		dw	$0385,$00CB,$0040
		dw	$0300,$00CB,$0AAE,envC,$2175,envD,$021E,envB,$0004,$0557,envC
		dw	$0305,$00CB,$021E,envB,$0044
		dw	$0304,$00CB,$0A14,envC,$021E,envB,$0004,$050A,envC
		dw	$0385,$00CB,$0040
		dw	$0300,$00CB,$08FB,envC,$2175,envD,$021E,envB,$0004,$047D,envC
		dw	$0305,$00CB,$021E,envB,$0044
		dw	$0304,$00CB,$087A,envC,$021E,envB,$0004,$043D,envC
		dw	$0385,$00CB,$0040
		dw	$0300,$00CB,$0A14,envC,$2175,envD,$021E,envB,$0004,$050A,envC
		dw	$0305,$00CB,$021E,envB,$0044
		dw	$0304,$00CB,$08FB,envC,$021E,envB,$0004,$047D,envC
		dw	$0385,$00CB,$0040
		dw	$0300,$00CB,$087A,envC,$2175,envA,$021E,envB,$0004,$043D,envC
		dw	$0305,$00CB,$021E,envB,$0044
		dw	$0304,$00CB,$08FB,envC,$021E,envB,$0004,$047D,envC
		dw	$0385,$00CB,$0040
		dw	$0300,$00CB,$0A14,envC,$2175,envA,$021E,envB,$0004,$050A,envC
		dw	$0305,$00CB,$021E,envB,$0044
		dw	$0304,$00CB,$0AAE,envC,$021E,envB,$0004,$0557,envC
		dw	$0385,$00CB,$0040
		dw	$0040

ptn7
		dw	$0300,$00CB,$0AAE,envC,$2175,envA,$01C8,envB,$0004,$050A,envC
		dw	$0305,$00CB,$01C8,envB,$0044
		dw	$0304,$00CB,$0A14,envC,$01C8,envB,$0004,$047D,envC
		dw	$0385,$00CB,$0040
		dw	$0300,$00CB,$0BFD,envC,$2175,envA,$01C8,envB,$0004,$05FE,envC
		dw	$0305,$00CB,$01C8,envB,$0044
		dw	$0304,$00CB,$0AAE,envC,$01C8,envB,$0004,$0557,envC
		dw	$0385,$00CB,$0040
		dw	$0300,$00CB,$0A14,envC,$2175,envA,$01C8,envB,$0004,$050A,envC
		dw	$0305,$00CB,$01C8,envB,$0044
		dw	$0304,$00CB,$08FB,envC,$01C8,envB,$0004,$047D,envC
		dw	$0385,$00CB,$0040
		dw	$0300,$00CB,$0AAE,envC,$2175,envA,$01C8,envB,$0004,$0557,envC
		dw	$0305,$00CB,$01C8,envB,$0044
		dw	$0304,$00CB,$0A14,envC,$01C8,envB,$0004,$050A,envC
		dw	$0385,$00CB,$0040
		dw	$0300,$00CB,$08FB,envC,$2175,envA,$01C8,envB,$0004,$047D,envC
		dw	$0305,$00CB,$01C8,envB,$0044
		dw	$0304,$00CB,$087A,envC,$01C8,envB,$0004,$043D,envC
		dw	$0385,$00CB,$0040
		dw	$0300,$00CB,$0A14,envC,$2175,envA,$01C8,envB,$0004,$050A,envC
		dw	$0305,$00CB,$01C8,envB,$0044
		dw	$0304,$00CB,$08FB,envC,$01C8,envB,$0004,$047D,envC
		dw	$0385,$00CB,$0040
		dw	$0300,$00CB,$087A,envC,$2175,envA,$01C8,envB,$0004,$043D,envC
		dw	$0305,$00CB,$01C8,envB,$0044
		dw	$0304,$00CB,$08FB,envC,$01C8,envB,$0004,$047D,envC
		dw	$0385,$00CB,$0040
		dw	$0300,$00CB,$087A,envC,$2175,envA,$01C8,envB,$0004,$043D,envC
		dw	$0305,$00CB,$01C8,envB,$0044
		dw	$0304,$00CB,$06BA,envC,$01C8,envB,$0004,$035D,envC
		dw	$0385,$00CB,$0040
		dw	$0300,$00CB,$0AAE,envC,$2175,envA,$021E,envB,$0004,$0557,envC
		dw	$0305,$00CB,$021E,envB,$0044
		dw	$0304,$00CB,$0A14,envC,$021E,envB,$0004,$050A,envC
		dw	$0385,$00CB,$0040
		dw	$0300,$00CB,$0BFD,envC,$2175,envA,$021E,envB,$0004,$05FE,envC
		dw	$0305,$00CB,$021E,envB,$0044
		dw	$0304,$00CB,$0AAE,envC,$021E,envB,$0004,$0557,envC
		dw	$0385,$00CB,$0040
		dw	$0300,$00CB,$0A14,envC,$2175,envA,$021E,envB,$0004,$050A,envC
		dw	$0305,$00CB,$021E,envB,$0044
		dw	$0304,$00CB,$08FB,envC,$021E,envB,$0004,$047D,envC
		dw	$0385,$00CB,$0040
		dw	$0300,$00CB,$0AAE,envC,$2175,envA,$021E,envB,$0004,$0557,envC
		dw	$0305,$00CB,$021E,envB,$0044
		dw	$0304,$00CB,$0A14,envC,$021E,envB,$0004,$050A,envC
		dw	$0385,$00CB,$0040
		dw	$0300,$00CB,$08FB,envC,$2175,envA,$021E,envB,$0004,$047D,envC
		dw	$0305,$00CB,$021E,envB,$0044
		dw	$0304,$00CB,$087A,envC,$021E,envB,$0004,$043D,envC
		dw	$0385,$00CB,$0040
		dw	$0300,$00CB,$0A14,envC,$2175,envA,$021E,envB,$0004,$050A,envC
		dw	$0305,$00CB,$021E,envB,$0044
		dw	$0304,$00CB,$08FB,envC,$021E,envB,$0004,$047D,envC
		dw	$0385,$00CB,$0040
		dw	$0300,$00CB,$087A,envC,$2175,envA,$021E,envB,$0004,$043D,envC
		dw	$0305,$00CB,$021E,envB,$0040
		dw	$0304,$00CB,$08FB,envC,$021E,envB,$0000,$047D,envC
		dw	$0385,$00CB,$0040
		dw	$0300,$00CB,$0A14,envC,$2175,envA,$021E,envB,$0000,$050A,envC
		dw	$0305,$00CB,$021E,envB,$0040
		dw	$0304,$00CB,$0AAE,envC,$021E,envB,$0000,$0557,envC
		dw	$0385,$00CB,$0040
		dw	$0040

ptn8
		dw	$0300,$CB00,$2175,envA,$0000,env0,$01AE,envB,$0004,$0000,env0
		dw	$0305,$CB00,$01AE,envB,$0040
		dw	$0305,$CB00,$01AE,envB,$0040
		dw	$0385,$CB00,$0040
		dw	$0385,$CB00,$0040
		dw	$0385,$CB00,$0040
		dw	$0305,$CB00,$01AE,envB,$0040
		dw	$0305,$CB00,$01AE,envB,$0040
		dw	$0305,$CB00,$01AE,envB,$0040
		dw	$0385,$CB00,$0040
		dw	$0305,$CB00,$01AE,envB,$0040
		dw	$0305,$CB00,$01AE,envB,$0040
		dw	$0305,$CB00,$01AE,envB,$0040
		dw	$0385,$CB00,$0040
		dw	$0305,$CB00,$01C8,envB,$0040
		dw	$0385,$CB00,$0040
		dw	$0301,$CB00,$035D,envF,$01AE,envB,$0040
		dw	$0301,$CB00,$035D,envF,$01AE,envB,$0040
		dw	$0301,$CB00,$035D,envF,$01AE,envB,$0040
		dw	$0385,$CB00,$0040
		dw	$0385,$CB00,$0040
		dw	$0385,$CB00,$0040
		dw	$0301,$CB00,$035D,envF,$01AE,envB,$0040
		dw	$0301,$CB00,$035D,envF,$01AE,envB,$0040
		dw	$0301,$CB00,$035D,envF,$01AE,envB,$0040
		dw	$0385,$CB00,$0040
		dw	$0301,$CB00,$035D,envF,$01AE,envB,$0040
		dw	$0301,$CB00,$035D,envF,$01AE,envB,$0040
		dw	$0301,$CB00,$035D,envF,$01AE,envB,$0040
		dw	$0385,$CB00,$0040
		dw	$0301,$CB00,$0390,envF,$01C8,envB,$0040
		dw	$0385,$CB00,$0040
		dw	$0301,$CB00,$0000,env0,$023F,envH,$0040
		dw	$0305,$CB00,$023F,envH,$0040
		dw	$0305,$CB00,$023F,envH,$0040
		dw	$0385,$CB00,$0040
		dw	$0385,$CB00,$0040
		dw	$0385,$CB00,$0040
		dw	$0305,$CB00,$023F,envH,$0040
		dw	$0305,$CB00,$023F,envH,$0040
		dw	$0305,$CB00,$023F,envH,$0040
		dw	$0385,$CB00,$0040
		dw	$0305,$CB00,$023F,envH,$0040
		dw	$0305,$CB00,$023F,envH,$0040
		dw	$0305,$CB00,$023F,envH,$0040
		dw	$0385,$CB00,$0040
		dw	$0305,$CB00,$023F,envB,$0040
		dw	$0385,$CB00,$0040
		dw	$0301,$CB00,$0390,envF,$01C8,envB,$0040
		dw	$0301,$CB00,$0390,envF,$01C8,envB,$0040
		dw	$0301,$CB00,$0390,envF,$01C8,envB,$0040
		dw	$0385,$CB00,$0040
		dw	$0385,$CB00,$0040
		dw	$0385,$CB00,$0040
		dw	$0301,$CB00,$0390,envF,$01C8,envB,$0040
		dw	$0301,$CB00,$0390,envF,$01C8,envB,$0040
		dw	$0301,$CB00,$0390,envF,$01C8,envB,$0040
		dw	$0385,$CB00,$0040
		dw	$0301,$CB00,$0390,envF,$01C8,envB,$0040
		dw	$0301,$CB00,$0390,envF,$01C8,envB,$0040
		dw	$0301,$CB00,$0390,envF,$01C8,envB,$0040
		dw	$0385,$CB00,$0040
		dw	$0301,$CB00,$0390,envF,$01C8,envB,$0040
		dw	$0385,$CB00,$0040
		dw	$0040

ptn9
		dw	$0300,$0000,$0A14,envC,$035D,envF,$01AE,envB,$0004,$0D74,envC
		dw	$0300,$0000,$0A14,envC,$035D,envF,$01AE,envB,$0000,$0D74,envC
		dw	$0300,$0000,$0A14,envC,$035D,envF,$01AE,envB,$0000,$0D74,envC
		dw	$0385,$0000,$0040
		dw	$0385,$0000,$0044
		dw	$0385,$0000,$0040
		dw	$0300,$0000,$0A14,envC,$035D,envF,$01AE,envB,$0000,$0D74,envC
		dw	$0300,$0000,$0A14,envC,$035D,envF,$01AE,envB,$0000,$0D74,envC
		dw	$0300,$0000,$0A14,envC,$035D,envF,$01AE,envB,$0004,$0D74,envC
		dw	$0385,$0000,$0040
		dw	$0300,$0000,$0A14,envC,$035D,envF,$01AE,envB,$0000,$0D74,envC
		dw	$0300,$0000,$0A14,envC,$035D,envF,$01AE,envB,$0000,$0D74,envC
		dw	$0300,$0000,$0A14,envC,$035D,envF,$01AE,envB,$0004,$0D74,envC
		dw	$0385,$0000,$0040
		dw	$0300,$0000,$0AAE,envC,$0390,envF,$01C8,envB,$0000,$0E41,envC
		dw	$0385,$0000,$0040
		dw	$0300,$0000,$0A14,envC,$035D,envF,$01AE,envB,$0004,$0D74,envC
		dw	$0300,$0000,$0A14,envC,$035D,envF,$01AE,envB,$0000,$0D74,envC
		dw	$0300,$0000,$0A14,envC,$035D,envF,$01AE,envB,$0000,$0D74,envC
		dw	$0385,$0000,$0040
		dw	$0385,$0000,$0044
		dw	$0385,$0000,$0040
		dw	$0300,$0000,$0A14,envC,$035D,envF,$01AE,envB,$0000,$0D74,envC
		dw	$0300,$0000,$0A14,envC,$035D,envF,$01AE,envB,$0000,$0D74,envC
		dw	$0300,$0000,$0A14,envC,$035D,envF,$01AE,envB,$0004,$0D74,envC
		dw	$0385,$0000,$0040
		dw	$0300,$0000,$0A14,envC,$035D,envF,$01AE,envB,$0000,$0D74,envC
		dw	$0300,$0000,$0A14,envC,$035D,envF,$01AE,envB,$0000,$0D74,envC
		dw	$0300,$0000,$0A14,envC,$035D,envF,$01AE,envB,$0004,$0D74,envC
		dw	$0385,$0000,$0040
		dw	$0300,$0000,$0AAE,envC,$0390,envF,$01C8,envB,$0000,$0E41,envC
		dw	$0385,$0000,$0040
		dw	$0300,$0000,$0D74,envC,$047D,envF,$023F,envB,$0004,$11F6,envC
		dw	$0300,$0000,$0D74,envC,$047D,envF,$023F,envB,$0000,$11F6,envC
		dw	$0300,$0000,$0D74,envC,$047D,envF,$023F,envB,$0000,$11F6,envC
		dw	$0385,$0000,$0040
		dw	$0385,$0000,$0044
		dw	$0385,$0000,$0040
		dw	$0300,$0000,$0D74,envC,$047D,envF,$023F,envB,$0000,$11F6,envC
		dw	$0300,$0000,$0D74,envC,$047D,envF,$023F,envB,$0000,$11F6,envC
		dw	$0300,$0000,$0D74,envC,$047D,envF,$023F,envB,$0004,$11F6,envC
		dw	$0385,$0000,$0040
		dw	$0300,$0000,$0D74,envC,$047D,envF,$023F,envB,$0000,$11F6,envC
		dw	$0300,$0000,$0D74,envC,$047D,envF,$023F,envB,$0000,$11F6,envC
		dw	$0300,$0000,$0D74,envC,$047D,envF,$023F,envB,$0004,$11F6,envC
		dw	$0385,$0000,$0040
		dw	$0300,$0000,$0D74,envC,$047D,envF,$023F,envB,$0000,$11F6,envC
		dw	$0385,$0000,$0040
		dw	$0300,$0000,$0E41,envC,$0390,envF,$01C8,envB,$0004,$155C,envC
		dw	$0300,$0000,$0E41,envC,$0390,envF,$01C8,envB,$0000,$155C,envC
		dw	$0300,$0000,$0E41,envC,$0390,envF,$01C8,envB,$0080,$155C,envC
		dw	$0385,$0000,$0040
		dw	$0385,$0000,$0044
		dw	$0385,$0000,$0040
		dw	$0300,$0000,$0E41,envC,$0390,envF,$01C8,envB,$0080,$155C,envC
		dw	$0300,$0000,$0E41,envC,$0390,envF,$01C8,envB,$0000,$155C,envC
		dw	$0300,$0000,$0E41,envC,$0390,envF,$01C8,envB,$0004,$155C,envC
		dw	$0385,$0000,$0040
		dw	$0300,$0000,$0E41,envC,$0390,envF,$01C8,envB,$0080,$155C,envC
		dw	$0300,$0000,$0E41,envC,$0390,envF,$01C8,envB,$0000,$155C,envC
		dw	$0300,$0000,$0E41,envC,$0390,envF,$01C8,envB,$0004,$155C,envC
		dw	$0385,$0000,$0040
		dw	$0300,$0000,$0E41,envC,$0390,envF,$01C8,envB,$0080,$155C,envC
		dw	$0385,$0000,$0040
		dw	$0040

ptn10
		dw	$0300,$0000,$1429,envG,$035D,envF,$01AE,envB,$0004,$0D74,envC
		dw	$0301,$0000,$035D,envF,$01AE,envB,$0000,$0D74,envC
		dw	$0301,$0000,$035D,envF,$01AE,envB,$0080,$0D74,envC
		dw	$0385,$0000,$00C0
		dw	$0385,$0000,$0044
		dw	$0385,$0000,$0040
		dw	$0301,$0000,$035D,envF,$01AE,envB,$0080,$0D74,envC
		dw	$0301,$0000,$035D,envF,$01AE,envB,$0080,$0D74,envC
		dw	$0301,$0000,$035D,envF,$01AE,envB,$0004,$0D74,envC
		dw	$0385,$0000,$0040
		dw	$0301,$0000,$035D,envF,$01AE,envB,$0080,$0D74,envC
		dw	$0301,$0000,$035D,envF,$01AE,envB,$0080,$0D74,envC
		dw	$0301,$0000,$035D,envF,$01AE,envB,$0004,$0D74,envC
		dw	$0385,$0000,$0040
		dw	$0300,$0000,$11F6,envG,$0390,envF,$01C8,envB,$0080,$0E41,envC
		dw	$0384,$0000,$1429,envG,$00C0
		dw	$0300,$0000,$155C,envG,$035D,envF,$01AE,envB,$0004,$0D74,envC
		dw	$0300,$0000,$1429,envG,$035D,envF,$01AE,envB,$0000,$0D74,envC
		dw	$0300,$0000,$11F6,envG,$035D,envF,$01AE,envB,$0080,$0D74,envC
		dw	$0384,$0000,$1429,envG,$00C0
		dw	$0385,$0000,$0044
		dw	$0385,$0000,$0040
		dw	$0301,$0000,$035D,envF,$01AE,envB,$0080,$0D74,envC
		dw	$0301,$0000,$035D,envF,$01AE,envB,$0080,$0D74,envC
		dw	$0301,$0000,$035D,envF,$01AE,envB,$0004,$0D74,envC
		dw	$0385,$0000,$0040
		dw	$0301,$0000,$035D,envF,$01AE,envB,$0080,$0D74,envC
		dw	$0301,$0000,$035D,envF,$01AE,envB,$0080,$0D74,envC
		dw	$0301,$0000,$035D,envF,$01AE,envB,$0004,$0D74,envC
		dw	$0385,$0000,$0040
		dw	$0300,$0000,$11F6,envG,$0390,envF,$01C8,envB,$0080,$0E41,envC
		dw	$0384,$0000,$1429,envG,$00C0
		dw	$0300,$0000,$155C,envG,$047D,envF,$023F,envB,$0004,$11F6,envC
		dw	$0300,$0000,$1429,envG,$047D,envF,$023F,envB,$0000,$11F6,envC
		dw	$0300,$0000,$11F6,envG,$047D,envF,$023F,envB,$0080,$11F6,envC
		dw	$0384,$0000,$1429,envG,$00C0
		dw	$0384,$0000,$155C,envG,$0044
		dw	$0384,$0000,$1429,envG,$0040
		dw	$0300,$0000,$11F6,envG,$047D,envF,$023F,envB,$0080,$11F6,envC
		dw	$0300,$0000,$1429,envG,$047D,envF,$023F,envB,$0080,$11F6,envC
		dw	$0300,$0000,$155C,envG,$047D,envF,$023F,envB,$0004,$11F6,envC
		dw	$0384,$0000,$1429,envG,$0040
		dw	$0300,$0000,$11F6,envG,$047D,envF,$023F,envB,$0080,$11F6,envC
		dw	$0300,$0000,$1429,envG,$047D,envF,$023F,envB,$0080,$11F6,envC
		dw	$0300,$0000,$155C,envG,$047D,envF,$023F,envB,$0004,$11F6,envC
		dw	$0384,$0000,$1429,envG,$0040
		dw	$0300,$0000,$11F6,envG,$047D,envF,$023F,envB,$0080,$11F6,envC
		dw	$0384,$0000,$1429,envG,$00C0
		dw	$0300,$0000,$1AE9,envG,$0390,envF,$01C8,envB,$0004,$0E41,envC
		dw	$0301,$0000,$0390,envF,$01C8,envB,$0000,$0E41,envC
		dw	$0301,$0000,$0390,envF,$01C8,envB,$0080,$0E41,envC
		dw	$0385,$0000,$00C0
		dw	$0385,$0000,$0044
		dw	$0385,$0000,$0040
		dw	$0301,$0000,$0390,envF,$01C8,envB,$0080,$0E41,envC
		dw	$0301,$0000,$0390,envF,$01C8,envB,$0080,$0E41,envC
		dw	$0300,$0000,$17F9,envG,$0390,envF,$01C8,envB,$0004,$0E41,envC
		dw	$0385,$0000,$0040
		dw	$0301,$0000,$0390,envF,$01C8,envB,$0080,$0E41,envC
		dw	$0301,$0000,$0390,envF,$01C8,envB,$0080,$0E41,envC
		dw	$0301,$0000,$0390,envF,$01C8,envB,$0004,$0E41,envC
		dw	$0385,$0000,$0040
		dw	$0301,$0000,$0390,envF,$01C8,envB,$0080,$0E41,envC
		dw	$0385,$0000,$00C0
		dw	$0040

ptn11
		dw	$0300,$0000,$1AE9,envG,$035D,envF,$01AE,envB,$0004,$06BA,envC
		dw	$0301,$0000,$035D,envF,$01AE,envB,$0000,$06BA,envC
		dw	$0301,$0000,$035D,envF,$01AE,envB,$0080,$06BA,envC
		dw	$0385,$0000,$00C0
		dw	$0385,$0000,$0044
		dw	$0385,$0000,$0040
		dw	$0301,$0000,$035D,envF,$01AE,envB,$0080,$06BA,envC
		dw	$0301,$0000,$035D,envF,$01AE,envB,$0080,$06BA,envC
		dw	$0301,$0000,$035D,envF,$01AE,envB,$0004,$06BA,envC
		dw	$0385,$0000,$0040
		dw	$0301,$0000,$035D,envF,$01AE,envB,$0080,$06BA,envC
		dw	$0301,$0000,$035D,envF,$01AE,envB,$0080,$06BA,envC
		dw	$0300,$0000,$17F9,envG,$035D,envF,$01AE,envB,$0004,$06BA,envC
		dw	$0385,$0000,$0040
		dw	$0301,$0000,$0390,envF,$01C8,envB,$0080,$0721,envC
		dw	$0385,$0000,$00C0
		dw	$0300,$0000,$1429,envG,$035D,envF,$01AE,envB,$0004,$06BA,envC
		dw	$0301,$0000,$035D,envF,$01AE,envB,$0000,$06BA,envC
		dw	$0301,$0000,$035D,envF,$01AE,envB,$0080,$06BA,envC
		dw	$0385,$0000,$00C0
		dw	$0385,$0000,$0044
		dw	$0385,$0000,$0040
		dw	$0301,$0000,$035D,envF,$01AE,envB,$0080,$06BA,envC
		dw	$0301,$0000,$035D,envF,$01AE,envB,$0080,$06BA,envC
		dw	$0301,$0000,$035D,envF,$01AE,envB,$0004,$06BA,envC
		dw	$0385,$0000,$0040
		dw	$0301,$0000,$035D,envF,$01AE,envB,$0080,$06BA,envC
		dw	$0301,$0000,$035D,envF,$01AE,envB,$0080,$06BA,envC
		dw	$0301,$0000,$035D,envF,$01AE,envB,$0004,$06BA,envC
		dw	$0385,$0000,$0040
		dw	$0300,$0000,$11F6,envG,$0390,envF,$01C8,envB,$0080,$0721,envC
		dw	$0384,$0000,$1429,envG,$00C0
		dw	$0300,$0000,$155C,envG,$047D,envF,$023F,envB,$0004,$08FB,envC
		dw	$0300,$0000,$1429,envG,$047D,envF,$023F,envB,$0000,$08FB,envC
		dw	$0300,$0000,$11F6,envG,$047D,envF,$023F,envB,$0080,$08FB,envC
		dw	$0384,$0000,$1429,envG,$00C0
		dw	$0384,$0000,$155C,envG,$0044
		dw	$0384,$0000,$1429,envG,$0040
		dw	$0300,$0000,$11F6,envG,$047D,envF,$023F,envB,$0080,$08FB,envC
		dw	$0300,$0000,$1429,envG,$047D,envF,$023F,envB,$0080,$08FB,envC
		dw	$0300,$0000,$155C,envG,$047D,envF,$023F,envB,$0004,$08FB,envC
		dw	$0384,$0000,$1429,envG,$0040
		dw	$0300,$0000,$11F6,envG,$047D,envF,$023F,envB,$0080,$08FB,envC
		dw	$0300,$0000,$1429,envG,$047D,envF,$023F,envB,$0080,$08FB,envC
		dw	$0300,$0000,$155C,envG,$047D,envF,$023F,envB,$0004,$08FB,envC
		dw	$0384,$0000,$1429,envG,$0040
		dw	$0300,$0000,$11F6,envG,$047D,envF,$023F,envB,$0080,$08FB,envC
		dw	$0384,$0000,$1429,envG,$00C0
		dw	$0300,$0000,$155C,envG,$0390,envF,$01C8,envB,$0004,$0721,envC
		dw	$0300,$0000,$17F9,envG,$0390,envF,$01C8,envB,$0000,$0721,envC
		dw	$0300,$0000,$155C,envG,$0390,envF,$01C8,envB,$0080,$0721,envC
		dw	$0384,$0000,$17F9,envG,$00C0
		dw	$0384,$0000,$155C,envG,$0044
		dw	$0384,$0000,$1429,envG,$0040
		dw	$0300,$0000,$11F6,envG,$0390,envF,$01C8,envB,$0080,$0721,envC
		dw	$0300,$0000,$1000,envG,$0390,envF,$01C8,envB,$0080,$0721,envC
		dw	$0300,$0000,$11F6,envG,$0390,envF,$01C8,envB,$0004,$0721,envC
		dw	$0384,$0000,$1429,envG,$0040
		dw	$0300,$0000,$11F6,envG,$0390,envF,$01C8,envB,$0080,$0721,envC
		dw	$0300,$0000,$1429,envG,$0390,envF,$01C8,envB,$0080,$0721,envC
		dw	$0300,$0000,$10F4,envG,$0390,envF,$01C8,envB,$0004,$0721,envC
		dw	$0384,$0000,$11F6,envG,$0040
		dw	$0300,$0000,$10F4,envG,$0390,envF,$01C8,envB,$0080,$0721,envC
		dw	$0384,$0000,$0E41,envG,$00C0
		dw	$0040

ptn12
		dw	$0300,$0000,$1429,envG,$035D,envF,$01AE,envB,$0004,$050A,envC
		dw	$0301,$0000,$035D,envF,$01AE,envB,$0040
		dw	$0301,$0000,$035D,envF,$01AE,envB,$00C0
		dw	$0385,$0000,$00C0
		dw	$0385,$0000,$0044
		dw	$0385,$0000,$0040
		dw	$0301,$0000,$035D,envF,$01AE,envB,$00C0
		dw	$0301,$0000,$035D,envF,$01AE,envB,$00C0
		dw	$0301,$0000,$035D,envF,$01AE,envB,$0044
		dw	$0385,$0000,$0040
		dw	$0301,$0000,$035D,envF,$01AE,envB,$00C0
		dw	$0301,$0000,$035D,envF,$01AE,envB,$00C0
		dw	$0301,$0000,$035D,envF,$01AE,envB,$0044
		dw	$0385,$0000,$0040
		dw	$0300,$0000,$11F6,envG,$0390,envF,$01C8,envB,$0080,$047D,envC
		dw	$0384,$0000,$1429,envG,$0080,$050A,envC
		dw	$0300,$0000,$155C,envG,$035D,envF,$01AE,envB,$0004,$0557,envC
		dw	$0300,$0000,$1429,envG,$035D,envF,$01AE,envB,$0000,$050A,envC
		dw	$0300,$0000,$11F6,envG,$035D,envF,$01AE,envB,$0080,$047D,envC
		dw	$0384,$0000,$1429,envG,$0080,$050A,envC
		dw	$0385,$0000,$0044
		dw	$0385,$0000,$0040
		dw	$0301,$0000,$035D,envF,$01AE,envB,$00C0
		dw	$0301,$0000,$035D,envF,$01AE,envB,$00C0
		dw	$0301,$0000,$035D,envF,$01AE,envB,$0044
		dw	$0385,$0000,$0040
		dw	$0301,$0000,$035D,envF,$01AE,envB,$00C0
		dw	$0301,$0000,$035D,envF,$01AE,envB,$00C0
		dw	$0301,$0000,$035D,envF,$01AE,envB,$0044
		dw	$0385,$0000,$0040
		dw	$0300,$0000,$11F6,envG,$0390,envF,$01C8,envB,$0080,$047D,envC
		dw	$0384,$0000,$1429,envG,$0080,$050A,envC
		dw	$0300,$0000,$155C,envG,$047D,envF,$023F,envB,$0004,$0557,envC
		dw	$0300,$0000,$1429,envG,$047D,envF,$023F,envB,$0000,$050A,envC
		dw	$0300,$0000,$11F6,envG,$047D,envF,$023F,envB,$0080,$047D,envC
		dw	$0384,$0000,$1429,envG,$0080,$050A,envC
		dw	$0384,$0000,$155C,envG,$0004,$0557,envC
		dw	$0384,$0000,$1429,envG,$0000,$050A,envC
		dw	$0300,$0000,$11F6,envG,$047D,envF,$023F,envB,$0080,$047D,envC
		dw	$0300,$0000,$1429,envG,$047D,envF,$023F,envB,$0080,$050A,envC
		dw	$0300,$0000,$155C,envG,$047D,envF,$023F,envB,$0004,$0557,envC
		dw	$0384,$0000,$1429,envG,$0000,$050A,envC
		dw	$0300,$0000,$11F6,envG,$047D,envF,$023F,envB,$0080,$047D,envC
		dw	$0300,$0000,$1429,envG,$047D,envF,$023F,envB,$0080,$050A,envC
		dw	$0300,$0000,$155C,envG,$047D,envF,$023F,envB,$0004,$0557,envC
		dw	$0384,$0000,$1429,envG,$0000,$050A,envC
		dw	$0300,$0000,$11F6,envG,$047D,envF,$023F,envB,$0080,$047D,envC
		dw	$0384,$0000,$1429,envG,$0080,$050A,envC
		dw	$0300,$0000,$1AE9,envG,$0390,envF,$01C8,envB,$0004,$06BA,envC
		dw	$0301,$0000,$0390,envF,$01C8,envB,$0040
		dw	$0301,$0000,$0390,envF,$01C8,envB,$00C0
		dw	$0385,$0000,$00C0
		dw	$0385,$0000,$0044
		dw	$0385,$0000,$0040
		dw	$0301,$0000,$0390,envF,$01C8,envB,$00C0
		dw	$0301,$0000,$0390,envF,$01C8,envB,$00C0
		dw	$0300,$0000,$17F9,envG,$0390,envF,$01C8,envB,$0004,$05FE,envC
		dw	$0385,$0000,$0040
		dw	$0301,$0000,$0390,envF,$01C8,envB,$00C0
		dw	$0301,$0000,$0390,envF,$01C8,envB,$00C0
		dw	$0301,$0000,$0390,envF,$01C8,envB,$0044
		dw	$0385,$0000,$0040
		dw	$0301,$0000,$0390,envF,$01C8,envB,$00C0
		dw	$0385,$0000,$00C0
		dw	$0040

ptn13
		dw	$0300,$0000,$0D74,envG,$035D,envF,$01AE,envB,$0004,$06BA,envC
		dw	$0385,$0000,$0040
		dw	$0385,$0000,$0040
		dw	$0385,$0000,$0040
		dw	$0385,$0000,$0040
		dw	$0385,$0000,$0040
		dw	$0385,$0000,$0040
		dw	$0385,$0000,$0040
		dw	$0385,$0000,$0040
		dw	$0385,$0000,$0040
		dw	$0385,$0000,$0040
		dw	$0385,$0000,$0040
		dw	$0385,$0000,$0040
		dw	$0385,$0000,$0040
		dw	$0385,$0000,$0040
		dw	$0385,$0000,$0040
		dw	$0385,$0000,$0040
		dw	$0385,$0000,$0040
		dw	$0385,$0000,$0040
		dw	$0385,$0000,$0040
		dw	$0385,$0000,$0040
		dw	$0385,$0000,$0040
		dw	$0385,$0000,$0040
		dw	$0385,$0000,$0040
		dw	$0385,$0000,$0040
		dw	$0385,$0000,$0040
		dw	$0385,$0000,$0040
		dw	$0385,$0000,$0040
		dw	$0385,$0000,$0040
		dw	$0385,$0000,$0040
		dw	$0385,$0000,$0040
		dw	$0385,$0000,$0040
		dw	$0385,$0000,$0040
		dw	$0385,$0000,$0040
		dw	$0385,$0000,$0040
		dw	$0385,$0000,$0040
		dw	$0385,$0000,$0040
		dw	$0385,$0000,$0040
		dw	$0385,$0000,$0040
		dw	$0385,$0000,$0040
		dw	$0385,$0000,$0040
		dw	$0385,$0000,$0040
		dw	$0385,$0000,$0040
		dw	$0385,$0000,$0040
		dw	$0385,$0000,$0040
		dw	$0385,$0000,$0040
		dw	$0385,$0000,$0040
		dw	$0385,$0000,$0040
		dw	$0385,$0000,$0040
		dw	$0385,$0000,$0040
		dw	$0385,$0000,$0040
		dw	$0385,$0000,$0040
		dw	$0385,$0000,$0040
		dw	$0385,$0000,$0040
		dw	$0385,$0000,$0040
		dw	$0385,$0000,$0040
		dw	$0385,$0000,$0040
		dw	$0385,$0000,$0040
		dw	$0385,$0000,$0040
		dw	$0385,$0000,$0040
		dw	$0385,$0000,$0040
		dw	$0385,$0000,$0040
		dw	$0385,$0000,$0040
		dw	$0385,$0000,$0040
		dw	$0305,$0000,$01AE,envB,$0040
		dw	$0305,$0000,$01AE,envB,$0040
		dw	$0305,$0000,$01AE,envB,$0040
		dw	$0305,$0000,$0000,env0,$0040
		dw	$0385,$0000,$0040
		dw	$0385,$0000,$0040
		dw	$0305,$0000,$01AE,envB,$0040
		dw	$0305,$0000,$01AE,envB,$0040
		dw	$0305,$0000,$01AE,envB,$0040
		dw	$0305,$0000,$0000,env0,$0040
		dw	$0305,$0000,$01AE,envB,$0040
		dw	$0305,$0000,$01AE,envB,$0040
		dw	$0305,$0000,$01AE,envB,$0040
		dw	$0305,$0000,$0000,env0,$0040
		dw	$0305,$0000,$01AE,envB,$0040
		dw	$0305,$0000,$0000,env0,$0040
		dw	$0305,$0000,$01AE,envB,$0040
		dw	$0305,$0000,$01AE,envB,$0040
		dw	$0305,$0000,$01AE,envB,$0040
		dw	$0305,$0000,$0000,env0,$0040
		dw	$0385,$0000,$0040
		dw	$0385,$0000,$0040
		dw	$0305,$0000,$01AE,envB,$0040
		dw	$0305,$0000,$01AE,envB,$0040
		dw	$0305,$0000,$01AE,envB,$0040
		dw	$0305,$0000,$0000,env0,$0040
		dw	$0305,$0000,$01AE,envB,$0040
		dw	$0305,$0000,$01AE,envB,$0040
		dw	$0305,$0000,$01AE,envB,$0040
		dw	$0305,$0000,$0000,env0,$0040
		dw	$0305,$0000,$01AE,envB,$0040
		dw	$0305,$0000,$0000,env0,$0040
		dw	$0305,$0000,$01AE,envB,$0040
		dw	$0305,$0000,$01AE,envB,$0040
		dw	$0305,$0000,$01AE,envB,$0040
		dw	$0305,$0000,$0000,env0,$0040
		dw	$0385,$0000,$0040
		dw	$0385,$0000,$0040
		dw	$0305,$0000,$01AE,envB,$0040
		dw	$0305,$0000,$01AE,envB,$0040
		dw	$0305,$0000,$01AE,envB,$0040
		dw	$0305,$0000,$0000,env0,$0040
		dw	$0305,$0000,$01AE,envB,$0040
		dw	$0305,$0000,$01AE,envB,$0040
		dw	$0305,$0000,$01AE,envB,$0040
		dw	$0305,$0000,$0000,env0,$0040
		dw	$0305,$0000,$01AE,envB,$0040
		dw	$0305,$0000,$0000,env0,$0040
		dw	$0305,$0000,$01AE,envB,$0040
		dw	$0305,$0000,$01AE,envB,$0040
		dw	$0305,$0000,$01AE,envB,$0040
		dw	$0305,$0000,$0000,env0,$0040
		dw	$0385,$0000,$0040
		dw	$0385,$0000,$0040
		dw	$0305,$0000,$01AE,envB,$0040
		dw	$0305,$0000,$01AE,envB,$0040
		dw	$0305,$0000,$01AE,envB,$0040
		dw	$0305,$0000,$0000,env0,$0040
		dw	$0305,$0000,$01AE,envB,$0040
		dw	$0305,$0000,$01AE,envB,$0040
		dw	$0305,$0000,$01AE,envB,$0040
		dw	$0305,$0000,$0000,env0,$0040
		dw	$0305,$0000,$01AE,envB,$0040
		dw	$0305,$0000,$0000,env0,$0040
		dw	$0040

ptn14
		dw	$0300,$CB00,$2175,envJ_mid,$1AE9,envI,$1000,envI,$0000,$1429,envI
		dw	$0385,$CB00,$0040
		dw	$0385,$CB00,$0040
		dw	$0385,$CB00,$0040
		dw	$0385,$CB00,$0040
		dw	$0385,$CB00,$0040
		dw	$0385,$CB00,$0040
		dw	$0385,$CB00,$0040
		dw	$0385,$CB00,$0040
		dw	$0385,$CB00,$0040
		dw	$0385,$CB00,$0040
		dw	$0385,$CB00,$0040
		dw	$0385,$CB00,$0040
		dw	$0385,$CB00,$0040
		dw	$0385,$CB00,$0040
		dw	$0385,$CB00,$0040
		dw	$0385,$CB00,$0040
		dw	$0385,$CB00,$0040
		dw	$0385,$CB00,$0040
		dw	$0385,$CB00,$0040
		dw	$0385,$CB00,$0040
		dw	$0385,$CB00,$0040
		dw	$0385,$CB00,$0040
		dw	$0385,$CB00,$0040
		dw	$0385,$CB00,$0040
		dw	$0385,$CB00,$0040
		dw	$0385,$CB00,$0040
		dw	$0385,$CB00,$0040
		dw	$0385,$CB00,$0040
		dw	$0385,$CB00,$0040
		dw	$0385,$CB00,$0040
		dw	$0385,$CB00,$0040
		dw	$0385,$CB00,$0040
		dw	$0385,$CB00,$0040
		dw	$0385,$CB00,$0040
		dw	$0385,$CB00,$0040
		dw	$0385,$CB00,$0040
		dw	$0385,$CB00,$0040
		dw	$0385,$CB00,$0040
		dw	$0385,$CB00,$0040
		dw	$0385,$CB00,$0040
		dw	$0385,$CB00,$0040
		dw	$0385,$CB00,$0040
		dw	$0385,$CB00,$0040
		dw	$0385,$CB00,$0040
		dw	$0385,$CB00,$0040
		dw	$0385,$CB00,$0040
		dw	$0385,$CB00,$0040
		dw	$0385,$CB00,$0040
		dw	$0385,$CB00,$0040
		dw	$0385,$CB00,$0040
		dw	$0385,$CB00,$0040
		dw	$0385,$CB00,$0040
		dw	$0385,$CB00,$0040
		dw	$0385,$CB00,$0040
		dw	$0385,$CB00,$0040
		dw	$0381,$CB00,$02AB,envS_10,$0040
		dw	$0381,$CB00,$0285,envS_14,$0040
		dw	$0381,$CB00,$0261,envS_18,$0040
		dw	$0381,$CB00,$023F,envS_1C,$0040
		dw	$0381,$CB00,$021E,envS_20,$0040
		dw	$0381,$CB00,$0200,envS_24,$0040
		dw	$0381,$CB00,$01E3,envS_28,$0040
		dw	$0381,$CB00,$01C8,envS_2C,$0040
		dw	$0040

ptn15
		dw	$0300,$00CB,$06BA,envC,$2175,envA,$01AE,envB,$0004,$035D,envC
		dw	$0385,$00CB,$0040
		dw	$0385,$00CB,$0040
		dw	$0385,$00CB,$0040
		dw	$0300,$00CB,$08FB,envC,$2175,envA,$023F,envB,$0004,$047D,envC
		dw	$0385,$00CB,$0040
		dw	$0305,$00CB,$0196,envF,$0040
		dw	$0305,$00CB,$011F,envF,$0040
		dw	$0305,$00CB,$0000,env0,$0040
		dw	$0380,$0000,$0000,env0,$0000,env0,$0000,$0000,env0
		dw	$0385,$0000,$0040
		dw	$0385,$0000,$0040
		dw	$0385,$0000,$0040
		dw	$0385,$0000,$0040
		dw	$0385,$0000,$0040
		dw	$0385,$0000,$0040
		dw	$0040

ptn16
		dw	$0300,$00CB,$0AAE,envC,$2175,envA,$023F,envB,$0004,$0557,envC
		dw	$0305,$00CB,$023F,envB,$0044
		dw	$0304,$00CB,$0A14,envC,$023F,envB,$0004,$050A,envC
		dw	$0385,$00CB,$0040
		dw	$0300,$00CB,$0BFD,envC,$2175,envA,$023F,envB,$0004,$05FE,envC
		dw	$0305,$00CB,$023F,envB,$0044
		dw	$0304,$00CB,$0AAE,envC,$023F,envB,$0004,$0557,envC
		dw	$0385,$00CB,$0040
		dw	$0300,$00CB,$0A14,envC,$2175,envA,$023F,envB,$0004,$050A,envC
		dw	$0305,$00CB,$023F,envB,$0044
		dw	$0304,$00CB,$08FB,envC,$023F,envB,$0004,$047D,envC
		dw	$0385,$00CB,$0040
		dw	$0300,$00CB,$0AAE,envC,$2175,envA,$023F,envB,$0004,$0557,envC
		dw	$0305,$00CB,$023F,envB,$0044
		dw	$0304,$00CB,$0A14,envC,$023F,envB,$0004,$050A,envC
		dw	$0385,$00CB,$0040
		dw	$0300,$00CB,$08FB,envC,$2175,envA,$023F,envB,$0004,$047D,envC
		dw	$0305,$00CB,$023F,envB,$0044
		dw	$0304,$00CB,$087A,envC,$023F,envB,$0004,$043D,envC
		dw	$0385,$00CB,$0040
		dw	$0300,$00CB,$0A14,envC,$2175,envA,$023F,envB,$0004,$050A,envC
		dw	$0305,$00CB,$023F,envB,$0044
		dw	$0304,$00CB,$08FB,envC,$023F,envB,$0004,$047D,envC
		dw	$0385,$00CB,$0040
		dw	$0300,$00CB,$087A,envC,$2175,envA,$023F,envB,$0004,$043D,envC
		dw	$0305,$00CB,$023F,envB,$0044
		dw	$0304,$00CB,$08FB,envC,$023F,envB,$0004,$047D,envC
		dw	$0385,$00CB,$0040
		dw	$0300,$00CB,$087A,envC,$2175,envA,$047D,envB,$0004,$043D,envC
		dw	$0305,$00CB,$047D,envB,$0044
		dw	$0304,$00CB,$06BA,envC,$047D,envB,$0004,$035D,envC
		dw	$0385,$00CB,$0040
		dw	$0300,$00CB,$0AAE,envC,$2175,envA,$021E,envB,$0004,$0557,envC
		dw	$0305,$00CB,$021E,envB,$0044
		dw	$0304,$00CB,$0A14,envC,$021E,envB,$0004,$050A,envC
		dw	$0385,$00CB,$0040
		dw	$0300,$00CB,$0BFD,envC,$2175,envA,$021E,envB,$0004,$05FE,envC
		dw	$0305,$00CB,$021E,envB,$0044
		dw	$0304,$00CB,$0AAE,envC,$021E,envB,$0004,$0557,envC
		dw	$0385,$00CB,$0040
		dw	$0300,$00CB,$0A14,envC,$2175,envA,$021E,envB,$0004,$050A,envC
		dw	$0305,$00CB,$021E,envB,$0044
		dw	$0304,$00CB,$08FB,envC,$021E,envB,$0004,$047D,envC
		dw	$0385,$00CB,$0040
		dw	$0300,$00CB,$0AAE,envC,$2175,envA,$021E,envB,$0004,$0557,envC
		dw	$0305,$00CB,$021E,envB,$0044
		dw	$0304,$00CB,$0A14,envC,$021E,envB,$0004,$050A,envC
		dw	$0385,$00CB,$0040
		dw	$0300,$00CB,$08FB,envC,$2175,envA,$021E,envB,$0004,$047D,envC
		dw	$0305,$00CB,$021E,envB,$0044
		dw	$0304,$00CB,$087A,envC,$021E,envB,$0004,$043D,envC
		dw	$0385,$00CB,$0040
		dw	$0300,$00CB,$0A14,envC,$2175,envA,$021E,envB,$0004,$050A,envC
		dw	$0305,$00CB,$021E,envB,$0044
		dw	$0304,$00CB,$08FB,envC,$021E,envB,$0004,$047D,envC
		dw	$0385,$00CB,$0040
		dw	$0300,$00CB,$087A,envC,$2175,envA,$021E,envB,$0004,$043D,envC
		dw	$0305,$00CB,$021E,envB,$0044
		dw	$0304,$00CB,$08FB,envC,$021E,envB,$0004,$047D,envC
		dw	$0385,$00CB,$0040
		dw	$0300,$00CB,$0A14,envC,$2175,envA,$01AE,envB,$0004,$050A,envC
		dw	$0305,$00CB,$01AE,envB,$0044
		dw	$0304,$00CB,$0AAE,envC,$01AE,envB,$0004,$0557,envC
		dw	$0385,$00CB,$0040
		dw	$0040

ptn17
		dw	$0300,$00CB,$0AAE,envC,$2175,envA,$01C8,envB,$0004,$050A,envC
		dw	$0305,$00CB,$01C8,envB,$0044
		dw	$0304,$00CB,$0A14,envC,$01C8,envB,$0004,$047D,envC
		dw	$0385,$00CB,$0040
		dw	$0300,$00CB,$0BFD,envC,$2175,envA,$01C8,envB,$0004,$05FE,envC
		dw	$0305,$00CB,$01C8,envB,$0044
		dw	$0304,$00CB,$0AAE,envC,$01C8,envB,$0004,$0557,envC
		dw	$0385,$00CB,$0040
		dw	$0300,$00CB,$0A14,envC,$2175,envA,$01C8,envB,$0004,$050A,envC
		dw	$0305,$00CB,$01C8,envB,$0044
		dw	$0304,$00CB,$08FB,envC,$01C8,envB,$0004,$047D,envC
		dw	$0385,$00CB,$0040
		dw	$0300,$00CB,$0AAE,envC,$2175,envA,$01C8,envB,$0004,$0557,envC
		dw	$0305,$00CB,$01C8,envB,$0044
		dw	$0304,$00CB,$0A14,envC,$01C8,envB,$0004,$050A,envC
		dw	$0385,$00CB,$0040
		dw	$0300,$00CB,$08FB,envC,$2175,envA,$01C8,envB,$0004,$047D,envC
		dw	$0305,$00CB,$01C8,envB,$0044
		dw	$0304,$00CB,$087A,envC,$01C8,envB,$0004,$043D,envC
		dw	$0385,$00CB,$0040
		dw	$0300,$00CB,$0A14,envC,$2175,envA,$01C8,envB,$0004,$050A,envC
		dw	$0305,$00CB,$01C8,envB,$0044
		dw	$0304,$00CB,$08FB,envC,$01C8,envB,$0004,$047D,envC
		dw	$0385,$00CB,$0040
		dw	$0300,$00CB,$087A,envC,$2175,envA,$01C8,envB,$0004,$043D,envC
		dw	$0305,$00CB,$01C8,envB,$0044
		dw	$0304,$00CB,$08FB,envC,$01C8,envB,$0004,$047D,envC
		dw	$0385,$00CB,$0040
		dw	$0300,$00CB,$087A,envC,$2175,envA,$01C8,envB,$0004,$043D,envC
		dw	$0305,$00CB,$01C8,envB,$0044
		dw	$0304,$00CB,$06BA,envC,$01C8,envB,$0004,$035D,envC
		dw	$0385,$00CB,$0040
		dw	$0300,$00CB,$0AAE,envC,$2175,envA,$01AE,envB,$0004,$0557,envC
		dw	$0305,$00CB,$01AE,envB,$0044
		dw	$0304,$00CB,$0A14,envC,$01AE,envB,$0004,$050A,envC
		dw	$0385,$00CB,$0040
		dw	$0300,$00CB,$0BFD,envC,$2175,envA,$01AE,envB,$0004,$05FE,envC
		dw	$0305,$00CB,$01AE,envB,$0044
		dw	$0304,$00CB,$0AAE,envC,$01AE,envB,$0004,$0557,envC
		dw	$0385,$00CB,$0040
		dw	$0300,$00CB,$0A14,envC,$2175,envA,$01AE,envB,$0004,$050A,envC
		dw	$0305,$00CB,$01AE,envB,$0044
		dw	$0304,$00CB,$08FB,envC,$01AE,envB,$0004,$047D,envC
		dw	$0385,$00CB,$0040
		dw	$0300,$00CB,$0AAE,envC,$2175,envA,$01AE,envB,$0004,$0557,envC
		dw	$0305,$00CB,$01AE,envB,$0044
		dw	$0304,$00CB,$0A14,envC,$01AE,envB,$0004,$050A,envC
		dw	$0385,$00CB,$0040
		dw	$0300,$00CB,$08FB,envC,$2175,envA,$01AE,envB,$0004,$047D,envC
		dw	$0305,$00CB,$01AE,envB,$0044
		dw	$0304,$00CB,$087A,envC,$01AE,envB,$0004,$043D,envC
		dw	$0385,$00CB,$0040
		dw	$0300,$00CB,$0721,envC,$2175,envA,$01AE,envB,$0004,$0390,envC
		dw	$0305,$00CB,$01AE,envB,$0044
		dw	$0304,$00CB,$08FB,envC,$01AE,envB,$0004,$047D,envC
		dw	$0385,$00CB,$0040
		dw	$0300,$00CB,$06BA,envC,$2175,envA,$01AE,envB,$0004,$035D,envC
		dw	$0385,$00CB,$0040
		dw	$0385,$00CB,$0040
		dw	$0385,$00CB,$0040
		dw	$0385,$00CB,$0040
		dw	$0385,$00CB,$0040
		dw	$0385,$00CB,$0040
		dw	$0385,$00CB,$0040
		dw	$0040

		;==== Envelope Tables ====
; Single-value (static duty) envelopes - contiguous staircase table
envS_10
		db	$10,$80

envS_14
		db	$14,$80

envS_18
		db	$18,$80

envS_1C
		db	$1C,$80

envS_20
		db	$20,$80

envS_24
		db	$24,$80

envS_28
		db	$28,$80

envS_2C
		db	$2C,$80

envS_40
		db	$40,$80

envA
		db	$39,$26,$26,$22,$1F,$1C,$19,$16,$13,$0F,$0C,$09,$06,$03,$00,$80

envB
		db	$40,$3A,$34,$34,$33,$32,$31,$31,$2F,$2D,$2B,$2A,$28,$26,$24,$23
		db	$23,$22,$22,$22,$22,$21,$21,$21,$21,$20,$20,$20,$20,$1F,$1F,$1F
		db	$1F,$1F,$1E,$1E,$1E,$1E,$1D,$1D,$1D,$1D,$1C,$1C,$1C,$1C,$1C,$1B
		db	$1B,$1B,$1B,$1A,$1A,$1A,$1A,$19,$19,$19,$19,$19,$18,$18,$18,$18
		db	$17,$17,$17,$17,$16,$16,$16,$16,$15,$15,$15,$15,$15,$14,$14,$14
		db	$14,$13,$13,$13,$13,$12,$12,$12,$12,$12,$11,$11,$11,$11,$10,$10
		db	$10,$10,$0F,$0F,$0F,$0F,$0F,$0E,$0E,$0E,$0E,$0D,$0D,$0D,$0D,$0C
		db	$0C,$0C,$0C,$0B,$0B,$0B,$0B,$0B,$0A,$0A,$0A,$0A,$09,$09,$09,$09
		db	$08,$08,$08,$08,$08,$07,$07,$07,$07,$06,$06,$06,$06,$05,$05,$05
		db	$05,$05,$80

envC
		db	$26,$22,$1F,$1B,$18,$14,$11,$0D,$0A,$80

envD
		db	$14,$0B,$0B,$0A,$09,$09,$08,$07,$07,$06,$05,$05,$04,$03,$03,$02
		db	$01,$01,$00,$00,$80

envE
		db	$16,$14,$13,$11,$10,$0E,$0D,$0D,$0C,$0B,$0A,$09,$08,$07,$06,$06
		db	$80

envF
		db	$2B,$29,$27,$25,$23,$21,$1F,$1D,$1D,$1C,$1C,$1C,$1C,$1C,$1B,$1B
		db	$1B,$1B,$1B,$1A,$1A,$1A,$1A,$1A,$19,$19,$19,$19,$19,$18,$18,$18
		db	$18,$18,$18,$17,$17,$17,$17,$17,$16,$16,$16,$16,$16,$15,$15,$15
		db	$15,$15,$14,$14,$14,$14,$14,$13,$13,$13,$13,$13,$13,$12,$12,$12
		db	$12,$12,$11,$11,$11,$11,$11,$10,$10,$10,$10,$10,$0F,$0F,$0F,$0F
		db	$0F,$0E,$0E,$0E,$0E,$0E,$0E,$0D,$0D,$0D,$0D,$0D,$0C,$0C,$0C,$0C
		db	$0C,$0B,$0B,$0B,$0B,$0B,$0A,$0A,$0A,$0A,$0A,$09,$09,$09,$09,$09
		db	$09,$08,$08,$08,$08,$08,$07,$07,$07,$07,$07,$06,$06,$06,$06,$06
		db	$05,$05,$05,$05,$05,$04,$04,$04,$04,$04,$04,$03,$03,$03,$03,$03
		db	$02,$02,$02,$02,$02,$01,$01,$01,$01,$01,$00,$00,$00,$00,$00,$00
		db	$80

envG
		db	$3C,$3B,$3A,$3A,$39,$39,$38,$38,$37,$37,$36,$36,$35,$35,$34,$34
		db	$33,$33,$32,$32,$31,$31,$30,$30,$2F,$2F,$2E,$2E,$2D,$2D,$2C,$2B
		db	$2B,$2A,$2A,$29,$29,$28,$28,$27,$27,$26,$26,$25,$25,$24,$24,$23
		db	$23,$22,$22,$21,$21,$20,$20,$1F,$1F,$1E,$1E,$1D,$1C,$1C,$1B,$1B
		db	$1A,$1A,$19,$19,$18,$18,$17,$17,$16,$16,$15,$15,$14,$14,$13,$13
		db	$12,$12,$11,$11,$10,$10,$0F,$0F,$0E,$0E,$80

envH
		db	$1A,$19,$19,$18,$18,$17,$17,$16,$16,$15,$15,$14,$14,$13,$13,$12
		db	$12,$11,$11,$10,$10,$10,$0F,$0F,$0F,$0F,$0F,$0F,$0F,$0F,$0F,$0F
		db	$0F,$0F,$0F,$0F,$0E,$0E,$0E,$0E,$0E,$0E,$0E,$0E,$0E,$0E,$0E,$0E
		db	$0E,$0E,$0D,$0D,$0D,$0D,$0D,$0D,$0D,$0D,$0D,$0D,$0D,$0D,$0D,$0D
		db	$0D,$0C,$0C,$0C,$0C,$0C,$0C,$0C,$0C,$0C,$0C,$0C,$0C,$0C,$0C,$0B
		db	$80

envI
		db	$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
		db	$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
		db	$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
		db	$00,$00,$00,$00,$00,$00,$00,$00,$01,$01,$01,$01,$01,$01,$01,$01
		db	$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01
		db	$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01
		db	$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$02
		db	$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02
		db	$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02
		db	$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02
		db	$02,$02,$02,$02,$02,$02,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03
		db	$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03
		db	$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03
		db	$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$04,$04,$04
		db	$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04
		db	$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04
		db	$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04
		db	$04,$04,$04,$04,$04,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05
		db	$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05
		db	$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05
		db	$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$06,$06,$06,$06
		db	$06,$06,$06,$06,$06,$06,$06,$06,$06,$06,$06,$06,$06,$06,$06,$06
		db	$06,$06,$06,$06,$06,$06,$06,$06,$06,$06,$06,$06,$06,$06,$06,$06
		db	$06,$06,$06,$06,$06,$06,$06,$06,$06,$06,$06,$06,$06,$06,$06,$06
		db	$06,$06,$06,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07
		db	$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07
		db	$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07
		db	$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$08,$08,$08,$08,$08,$08
		db	$08,$08,$08,$08,$08,$09,$09,$09,$09,$09,$09,$09,$09,$09,$09,$0A
		db	$0A,$0A,$0A,$0A,$0A,$0A,$0A,$0A,$0A,$0B,$0B,$0B,$0B,$0B,$0B,$0B
		db	$0B,$0B,$0B,$0C,$0C,$0C,$0C,$0C,$0C,$0C,$0C,$0C,$0C,$0D,$0D,$0D
		db	$0D,$0D,$0D,$0D,$0D,$0D,$0D,$0E,$0E,$0E,$0E,$0E,$0E,$0E,$0E,$0E
		db	$0E,$0F,$0F,$0F,$0F,$0F,$0F,$0F,$0F,$0F,$10,$80

envJ_mid		equ	envJ+$16D
envJ
		db	$02,$02,$02,$02,$02,$02,$02,$03,$03,$03,$03,$03,$03,$04,$04,$04
		db	$04,$04,$04,$04,$05,$05,$05,$05,$05,$05,$06,$06,$06,$06,$06,$06
		db	$07,$07,$07,$07,$07,$07,$07,$08,$08,$08,$08,$08,$08,$09,$09,$09
		db	$09,$09,$09,$0A,$0A,$0A,$0A,$0A,$0A,$0B,$0B,$0B,$0B,$0B,$0B,$0B
		db	$0C,$0C,$0C,$0C,$0C,$0C,$0D,$0D,$0D,$0D,$0D,$0D,$0E,$0E,$0E,$0E
		db	$0E,$0E,$0E,$0F,$0F,$0F,$0F,$0F,$0F,$10,$10,$10,$10,$10,$10,$11
		db	$11,$11,$11,$11,$11,$11,$12,$12,$12,$12,$12,$12,$13,$13,$13,$13
		db	$13,$13,$13,$14,$14,$14,$14,$14,$14,$15,$15,$15,$15,$15,$15,$16
		db	$16,$16,$16,$16,$16,$16,$17,$17,$17,$17,$17,$17,$18,$18,$18,$18
		db	$18,$18,$19,$19,$19,$19,$19,$19,$19,$1A,$1A,$1A,$1A,$1A,$1A,$1B
		db	$1B,$1B,$1B,$1B,$1B,$1C,$1C,$1C,$1C,$1C,$1C,$1C,$1D,$1D,$1D,$1D
		db	$1D,$1D,$1E,$1E,$1E,$1E,$1E,$1E,$1F,$1F,$1F,$1F,$1F,$1F,$1F,$20
		db	$20,$20,$20,$20,$20,$21,$21,$21,$21,$21,$21,$22,$22,$22,$22,$22
		db	$22,$22,$23,$23,$23,$23,$23,$23,$24,$24,$24,$24,$24,$24,$25,$25
		db	$25,$25,$25,$25,$25,$26,$26,$26,$26,$26,$26,$27,$27,$27,$27,$27
		db	$27,$28,$28,$28,$28,$28,$28,$28,$29,$29,$29,$29,$29,$29,$29,$29
		db	$29,$29,$29,$29,$29,$29,$29,$29,$29,$29,$29,$29,$29,$29,$29,$29
		db	$29,$29,$29,$29,$29,$29,$29,$29,$29,$29,$29,$29,$29,$29,$29,$29
		db	$29,$29,$29,$29,$29,$29,$29,$29,$29,$29,$29,$29,$29,$29,$29,$29
		db	$29,$29,$29,$29,$29,$29,$29,$29,$29,$29,$29,$29,$29,$29,$29,$29
		db	$29,$29,$29,$29,$29,$29,$29,$29,$29,$29,$29,$29,$29,$29,$29,$29
		db	$29,$29,$29,$29,$29,$29,$29,$29,$29,$29,$29,$29,$29,$29,$29,$29
		db	$29,$29,$29,$29,$29,$29,$29,$29,$29,$29,$29,$29,$29,$29,$29,$29
		db	$29,$29,$29,$2A,$2A,$2A,$2A,$2A,$2A,$2A,$2A,$2A,$2A,$2A,$2A,$2A
		db	$2A,$2A,$2A,$2A,$2A,$2A,$2A,$2A,$2A,$2A,$2A,$2A,$2A,$2A,$2A,$2A
		db	$2A,$2A,$2A,$2A,$2A,$2A,$2A,$2A,$2A,$2A,$2A,$2A,$2A,$2A,$2A,$2A
		db	$2A,$2A,$2A,$2A,$2A,$2A,$2A,$2A,$2A,$2A,$2A,$2A,$2A,$2A,$2A,$2A
		db	$2A,$2A,$2A,$2A,$2A,$2A,$2A,$2A,$2A,$2A,$2A,$2A,$2A,$2A,$2A,$2A
		db	$2A,$2A,$2A,$2A,$2A,$2A,$2A,$2A,$2A,$2A,$2A,$2A,$2A,$2A,$2A,$2A
		db	$2A,$2A,$2A,$2A,$2A,$2A,$2A,$2A,$2A,$2A,$2A,$2A,$2A,$2A,$2A,$2A
		db	$2A,$2A,$2A,$2A,$2A,$2A,$2A,$2A,$2A,$2A,$2A,$2A,$2A,$2B,$80
