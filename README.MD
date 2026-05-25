

  ..--== SHARP MZ700  ONE BIT MUSIC ==--..


1-bit music converted from ZX Spectrum to Sharp MZ700.


A number of older Sharp MZ700 emulators refuse to work with 1-bit sound.
I found this particular version " EmuZ-80B-1500-2200-2500_beta5b.zip " from some unknown obscure location, and it works brilliantly on all engines, and runs under Win 7 x32, Win 10 and Win 11.
executable :

		 MZ700-PAL.EXE

	     MZ700-NTSC.EXE

Unfortunately a number of emus that are listed here do not appear to work : https://sharpmz.zdechov.net/?wiki/emulators

One of the newer emulators is here, which may work (untested).  https://sourceforge.net/projects/mz800emu/



Emulator usage, being "EmuZ-80B" that specifically emulates the MZ700.
==================

Load in raw .BIN files
----------------------

USE EMULATOR: mz700-PAL.exe

Control --> Debug.

<in debug>

n file.bin

l 5000

Q

<back at monitor>

G5000

<1bit music engine and tune will then execute>



Load in MZT or M12 tape files
-----------------------------
USE EMULATOR: mz700-PAL.exe

CMT --> Play --> select MZT or M12 file.

CMT --> PLAY BUTTON    (this loads a converted wav file from the MZT or M12 file)

<Will then auto play - 1bit music engine and tune will then execute>




Assembling ASM files:
Depending on the engine, all source code were written with either z80 SJASMplus or z80 PASMO assemblers.

PASMO:		pasmo --alocal %1.asm %1.bin

SJASMPUS:	sjasmplus %1.asm			(output file is configured within source code)



Conversion of .BIN to .MZT (add a tape file header on to .BIN to become .MZT / .M12)
------------------------------------------------------------------------------------

From the bin directory of the Z88DK deveopment kit (www.z88dk.org) use:

z88dk-appmake.exe +mz --org 20480 -b music.bin -o music.mzt

(Use the decimal equiv of hex origin, ie: 20480 = $5000 memory address)


Assembly details
===================

Typical origin : $1200 or $5000

Needs at the start to initialise sound:

begin:		out 	($E0), a

out	($E3), a

ld 	hl, $E008 	;sound on

ld 	(hl), $01




and replace	OUT  ($FE), A		; ZX SPECTRUM

with:

and 	$08		; SHARP MZ700

or  	$20		; SHARP MZ700

ld  	($e007), a	; SHARP MZ700





.MZT/.M12 File Header:
------------------------


org $5000

   db	01								; 01 = Binary.

dw	'FILE',$0d,$0d,$0d,$0d,$0d,$0d,$0d,$0d,$0d,$0d,$0d,$0d,$0d	; 16 byte filename with $0D terminator

dw	$800								; Length.  $800 = $2k program.  $1000=4k program

dw	$5000								; Load address

dw	$5000								; Execute address

ds 	104, ' '           						; blank trailer space. 104 total.  32 per line.


################




01 47 41 4D 45 0D 0D 0D 0D 0D 0D 0D 0D 0D 0D 0D

0D 00 10 00 12 00 12 00 00 00 00 00 00 00 00 00

00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00

00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00

00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00

00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00

00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00

00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00


################



Breakdown of the Hex Example:

01: Type is a machine code binary file.

47 41 4D 45: ASCII for "G", "A", "M", "E".

0D 0D...: The rest of the 16-byte filename field is padded with Carriage Returns (0x0D).

00 10: File size is $1000 (Little-Endian: Low byte 00, High byte 10).

00 12: Load address is $1200.

00 12: Execution address is $1200.

00 00...: The remaining 104 bytes are zero-padded comments.


################



Byte(s)		Length		Description

0x00		1 byte		File Attribute/Type: 0x01 (Machine code/Binary), 0x0/2 (ASCII), 0x03 (Data), 0x05 (MZ-700 BASIC).

0x01 - 0x10	16 bytes	Filename: Pad with trailing $0D (Carriage Return) if less than 16 characters.

0x11 - 0x12	2 bytes		File Size: Size of the following data block in bytes (Little-Endian).

0x13 - 0x14	2 bytes		Load Address: Address in RAM where data is loaded (Little-Endian).

0x15 - 0x16	2 bytes		Execution Address: RAM address where program execution starts (Little-Endian).

0x17 - 0x7F	104 bytes	Comment Area: Unused/Comment section, typically filled with 0x00 or spaces.






