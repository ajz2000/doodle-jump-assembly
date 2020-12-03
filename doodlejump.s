.data
# Bitmap Display Configuration:
# - Unit width in pixels: 8					     
# - Unit height in pixels: 8
# - Display width in pixels: 256
# - Display height in pixels: 256
# - Base Address for Display: 0x10008000 ($gp)
# - Functional screen size: 32x32
	display_address:	.word	0x10008000           # The base address for the display
  col_doodler:  .word 0xEBD234                 # The colour of the doodler
  col_platform: .word 0x3feb36                 # The colour of the platforms
  col_background: .word 0x9df2eb               # The colour of the background
  col_red: .word 0xFF0000
  col_blue: .word 0x0000FF
  screen_height:  .word 32                     # Height of the screen in pixels
  screen_width:   .word 32                     # Width of the screen in pixels
  screen_total_pixels: .word 0                 # Total number of pixels on screen, calculated at initialization

  #This will be from top left corner of screen
  #And refer to the top left corner of the doodler
  doodler_x: .word 15                          # Doodler's position x, ie from left of screen
  doodler_y: .word 30                          # Doodler's position y, ie from top of screen
  doodler_size: .word 3                        # Doodler's height/width, keeping him square makes life much easier 
  doodler_jump_height: .word 25                # Height of the Doodler's jump
  doodler_current_jump: .word 25               # Used for keeping track of the portion of his jump the doodler has completed
  #doodler_current_jump acts like a counter. When a jump starts, it is set to 25, and decrements each frame 
  #each frame, we check if its value is >0, if it is, move the doodler up, if it isn't, move the doodler down
  doodler_has_shield: .word 0

  platform_num: .word 5                        # Number of platforms
  platforms: .word 2,4,10,10,15,20,20,2,25,30           # Position of platforms in (x,y),(x,y),.... form
  platform_width: .word 6                 
  
  screen_refresh: 30
  difficulty_counter: 0

  enemy_x: .word 18
  enemy_y: .word 32
  enemy_size: .word 2

  shield_x: .word 2
  shield_y: .word 32
  shield_size: .word 2

  #Stores the offsets of pixels (multiplied by 4, due to word size) in the "bye!" gameover text
  #-1 is a flag used to signal the rendering function should move to the next line
  #-2 is a flag used to signal the end of the data (basically a null terminator)
  bye_text: .word 0, 16, 24, 32,36,40,48,-1,0,16,20,24,32,40,48,-1,0,4,8,24,32,36,40,48,-1,0,8,24,32,-1,0,4,8,16,20,24,32,36,40,48,-2

.globl main
.text
main: 

init:                               # PROGRAM INITIALIZATION
  # This code block calculates the total number of pixels on screen
  # It's essentially leftover from when I was drawing the entire background every frame, and wanted to only compute this value once
  # It could really be moved into the background drawing method
  la $t0, screen_width              # $t0 stores the address storing the screen width
  lw $t0, ($t0)	                    # $t0 stores the screen width
  la $t1, screen_height             # $t1 stores the address storing the screen height
  lw $t1, ($t1)	                    # $t1 stores the screen height
  mult $t0, $t1                     # Multiply screen width x height
  mflo $t0                          # $t0 stores result of screen width x height
  la $t1, screen_total_pixels       # $t1 stores the address storing the total # of pixels
  sw $t0, 0($t1)                    # Store the total # of pixels on screen in screen_total_pixels in memory
  jal draw_background               # Draw the full background once

core:                               #CORE LOOP
  #First Screen Draw: "Erases" previous positions of objects (Instead of redrawing the entire background)
  la $a0, col_background            # Load the background colour to first param of draw_doodler,draw_platforms.
  jal draw_doodler                  # Call draw_doodler
  jal draw_platforms                # Call draw_platforms
  jal draw_enemy
  jal draw_shield

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
doodler_screen_wrap:                # Wrap the doodler from right to left edge if x position becomes too greate
  li $t2, 31                        # $t2 gets 31
  and $t1, $t1, $t2                 # $t1 gets doodler's new position mod 32 (Wrap!) NEEDS TO CHANGE IF SCREEN SIZE CHANGES
  sw $t1, ($t0)                     # Save the doodler's updated x position to memory  
  j end_keyboard_input
end_keyboard_input:

  #Check Collisions (Doodler, screen)
  la $t0, doodler_y                 # $t0 stores the doodler y pos memory location
  lw $t0 ($t0)                      # $t0 stores the doodler y pos
  la $t1, screen_height             # $t1 stores the screen height memory location
  lw $t1 ($t1)                      # $t1 stores the screen height
  bgt $t0, $t1, gameover            # If doodler's y exceeds screen-height, gameover

  #Check collisions (Doodler, enemy)
  la $t2, enemy_y
  lw $t2 ($t2)
  li $t3, 32
  bgt		$t2, $t3, skip_check_enemy_collision	# if $t2 > 32 then skip check
  check_enemy_collision:
  la, $t1, doodler_x
  lw $t1, ($t1)
  la $t3, enemy_x
  lw $t3, ($t3)
  #$t0: doodler y, $t1, doodler x, $t2, enemy y, $t3 enemy x
  #Check if doodler above, or to the left
  addi $t0, $t0, 3
  addi $t1, $t1, 3
  ble	$t0, $t2, skip_check_enemy_collision
  ble $t1, $t3, skip_check_enemy_collision
  addi $t0, $t0, -3
  addi $t1, $t1, -3
  addi $t2, $t2, 2
  addi $t3, $t3, 2
  bgt $t0, $t2, skip_check_enemy_collision
  bge $t1, $t3, skip_check_enemy_collision
  la $t0, doodler_has_shield
  lw $t1, ($t0)
  bgtz $t1, remove_shield
  j gameover
  remove_shield:
  sw $zero, ($t0)
  la $t0, enemy_y
  li $t1, 32
  sw $t1 ($t0)
  skip_check_enemy_collision:

  #Check collisions (Doodler, shield)
  la $t2, shield_y
  lw $t2 ($t2)
  li $t3, 32
  bgt		$t2, $t3, skip_check_shield_collision	# if $t2 > 32 then skip check
  check_shieldenemy_collision:
  la, $t1, doodler_x
  lw $t1, ($t1)
  la $t3, shield_x
  lw $t3, ($t3)
  #$t0: doodler y, $t1, doodler x, $t2, shield y, $t3 shield x
  #Check if doodler above, or to the left
  addi $t0, $t0, 3
  addi $t1, $t1, 3
  ble	$t0, $t2, skip_check_shield_collision
  ble $t1, $t3, skip_check_shield_collision
  addi $t0, $t0, -3
  addi $t1, $t1, -3
  addi $t2, $t2, 2
  addi $t3, $t3, 2
  bgt $t0, $t2, skip_check_shield_collision
  bge $t1, $t3, skip_check_shield_collision
  la $t0 doodler_has_shield
  li $t1, 1
  sw $t1 ($t0)
  la $t0, shield_y
  li $t1, 32
  sw $t1 ($t0)
  skip_check_shield_collision:

  #Check Collisions (Doodler, platforms)
  la $t0, doodler_x            
  lw $t0, ($t0)                # $t0 gets doodler's x pos
  la $t1, doodler_y             
  lw $t1, ($t1)                # $t1 gets doodler's y pos
  la $t2, platforms            # $t2 stores the platforms array address
  la $t3, platform_num
  lw $t3 ($t3)                 # $t3 stores the number of platforms
  sll $t3, $t3, 3              # $t3 stores the number of platforms * 8 (Each platform is represented by a 2-word position)
  add $t3, $t3, $t2            # $t3 stores the first address after the end of our platform array
  la $t4, doodler_current_jump # $t4 stores the doodler's cur jump height address
  lw $t5 ($t4)                 # $t5 stores the doodler's cur jump height
  bgtz $t5, end_platform_collision_loop #if the doodler is moving upwards, don't check for platform collisions
  #Note: Should probably check this ^ before loading everything else for effiency's sake
platform_collision_loop:
  beq $t2, $t3 end_platform_collision_loop
  lw $t6 0($t2)                # $t6 stores x pos of current platform
  lw $t7 4($t2)                # $t7 stores y pos of current platform
  #if doodler y is one pixel above platform...
  sub		$t7, $t7, $t1
  addi	$t7, $t7, -3
  bne		$t7, $zero, platform_not_touching
  #if doodler x is between platform start and end...
  addi $t6, $t6, -2
  blt		$t0, $t6, platform_not_touching
  addi $t6, $t6, 7
  bgt	 $t0, $t6, platform_not_touching
  #Update doodler's current jump timer
  la $t8, doodler_jump_height
  lw $t8 ($t8)
  sw $t8 ($t4)
platform_not_touching:            # If the doodler isn't touching current platform...
  addi $t2, $t2, 8                # Increment to next platform stored in our array
  j platform_collision_loop
end_platform_collision_loop:      # Our loop exit label

  #Update positions of objects
  # Why did I do this...? I think this might be leftover from something I changed
  # Try removing and see if anything breaks
  la $t0, screen_height                 # $t0 stores the screen height memory location
  lw $t1 ($t0)                          # $t1 stores the screen height

  #Update doodler height
  la $t0, doodler_y                 # $t0 stores the doodler y pos memory location
  lw $t1 ($t0)                      # $t1 stores the doodler y pos
  la $t3, doodler_current_jump      # $t3 stores the doodler's cur jump height address
  lw $t4 ($t3)                      # $t4 stores the doodler's cur jump height
  bgtz $t4, doodler_rise            # if the doodler_current_jump is greater than zero, he's moving up!
doodler_fall:                       # if the doodler is falling (ie, doodler_current_jump <= 0)
  addi $t1, $t1, 1                  # Move the doodler down 1 unit
  sw $t1, ($t0)                     # Save the doodler's updated y position to memory 
  j doodler_y_end 
doodler_rise:                       # if the doodler is rising (ie, doodler_current_jump > 0)
  addi $t1, $t1, -1                 # Move the doodler up 1 unit
  sw $t1, ($t0)                     # Save the doodler's updated y position to memory 
  j doodler_y_end
doodler_y_end:
  addi $t4, $t4, -1                 # Decrement doodler_current_jump 
  sw $t4, ($t3)                     # Store decremented doodler_current_jump

  #move enemy
  la $t0, enemy_x
  lw $t1, ($t0)
  addi $t1, $t1, 1 
  li $t2, 31                        # $t2 gets 31
  and $t1, $t1, $t2                 # mod32
  sw $t1, ($t0)

  #Scroll Screen
  la $t0, screen_height
  lw $t0, ($t0)
  move $t5, $t0                # $t5 gets unaltered screenheight, for use later
  sra $t0, $t0, 2              # $t0 stores screen height divided by 4
  la $t1, doodler_y
  lw $t1, ($t1)                # $t1 gets the doodler's height
  bgt	$t1, $t0, scroll_screen_end	 #if the doodler isn't in the top 1/4 of the screen, don't scroll
  la $t2, platforms            # $t2 stores the platforms array address
  la $t3, platform_num
  lw $t3 ($t3)                 # $t3 stores the number of platforms
  sll $t3, $t3, 3              # $t3 stores the number of platforms * 8
  add $t3, $t3, $t2            # $t3 stores the first address after the end of our platform array
  la $t4, doodler_y            # $t4 stores the address of the doodler's y position (Because I wasn't thinking ahead I overwrote the register that had it earlier)
  addi $t1, $t1, 1             # $t1 gets doodlers current height + 1 (Moves him down, ie scrolling screen)
  sw $t1 ($t4)                 # $update doodler's new height
  la $t7 difficulty_counter
  lw $t8 ($t7)                
  addi $t8, $t8, 1
  sw $t8, ($t7)                # Update difficulty counter
  
  #Scroll the enemy
  la $t8, enemy_y
  lw $t9 ($t8)
  li $s0, 32
  bgt		$t9, $s0, scroll_enemy_end
scroll_enemy_start:
  addi $t9, $t9, 1
  sw $t9, ($t8)
scroll_enemy_end:

  #Scroll the shield
  la $t8, shield_y
  lw $t9 ($t8)
  li $s0, 32
  bgt		$t9, $s0, scroll_shield_end
scroll_shield_start:
  addi $t9, $t9, 1
  sw $t9, ($t8)
scroll_shield_end:

  #scroll the platforms
scroll_screen_start:
  beq $t2, $t3 scroll_screen_end
  lw $t4 4($t2)                # $t4 stores y pos of current platform
  addi $t4, $t4, 1
  sw $t4 4($t2)                # Increase the y pos of the current platform by 1
  blt	$t4, $t5, new_platform_end	# if $t0 < $t1 then target
new_platform_start:           # if the current platform goes offscreen, make a new one at the top of the screen
  sw $zero 4($t2)              
  li $v0, 42
  li $a0, 0
  li $a1, 25
  syscall
  sw $a0 0($t2)
new_platform_end:
  addi $t2, $t2, 8            # Move to the next platform in the array
  j scroll_screen_start
scroll_screen_end:

#update difficulty
  la $t0, difficulty_counter
  lw $t1, ($t0)
  li $t2, 250
  bne		$t1, $t2, increase_difficulty_end	# if $t0 != $t1 then increase_difficulty_end
  increase_difficulty:
  sw $zero ($t0)                          # Reset difficulty counter
  la $t3, enemy_y                         # Put an enemy at the top of the screen
  sw $zero, ($t3)
  la $t5, enemy_x
  li $v0, 42
  li $a0, 0
  li $a1, 30
  syscall
  sw $a0 0($t5)

  la $t0, platform_num
  lw $t1 ($t0)
  li $t2, 3
  beq $t1, $t2, decrease_platforms_end
  decrease_platforms:                     # Remove a platform if we have more than 3 platforms
  addi $t1, $t1, -1
  sw $t1, ($t0)
  decrease_platforms_end:
  la $t0, screen_refresh
  lw $t1 ($t0)
  li $t2, 15
  beq $t1, $t2, increase_speed_end
  increase_speed:
  addi $t1, $t1, -1
  sw $t1 ($t0)
  increase_speed_end:
  increase_difficulty_end:

  #spawn shield
  la $t0, difficulty_counter
  lw $t1, ($t0)
  li $t2, 125
  bne		$t1, $t2, spawn_shield_end
  spawn_shield:
  addi $t1, $t1, 1
  sw $t1, ($t0) 
  la $t3, shield_y                         # Put a shield at the top of the screen
  sw $zero, ($t3)
  la $t5, shield_x
  li $v0, 42
  li $a0, 0
  li $a1, 30
  syscall
  sw $a0 0($t5)
  spawn_shield_end:

  #Redraw Screen
  la $t0 doodler_has_shield
  lw $t0 ($t0)
  bgtz $t0, doodler_col_shield
doodler_col_no_shield:
 la $a0, col_doodler
 j doodler_col_end
doodler_col_shield:
  la $a0, col_blue
doodler_col_end: 
 
  jal draw_doodler
  la $a0, col_platform
  jal draw_platforms
  la $a0, col_red
  jal draw_enemy
  la $a0, col_blue
  jal draw_shield
  #Sleep
  li $v0, 32
  la $t0, screen_refresh
  lw $a0, ($t0)
  syscall

  j core
#TERMINATION
gameover:
jal draw_background            # Draw the full background once
jal draw_gameover              # Draw the gameover screen/text
wait_restart:
  li $v0, 32
  la $t0, screen_refresh
  lw $a0, ($t0)
  syscall
  lw $t0, 0xffff0000                # $t0 gets the value indicating keyboard input
  beq $t0, 0, wait_restart          # $if no keyboard input, skip handler
  lw $t0, 0xffff0004                # $t0 gets ascii value of entered key
  beq $t0, 0x73, do_restart         # if keyboard input s, restart
  j wait_restart
do_restart:
  jal reset_values
  j init

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
 
draw_platforms:                # Draws all the platforms stored in memory
####################################################################################################
  #$t0 - display base address
  #$t1 - colour to draw
  #$t2 - the platform array root
  #$t3 - loop exit flag (End of array)
  #$t4 - Screen width
  #$t5 - x pos of platform
  #$t6 - y pos of platform
  lw $t0, display_address	     # $t0 stores the base address for display
  move $t1, $a0                # $t1 stores the address storing the platform colour
  lw $t1, ($t1)	               # $t1 stores the platform colour
  la $t2, platforms            # $t2 stores the platforms array address
  la $t3, platform_num
  lw $t3 ($t3)                 # $t3 stores the number of platforms
  sll $t3, $t3, 3              # $t3 stores the number of platforms * 8
  add $t3, $t3, $t2            # $t3 stores the first address after the end of our platform array
  la $t4, screen_width          
  lw $t4 ($t4)                 # $t4 stores the screen width
platform_loop:
  beq $t2, $t3 end_platform_loop
  lw $t5 0($t2)                # $t5 stores x pos of current platform
  lw $t6 4($t2)                # $t6 stores y pos of current platform
  mult $t6, $t4                # multiply y pos by screen width
  mflo $t6                     # $t6 stores ^
  add $t5, $t5, $t6            # $t5 stores total pixel offset from base display address
  sll $t5, $t5, 2
  add $t5, $t5, $t0            
  
  sw $t1, 0($t5)               # write colour to pixel
  sw $t1, 4($t5)               # write colour to pixel
  sw $t1, 8($t5)               #write colour to pixel
  sw $t1, 12($t5)              # write colour to pixel
  sw $t1, 16($t5)              # write colour to pixel
  sw $t1, 20($t5)              # write colour to pixel

  addi $t2, $t2, 8
  j platform_loop

end_platform_loop:
  jr $ra 

draw_gameover:                 # Draw the gameover text
####################################################################################################
  lw $t0, display_address	     # $t0 stores the base address for display
  la $t1, col_doodler          # $t1 stores the address storing the background colour
  lw $t1, ($t1)	               # $t1 stores the text colour
  li $t2, 128
  addi $t0, $t0, 1440
  la $t3, bye_text
  li $t5, -1
  li $t6, -2
gameover_loop:
  lw $t4, ($t3)
  beq $t4, $t5, gameover_jump_row
  beq $t4, $t6, gameover_end
  add $t7, $t4, $t0
  sw $t1, ($t7)
  addi $t3, $t3, 4
  j gameover_loop
gameover_jump_row:
  addi $t0, $t0, 128
  addi $t3, $t3, 4
  j gameover_loop
gameover_end:  
  jr $ra                       # Exit Function

draw_enemy:                   # Draws the enemy at the x,y position stored in memory
####################################################################################################
  lw $t0, display_address	     # $t0 stores the base address for display
  move $t1, $a0                # $t1 stores the address storing the enemy colour
  lw $t1, ($t1)	               # $t1 stores the enemy colour
  la $t2, enemy_x           
  lw $t2 ($t2)                 # $t2 stores the enemy x pos
  la $t3, enemy_y           
  lw $t3, ($t3)                # $t3 stores the enemy y pos
  la $t4, screen_width         # $t4 stores the address storing the screen width
  lw $t4, ($t4)	               # $t4 stores the screen width

  #Draw enemy
  mult $t3, $t4
  mflo $t5
  add $t5, $t5, $t2            # $t5 stores the pixel offset from origin of enemy
  sll $t5, $t5, 2              # $t5 stores the equivalent offset in memory ie pixel offset * 4
  add $t0, $t0, $t5
  sw $t1, 0($t0)               # write enemy colour to pixel
  sw $t1, 4($t0)               # write enemy colour to pixel

  move 	$t5, $t4		           # $t5 = t4
  sll $t5, $t5, 2
  add $t0, $t0, $t5            # $t5
  sw $t1, 0($t0)               # write enemy colour to pixel
  sw $t1, 4($t0)               # write enemy colour to pixel

  jr $ra

reset_values:
####################################################################################################
  la $t0, doodler_x
  li $t1, 15
  sw $t1, ($t0)
  la $t0, doodler_y
  li $t1, 30
  sw $t1, ($t0)
  la $t0, doodler_current_jump
  li $t1, 25
  sw $t1, ($t0)
  la $t0, platform_num
  li $t1, 5
  sw $t1, ($t0)
  la $t0, screen_refresh
  li $t1, 30
  sw $t1, ($t0)
  la $t0, difficulty_counter
  li $t1, 0
  sw $t1, ($t0)
  la $t0, enemy_x
  li $t1, 18
  sw $t1, ($t0)
  la $t0, enemy_y
  li $t1, 32
  sw $t1, ($t0)
  la $t0, doodler_has_shield
  sw $zero, ($t0)
  jr $ra

draw_shield:                   # Draws the shield at the x,y position stored in memory
####################################################################################################
  lw $t0, display_address	     # $t0 stores the base address for display
  move $t1, $a0                # $t1 stores the address storing the enemy colour
  lw $t1, ($t1)	               # $t1 stores the enemy colour
  la $t2, shield_x           
  lw $t2 ($t2)                 # $t2 stores the enemy x pos
  la $t3, shield_y           
  lw $t3, ($t3)                # $t3 stores the enemy y pos
  la $t4, screen_width         # $t4 stores the address storing the screen width
  lw $t4, ($t4)	               # $t4 stores the screen width

  #Draw shield
  mult $t3, $t4
  mflo $t5
  add $t5, $t5, $t2            # $t5 stores the pixel offset from origin of enemy
  sll $t5, $t5, 2              # $t5 stores the equivalent offset in memory ie pixel offset * 4
  add $t0, $t0, $t5
  sw $t1, 0($t0)               # write shield colour to pixel
  sw $t1, 4($t0)               # write shield colour to pixel

  move 	$t5, $t4		           # $t5 = t4
  sll $t5, $t5, 2
  add $t0, $t0, $t5            # $t5
  sw $t1, 0($t0)               # write shield colour to pixel
  sw $t1, 4($t0)               # write shield colour to pixel

  jr $ra