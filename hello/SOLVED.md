# Print cats

This program is a simple x86 assembly application designed to run in 16-bit real mode (typically used in bootloaders or legacy BIOS environments). It prompts the user to input a number and then prints that many ASCII-art cats on the screen. After printing all the cats, it displays the current local time (fetched via BIOS interrupt) and a "done" message.


## Key Features:
1. User Input Handling:
    * Reads a number from the user (via keyboard input) using BIOS interrupt `0x16`.
    * Converts the ASCII input to a numeric value for processing.

2. ASCII Art Printing:

    * Prints a cute ASCII-art cat multiple times based on the user's input.
    * Each cat is composed of four lines of text, stored as null-terminated strings in the `.rodata` section.

3. Time Display:

    * Uses BIOS interrupt `0x1A` (Real-Time Clock services) to fetch the current time in BCD (Binary-Coded Decimal) format.
    * Converts BCD to ASCII and prints the time in `HH:MM:SS` format.

4. Text Output:

    * Implements basic string and character printing using BIOS teletype output (`int 0x10`, function `0x0E`).

## Explanation of the Cat Printer Assembly Program

This 16-bit x86 assembly program demonstrates several key concepts through an interactive cat-printing utility. Here's a breakdown of the major components:

### Data Section (`.rodata`)
```nasm
        cat1: .ascii "  *.*     *,-'''`-.*\r\n\0"
        cat2: .ascii " (,-.`._,'(       |\\`- /|\r\n\0"
        cat3: .ascii "    `-.-'  \\ )-`  (, o o)\r\n\0"
        cat4: .ascii "            `-     \\``*'-\r\n\0"
        start: .ascii "Choose how many cats you want to have\r\n\0"
        new_line: .ascii "\r\n\0"
        doneMsg: .ascii "Finished at UTC \0"
```
* Stores ASCII art of a cat split across 4 lines
* Contains prompt and status messages
* All strings are null-terminated (\0) and include carriage return + line feed (\r\n) (excluding doneMsg)

### Main Program Flow
#### 1. Initialization
```
print_cats:
    mov $start, %bx
    call stringOutput      # Display prompt
    call intInput         # Get user input
    call newLine
    mov %bx, %dx          # Store cat count in DX
```
* The print_cats function is called by `main.c`
* Prints the initial prompt asking how many cats to display
* Reads user input and stores the number in DX

#### 2. Cat Printing Loop
```
while:
    cmp $0x0, %dx         # Check counter
    je end                # Exit if done
    call printCatsString  # Print one cat
    sub $1, %dx           # Decrement counter
    jmp while             # Repeat
```
* Loops until DX (cat counter) reaches zero
* Prints one complete cat per iteration

#### 3. Printing a Single Cat
```
printCatsString:
    mov $cat1, %bx
    call stringOutput
    mov $cat2, %bx
    call stringOutput
    mov $cat3, %bx
    call stringOutput
    mov $cat4, %bx
    call stringOutput
    ret
```
* Prints all 4 lines of the cat ASCII art sequentially
* Each line is printed using the `stringOutput` routine

### Key Subroutines
#### 1. String Output
```
stringOutput:
    push %bx
    push %cx
    jmp clearStringOutput

clearStringOutput:
    movb (%bx), %cl        # Load character
    cmpb $0x0, %cl         # Check for null terminator
    je endStringOutput
    call charOutput        # Print character
    add $0x1, %bx          # Next character
    jmp clearStringOutput
```
* Takes string address in BX
* Prints each character until null terminator
* Uses BIOS interrupt 0x10, function 0x0E (teletype output)

#### 2. Character Input/Conversion
```
intInput:
    push %ax
    push %cx
    mov $0, %bx            # Initialize result

charToInt:
    mov $0x0, %ah
    int $0x16              # Read keyboard input
    cmp $13, %al           # Check for Enter key
    je endConversion
    mov $0xe, %ah
    int $0x10              # Echo character
    movzx %al, %dx         # Convert ASCII to number
    sub $'0', %dx
    imul $0xA, %bx         # Multiply current total by 10
    add %dx, %bx           # Add new digit
    jmp charToInt
```
* Reads digits until Enter is pressed
* Converts ASCII digits to a numerical value
* Handles multi-digit numbers by multiplying current total by 10 before adding each new digit

#### 3. Time Display
```
print_time:
    mov $0x02, %ah         # Get RTC time function
    int $0x1a              # BIOS time interrupt
    jc .error              # Handle error if carry set

    # Print hours, minutes, seconds with colons
    mov %ch, %al           # Hours (BCD)
    call print_bcd
    mov $':', %cl
    call charOutput
    mov %cl, %al           # Minutes (BCD)
    call print_bcd
    mov $':', %cl
    call charOutput
    mov %dh, %al           # Seconds (BCD)
    call print_bcd
```
* Uses BIOS interrupt 0x1A to get current time
* Time is returned in BCD (Binary Coded Decimal) format
* Prints time in HH:MM:SS format

#### 4. BCD to ASCII Conversion
```
print_bcd:
        # Save registers we'll modify (preserve caller's values)
        push %ax
        push %cx

        # Backup the original BCD byte since we need to process both nibbles
        # AL contains input BCD value (each nibble represents a digit 0-9)
        mov %al, %ah           # Copy original BCD byte from AL to AH for safekeeping

        # PROCESS HIGH NIBBLE (tens digit)
        mov %ah, %cl           # Move byte to CL for processing
        shr $4, %cl            # Shift right by 4 bits to move high nibble to low nibble
                                # (e.g., BCD 0x59 becomes 0x05)
        and $0x0F, %cl         # Mask to keep only low 4 bits (in case of sign extension)
        add $'0', %cl          # Convert numeric value to ASCII character
                                # (e.g., 5 becomes '5' which is 0x35 in ASCII)
        call charOutput        # Print the tens digit character

        # PROCESS LOW NIBBLE (units digit)
        mov %ah, %cl           # Reload original BCD value from AH
        and $0x0F, %cl         # Mask to keep only low nibble
                                # (e.g., BCD 0x59 becomes 0x09)
        add $'0', %cl          # Convert numeric value to ASCII character
                                # (e.g., 9 becomes '9' which is 0x39 in ASCII)
        call charOutput        # Print the units digit character

        # Restore registers to their original values
        pop %cx
        pop %ax
        ret
```
* Converts BCD digits to ASCII characters
* Handles both high and low nibbles of each byte
* Prints each digit separately