## Letter Boxed Project
# Authors: Connor Burley, Eadan Lachover, Riggs McLeod, Elise Morhack

# What is Letter Boxed?
  The board is a square with 12 letters, 3 on each side
  You build words from those letters, and each word must be at least 3 letters and at most 15 letters
  You can't use consecutive letters or letters from the same side of the box
  The 12 letters have to be 12 distinct letters made from two words that, together, could solve the Letter Boxed
  The last letter of the word we just entered is the first letter of the next word we enter; we'll call this our connecting letter
  There is a bar upon which the letters are built, and above the bar and letters, we will have "ENTER A WORD"
  There are dashed lines between letters in the word we're building
  There are full lines between letters in words we've made
  If the word the user made does not exist, we will flash a box for three seconds that gives the failure case

# How Would We Implement It?
  4 char arrays of size 3; no overlap between arrays and no repeating letters
  Each letter should be given a weight so we can find par
  We need to import a dictionary of all the standard Scrabble words.
  From this dictionary, we should find two words in which the Letter Boxed could be won
    We could use a random operator for this-- all words with length 8-13
    They can have letters that repeat both in them and between them
    Their letters must meet the standard rules of Letter Boxed of being able to make a string to a different side
    These words would be the most important part of the game, since we would need to find them to make a correct Letter Boxed game
  The program has to keep track of which letters sit on which side, which letters have been used so far, the words we've entered so far, the last connecting letter (last letter of the most recent word), and the word count
  On each turn, the board is shown, we read a word or letter from the player, we check the length, letters on the board, that there are no same-side neighbors, that it starts with the previous word's last letter, and is in the dictionary
  Failure Cases:
    Too short: *word* "IS TOO SHORT"
    Too long: *word* "IS TOO LONG"
    Invalid word: *word* "IS NOT VALID"
  If the word passes, update the state and indicate the connecting letter of this word would not make the box full
  We would need to have a win condition, and if we did not win yet, repeat
  The hard parts in MIPS:
    Representing the board and mapping letters to sides
    Tracking used letters: there are only 12, so we could use some register to check if we've won yet 
    Using the input: which syscall reads a string, and what do we know about the trailing newline?
    Procedures: which checks become their own procedures; what go in $a registers vs $v registers

# Different Colors:
  Background color: #007fff (azure)
  Lines Inside Box and Circles Around Letters with Strings: #0075ec (electric blue)
  Letter, Outside of Box, Circles Around Letters without Strings: #3C4142 (charcoal grey)
  Word Building and bar Under Built Word: #000000 (black)
  Showing Words We've Built: #FF7F00 (orange) for non-connecting letters and #FFA500 (vibrant orange) for the connecting letter
  Command list: #00FF01 (chartreuse) for words and #FFFFFF (white) for outlining the list 
  TRY TO SOLVE IN *par* WORDS: #C71585 (medium violet-red)
  Initial color of the letters: #FFFFFF (white)
  Used letters or letter with line going to it: #000000 (white)
  Failure box: letters in #FFFFFF and background in #000000

# Command List (Needed since you can't touch anything on Bitmap Display):
  Restart = “RR”
  Delete = “XX”
  Enter = “EE”
  Top Row: W
  Left Row: A
  Bottom Row: S
  Right Row: D
  Left or Top Char of the Row: J
  Middle Char of the Row: K
  Right or Bottom Char of the Row: L

We give the player a star after the box is fully made
  7 or more guesses– #777B7E (grey); size 10
  6 guesses– #EFFD5F (lemon); size 12
  5 guesses– #FEE12B (pineapple); size 14
  4 guesses– #FFD300 (cyber); size 16
  3 guesses– #FFDA03 (sunflower); size 18
  2 guesses– #FFF200 (yellow); size 20

Audio:
  We could make a sound for finishing the game and deleting connections
  Happy Wheels victory sound for a full box
  Pluck sound effect for deleting or restarting
    

