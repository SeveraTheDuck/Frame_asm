.286
.model tiny
.code
org 100h

;----------------------------------------------------------
X_BEGIN		equ 20
Y_BEGIN		equ 6
FRAME_HEIGHT	equ 10
FRAME_WIDTH	equ 40
FRAME_COLOR	equ 1fh

BG_FILLER	equ 07023h

VIDEO_MEMORY	equ 0b800h
LINE_LENGTH	equ 80
LINE_NUMBER	equ 25
;----------------------------------------------------------

Start:		call SetStreams		;ok naming?
		call FillBackground

		mov ah, FRAME_COLOR
		mov di, (X_BEGIN + (Y_BEGIN - 1) * LINE_LENGTH) * 2		
		call PrintFrame

		call TerminatePr

;----------------------------------------------------------
;PrintFrame prints a frame at given place with given color and symbols
;Enter: AH = FRAME_COLOR, BX -> FramePattern, ES = VIDEO_MEMORY,
;	SI = frame_begin, DI -> FramePattern, DF = 0
;Exit:  none
;Destr: AX, BX, CX, DX, SI, DI
;----------------------------------------------------------
PrintFrame	proc

		;top row
		mov cx, FRAME_WIDTH - 2
		call PrintRow

		;middle rows
		mov cx, FRAME_HEIGHT - 2
		add bx, 3

MiddleRows:	mov dx, cx		;temp saving location
		mov cx, FRAME_WIDTH - 2
		call PrintRow
		mov cx, dx
		loop MiddleRows

		;bottom row
		mov cx, FRAME_WIDTH - 2
		add bx, 3
		call PrintRow

		ret
		endp

;----------------------------------------------------------
;SetStreams sets video_mem and input data streams
;Enter: none
;Exit:  BX -> FramePattern, ES = VIDEO_MEMORY,
;	SI -> FramePattern, DI = 0, DF = 0
;Destr: AX, ES, SI, DI, DF
;----------------------------------------------------------
SetStreams	proc

		mov ax, VIDEO_MEMORY
		mov es, ax			;es -> video_mem segment

		xor di, di
		mov si, offset FramePattern	;si -> FramePattern string
		mov bx, si
		cld				;clear DF flag

		ret
		endp

;----------------------------------------------------------
;FillBackground fills background with a constant filler.
;Enter: ES = VIDEO_MEMORY, DI = 0, DF = 0
;Exit:  none
;Destr: AX, CX, DI
;----------------------------------------------------------
FillBackground	proc

		mov cx, LINE_LENGTH * LINE_NUMBER
		mov ax, BG_FILLER
		rep stosw

		ret
		endp

;----------------------------------------------------------
;PrintRow prints a row of symbols with a given from ds pattern
;Enter:	AH = COLOR, BX = pattern_str_begin, CX = NUM_OF_SYMBOLS - 2
;Exit:  none
;Destr: AL, CX, SI, DI
;----------------------------------------------------------
PrintRow	proc
		
		push cx
		mov si, bx
		
		lodsb
		stosw		;left part

		lodsb
		rep stosw	;middle part

		lodsb
		stosw		;right part
		
		;----------------------
		;cringe?
		pop cx
		shl cx, 1			;cx *= 2
		add di, (LINE_LENGTH - 2) * 2	;di offset after each row
		sub di, cx
		;----------------------

		ret
		endp

;----------------------------------------------------------
;TerminatePr end the programm. 
;Enter: none
;Exit:  none
;Destr: AX
;----------------------------------------------------------
TerminatePr	proc

		mov ax, 4c00h
		int 21h

		ret
		endp

FramePattern 	db "/-\| |\_/$"

end		Start