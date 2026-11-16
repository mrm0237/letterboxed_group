## Game logic and validation - 


# Letter Boxed Project
# Game Logic and Validation
# Elise Morhack



.data

#track used letters
.globl usedLetters
usedLetters: .word 0

#track number of words
.globl wordCount
wordCount: .word 0


    
.text

.globl checkLength
.globl checkBoardLetters
.globl checkSides
.globl checkConnection
.globl updateUsedLetters
.globl checkWin
.globl updateWordCount
.globl checkPar






checkLength:
    #start counting @ 0
    li $t0, 0



lengthLoop:
    #get next character
    add $t1, $a0, $t0
    lb $t2, 0($t1)
    
    
    

    #stop at end of word
    beq $t2, $zero, lengthDone



    #stop if newline
    li $t3, 10
    
    beq $t2, $t3, lengthDone




    # + length
    addi $t0, $t0, 1
    
    j lengthLoop
    
    
    

lengthDone:


    #see if words to short
    blt $t0, 3, tooShort



    #see if wrods to long
    bgt $t0, 15, tooLong




    #good length
    li $v0, 0
    jr $ra



tooShort:
    li $v0, 1
    jr $ra

tooLong:
    li $v0, 2
    jr $ra
     

#letters on board?
.globl checkBoardLetters




checkBoardLetters:
    #@first letter
    li $t0, 0



boardWordLoop:
    #letter from word
    add $t1, $a0, $t0
    lb $t2, 0($t1)

    #stop at end of word
    beq $t2, $zero, boardValid

    #stop if newline
    li $t3, 10
    beq $t2, $t3, boardValid



    #start checking board
    li $t4, 0



boardSearchLoop:
    #check all 12 letters
    beq $t4, 12, boardInvalid
    
    

    #get letter from board
    add $t5, $a1, $t4
    
    lb $t6, 0($t5)



    #letters match?
    beq $t2, $t6, boardFound
    
    

    #check next board letter
    addi $t4, $t4, 1
    j boardSearchLoop



boardFound:
    #move on
    addi $t0, $t0, 1
    j boardWordLoop



boardValid:
    #all letters are on board
    li $v0, 0
    jr $ra



boardInvalid:
    #letter not on board
    li $v0, 3
    jr $ra


    
    
    
#check letters are not on same side
.globl checkSides

checkSides:
    #start first letter
    li $t0, 0

    #no past side yet
    li $t7, -1



sideWordLoop:
    #next letter
    add $t1, $a0, $t0
    lb $t2, 0($t1)

    #stop at end of word
    beq $t2, $zero, sidesValid

    #stop if newline
    li $t3, 10
    beq $t2, $t3, sidesValid



    #start checking board
    li $t4, 0



sideSearchLoop:
    #check all 12 letters
    beq $t4, 12, sidesInvalid



    #get board letter
    add $t5, $a1, $t4
    
    lb $t6, 0($t5)


    #letters match?
    beq $t2, $t6, sideFound
    
    

    #check next board letter
    addi $t4, $t4, 1
    j sideSearchLoop



sideFound:
    #find which side letter is on
    li $t8, 3
    
    div $t4, $t8
    
    mflo $t9
    
    

    #check if same as previous side
    beq $t9, $t7, sidesInvalid



    #save current side
    move $t7, $t9



    #move to next word letter
    addi $t0, $t0, 1
    j sideWordLoop

sidesValid:
    #letters are on different sides
    li $v0, 0
    jr $ra



sidesInvalid:
    #same side or invalid letter
    li $v0, 3
    jr $ra   
    
    
#check connecting letter
.globl checkConnection



checkConnection:
    #a0 = new word
    #a1 = connecting letter [0 for first word]



    #get first letter
    lb $t0, 0($a0)



    #first not need connection
    beq $a1, $zero, connectionValid



    #letters match?
    beq $t0, $a1, connectionValid



    #letters not match
    li $v0, 3
    jr $ra


connectionValid:
    #good connection
    li $v0, 0
    jr $ra
    
    
    
    
    
    
#track letters used
.globl updateUsedLetters

updateUsedLetters:
    #start at first letter
    li $t0, 0

    #get used letters
    lw $t7, usedLetters



usedWordLoop:
    #get next word letter
    add $t1, $a0, $t0
    lb $t2, 0($t1)

    #stop at end of word
    beq $t2, $zero, usedDone

    #stop if newline
    li $t3, 10
    beq $t2, $t3, usedDone



    #start checking board
    li $t4, 0



usedSearchLoop:
    #check all 12 letters
    beq $t4, 12, usedInvalid

    #get board letter
    add $t5, $a1, $t4
    lb $t6, 0($t5)

    #see if letters match
    beq $t2, $t6, usedFound

    #check next board letter
    addi $t4, $t4, 1
    j usedSearchLoop



usedFound:
    #make bit for letter
    li $t8, 1
    sllv $t8, $t8, $t4

    #mark letter as used
    or $t7, $t7, $t8

    #move to next letter
    addi $t0, $t0, 1
    j usedWordLoop



usedDone:
    #save used letters
    sw $t7, usedLetters

    #good word
    li $v0, 0
    jr $ra



usedInvalid:
    #letter not on board
    li $v0, 3
    jr $ra

    
    
    
#check if all letters have been used
.globl checkWin

checkWin:
    #get used letters
    lw $t0, usedLetters

    #all 12 letters
    li $t1, 4095

    #check if all used
    beq $t0, $t1, gameWon

    #not won yet
    li $v0, 0
    jr $ra



gameWon:
    #all letters used
    li $v0, 1
    jr $ra
    
    
    
    
    
#count valid words
.globl updateWordCount




updateWordCount:
    #get current word count
    lw $t0, wordCount



    #add 
    
    addi $t0, $t0, 1

    #save word count
    sw $t0, wordCount





    #return new 
    move $v0, $t0
    jr $ra







#check number of words for star
.globl checkPar

checkPar:
    #get word count
    lw $t0, wordCount

    #2
    ble $t0, 2, star20

    #3
    beq $t0, 3, star18

    #4
    beq $t0, 4, star16

    #5
    beq $t0, 5, star14

    #6
    beq $t0, 6, star12

    #7
    li $v0, 10
    jr $ra



star20:
    li $v0, 20
    jr $ra





star18:
    li $v0, 18
    jr $ra



star16:
    li $v0, 16
    jr $ra



star14:
    li $v0, 14
    jr $ra



star12:
    li $v0, 12
    jr $ra


    
    
    
   

