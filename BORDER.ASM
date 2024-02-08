.286
.model tiny
.code
org 100h

X_BEGIN			equ 20
Y_BEGIN			equ 5
FRAME_WIDTH		equ 40
FRAME_HEIGHT		equ 5
LINE_LENGTH		equ 80

FRAME_FILL		equ 1020h
FRAME_SHADOW_FILL	equ 0020h
DEMONSTRATION_FILL	equ 0ff20h ;wtf order???

VIDEO_MEMORY		equ 0b800h
NUM_OF_SCREEN_SYMBOLS	equ 4000

Start:		call PrintDemonstrationBackground
		call SetFrameShadowRegisters
		call PrintFrame		;prints shadow
		call SetFrameRegisters	;set initial values
		call PrintFrame

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

DEM_BACKGROUND:	cmp bx, NUM_OF_SCREEN_SYMBOLS
		je END_DEM_BACKGROUND
		
		mov es:[bx], si

		inc bx
		inc bx
		jmp DEM_BACKGROUND

END_DEM_BACKGROUND:
		ret
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

end		Start









