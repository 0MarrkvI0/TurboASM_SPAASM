; ==================== Assignment No. 1_8 ====================
; Author: Martin Kvietok
; 
; Description:
; This program finds the shortest word in a text file and prints only lines
; containing that word. Written in x86 Assembly, it uses DOS interrupts for 
; file operations and output.
;
; Deadline: 23.3.2025
; Year, Semester, Program: [2025, 4, B_INFO]
;
; ==================== Commented Code ====================

INCLUDE makros.inc  ; Include macro definitions for common operations like printing strings or handling files

.MODEL SMALL         ; Define the small memory model (code and data share the same segment)
.STACK 100h          ; Allocate 256 bytes for the stack

.DATA
    ; -------------------- Constants and Settings --------------------
    MAX_FILE_BYTES EQU 13                    ; Maximum number of characters allowed for the filename
    FILENAME DB MAX_FILE_BYTES DUP(0), 0     ; Buffer to store the filename, initialized to 0s with a null terminator at the end

    _HELPFLAG DW 0                           ; Flag variable to check if help was requested (0 = not requested)

    NEWLINE DB 13, 10                        ; Newline sequence (Carriage Return + Line Feed) for formatting output

    HANDLE DW 0                              ; Variable to store the file handle, which is used in file operations

    MAX_BYTES EQU 256                        ; Define the maximum number of bytes that can be handled at once
    BUFFER DB 256 DUP(0)                     ; A buffer to store data read from the file, initialized to 0
    TEMP_BUFFER DB 256 DUP(0)                ; A temporary buffer to store processed data

    remaining_bytes DW 0                     ; Variable to track how many bytes remain to be read from the file
    act_word DW 0                            ; Variable to track the current word being processed

    min_word DW 255                          ; Variable to store the length of the shortest word found in the file (initially set to 255, representing an infinite length)
    CONTAINS_MIN DB 0                        ; Flag to indicate if a line with the shortest word has been found (0 = not found, 1 = found)

    ; -------------------- Error Messages --------------------
    CURSOR_ERROR_MSG DB 'Error: Cursor position out of bounds!$'          ; Error message for cursor out of bounds error
    FILE_ERROR_MSG DB 'Error: File could not be opened!$'                 ; Error message when the file cannot be opened
    FILE_CLOSE_ERROR_MSG DB 'Error: File not open or already closed!$'    ; Error message when attempting to close a file that is not open
    FLAG_ERROR_MSG DB 'Error: Flag is not defined$'                       ; Error message for undefined flag
    FILENAME_LENGTH_ERROR DB 'Error: Filename exceeded the character limit$' ; Error message when filename exceeds the defined length limit
    NO_ARGUMENT DB 'Error: No arguments provided$'                       ; Error message when no arguments are passed to the program

    ; -------------------- Help and Usage Information --------------------
    HELP DB 'This program finds the length of the shortest word in the given file and prints only the lines that contain a word with the same length.$'  ; Description of what the program does
    HELP_USAGE DB 'Usage: main_8.exe file.txt ... - h for help$'  ; Usage instructions for the program, including how to get help


    

.CODE

MAIN:
    ; Initialize the data segment (set up access to data)
    MOV AX, @data
    MOV DS, AX

    ; Get Program Segment Prefix (PSP) segment for handling command-line arguments
    MOV AH, 62H            ; DOS function 62H: Get PSP segment
    INT 21H                ; Call DOS interrupt
    MOV ES, BX             ; Store PSP segment in ES register

    ; Set up for processing arguments
    MOV SI, 80H            ; Set SI to the start of command-line arguments
    MOV BL, byte ptr ES:[SI] ; Load the number of argument bytes into BL
    CMP BL, 0              ; Check if there are no arguments
    JZ NO_ARGS             ; If no arguments, jump to NO_ARGS section
    INC SI                 ; Move to the first character of the argument

    ; Set up the FILENAME buffer to store the filename argument
    LEA DI, FILENAME       ; Load effective address of FILENAME into DI

SKIP_SPACES:
    MOV AL, ES:[SI]        ; Load current argument character into AL
    CMP AL, 32             ; Check if the character is a space (ASCII 32)
    JNE CHECK_FLAG         ; If not a space, jump to CHECK_FLAG
    INC SI                 ; Move to the next argument character
    DEC BL                 ; Decrement the byte count for arguments
    CMP BL, 0              ; Check if all argument bytes are processed
    JZ END_ARGS            ; If done, jump to END_ARGS
    JMP SKIP_SPACES        ; Otherwise, continue skipping spaces

CHECK_FLAG:
    CMP AL, '-'            ; Check if the current character is a flag '-'
    JZ IS_FLAG             ; If it is a flag, jump to IS_FLAG
    CMP AL, 0Dh            ; Check if the character is a carriage return (end of line)
    JZ END_ARGS            ; If it is, jump to END_ARGS
    JMP IS_FILE            ; Otherwise, continue processing as a filename

IS_FLAG:
    MOV BYTE PTR ES:[SI], 32 ; Replace flag character with a space (marking the flag)
    INC SI                 ; Move to the next character
    MOV AL, ES:[SI]        ; Load the next character after the flag
    MOV BYTE PTR ES:[SI], 32 ; Replace it with a space (marking it as processed)
    CMP AL, 'h'            ; Check if the flag is '-h'
    JZ HELP_FLAG           ; If it is '-h', jump to HELP_FLAG
    PRINT_STRING FLAG_ERROR_MSG ; Print an error message if flag is invalid
    JMP END_ARGS           ; Jump to END_ARGS

HELP_FLAG:
    PRINT_STRING HELP      ; Print the help message
    PRINT_STRING HELP_USAGE ; Print usage instructions
    INC _HELPFLAG          ; Set the help flag to indicate help was displayed
    DEC BL                 ; Decrement argument byte count
    DEC BL                 ; Decrement argument byte count again
    CMP BL, 0              ; Check if all arguments are processed
    JZ END_ARGS            ; If done, jump to END_ARGS
    INC SI                 ; Otherwise, move to the next character
    JMP END_ARGS           ; Jump to END_ARGS to finish argument processing

NO_ARGS:    
    PRINT_STRING NO_ARGUMENT ; Print an error message if no arguments were provided
END_ARGS:
    MOV AX, 4C00h          ; Exit the program using DOS interrupt 21h
    INT 21h                ; DOS interrupt to terminate the program

IS_FILE:
    CMP _HELPFLAG, 0       ; Check if the help flag is set
    JNZ END_ARGS           ; If the help flag is set, jump to END_ARGS (no file processing)

    MOV CX, MAX_FILE_BYTES ; Set CX to the maximum allowed bytes for the filename

LOAD_F_NAME:
    MOV AL, ES:[SI]        ; Load the current character from the argument
    MOV BYTE PTR ES:[SI], 32 ; Replace it with a space (marking it as processed)
    CMP AL, 32             ; Check if it's a space
    JE END_FILENAME        ; If it is, jump to END_FILENAME
    CMP AL, 0              ; Check if it's a null byte (end of string)
    JE END_FILENAME        ; If it is, jump to END_FILENAME
    CMP AL, 0Dh            ; Check if it's a carriage return (end of line)
    JE END_FILENAME        ; If it is, jump to END_FILENAME

    MOV [DI], AL           ; Store the character in the FILENAME buffer
    INC DI                 ; Increment the destination index (DI)
    INC SI                 ; Move to the next character in the argument
    DEC BL                 ; Decrement the byte count for arguments
    LOOP LOAD_F_NAME       ; Repeat until all characters are loaded into the filename

    PRINT_STRING FILENAME_LENGTH_ERROR ; Print error if the filename is too long
    JMP END_ARGS           ; Jump to END_ARGS to finish argument processing

END_FILENAME:
    MOV BYTE PTR [DI], 0    ; Null-terminate the FILENAME string
    INC DI                  ; Move DI to the next byte
    JMP READ_FILE           ; Jump to the READ_FILE section to process the file

CLOSE:
    PRINT_NEWLINE           ; Print a newline before closing the file
    FILECLOSE HANDLE       ; Close the file using the file handle
    EMPTYBUFFER BUFFER, MAX_BYTES ; Clear the BUFFER array
    EMPTYBUFFER FILENAME, 13 ; Clear the FILENAME array
    PRINT_NUMBER min_word  ; Print the value of `min_word`
    MOV min_word, 256      ; Reset `min_word` to its maximum value
    MOV HANDLE, 0          ; Reset the file handle to 0

    JMP MAIN               ; Restart the main process

READ_FILE:
    FILEOPEN FILENAME, HANDLE ; Open the file using the filename
    FIND_MIN_WORD HANDLE, BUFFER, MAX_BYTES ; Find the shortest word in the file using the buffer
    RESET_HANDLE HANDLE    ; Reset the file handle for further operations

    MOV BX, HANDLE         ; Load the handle into BX
    CMP BX, 0              ; Check if the handle is valid (non-zero)
    JZ FILE_READ_ERROR     ; If the handle is zero, jump to FILE_READ_ERROR

    XOR DI, DI             ; Clear DI (used as an index)
    JMP GET_TEXT           ; Jump to GET_TEXT to start reading the file


; -------------------- Reading Data from File --------------------
GET_TEXT:
    MOV AH, 3Fh          ; Set AH to 3Fh to call DOS interrupt function for reading a file
    MOV CX, MAX_BYTES    ; Load CX with the number of bytes to read from the file
    LEA DX, BUFFER       ; Load the address of the BUFFER into DX (where the data will be stored)
    INT 21h              ; Call DOS interrupt 21h to read data into the BUFFER

    JC READ_DONE         ; Jump to READ_DONE if there's an error during reading
    OR AX, AX            ; Perform a logical OR on AX to check if no data is read
    JZ READ_DONE         ; If no data is read (AX = 0), jump to READ_DONE (end of file)

    MOV remaining_bytes, AX  ; Store the number of bytes read into remaining_bytes
    MOV SI, 0               ; Initialize SI (source index) to 0 (start of BUFFER)
    MOV act_word, 0         ; Initialize act_word to 0 (used for tracking word length)
    JMP READ_LINE           ; Jump to READ_LINE to start processing the data

; -------------------- Error Opening File --------------------
FILE_READ_ERROR:
    MOV DX, OFFSET FILE_ERROR_MSG  ; Load the address of the file error message
    MOV AH, 09h                    ; Set AH to 09h to call DOS interrupt for printing a string
    INT 21h                        ; Call DOS interrupt to display the file error message
    JMP READ_DONE                  ; Jump to READ_DONE to finish reading

; -------------------- End of Reading --------------------
READ_DONE:
    CMP CONTAINS_MIN, 1           ; Check if the shortest word has been found
    JE PRINT_BUFFER               ; If the shortest word is found, jump to PRINT_BUFFER
    JMP CLOSE                     ; Otherwise, jump to CLOSE to finish the process

; -------------------- New Word --------------------
NEW_WORD:
    CMP act_word, 0               ; Check if the current word has length 0
    JZ NEXT_STEP                  ; If the current word length is 0, jump to the next step
    MOV AX, min_word              ; Load the minimum word length into AX
    CMP AX, act_word              ; Compare the minimum word length with the current word length
    JZ IS_MIN                     ; If they are equal, jump to IS_MIN
    MOV act_word, 0               ; Reset the current word length to 0
    JMP NEXT_STEP                 ; Jump to the next step

; -------------------- Next Step --------------------
NEXT_STEP:
    INC DI                        ; Increment the destination index (DI)
CONT_STEP:
    INC SI                        ; Increment the source index (SI)
    DEC remaining_bytes           ; Decrease the remaining bytes counter
    CMP remaining_bytes, 0        ; Check if there are still bytes left to read
    JZ GET_TEXT                   ; If there are no bytes left, jump to GET_TEXT to read more
    JMP READ_LINE                 ; Otherwise, continue reading the next line

; -------------------- Checking for Shortest Word --------------------
IS_MIN:
    MOV act_word, 0               ; Reset the current word length
    CMP CONTAINS_MIN, 0           ; Check if the shortest word has been found
    JNZ NEXT_STEP                 ; If the shortest word has been found, jump to the next step
    INC CONTAINS_MIN              ; Mark the shortest word as found
    JMP NEXT_STEP                 ; Jump to the next step

; -------------------- Reading Characters from the Buffer --------------------
READ_LINE:
    MOV AL, BUFFER[SI]            ; Load the next character from the BUFFER into AL
    MOV TEMP_BUFFER[DI], AL       ; Store the character in TEMP_BUFFER

    CMP AL, 0Dh                   ; Check if the character is a carriage return (CR)
    JE PRINT_MIN_LINE             ; If CR, jump to PRINT_MIN_LINE to print the line
    CMP AL, 0Ah                   ; Check if the character is a line feed (LF)
    JE PRINT_MIN_LINE             ; If LF, jump to PRINT_MIN_LINE to print the line
    CMP AL, 20h                   ; Check if the character is a space
    JE NEW_WORD                   ; If space, jump to NEW_WORD to handle a new word

    INC act_word                  ; Increment the current word length
    JMP NEXT_STEP                 ; Jump to the next step

; -------------------- Print the Shortest Line --------------------
PRINT_MIN_LINE:
    XOR DI, DI                    ; Reset DI (destination index) to 0
    MOV act_word, 0               ; Reset the current word length to 0
    CMP CONTAINS_MIN, 1           ; Check if the shortest word is found
    JE PRINT_BUFFER               ; If the shortest word is found, print the buffer
    JMP EMPTY_BUFFER              ; Otherwise, empty the buffer

; -------------------- Actual Printing of Characters from TEMP_BUFFER --------------------
PRINT_BUFFER:
    MOV AL, TEMP_BUFFER[DI]       ; Load the character from TEMP_BUFFER into AL
    MOV DL, AL                    ; Move AL to DL for printing
    MOV AH, 02h                   ; Set AH to 02h for DOS interrupt to print a character
    INT 21h                       ; Call DOS interrupt 21h to print the character

    INC DI                        ; Increment the destination index (DI)
    CMP AL, 0Dh                   ; Check if the character is a carriage return (CR)
    JE NEW_LINE_PRINT             ; If CR, jump to NEW_LINE_PRINT
    CMP AL, 0Ah                   ; Check if the character is a line feed (LF)
    JE NEW_LINE_PRINT             ; If LF, jump to NEW_LINE_PRINT
    JMP PRINT_BUFFER              ; Otherwise, continue printing the next character

NEW_LINE_PRINT:
    PRINT_NEWLINE                 ; Print a newline after the line is completed

; -------------------- Clearing After Printing --------------------
CLEAR_BUFFER:
    XOR DI, DI                    ; Reset the destination index (DI) to 0
    DEC CONTAINS_MIN              ; Decrement CONTAINS_MIN after printing the shortest line
    JMP EMPTY_BUFFER              ; Jump to empty the TEMP_BUFFER

; -------------------- Emptying TEMP_BUFFER (Setting to Spaces) --------------------
EMPTY_BUFFER:
    EMPTYBUFFER TEMP_BUFFER,MAX_BYTES ; Empty the TEMP_BUFFER (set all values to spaces)
    JMP CONT_STEP                 ; Jump back to continue processing the next step

END MAIN

; ==================== Evaluation ====================

; Functionality:
; - The program successfully reads from multiple files, calculates the shortest word length,
;   and prints matching lines.
; - It handles file opening and argument errors with clear messages.
; - It fails if the file isn't found or if invalid arguments are provided.
; - The program does not handle user console input directly; it only processes file input.
; - Includes the -h flag function to display information about the program.

; Development Environment:
; - Developed using Turbo Assembler (TASM) on a DOS system.
; - Utilizes DOS interrupts (int 21h) for file I/O and console output.

; Program Behavior:
; - The program expects a text file with words separated by spaces or newlines.
; - If the file can't be opened or an invalid argument is provided, an error 
;   message is shown.
; - It handles the -h flag to show helpful program information.
; - Works with larger input files as it reads them in 256-byte chunks and waits for an 
;   end-of-line character before processing.

; Assumptions for Correct Functioning:
; - The input file exists and is accessible.
; - The file format is plain text.
; - Arguments are correctly passed.

; DOS/BIOS Service Usage:
; - Uses DOS interrupts for file reading (int 21h/3Fh) and string printing 
;   (int 21h/09h).

; Possible Improvements:
; - Input validation could be expanded to handle more edge cases.
; - Porting to modern systems or using higher-level file operations would improve compatibility.
; - Counting length also includes punctuation and special characters, not just letters.

; Algorithms Used:
; - Reads the file byte by byte.
; - Tracks the shortest word length, including punctuation and special characters.
; - Prints lines containing the shortest word length.

; Techniques and Tricks:
; - DOS interrupts are used for file I/O and printing, keeping the code simple 
;   and efficient.
; - Error checks ensure that the program exits gracefully on invalid input.

; Special Notes:
; - The program demonstrates low-level file handling in Assembly and provides 
;   user feedback with minimal memory usage.

; Sources:
; - Lectures and exercise materials.
; - TASM documentation.
; - DOS interrupt documentation.
; - Online Assembly programming resources.

