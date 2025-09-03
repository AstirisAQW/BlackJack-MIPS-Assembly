# BlackJack-in-MIPS
CS222 - Computer Architecture and Organization

University of Science & Technology of Southern Philippines

# Project Description
Developed a simplified, single-player Blackjack game against a computer-controlled dealer using MIPS assembly language, demonstrating low-level programming and computer architecture concepts.

The core gameplay and features include:

1.  **Initial Deal:**
    *   The dealer receives two cards, with one card shown and one card hidden to the player.
    *   The player receives two cards, both face up.

2.  **Card Generation:**
    *   Cards are randomly generated with values from 1 to 10.
    *   An Ace (generated as '1') can be valued as 11 or 1, whichever is more beneficial to the hand without busting (exceeding 21). Cards 2-9 are their face value. Cards generated as '10' represent 10, Jack, Queen, or King.

3.  **Score Calculation:**
    *   The program calculates and displays the current score for the player after each card draw.
    *   The dealer's score is initially partially hidden (only the value of the face-up card is implicitly known to the player, and the total score is displayed as "**").

4.  **Player's Turn:**
    *   The player can either "Hit" (draw another card) or "Stay" (keep their current hand).
    *   If the player chooses to "Hit", another card is dealt to the players hand, and their score is updated.
    *   If the player's score exceeds 21 (a "Bust"), the player automatically loses, and the game ends.
    *   The player can continue to "Hit" until they choose to "Stay" or "Bust".

5.  **Dealer's Turn:**
    *   If the player chooses to "Stay" (and has not busted), the dealer's turn begins.
    *   The dealer's hidden card is revealed, and their full initial score is displayed.
    *   **The dealer must draw cards ("Hit") until their hand total is 17 or higher.**
    *   If the dealer's score is 16 or less, they will draw another card.
    *   The dealer continues to hit until their hand total reaches 17 or more.
    *   If the dealer's score exceeds 21 (a "Bust") while hitting, the dealer loses (and the player wins, provided the player did not bust earlier).

6.  **Determining the Winner:**
    *   After both the player and dealer have completed their turns (player Stays or Busts, dealer reaches 17+ or Busts):
        *   If the player busted, the dealer wins.
        *   If the dealer busted (and the player did not), the player wins.
        *   If neither busted, their scores are compared:
            *   The hand closest to 21 without exceeding it wins.
            *   If both have the same score, the game is a "Tie".

7.  **User Input:**
    *   The program uses MIPS system call `li $v0, 5` followed by `syscall` to read an integer from the user (1 for "Hit", 2 for "Stay").

The purpose of this project is to demonstrate understanding of MIPS assembly programming, including memory management (arrays for cards), procedural programming (functions for dealing, calculating scores, handling turns), conditional logic, and basic I/O operations.

# How to Run
1.  Assemble the `.asm` file using a MIPS assembler (e.g., MARS - MIPS Assembler and Runtime Simulator).
2.  Run the assembled code.
3.  Follow the on-screen prompts to play the game.

# Credits
AstirisAQW - https://github.com/AstirisAQW

HarV1821 - https://github.com/HarV1821