*-------------------------------------------------------
* Author         : Michael Rainsford Ryan
* Student Number : C00239510
* Date Created   : 21/01/2019
* Description    : A simplified, offline clone of the
*                : online game "Avalon".
* Issues/Bugs    : None currenty.
*-------------------------------------------------------

    org $1000

*-------------------------------------------------------
*Choose to be a Worker or a God 
*https://www.avalon-rpg.com/
*-------------------------------------------------------

*-------------------------------------------------------
*-------------------Game Information-------------------
*-------------------------------------------------------
*A6 is used for player coordinates
*A5 is used for enemy coordinates when in combat or looping through them
*D5 is used occasionally for input range
*$5000 to $5FE0 holds maps
*$5FF0 holds player information
*$6000 to $7000 holds enemies

*Enemies:
*Byte:  Name
*0      Health
*1      Damage/level
*2      enemy type (Knight, mage, rogue)
*3      Alive state (1 == alive, 0 == dead)
*4 & 5  Coordinates

*Player:
*Byte:  Name
*0      Health
*1      Damage/level
*2      Class (Knight, mage, rogue)
*3      Game state
*4-5+A6 Coordinates
*6-7    Last coordinates
    
*Game state : 0 = Pick role/intro | 5 = Move around | 6 = Combat | 10 to 20 = Shop | 64 = End game
*Class      : 1 corresponds to knight - 2 corresponds to mage - 3 corresponds to rogue


*-------------------------------------------------------
*Validation values to be used, modify as needed
*Add additional validation values as required
*-------------------------------------------------------
exit        EQU 0      used to exit assembly program
min_feed    EQU 100    min feed requirement
min_potions EQU 1      min number of potions
max_potions EQU 9      max number of potions
min_weapons EQU 6      min weapons
win_point   EQU 5      points accumilated on win
lose_point  EQU 8      points deducted on a loss

FIRST_ENEMY EQU $6000
ENEMY_MAX   EQU 1      Number of enemies in the game

RED         EQU $000000FF   Red colour value
GREEN       EQU $0000FF00   Green colour value
BLUE        EQU $0000FF00   Blue colour value
WHITE       EQU $00FFFFFF   White colour value
FONT        EQU $01090000   Font value

PLAYER      EQU $5FF0       Memory address for player information
GAME_STATE  EQU $5FF3       The memory address of the game state
PLA_CLASS   EQU $5FF2       The memory address for the player class
PLA_P_POS   EQU $5FF6       Memory location of the player's previous position

DAMAGE      EQU 1           The number of bytes to move from the charater before reaching the damage
CLASS       EQU 2           The number of bytes to move from the charater before reaching the class
ALIVE       EQU 3           The number of bytes to move from the charater before reaching the alive state
POSITION    EQU 4           The number of bytes to move from the charater before reaching the position




*Start of Game
start:
    move.b  #10,$5FF0  put score/health in memory location $5FF0
    lea     $5FF0,A3   assign address A3 to that memory location
    
    move.b  #0,$5FF3   put game state number in memory location $5FF3
    *0 = Pick role/intro | 5 = Move around | 6 = Combat | 10 to 20 = Shop | 64 = End game

    move.b  #0,$5FF2   put class number in memory location $5FF2
    * 1 corresponds to knight - 2 corresponds to mage - 3 corresponds to rogue
    
    bsr     setup_world
    bsr     setup_enemies

    bsr     welcome    branch to the welcome subroutine
    bsr     press_continue
    bsr     game       branch to the game subroutine
*Game loop
    org     $3000      the rest of the program is to be located from 3000 onwards

*-------------------------------------------------------
*-------------------Game Subroutine---------------------
*-------------------------------------------------------
game:
    bsr     gameloop   branch to gameloop subroutine
    rts                return from game: subroutine
          
end:
    simhalt

*-------------------------------------------------------
*-------------------Welcome Subroutine------------------
*-------------------------------------------------------
welcome:
    bsr     endl            branch to endl subroutine
    lea     welcome_msg,A1  assign message to address register A1
    move.b  #14,D0          move literal 14 to DO
    trap    #15             trap and interpret value in D0
    bsr     endl            branch to endl subroutine
    
    rts                     return from welcome: subroutine

*-------------------------------------------------------
*-------------------Role Picking Subroutine------------------
*-------------------------------------------------------
pick_role:

    lea     wake_up_msg,A1  assign message to address register A1
    move.b  #14,D0          move literal 14 to DO
    trap    #15             trap and interpret value in D0
    bsr     endl            branch to endl subroutine
    
    lea     pick_role_msg,A1 assign message to address register A1
    move.b  #14,D0           move literal 14 to DO
    trap    #15              trap and interpret value in D0
    
    move.l  #3,D5           Move the number 3 to D5 to tell the program how many options there are
    
    bsr     input           branch to the input subroutine
    
    bsr     press_continue          Pause the game until a key is pressed
    
    rts                     return from pick_role subroutine
    
role_input:
    move.b  D1,PLA_CLASS    Move the role number to player class memory location to hold the class number
    
    *Give the player a message depending on the role chosen
    CMP.B   #1,D1
    BEQ     knight_select   Branch to knight message if role selected
    
    CMP.B   #2,D1
    BEQ     mage_select     Branch to mage message if role selected
    
    CMP.B   #3,D1
    BEQ     rogue_select    Branch to rogue message if role selected
    
    rts
    
knight_select:
    lea     knight_role_msg,A1 assign message to address register A1
    move.b  #14,D0          move literal 14 to DO
    trap    #15             Display the knight message
    
    move.b  #5,GAME_STATE   Change the game state to the movement state
    lea     $514A,A6        Set the player coordinate to the first corridor
    
    rts                     Return from the sub routine

mage_select:
    lea     mage_role_msg,A1 assign message to address register A1
    move.b  #14,D0          move literal 14 to DO
    trap    #15             Display the mage message
    
    move.b  #5,GAME_STATE   Change the game state to the movement state
    lea     $514A,A6        Set the player coordinate to the first corridor
    
    rts                     Return from the sub routine

rogue_select:
    lea     rogue_role_msg,A1 assign message to address register A1
    move.b  #14,D0          move literal 14 to DO
    trap    #15             Display the rogue message
    
    move.b  #5,GAME_STATE   Change the game state to the movement state
    lea     $514A,A6        Set the player coordinate to the first corridor
    
    rts                     Return from the sub routin
    
*-------------------------------------------------------
*---------Gameplay Input Values Subroutine--------------
*-------------------------------------------------------    
input:
    bsr     endl            Branch to end line subroutine
    
    lea     input_nums_msg,A1 assign message to address register A1
    move.b  #14,D0          move literal 14 to DO
    trap    #15             Display the "enter number" message
    
    move.l  D5,D1           Move the number of options to D1 to display it
    move.b  #3,D0           move literal 3 to DO
    trap    #15             Display the number in D1 to show the input range
    
    lea     colon_msg,A1    assign message to address register A1
    move.b  #14,D0          move literal 14 to DO
    trap    #15             Display a colon after the number range
    
    move.b  #4,D0           Move the number 4 to D0
    trap    #15             Take input
    
manage_input:
    CMP     #1,D1           Check input against minimum value
    BLT     invalid_input   Error if less than 1
    
    CMP     D5,D1           Compare input against max value
    BGT     invalid_input   Error if more than max value
    
    CMP.B   #0,GAME_STATE   Check which state the game is in
    BEQ     role_input      Branch to the manage input for the role picking
    CMP.B   #5,GAME_STATE   Check which state the game is in
    BEQ     wall_collisions Branch to the manage input for the movement
    CMP.B   #6,GAME_STATE   Check which state the game is in
    BNE     fake_gamestate  branch to display a message if the gamestate is undifined
    
    rts                     Return out of subroutine

invalid_input:
    lea     input_error_msg,A1 assign message to address register A1
    move.b  #14,D0          move literal 14 to DO
    trap    #15             Display the error message
    
    bra     input           Go back to taking input
    
fake_gamestate:
    lea     fake_gamestate_msg,A1   Assign message to address register A1
    move.b  #14,D0                  move literal 14 to DO
    trap    #15                     Display the error message
    rts

*-------------------------------------------------------
*----------------Gameloop (main loop)-------------------
*------------------------------------------------------- 
gameloop:
    bsr     clear_screen    clears the screen  
    bsr     draw            branch to draw screen subroutine
    bsr     draw_hud
    bsr     update          branch to update game subroutine 
    bsr     gameplay        branch to gameplay subroutine
    bra     gameloop        Continue looping the game loop     
    
    *bsr     clear_screen    clears the screen
    *bsr     hud             branch to display HUD subroutine
    *bsr     clear_screen    clears the screen
    *bsr     replay          branch to replay game subroutine
    *bsr     clear_screen    clears the screen
    *rts                     return from gameloop: subroutine

*-------------------------------------------------------
*----------------Update Quest Progress------------------
*  Complete Quest
*------------------------------------------------------- 
update:
    CMP.B   #5,GAME_STATE       Check which state the game is in
    BEQ     enemy_check         Check for enemies if in movement state
    CMP.B   #6,GAME_STATE       Check which state the game is in
    BEQ     enemy_alive_check   Check if enemy is dead if in combat
    
    rts
    
enemy_check:
    lea     FIRST_ENEMY,A5  Load the enemy information into A5
    add.w   #ALIVE,A5       Move into enemy information to check if its alive
    CMP.B   #0,(A5)         Check if the enemy is alive
    BEQ     return          Return from the check if the enemy is dead
    
    add.w   #1,A5           Move from the enemy alive state to its position
    move.w  A6,D2           Move the player position to D2
    
    *Check if the player is beside an enemy
    sub.w   #16,D2          Check north
    CMP.W   (A5),D2           
    BEQ     enter_combat    Enter the player into combat
    
    add.w   #32,D2          Check south
    CMP.W   (A5),D2           
    BEQ     enter_combat    Enter the player into combat
    
    sub.w   #17,D2          Check west
    CMP.W   (A5),D2           
    BEQ     enter_combat    Enter the player into combat
    
    add.w   #2,D2           Check east
    CMP.W   (A5),D2           
    BEQ     enter_combat    Enter the player into combat
    
    rts     Return if not touching an enemy
    
enter_combat:
    sub.w   #4,A5               Get the memory address of the enemy opposed to it's position
    move.b  #6,GAME_STATE       Move to combat state
    
    bsr     endl                Line break
    
    LEA     encounter_msg,A1    Load the encounter message int A1
    move.b  #14,D0              Move #14 to D0 to display message
    trap    #15                 Display the loaded message
    
    bsr     press_continue      Branch to the press to continue subroutine
    
    bsr     clear_screen        Clear the screen
    
    bsr     draw_skeleton       Draw the enemy
    bsr     draw_battle_info    Draw the info
    
    rts
    
enemy_alive_check:
    CMP.B   #0,(A5)     Compare the enemy health with zero
    BEQ     enemy_died  If the enemy health is zero, they died
    CMP.B   #100,(A5)   Compare the enemy health with 100
    BGT     enemy_died  If the enemy health is greater than 100, their health has underflowed and they're dead
    
    rts
    
enemy_died:
    bsr     endl            Break to a new line

    lea     battle_won_msg,A1   Load the won battle message
    move.b  #14,D0              Move the literal #14 to D0 for trap task #14
    trap    #15                 Display the message
    
    move.b  #5,GAME_STATE   Set the game state mack to movement state
    add.w   #ALIVE,A5       Move from the enemy health to its alive status
    move.b  #0,(A5)         Set the enemy as dead
    
    bsr     press_continue
    
    bsr     clear_screen    Clear the screen
    bsr     draw            Draw the map for first frame back in movement
    bsr     draw_hud        Draw the hud for first frame back in movement
    
    rts
    
*-------------------------------------------------------
*-----------------Draw Quest Updates--------------------
* Draw the game progress information, status regarding
* quest
*------------------------------------------------------- 
draw:
    CMP.B   #5,GAME_STATE   Check which state the game is in
    BEQ     draw_loop       If in the movement state, draw the map
    CMP.B   #6,GAME_STATE   Check which state the game is in
    BEQ     draw_skeleton   If in the combat state, draw the enemy
    rts
    
draw_skeleton:
    lea     skeleton_msg,A1 Load the skeleton message
    move.b  #14,D0          Move literal 14 for display message trap command
    trap    #15             Display the loaded message
    
    rts
    
draw_hud:
    CMP.B   #5,GAME_STATE       Check which state the game is in
    BEQ     draw_player_info    If in the movement state, draw the player info
    CMP.B   #6,GAME_STATE       Check which state the game is in
    BEQ     draw_battle_info     If in the combat state, draw the combat info
    
    rts

draw_player_info:
    move.w  #255,D1         Move the word #255 to D1 to set the type of trap 11
    move.b  #11,D0          Move the byte #11 to D0 for trap command 11
    trap    #15             Trap to get the cursor position in D1
    
    move.w  D1,D3           Move the current cursor position to D3 for later
    
    move.w  #$3201,D1           
    trap    #15             Set the cursor position with trap command 11
    clr     D1              Clear D1 of the cursor position
    
    lea     health_msg,A1   Load the hud message
    move.b  #14,D0          Move literal 14 for display message trap command
    trap    #15             Display the loaded message
    
    move.b  PLAYER,D1       Move the player health value to D1 to display
    move.b  #3,D0           Move literal 3 for display number trap command
    trap    #15             Display the number in D1
    
    move.w  D3,D1           Move the current cursor position to D3 for later
    
    move.b  #11,D0          Move the byte #11 to D0 for trap command 11          
    trap    #15             Set the cursor position with trap command 11
    
    clr     D1              Clear D1 for later use
    
    rts

draw_battle_info:
    move.w  #255,D1         Move the word #255 to D1 to set the type of trap 11
    move.b  #11,D0          Move the byte #11 to D0 for trap command 11
    trap    #15             Trap to get the cursor position in D1
    
    move.w  D1,D3           Move the current cursor position to D3 for later
    
    * Move cursor to draw player info
    move.w  #$2001,D1           
    trap    #15             Set the cursor position with trap command 11
    clr     D1              Clear D1 of the cursor position
    
    lea     health_msg,A1   Load the hud message
    move.b  #14,D0          Move literal 14 for display message trap command
    trap    #15             Display the loaded message
    
    move.b  PLAYER,D1       Move the player health value to D1 to display
    move.b  #3,D0           Move literal 3 for display number trap command
    trap    #15             Display the number in D1
    
    * Move the cursor to draw enemy info
    move.b  #11,D0          Move the byte #11 to D0 for trap command 11
    move.w  #$2002,D1       
    trap    #15             Set the cursor position with trap command 11
    clr     D1              Clear D1 of the cursor position
    
    lea     enemy_health_msg,A1 Load the hud message
    move.b  #14,D0              Move literal 14 for display message trap command
    trap    #15                 Display the loaded message
    
    move.b  FIRST_ENEMY,D1  Move the player health value to D1 to display
    move.b  #3,D0           Move literal 3 for display number trap command
    trap    #15             Display the number in D1
    
    * Move the cursor back to its previous position
    move.w  D3,D1           Move the previous cursor position back to D1
    move.b  #11,D0          Move the byte #11 to D0 for trap command 11          
    trap    #15             Set the cursor position with trap command 11
    
    clr     D1              Clear D1 for later use
    
    rts

*-------------------------------------------------------
*---Game Play (Quest Progress)--------------------------
*------------------------------------------------------- 
gameplay:
    bsr     endl        Break to a new line
    CMP.B   #0,GAME_STATE     Check which stage the game is in
    BEQ     pick_role   branch to the pick role subroutine
    CMP.B   #5,GAME_STATE     Check which stage the game is in
    BEQ     movement    branch to the movement subroutine
    CMP.B   #6,GAME_STATE     Check which stage the game is in
    BEQ     combat      branch to the combat subroutine
    rts                 Return from 'gameplay' subroutine

*-------------------------------------------------------
*-----------------Heads Up Display (Score)--------------
* Retrieves the score from memory location
*-------------------------------------------------------   
hud:

    bsr     endl
    bsr     decorate
    lea     hud_msg,A1
    move.b  #14,D0
    trap    #15
    move.b  (A3),D1     retrieve the value A3 point to and move to D1
    move.b  #3,D0       move literal 3 to D0
    trap    #15         intrepret value in D0, which 3 which displays D1
    bsr     decorate
    rts

*-------------------------------------------------------
*------------------Screen Decoration--------------------
*-------------------------------------------------------
decorate:
    move.b  #60, D3
    bsr     endl
out:
    lea     loop_msg,A1
    move.b  #14,D0
    trap    #15
	sub     #1,D3   decrement loop counter
    bne     out	    repeat until D0=0
    bsr     endl
    rts
    
clear_screen: 
    move.b  #11,D0      clear screen
    move.w  #$ff00,D1
    trap    #15
    rts
*-------------------------------------------------------
*------------------------Replay-------------------------
*-------------------------------------------------------
replay:
    bsr     endl
    lea     replay_msg,A1
    move.b  #14,D0
    trap    #15
    
    move.b  #4,D0
    trap    #15
    
    cmp     #exit,D1
    beq     end         if SR Z register contains 1 beq => Branch Equals
    bsr     gameloop

endl:
    movem.l D0/A1,-(A7)
    move    #14,D0
    lea     crlf,A1
    trap    #15
    movem.l (A7)+,D0/A1
    rts
        
*-------------------------------------------------------
*----------------------Manage Movement------------------
*-------------------------------------------------------
movement:
    lea     movement_msg,A1 Load the movement message
    move.b  #14,D0          Move literal 14 for display message trap command
    trap    #15             Display the loaded message

    move.l  #4,D5           Move the number 4 to D5 to tell the program how many options there are
    
    bsr     input           branch to the input subroutine
    rts

*-------------------------------------------------------
*-------------------Check Wall Collisions---------------
*-------------------------------------------------------
wall_collisions:
    *Check collisions in the movement direction
    CMP.B   #1,D1       Check the movement direction
    BEQ     move_north  Branch to Display the corridor type
    
    CMP.B   #2,D1       Check the movement direction
    BEQ     move_south  Branch to Display the corridor type
    
    CMP.B   #3,D1       Check the movement direction
    BEQ     move_west   Branch to Display the corridor type
    
    CMP.B   #4,D1       Check the movement direction
    BEQ     move_east   Branch to Display the corridor type
    
    rts
    
move_north:
    *Check if the tile is any of the corridor types with a wall at the top
    CMP.B   #2,(A6)
    BEQ     movement_blocked
    CMP.B   #3,(A6)
    BEQ     movement_blocked
    CMP.B   #6,(A6)
    BEQ     movement_blocked
    CMP.B   #7,(A6)
    BEQ     movement_blocked
    CMP.B   #11,(A6)
    BEQ     movement_blocked
    CMP.B   #12,(A6)
    BEQ     movement_blocked
    CMP.B   #13,(A6)
    BEQ     movement_blocked
    
    move.w  A6,PLA_P_POS        Move the player's previous location to a memory address for storage
    sub     #16,A6              Move the player north
    
    rts
    
move_south:
    *Check if the tile is any of the corridor types with a wall at the bottom
    CMP.B   #2,(A6)
    BEQ     movement_blocked
    CMP.B   #4,(A6)
    BEQ     movement_blocked
    CMP.B   #5,(A6)
    BEQ     movement_blocked
    CMP.B   #9,(A6)
    BEQ     movement_blocked
    CMP.B   #11,(A6)
    BEQ     movement_blocked
    CMP.B   #13,(A6)
    BEQ     movement_blocked
    CMP.B   #14,(A6)
    BEQ     movement_blocked
    
    move.w  A6,PLA_P_POS        Move the player's previous location to a memory address for storage
    add     #16,A6              Move the player south
    
    rts

move_west:
    *Check if the tile is any of the corridor types with a wall to the left
    CMP.B   #1,(A6)
    BEQ     movement_blocked
    CMP.B   #3,(A6)
    BEQ     movement_blocked
    CMP.B   #4,(A6)
    BEQ     movement_blocked
    CMP.B   #8,(A6)
    BEQ     movement_blocked
    CMP.B   #11,(A6)
    BEQ     movement_blocked
    CMP.B   #12,(A6)
    BEQ     movement_blocked
    CMP.B   #14,(A6)
    BEQ     movement_blocked
    
    move.w  A6,PLA_P_POS        Move the player's previous location to a memory address for storage
    sub     #1,A6               Move the player west
    
    rts
    
move_east:
    *Check if the tile is any of the corridor types with a wall to the right
    CMP.B   #1,(A6)
    BEQ     movement_blocked
    CMP.B   #5,(A6)
    BEQ     movement_blocked
    CMP.B   #6,(A6)
    BEQ     movement_blocked
    CMP.B   #10,(A6)
    BEQ     movement_blocked
    CMP.B   #12,(A6)
    BEQ     movement_blocked
    CMP.B   #13,(A6)
    BEQ     movement_blocked
    CMP.B   #14,(A6)
    BEQ     movement_blocked
    
    move.w  A6,PLA_P_POS            Move the player's previous location to a memory address for storage
    add     #1,A6                   Move the player east
    
    rts

movement_blocked:
    lea     movement_blocked_msg,A1 Load the message
    move.b  #14,D0                  Move the trap command to display a message
    trap    #15                     Display the movement blocked message
    bsr     press_continue          Pause the game until a key is pressed
    
    rts                             Return from the subroutine
    
*-------------------------------------------------------
*---------------------Manage Combat---------------------
*-------------------------------------------------------
combat:
    bsr endl                Break to a new line

    lea     combat_msg,A1   Load the combat message
    move.b  #14,D0          Move literal 14 for display message trap command
    trap    #15             Display the loaded message

    move.l  #4,D5           Move the number 4 to D5 to tell the program how many options there are
    
    bsr     input           branch to the input subroutine
    
    CMP.B   #1,D1
    BEQ     block_counter
    CMP.B   #2,D1
    BEQ     cast_magic
    CMP.B   #3,D1
    BEQ     melee_attack
    CMP.B   #4,D1
    BEQ     try_run
    
    rts
    
block_counter:
    bsr     random_number       Get a random number 1-100
    
    CMP.W   #33,D2              Compare random with #33
    BLE     both_block          Enemy tries to block - attack failed
    CMP.W   #66,D2              Compare random with #66
    BLE     hit_by_magic        Enemy casts magic - player takes damage      
    BGT     hit_against_melee   Enemy tried to lunge - enemy takes damage
    
    rts                         Return from subroutine
    
cast_magic:
    bsr     random_number       Get a random number 1-100

    CMP.W   #33,D2              Compare random with #33
    BLE     hit_against_block    Enemy blocks - enemy takes damage
    CMP.W   #66,D2              Compare random with #66
    BLE     both_cast_magic     Enemy casts magic - attack fails     
    BGT     hit_by_melee        Enemy lunges forward - player takes damage
    
    rts                         Return from subroutine

melee_attack:
    bsr     random_number       Get a random number 1-100

    CMP.W   #33,D2              Compare random with #33
    BLE     hit_by_counter      Enemy blocks and counters - player takes damage
    CMP.W   #66,D2              Compare random with #66
    BLE     hit_against_magic   Enemy casts magic - player takes damage     
    BGT     both_melee          Enemy lunges forward - attack fails
    
    rts                         Return from subroutine

try_run:
    bsr     random_number
    
    CMP.W   #40,D2
    BLT     escape_attack
    BGE     fail_escape
    
    bsr     press_continue
    
    rts
    
escape_attack:
    move.w  PLA_P_POS,A6    Move the player to their position before the battle
    move.b  #5,GAME_STATE   Switch game state
    
    lea     escape_msg,A1   Load escape message
    move.b  #14,D0          Move literal for trap command
    trap    #15             Trap 15 to display messgae
    
    bsr     press_continue  Pause until the player presses to continue
    
    rts                     Return from subroutine
    
fail_escape:
    lea     fail_escape_msg,A1  Load fail escape message
    move.b  #14,D0              Move literal for trap command
    trap    #15                 Trap 15 to display message
    
    sub.b   #1,PLAYER           Remove one from the player's health
    
    bsr     press_continue      Pause until the player presses to continue
    rts
    
both_block:
    move.b  #14,D0
    lea     both_block_msg,A1
    trap    #15
    
    bsr     press_continue
    rts
    
both_cast_magic:
    move.b  #14,D0
    lea     both_cast_magic_msg,A1
    trap    #15
    
    bsr     press_continue
    rts

both_melee:
    move.b  #14,D0
    lea     both_melee_msg,A1
    trap    #15  
    
    bsr     press_continue
    rts

hit_against_block:
    move.b  #14,D0
    lea     hit_against_block_msg,A1
    trap    #15  
    
    sub.b   #1,(A5)         Remove one from the enemy's health
    
    bsr     press_continue
    rts

hit_against_magic:
    move.b  #14,D0
    lea     hit_against_magic_msg,A1
    trap    #15
    
    sub.b   #1,(A5)         Remove one from the enemy's health
    
    bsr     press_continue
    rts

hit_against_melee:
    move.b  #14,D0
    lea     hit_against_melee_msg,A1
    trap    #15
    
    sub.b   #1,(A5)         Remove one from the enemy's health
    
    bsr     press_continue
    rts

hit_by_counter:
    move.b  #14,D0
    lea     hit_by_counter_msg,A1
    trap    #15  
    
    sub.b   #1,PLAYER           Remove one from the player's health
    
    bsr     press_continue
    rts

hit_by_magic:
    move.b  #14,D0
    lea     hit_by_magic_msg,A1
    trap    #15  
    
    sub.b   #1,PLAYER           Remove one from the player's health
    
    bsr     press_continue
    rts

hit_by_melee:
    move.b  #14,D0
    lea     hit_by_melee_msg,A1
    trap    #15
    
    sub.b   #1,PLAYER           Remove one from the player's health
    
    bsr     press_continue
    rts

*-------------------------------------------------------
*-------------------Misc Subroutines--------------------
*-------------------------------------------------------
press_continue:
    bsr     endl

    lea     continue_msg,A1 Load message into A1
    move.b  #14,D0          Move the trap command to display a message
    trap    #15             display the "press any ket to continue" text
    
    move.b  #4,D0           Move the trap command to take input
    trap    #15             take input to freeze the game
    rts                     Return from the 'press continue' subroutine
    
random_number:              *Psuedo random number generator, courtesy of Pádraig
    move.b  #8,D0
    trap    #15
    and.l   #$5FFFFF,d1     prevent overflow in divu
    divu    #100,D1         time count / 100
    swap    D1              swap upper and lower words of D1 to put remainder in low word
    addq.w  #1,D1           d1.w contains number from 1 to 100
    move    D1,D2           d2 = d1
    clr.l   D1
    
    rts                     Returns from random generation subroutine
    
return:   *Subroutine to branch to to break out of a subroutine when a condition is met
    rts
    
*-------------------------------------------------------
*----------------------Draw loop------------------------
*-------------------------------------------------------
draw_loop:
    lea     $5000,A2        Load starting memory location into A7
    move.b  #0,D6           Data register used for rows
    move.b  #0,D7           Data register used for columns
    move.l  #0,D1           Clear the D1 data register
    
    bsr     loop_rows       Loop for every row
    rts
    
loop_rows:
    CMP     #22,D6          Check the rows don't go out of bounds
    BGT     end_loop        If the rows are greater than 22 end the loop
    
    move.b  #0,D7           Reset to column 0
    bsr     loop_columns    Loop for every column
    
    add.b   #1,D6           Add to the rows
    
    bsr     endl            Break to the next line
    bra     loop_rows       Loop through the rows again
    
loop_columns:
    CMP.B   #15,D7              Check the rows don't go out of bounds
    BGT     end_loop            If the rows are greater than 22 end the loop
    
    bsr     draw_tile           Draw the current tile
    bsr     check_for_player    Draw the player in the current tile if they're there
    bsr     check_for_enemy
    
    add.b   #1,D7               Add to the column count
    add     #1,A2               Move to the next memory location
    bra     loop_columns        Loop the columns again

end_loop:
    rts                         Return once a loop is finished
    
*-------------------------------------------------------
*----------------------Draw tile------------------------
*-------------------------------------------------------
*Draws the tile at the address in the address register A2
draw_tile:
    CMP.B   #255,(A2)           Check if the value is undifined
    BEQ     draw_blocked_tile   Draw the blank tile
    
    CMP.B   #1,(A2)
    BEQ     draw_both_tile
    CMP.B   #3,(A2)
    BEQ     draw_left_tile
    CMP.B   #4,(A2)
    BEQ     draw_left_tile
    CMP.B   #5,(A2)
    BEQ     draw_right_tile
    CMP.B   #6,(A2)
    BEQ     draw_right_tile
    CMP.B   #8,(A2)
    BEQ     draw_left_tile
    CMP.B   #10,(A2)
    BEQ     draw_right_tile
    CMP.B   #11,(A2)
    BEQ     draw_left_tile
    CMP.B   #12,(A2)
    BEQ     draw_both_tile
    CMP.B   #13,(A2)
    BEQ     draw_right_tile
    CMP.B   #14,(A2)
    BEQ     draw_both_tile
    
    BRA     draw_blank_tile     Draw the blank tile
    
draw_blocked_tile:
    lea     blocked_tile,A1
    move.b  #14,D0
    trap    #15
    rts
    
draw_both_tile:
    lea     both_tile,A1
    move.b  #14,D0
    trap    #15
    rts
    
draw_left_tile:
    lea     left_tile,A1
    move.b  #14,D0
    trap    #15
    rts
    
draw_right_tile:
    lea     right_tile,A1
    move.b  #14,D0
    trap    #15
    rts
    
draw_blank_tile:
    lea     blank_tile,A1
    move.b  #14,D0
    trap    #15
    rts
    
check_for_player:
    CMP.W   A6,A2
    BEQ     draw_player
    rts
    
draw_player:
    move.w  #255,D1         Move the word #255 to D1 to set the type of trap 11
    move.b  #11,D0          Move the byte #11 to D0 for trap command 11
    trap    #15             Trap to get the cursor position in D1
    
    sub.w   #512,D1         Move the cursor back by two columns
    trap    #15             Set the cursor position with trap command 11
    
    move.l  D1,D3          Move the value in D1 to D3 for storage
    
    move.b  #21,D0          Move #21 to D0 for trap command 21
    move.l  #GREEN,D1       Move the colour green to D1
    move.l  #FONT,D2        Move the font to D2
    trap    #15             Set the colour
    
    lea     player_mark,A1      load the player symbol
    move.b  #14,D0              Move #14 to D0 for trap command 14
    trap    #15                 Draw the player mark
    
    move.b  #21,D0          Move #21 to D0 for trap command 21
    move.l  #WHITE,D1       Move the colour green to D1
    trap    #15             Set the colour
    clr.l   D1
    
    move.l  D3,D1           Move the value in D3 to D1 for previous cursor position
    
    add.w   #512,D1         Move the cursor position two columns forward
    move.b  #11,D0          Move byte #11 for trap command 11 
    trap    #15             Set the cursor position
    
    rts
    
check_for_enemy:
    lea     FIRST_ENEMY,A5  Load the memory address of the first enemy
    add.w   #ALIVE,A5       Add to the enemy memory address to get to its alive state
    CMP.B   #0,(A5)         Check if the enemy is alive
    BEQ     return          Return from the subroutine if not
    
    move.w  $6004,D1
    move.w  D1,A0
    CMP.W   A0,A2
    BEQ     draw_enemy
    rts
    
draw_enemy:
    move.w  #255,D1         Move the word #255 to D1 to set the type of trap 11
    move.b  #11,D0          Move the byte #11 to D0 for trap command 11
    trap    #15             Trap to get the cursor position in D1
    
    sub.w   #512,D1         Move the cursor back by two columns
    trap    #15             Set the cursor position with trap command 11
    
    move.l  D1,D3          Move the value in D1 to D3 for storage
    
    move.b  #21,D0          Move #21 to D0 for trap command 21
    move.l  #RED,D1       Move the colour green to D1
    move.l  #FONT,D2        Move the font to D2
    trap    #15             Set the colour
    
    lea     enemy_mark,A1      load the player symbol
    move.b  #14,D0              Move #14 to D0 for trap command 14
    trap    #15                 Draw the player mark
    
    move.b  #21,D0          Move #21 to D0 for trap command 21
    move.l  #WHITE,D1       Move the colour green to D1
    trap    #15             Set the colour
    clr.l   D1
    
    move.l  D3,D1           Move the value in D3 to D1 for previous cursor position
    
    add.w   #512,D1         Move the cursor position two columns forward
    move.b  #11,D0          Move byte #11 for trap command 11 
    trap    #15             Set the cursor position
    
    rts
    
*-------------------------------------------------------
*-------------------Setup the world---------------------
*-------------------------------------------------------
setup_world:
    move.b  #14,$514A   Setup the starting corridor
    move.b  #7,$513A    T junction upwards from starting corridor
    move.b  #4,$5139    Left corridor
    move.b  #1,$5129
    move.b  #1,$5119
    
    move.b  #4,$5108    First shop
    move.b  #0,$5109    Entrance
    move.b  #5,$510A
    move.b  #8,$50F8
    move.b  #0,$50F9
    move.b  #10,$50FA
    move.b  #3,$50E8
    move.b  #7,$50E9
    move.b  #6,$50EA
    
    move.b  #5,$513B    Right corridor
    move.b  #1,$512B
    move.b  #1,$511B
    move.b  #8,$510B    Path continues up with a turn off to the right
    
    move.b  #2,$510C    Right path
    move.b  #2,$510D    Continue right
    move.b  #5,$510E    Path upwards and to the left
    move.b  #1,$50FE    Leads upwards into a room
    
    move.b  #4,$50ED    First monster room
    move.b  #0,$50EE    Entrance
    move.b  #5,$50EF
    move.b  #8,$50DD
    move.b  #0,$50DE
    move.b  #10,$50DF
    move.b  #3,$50CD
    move.b  #7,$50CE
    move.b  #6,$50CF
    
    move.b  #1,$50FB    Path that continues up
    move.b  #1,$50EB    Path continues upwards
    move.b  #1,$50DB
    
    *Bottom row of room
    move.b  #4,$50C8    Large monster room with locked door
    move.b  #9,$50C9
    move.b  #9,$50CA
    move.b  #0,$50CB    Entrance
    move.b  #5,$50CC
    *Middle row of room
    move.b  #0,$50B8    Exit to the left
    move.b  #0,$50B9
    move.b  #0,$50BA
    move.b  #0,$50BB
    move.b  #10,$50BC
    *Top row of room
    move.b  #3,$50A8
    move.b  #7,$50A9
    move.b  #7,$50AA
    move.b  #7,$50AB    Locked door
    move.b  #6,$50AC
    
    move.b  #2,$50B7    Exit large room leftwards
    move.b  #2,$50B6    Continue to the left
    move.b  #7,$50B5    Continue to the left and a path downwards
    move.b  #2,$50B4    Continue to the left
    
    move.b  #3,$50A1    Room to the left
    move.b  #7,$50A2
    move.b  #6,$50A3
    move.b  #8,$50B1
    move.b  #0,$50B2
    move.b  #0,$50B3    Entrance to the right
    move.b  #4,$50C1
    move.b  #9,$50C2
    move.b  #5,$50C3
    
    move.b  #1,$50C5    Path leading downwards
    move.b  #1,$50D5
    move.b  #10,$50E5   Path leading downward and to the left
    move.b  #2,$50E4    Path on the left
    move.b  #2,$50E3
    move.b  #3,$50E2    Path takes a turn downwards
    move.b  #1,$50F2    Path continues downwards
    
    move.b  #3,$5101    Regular enemy room
    move.b  #0,$5102    Entrance
    move.b  #6,$5103
    move.b  #8,$5111
    move.b  #0,$5112
    move.b  #10,$5113
    move.b  #4,$5121
    move.b  #9,$5122
    move.b  #10,$5123   Exit at the bottom
    
    move.b  #1,$50F5    Path leading downward
    move.b  #1,$5105
    move.b  #1,$5115
    move.b  #1,$5125
    
    *Top row of room
    move.b  #8,$5133    Large enemy room - Exit at top
    move.b  #7,$5134
    move.b  #0,$5135    Entrance
    move.b  #6,$5136
    
    *Middle row of room
    move.b  #8,$5143
    move.b  #0,$5144
    move.b  #0,$5145
    move.b  #10,$5146
    
    *Bottom row of room
    move.b  #4,$5153
    move.b  #9,$5154
    move.b  #9,$5155
    move.b  #5,$5156
    
    rts

setup_enemies:
    move.b  #1,$6000    Health - Setup the first enemy
    move.b  #1,$6001    Damage/level
    move.b  #1,$6002    Class type (Knight)
    move.b  #1,$6003    Alive state (Alive)
    move.w  #$513A,$6004  Move enemy coordinates
    
    rts
    
    
*-------------------------------------------------------
*-------------------Data Delarations--------------------
*-------------------------------------------------------

crlf:           dc.b    $0D,$0A,0
welcome_msg:    dc.b    '************************************************************'
                dc.b    $0D,$0A
                dc.b    'Avalon: The Legend Lives'
                dc.b    $0D,$0A
                dc.b    '************************************************************'
                dc.b    $0D,$0A,0
potion_msg:     dc.b    'Feed load (each horse needs at least 100 units of feed)'
                dc.b    $0D,$0A
                dc.b    'Enter feed load : ',0
potions_msg:    dc.b    'Number of potions : ',0
weapons_msg:    dc.b    'Each quest need at least 2 Weapons'
                dc.b    $0D,$0A
                dc.b    'minimum requirement is 2 i.e. Sword x 1 and Speer x 1.'
                dc.b    $0D,$0A
                dc.b    'Enter # of weapons : ',0
gameplay_msg:   dc.b    'Add Gameplay !',0
update_msg:     dc.b    'Update Gameplay !',0
draw_msg:       dc.b    'Draw Screen !',0
hit_msg:        dc.b    'Strike!',0
miss_msg:       dc.b    'Miss!',0
loop_msg:       dc.b    '.',0
replay_msg:     dc.b    'Enter 0 to Quit any other number to replay : ',0
hud_msg:        dc.b    'Score : ',0

health:     ds.w    1
score:      ds.w    1 reserve space for score

wake_up_msg:    dc.b    'You awake in a room, on a bed of red velvet, with no memory',$0D,$0A
                dc.b    'of how you got here. You climb from the frame and look in a nearby mirror',$0D,$0A,0
pick_role_msg:  dc.b    '1> You wear armour of polished iron, a short sword and heavy shield laying',$0D,$0A
                dc.b    'close by. (Knight class)',$0D,$0A,$0D,$0A
                dc.b    '2> You wear a cloak with mystic symbols sewn into the fabrics, an ancient',$0D,$0A
                dc.b    'looking staff lays near. (Mage class)',$0D,$0A,$0D,$0A
                dc.b    '3> You wear tight, well-fitting leather armour with reminents of black dye',$0D,$0A
                dc.b    'stained to the material. Two knives are fastened to your belt. (Rogue class)',$0D,$0A,0
input_nums_msg:  dc.b    'Enter num between 1 and ',0
colon_msg:       dc.b    ': ',0

input_error_msg: dc.b    'Inputted number is outside of range.',$0D,$0A,0
fake_gamestate_msg: dc.b    'Gamestate doesnt exist',$0D,$0A,0
knight_role_msg: dc.b    'You pick up your sword, grab a torch from the wall, and leave the room.',$0D,$0A
                dc.b    '- You have chosen the KNIGHT class. You specialise in slow, strong attacks.',$0D,$0A,0
mage_role_msg:   dc.b    'You pick up your staff, grab a torch from the wall, and leave the room.',$0D,$0A
                dc.b    '- You have chosen the MAGE class. You specialise in ranged magic attacks.',$0D,$0A,0
rogue_role_msg:  dc.b    'You fasten your belt, grab a torch from the wall, and leave the room.',$0D,$0A
                dc.b    '- You have chosen the ROGUE class. You specialise in fast, weak attacks.',$0D,$0A,0
movement_msg:    dc.b    '1> Move north.',$0D,$0A
                dc.b    '2> Move south.',$0D,$0A
                dc.b    '3> Move west.',$0D,$0A
                dc.b    '4> Move east.',$0D,$0A,0
move_north_msg:  dc.b    'Moved north.',$0D,$0A,0
move_east_msg:   dc.b    'Moved east.',$0D,$0A,0
move_south_msg:  dc.b    'Moved south.',$0D,$0A,0
move_west_msg:   dc.b    'Moved west.',$0D,$0A,0
movement_blocked_msg:  dc.b    'A wall blocks your path.',$0D,$0A,0
continue_msg:    dc.b    'Enter any key to continue... ',0

blank_tile      dc.b    '   ',0
both_tile       dc.b    '| |',0
left_tile       dc.b    '|  ',0
right_tile      dc.b    '  |',0
blocked_tile    dc.b    '\/\',0
player_mark     dc.b    '*',0
enemy_mark     dc.b    'X',0
encounter_msg:  dc.b    'A monster blocks your path, it looks ready to attack!',$0D,$0A,0
combat_msg:     dc.b    '1> Block and Counter.',$0D,$0A
                dc.b    '2> Cast Magic.',$0D,$0A
                dc.b    '3> Attack Swiftly.',$0D,$0A
                dc.b    '4> Try Run.',$0D,$0A,0
skeleton_msg:   dc.b    '           .-.     ',$0D,$0A
                dc.b    ' /\____/\ (o.o)    ',$0D,$0A
                dc.b    '|  _||_  | |=|     ',$0D,$0A
                dc.b    ' \/ || \/ __|__    ',$0D,$0A
                dc.b    '    ||\_//.=|=.\\  ',$0D,$0A
                dc.b    '    ||\_/ .=|=. \\ ',$0D,$0A
                dc.b    '    ||    .=|=. // ',$0D,$0A
                dc.b    '    ||    (_=_)//  ',$0D,$0A
                dc.b    '    ||   (:| |:)   ',$0D,$0A
                dc.b    '    ||    || ||    ',$0D,$0A
                dc.b    '    ||    () ()    ',$0D,$0A
                dc.b    '    /\    || ||    ',$0D,$0A
                dc.b    '    ||    || ||    ',$0D,$0A
                dc.b    '    \/  ==   ==    ',$0D,$0A,0
escape_msg:             dc.b    'You escaped the monster!',$0D,$0A,0
fail_escape_msg:        dc.b    'You try to run, but the monster catches and damages you!',$0D,$0A,0
both_block_msg:         dc.b    'You both block, No damage is done!',$0D,$0A,0
both_cast_magic_msg:    dc.b    'You both cast magic at eachother, the spells clash in mid air! No damage',$0D,$0A
                        dc.b    'is done!',$0D,$0A,0
both_melee_msg:         dc.b    'You both lunge forward, metal clashes together, but no damage is done!',$0D,$0A,0
hit_against_block_msg:  dc.b    'The enemy blocks, you cast a cast a spell and it damages the monster!',$0D,$0A,0
hit_against_magic_msg:  dc.b    'The enemy begins to charge a spell but you lunge forward and hit it first,',$0D,$0A
                        dc.b    'damaging the monster!',$0D,$0A,0
hit_against_melee_msg:  dc.b    'The enemy lunges forward but you block quicky, then counter, damaging the',$0D,$0A
                        dc.b    'monster!',$0D,$0A,0
hit_by_counter_msg:     dc.b    'You lunge at the enemy but they block before you hit, they swing around quickly',$0D,$0A
                        dc.b    'and damage you!',$0D,$0A,0
hit_by_magic_msg:       dc.b    'You try to block the enemies attack, but they cast a spell that breaks through',$0D,$0A
                        dc.b    'your defense and damages you!',$0D,$0A,0
hit_by_melee_msg:       dc.b    'You try to charge up a spell, but the enemy lunges forward and damages you!',$0D,$0A,0
health_msg:             dc.b    'Health: ',0
enemy_health_msg:       dc.b    'Enemy Health: ',0
torch_msg:              dc.b    'Torch Life: ',0
inventory_msg:          dc.b    'Inventory:',$0D,$0A,0
battle_won_msg:         dc.b    'The monster collapses at your feet. It is dead!',$0D,$0A,0

    end start














*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
