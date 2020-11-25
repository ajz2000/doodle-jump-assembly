.data
# Bitmap Display Configuration:
# - Unit width in pixels: 8					     
# - Unit height in pixels: 8
# - Display width in pixels: 256
# - Display height in pixels: 256
# - Base Address for Display: 0x10008000 ($gp)
# - Functional screen size: 32x32
	display_address:	.word	0x10008000          # The base address for the display
  col_doodler:  .word 0xEBD234                 # The colour of the doodler
  col_platform: .word 0x3feb36                # The colour of the platforms
  col_background: .word 0x9df2eb              # The colour of the background
  screen_height:  .word 32                    # Height of the screen in pixels
  screen_width:   .word 32                    # Width of the screen in pixels
  screen_total_pixels: .word 0                # Total number of pixels on screen, calulated at initialization

  #This will be from top left corner of screen
  #And refer to the top left corner of the doodler
  doodler_x: .word 15                          # Doodler's position x, ie from left of screen
  doodler_y: .word 15                          # Doodler's position y, ie from top of screen
  doodler_size: .word 3                        # Doodler's height/width, keeping him square makes life much easier 
  doodler_jump_height: .word 25
  doodler_current_jump: .word 10

.globl main
.text
main: 

init:                            #PROGRAM INITIALIZATION
  la $t0, screen_width           # $t0 stores the address storing the screen width
  lw $t0, ($t0)	                 # $t0 stores the screen width
  la $t1, screen_height          # $t1 stores the address storing the screen height
  lw $t1, ($t1)	                 # $t1 stores the screen height
  mult $t0, $t1                  # Multiply screen width x height
  mflo $t0                       # $t0 stores result of screen width x height
  la $t1, screen_total_pixels    # $t1 stores the address storing the total # of pixels
  sw $t0, 0($t1)                 # Store the total # of pixels on screen in screen_total_pixels in memory
  jal draw_background            # Draw the full background once
#CORE LOOP
core:
  #First Screen Draw
  la $a0, col_background            #Load the background colour to first param of draw_doodler
  jal draw_doodler                  #Call draw_doodler
check_keyboard_input:               # Check for keyboard inputs  
  lw $t0, 0xffff0000                # $t0 gets the value indicating keyboard input
  beq $t0, 0, end_keyboard_input    # $if no keyboard input, skip handler
keyboard_input:                     # Keyboard input branch handler
  lw $t0, 0xffff0004                # $t0 gets ascii value of entered key
  beq $t0, 0x6A, respond_to_j       # if keyboard input j, respond_to_j
  beq $t0, 0x6B, respond_to_k       # if keyboard input k, respond_to_k
  j end_keyboard_input              # if input that doesn't do anything, jump to end of keyboard input handling
respond_to_j:                       # Move Doodler left
  la $t0, doodler_x                 # $t0 stores the doodler x pos memory location
  lw $t1 ($t0)                      # $t1 stores the doodler x pos
  addi $t1, $t1, -1                 # $t1 stores update (-1) doodler x pos 
  j doodler_screen_wrap
respond_to_k:                       # Move Doodler right
  la $t0, doodler_x                 # $t0 stores the doodler x pos memory location
  lw $t1 ($t0)                      # $t1 stores the doodler x pos
  addi $t1, $t1, 1                  # $t1 stores update (+1) doodler x pos 
  j doodler_screen_wrap
doodler_screen_wrap:
  li $t2, 31                        # $t2 gets 31
  and $t1, $t1, $t2                 # $t1 gets doodler's new position mod 32 (Wrap!) NEEDS TO CHANGE IF SCREEN SIZE CHANGES
  sw $t1, ($t0)                     # Save the doodler's updated x position to memory  
  j end_keyboard_input
end_keyboard_input:

  #Check Collisions (Doodler, screen)
  #TEMP REMOVE
  #TEMP REMOVE
  #TEMP REMOVE
  #TEMP REMOVE
  #Make doodler jump if he hits bottom of screen
  la $t0, doodler_y                 # $t0 stores the doodler y pos memory location
  lw $t0 ($t0)                      # $t0 stores the doodler y pos
  la $t1, screen_height             # $t1 stores the screen height memory location
  lw $t1 ($t1)                      # $t1 stores the screen height
  blt $t0, $t1, doodler_trigger_jump_end
  doodler_trigger_jump:
  la $t2, doodler_jump_height       # $t2 stores the doodler's max jump height address
  lw $t2 ($t2)                      # $t2 stores the doodler's max jump height
  la $t3, doodler_current_jump      # $t3 stores the doodler's cur jump height address
  lw $t4 ($t3)                      # $t4 stores the doodler's cur jump height
  move $t4, $t2
  sw $t4, ($t3)
  doodler_trigger_jump_end:
  #TEMP REMOVE
  #TEMP REMOVE
  #TEMP REMOVE
  #TEMP REMOVE

  #Check Collisions (Doodler, platforms)
  #Update positions of objects
  la $t0, screen_height                 # $t0 stores the doodler y pos memory location
  lw $t1 ($t0)                      # $t1 stores the doodler y pos

  #Update doodler height
  la $t0, doodler_y                 # $t0 stores the doodler y pos memory location
  lw $t1 ($t0)                      # $t1 stores the doodler y pos
#  la $t2, doodler_jump_height       # $t2 stores the doodler's max jump height address
#  lw $t2 ($t2)                      # $t2 stores the doodler's max jump height
  la $t3, doodler_current_jump      # $t3 stores the doodler's cur jump height address
  lw $t4 ($t3)                      # $t4 stores the doodler's cur jump height
  bgtz $t4, doodler_rise
doodler_fall:
  addi $t1, $t1, 1                  # Move the doodler down 1 unit
  sw $t1, ($t0)                     # Save the doodler's updated y position to memory 
  j doodler_y_end 
doodler_rise:
  addi $t1, $t1, -1                  # Move the doodler up 1 unit
  sw $t1, ($t0)                     # Save the doodler's updated y position to memory 
  j doodler_y_end
doodler_y_end:
  addi $t4, $t4, -1
  sw $t4, ($t3)

  #Redraw Screen
  la $a0, col_doodler
  jal draw_doodler
  #Sleep
  li $v0, 32
  li $a0, 30
  syscall

  j core
#TERMINATION
gameover:
exit:
  li $v0, 10            # prepare syscall to terminate the program
	syscall               # Syscall to terminate the program

#FUNCTIONS

draw_background:               # Draws the filled out-colour background of the screen
####################################################################################################
  lw $t0, display_address	     # $t0 stores the base address for display
  la $t1, col_background       # $t1 stores the address storing the background colour
  lw $t1, ($t1)	               # $t1 stores the background colour
  la $t2, screen_total_pixels  # $t2 stores the address storing the total number of pixels onscreen
  lw $t2, ($t2)	               # $t2 stores the total number of pixels onscreen
  sll $t2, $t2, 2              # $t2 stores # pixels * 4
loopinit:
  add $t2, $t0, $t2            # $t2 stores the memory adress we see when we want to stop the loop
while:
  beq	$t0, $t2, end	           # if $t0 == $t2 then jump to end 
  sw $t1, 0($t0)               # write background colour to pixel
  addi $t0, $t0 4              # $t0 increments by 4, ie move to next pixel
  j while
end:  
  jr $ra                       # Exit Function


 
draw_doodler:                  # Draws the doodler at the x,y position stored in memory
####################################################################################################
  lw $t0, display_address	     # $t0 stores the base address for display
  move $t1, $a0          # $t1 stores the address storing the doodler colour
  lw $t1, ($t1)	               # $t1 stores the doodler colour
  la $t2, doodler_x           
  lw $t2 ($t2)                 # $t2 stores the doodler x pos
#  sll $t2, $t2, 2              # $t2 stores doodler x pos * 4
  la $t3, doodler_y           
  lw $t3, ($t3)                # $t3 stores the doodler y pos
  la $t4, screen_width         # $t4 stores the address storing the screen width
  lw $t4, ($t4)	               # $t4 stores the screen width

  #Draw doodler's head
  mult $t3, $t4
  mflo $t5
  add $t5, $t5, $t2            # $t5 stores the pixel offset from origin of doodler
  sll $t5, $t5, 2              # $t5 stores the equivalent offset in memory ie pixel offset * 4
  add $t0, $t0, $t5
  sw $t1, 4($t0)               # write doodler colour to pixel
  #Draw doodler's body
  move 	$t5, $t4		           # $t5 = t4
  sll $t5, $t5, 2
  add $t0, $t0, $t5            # $t5
  sw $t1, 0($t0)               # write doodler colour to pixel
  sw $t1, 4($t0)               # write doodler colour to pixel
  sw $t1, 8($t0)               # write doodler colour to pixel
  #Draw doodler's feet
  add $t0, $t0, $t5
  sw $t1, 0($t0)               # write doodler colour to pixel
  sw $t1, 8($t0)              # write doodler colour to pixel
  jr $ra
 
