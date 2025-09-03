.data
.align 2
	array_dealerCards:	.space 40	# Space to store dealer's cards
	array_playerCards:	.space 40	# Space to store player's cards
	
	text_BlackJack: 	.asciiz "\n**** BlackJack in MIPS ****"
	text_choices:		.asciiz "\nPress Hit(1) or Stay(2): "
	
	text_dealerCards:	.asciiz "\nDealer's Cards: "
	text_dealerCardsScore:	.asciiz "\nDealer's Score: "
	text_dealerWins:	.asciiz "\n**** Dealer has won!!! ****\n"
	
	text_playerCards:	.asciiz "\nPlayer's Cards: "
	text_playerCardsScore:	.asciiz "\nPlayer's Score: "
	text_playerWins:	.asciiz "\n**** Player Has Won!!! ****\n"
	
	text_hideCard:		.asciiz " *"
	text_hideScore:		.asciiz "**"
	text_space:		    .asciiz " "
	text_newLine:		.asciiz "\n"
	
	text_bust:		    .asciiz "\nBust, You've Exceeded 21 points\n"
	text_tie:		    .asciiz "\nDraw, Both the Player and Dealer are tied.\n"
	
.text
.globl main

main:
	la $a0, text_BlackJack
	li $v0, 4
	syscall					# Print text_BlackJack
	
	# Initialize game state registers
	# $s0: dealer_card_count, $s1: player_card_count
	# $s2: dealer_score, $s3: player_score
	li $s0, 0				# Dealer's card counter
	li $s1, 0				# Player's card counter
	li $s2, 0				# Dealer's score
	li $s3, 0				# Player's score

	li $a0, 1				# Parameter for function_dealerDrawsCards: will be incremented to 2 for initial 2-card deal
	
# Initial dealing phase for the dealer (2 cards, one hidden)
function_dealerDrawsCards:
	addi $a0, $a0, 1		# For initial deal, $a0 becomes 2 (draw 2 cards for dealer)
	la $a1, array_dealerCards	
	mul $t7, $s0, 4			# Use $s0 (dealer_card_count) for memory offset
	add $a1, $a1, $t7		# Update memory address for the next card
	
	jal function_generateCards	# Generate and store the cards ($v0 = number of cards generated)
	add $s0, $s0, $v0		# Update Dealer's card counter $s0
	
	# Display one dealer card and a hidden card marker
	la $a0, text_dealerCards
	li $v0, 4
	syscall				# Print text_dealerCards
		la $a0, array_dealerCards # Get address of dealer's card array
		lw $a0, 0($a0)    # Load value of the first card into $a0
		li $v0, 1
		syscall			  # Print the first card
		la $a0, text_hideCard
		li $v0, 4
		syscall			  # Print " *" to hide the second card
			
	# Calculate dealer's score but keep it hidden for now
	la $a0, array_dealerCards
	move $a1, $s0			# Pass dealer card counter $s0 to function_calculateValue
	jal function_calculateValue	# Calculate Dealer's score (of both cards)
	move $s2, $v0			# Store Dealer's total score in $s2 (hidden from player)
	
	la $a0, text_dealerCardsScore
	li $v0, 4
	syscall				    # Print text_dealerCardsScore
		la $a0, text_hideScore		
		li $v0, 4
		syscall			    # Prints "**" to hide score
				
# Player's turn begins
function_playerBegins:
	li $a0, 1               # Parameter for drawing cards (will be incremented to 2 for initial player deal)
	# $s1 (player_card_counter) is 0 from main.
	
function_playerDrawCards_loop:
	addi $a0, $a0, 1		# For initial deal, $a0 becomes 2. For hits, $a0 becomes 1 (as it's reset to 0 before loop).
	la $a1, array_playerCards	
	mul $t7, $s1, 4			# Calculate offset using player card counter $s1
	add $a1, $a1, $t7		# Update memory address for the next card
	# $a2 (text_space) is not directly used by generateCards, but good to note for printCards
	
	jal function_generateCards	# Generate and store the cards ($v0 = number of cards generated)
	
	add $s1, $s1, $v0		# Update player's card counter $s1
	
	# Display player's cards
	la $a0, text_playerCards
	li $v0, 4
	syscall				    # Print text_playerCards
		la $a0, text_space      # Arg0 for printCards
		move $a1, $s1           # Arg1 for printCards (player card count)
		la $a2, array_playerCards # Arg2 for printCards
		jal function_printCards	# Print Player's cards
	
	# Calculate and display player's score
	la $a0, array_playerCards
	move $a1, $s1			# Pass player card counter $s1 to function_calculateValue
	jal function_calculateValue	# Calculate Player's score
	
	move $s3, $v0			# Store Player's score in $s3
	
	la $a0, text_playerCardsScore
	li $v0, 4
	syscall				    # Print text_playerCardsScore
		move $a0, $s3       # Player's score from $s3
		li $v0, 1
		syscall 		    # Print Player's score
	
	bgt $s3, 21, function_player_bust_ends_game	# Jump to bust if player's score exceeds 21
	
	# Get player's choice: Hit or Stay
	la $a0, text_choices
	jal function_getPlayerChoice	# $v0 will contain player's choice (1 for Hit, 2 for Stay)
	
	move $t4, $v0           # Store choice in $t4
	li $a0, 0			    # Reset $a0 to 0, so next 'addi $a0, $a0, 1' makes $a0=1 for a hit
		
	beq $t4, 1, function_playerDrawCards_loop	    # Loop if player chooses to Hit
	beq $t4, 2, function_player_stays_dealer_turn   # Player stays, proceed to dealer's turn

# Player chose to stay. Dealer's turn begins.
function_player_stays_dealer_turn:
    jal function_dealerPlays    # Execute dealer's playing logic
    j function_determine_winner # After dealer plays, determine the winner

# Dealer's playing logic
function_dealerPlays:
    addi $sp, $sp, -4       # Allocate space on stack for $ra
    sw $ra, 0($sp)          # Save $ra

    la $a0, text_newLine    # Announce Dealer's turn
	li $v0, 4
    syscall
    # Optional: print "Dealer's turn..." message here

dealer_play_loop_in_function_dealerPlays:
    # Display dealer's current hand and score (reveals hole card)
    la $a0, text_dealerCards
    li $v0, 4
    syscall
        la $a0, text_space      # Arg0 for printCards
        la $a2, array_dealerCards # Arg2 for printCards
        move $a1, $s0           # Arg1 for printCards (dealer card count $s0)
        jal function_printCards

    la $a0, text_dealerCardsScore
    li $v0, 4
    syscall
        move $a0, $s2           # Dealer's score ($s2)
        li $v0, 1
        syscall
    la $a0, text_newLine
	li $v0, 4
    syscall

    # Dealer rule: Hit until hand total is 17 or more
    bge $s2, 17, dealer_turn_ends_in_function_dealerPlays # If score is 17+ (stand or bust), turn ends

    # Dealer's score is < 17, dealer must hit.
    # Optional: print "Dealer hits." message here

    li $a0, 1                   # Number of cards to generate = 1
    la $a1, array_dealerCards
    mul $t7, $s0, 4             # Offset for the new card using $s0 (current dealer card count)
    add $a1, $a1, $t7           # Address in dealer's card array to store the new card

    jal function_generateCards      # $v0 will return 1 (number of cards generated)

    add $s0, $s0, $v0           # Increment dealer's card count ($s0)

    # Recalculate dealer's score
    la $a0, array_dealerCards
    move $a1, $s0               # Pass updated dealer card count ($s0)
    jal function_calculateValue
    move $s2, $v0               # Update dealer's score in $s2

    j dealer_play_loop_in_function_dealerPlays # Loop to re-evaluate dealer's hand

dealer_turn_ends_in_function_dealerPlays:
    # Dealer's turn is over (stood at >=17 or busted). Final dealer score is in $s2.
    lw $ra, 0($sp)          # Restore $ra
    addi $sp, $sp, 4        # Deallocate stack space
    jr $ra

# Helper function to display final hands and scores of both player and dealer
function_display_final_hands:
    addi $sp, $sp, -4       # Space for $ra
    sw $ra, 0($sp)          # Save $ra

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
        move $a1, $s0       # Dealer's card count $s0
        la $a2, array_dealerCards
		jal function_printCards	
	la $a0, text_dealerCardsScore
	li $v0, 4
    syscall
		move $a0, $s2		# Dealer's score $s2
		li $v0, 1
        syscall
    la $a0, text_newLine
	li $v0, 4
    syscall

 	la $a0, text_playerCards
	li $v0, 4
    syscall
		la $a0, text_space
        move $a1, $s1       # Player's card count $s1
        la $a2, array_playerCards
		jal function_printCards
	la $a0, text_playerCardsScore
	li $v0, 4
    syscall
		move $a0, $s3       # Player's score $s3
		li $v0, 1
        syscall
    la $a0, text_newLine
	li $v0, 4
    syscall

    lw $ra, 0($sp)          # Restore $ra
    addi $sp, $sp, 4        # Deallocate stack space
    jr $ra

# Called when player's score ($s3) exceeds 21
function_player_bust_ends_game:
    addi $sp, $sp, -4       # Save $ra for jal
    sw $ra, 0($sp)
    jal function_display_final_hands  # Display final state (dealer's initial 2 cards will be shown)
    lw $ra, 0($sp)          # Restore $ra
    addi $sp, $sp, 4

    la $a0, text_bust
    li $v0, 4
    syscall
    la $a0, text_dealerWins # If player busts, dealer wins
    li $v0, 4
    syscall
    li $v0, 10
    syscall			# Exit program

# Called after player stays and dealer has played their hand
function_determine_winner:
    addi $sp, $sp, -4       # Save $ra for jal
    sw $ra, 0($sp)
    jal function_display_final_hands  # Display final state of both hands
    lw $ra, 0($sp)          # Restore $ra
    addi $sp, $sp, 4

    # Compare scores: $s2 (Dealer) vs $s3 (Player)
    # Player score $s3 is <= 21 at this point.
    bgt $s2, 21, label_dealer_busts_player_wins # Dealer busted

    # Neither player nor dealer busted.
    bgt $s2, $s3, label_dealer_wins_no_bust # Dealer score > Player score
    blt $s2, $s3, label_player_wins_no_bust # Player score > Dealer score
    beq $s2, $s3, label_tie_game            # Scores are equal

label_dealer_busts_player_wins: # Dealer busted ($s2 > 21), player ($s3 <= 21) wins
    # Optional: Print "Dealer busts!" message here
    j label_player_wins_no_bust # Player wins outcome

label_dealer_wins_no_bust:	
    la $a0, text_dealerWins
    li $v0, 4
    syscall
    li $v0, 10
    syscall		# Exit program
	
label_player_wins_no_bust:	
    la $a0, text_playerWins
    li $v0, 4
    syscall
    li $v0, 10
    syscall		# Exit program

label_tie_game:
    la $a0, text_tie
    li $v0, 4
    syscall
    li $v0, 10
    syscall		# Exit program

# -----------------------------------------------------------------------------
# Provided helper functions from the original problem (assumed correct)
# -----------------------------------------------------------------------------
function_generateCards:
	move $t0, $a0		# a0 is the size of the array, i.e., the number of cards to generate
	move $t1, $a1		# a1 is the memory address of the array
	li $t3, 0		# Generate card counter
	
	function_generateCards_loop:
		beq $t3, $t0, function_generateCards_end	# When the loop repeats the number of times for the cards to generate 
		li $a1, 10		# Initialize the maximum limit for random number. syscall 42 with $a1=X returns $a0 in [0, X-1]
		li $v0, 42      # So $a0 will be in [0,9]
		syscall
	
		addi $a0, $a0, 1 	# Random number becomes [1,10]. (Card '1' is Ace, '10' is 10/J/Q/K)
		sw $a0, ($t1)		# Store the generated card in the array
	
		addi $t1, $t1, 4	# Move to the next position in the array
		addi $t3, $t3, 1	# Increment the card counter
	
		j function_generateCards_loop
	
	function_generateCards_end:
		move $v0, $t3       # Return number of cards generated (equals input $a0 or $t0)
		jr $ra
	
function_printCards:
	# a0 is the string to print a text_space
	# a1 is the size of the array (number of cards to print)
	# a2 is the memory address of the card array
	li $t2, 1 			# Initialize counter for cards printed (1-indexed)
	move $t4, $a0       # Save text_space address from $a0 into $t4
	
	function_printCards_loop:
		lw $t1, ($a2)		# Load the card value from memory into $t1
	
		move $a0, $t1       # Move card value to $a0 for printing
		li $v0, 1
		syscall			    # Print the card value
		
		beq $a1, $t2, function_printCards_end	# If all cards in $a1 are printed, end
		
		move $a0, $t4       # Restore text_space address to $a0
		li $v0, 4
		syscall			    # Print a space between cards
		
		addi $t2, $t2, 1	# Increment cards_printed counter
		addi $a2, $a2, 4	# Move to the next card in the array
		 
		j function_printCards_loop
		 
	function_printCards_end:
		jr $ra

function_calculateValue:
	# a0 is the array containing the cards
	# a1 is the size of the array (number of cards)
	li $t0, 0			# Loop counter (0-indexed for cards processed)
 	li $t2, 0			# Total value of cards
 	
	function_calculateValue_loop:
 		lw $a2, ($a0)					# Load the card value from the array into $a2
 		beq $t0, $a1, function_calculateValue_end	# Exit loop if all cards (count $a1) are processed
 		beq $a2, 1, function_sumAce			# Special handling for Ace (card value 1)
		# Card is not an Ace
 		add $t2, $a2, $t2				# Add card value to total
		# Fall through to common increment part
 		
common_card_increment:
        addi $a0, $a0, 4				# Move to the next card in the array
 		add $t0, $t0, 1					# Increment loop counter
 		j function_calculateValue_loop
 		
 	function_sumAce:
 		addi $t2, $t2, 11			# Initially consider Ace as 11
 		bgt $t2, 21, function_subtractTen	# If total exceeds 21, Ace becomes 1
		# Ace is 11 and total <= 21
 		j common_card_increment         # Go to common increment part
 			
 	function_subtractTen:
 		sub $t2, $t2, 10			# Subtract 10 (11 - 10 = 1) to consider Ace as 1
		# Ace is 1 and total was > 21, now reduced by 10
 		j common_card_increment         # Go to common increment part
 	
 	function_calculateValue_end:
 		move $v0, $t2					# Store the total value in $v0
 		jr $ra

function_getPlayerChoice:
	# Caller sets $a0 to the address of the prompt string (e.g., text_choices)
	function_getPlayerChoice_loop:
		li $v0, 4		# Print the choice string (passed in $a0)
		syscall
	
		li $v0, 5		# Read integer input from the player
		syscall
	
		# $v0 now contains player's input
		beq $v0, 1, function_getPlayerChoice_end # If 1 (Hit), choice is valid
		beq $v0, 2, function_getPlayerChoice_end # If 2 (Stay), choice is valid
		
		# Invalid input, loop again to re-prompt and read input
		# $a0 (prompt string) is still set correctly from the caller for re-printing
		j function_getPlayerChoice_loop

	function_getPlayerChoice_end:
		# Valid choice (1 or 2) is in $v0
		jr $ra