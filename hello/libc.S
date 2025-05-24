#    SPDX-FileCopyrightText: 2025 Daniel Sá Barretto <danielbarretto@usp.br>
#   
#    SPDX-License-Identifier: GPL-3.0-or-later
#
#  This file is a derivative of SYSeg (https://gitlab.com/monaco/syseg)
#  and includes modifications made by the following author(s):
#  Daniel Sá Barretto <danielbarretto@usp.br>

	/* Suppose we receive the argument in %cx. */

	.code16gcc
	.global printf
	.global print_cats
	.section .text

.section .rodata
        cat1: .ascii "  *.*     *,-'''`-.*\r\n\0"
        cat2: .ascii " (,-.`._,'(       |\\`- /|\r\n\0"
        cat3: .ascii "    `-.-'  \\ )-`  (, o o)\r\n\0"
        cat4: .ascii "            `-     \\``*'-\r\n\0"
        start: .ascii "Choose how many cats you want to have\r\n\0"
        new_line: .ascii "\r\n\0"
        doneMsg: .ascii "Finished at UTC \0"

printf:	
	mov   %cx, %bx
        mov   $0x0e,%ah               
        mov   $0x0, %si

print_cats:
        mov   %cx, %bx
        mov $start, %bx
        call stringOutput      # Display prompt string
        call intInput          # Read an integer from user
        call newLine
        mov %bx, %dx           # Put the read integer in DX
        # DX now contains the number of cats to print

while:
        cmp $0x0, %dx          # Check if counter reached zero
        je end                 # If zero, we're done
        call printCatsString   # Print one cat
        sub $1, %dx            # Decrement counter
        jmp while              # Loop back

printCatsString:
        # Print all 4 lines of the cat ASCII art
        mov $cat1, %bx
        call stringOutput
        mov $cat2, %bx
        call stringOutput
        mov $cat3, %bx
        call stringOutput
        mov $cat4, %bx
        call stringOutput
        ret                    # Return to caller

intInput:
        push %ax
        push %cx
        mov $0, %bx            # Initialize result to 0

charToInt:
        mov $0x0, %ah
        int $0x16              # Read a character from keyboard
        cmp $13, %al           # Check if it's Enter (carriage return)
        je endConversion
        mov $0xe, %ah
        int $0x10              # Echo character to screen
        movzx %al, %dx         # Store the character in dx
        sub $'0', %dx          # Convert ASCII digit to numeric value
        imul $0xA, %bx         # Multiply current result by 10
        add %dx, %bx           # Add new digit to result
        jmp charToInt

endConversion:
        pop %cx
        pop %ax
        ret                    # Return with result in BX

stringOutput:
        push %bx
        push %cx
        jmp clearStringOutput

clearStringOutput:
        movb (%bx), %cl        # Load byte from string
        cmpb $0x0, %cl         # Check if null terminator
        je endStringOutput
        call charOutput        # Print the character
        add $0x1, %bx          # Move to next character
        jmp clearStringOutput

charOutput:
        push %ax
        # Set arguments for BIOS interrupt
        mov $0x0e, %ah         # BIOS teletype output function
        mov %cl, %al           # Character to print
        int $0x10              # Call BIOS interrupt
        pop %ax
        ret

newLine:
        # Print \r\n (carriage return + line feed)
        push %bx
        mov $new_line, %bx
        call stringOutput
        pop %bx
        ret

endStringOutput:
        pop %cx
        pop %bx
        ret

end:
        mov $doneMsg, %bx
        call stringOutput      # Print "done" message
        call print_time        # Print the current time
        mov %si, %ax
        ret

print_time:
        pusha
        mov $0x02, %ah         # Function 0x02: Get RTC time
        int $0x1a              # Call BIOS interrupt

        mov %dh, %bl           # Save seconds in BL
        mov %cl, %bh           # Save minutes in BH
        
        # Print hours
        mov %ch, %al
        call print_bcd

        # Print colon
        mov $':', %cl
        call charOutput

        # Print minutes
        mov %bh, %al
        call print_bcd

        # Print colon
        mov $':', %cl
        call charOutput

        # Print seconds
        mov %bl, %al
        call print_bcd

        call newLine           # Print new line

        jmp .done

.done:
        popa
        ret

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
