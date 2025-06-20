; -----------------------------------------------------------
; File: makros.inc
; Description: Macro definitions for assembly program with error handling
; Author: [Martin Kvietok]
; Date: [Date]
; -----------------------------------------------------------


; -----------------------------------------------------------
; Macro: PRINT_NEWLINE
; Purpose: Prints a new line (CR + LF)
; Usage: PRINT_NEWLINE
; -----------------------------------------------------------
PRINT_NEWLINE MACRO
    MOV DL, 13       ; Load carriage return (CR)
    MOV AH, 02H      ; DOS function 02H: Display character in DL
    INT 21H          ; Call DOS interrupt to print CR

    MOV DL, 10       ; Load line feed (LF)
    MOV AH, 02H      ; DOS function 02H: Display character in DL
    INT 21H          ; Call DOS interrupt to print LF
ENDM

; -----------------------------------------------------------
; Macro: PRINT_STRING
; Purpose: Prints a null-terminated string using MS-DOS interrupt 21h
; Usage: PRINT_STRING string
; -----------------------------------------------------------

PRINT_STRING MACRO string
    MOV DX, OFFSET string  ; Load the offset address of the string
    MOV AH, 09H            ; DOS function 09h to print a string
    INT 21H
    PRINT_NEWLINE   
ENDM


; -----------------------------------------------------------
; Macro: EMPTYBUFFER
; Purpose: Empties a buffer by setting each byte to space (0x20)
; Usage: EMPTYBUFFER buffer, size
; -----------------------------------------------------------
EMPTYBUFFER MACRO buffer, size
    LOCAL .FILL_LOOP

    PUSH CX                ; Save CX register (used in the loop)
    PUSH DI                ; Save DI register (destination index)

    MOV CX, size           ; Load the number of bytes to clear (size of buffer)
    LEA DI, buffer         ; Load the effective address of the buffer into DI
    MOV AL, 20h            ; Load the ASCII value for space (0x20)

.FILL_LOOP:
    MOV [DI], AL           ; Store space (0x20) at the current address in DI
    INC DI                 ; Increment DI to move to the next byte in the buffer
    LOOP .FILL_LOOP        ; Decrement CX and jump to .FILL_LOOP if CX > 0 (loop through all bytes)

    POP DI                 ; Restore the DI register (used for the buffer address)
    POP CX                 ; Restore the CX register (used for the loop counter)
ENDM


; -----------------------------------------------------------
; Macro: RESET_HANDLE
; Purpose: Resets the file handle by seeking to the beginning of the file
; Usage: RESET_HANDLE handle
; -----------------------------------------------------------
RESET_HANDLE MACRO handle
    MOV AH, 42h         ; DOS function 42h: Seek function (used to move file pointer)
    MOV AL, 0           ; Move relative to the beginning of the file (seek from start)
    MOV BX, handle      ; Load the file handle into BX (handle of the file to reset)
    MOV CX, 0           ; Set the number of bytes to seek (0 means no offset, stay at start)
    MOV DX, 0           ; Set the offset to 0 (seek to the beginning of the file)
    INT 21h             ; Call DOS interrupt 21h to perform the seek operation
ENDM



; -----------------------------------------------------------
; Macro: PRINT_NUMBER
; Purpose: Prints a number (decimal) by converting it to its ASCII representation
; Usage: PRINT_NUMBER number
; -----------------------------------------------------------
PRINT_NUMBER MACRO number
    LOCAL CONVERT_LOOP, PRINT_LOOP

    PUSH AX            ; Save AX (used for the number)
    PUSH BX            ; Save BX (used for divisor)
    PUSH CX            ; Save CX (used for digit count)
    PUSH DX            ; Save DX (used for remainder)

    MOV AX, number    ; Load the number to be printed into AX
    MOV CX, 0         ; Initialize CX to count the number of digits
    MOV BX, 10        ; Set the divisor to 10 for decimal conversion

CONVERT_LOOP:
    MOV DX, 0         ; Clear DX before the division (DX:AX = number to be divided)
    DIV BX            ; AX / 10, Quotient -> AX, Remainder -> DX
    ADD DL, 30h       ; Convert the remainder to ASCII ('0' = 30h)
    PUSH DX           ; Push the ASCII digit onto the stack
    INC CX            ; Increment the count of digits
    TEST AX, AX       ; Test if AX is 0 (no more digits)
    JNZ CONVERT_LOOP  ; If AX != 0, continue the conversion loop

PRINT_LOOP:
    POP DX            ; Pop an ASCII digit from the stack
    MOV AH, 02h       ; DOS function 02h: Print character in DL
    INT 21h           ; Call DOS interrupt to print the character in DL
    LOOP PRINT_LOOP   ; Repeat until all digits are printed

    PRINT_NEWLINE     ; Print a newline after the number
    POP DX            ; Restore DX
    POP CX            ; Restore CX
    POP BX            ; Restore BX
    POP AX            ; Restore AX
ENDM




; -----------------------------------------------------------
; Macro: CLEAR_SCREEN
; Purpose: Clears the screen and resets the cursor position
; Usage: CLEAR_SCREEN
; -----------------------------------------------------------
MOVE_CURSOR MACRO X_POS, Y_POS  
    LOCAL CURSOR_OUT_OF_BOUNDS, CURSOR_DONE

    ; Load values into registers
    MOV BL, X_POS   ; Store X_POS in BL (row)
    MOV BH, Y_POS   ; Store Y_POS in BH (column)

    ; Validate X (row) is between 0-24
    CMP BL, 0
    JL CURSOR_OUT_OF_BOUNDS
    CMP BL, 24
    JG CURSOR_OUT_OF_BOUNDS

    ; Validate Y (column) is between 0-79
    CMP BH, 0
    JL CURSOR_OUT_OF_BOUNDS
    CMP BH, 79
    JG CURSOR_OUT_OF_BOUNDS

    ; Move validated values to cursor position registers
    MOV DH, BL       ; Set cursor row (X_POS)
    MOV DL, BH       ; Set cursor column (Y_POS)
    MOV BH, 0        ; Select page 0
    MOV AH, 02H      ; BIOS function 02h - Move cursor
    INT 10H          ; Call BIOS interrupt 10h (video services)
    JMP CURSOR_DONE  ; Skip error handling

CURSOR_OUT_OF_BOUNDS:
    PRINT_STRING CURSOR_ERROR_MSG  ; Print an error message

CURSOR_DONE:
ENDM

; -----------------------------------------------------------
; Macro: CLEAR_SCREEN
; Purpose: Clears the entire screen by scrolling the screen content up
; Usage: CLEAR_SCREEN
; -----------------------------------------------------------
CLEAR_SCREEN MACRO
    PUSH AX            ; Save AX (used for the BIOS call)
    PUSH BX            ; Save BX (temporary register)

    MOV AH, 06h        ; BIOS function 06h: Scroll up screen function
    MOV AL, 0          ; Scroll 0 lines, which clears the screen
    MOV BH, 07h        ; Text attribute: white on black (07h is standard text color)
    MOV CX, 0          ; Upper left corner (row=0, col=0)
    MOV DX, 184FH      ; Lower right corner (row=24, col=79), the bottom-right corner of the screen
    INT 10h            ; Call BIOS interrupt 10h to clear the screen

    POP BX             ; Restore BX
    POP AX             ; Restore AX
ENDM

; -----------------------------------------------------------
; Macro: FILEOPEN
; Purpose: Opens a file in read-only mode and handles errors
; Usage: FILEOPEN filename, handle
; Edge Case: If the file fails to open, sets the handle to -1
; -----------------------------------------------------------
FILEOPEN MACRO file, handle
    LOCAL OPEN_ERROR, OPEN_SUCCESS

    MOV AH, 3DH         ; DOS function 3Dh: Open a file
    MOV AL, 0           ; AL = 0 for read-only mode (1 = write, 2 = read/write)
    MOV DX, OFFSET file ; Load the offset address of the filename to open
    INT 21H             ; Call DOS interrupt 21h to open the file
    JC OPEN_ERROR       ; Jump if carry flag is set (error occurred)

    MOV handle, AX      ; If successful, store the file handle in `handle`
    JMP OPEN_SUCCESS    ; Jump to success section

OPEN_ERROR:
    MOV handle, -1      ; Set handle to -1 to indicate error (file could not be opened)
    PRINT_STRING FILE_ERROR_MSG ; Print the error message
    JMP FILEOPEN_DONE   ; Jump to the end of the macro to complete the process

OPEN_SUCCESS:
    ; File opened successfully, handle stored in `handle`

FILEOPEN_DONE:
ENDM

; -----------------------------------------------------------
; Macro: FILECLOSE
; Purpose: Closes an open file using its handle
; Usage: FILECLOSE handle
; Edge Case: Ensures file is open before attempting to close
; -----------------------------------------------------------
FILECLOSE MACRO handle
    LOCAL FILE_CLOSE_ERROR, FILE_CLOSE_SUCCESS

    CMP handle, 0                    ; Check if the file handle is valid (non-zero)
    JZ FILE_CLOSE_ERROR              ; Jump to error handling if the handle is 0 (invalid)

    MOV AH, 3EH                      ; DOS function 3Eh: Close a file
    MOV BX, handle                   ; Load the file handle into BX
    INT 21H                          ; Call DOS interrupt 21h to close the file
    JMP FILE_CLOSE_SUCCESS           ; Jump to success section if the file is closed

FILE_CLOSE_ERROR:
    PRINT_STRING FILE_CLOSE_ERROR_MSG ; Print the error message if the handle is invalid

FILE_CLOSE_SUCCESS:
ENDM


; -----------------------------------------------------------
; Macro: READ_FILE_CONTENTS
; Purpose: Reads and prints the content of an open file
; Usage: READ_FILE_CONTENTS handle, buffer, buffer_size
; Edge Case: Prevents reading if the file handle is invalid (0) or an error occurs
; -----------------------------------------------------------
READ_FILE_CONTENTS MACRO handle, buffer, buffer_size
    LOCAL READ_LOOP, FILE_READ_ERROR, READ_DONE

    CMP handle, 0                   ; Check if the file handle is valid (non-zero)
    JZ FILE_READ_ERROR              ; Jump to error if handle is 0 (file is not open)

READ_LOOP:
    MOV AH, 3Fh                     ; DOS function 3Fh: Read from file
    MOV BX, handle                  ; File handle
    MOV CX, buffer_size             ; Number of bytes to read
    MOV DX, OFFSET buffer           ; Address of the buffer to store the data
    INT 21h                         ; Call DOS interrupt 21h to read from file

    JC READ_DONE                    ; Jump if there is an error or end of file (EOF)
    OR AX, AX                       ; Check if AX = 0 (EOF reached)
    JZ READ_DONE                    ; If EOF, exit the loop

    ; Print the data read using DOS function 40h (write to screen)
    MOV BX, 1                       ; Standard output (console)
    MOV CX, AX                      ; Number of bytes to write (from AX)
    MOV DX, OFFSET buffer           ; Buffer to print
    MOV AH, 40h                     ; DOS function 40h: Write to standard output
    INT 21h                         ; Print buffer to screen

    JMP READ_LOOP                   ; Continue reading more data from the file

FILE_READ_ERROR:
    PRINT_STRING FILE_ERROR_MSG     ; Print the error message if reading fails

READ_DONE:
ENDM

; -----------------------------------------------------------
; Macro: FIND_MIN_WORD
; Purpose: Finds the shortest word in a file by reading its contents and comparing word lengths
; Usage: FIND_MIN_WORD handle, buffer, buffer_size
; Edge Case: Handles file errors and ensures proper word comparison
; -----------------------------------------------------------
FIND_MIN_WORD MACRO handle, buffer, buffer_size
    LOCAL FILE_READ_ERROR, GET_TEXT, NEW_WORD, NEXT_STEP, SET_NEW_MIN, READ_LINE, READ_DONE

    CMP handle, 0                     ; Check if the file handle is valid (non-zero)
    JZ FILE_READ_ERROR                ; Jump to error handling if handle is 0 (file not open)
    JMP GET_TEXT                      ; If file is open, jump to GET_TEXT to start reading

FILE_READ_ERROR:
    PRINT_STRING FILE_ERROR_MSG       ; Print error message if file handle is invalid
    JMP READ_DONE                     ; Jump to end of macro

GET_TEXT:
    MOV AH, 3Fh                       ; DOS function 3Fh: Read from file
    MOV BX, handle                    ; File handle
    MOV CX, buffer_size               ; Number of bytes to read
    MOV DX, OFFSET buffer             ; Address of the buffer to store the data
    INT 21h                           ; Call DOS interrupt 21h to read from the file

    JC READ_DONE                      ; Jump if an error occurs or EOF is reached
    OR AX, AX                         ; Check if AX = 0 (EOF reached)
    JZ READ_DONE                      ; Exit the macro if EOF is reached

    MOV remaining_bytes, AX           ; Store the number of bytes read in remaining_bytes
    MOV SI, 0                          ; Set SI to the start of the buffer (index)
    MOV act_word, 0                    ; Initialize current word length
    JMP READ_LINE                     ; Start processing the file content

NEW_WORD:
    CMP act_word, 0                   ; Check if we are at a new word (act_word == 0)
    JZ NEXT_STEP                      ; Jump to next step if act_word is 0 (new word)
    MOV AX, min_word                  ; Compare the current word with the shortest word
    CMP AX, act_word                  ; If min_word > act_word, update min_word
    JG SET_NEW_MIN                    ; Jump to SET_NEW_MIN if current word is smaller than min_word
    MOV act_word, 0                   ; Otherwise, reset act_word for the next word
    JMP NEXT_STEP                     ; Jump to next step

NEXT_STEP:
    INC SI                             ; Increment the buffer index (next character)
    DEC remaining_bytes                ; Decrement the remaining bytes counter
    CMP remaining_bytes, 0             ; Check if we have reached the end of the buffer
    JZ GET_TEXT                        ; If no more bytes, jump to GET_TEXT to read the next chunk
    JMP READ_LINE                      ; Otherwise, process the next character

SET_NEW_MIN:
    MOV AX, act_word                   ; Update min_word with the new smallest word length
    MOV min_word, AX
    MOV act_word, 0                    ; Reset act_word for the next word
    JMP NEXT_STEP                      ; Jump to next step

READ_LINE:
    MOV AL, buffer[SI]                 ; Load the current character from the buffer
    CMP AL, 0Dh                        ; Check if it's a Carriage Return (CR)
    JE NEW_WORD                        ; If CR, consider it the end of the current word
    CMP AL, 0Ah                        ; Check if it's a Line Feed (LF)
    JE NEW_WORD                        ; If LF, end the current word
    CMP AL, 20H                        ; Check if it's a space (ASCII 0x20)
    JE NEW_WORD                        ; If space, end the current word
    ; If character is not CR, LF, or space, it is a letter
    INC act_word                       ; Increment the word length for each letter in the word
    JMP NEXT_STEP                      ; Continue to the next character

READ_DONE:
ENDM
