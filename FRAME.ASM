.286
.model tiny
.code
org 100h

;----------------------------------------------------------
;positions and sizes
X_BEGIN			equ 20
Y_BEGIN			equ 5
FRAME_WIDTH		equ 40
FRAME_HEIGHT		equ 10
LINE_LENGTH		equ 80

;fill colors and border symbols
FRAME_FILL		equ 1020h
FRAME_SHADOW_FILL	equ 0020h
DEMONSTRATION_FILL	equ 0ff20h ;wtf order???
FRAME_COLUMN_BORDER	equ 1f7ch
FRAME_LINE_BORDER	equ 1f2dh

;video memory constants
VIDEO_MEMORY		equ 0b800h
NUM_OF_SCREEN_SYMBOLS	equ 4000
;----------------------------------------------------------

Start:		call PrintDemonstrationBackground

		call MakeAnimation

		call SetFrameShadowRegisters
		call PrintFrame		;print shadow

		call SetFrameRegisters
		call PrintFrame		;print frame

		call PrintBorder	;print frame border

		mov ax, 4c00h		;terminate program
		int 21h

;----------------------------------------------------------
;PrintDemonstrationBackground - prints white background
;Enter: none
;Exit:  ES = VIDEO_MEMORY
;Destr: AX BX ES SI
;----------------------------------------------------------
PrintDemonstrationBackground	proc
		mov ax, VIDEO_MEMORY
		mov bx, 0
		mov es, ax
		mov si, DEMONSTRATION_FILL

DemBackground:	cmp bx, NUM_OF_SCREEN_SYMBOLS
		je EndDemBackground
		
		mov es:[bx], si

		inc bx
		inc bx
		jmp DemBackground

EndDemBackground:
		ret
		endp

;
;
;
;
;
;
MakeAnimation 	proc

		mov di, (FRAME_WIDTH / 2) * 2 ;used to make even numbers
		mov si, FRAME_FILL
		mov cl, 0
		mov dx, LINE_LENGTH * 2

NextAnimation:	cmp di, 0
		je EndAnimation

		mov al, FRAME_HEIGHT
		mov ah, 0
		mov ch, 0

		mov bx, (X_BEGIN + (Y_BEGIN - 1) * LINE_LENGTH) * 2
		add bx, di

		call PrintFrame

		sub di, 2
		add cl, 4
		sub dx, 4

;		push cx
;		push dx
;		mov ax, 86h
;		int 15h
;		pop dx
;		pop cx

		jmp NextAnimation

EndAnimation:	ret
		endp

;----------------------------------------------------------
;SetFrameShadowRegisters - sets initial values to print shadow
;Enter: ES = VIDEO_MEMORY
;Exit:  AL = FRAME_HEIGHT, AH = 0, 	   BX = shadow_position
;	CL = FRAME_WIDTH,  DX = line_step, SI = FRAME_SHADOW_FILL,
;	ES = VIDEO_MEMORY	
;Destr: AX BX CL DX SI
;----------------------------------------------------------
SetFrameShadowRegisters		proc

		mov bx, (X_BEGIN + 1 + Y_BEGIN * LINE_LENGTH) * 2
		mov dx, (LINE_LENGTH - FRAME_WIDTH) * 2

		mov al, FRAME_HEIGHT
		mov ah, 0

		mov cl, FRAME_WIDTH

		mov si, FRAME_SHADOW_FILL

		ret
		endp

;----------------------------------------------------------
;SetFrameRegisters sets initial values for registers to draw a frame
;Entry: AL = FRAME_HEIGHT, CL = FRAME_WIDTH,
;	DX = line_step, ES = VIDEO_MEMORY
;Exit:  AL = FRAME_HEIGHT, AH = 0, 	   BX = frame_position,
;	CL = FRAME_WIDTH,  DX = line_step, SI = FRAME_FILL
;	ES = VIDEO_MEMORY
;Destr: AH BX SI
;----------------------------------------------------------
SetFrameRegisters	proc

		mov bx, (X_BEGIN + (Y_BEGIN - 1) * LINE_LENGTH) * 2

		mov ah, 0

		mov si, FRAME_FILL

		ret
		endp

;----------------------------------------------------------
;Prints frame at given place with given filler
;Enter: AL = FRAME_HEIGHT, AH = 0, 	   BX = frame_position
;	CL = FRAME_WIDTH,  DX = line_step, SI = FRAME_FILL
;	ES = VIDEO_MEMORY
;Exit:  none
;Destr: AH BX CH
;----------------------------------------------------------
PrintFrame	proc
	
NextLine:	cmp ah, al
		je EndFrame

		call PrintFrameLine
		
		add bx, dx
		inc ah
		jmp NextLine

EndFrame:	ret
		endp

;----------------------------------------------------------
;Prints line at given place with given filler
;Enter: BX = line_begin, CL = FRAME_WIDTH, 
;	SI = FRAME_FILL, ES = VIDEO_MEMORY 
;Exit:  BX = line_end
;Destr: BX CH
;----------------------------------------------------------
PrintFrameLine	proc
		mov ch, 0

NextSymbol:	cmp ch, cl
		je EndFrameLine

		mov es:[bx], si
		inc bx
		inc bx

		inc ch
		jmp NextSymbol

EndFrameLine:	ret
		endp

;----------------------------------------------------------
;PrintFrameColumn prints a column at given place with given filler
;Enter: AL = FRAME_HEIGHT, BX = column_begin, DX = LINE_LENGTH * 2
;	ES = VIDEO_MEMORY, SI = FRAME_COLUMN_BORDER
;Exit:  BX = column_end
;Destr: AH, BX
;----------------------------------------------------------
PrintFrameColumn	proc
		mov ah, 0

NextFrameColumnSymbol:
		cmp ah, al
		je EndFrameColumn

		mov es:[bx], si
		
		add bx, dx
		inc ah
		jmp NextFrameColumnSymbol

EndFrameColumn:	ret
		endp

;----------------------------------------------------------
;PrintBorder prints frame border
;Enter: AL = FRAME_HEIGHT, CL = FRAME_WIDTH, ES = VIDEO_MEMORY
;Exit:  none
;Destr: AH, BX, CH, DX, SI
;----------------------------------------------------------
PrintBorder	proc
		
		;print left column		
		mov bx, (X_BEGIN + (Y_BEGIN - 1) * LINE_LENGTH) * 2		
		mov dx, LINE_LENGTH * 2
		mov si, FRAME_COLUMN_BORDER
		call PrintFrameColumn
		
		;print right column
		mov bx, (X_BEGIN + FRAME_WIDTH - 1 + (Y_BEGIN - 1) * LINE_LENGTH) * 2
		call PrintFrameColumn

		;print top line
		mov si, FRAME_LINE_BORDER
		mov bx, (X_BEGIN + (Y_BEGIN - 1) * LINE_LENGTH) * 2
		call PrintFrameLine

		;print bottom line
		mov bx, (X_BEGIN + (Y_BEGIN - 2 + FRAME_HEIGHT) * LINE_LENGTH) * 2
		call PrintFrameLine

		ret
		endp

end		Start









