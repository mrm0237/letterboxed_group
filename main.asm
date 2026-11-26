.data
imageBuffer:    .space 0x80000          # must stay first
dict_buffer:    .space 4000000          # file size and at least 1 extra byte
                .align 2
letter_index:   .space 104              # 26 letters x 4 bytes
dict_bytes:     .word 0                 # bytes read from the dictionary
connect_letter: .word 0                 # last letter of the latest valid word (0 = none yet)
board:          .space 13               # 12 board letters + 1 byte that stays 0 so it can be printed
input_buf:      .space 32               # the player's word
dict_filename:  .asciiz "validwords.txt"
dict_err_msg:   .asciiz "Could not load validwords.txt\n"
board_msg:      .asciiz "Board (3 letters per side): "
solution_msg:   .asciiz "Solution words (debug only):\n"
prompt_msg:     .asciiz "Enter a word: "
short_msg:      .asciiz "IS TOO SHORT\n"
long_msg:       .asciiz "IS TOO LONG\n"
invalid_msg:    .asciiz "IS NOT VALID\n"
win_msg:        .asciiz "All letters used! Star size: "

.text
main:
# seed the random generator
	li $v0, 30
	syscall
	move $a1, $a0
	li $a0, 0
	li $v0, 40
	syscall

# load the dictionary and build the letter index
	la $a0, dict_filename
	la $a1, dict_buffer
	li $a2, 3999999
	jal load_dictionary
	bltz $v0, dict_failed
	sw $v0, dict_bytes

	la $a0, dict_buffer
	la $a1, letter_index
	jal build_letter_index

# generate the puzzle
	la $a0, dict_buffer
	la $a1, letter_index
	lw $a2, dict_bytes
	la $a3, board
	jal generate_pair
	move $s0, $v0				# W1 address (0 if the fallback board was used)
	move $s1, $v1				# W2 address

# show the board
	li $v0, 4
	la $a0, board_msg
	syscall
	li $v0, 4
	la $a0, board
	syscall
	li $v0, 11
	li $a0, 10
	syscall

# show the solution words so you can test a win (delete later)
	beq $s0, $zero, game_loop	# fallback board: no words to show
	li $v0, 4
	la $a0, solution_msg
	syscall
	move $a0, $s0
	jal print_line
	move $a0, $s1
	jal print_line

# one turn:
game_loop:
	li $v0, 4
	la $a0, prompt_msg
	syscall
	li $v0, 8					# reads a string
	la $a0, input_buf
	li $a1, 32
	syscall
	la $a0, input_buf
	jal to_upper				# checks expect capitals

	# the checks return 0 for OK, so branch away on non-zero
	la $a0, input_buf
	jal checkLength				 
	bne $v0, $zero, show_failure

	la $a0, input_buf
	la $a1, board
	jal checkBoardLetters
	bne $v0, $zero, show_failure

	la $a0, input_buf
	la $a1, board
	jal checkSides
	bne $v0, $zero, show_failure

	la $a0, input_buf
	lw $a1, connect_letter		# 0 for the first word
	jal checkConnection
	bne $v0, $zero, show_failure

	la $a0, input_buf
	la $a1, letter_index
	jal find_dictionary_word	# the opposite convention: 1 = found
	beq $v0, $zero, fail_invalid

# the word passed every check: update the state 
	la $a0, input_buf
	la $a1, board
	jal updateUsedLetters
	jal updateWordCount

	la $a0, input_buf
	jal word_length				# $v0 is the length of the word
	la $t0, input_buf
	addu $t0, $t0, $v0
	lb $t1, -1($t0)				# the word's last letter
	sw $t1, connect_letter		# the next word must start with it

	jal checkWin				# 1 = all 12 letters used
	bne $v0, $zero, game_won
	j game_loop

# failure messages 
show_failure:					# $v0 still holds the check's failure code
	beq $v0, 1, fail_short
	beq $v0, 2, fail_long
	j fail_invalid				# any other code: not valid
fail_short:
	li $v0, 4
	la $a0, short_msg
	syscall
	j game_loop
fail_long:
	li $v0, 4
	la $a0, long_msg
	syscall
	j game_loop
fail_invalid:
	li $v0, 4
	la $a0, invalid_msg
	syscall
	j game_loop

#  win 
game_won:
	jal checkPar				# $v0 = star size
	move $s2, $v0
	li $v0, 4
	la $a0, win_msg
	syscall
	move $a0, $s2
	li $v0, 1
	syscall
	li $v0, 11
	li $a0, 10
	syscall
	li $v0, 10
	syscall

dict_failed:
	li $v0, 4
	la $a0, dict_err_msg
	syscall
	li $v0, 10
	syscall

# to_upper: $a0 = string address; converts a-z to A-Z in place
to_upper:
	lb $t0, 0($a0)
	beq $t0, $zero, tu_done
	blt $t0, 97, tu_next		# below 'a'
	bgt $t0, 122, tu_next		# above 'z'
	addiu $t0, $t0, -32			# lowercase -> uppercase
	sb $t0, 0($a0)
tu_next:
	addiu $a0, $a0, 1
	j to_upper
tu_done:
	jr $ra

#  everyone else's code (these must stay at the END of the file) 
.include "project.asm"
.include "gamelogic.asm"
