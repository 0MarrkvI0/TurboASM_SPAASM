# Shortest Word Line Printer (TASM / DOS) - SPAASM FIIT STU LS 2024/25

**Author:** Martin Kvietok  
**Subject:** System Programming and Assemblers
**Faculty:** Fakulta informatiky a informačných technológií, STU Bratislava

---

## Description

This x86 Assembly program reads a text file, finds the **shortest word**, and **prints only lines that contain words of that length**. It uses **DOS interrupts** for file handling and console output. Written for Turbo Assembler (TASM) in real-mode DOS.

---

## Program Overview

- Reads input file byte-by-byte in **256-byte chunks**
- Tracks the **length of each word**
- Identifies the **shortest word length**
- On second pass, prints **lines containing a word with that shortest length**
- Supports a `-h` flag to print usage/help

---

## Features

- ✅ Handles file opening and reading with clear error messages
- ✅ Supports argument parsing and help mode
- ✅ Efficient buffer handling for low-memory DOS environments
- ❌ Does not support real-time user input – works only with text files

---

## Workflow Summary

1. Parse command-line arguments and flags
2. Open the file using DOS `int 21h`
3. First pass:
   - Track each word length
   - Store the minimum word length (`min_word`)
4. Second pass:
   - Print lines from the file that contain a word matching `min_word`

---

## Usage

```bash
main_8.exe file.txt        ; Find and print lines with shortest word
main_8.exe -h              ; Show help and usage
```

---

## Development Environment

- **Assembler:** Turbo Assembler (TASM)
- **Platform:** DOS (real mode)
- **Tech:** x86 Assembly, `int 21h` interrupts

---

## Assumptions

- Input is a plain text file
- Words are delimited by spaces or newlines
- File is accessible and arguments are valid

---

## Internals

- **Main interrupts used:**
  - `int 21h / 3Fh` – file read
  - `int 21h / 09h` – print string
  - `int 21h / 02h` – print character

- **Memory:**
  - `.MODEL SMALL`
  - `256-byte` stack
  - Buffers for file and temp storage

- **Flags and buffers:**
  - `min_word` holds shortest word length
  - `TEMP_BUFFER` stores current line
  - `CONTAINS_MIN` tracks match flag

---
