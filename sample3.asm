
CLS	EQU	16H		;clear screen char
PRNT   	EQU	0012H		;subroutine to print 1 char from accu



	org 	$5000



            ld a,$30
            ld (pit8253cword),a
            ld a,$00
            ld (pit8253c0),a
            ld (pit8253c0),a
            ld a,$10
            ld (pit8253cword),a
            call musicon
            ld hl,sample
            ld bc,length
sampleloop:	ld a,(hl)
            inc hl
            ld (pit8253c0),a
            call delay
            dec bc
            ld a, b
            or c
            jr nz, sampleloop
endy:        call musicoff
            jp $00ad


; pause for value in de
delay:	ld de,(delaytime)
delayloop:	dec de
            ld a, d
            or e
            jr nz, delayloop
            ret

; control sound generator a is not preserved
musicon:	ld a,1
            jr sendcont
musicoff:	ld a,0
sendcont:	ld (pit8253cont),a
            ret


pit8253c0:	   EQU $e004
pit8253cword:  EQU $e007
pit8253cont:   EQU $e008

length:        EQU 16010 
delaytime:     DEFW $10
;sample:        incbin "sample2.raw"
sample:        incbin "sample.raw"

