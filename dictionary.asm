# Letter Boxed: dictionary + generator pieces (Riggs)
# Puzzle logic

.text

.globl load_dictionary
.globl build_letter_index
.globl find_dictionary_word
.globl generate_pair
.globl pick_random_line
.globl print_line
.globl word_length
.globl word_ok


load_dictionary:
	addiu $sp, $sp, -12
	sw $s0, 0($sp)
	sw $s1, 4($sp)
	sw $s2, 8($sp)
	move $s1, $a1			## buffer
	move $s2, $a2			## max bytes
	li $v0, 13				## open ($a0 is already the file name)
	li $a1, 0
	li $a2, 0
	syscall
	bltz $v0, ld_fail
	move $s0, $v0			## file descriptor
	li $v0, 14				## read
	move $a0, $s0
	move $a1, $s1
	move $a2, $s2
	syscall
	move $s1, $v0			## bytes read (or negative on error)
	li $v0, 16				## close
	move $a0, $s0
	syscall
	move $v0, $s1
	bltz $v0, ld_fail
	j ld_done 

ld_fail:
	li $v0, -1

ld_done:
	lw $s0, 0($sp)
	lw $s1, 4($sp)
	lw $s2, 8($sp)
	addiu $sp, $sp, 12
	jr $ra
	
build_letter_index:
	move $t0, $a0	## $t0 is the start of the current line
	li $t1, 0		## $t1 is the first letter of the previous line
	
index_loop:
	lb $t2, 0($t0) 	## first character of this line
	beq $t2, $zero, index_done	## end of buffer
	beq $t1, $t2, index_skip	## if $t1 == $t2, skip to index_skip
	blt $t2, 65, index_skip		## if it's not a capital letter, ignore it
	bgt $t2, 90, index_skip
	
	addiu $t3, $t2, -65			## letter -> slot number from 0-25
	sll $t3, $t3, 2				## slot numer * 4 bytes
	addu $t3, $t3, $a1			## address of this letter's slot
	sw $t0, 0($t3)				## store the address of this line
	move $t1, $t2				## remember this letter
	
index_skip:
	lb $t4, 0($t0)
	beq $t4, $zero, index_done		## hit the end of the buffer
	addiu $t0, $t0, 1
	bne $t4, 10, index_skip			## keep going until we pass a newline
	j index_loop					## $t0 is the start of the line
	
index_done:
	jr $ra
	
find_dictionary_word:
	lb $t0, 0($a0) 		## first letter of the input word
	blt $t0, 65, not_equal	## not a capital letter
	bgt $t0, 90, not_equal
	addiu $t0, $t0, -65		## slot number
	sll $t0, $t0, 2
	addu $t0, $t0, $a1		## address of that letter's slot
	lw $t0, 0($t0)			## start of that letter's words
	beq $t0, $zero, not_equal	## no words start with this letter

line_loop:
	lb $t3, 0($t0)
	beq $t3, $zero, not_equal	## if we hit the end of the dictionary, the word isn't in it
	move $t1, $a0				## $t1 is the pointer into the input word
	move $t2, $t0				## $t2 is the pointer into this dictionary line

compare_loop:
	lb $t4, 0($t1)	## $t4 is the input character
	lb $t5, 0($t2)	## $t5 is the dictionary character
	beq $t4, 10, input_ended		## a newline ends the word
	beq $t4, 13, input_ended
	bne $t4, $zero, check_char		## input hasn't ended yet 
	## if the input ended, it's only a match if the dictionary line ends here too

input_ended:
	beq $t5, 10, equal	## newline
	beq $t5, 13, equal  ## carriage return (if there are \r\n files)
	beq $t5, $zero, equal	## last line with no newline
	j not_equal 			## input is a prefix of a longer word
	
check_char:
	bne $t4, $t5, mismatch		## if the characters are different
	addiu $t1, $t1, 1			## advance both pointers
	addiu $t2, $t2, 1
	j compare_loop
	
mismatch:
	bgt $t5, $t4, not_equal 	## if the dictionary char is bigger, we've passed where the word would be

skip_loop:
	lb $t3, 0($t0)
	beq $t3, $zero, not_equal	## hit the end of the buffer
	addiu $t0, $t0, 1			## go deeper in the dictionary
	bne $t3, 10, skip_loop		## keep going until we pass a newline
	j line_loop					## $t0 is the start of the next word

equal:
	li $v0, 1
	jr $ra
	
not_equal:
	li $v0, 0
	jr $ra
	
# Generation method:
# Pick a random word W1 that is 5-13 letters long
# Check that W1 has no two row-identical letters 
# Pick W2 from the words that start with W1's last letter 
# Count the distinct letters between W1 and W2. If it isn't 12, retry
# Assign the 12 letters to 4 sides of 3 such that no two consecutive letters of either word share a side
# If no assignment of the 12 letters works, retry
# Output the four sides and the two words

## $a0 = dict_buffer; $a1 = number of bytes read
pick_random_line:
	move $t1, $a0		## keeps the start for the bounds check
	li $v0, 42			## random int in [0, $a1)
	li $a0, 0			## generator
	syscall
	addu $t2, $t1, $a0	## $t2 is a random address in the buffer
	
back_loop:
	beq $t2, $t1, line_found	## at the buffer start, so this is a line start
	lb $t3, -1($t2) 			## gets the byte just before $t2 
	beq $t3, 10, line_found		## a newline at $t3 means $t2 is a line start
	addiu $t2, $t2, -1			## if it's not a line start, step back one byte 
	j back_loop
	
line_found:
	move $v0, $t2
	jr $ra

print_line:
	move $t0, $a0
	
pl_loop:
	lb $a0, 0($t0)
	beq $a0, 10, pl_done
	beq $a0, 13, pl_done
	beq $a0, $zero, pl_done
	li $v0, 11
	syscall
	addiu $t0, $t0, 1
	j pl_loop
	
pl_done:
	li $v0, 11
	li $a0, 10
	syscall
	jr $ra
	
word_length:
	move $t0, $a0
	li $v0, 0
	
wl_loop:
	lb $t1, 0($t0)
	beq $t1, 10, wl_done	## a newline, \r or \0 means the word ended
	beq $t1, 13, wl_done
	beq $t1, $zero, wl_done
	addiu $v0, $v0, 1		## count this letter
	addiu $t0, $t0, 1		## and move to the next one
	j wl_loop
	
wl_done:
	jr $ra

word_ok:
	addiu $sp, $sp, -4		## word_ok calls word_length, so save $ra
	sw $ra, 0($sp)	
	jal word_length			## $v0 is the length
	blt $v0, 5, word_bad	## length can't be less than 5
	bgt $v0, 13, word_bad	## length can't be more than 13
	move $t0, $a0			## pointer for the double-letter scan
	
ok_loop:
	lb $t1, 0($t0)			## this letter
	lb $t2, 1($t0) 			## next letter 
	beq $t2, 10, word_good	## next byte ends the word, so we checked every pair
	beq $t2, 13, word_good
	beq $t2, $zero, word_good
	beq $t1, $t2, word_bad	## can't have the same letter twice in a row
	addiu $t0, $t0, 1		## move to the next pair
	j ok_loop


word_good:
	li $v0, 1
	j word_return
word_bad:
	li $v0, 0
word_return:
	lw $ra, 0($sp)			## restore $ra, then pop the stack
	addiu $sp, $sp, 4
	jr $ra
	
section_range:
	li $v1, 0				## default end, in case there are no words
	addiu $t0, $a0, -65		## slot number
	sll $t1, $t0, 2
	addu $t1, $t1, $a1		## address of this letter's slot
	lw $v0, 0($t1)			## section start
	beq $v0, $zero, sr_done
	
sr_next:
	addiu $t0, $t0, 1		## look at the next letter's slot
	bne $t0, 26, sr_more	## past slot 25, there are no more letters
	move $v1, $a2			## so this section runs to the buffer end
	j sr_done
		
sr_more:
	sll $t1, $t0, 2			## load that slot's address
	addu $t1, $t1, $a1
	lw $t2, 0($t1)
	beq $t2, $zero, sr_next
	move $v1, $t2

sr_done:
	jr $ra	

# $a0 is W1 address, $a1 is letter_index, $a2 is buffer end address
# returns $v0, the W2 address, or 0 if none found
pick_w2:
	addiu $sp, $sp, -20
	sw $ra, 0($sp)
	sw $s4, 4($sp)
	sw $s5, 8($sp)
	sw $s6, 12($sp)
	sw $s7, 16($sp)
	jal word_length			## $v0 is the length of W1
	addu $t0, $a0, $v0		## address just past W1's last letter
	lb $a0, -1($t0)			## the last letter is passed as $a0
	jal section_range		## $v0 = section start. $v1 = section end
	beq $v0, $zero, w2_fail	## if no words start with that letter
	move $s4, $v0			## section start
	subu $s5, $v1, $v0		## section size = end - start
	li $s6, 50				## retry limit
	
w2_try:
	move $a0, $s4
	move $a1, $s5
	jal pick_random_line
	move $s7, $v0			## candidate
	move $a0, $s7			## is the candidate viable?
	jal word_ok
	bne $v0, $zero, w2_found
	addiu $s6, $s6, -1		## one less retry
	bgtz $s6, w2_try		## keep trying while there are retries
	
	
w2_fail:
	li $v0, 0
	j w2_done
	
w2_found:
	move $v0, $s7
	
w2_done:
	lw $ra, 0($sp)
	lw $s4, 4($sp)
	lw $s5, 8($sp)
	lw $s6, 12($sp)
	lw $s7, 16($sp)
	addiu $sp, $sp, 20
	jr $ra

letter_mask:
	move $v0, $a1
	
lm_loop:
	lb $t0, 0($a0)
	beq $t0, 10, lm_done
	beq $t0, 13, lm_done
	beq $t0, $zero, lm_done
	addiu $t1, $t0, -65			## letter -> bit number
	li $t2, 1					## shift to the left by the bit number
	sllv $t2, $t2, $t1
	or $v0, $v0, $t2			## set that bit in the mask
	addiu $a0, $a0, 1
	j lm_loop
lm_done:
	jr $ra
	
	
count_bits:
	li $v0, 0
cb_loop:
	beq $a0, $zero, cb_done
	andi $t0, $a0, 1		## get the lowest bit
	addu $v0, $v0, $t0		## to add to the count
	srl $a0, $a0, 1			## and drop that bit and move the next one down
	j cb_loop
cb_done:
	jr $ra
	
place_letter:
	addiu $sp, $sp, -20
	sw $ra, 0($sp)
	sw $s0, 4($sp)			## i
	sw $s1, 8($sp)			## s, the side we're trying
	sw $s2, 12($sp)			## workspace pointer
	sw $s3, 16($sp)			## sides opened so far
	move $s0, $a0
	move $s2, $a1
	move $s3, $a2
	beq $s0, 12, place_success	## all 12 placed
	li $s1, 0
	
place_side_loop:
	bgt $s1, 3, place_fail 		## sides are numbered 0-3, so s > 3 means we ran out
	bgt $s1, $s3, place_fail	## it can't use side s while an earlier side is still empty
	sll $t0, $s1, 2				## $t0 = 4 * s
	addu $t1, $s2, $t0			## $t1 = &sideMask[s] 
	lw $t2, 16($t1)				## $t2 = count[s]
	beq $t2, 3, place_next_side	## a side can only hold 3 letters
	# skip this side if the letter already on it conflicts with letter i
	sll $t3, $s0, 2				## $t3 = 4 * i
	addu $t3, $s2, $t3			## $t3 = &conflict[i] - 32
	lw $t4, 32($t3)				## $t4 = conflict[i]
	lw $t5, 0($t1)				## $t5 = sideMask[s]
	and $t6, $t4, $t5			## non-zero if there is a conflicting letter on side s
	bne $t6, $zero, place_next_side
	# put letter i on side s
	li $t6, 1
	sllv $t6, $t6, $s0			## $t6 = 1 << i, the bit for the letter i
	or $t5, $t5, $t6			## adds letter i to this side's mask
	sw $t5, 0($t1)				## updates sideMask[s]
	addiu $t2, $t2, 1			## one more letter on this side
	sw $t2, 16($t1)				## count[s] updated
	# recurse to place letter i+1
	addiu $a0, $s0, 1			## next letter
	move $a1, $s2				
	addiu $t7, $s1, 1			## $t7 = s + 1
	move $a2, $s3				## new opened = max(opened, s + 1); start from opened
	ble $t7, $s3, place_call	## if s + 1 <= opened, opened doesn't change
	move $a2, $t7				## otherwise, we just open side s

place_call:
	jal place_letter			## $v0 = 1 if the rest could be placed
	bne $v0, $zero, place_success
	sll $t0, $s1, 2				## the call overwrote the $t registers, so recompute
	addu $t1, $s2, $t0			## $t1 = &sideMask[s]
	lw $t5, 0($t1)
	li $t6, 1
	sllv $t6, $t6, $s0			## the bit for letter i
	xor $t5, $t5, $t6			
	sw $t5, 0($t1)
	lw $t2, 16($t1)
	addiu $t2, $t2, -1			## one fewer letter can be put on this side
	sw $t2, 16($t1) 
			
place_next_side:
	addiu $s1, $s1, 1
	j place_side_loop
	
place_success:
	li $v0, 1
	j place_done
	
place_fail:
	li $v0, 0
	
place_done:
	lw $ra, 0($sp)
	lw $s0, 4($sp)
	lw $s1, 8($sp)
	lw $s2, 12($sp)
	lw $s3, 16($sp)
	addiu $sp, $sp, 20
	jr $ra
# find a letter's position in the sorted letters[] list
letter_index_of: 
	li $v0, 0			# start at index 0
lio_loop:
	beq $v0, 12, lio_missing	## checked all 12 slots without a match
	addu $t0, $a1, $v0			## address of letters[index]
	lb $t1, 0($t0)
	beq $t1, $a0, lio_done		## found it: $v0 already holds the index
	addiu $v0, $v0, 1
	j lio_loop
lio_missing:
	li $v0, -1
lio_done:
	jr $ra
	
# record if you can't share a side for every consecutive letter pair in one word
add_conflicts:
	addiu $sp, $sp, -20
	sw $ra, 0($sp)
	sw $s0, 4($sp)				## pointer into the word
	sw $s1, 8($sp)				## workspace pointer
	sw $s2, 12($sp)				## index of the current letter
	sw $s3, 16($sp)				## index of the next letter
	move $s0, $a0
	move $s1, $a1

ac_loop:
	lb $t0, 1($s0)				## the NEXT letter; if the word ends there,
	beq $t0, 10, ac_done		## the current letter was the last one
	beq $t0, 13, ac_done
	beq $t0, $zero, ac_done

	lb $a0, 0($s0)				## index of the current letter
	addiu $a1, $s1, 80
	jal letter_index_of
	move $s2, $v0
	lb $a0, 1($s0)				## index of the next letter
	addiu $a1, $s1, 80
	jal letter_index_of
	move $s3, $v0

	sll $t1, $s2, 2				## conflict[cur] |= (1 << next)
	addu $t1, $s1, $t1
	lw $t2, 32($t1)
	li $t3, 1
	sllv $t3, $t3, $s3
	or $t2, $t2, $t3
	sw $t2, 32($t1)

	sll $t1, $s3, 2				## conflict[next] |= (1 << cur), so it works both ways
	addu $t1, $s1, $t1
	lw $t2, 32($t1)
	li $t3, 1
	sllv $t3, $t3, $s2
	or $t2, $t2, $t3
	sw $t2, 32($t1)

	addiu $s0, $s0, 1			## move to the next pair
	j ac_loop

ac_done:
	lw $ra, 0($sp)
	lw $s0, 4($sp)
	lw $s1, 8($sp)
	lw $s2, 12($sp)
	lw $s3, 16($sp)
	addiu $sp, $sp, 20
	jr $ra

assign_sides:
	addiu $sp, $sp, -112
	sw $ra, 96($sp)
	sw $s0, 100($sp)
	sw $s1, 104($sp)
	sw $s2, 108($sp)
	move $s0, $a0				## $s0 = W1
	move $s1, $a1				## $s1 = W2
	move $s2, $a2				## $s2 = board output address

	# zero the workspace: empty sides, no conflicts, no letters
	move $t0, $sp
	li $t1, 24					## 96 bytes = 24 words
zero_ws:
	sw $zero, 0($t0)
	addiu $t0, $t0, 4
	addiu $t1, $t1, -1
	bgtz $t1, zero_ws

	# extract the 12 distinct letters into letters[]
	move $a0, $s0				## mask of W1's letters
	li $a1, 0
	jal letter_mask
	move $a1, $v0				## add W2's letters
	move $a0, $s1
	jal letter_mask
	move $t0, $v0				## $t0 = combined mask (bit 0 = A ... bit 25 = Z)
	li $t1, 0					## $t1 = bit number being examined
	li $t2, 0					## $t2 = how many letters stored so far
	addiu $t3, $sp, 80			## $t3 = where the next letter goes in letters[]
ex_loop:
	beq $t1, 26, ex_done		## looked at all 26 possible letters
	srlv $t4, $t0, $t1			## move bit $t1 down to the lowest position
	andi $t4, $t4, 1
	beq $t4, $zero, ex_next		## letter not used in either word
	addiu $t5, $t1, 65			## bit number -> ASCII letter
	sb $t5, 0($t3)				## store it (letters end up in alphabetical order)
	addiu $t3, $t3, 1
	addiu $t2, $t2, 1
ex_next:
	addiu $t1, $t1, 1
	j ex_loop
ex_done:
	bne $t2, 12, as_fail		## safety check: generate_pair already required 12

	# build conflict[] from both words
	move $a0, $s0				## every consecutive pair in W1
	move $a1, $sp
	jal add_conflicts
	move $a0, $s1				## every consecutive pair in W2
	move $a1, $sp
	jal add_conflicts

	# run the backtracking search
	li $a0, 0					## start by placing letter 0
	move $a1, $sp				## the workspace is at the bottom of the frame
	li $a2, 0					## no sides opened yet
	jal place_letter			## $v0 = 1 if a layout exists
	beq $v0, $zero, as_fail

	# write the board, 3 bytes per side
	li $t0, 0					## $t0 = side number
wb_side:
	beq $t0, 4, as_ok			## all 4 sides written
	sll $t1, $t0, 2
	addu $t1, $sp, $t1
	lw $t2, 0($t1)				## $t2 = sideMask[s]
	sll $t3, $t0, 1				## side * 3 = side * 2 + side
	addu $t3, $t3, $t0
	addu $t3, $s2, $t3			## $t3 = where this side's 3 bytes go in the board
	li $t4, 0					## $t4 = letter index being checked
wb_letter:
	beq $t4, 12, wb_next_side
	srlv $t5, $t2, $t4			## is letter $t4 on this side?
	andi $t5, $t5, 1
	beq $t5, $zero, wb_skip
	addiu $t6, $sp, 80
	addu $t6, $t6, $t4
	lb $t7, 0($t6)				## the letter itself, from letters[]
	sb $t7, 0($t3)				## write it into the board
	addiu $t3, $t3, 1			## next board byte on this side
wb_skip:
	addiu $t4, $t4, 1
	j wb_letter
wb_next_side:
	addiu $t0, $t0, 1
	j wb_side

as_ok:
	li $v0, 1
	j as_done

as_fail:
	li $v0, 0

as_done:
	lw $ra, 96($sp)
	lw $s0, 100($sp)
	lw $s1, 104($sp)
	lw $s2, 108($sp)
	addiu $sp, $sp, 112			## free the frame on every exit path
	jr $ra

# generate_pair: the generator's entry point
# $a0 = dictionary buffer, $a1 = letter_index, $a2 = bytes read, $a3 = board (12 bytes)
# returns $v0 = W1, $v1 = W2
generate_pair:
	addiu $sp, $sp, -32
	sw $ra, 0($sp)
	sw $s0, 4($sp)
	sw $s1, 8($sp)
	sw $s2, 12($sp)
	sw $s3, 16($sp)
	sw $s4, 20($sp)
	sw $s5, 24($sp)
	sw $s6, 28($sp)
	move $s0, $a0			## dictionary buffer
	move $s1, $a1			## letter_index
	move $s2, $a2			## bytes read
	move $s5, $a3			## board output address (12 bytes)
	li $s6, 2000			## retry cap 
	
gp_try:
	beq $s6, $zero, gp_fallback		## if out of attempts, use the fallback board
	addiu $s6, $s6, -1				## this pass uses one attempt, so decrement
	move $a0, $s0
	move $a1, $s2
	jal pick_random_line
	move $s3, $v0			## candidate W1
	move $a0, $s3
	jal word_ok
	beq $v0, $zero, gp_try
	move $a0, $s3
	move $a1, $s1
	addu $a2, $s0, $s2		## buffer end address
	jal pick_w2
	beq $v0, $zero, gp_try
	move $s4, $v0			## candidate W2
	move $a0, $s3			## mask of W1 alone
	li $a1, 0
	jal letter_mask
	move $a1, $v0			## Add W2's letters to the mask
	move $a0, $s4
	jal letter_mask
	move $a0, $v0			## Count the 1 bits
	jal count_bits
	bne $v0, 12, gp_try		## If there aren't exactly 12 distinct letters, we try again
	move $a0, $s3			## can the letters be split into 4 sides of 3?
	move $a1, $s4
	move $a2, $s5
	jal assign_sides
	beq $v0, $zero, gp_try	## no valid layout: pick a new pair
	move $v0, $s3			## W1
	move $v1, $s4			## W2
	j gp_done
	
gp_fallback:
	li $t0, 'L'
	sb $t0, 0($s5)
	li $t0, 'O'
	sb $t0, 1($s5)
	li $t0, 'U'
	sb $t0, 2($s5)
	li $t0, 'A'
	sb $t0, 3($s5)
	li $t0, 'D'
	sb $t0, 4($s5)
	li $t0, 'N'
	sb $t0, 5($s5)
	li $t0, 'B'
	sb $t0, 6($s5)
	li $t0, 'K'
	sb $t0, 7($s5)
	li $t0, 'P'
	sb $t0, 8($s5)
	li $t0, 'E'
	sb $t0, 9($s5)
	li $t0, 'S'
	sb $t0, 10($s5)
	li $t0, 'Y'
	sb $t0, 11($s5)
	li $v0, 0				## no solution words for the fallback
	li $v1, 0
	
gp_done:
	lw $ra, 0($sp)
	lw $s0, 4($sp)
	lw $s1, 8($sp)
	lw $s2, 12($sp)
	lw $s3, 16($sp)
	lw $s4, 20($sp)
	lw $s5, 24($sp)
	lw $s6, 28($sp)
	addiu $sp, $sp, 32
	jr $ra
	
