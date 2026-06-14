; ============================================================
; HOSTEL ROOM ALLOCATION SYSTEM
; ------------------------------------------------------------
; Student  : Afaq Ahmed
; Reg No.  : 24-SE-080
; Section  : B
; Subject  : Computer Organization & Assembly Language (COAL)
; Tool     : EMU8086 / MASM  |  Mode: 8086 Real Mode (16-bit)
; ============================================================

.MODEL SMALL
.STACK 100h

; ============================================================
;  DATA SEGMENT
; ============================================================
.DATA

; --- Room Status Array  (0 = Vacant, 1 = Booked) -----------
roomStatus  DB 0,0,0,0,0,0,0,0,0,0  ; Rooms 101-110

; --- Room Type Descriptions (index matches roomStatus) -----
; Type codes: 1=Single, 2=Double, 3=Suite
roomType    DB 1,1,2,2,1,2,3,1,2,3  ; 10 rooms

; --- Tenant Names (10 x 16 bytes, space-padded) ------------
tenantNames DB "                "   ; Room 101
            DB "                "   ; Room 102
            DB "                "   ; Room 103
            DB "                "   ; Room 104
            DB "                "   ; Room 105
            DB "                "   ; Room 106
            DB "                "   ; Room 107
            DB "                "   ; Room 108
            DB "                "   ; Room 109
            DB "                "   ; Room 110

; --- Room base number (display) ----------------------------
roomBase    DW 101

; --- Input buffer ------------------------------------------
inputBuf    DB 16 DUP(0)

; --- Temp storage ------------------------------------------
tempRoom    DW 0
nameLen     DB 0

; === STRINGS ===============================================

; Intro screen
introLine1  DB "  ================================================$"
introLine2  DB "  ||                                            ||$"
introLine3  DB "  ||     HITEC UNIVERSITY HOSTEL SYSTEM         ||$"
introLine4  DB "  ||       Hostel Room Allocation System        ||$"
introLine5  DB "  ||                                            ||$"
introLine6  DB "  ||  Developer : Afaq Ahmed  (24-SE-080)       ||$"
introLine7  DB "  ||  Section B | COAL Semester Project         ||$"
introLine8  DB "  ||                                            ||$"
introLine9  DB "  ================================================$"
introLine10 DB "  Press any key to continue...$"

; Main menu
menuTitle   DB "  ============  MAIN MENU  ============$"
menuOpt1    DB "  [1] View All Rooms$"
menuOpt2    DB "  [2] Book a Room$"
menuOpt3    DB "  [3] Vacate a Room$"
menuOpt4    DB "  [4] Room Summary$"
menuOpt5    DB "  [5] Exit$"
menuPrompt  DB "  Enter choice (1-5): $"

; Room list header
listHdr1    DB "  ==========================================$"
listHdr2    DB "  Room   Status     Type         Tenant$"
listHdr3    DB "  ==========================================$"

; Status strings
vacantStr   DB "  [VACANT] $"
bookedStr   DB "  [BOOKED] $"

; Type strings
singleStr   DB "Single     $"
doubleStr   DB "Double     $"
suiteStr    DB "Suite      $"

; Booking prompts
bookPrompt  DB "  Enter Room Number (101-110): $"
namePrompt  DB "  Enter Tenant Name (max 15 chars): $"
bookOK      DB "  Room booked successfully!$"
bookFail    DB "  Room is already booked!$"
bookBad     DB "  Invalid room number!$"

; Vacate prompts
vacPrompt   DB "  Enter Room Number to Vacate (101-110): $"
vacOK       DB "  Room vacated successfully!$"
vacFail     DB "  Room is already vacant!$"

; Summary strings
sumHdr      DB "  ===== ROOM SUMMARY =====$"
sumVacant   DB "  Vacant Rooms  : $"
sumBooked   DB "  Booked Rooms  : $"
sumTotal    DB "  Total  Rooms  : 10$"

; Common strings
pressKey    DB "  Press any key to return to menu...$"
colonSp     DB " : $"
newLine     DB 13,10,"$"
room_prefix DB "  Room $"

; ============================================================
;  CODE SEGMENT
; ============================================================
.CODE

; ============================================================
;  MACRO: Print a $ terminated string in DS:DX
; ============================================================
PRINT MACRO strAddr
    LEA  DX, strAddr
    MOV  AH, 09h
    INT  21h
ENDM

; ============================================================
;  PROC: CLEAR_SCREEN  - scrolls display blank via BIOS
; ============================================================
CLEAR_SCREEN PROC
    MOV  AX, 0600h   ; Scroll up, blank window
    MOV  BH, 07h     ; Attribute (light gray on black)
    MOV  CX, 0000h   ; Top-left corner (row 0, col 0)
    MOV  DX, 184Fh   ; Bottom-right (row 24, col 79)
    INT  10h
    ; Move cursor to top-left
    MOV  AH, 02h
    MOV  BH, 00h
    MOV  DX, 0000h
    INT  10h
    RET
CLEAR_SCREEN ENDP           ; FIX #1: named ENDP

; ============================================================
;  PROC: PRINT_NEWLINE
; ============================================================
PRINT_NEWLINE PROC
    MOV  AH, 02h
    MOV  DL, 13
    INT  21h
    MOV  DL, 10
    INT  21h
    RET
PRINT_NEWLINE ENDP          ; FIX #1: named ENDP

; ============================================================
;  PROC: WAIT_KEY  - waits for any key press
; ============================================================
WAIT_KEY PROC
    PRINT pressKey
    CALL PRINT_NEWLINE
    MOV  AH, 00h
    INT  16h         ; BIOS keyboard wait
    RET
WAIT_KEY ENDP               ; FIX #1: named ENDP

; ============================================================
;  PROC: PRINT_DIGIT  - prints a single decimal digit in AL
; ============================================================
PRINT_DIGIT PROC
    ADD  AL, '0'
    MOV  AH, 02h
    MOV  DL, AL
    INT  21h
    RET
PRINT_DIGIT ENDP            ; FIX #1: named ENDP

; ============================================================
;  PROC: PRINT_NUMBER  - prints 16-bit number in AX (0-999)
; ============================================================
PRINT_NUMBER PROC
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX
    MOV  BX, 10
    MOV  CX, 0        ; digit count
PN_LOOP:
    XOR  DX, DX
    DIV  BX            ; AX = quotient, DX = remainder
    PUSH DX            ; save digit
    INC  CX
    TEST AX, AX
    JNZ  PN_LOOP
PN_PRINT:
    POP  AX
    CALL PRINT_DIGIT
    LOOP PN_PRINT
    POP  DX
    POP  CX
    POP  BX
    POP  AX
    RET
PRINT_NUMBER ENDP           ; FIX #1: named ENDP

; ============================================================
;  PROC: SHOW_INTRO  - introductory splash screen
; ============================================================
SHOW_INTRO PROC
    CALL CLEAR_SCREEN
    CALL PRINT_NEWLINE
    CALL PRINT_NEWLINE
    PRINT introLine1
    CALL PRINT_NEWLINE
    PRINT introLine2
    CALL PRINT_NEWLINE
    PRINT introLine3
    CALL PRINT_NEWLINE
    PRINT introLine4
    CALL PRINT_NEWLINE
    PRINT introLine5
    CALL PRINT_NEWLINE
    PRINT introLine6
    CALL PRINT_NEWLINE
    PRINT introLine7
    CALL PRINT_NEWLINE
    PRINT introLine8
    CALL PRINT_NEWLINE
    PRINT introLine9
    CALL PRINT_NEWLINE
    CALL PRINT_NEWLINE
    PRINT introLine10
    CALL PRINT_NEWLINE
    ; Wait for key press
    MOV  AH, 00h
    INT  16h
    RET
SHOW_INTRO ENDP             ; FIX #1: named ENDP

; ============================================================
;  PROC: SHOW_MENU  - main menu display
; ============================================================
SHOW_MENU PROC
    CALL CLEAR_SCREEN
    CALL PRINT_NEWLINE
    PRINT menuTitle
    CALL PRINT_NEWLINE
    CALL PRINT_NEWLINE
    PRINT menuOpt1
    CALL PRINT_NEWLINE
    PRINT menuOpt2
    CALL PRINT_NEWLINE
    PRINT menuOpt3
    CALL PRINT_NEWLINE
    PRINT menuOpt4
    CALL PRINT_NEWLINE
    PRINT menuOpt5
    CALL PRINT_NEWLINE
    CALL PRINT_NEWLINE
    PRINT menuPrompt
    RET
SHOW_MENU ENDP              ; FIX #1: named ENDP

; ============================================================
;  PROC: VIEW_ROOMS  - lists all rooms with status & details
; ============================================================
VIEW_ROOMS PROC
    CALL CLEAR_SCREEN
    CALL PRINT_NEWLINE
    PRINT listHdr1
    CALL PRINT_NEWLINE
    PRINT listHdr2
    CALL PRINT_NEWLINE
    PRINT listHdr3
    CALL PRINT_NEWLINE

    MOV  CX, 10         ; loop 10 rooms
    MOV  SI, 0          ; room index (0-9)

VR_LOOP:
    PUSH CX
    PUSH SI             ; FIX #2: protect SI across PRINT_NUMBER call

    ; --- Print "  Room " prefix ---
    PRINT room_prefix

    ; --- Print room number (101 + SI) ---
    ; FIX #2: removed wrong ADC AH,0; use BX to hold index safely
    MOV  BX, SI
    MOV  AX, 101
    ADD  AX, BX         ; AX = 101..110 (no carry possible)
    CALL PRINT_NUMBER

    POP  SI             ; FIX #2: restore SI after PRINT_NUMBER

    ; --- Print "   " spacer ---
    MOV  AH, 02h
    MOV  DL, ' '
    INT  21h
    MOV  DL, ' '
    INT  21h
    MOV  DL, ' '
    INT  21h

    ; --- Print status (VACANT or BOOKED) ---
    MOV  BL, roomStatus[SI]
    CMP  BL, 0
    JNE  VR_BOOKED
    PRINT vacantStr
    JMP  VR_TYPE
VR_BOOKED:
    PRINT bookedStr

VR_TYPE:
    ; --- Print room type ---
    MOV  BL, roomType[SI]
    CMP  BL, 1
    JE   VR_SINGLE
    CMP  BL, 2
    JE   VR_DOUBLE
    PRINT suiteStr
    JMP  VR_TENANT
VR_SINGLE:
    PRINT singleStr
    JMP  VR_TENANT
VR_DOUBLE:
    PRINT doubleStr

VR_TENANT:
    ; --- Print tenant name if booked ---
    MOV  BL, roomStatus[SI]
    CMP  BL, 0
    JE   VR_SKIP_NAME

    ; Compute offset into tenantNames (SI * 16)
    MOV  BX, SI
    SHL  BX, 4            ; BX = SI * 16
    LEA  DI, tenantNames
    ADD  DI, BX           ; DI -> start of tenant name

    ; Print up to 15 chars (stop at space padding or null)
    MOV  CX, 15
VR_NAME_LOOP:
    MOV  AL, [DI]
    CMP  AL, ' '
    JE   VR_SKIP_NAME
    CMP  AL, 0
    JE   VR_SKIP_NAME
    MOV  AH, 02h
    MOV  DL, AL
    INT  21h
    INC  DI
    LOOP VR_NAME_LOOP

VR_SKIP_NAME:
    CALL PRINT_NEWLINE
    INC  SI
    POP  CX
    LOOP VR_LOOP

    CALL PRINT_NEWLINE
    PRINT listHdr1
    CALL PRINT_NEWLINE
    CALL PRINT_NEWLINE
    CALL WAIT_KEY
    RET
VIEW_ROOMS ENDP             ; FIX #1: named ENDP

; ============================================================
;  PROC: GET_ROOM_NUMBER  - read room number from user,
;        returns 0-based index in BX (-1 = invalid)
; ============================================================
GET_ROOM_NUMBER PROC
    ; Read hundreds digit (must be '1')
    MOV  AH, 01h
    INT  21h
    CMP  AL, '1'
    JNE  GRN_BAD
    MOV  BL, AL           ; save hundreds digit

    ; Read tens digit (must be '0' or '1')
    MOV  AH, 01h
    INT  21h
    CMP  AL, '0'
    JB   GRN_BAD
    CMP  AL, '1'
    JA   GRN_BAD
    MOV  BH, AL           ; save tens digit

    ; Read units digit
    MOV  AH, 01h
    INT  21h
    CMP  AL, '0'
    JB   GRN_BAD
    CMP  AL, '9'
    JA   GRN_BAD

    ; FIX #3: Save units digit in DL instead of PUSH AX
    ;         (PUSH/POP AX was broken because MUL overwrites AX between push and pop)
    MOV  DL, AL           ; save units digit in DL

    ; Compute: hundreds*100
    SUB  BL, '0'
    MOV  AL, BL
    MOV  AH, 0
    MOV  CX, 100
    MUL  CX               ; AX = hundreds*100
    MOV  CX, AX           ; CX = hundreds*100

    ; Add tens*10
    SUB  BH, '0'
    MOV  AL, BH
    MOV  AH, 0
    MOV  BX, 10
    MUL  BX               ; AX = tens*10
    ADD  CX, AX           ; CX = hundreds*100 + tens*10

    ; Add units
    MOV  AL, DL           ; FIX #3: restore units digit from DL
    SUB  AL, '0'
    MOV  AH, 0
    ADD  CX, AX           ; CX = full 3-digit number

    ; Validate 101 <= CX <= 110
    CMP  CX, 101
    JB   GRN_BAD
    CMP  CX, 110
    JA   GRN_BAD

    ; Convert to 0-based index
    SUB  CX, 101
    MOV  BX, CX
    RET

GRN_BAD:
    MOV  BX, 0FFFFh       ; signal: invalid
    RET
GET_ROOM_NUMBER ENDP        ; FIX #1: named ENDP

; ============================================================
;  PROC: BOOK_ROOM  - books a selected room
; ============================================================
BOOK_ROOM PROC
    CALL CLEAR_SCREEN
    CALL PRINT_NEWLINE
    PRINT bookPrompt
    CALL GET_ROOM_NUMBER
    CALL PRINT_NEWLINE

    CMP  BX, 0FFFFh
    JE   BR_INVALID

    ; Check if already booked
    MOV  AL, roomStatus[BX]
    CMP  AL, 1
    JE   BR_ALREADY

    ; --- Get tenant name ---
    CALL PRINT_NEWLINE
    PRINT namePrompt

    ; Store index for later
    MOV  tempRoom, BX

    ; FIX #4: Zero out inputBuf before reading to avoid stale data
    LEA  DI, inputBuf
    MOV  CX, 16
    MOV  AL, 0
BR_ZERO_BUF:
    MOV  [DI], AL
    INC  DI
    LOOP BR_ZERO_BUF

    ; Read name character by character
    MOV  SI, 0
    LEA  DI, inputBuf

BR_NAME_LOOP:
    MOV  AH, 01h
    INT  21h
    CMP  AL, 13           ; Enter key?
    JE   BR_NAME_DONE
    CMP  SI, 15           ; max 15 chars
    JAE  BR_NAME_LOOP     ; ignore if buffer full
    MOV  [DI], AL
    INC  DI
    INC  SI
    JMP  BR_NAME_LOOP

BR_NAME_DONE:
    MOV  AX, SI             ; 16-bit to 16-bit: valid in 8086
    MOV  nameLen, AL        ; AL holds low byte of SI (name length, max 15)

    ; Copy name to tenantNames[BX*16]
    MOV  BX, tempRoom
    MOV  AX, BX
    SHL  AX, 4            ; AX = BX*16
    LEA  DI, tenantNames
    ADD  DI, AX           ; DI -> slot

    ; Fill slot with spaces first
    PUSH DI
    MOV  CX, 16
    MOV  AL, ' '
BR_FILL:
    MOV  [DI], AL
    INC  DI
    LOOP BR_FILL
    POP  DI

    ; Copy actual name
    LEA  SI, inputBuf
    MOV  CL, nameLen
    MOV  CH, 0
    CMP  CX, 0
    JE   BR_SET_STATUS
BR_COPY:
    MOV  AL, [SI]
    MOV  [DI], AL
    INC  SI
    INC  DI
    LOOP BR_COPY

BR_SET_STATUS:
    ; Set status = Booked
    MOV  BX, tempRoom
    MOV  roomStatus[BX], 1
    CALL PRINT_NEWLINE
    CALL PRINT_NEWLINE
    PRINT bookOK
    CALL PRINT_NEWLINE
    CALL WAIT_KEY
    RET

BR_ALREADY:
    CALL PRINT_NEWLINE
    PRINT bookFail
    CALL PRINT_NEWLINE
    CALL WAIT_KEY
    RET

BR_INVALID:
    PRINT bookBad
    CALL PRINT_NEWLINE
    CALL WAIT_KEY
    RET
BOOK_ROOM ENDP              ; FIX #1: named ENDP

; ============================================================
;  PROC: VACATE_ROOM  - vacates a booked room
; ============================================================
VACATE_ROOM PROC
    CALL CLEAR_SCREEN
    CALL PRINT_NEWLINE
    PRINT vacPrompt
    CALL GET_ROOM_NUMBER
    CALL PRINT_NEWLINE

    CMP  BX, 0FFFFh
    JE   VCR_INVALID

    ; Check if already vacant
    MOV  AL, roomStatus[BX]
    CMP  AL, 0
    JE   VCR_ALREADY

    ; Set status = Vacant
    MOV  roomStatus[BX], 0

    ; Clear tenant name (fill with spaces)
    MOV  AX, BX
    SHL  AX, 4
    LEA  DI, tenantNames
    ADD  DI, AX
    MOV  CX, 16
    MOV  AL, ' '
VCR_CLEAR:
    MOV  [DI], AL
    INC  DI
    LOOP VCR_CLEAR

    CALL PRINT_NEWLINE
    PRINT vacOK
    CALL PRINT_NEWLINE
    CALL WAIT_KEY
    RET

VCR_ALREADY:
    PRINT vacFail
    CALL PRINT_NEWLINE
    CALL WAIT_KEY
    RET

VCR_INVALID:
    PRINT bookBad
    CALL PRINT_NEWLINE
    CALL WAIT_KEY
    RET
VACATE_ROOM ENDP            ; FIX #1: named ENDP

; ============================================================
;  PROC: SHOW_SUMMARY  - counts and displays vacant/booked
; ============================================================
SHOW_SUMMARY PROC
    CALL CLEAR_SCREEN
    CALL PRINT_NEWLINE
    PRINT sumHdr
    CALL PRINT_NEWLINE
    CALL PRINT_NEWLINE

    MOV  CX, 10
    MOV  SI, 0
    MOV  BX, 0           ; vacant count
    MOV  DX, 0           ; booked count

SS_LOOP:
    MOV  AL, roomStatus[SI]
    CMP  AL, 0
    JNE  SS_INC_BOOKED
    INC  BX
    JMP  SS_NEXT
SS_INC_BOOKED:
    INC  DX
SS_NEXT:
    INC  SI
    LOOP SS_LOOP

    PRINT sumTotal
    CALL PRINT_NEWLINE

    ; FIX #5: Save booked count (DX) before PRINT_NUMBER corrupts it
    PRINT sumVacant
    PUSH DX              ; protect booked count
    MOV  AX, BX
    CALL PRINT_NUMBER
    POP  DX              ; restore booked count
    CALL PRINT_NEWLINE

    PRINT sumBooked
    MOV  AX, DX
    CALL PRINT_NUMBER
    CALL PRINT_NEWLINE

    CALL PRINT_NEWLINE
    CALL WAIT_KEY
    RET
SHOW_SUMMARY ENDP           ; FIX #1: named ENDP

; ============================================================
;  MAIN PROCEDURE
; ============================================================
MAIN PROC
    ; Initialize DS to data segment
    MOV  AX, @DATA
    MOV  DS, AX

    ; Show introductory splash
    CALL SHOW_INTRO

MENU_LOOP:
    CALL SHOW_MENU

    ; Read single-character choice
    MOV  AH, 01h
    INT  21h
    CALL PRINT_NEWLINE

    CMP  AL, '1'
    JE   DO_VIEW
    CMP  AL, '2'
    JE   DO_BOOK
    CMP  AL, '3'
    JE   DO_VACATE
    CMP  AL, '4'
    JE   DO_SUMMARY
    CMP  AL, '5'
    JE   DO_EXIT

    ; Invalid choice - loop back
    JMP  MENU_LOOP

DO_VIEW:
    CALL VIEW_ROOMS
    JMP  MENU_LOOP

DO_BOOK:
    CALL BOOK_ROOM
    JMP  MENU_LOOP

DO_VACATE:
    CALL VACATE_ROOM
    JMP  MENU_LOOP

DO_SUMMARY:
    CALL SHOW_SUMMARY
    JMP  MENU_LOOP

DO_EXIT:
    CALL CLEAR_SCREEN
    MOV  AH, 09h
    LEA  DX, introLine3
    INT  21h
    CALL PRINT_NEWLINE
    MOV  AH, 4Ch         ; Exit to DOS
    MOV  AL, 0
    INT  21h

MAIN ENDP

END MAIN