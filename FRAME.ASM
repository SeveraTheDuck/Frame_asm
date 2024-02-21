.286
.model tiny
.code
org 100h

;----------------------------------------------------------
X_CENTER			equ 40		; frame center on horizontal
Y_CENTER			equ 12		; frame center on vertical

PATTERN_STRING_SIZE		equ 9		; size of frame pattern string
PATTERN_STRING_STEP		equ 3		; 3 symbols from pattern are used to draw a line
NUM_OF_LINE_BORDER_SYMBOLS	equ 2		; left and right symbols in line

ANIMATION_BEGIN_FRAME_WIDTH	equ 2		; initial frame width during animation
ANIMATION_STEP_IN_SYMBOLS	equ 2		; width increase by animation step
ANIMATION_WAIT			equ 02fffh	; delay before animation next step

BACKGROUND_FILL_PATTERN		equ 70b0h	; white background black ° symbol
FRAME_COLOR			equ 1fh		; blue background with white symbols
SHADOW_COLOR			equ 88h		; black background with grey symbols

KEYBOARD_ENTER_ADDRESS		equ 82h		; memory address where terminal input starts
DECIMAL_RADIX			equ 10		; decimal radix for calculations
ZERO_SYMBOL			equ '0'		; ascii code of '0' symbol

VIDEO_MEMORY_ADDRESS		equ 0b800h	; segment address of video memory, that is printed on the screen
VIDEO_MEM_CELL_SIZE		equ 2		; two bytes: color and symbol
LINE_LENGTH_IN_SYMBOLS		equ 80		; window width in symbols
LINES_NUMBER			equ 25		; window height in symbols
;----------------------------------------------------------

Start:		
		mov ax, VIDEO_MEMORY_ADDRESS
		mov es, ax			; es = VIDEO_MEMORY_ADDRESS

		xor di, di			; di = 0

		cld 				; clear DF flag

		call FillBackground
		call GetInput			; gets terminal input
		
		call PrintAnimatedFrame

		mov ax, 4c00h			; terminate program
		int 21h

;----------------------------------------------------------
; FillBackground fills background with a constant filler.
; Enter: ES = VIDEO_MEMORY_ADDRESS, DI = 0, DF = 0
; Exit:  none
; Destr: AX, CX, DI
;----------------------------------------------------------
FillBackground	proc

		;----------------------
		; cx = num_of_screen_symbols
		;----------------------
		mov cx, LINE_LENGTH_IN_SYMBOLS * LINES_NUMBER
		mov ax, BACKGROUND_FILL_PATTERN

		;----------------------
		; print pattern in every symbol
		;----------------------
		rep stosw

		ret
		endp

;----------------------------------------------------------
; GetInput gets input values from user
; Enter: none
; Exit:	 BL = FRAME_WIDTH, BH = FRAME_HEIGHT
; Destr: AX, BX, CX, DI
;----------------------------------------------------------
GetInput	proc

		mov di, KEYBOARD_ENTER_ADDRESS
		mov cl, DECIMAL_RADIX
		
		;----------------------
		; read frame width
		;----------------------
		call ReadDecimalValue
		mov bl, al
		
		;----------------------
		; skip space symbol
		;----------------------
		inc di

		;----------------------
		; read frame height
		;----------------------
		call ReadDecimalValue
		mov bh, al

		;----------------------
		; kill last byte in width and height
		;----------------------
		shr bl, 1
		shl bl, 1
		shr bh, 1
		shl bh, 1

		;----------------------
		; skip space and read pattern
		;----------------------
		inc di
		call GetInputPattern

		ret
		endp

;----------------------------------------------------------
; ReadDecimalValue reads decimal number (up to 2 symbols)
; Enter: CL = DECIMAL_RADIX, DI = READ_ADDRESS (in ds)
; Exit:  AL = value
; Destr: AX, DI
;----------------------------------------------------------
ReadDecimalValue proc

		xor ax, ax

		;----------------------
		; al = [di++] - '0'
		;----------------------
		mov al, [di]
		sub al, ZERO_SYMBOL
		inc di
		
		;----------------------
		;if [di] == ' '
		;----------------------
		cmp [di], byte ptr ' '
		je ReadNumberEnd

		;----------------------
		;al = 10 * al + [di] - '0'
		;----------------------
		mul cl
		add al, [di]
		sub al, ZERO_SYMBOL
		inc di

ReadNumberEnd:	ret
		endp

;----------------------------------------------------------
; GetInputPattern gets the pattern user choose.
; It can be a number from 1 to 4 for pre-installed patterns
; or 0 for a user pattern
; Enter: DI = user_input
; Exit:  SI = pattern_string
; Destr: AX, CL, SI
;----------------------------------------------------------
GetInputPattern	proc

		;----------------------
		; check if user pattern selected
		;----------------------
		cmp byte ptr [di], ZERO_SYMBOL
		je UserPattern
		
		;----------------------
		; set frame pattern to prepared one
		; si = frame_pattern + ([di] - '0' - 1) * 9
		;----------------------
		xor ax, ax
		mov al, [di]
		sub al, ZERO_SYMBOL + 1
		mov cl, PATTERN_STRING_SIZE
		mul cl

		mov si, offset frame_pattern
		add si, ax

		jmp EndGetInputPattern

UserPattern:	;----------------------
		; si = pattern_string
		;----------------------
		inc di
		inc di
		mov si, di

EndGetInputPattern:	
		ret
		endp

;----------------------------------------------------------
; PrintAnimatedFrame prints animated frame of given size and pattern
; Enter: BL = frame_width, BH = frame_height, SI = frame_pattern,
; 	 ES = VIDEO_MEMORY_ADDRESS
; Exit:  none
; Destr: AX, BX, CX, DX, SI, DI
;----------------------------------------------------------
PrintAnimatedFrame proc

		xor cx, cx
		mov cl, ANIMATION_BEGIN_FRAME_WIDTH

		;----------------------
		; di = frame_center
		;----------------------
		mov di, (X_CENTER + (Y_CENTER - 1) * LINE_LENGTH_IN_SYMBOLS) * VIDEO_MEM_CELL_SIZE

BeginAnimation:	cmp cl, bl
		jg EndAnimation

		;----------------------
		; set frame color
		;----------------------
		xor ax, ax
		mov ah, FRAME_COLOR

		;----------------------
		; save needed register values
		;----------------------
		push bx
		push cx
		push si
		push di

		;----------------------
		; bl = current_frame_width
		; print frame with current width
		;----------------------
		mov bl, cl
		call PrintFrame

		;----------------------
		; DOS Fn 86h - wait
		;----------------------
		xor cx, cx
		mov dx, ANIMATION_WAIT
		mov ah, 86h
		int 15h

		;----------------------
		; get register values back
		;----------------------
		pop di
		pop si
		pop cx
		pop bx
		add cl, ANIMATION_STEP_IN_SYMBOLS
		jmp BeginAnimation

EndAnimation:	ret
		endp

;----------------------------------------------------------
; PrintFrame prints a frame at given place with given color and symbols
; Enter: AH = FRAME_COLOR,          BL = frame_width,   BH = frame_heigth, 
; 	 ES = VIDEO_MEMORY_ADDRESS, SI -> pattern_line, DI = frame_center, DF = 0
; Exit:  none
; Destr: AX, BX, CX, DX, SI, DI
;----------------------------------------------------------
PrintFrame	proc

		;----------------------
		; save frame_color in ax by push/pop
		; di = frame_corner
		;----------------------
		push ax
		call FindFrameCorner
		pop ax

		;----------------------
		; save frame_corner for shadow
		;----------------------
		push di

		;----------------------
		; PRINT TOP ROW
		; cl = num_of_interior_symbols = frame_width - 2
		;----------------------
		xor cx, cx
		mov cl, bl
		sub cl, NUM_OF_LINE_BORDER_SYMBOLS
		call PrintRow

		;----------------------
		; PRINT MIDDLE ROWS
		; cl = num_of_middle_rows = frame_height - 2
		;----------------------
		xor cx, cx
		mov cl, bh
		sub cl, NUM_OF_LINE_BORDER_SYMBOLS

MiddleRows:	;----------------------
		; save cx for external loop
		; cl = num_of_internal_symbols = frame_width - 2
		;----------------------
		push cx
		xor cx, cx
		mov cl, bl
		sub cl, NUM_OF_LINE_BORDER_SYMBOLS
		call PrintRow
		
		;----------------------
		; get cx value for external loop
		;----------------------
		pop cx

		;----------------------
		; si -= 3 during the loop
		; for repeating pattern
		;----------------------
		sub si, PATTERN_STRING_STEP

		loop MiddleRows

		;----------------------
		; PRINT BOTTOM ROW
		; cl = num_of_internal_symbols = frame_width - 2
		; si += 3 to move the pattern
		;----------------------
		xor cx, cx
		mov cl, bl
		sub cl, NUM_OF_LINE_BORDER_SYMBOLS 
		add si, PATTERN_STRING_STEP
		call PrintRow
		
		;----------------------
		; makes you a sandwich
		;----------------------
		call PrintShadow

		ret
		endp

;----------------------------------------------------------
; FindFrameCorner finds the upper left corner of the frame from its center
; Enter: BL = frame_width, BH = frame_height, DI = frame_center
; Exit:  DI = frame_corner_position
; Destr: AX, CX, DI
;----------------------------------------------------------
FindFrameCorner	proc

		xor ax, ax

		;----------------------
		; di -= frame_height * LINE_LENGTH_IN_SYMBOLS
		;----------------------
		mov al, bh
		mov cl, LINE_LENGTH_IN_SYMBOLS
		mul cl
		sub di, ax

		xor ax, ax

		;----------------------
		; di -= frame_width
		;----------------------
		mov al, bl
		sub di, ax

		ret
		endp

;----------------------------------------------------------
; PrintRow prints a row of symbols with a given from ds pattern
; Enter: AH = frame_color, CX = num_of_internal_symbols, SI -> pattern_line
; Exit:  none
; Destr: AL, CX, SI, DI
;----------------------------------------------------------
PrintRow	proc
		
		;----------------------
		; remember start position
		; for quick return
		;----------------------
		push di

		;----------------------
		; read pattern symbol
		; print first symbol
		;----------------------
		lodsb
		stosw
		
		;----------------------
		; read pattern symbol
		; print internal symbols
		;----------------------
		lodsb
		rep stosw

		;----------------------
		; read pattern symbol
		; print last symbol
		;----------------------
		lodsb
		stosw
		
		;----------------------
		; return start position
		; and move to next line
		;----------------------
		pop di
		add di, LINE_LENGTH_IN_SYMBOLS * VIDEO_MEM_CELL_SIZE

		ret
		endp

;----------------------------------------------------------
; PrintShadow prints shadow for a frame
; Enter: BL = frame_width, BH = frame_height, STACK: frame_corner
; Exit:  none
; Destr: AL, CX, DX, DI
;----------------------------------------------------------
PrintShadow	proc
		
		;----------------------
		; save return address from stack in dx
		; get frame_corner value
		;----------------------
		pop dx
		pop di

		;----------------------
		; print shadow bottom row
		;----------------------

		;----------------------
		; di = shadow_bottom_row_begin + 1
		; only change color
		;----------------------
		xor ax, ax
		mov al, bh
		mov cl, LINE_LENGTH_IN_SYMBOLS * VIDEO_MEM_CELL_SIZE
		mul cl
		add di, ax
		add di, VIDEO_MEM_CELL_SIZE + 1
		
		;----------------------
		; al = shadow_color
		; cl = frame_width
		;----------------------
		xor ax, ax
		mov al, SHADOW_COLOR
		xor cx, cx
		mov cl, bl

PrintSymbolRow:	stosb
		inc di
		loop PrintSymbolRow

		;----------------------
		; print side column
		;----------------------

		;----------------------
		; cx = frame_height
		;----------------------
		xor cx, cx
		mov cl, bh

		;----------------------
		; DF = 1
		;----------------------
		std

		;----------------------
		; print two side symbols
		; and go to the upper line
		;----------------------
PrintSymbolColumn:
		stosb
		dec di
		stosb		
		sub di, (LINE_LENGTH_IN_SYMBOLS - 2) * VIDEO_MEM_CELL_SIZE + 1
		loop PrintSymbolColumn

		;----------------------
		; DF = 0
		;----------------------
		cld
	
		;----------------------
		; get saved return address
		;----------------------
		push dx
		ret
		endp

;----------------------------------------------------------
; array of 4 lines with frame patterns
;----------------------------------------------------------
frame_pattern 	db 0dah, 0c4h, 0bfh, 0b3h, ' ', 0b3h, 0c0h, 0c4h, 0d9h, \
		   0c9h, 0cdh, 0bbh, 0bah, ' ', 0bah, 0c8h, 0cdh, 0bch, \
		    ' ', 0c4h,  ' ', 0b3h, ' ', 0b3h,  ' ', 0c4h,  ' ', \
		   0dah, 0c1h, 0bfh, 0b4h, ' ', 0c3h, 0c0h, 0c2h, 0d9h

end		Start
