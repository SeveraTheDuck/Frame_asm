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

BG_FILLER	equ 7003h

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

		mov dx, (LINE_LENGTH - FRAME_WIDTH) * 2	;dx = line_step

		;top row
		mov cx, FRAME_WIDTH - 2
		call PrintRow

		;middle rows
		mov cx, FRAME_HEIGHT - 2
		add bx, 3

MiddleRows:	push cx
		mov cx, FRAME_WIDTH - 2
		call PrintRow
		pop cx
		loop MiddleRows

		;bottom row
		mov cx, FRAME_WIDTH - 2
		add bx, 3
		call PrintRow

		call PrintShadow

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
;	DX = line_step
;Exit:  none
;Destr: AL, CX, SI, DI
;----------------------------------------------------------
PrintRow	proc
		
		mov si, bx
		
		lodsb
		stosw		;left part

		lodsb
		rep stosw	;middle part

		lodsb
		stosw		;right part
		
		add di, dx	;di offset after each row

		ret
		endp

;----------------------------------------------------------
;PrintShadow prints shadow for a frame
;Enter:	none
;Exit: 	none
;Destr:	AL, CX, DX, DI
;----------------------------------------------------------
PrintShadow	proc

		;bottom row
		mov al, 88h
		mov cx, FRAME_WIDTH
		mov di, (X_BEGIN + 1 + (Y_BEGIN + FRAME_HEIGHT - 1) * LINE_LENGTH) * 2 + 1
PrintSymbolRow:	stosb
		inc di
		loop PrintSymbolRow

		;side column
		mov cx, FRAME_HEIGHT - 1
		mov dx, (LINE_LENGTH - 1) * 2 + 1
		mov di, (X_BEGIN + FRAME_WIDTH + Y_BEGIN * LINE_LENGTH) * 2 + 1
PrintSymbolColumn:
		stosb
		add di, dx
		loop PrintSymbolColumn
		
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

FramePattern 	db 0c9h, 0cdh, 0bbh, 0bah, " ", 0bah, 0c8h, 0cdh, 0bch, "$"

end		Start
