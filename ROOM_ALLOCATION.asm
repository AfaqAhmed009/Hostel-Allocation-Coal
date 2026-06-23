; ============================================================
; PROJECT  : ROOM ALLOCATION SYSTEM (Compact Version)
; LANGUAGE : 8086 Assembly (COAL) for EMU8086
; FEATURES : View All Rooms | Book a Room
; ============================================================

.MODEL SMALL
.STACK 200H

; ============================================================
;                     DATA SECTION
; ============================================================
.DATA

    room_nums   DB  101, 102, 103, 201, 202, 203
    room_status DB    0,   0,   0,   0,   0,   0   ; 0=vacant 1=booked
    room_cap    DB    2,   2,   4,   2,   3,   4
    room_floors DB    1,   1,   1,   2,   2,   2

    TOTAL_ROOMS EQU 6

    cur_color   DB  07H

    crlf        DB  13, 10, "$"
    bdr_eq      DB  "=====================================================$"

    ; Intro
    s_title     DB  " ** ROOM ALLOCATION SYSTEM ** | COAL | 8086$"
    s_anykey    DB  " >> Press any key to continue ...$"

    ; Menu
    s_menu      DB  "          [ MAIN MENU ]$"
    s_opt1      DB  "  1. View All Rooms$"
    s_opt2      DB  "  2. Book a Room$"
    s_opt3      DB  "  3. Exit$"
    s_choice    DB  "  Enter choice (1-3) : $"

    ; View rooms header
    s_vh1       DB  "  Room   Floor   Cap   Status$"

    ; Status strings
    s_vacant    DB  "VACANT$"
    s_booked    DB  "BOOKED$"

    ; Book room
    s_enter_r   DB  "  Enter room no (101-103 / 201-203) : $"
    s_invalid   DB  "  !! Invalid room number.$"
    s_alrbook   DB  "  !! Room already BOOKED.$"
    s_booksuc   DB  "  >> Booked successfully!$"
    s_bookedat  DB  "  >> Time : $"
    s_colon     DB  ":$"

    s_return    DB  13,10,"  Press any key to return ...$"
    s_exit      DB  "  Goodbye!$"

; ============================================================
;                     CODE SECTION
; ============================================================
.CODE

; ============================================================
; MAIN
; ============================================================
MAIN PROC
    MOV AX, @DATA
    MOV DS, AX

    CALL INTRO_SCREEN

MENU_LOOP:
    CALL CLEAR_SCREEN
    CALL SHOW_MENU

FLUSH_BUF:
    MOV AH, 01H
    INT 16H
    JZ  MENU_READ
    MOV AH, 00H
    INT 16H
    JMP FLUSH_BUF

MENU_READ:
    MOV AH, 00H
    INT 16H

    CMP AL, '1'
    JE  M_VIEW
    CMP AL, '2'
    JE  M_BOOK
    CMP AL, '3'
    JE  M_EXIT
    JMP MENU_LOOP

M_VIEW:
    CALL CLEAR_SCREEN
    CALL VIEW_ALL_ROOMS
    CALL WAIT_KEY
    JMP  MENU_LOOP

M_BOOK:
    CALL CLEAR_SCREEN
    CALL BOOK_ROOM
    CALL WAIT_KEY
    JMP  MENU_LOOP

M_EXIT:
    CALL CLEAR_SCREEN
    MOV cur_color, 0AH
    LEA DX, s_exit
    CALL CPRINTSTR
    CALL PRINT_CRLF
    MOV AH, 4CH
    INT 21H
MAIN ENDP

; ============================================================
; INTRO_SCREEN  (compact)
; ============================================================
INTRO_SCREEN PROC
    CALL CLEAR_SCREEN

    MOV cur_color, 0EH
    LEA DX, bdr_eq
    CALL CPRINTSTR
    CALL PRINT_CRLF

    LEA DX, s_title
    CALL CPRINTSTR
    CALL PRINT_CRLF

    LEA DX, bdr_eq
    CALL CPRINTSTR
    CALL PRINT_CRLF
    CALL PRINT_CRLF

    MOV cur_color, 0AH
    LEA DX, s_anykey
    CALL CPRINTSTR
    CALL PRINT_CRLF

    MOV AH, 00H
    INT 16H
    RET
INTRO_SCREEN ENDP

; ============================================================
; SHOW_MENU
; ============================================================
SHOW_MENU PROC
    MOV cur_color, 0EH
    LEA DX, bdr_eq
    CALL CPRINTSTR
    CALL PRINT_CRLF
    LEA DX, s_menu
    CALL CPRINTSTR
    CALL PRINT_CRLF
    LEA DX, bdr_eq
    CALL CPRINTSTR
    CALL PRINT_CRLF
    CALL PRINT_CRLF

    MOV cur_color, 0BH
    LEA DX, s_opt1
    CALL CPRINTSTR
    CALL PRINT_CRLF
    LEA DX, s_opt2
    CALL CPRINTSTR
    CALL PRINT_CRLF

    MOV cur_color, 0CH
    LEA DX, s_opt3
    CALL CPRINTSTR
    CALL PRINT_CRLF
    CALL PRINT_CRLF

    MOV cur_color, 07H
    LEA DX, s_choice
    CALL CPRINTSTR
    RET
SHOW_MENU ENDP

; ============================================================
; VIEW_ALL_ROOMS
; ============================================================
VIEW_ALL_ROOMS PROC
    MOV cur_color, 0EH
    LEA DX, bdr_eq
    CALL CPRINTSTR
    CALL PRINT_CRLF
    LEA DX, s_vh1
    CALL CPRINTSTR
    CALL PRINT_CRLF
    LEA DX, bdr_eq
    CALL CPRINTSTR
    CALL PRINT_CRLF

    MOV CX, TOTAL_ROOMS
    MOV SI, 0

VAR_LOOP:
    PUSH CX

    ; Spacing
    MOV cur_color, 07H
    MOV AH, 02H
    MOV DL, ' '
    INT 21H
    INT 21H

    ; Room number
    MOV AL, room_nums[SI]
    CALL PRINT_ROOMNUM

    ; Floor
    MOV AH, 02H
    MOV DL, ' '
    INT 21H
    INT 21H
    INT 21H
    INT 21H
    INT 21H
    MOV AL, room_floors[SI]
    ADD AL, '0'
    MOV DL, AL
    MOV AH, 02H
    INT 21H

    ; Capacity
    MOV AH, 02H
    MOV DL, ' '
    INT 21H
    INT 21H
    INT 21H
    INT 21H
    INT 21H
    MOV AL, room_cap[SI]
    ADD AL, '0'
    MOV DL, AL
    MOV AH, 02H
    INT 21H

    ; Status
    MOV AH, 02H
    MOV DL, ' '
    INT 21H
    INT 21H
    INT 21H

    MOV AL, room_status[SI]
    CMP AL, 0
    JE  VAR_VACANT

    MOV cur_color, 0CH
    LEA DX, s_booked
    CALL CPRINTSTR
    JMP VAR_NEXT

VAR_VACANT:
    MOV cur_color, 0AH
    LEA DX, s_vacant
    CALL CPRINTSTR

VAR_NEXT:
    CALL PRINT_CRLF
    INC SI
    POP CX
    LOOP VAR_LOOP

    MOV cur_color, 07H
    LEA DX, s_return
    CALL CPRINTSTR
    CALL PRINT_CRLF
    RET
VIEW_ALL_ROOMS ENDP

; ============================================================
; BOOK_ROOM
; ============================================================
BOOK_ROOM PROC
    MOV cur_color, 0EH
    LEA DX, bdr_eq
    CALL CPRINTSTR
    CALL PRINT_CRLF
    CALL PRINT_CRLF

    MOV cur_color, 07H
    LEA DX, s_enter_r
    CALL CPRINTSTR

    CALL READ_3DIGIT
    CALL FIND_ROOM_IDX
    CMP DI, 0FFH
    JE  BK_INVALID

    MOV AL, room_status[DI]
    CMP AL, 1
    JE  BK_ALREADY

    ; Book it
    MOV room_status[DI], 1

    ; Get current time
    MOV AH, 2CH
    INT 21H                 ; CH=hours CL=minutes

    MOV cur_color, 0AH
    LEA DX, s_booksuc
    CALL CPRINTSTR
    CALL PRINT_CRLF

    LEA DX, s_bookedat
    CALL CPRINTSTR
    MOV AL, CH
    CALL PRINT_2DIGIT
    LEA DX, s_colon
    CALL CPRINTSTR
    MOV AL, CL
    CALL PRINT_2DIGIT
    CALL PRINT_CRLF
    JMP BK_DONE

BK_ALREADY:
    MOV cur_color, 0CH
    LEA DX, s_alrbook
    CALL CPRINTSTR
    CALL PRINT_CRLF
    JMP BK_DONE

BK_INVALID:
    MOV cur_color, 0CH
    LEA DX, s_invalid
    CALL CPRINTSTR
    CALL PRINT_CRLF

BK_DONE:
    MOV cur_color, 07H
    LEA DX, s_return
    CALL CPRINTSTR
    CALL PRINT_CRLF
    RET
BOOK_ROOM ENDP

; ============================================================
; READ_3DIGIT  -  returns value in BX
; ============================================================
READ_3DIGIT PROC
    MOV AH, 01H
    INT 21H
    SUB AL, '0'
    MOV AH, 0
    MOV BX, AX

    MOV AX, BX
    MOV CX, 100
    MUL CX
    MOV BX, AX

    MOV AH, 01H
    INT 21H
    SUB AL, '0'
    MOV AH, 0
    MOV CX, 10
    MUL CX
    ADD BX, AX

    MOV AH, 01H
    INT 21H
    SUB AL, '0'
    MOV AH, 0
    ADD BX, AX

    ; Drain leftover CR from buffer
R3D_DRAIN:
    MOV AH, 0BH
    INT 21H
    CMP AL, 0FFH
    JNE R3D_DONE
    MOV AH, 01H
    INT 21H
    JMP R3D_DRAIN
R3D_DONE:
    CALL PRINT_CRLF
    RET
READ_3DIGIT ENDP

; ============================================================
; FIND_ROOM_IDX  -  Input BX=room no, Output DI=index/FFH
; ============================================================
FIND_ROOM_IDX PROC
    MOV CX, TOTAL_ROOMS
    MOV SI, 0
FRI_LOOP:
    MOV AL, room_nums[SI]
    MOV AH, 0
    CMP AX, BX
    JE  FRI_FOUND
    INC SI
    LOOP FRI_LOOP
    MOV DI, 0FFH
    RET
FRI_FOUND:
    MOV DI, SI
    RET
FIND_ROOM_IDX ENDP

; ============================================================
; PRINT_ROOMNUM  -  Input AL=room number byte
; ============================================================
PRINT_ROOMNUM PROC
    MOV AH, 0
    MOV BL, 10
    DIV BL
    MOV CL, AH
    MOV AH, 0
    DIV BL

    MOV DL, AL
    ADD DL, '0'
    MOV AH, 02H
    INT 21H

    MOV DL, AH
    ADD DL, '0'
    MOV AH, 02H
    INT 21H

    MOV DL, CL
    ADD DL, '0'
    MOV AH, 02H
    INT 21H
    RET
PRINT_ROOMNUM ENDP

; ============================================================
; PRINT_2DIGIT  -  Input AL=value 0-99
; ============================================================
PRINT_2DIGIT PROC
    MOV AH, 0
    MOV BL, 10
    DIV BL
    MOV CL, AH
    MOV DL, AL
    ADD DL, '0'
    MOV AH, 02H
    INT 21H
    MOV DL, CL
    ADD DL, '0'
    MOV AH, 02H
    INT 21H
    RET
PRINT_2DIGIT ENDP

; ============================================================
; CPRINTSTR  -  Colored string print via BIOS INT 10H
; Input: DX=string offset, cur_color=attribute byte
; ============================================================
CPRINTSTR PROC
    PUSH SI
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX

    MOV SI, DX

CPS_LOOP:
    MOV AL, [SI]
    CMP AL, '$'
    JE  CPS_DONE

    MOV AH, 03H
    MOV BH, 0
    INT 10H

    MOV AH, 09H
    MOV BH, 0
    MOV BL, cur_color
    MOV CX, 1
    INT 10H

    INC DL
    MOV AH, 02H
    MOV BH, 0
    INT 10H

    INC SI
    JMP CPS_LOOP

CPS_DONE:
    POP DX
    POP CX
    POP BX
    POP AX
    POP SI
    RET
CPRINTSTR ENDP

; ============================================================
; PRINT_CRLF
; ============================================================
PRINT_CRLF PROC
    MOV AH, 09H
    LEA DX, crlf
    INT 21H
    RET
PRINT_CRLF ENDP

; ============================================================
; CLEAR_SCREEN
; ============================================================
CLEAR_SCREEN PROC
    MOV AH, 06H
    MOV AL, 00H
    MOV BH, 07H
    MOV CH, 00H
    MOV CL, 00H
    MOV DH, 24
    MOV DL, 79
    INT 10H
    MOV AH, 02H
    MOV BH, 00H
    MOV DX, 0000H
    INT 10H
    RET
CLEAR_SCREEN ENDP

; ============================================================
; WAIT_KEY  -  flushes buffer then waits for a real keypress
; ============================================================
WAIT_KEY PROC
WK_FLUSH:
    MOV AH, 01H
    INT 16H
    JZ  WK_WAIT
    MOV AH, 00H
    INT 16H
    JMP WK_FLUSH
WK_WAIT:
    MOV AH, 00H
    INT 16H
    RET
WAIT_KEY ENDP

END MAIN
