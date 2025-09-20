.data
.align 2
	array_dealerCards:		.space 40	# Space to store dealer's cards
	array_playerCards:		.space 40	# Space to store player's cards
	
	text_BlackJack: 		.asciiz "\n**** BlackJack in MIPS ****"
	text_choices:			.asciiz "\nPress Hit(1) or Stay(2): "
	
	text_dealerCards:		.asciiz "\nDealer's Cards: "
	text_dealerCardsScore:	.asciiz "\nDealer's Score: "
	text_dealerWins:		.asciiz "\n**** Dealer has won!!! ****\n"
	text_dealer_blackjack:	.asciiz "\nBLACKJACK! Dealer wins!\n"

	text_playerCards:		.asciiz "\nPlayer's Cards: "
	text_playerCardsScore:	.asciiz "\nPlayer's Score: "
	text_playerWins:		.asciiz "\n**** Player Has Won!!! ****\n"
	text_player_blackjack:	.asciiz "\nBLACKJACK! Player wins!\n"

	text_hideCard:			.asciiz " *"
	text_hideScore:			.asciiz "**"
	text_space:		  	  	.asciiz " "
	text_newLine:			.asciiz "\n"
	
	text_bust:		  	  	.asciiz "\nBust, You've Exceeded 21 points\n"
	text_tie:		   		.asciiz "\nDraw, Both the Player and Dealer are tied.\n"
	text_push:				.asciiz "\nPush! Both have Blackjack.\n"
	
.text
.globl main

main:
	# --- Function Prologue ---
	addi $sp, $sp, -4
	sw $ra, 0($sp)

	la $a0, text_BlackJack
	li $v0, 4
	syscall						# Print text_BlackJack
	
	# Initialize game state registers
	li $s0, 0					# Dealer's card counter
	li $s1, 0					# Player's card counter
	li $s2, 0					# Dealer's score
	li $s3, 0					# Player's score

# --- Initial Dealing Phase ---

# Deal 2 cards to the Dealer
	li $a0, 2					# Arg0: Number of cards to draw
	la $a1, array_dealerCards	# Arg1: Address to store cards
	jal function_generateCards
	add $s0, $s0, $v0			# Update Dealer's card counter

# Deal 2 cards to the Player
	li $a0, 2					# Arg0: Number of cards to draw
	la $a1, array_playerCards	# Arg1: Address to store cards
	jal function_generateCards
	add $s1, $s1, $v0			# Update Player's card counter

# --- Calculate Initial Scores ---
	la $a0, array_dealerCards
	move $a1, $s0
	jal function_calculateValue
	move $s2, $v0				# Store Dealer's total score in $s2

	la $a0, array_playerCards
	move $a1, $s1
	jal function_calculateValue
	move $s3, $v0				# Store Player's score in $s3

# --- Display Initial Hands (Dealer's card hidden) ---
	la $a0, text_dealerCards
	li $v0, 4
	syscall				
		la $a0, array_dealerCards 
		lw $a0, 0($a0)    
		li $v0, 1
		syscall			  
		la $a0, text_hideCard
		li $v0, 4
		syscall			  
			
	la $a0, text_dealerCardsScore
	li $v0, 4
	syscall				    
		la $a0, text_hideScore		
		li $v0, 4
		syscall			    

	la $a0, text_playerCards
	li $v0, 4
	syscall				    
		la $a0, text_space      
		move $a1, $s1           
		la $a2, array_playerCards 
		jal function_printCards	
	
	la $a0, text_playerCardsScore
	li $v0, 4
	syscall				    
		move $a0, $s3       
		li $v0, 1
		syscall 		    

# --- Check for Natural Blackjack (21 on first two cards) ---
	li $t0, 21
	beq $s3, $t0, function_check_dealer_blackjack_on_player_21
	beq $s2, $t0, function_dealer_has_blackjack_win # Player doesn't have BlackJack, but maybe dealer does
	j function_playerBegins # Neither has blackjack, proceed to player's turn

function_check_dealer_blackjack_on_player_21: # Player has 21, check if dealer also has 21 for a push
	beq $s2, $t0, blackjack_push_tie
	# Player has BlackJack, dealer does not. Player wins.
	jal function_display_final_hands
	la $a0, text_player_blackjack
	li $v0, 4
	syscall
	j function_exit_program

function_dealer_has_blackjack_win: # Dealer has 21, player does not. Dealer wins.
	jal function_display_final_hands
	la $a0, text_dealer_blackjack
	li $v0, 4
	syscall
	j function_exit_program

blackjack_push_tie: # Both have 21. It's a tie (push).
	jal function_display_final_hands
	la $a0, text_push
	li $v0, 4
	syscall
	j function_exit_program

# --- Player's Turn ---
function_playerBegins:
function_playerDrawCards_loop:
	# Get player's choice: Hit or Stay
	la $a0, text_choices
	jal function_getPlayerChoice	# $v0 will contain player's choice (1 for Hit, 2 for Stay)
	
	beq $v0, 2, function_player_stays_dealer_turn   # Player stays (2), proceed to dealer's turn

	# Player chose to Hit (1)
	li $a0, 1				# Arg0: Draw 1 card
	la $a1, array_playerCards	
	mul $t7, $s1, 4			
	add $a1, $a1, $t7		
	jal function_generateCards	
	add $s1, $s1, $v0		# Update player's card counter $s1
	
	# Display player's cards
	la $a0, text_playerCards
	li $v0, 4
	syscall				    
		la $a0, text_space      
		move $a1, $s1           
		la $a2, array_playerCards 
		jal function_printCards	
	
	# Calculate and display player's score
	la $a0, array_playerCards
	move $a1, $s1			
	jal function_calculateValue	
	move $s3, $v0			
	
	la $a0, text_playerCardsScore
	li $v0, 4
	syscall				    
		move $a0, $s3       
		li $v0, 1
		syscall 		    
	
	bgt $s3, 21, function_player_bust_ends_game	# Jump to bust if player's score exceeds 21
	j function_playerDrawCards_loop # Go back for next choice

# --- Dealer's Turn ---
function_player_stays_dealer_turn:
    jal function_dealerPlays    
    j function_determine_winner

function_dealerPlays:
    addi $sp, $sp, -4       
    sw $ra, 0($sp)          

    la $a0, text_newLine    
	li $v0, 4
    syscall

dealer_play_loop_in_function_dealerPlays:
    # Display dealer's current hand and score (reveals hole card)
    la $a0, text_dealerCards
    li $v0, 4
    syscall
        la $a0, text_space      
        la $a2, array_dealerCards 
        move $a1, $s0           
        jal function_printCards

    la $a0, text_dealerCardsScore
    li $v0, 4
    syscall
        move $a0, $s2           
        li $v0, 1
        syscall
    la $a0, text_newLine
	li $v0, 4
    syscall

    # Dealer rule: Hit until hand total is 17 or more
    bge $s2, 17, dealer_turn_ends_in_function_dealerPlays 

    # Dealer hits
    li $a0, 1                   
    la $a1, array_dealerCards
    mul $t7, $s0, 4             
    add $a1, $a1, $t7           

    jal function_generateCards      
    add $s0, $s0, $v0           

    # Recalculate dealer's score
    la $a0, array_dealerCards
    move $a1, $s0               
    jal function_calculateValue
    move $s2, $v0               

    j dealer_play_loop_in_function_dealerPlays 

dealer_turn_ends_in_function_dealerPlays:
    lw $ra, 0($sp)          
    addi $sp, $sp, 4        
    jr $ra

# --- Game End Logic ---
function_display_final_hands:
    addi $sp, $sp, -4       
    sw $ra, 0($sp)          

    la $a0, text_newLine
	li $v0, 4
    syscall
 	la $a0, text_BlackJack
	li $v0, 4
    syscall

    la $a0, text_dealerCards
	li $v0, 4
    syscall
		la $a0, text_space
        move $a1, $s0       
        la $a2, array_dealerCards
		jal function_printCards	
	la $a0, text_dealerCardsScore
	li $v0, 4
    syscall
		move $a0, $s2		
		li $v0, 1
        syscall
    la $a0, text_newLine
	li $v0, 4
    syscall

 	la $a0, text_playerCards
	li $v0, 4
    syscall
		la $a0, text_space
        move $a1, $s1       
        la $a2, array_playerCards
		jal function_printCards
	la $a0, text_playerCardsScore
	li $v0, 4
    syscall
		move $a0, $s3       
		li $v0, 1
        syscall
    la $a0, text_newLine
	li $v0, 4
    syscall

    lw $ra, 0($sp)          
    addi $sp, $sp, 4        
    jr $ra

function_player_bust_ends_game:
    jal function_display_final_hands  
    la $a0, text_bust
    li $v0, 4
    syscall
    la $a0, text_dealerWins 
    li $v0, 4
    syscall
    j function_exit_program

function_determine_winner:
    jal function_display_final_hands  

    bgt $s2, 21, label_dealer_busts_player_wins 
    bgt $s2, $s3, label_dealer_wins_no_bust 
    blt $s2, $s3, label_player_wins_no_bust 
    beq $s2, $s3, label_tie_game            

label_dealer_busts_player_wins: 
    j label_player_wins_no_bust 

label_dealer_wins_no_bust:	
    la $a0, text_dealerWins
    li $v0, 4
    syscall
    j function_exit_program
	
label_player_wins_no_bust:	
    la $a0, text_playerWins
    li $v0, 4
    syscall
    j function_exit_program

label_tie_game:
    la $a0, text_tie
    li $v0, 4
    syscall
    j function_exit_program

function_exit_program:
	# --- Function Epilogue for main ---
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	li $v0, 10
	syscall

# --- Helper Functions ---

function_generateCards:
	move $t0, $a0		
	move $t1, $a1		
	li $t3, 0		
	
function_generateCards_loop:
	beq $t3, $t0, function_generateCards_end	
	li $a1, 10		
	li $v0, 42      
	syscall
	addi $a0, $a0, 1 	
	sw $a0, ($t1)		
	addi $t1, $t1, 4	
	addi $t3, $t3, 1	
	j function_generateCards_loop
	
function_generateCards_end:
	move $v0, $t3       
	jr $ra
	
function_printCards:
	li $t2, 1 			
	move $t4, $a0       
	
function_printCards_loop:
	lw $t1, ($a2)		
	move $a0, $t1       
	li $v0, 1
	syscall			    
	beq $a1, $t2, function_printCards_end	
	move $a0, $t4       
	li $v0, 4
	syscall			    
	addi $t2, $t2, 1	
	addi $a2, $a2, 4	
	j function_printCards_loop
		 
function_printCards_end:
	jr $ra

function_calculateValue:
	# a0: array of cards
	# a1: number of cards
	li $t2, 0			# Total value of cards
	li $t3, 0			# Ace counter
	li $t4, 0			# Loop counter
	move $t5, $a0		# Temp register for array address
	
# First pass: Sum non-Aces and count the number of Aces.
function_calculateValue_loop:
	beq $t4, $a1, add_aces_to_total # If all cards processed, go to handle aces
	lw $a2, ($t5)		# a2 = current card value
	
	beq $a2, 1, function_sumAce   # If card is an Ace (1), go to count it
	
	# Card is not an ace
	add $t2, $t2, $a2	# Add card value to total
	j common_card_increment
	
function_sumAce:
	addi $t3, $t3, 1	# Increment ace counter
	
common_card_increment:
	addi $t5, $t5, 4	# Move to next card in array
	addi $t4, $t4, 1	# Increment loop counter
	j function_calculateValue_loop

# Second pass: Add the counted Aces to the total, valuing them as 11 or 1.
add_aces_to_total:
	beq $t3, 0, function_calculateValue_end # If no aces, we are done
	
	addi $t3, $t3, -1	# "Use" one ace from the counter
	add $t2, $t2, 11	# Try adding it as 11
	
	# If total > 21, the Ace must be valued at 1 instead of 11.
	bgt $t2, 21, function_subtractTen 
	
	j add_aces_to_total	# Otherwise, try adding the next ace as 11
	
function_subtractTen:
	sub $t2, $t2, 10	# Convert the 11 to a 1 by subtracting 10
	j add_aces_to_total	# Add the next ace
	
function_calculateValue_end:
	move $v0, $t2		# Return total score in $v0
	jr $ra

function_getPlayerChoice:
function_getPlayerChoice_loop:
	li $v0, 4		
	syscall
	li $v0, 5		
	syscall
	beq $v0, 1, function_getPlayerChoice_end 
	beq $v0, 2, function_getPlayerChoice_end 
	j function_getPlayerChoice_loop

function_getPlayerChoice_end:
	jr $ra