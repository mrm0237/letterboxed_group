# Connor Burley - Letter Boxed graphics module and standalone demo.
# MARS 4.5, default memory configuration, pseudo-instructions enabled.
# Bitmap Display: unit width=1, unit height=1, display=512x512,
# base=0x10010000 (static data). Connect to MIPS BEFORE running.
# imageBuffer MUST remain the first object in .data.
# Coordinates are logical pixels, origin at top left; x right, y down.
# All public drawing routines preserve $s0-$s7. $t/$a/$v are volatile.
# Explicit delay-slot nops allow delayed branching ON or OFF.
# This is graphics, not word validation or a dictionary/puzzle generator.
# Demo commands in Run I/O: F=failure, S=star, R=board, Q=quit.
# Each command is followed by Enter. Real game command list is drawn on screen.

.eqv AZURE 0x007fff
.eqv BLUE 0x0075ec
.eqv CHARCOAL 0x3c4142
.eqv BLACK 0x000000
.eqv WHITE 0xffffff
.eqv ORANGE 0xff7f00
.eqv CONNECT_ORANGE 0xffa500
.eqv GREEN 0x00ff01
.eqv VIOLET 0xc71585
.data 0x10010000
.align 2
imageBuffer: .space 1048576     # 512 * 512 * 4 bytes, no overlap
# TEAM INTERFACE: top, left, bottom, right; each side has 3 letters.
# Sample letters/paths demonstrate graphics, not a verified solvable puzzle.
boardLetters: .ascii "ABCDEFGHIJKL"
.align 2
letterX: .word 192,256,320,128,128,128,192,256,320,384,384,384
letterY: .word 112,112,112,192,256,320,368,368,368,192,256,320
# Paths contain board indices (0..11). length bounds checked by renderer.
currentPath: .word 6,10,2,5
.space 48                    # 16 word slots total
currentLength: .word 4
currentWord: .asciiz "GKCF"
.space 12                    # 17 bytes total, max 15 chars + NUL
.align 2
acceptedPath: .word 0,4,8,3,7,11,6
.space 996                   # 256 indices total
acceptedLength: .word 7       # one example accepted word
acceptedWord: .asciiz "AEIDHLG"
.space 9                     # 17 bytes total
.align 2
usedMask: .word 0x9d9         # indices 0,3,4,6,7,8,11
wordCount: .word 2
par: .word 2
fontScale: .word 2
# drawLine inputs: a0=x0,a1=y0,a2=x1,a3=y1; globals below.
drawColor: .word BLACK
lineDashed: .word 0           # 0 solid, 1 dashed, 4 on / 4 off
# Error text supplied by game logic; do not pass overlong/unbounded strings.
failureWord: .asciiz "CAT"
failureMessage: .asciiz "IS NOT VALID"
titleText: .asciiz "ENTER A WORD"
parText: .asciiz "TRY TO SOLVE IN"
parSuffix: .asciiz "WORDS"
command1: .asciiz "RR RESTART    XX DELETE    EE ENTER"
command2: .asciiz "W TOP   A LEFT   S BOTTOM   D RIGHT"
command3: .asciiz "J FIRST       K MIDDLE      L LAST"
command4: .asciiz "SELECT SIDE, THEN POSITION"
wordLabel: .asciiz "LAST WORD:"
consoleHelp: .asciiz "GRAPHICS DEMO ONLY. F=failure, S=star, R=redraw, Q=quit.\nType a command and press Enter: "
inputBuffer: .space 32
charBuffer: .space 2
numberBuffer: .space 12
.align 2
starColors: .word 0xfff200,0xffda03,0xffd300,0xfee12b,0xeffd5f,0x777b7e
starSizes: .word 20,18,16,14,12,10
# Normalized five-point star, 10 vertices; fixed integer coordinates.
starX: .word 0,24,95,38,59,0,-59,-38,-95,-24
starY: .word -100,-32,-31,12,81,40,81,12,-31,-32
# Five-bit rows, seven rows per glyph, ASCII 32..90. Filled below.
fontData:

.byte 0,0,0,0,0,0,0 # ASCII 32

.byte 0,0,0,0,0,0,0 # ASCII 33

.byte 0,0,0,0,0,0,0 # ASCII 34

.byte 0,0,0,0,0,0,0 # ASCII 35

.byte 0,0,0,0,0,0,0 # ASCII 36

.byte 0,0,0,0,0,0,0 # ASCII 37

.byte 0,0,0,0,0,0,0 # ASCII 38

.byte 0,0,0,0,0,0,0 # ASCII 39

.byte 0,0,0,0,0,0,0 # ASCII 40

.byte 0,0,0,0,0,0,0 # ASCII 41

.byte 0,0,0,0,0,0,0 # ASCII 42

.byte 0,0,0,0,0,0,0 # ASCII 43

.byte 0,0,0,0,0,0,0 # ASCII 44

.byte 0,0,0,31,0,0,0 # ASCII 45

.byte 0,0,0,0,0,0,0 # ASCII 46

.byte 0,0,0,0,0,0,0 # ASCII 47

.byte 14,17,19,21,25,17,14 # ASCII 48

.byte 4,12,4,4,4,4,14 # ASCII 49

.byte 14,17,1,2,4,8,31 # ASCII 50

.byte 30,1,1,14,1,1,30 # ASCII 51

.byte 2,6,10,18,31,2,2 # ASCII 52

.byte 31,16,16,30,1,1,30 # ASCII 53

.byte 14,16,16,30,17,17,14 # ASCII 54

.byte 31,1,2,4,8,8,8 # ASCII 55

.byte 14,17,17,14,17,17,14 # ASCII 56

.byte 14,17,17,15,1,1,14 # ASCII 57

.byte 0,4,4,0,4,4,0 # ASCII 58

.byte 0,0,0,0,0,0,0 # ASCII 59

.byte 0,0,0,0,0,0,0 # ASCII 60

.byte 0,0,0,0,0,0,0 # ASCII 61

.byte 0,0,0,0,0,0,0 # ASCII 62

.byte 0,0,0,0,0,0,0 # ASCII 63

.byte 0,0,0,0,0,0,0 # ASCII 64

.byte 14,17,17,31,17,17,17 # ASCII 65

.byte 30,17,17,30,17,17,30 # ASCII 66

.byte 14,17,16,16,16,17,14 # ASCII 67

.byte 30,17,17,17,17,17,30 # ASCII 68

.byte 31,16,16,30,16,16,31 # ASCII 69

.byte 31,16,16,30,16,16,16 # ASCII 70

.byte 14,17,16,23,17,17,15 # ASCII 71

.byte 17,17,17,31,17,17,17 # ASCII 72

.byte 31,4,4,4,4,4,31 # ASCII 73

.byte 7,2,2,2,18,18,12 # ASCII 74

.byte 17,18,20,24,20,18,17 # ASCII 75

.byte 16,16,16,16,16,16,31 # ASCII 76

.byte 17,27,21,21,17,17,17 # ASCII 77

.byte 17,25,21,19,17,17,17 # ASCII 78

.byte 14,17,17,17,17,17,14 # ASCII 79

.byte 30,17,17,30,16,16,16 # ASCII 80

.byte 14,17,17,17,21,18,13 # ASCII 81

.byte 30,17,17,30,20,18,17 # ASCII 82

.byte 15,16,16,14,1,1,30 # ASCII 83

.byte 31,4,4,4,4,4,4 # ASCII 84

.byte 17,17,17,17,17,17,14 # ASCII 85

.byte 17,17,17,17,17,10,4 # ASCII 86

.byte 17,17,17,21,21,21,10 # ASCII 87

.byte 17,17,10,4,10,17,17 # ASCII 88

.byte 17,17,10,4,4,4,4 # ASCII 89

.byte 31,1,2,4,8,16,31 # ASCII 90

.text
.globl main
main:
    jal renderGame
    nop
demoLoop:
    la $a0,consoleHelp
    li $v0,4
    syscall
    la $a0,inputBuffer
    li $a1,32
    li $v0,8
    syscall
    lbu $t0,inputBuffer
    beq $t0,81,demoQuit
    nop
    beq $t0,113,demoQuit
    nop
    beq $t0,70,demoFail
    nop
    beq $t0,102,demoFail
    nop
    beq $t0,83,demoStar
    nop
    beq $t0,115,demoStar
    nop
    jal renderGame
    nop
    b demoLoop
    nop
demoFail:
    la $a0,failureWord
    la $a1,failureMessage
    jal drawFailureBox
    nop
    # Integration: Eadan owns sleep and redraw, not drawFailureBox.
    li $a0,3000
    li $v0,32
    syscall
    jal renderGame
    nop
    b demoLoop
    nop
demoStar:
    lw $a0,wordCount
    jal drawStar
    nop
    b demoLoop
    nop
demoQuit:
    li $v0,10
    syscall

# putPixel(a0=x,a1=y,a2=RGB). Clips to buffer; leaf routine.
putPixel:
    sltiu $t0,$a0,512
    beqz $t0,pixelDone
    nop
    sltiu $t0,$a1,512
    beqz $t0,pixelDone
    nop
    sll $t0,$a1,9
    addu $t0,$t0,$a0
    sll $t0,$t0,2
    la $t1,imageBuffer
    addu $t0,$t0,$t1
    sw $a2,0($t0)
pixelDone:
    jr $ra
    nop

# clearScreen(a0=RGB). Writes every word after display connection.
clearScreen:
    la $t0,imageBuffer
    li $t1,262144
clearLoop:
    sw $a0,0($t0)
    addiu $t0,$t0,4
    addiu $t1,$t1,-1
    bnez $t1,clearLoop
    nop
    jr $ra
    nop

fillRect:
    addiu $sp,$sp,-40
    sw $ra,36($sp)
    sw $s0,0($sp)
    sw $s1,4($sp)
    sw $s2,8($sp)
    sw $s3,12($sp)
    sw $s4,16($sp)
    sw $s5,20($sp)
    sw $s6,24($sp)
    sw $s7,28($sp)

# a0=x,a1=y,a2=width,a3=height; drawColor supplies RGB.
    move $s0,$a0
    move $s1,$a1
    move $s2,$a2
    move $s3,$a3
    blez $s2,rectDone
    nop
    blez $s3,rectDone
    nop
    li $s4,0
rectRow:
    li $s5,0
rectCol:
    addu $a0,$s0,$s5
    addu $a1,$s1,$s4
    lw $a2,drawColor
    jal putPixel
    nop
    addiu $s5,$s5,1
    blt $s5,$s2,rectCol
    nop
    addiu $s4,$s4,1
    blt $s4,$s3,rectRow
    nop
rectDone:

lw $s0,0($sp)
    lw $s1,4($sp)
    lw $s2,8($sp)
    lw $s3,12($sp)
    lw $s4,16($sp)
    lw $s5,20($sp)
    lw $s6,24($sp)
    lw $s7,28($sp)
    lw $ra,36($sp)
    addiu $sp,$sp,40
    jr $ra
    nop

drawLine:
    addiu $sp,$sp,-40
    sw $ra,36($sp)
    sw $s0,0($sp)
    sw $s1,4($sp)
    sw $s2,8($sp)
    sw $s3,12($sp)
    sw $s4,16($sp)
    sw $s5,20($sp)
    sw $s6,24($sp)
    sw $s7,28($sp)

# All-octant integer Bresenham. drawColor and lineDashed are inputs.
    move $s0,$a0
    move $s1,$a1
    move $s2,$a2
    move $s3,$a3
    subu $s4,$s2,$s0
    abs $s4,$s4                 # dx >= 0
    subu $s5,$s3,$s1
    abs $s5,$s5
    subu $s5,$zero,$s5          # dy <= 0
    addu $s6,$s4,$s5           # err
    li $s7,0                   # dash counter
lineLoop:
    lw $t0,lineDashed
    beqz $t0,linePlot
    nop
    andi $t0,$s7,7
    bge $t0,4,lineNext
    nop
linePlot:
    move $a0,$s0
    move $a1,$s1
    lw $a2,drawColor
    jal putPixel
    nop
lineNext:
    bne $s0,$s2,lineStep
    nop
    beq $s1,$s3,lineDone
    nop
lineStep:
    sll $t2,$s6,1              # e2 snapshot for BOTH tests
    blt $t2,$s5,lineSkipX
    nop
    addu $s6,$s6,$s5
    li $t3,-1
    bge $s0,$s2,lineMoveX
    nop
    li $t3,1
lineMoveX:
    addu $s0,$s0,$t3
lineSkipX:
    bgt $t2,$s4,lineSkipY
    nop
    addu $s6,$s6,$s4
    li $t3,-1
    bge $s1,$s3,lineMoveY
    nop
    li $t3,1
lineMoveY:
    addu $s1,$s1,$t3
lineSkipY:
    addiu $s7,$s7,1
    b lineLoop
    nop
lineDone:

lw $s0,0($sp)
    lw $s1,4($sp)
    lw $s2,8($sp)
    lw $s3,12($sp)
    lw $s4,16($sp)
    lw $s5,20($sp)
    lw $s6,24($sp)
    lw $s7,28($sp)
    lw $ra,36($sp)
    addiu $sp,$sp,40
    jr $ra
    nop

drawCircle:
    addiu $sp,$sp,-40
    sw $ra,36($sp)
    sw $s0,0($sp)
    sw $s1,4($sp)
    sw $s2,8($sp)
    sw $s3,12($sp)
    sw $s4,16($sp)
    sw $s5,20($sp)
    sw $s6,24($sp)
    sw $s7,28($sp)

# a0=cx,a1=cy,a2=radius,a3=color. Integer ring, thickness ~2px.
    move $s0,$a0
    move $s1,$a1
    move $s2,$a2
    move $s3,$a3
    mul $s6,$s2,$s2
    addiu $t0,$s2,-2
    mul $s7,$t0,$t0
    subu $s4,$zero,$s2
circleRow:
    subu $s5,$zero,$s2
circleCol:
    mul $t0,$s4,$s4
    mul $t1,$s5,$s5
    addu $t0,$t0,$t1
    bgt $t0,$s6,circleSkip
    nop
    blt $t0,$s7,circleSkip
    nop
    addu $a0,$s0,$s5
    addu $a1,$s1,$s4
    move $a2,$s3
    jal putPixel
    nop
circleSkip:
    addiu $s5,$s5,1
    ble $s5,$s2,circleCol
    nop
    addiu $s4,$s4,1
    ble $s4,$s2,circleRow
    nop

lw $s0,0($sp)
    lw $s1,4($sp)
    lw $s2,8($sp)
    lw $s3,12($sp)
    lw $s4,16($sp)
    lw $s5,20($sp)
    lw $s6,24($sp)
    lw $s7,28($sp)
    lw $ra,36($sp)
    addiu $sp,$sp,40
    jr $ra
    nop

drawChar:
    addiu $sp,$sp,-40
    sw $ra,36($sp)
    sw $s0,0($sp)
    sw $s1,4($sp)
    sw $s2,8($sp)
    sw $s3,12($sp)
    sw $s4,16($sp)
    sw $s5,20($sp)
    sw $s6,24($sp)
    sw $s7,28($sp)

# a0=ASCII,a1=x,a2=y,a3=color; fontScale=1 or 2.
    blt $a0,32,charDone
    nop
    bgt $a0,90,charDone
    nop
    addiu $t0,$a0,-32
    li $t1,7
    mul $t0,$t0,$t1
    la $s0,fontData
    addu $s0,$s0,$t0
    move $s1,$a1
    move $s2,$a2
    move $s3,$a3
    li $s4,0
charRow:
    li $s5,0
charCol:
    addu $t0,$s0,$s4
    lbu $t0,0($t0)
    li $t1,4
    subu $t1,$t1,$s5
    srlv $t0,$t0,$t1
    andi $t0,$t0,1
    beqz $t0,charSkip
    nop
    lw $t2,fontScale
    mul $a0,$s5,$t2
    addu $a0,$a0,$s1
    mul $a1,$s4,$t2
    addu $a1,$a1,$s2
    move $a2,$t2
    move $a3,$t2
    sw $s3,drawColor
    jal fillRect
    nop
charSkip:
    addiu $s5,$s5,1
    blt $s5,5,charCol
    nop
    addiu $s4,$s4,1
    blt $s4,7,charRow
    nop
charDone:

lw $s0,0($sp)
    lw $s1,4($sp)
    lw $s2,8($sp)
    lw $s3,12($sp)
    lw $s4,16($sp)
    lw $s5,20($sp)
    lw $s6,24($sp)
    lw $s7,28($sp)
    lw $ra,36($sp)
    addiu $sp,$sp,40
    jr $ra
    nop

drawString:
    addiu $sp,$sp,-40
    sw $ra,36($sp)
    sw $s0,0($sp)
    sw $s1,4($sp)
    sw $s2,8($sp)
    sw $s3,12($sp)
    sw $s4,16($sp)
    sw $s5,20($sp)
    sw $s6,24($sp)
    sw $s7,28($sp)

# a0=NUL string,a1=x,a2=y,a3=color; uppercase font only.
    move $s0,$a0
    move $s1,$a1
    move $s2,$a2
    move $s3,$a3
stringLoop:
    lbu $a0,0($s0)
    beqz $a0,stringDone
    nop
    move $a1,$s1
    move $a2,$s2
    move $a3,$s3
    jal drawChar
    nop
    lw $t0,fontScale
    li $t1,6
    mul $t0,$t0,$t1
    addu $s1,$s1,$t0
    addiu $s0,$s0,1
    b stringLoop
    nop
stringDone:

lw $s0,0($sp)
    lw $s1,4($sp)
    lw $s2,8($sp)
    lw $s3,12($sp)
    lw $s4,16($sp)
    lw $s5,20($sp)
    lw $s6,24($sp)
    lw $s7,28($sp)
    lw $ra,36($sp)
    addiu $sp,$sp,40
    jr $ra
    nop

drawPath:
    addiu $sp,$sp,-40
    sw $ra,36($sp)
    sw $s0,0($sp)
    sw $s1,4($sp)
    sw $s2,8($sp)
    sw $s3,12($sp)
    sw $s4,16($sp)
    sw $s5,20($sp)
    sw $s6,24($sp)
    sw $s7,28($sp)

# a0=word indices pointer,a1=count,a2=dashed flag.
    move $s0,$a0
    move $s1,$a1
    sw $a2,lineDashed
    li $t0,BLUE
    sw $t0,drawColor
    li $s2,1
    ble $s1,1,pathDone
    nop
    bgt $s1,256,pathDone
    nop
pathLoop:
    lw $t0,0($s0)
    lw $t1,4($s0)
    bgeu $t0,12,pathSkip
    nop
    bgeu $t1,12,pathSkip
    nop
    sll $t0,$t0,2
    sll $t1,$t1,2
    la $t2,letterX
    addu $t3,$t2,$t0
    lw $a0,0($t3)
    addu $t3,$t2,$t1
    lw $a2,0($t3)
    la $t2,letterY
    addu $t3,$t2,$t0
    lw $a1,0($t3)
    addu $t3,$t2,$t1
    lw $a3,0($t3)
    jal drawLine
    nop
pathSkip:
    addiu $s0,$s0,4
    addiu $s2,$s2,1
    blt $s2,$s1,pathLoop
    nop
pathDone:

lw $s0,0($sp)
    lw $s1,4($sp)
    lw $s2,8($sp)
    lw $s3,12($sp)
    lw $s4,16($sp)
    lw $s5,20($sp)
    lw $s6,24($sp)
    lw $s7,28($sp)
    lw $ra,36($sp)
    addiu $sp,$sp,40
    jr $ra
    nop

renderGame:
    addiu $sp,$sp,-40
    sw $ra,36($sp)
    sw $s0,0($sp)
    sw $s1,4($sp)
    sw $s2,8($sp)
    sw $s3,12($sp)
    sw $s4,16($sp)
    sw $s5,20($sp)
    sw $s6,24($sp)
    sw $s7,28($sp)

# Redraw from shared state. No input, validation, sleep, or win decision here.
li $a0,AZURE
jal clearScreen
nop
li $t0,2
sw $t0,fontScale
la $a0,titleText
li $a1,184
li $a2,12
li $a3,BLACK
jal drawString
nop
la $a0,parText
li $a1,118
li $a2,34
li $a3,VIOLET
jal drawString
nop
lw $t0,par
li $t1,10
bltu $t0,$t1,renderParDigit
nop
li $t0,9
renderParDigit:
addiu $a0,$t0,48
li $a1,310
li $a2,34
li $a3,VIOLET
jal drawChar
nop
la $a0,parSuffix
li $a1,334
li $a2,34
li $a3,VIOLET
jal drawString
nop
la $a0,currentWord
li $a1,166
li $a2,57
li $a3,BLACK
jal drawString
nop
li $a0,128
li $a1,76
li $a2,256
li $a3,2
li $t0,BLACK
sw $t0,drawColor
jal fillRect
nop
li $a0,128
li $a1,112
li $a2,257
li $a3,2
li $t0,CHARCOAL
sw $t0,drawColor
jal fillRect
nop
li $a0,128
li $a1,367
li $a2,257
li $a3,2
li $t0,CHARCOAL
sw $t0,drawColor
jal fillRect
nop
li $a0,128
li $a1,112
li $a2,2
li $a3,257
li $t0,CHARCOAL
sw $t0,drawColor
jal fillRect
nop
li $a0,383
li $a1,112
li $a2,2
li $a3,257
li $t0,CHARCOAL
sw $t0,drawColor
jal fillRect
nop
la $a0,acceptedPath
lw $a1,acceptedLength
li $a2,0
jal drawPath
nop
la $a0,currentPath
lw $a1,currentLength
bgt $a1,15,renderNoCurrent
nop
li $a2,1
jal drawPath
nop
renderNoCurrent:
li $s0,0
renderLetters:
sll $s1,$s0,2
la $t0,letterX
addu $t0,$t0,$s1
lw $s2,0($t0)
la $t0,letterY
addu $t0,$t0,$s1
lw $s3,0($t0)
# Used or currently selected letter: blue circle, black letter.
lw $t0,usedMask
srlv $t0,$t0,$s0
andi $s4,$t0,1
la $t0,currentPath
lw $t1,currentLength
li $t2,0
renderSelectedLoop:
bge $t2,$t1,renderSelectedDone
nop
bge $t2,15,renderSelectedDone
nop
lw $t3,0($t0)
bne $t3,$s0,renderSelectedNext
nop
li $s4,1
renderSelectedNext:
addiu $t0,$t0,4
addiu $t2,$t2,1
b renderSelectedLoop
nop
renderSelectedDone:
addiu $a0,$s2,-15
addiu $a1,$s3,-15
li $a2,31
li $a3,31
li $t0,AZURE
sw $t0,drawColor
jal fillRect
nop
move $a0,$s2
move $a1,$s3
li $a2,14
li $a3,CHARCOAL
beqz $s4,renderCircle
nop
li $a3,BLUE
renderCircle:
jal drawCircle
nop
la $t0,boardLetters
addu $t0,$t0,$s0
lbu $a0,0($t0)
addiu $a1,$s2,-5
addiu $a2,$s3,-7
li $a3,WHITE
beqz $s4,renderLetter
nop
li $a3,BLACK
renderLetter:
jal drawChar
nop
addiu $s0,$s0,1
blt $s0,12,renderLetters
nop
li $t0,1
sw $t0,fontScale
la $a0,wordLabel
li $a1,110
li $a2,393
li $a3,BLACK
jal drawString
nop
la $s0,acceptedWord
li $s1,178
renderHistory:
lbu $a0,0($s0)
beqz $a0,renderHistoryDone
nop
move $a1,$s1
li $a2,393
li $a3,ORANGE
lbu $t0,1($s0)
bnez $t0,renderHistoryChar
nop
li $a3,CONNECT_ORANGE
renderHistoryChar:
jal drawChar
nop
addiu $s0,$s0,1
addiu $s1,$s1,6
b renderHistory
nop
renderHistoryDone:
li $a0,44
li $a1,418
li $a2,424
li $a3,2
li $t0,WHITE
sw $t0,drawColor
jal fillRect
nop
li $a0,44
li $a1,504
li $a2,424
li $a3,2
li $t0,WHITE
sw $t0,drawColor
jal fillRect
nop
li $a0,44
li $a1,418
li $a2,2
li $a3,88
li $t0,WHITE
sw $t0,drawColor
jal fillRect
nop
li $a0,466
li $a1,418
li $a2,2
li $a3,88
li $t0,WHITE
sw $t0,drawColor
jal fillRect
nop
la $a0,command1
li $a1,58
li $a2,432
li $a3,GREEN
jal drawString
nop
la $a0,command2
li $a1,58
li $a2,450
li $a3,GREEN
jal drawString
nop
la $a0,command3
li $a1,58
li $a2,468
li $a3,GREEN
jal drawString
nop
la $a0,command4
li $a1,58
li $a2,486
li $a3,GREEN
jal drawString
nop

lw $s0,0($sp)
    lw $s1,4($sp)
    lw $s2,8($sp)
    lw $s3,12($sp)
    lw $s4,16($sp)
    lw $s5,20($sp)
    lw $s6,24($sp)
    lw $s7,28($sp)
    lw $ra,36($sp)
    addiu $sp,$sp,40
    jr $ra
    nop

drawFailureBox:
    addiu $sp,$sp,-40
    sw $ra,36($sp)
    sw $s0,0($sp)
    sw $s1,4($sp)
    sw $s2,8($sp)
    sw $s3,12($sp)
    sw $s4,16($sp)
    sw $s5,20($sp)
    sw $s6,24($sp)
    sw $s7,28($sp)

# a0=word (<=15 chars), a1=message (<=20 chars), NUL terminated.
# Draw only. Main loop sleeps 3000ms then calls renderGame.
move $s0,$a0
move $s1,$a1
lw $s2,fontScale
li $t0,2
sw $t0,fontScale
li $a0,68
li $a1,210
li $a2,376
li $a3,84
li $t0,BLACK
sw $t0,drawColor
jal fillRect
nop
move $a0,$s0
li $a1,80
li $a2,225
li $a3,WHITE
jal drawString
nop
move $a0,$s1
li $a1,80
li $a2,257
li $a3,WHITE
jal drawString
nop
sw $s2,fontScale

lw $s0,0($sp)
    lw $s1,4($sp)
    lw $s2,8($sp)
    lw $s3,12($sp)
    lw $s4,16($sp)
    lw $s5,20($sp)
    lw $s6,24($sp)
    lw $s7,28($sp)
    lw $ra,36($sp)
    addiu $sp,$sp,40
    jr $ra
    nop

drawStar:
    addiu $sp,$sp,-40
    sw $ra,36($sp)
    sw $s0,0($sp)
    sw $s1,4($sp)
    sw $s2,8($sp)
    sw $s3,12($sp)
    sw $s4,16($sp)
    sw $s5,20($sp)
    sw $s6,24($sp)
    sw $s7,28($sp)

# a0=accepted word count. Call only after game logic confirms all 12 used.
# Radius in logical pixels: 2=20,3=18,4=16,5=14,6=12,7+=10.
# 0/1 words use the 2-word style as an explicit fallback.
addiu $s0,$a0,-2
bgez $s0,starNonnegative
nop
li $s0,0
starNonnegative:
ble $s0,5,starIndexReady
nop
li $s0,5
starIndexReady:
sll $s0,$s0,2
la $t0,starColors
addu $t0,$t0,$s0
lw $s6,0($t0)
la $t0,starSizes
addu $t0,$t0,$s0
lw $s7,0($t0)
# Filled 5-point star: draw radial strokes along the ten boundary edges.
li $s0,0
starEdge:
addiu $t0,$s0,1
li $t1,10
rem $t0,$t0,$t1
sll $t0,$t0,2
sll $t1,$s0,2
la $t2,starX
addu $t3,$t2,$t1
lw $s1,0($t3)
addu $t3,$t2,$t0
lw $s3,0($t3)
la $t2,starY
addu $t3,$t2,$t1
lw $s2,0($t3)
addu $t3,$t2,$t0
lw $s4,0($t3)
# Scale to requested radius.
mul $s1,$s1,$s7
mul $s2,$s2,$s7
mul $s3,$s3,$s7
mul $s4,$s4,$s7
li $t0,100
div $s1,$s1,$t0
div $s2,$s2,$t0
div $s3,$s3,$t0
div $s4,$s4,$t0
# Fill radial strokes to every point on this boundary edge (100 samples).
li $s5,0
starSample:
subu $t0,$s3,$s1
mul $t0,$t0,$s5
li $t2,100
div $t0,$t0,$t2
addu $a2,$t0,$s1
addiu $a2,$a2,256
subu $t1,$s4,$s2
mul $t1,$t1,$s5
div $t1,$t1,$t2
addu $a3,$t1,$s2
addiu $a3,$a3,240
li $a0,256
li $a1,240
sw $s6,drawColor
sw $zero,lineDashed
jal drawLine
nop
addiu $s5,$s5,1
ble $s5,100,starSample
nop
addiu $s0,$s0,1
blt $s0,10,starEdge
nop

lw $s0,0($sp)
    lw $s1,4($sp)
    lw $s2,8($sp)
    lw $s3,12($sp)
    lw $s4,16($sp)
    lw $s5,20($sp)
    lw $s6,24($sp)
    lw $s7,28($sp)
    lw $ra,36($sp)
    addiu $sp,$sp,40
    jr $ra
    nop

