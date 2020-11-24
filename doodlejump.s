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
  doodler_x: .word 0                          # Doodler's position x, ie from left of screen
  doodler_y: .word 0                          # Doodler's position y, ie from top of screen
  doodler_size: .word 3                       # Doodler's height/width, keeping him square makes life much easier 

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

#CORE LOOP
core:
  #Check Keyboard inputs
  #Update Doodler Position
  #Check Collisions (Doodler, screen)
  #Check Collisions (Doodler, platforms)
  #Update positions of objects
  #Redraw Screen
  jal draw_background
  jal draw_doodler
  #Sleep
#TERMINATION
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
  la $t1, col_doodler          # $t1 stores the address storing the doodler colour
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
 
