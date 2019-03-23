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
*A5 is used for shops when in shop screen or when looping through them
*A4 occasionally used for displaying the inventory
*D5 is used occasionally for input range
*$5FF0 holds player information
*$6000 to $64F0 holds enemies
*$6500 to $6FE0 holds shops
*$6FE0 to $6FEF Holds locked doors
*$6FF0 to $6FFF Holds big key locked doors
*$7000 to $7500 holds loot
*$8000 to $9000 holds maps

*Enemies:
*Byte:  Name:
*0      Health
*1      Damage/level
*2      enemy type (Knight, mage, rogue)
*3      Alive state (1 == alive, 0 == dead)
*4 & 5  Coordinates

*Player:
*Byte:  Name:
*0      Health
*1      Damage/level
*2      Class (Knight, mage, rogue)
*3      Game state
*4-5+A6 Coordinates
*6-7    Last coordinates
*8      Gold
*9      Potions
*A      Keys
*B      Torch life

*Shops:
*Byte:  Name:
*0-1    Position
*2      Potions
*3      Keys
*4      Torches
*5      Damage increase

*Loot:
*Byte:  Name:
*0-1    Position
*2      Potions
*3      Keys
*4      Torches
*5      Gold
*6      Active State
    
*Game state : 0 = Pick role/intro | 5 = Move around | 6 = Combat | 7 = Shop | 64 = End game
*Class      : 1 corresponds to knight - 2 corresponds to mage - 3 corresponds to rogue


*-------------------------------------------------------
*Validation values to be used, modify as needed
*Add additional validation values as required
*-------------------------------------------------------
exit        EQU 0      used to exit assembly program

* Text display
RED         EQU $000000FF   Red colour value
GREEN       EQU $0000FF00   Green colour value
BLUE        EQU $00FF0000   Blue colour value
WHITE       EQU $00FFFFFF   White colour value
PURPLE      EQU $00F000F0   Purple colour value
GOLD        EQU $0000FFFF   gold colour value
BROWN       EQU $00507090   brown colour value
FONT        EQU $01090000   Font value

* Player
PLAYER      EQU $5FF0       Memory address for player information and health
PLA_DAMAGE  EQU $5FF1       Memory address for player damage value
PLA_CLASS   EQU $5FF2       The memory address for the player class
GAME_STATE  EQU $5FF3       The memory address of the game state
PLA_P_POS   EQU $5FF6       Memory location of the player's previous position
PLA_GOLD    EQU $5FF8       Memory address for player gold
PLA_POTIONS EQU $5FF9       Memory address for player potions
PLA_KEYS    EQU $5FFA       Memory address for player keys
PLA_TORCH   EQU $5FFB       Memory address for player torch life

* Enemy
FIRST_ENEMY EQU $6000       Memory location of the first enemy
ENEMY_MAX   EQU 2           Number of enemies in the game

DAMAGE      EQU 1           The number of bytes to move from the enemy before reaching the damage
CLASS       EQU 2           The number of bytes to move from the enemy before reaching the class
ALIVE       EQU 3           The number of bytes to move from the enemy before reaching the alive state
POSITION    EQU 4           The number of bytes to move from the enemy before reaching the position

* Shop & Loot
FIRST_SHOP  EQU $6500       Memory location of the first shop
SHOP_MAX    EQU 2           Number of shops in the game

S_POTIONS   EQU 2           The number of bytes to move from the shop root before reaching the potions
S_KEYS      EQU 3           The number of bytes to move from the shop root before reaching the keys
S_TORCHES   EQU 4           The number of bytes to move from the shop root before reaching the torches
S_DAMAGE_IN EQU 5           The number of bytes to move from the shop root before reaching the damage increase

FIRST_LOOT  EQU $7000       Memory location of the first loot pile
L_ACTIVE    EQU 6           The number of bytes to move from the loot pile root before reaching the active state

* HUD
CSR_POS_MOVE    EQU $3201   The cursor position to draw the HUD to when in movement state
CSR_POS_BATTLE  EQU $2001   The cursor position to draw the HUD to when in battle state
CSR_POS_SHOP_S  EQU $1801   The cursor position to draw the HUD to when in shop state for shop info
CSR_POS_SHOP_P  EQU $3401   The cursor position to draw the HUD to when in shop state for player info

* Game
WIN_POINT       EQU $8156   The position the player has to get to to win
FIRST_DOOR      EQU $6FE0   The memory location of the first locked door
DOOR_MAX        EQU 1       The number of locked doors in the game
OPEN_DOOR_POS   EQU $1000   The position doors are given when opened

POTION_PRICE    EQU 5       The price in gold for a potion
KEY_PRICE       EQU 15      The price in gold for a key
TORCH_PRICE     EQU 10      The price in gold for a torch
DAMAGE_UP_PRICE EQU 20      The price in gold for a damage upgrade

LIFE_PER_TORCH  EQU 15      The life value each torch has

MAP_START_POINT EQU $8080   The starting coordinates the map draws at
MAP_LENGTH      EQU 15      The number of tiles downwords the map will draw


*Start of Game
start:
    bsr     setup_player
    bsr     setup_world
    bsr     setup_enemies
    bsr     setup_shops
    bsr     setup_loot

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
    lea     knight_role_msg,A1  assign message to address register A1
    move.b  #14,D0              move literal 14 to DO
    trap    #15                 Display the knight message
    
    move.l  #PURPLE,D1          Load the purple colour
    bsr     change_font_colour  Change the font colour
    
    lea     knight_spec_msg,A1  assign message to address register A1
    move.b  #14,D0              move literal 14 to DO
    trap    #15                 Display the knight message
    
    move.l  #WHITE,D1           Load the white colour
    bsr     change_font_colour  Change the font colour
    
    bra     tutorial_intro      Branch to tutorial subroutine

mage_select:
    lea     mage_role_msg,A1    Assign message to address register A1
    move.b  #14,D0              move literal 14 to DO
    trap    #15                 Display the mage message
    
    move.l  #PURPLE,D1          Load the purple colour
    bsr     change_font_colour  Change the font colour
    
    lea     mage_spec_msg,A1    assign message to address register A1
    move.b  #14,D0              move literal 14 to DO
    trap    #15                 Display the mage message
    
    move.l  #WHITE,D1           Load the white colour
    bsr     change_font_colour  Change the font colour
    
    bra     tutorial_intro      Branch to tutorial subroutine

rogue_select:
    lea     rogue_role_msg,A1   Assign message to address register A1
    move.b  #14,D0              move literal 14 to DO
    trap    #15                 Display the rogue message
    
    move.l  #PURPLE,D1          Load the purple colour
    bsr     change_font_colour  Change the font colour
    
    lea     rogue_spec_msg,A1   Assign message to address register A1
    move.b  #14,D0              move literal 14 to DO
    trap    #15                 Display the rogue message
    
    move.l  #WHITE,D1           Load the white colour
    bsr     change_font_colour  Change the font colour
    
    bra     tutorial_intro      Branch to tutorial subroutine
    
tutorial_intro:
    bsr     endl                Break to a new line

    move.l  #RED,D1             Load the purple colour
    bsr     change_font_colour  Change the font colour
    
    lea     tutorial_msg,A1     Load tutorial message to address register A1
    move.b  #14,D0              move literal 14 to DO
    trap    #15                 Display the tutorial message
    
    move.l  #WHITE,D1           Load the white colour
    bsr     change_font_colour  Change the font colour
    
    move.b  #5,GAME_STATE       Change the game state to the movement state
    
    rts
    
*-------------------------------------------------------
*---------Gameplay Input Values Subroutine--------------
*-------------------------------------------------------    
input:
    bsr     endl            Branch to end line subroutine
    bsr     get_cursor_pos  Get the position of the cursor in D3
    
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
    
    move.b  D1,D5           Move the input to D5 for later
    
    move.w  D3,D1           Move the cursor position of the start of the line
    move.b  #11,D0          Move the number literal 11 to D0 for trap command
    trap    #15             Move the cursor back to the start of the line
    
    lea     blank_msg,A1    Load the blank message into A1 to wipe the line blank
    move.b  #14,D0          Move number literal to D0 for trap command
    trap    #15             Display the loaded message
    
    move.b  #11,D0          Move the number literal 11 to D0 for trap command
    trap    #15             Move the cursor back to the start of the line
    
    clr.l   D1              Clear D1 of large values
    move.b  D5,D1           Move the input back to D1
    
manage_input:
    CMP     #1,D1           Check input against minimum value
    BLT     invalid_input   Error if less than 1
    
    CMP     D5,D1           Compare input against max value
    BGT     invalid_input   Error if more than max value
    
    CMP.B   #0,GAME_STATE   Check which state the game is in
    BEQ     role_input      Branch to the manage input for the role picking
    
    rts                     Return out of subroutine

invalid_input:
    lea     input_error_msg,A1 assign message to address register A1
    move.b  #14,D0          move literal 14 to DO
    trap    #15             Display the error message
    
    bra     input           Go back to taking input

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

*-------------------------------------------------------
*----------------Update Quest Progress------------------
*  Complete Quest
*------------------------------------------------------- 
update:
    CMP.B   #0,PLAYER           Check if the player health is zero
    BLE     player_dead         Player is dead if health is zero or below
    
    CMP.L   #WIN_POINT,A6       Check if the player is standing on the win point
    BEQ     won_game            Branch to the won game subroutine

    CMP.B   #5,GAME_STATE       Check which state the game is in
    BEQ     movement_checks     Check for enemies and shops if in movement state
    CMP.B   #6,GAME_STATE       Check which state the game is in
    BEQ     enemy_alive_check   Check if enemy is dead if in combat
    
    rts
    
*-------------------------------------------------------
*---------------------Win or Lose----------------------- 
player_dead:
    bsr     endl            Break to new line
    
    lea     death_msg,A1    Load the death message
    move.b  #14,D0          Move byte #14 to D0 for the trap command
    trap    #15             Display the loaded message

    bsr     press_continue  Pause to get input
    bsr     clear_screen    Clear the screen
    bsr     draw_graveyard  Draw a graveyard
    bsr     endl            Break to new line
    move.b  #64,GAME_STATE  Set the game state to end game
    bra     replay          Give the player the option to restart or quit
    
won_game:
    bsr     endl            Break to new line
    
    lea     win_msg,A1      Load the win message
    move.b  #14,D0          Move byte #14 to D0 for the trap command
    trap    #15             Display the loaded message

    bsr     press_continue  Pause to get input
    bsr     clear_screen    Clear the screen
    bsr     endl            Break to new line
    bsr     draw_castle     Draw a castle
    bsr     endl            Break to new line
    move.b  #64,GAME_STATE  Set the game state to end game
    bra     replay          Give the player the option to restart or quit

*-------------------------------------------------------
*--------------------Movement State--------------------- 
movement_checks:
    bsr     manage_torch    Check if the torch life is zero and if damage player if so
    bsr     loot_piles_check Check for loot piles under the player 
    bsr     enemies_check   Check for enemies beside the player
    CMP.B   #5,GAME_STATE   Compare the movement gamestate number with the current gamestate
    BNE     return          Return from the loop if the game is not in the movement state anymore
    bsr     shops_check     Check for shops beside the player
    
    rts

*-------------------Loot pile checks--------------------
loot_piles_check:
    lea     FIRST_LOOT,A5   Load the memory address of the first loot pile
    move.b  #0,D5           Move the starting loot number to D5
    bsr     loot_pile_loop  Loop through all loot piles
    rts                     Return from subroutine
    
loot_pile_loop:
    CMP.B   #ENEMY_MAX,D5   Compare the loot number with the maximum enemy number
    BGE     return          Return from the loop if the current loot number is greater than or equal to the max

    bsr     loot_pile_check Check for a loot pile
    
    add.b   #1,D5           Add to the current loot number
    add.w   #16,A5          Add to the current loot pointer to move to the next loot pile
    bra     loot_pile_loop  Keep looping the loot piles
    
loot_pile_check:
    add.w   #L_ACTIVE,A5    Move to the active state
    CMP.B   #0,(A5)         Check if the loot is active
    sub.w   #L_ACTIVE,A5    Move to the active state
    BEQ     return          Return if not active

    move.w  (A5),D2         Move the loot pile position to D2 for large value comparison
    CMP.L   D2,A6           Check if the player is on a loot pile   
    BEQ     pickup_loot     Pickup the loot
    
    rts     Return if not touching a loot pile
    
pickup_loot:
    bsr     endl                Line break
    
    move.l  #GOLD,D1            Load gold colour
    bsr     change_font_colour  Change the font colour
    
    LEA     pickup_loot_msg,A1  Load the encounter message int A1
    move.b  #14,D0              Move #14 to D0 to display message
    trap    #15                 Display the loaded message
    
    add.w   #S_POTIONS,A5       Move to potions number
    move.b  (A5),D1            Move the loot potions number to D1 and increment
    add.b   D1,PLA_POTIONS      Give the player the number of potions in the loot
    
    LEA     pickup_potion_msg,A1  Load the pickup potions message into A1
    move.b  #14,D0              Move #14 to D0 to display message
    trap    #15                 Display the loaded message
    
    move.w  A5,A4               Move the item number to A4 to draw it
    bsr     draw_item_number    Draw the item number
    bsr     endl                Break to new line
    add.w   #1,A5               Move to the next item in the loot pile
    
    move.b  (A5),D1             Move the key number to D1 and increment
    add.b   D1,PLA_KEYS         Give the player the number of keys in the loot
    
    LEA     pickup_key_msg,A1   Load the pickup key message into A1
    move.b  #14,D0              Move #14 to D0 to display message
    trap    #15                 Display the loaded message
    
    move.w  A5,A4               Move the item number to A4 to draw it
    bsr     draw_item_number    Draw the item number
    bsr     endl                Break to new line
    add.w   #1,A5               Move to the next item in the loot pile
    
    move.b  (A5),D1             Move the torch number to D1 and increment
    add.b   D1,PLA_TORCH        Give the player the number of torches in the loot
    
    LEA     pickup_torch_msg,A1 Load the pickup torch message into A1
    move.b  #14,D0              Move #14 to D0 to display message
    trap    #15                 Display the loaded message
    
    move.w  A5,A4               Move the item number to A4 to draw it
    bsr     draw_item_number    Draw the item number
    bsr     endl                Break to new line
    add.w   #1,A5               Move to the next item in the loot pile
    
    move.b  (A5),D1             Move the torch number to D1 and increment
    add.b   D1,PLA_GOLD         Give the player the number of gold in the loot
    
    LEA     pickup_gold_msg,A1  Load the pickup gold message int A1
    move.b  #14,D0              Move #14 to D0 to display message
    trap    #15                 Display the loaded message
    
    move.w  A5,A4               Move the item number to A4 to draw it
    bsr     draw_item_number    Draw the item number
    bsr     endl                Break to new line
    add.w   #1,A5               Move to the next item in the loot pile
    
    move.b  #0,(A5)             Set the loot to not active
    sub.w   #L_ACTIVE,A5        Move to active state
    
    move.l  #WHITE,D1           Load the white colour
    bsr     change_font_colour  Change the font colour
    
    bsr     press_continue      Wait for user input
    bsr     draw_hud            Re-draw the hud
    
    rts

*---------------------Manage Torch----------------------
manage_torch:
    CMP.B   #0,PLA_TORCH    Compare the torch life with zero
    BGT     return          Return if the torch life is greater than zero
    
    sub.b   #1,PLAYER       Remove one health from the player
    
    bsr     endl            Break to new line
    
    move.l  #RED,D1
    bsr     change_font_colour  Change the font colour
    
    lea     no_torch_msg,A1 Load the no torch message into A1
    move.b  #14,D0          Move the number literal 14 into D0 for trap command
    trap    #15             Display the loaded message
    
    move.l  #WHITE,D1
    bsr     change_font_colour  Change the font colour
    
    rts                     Return from the subroutine

*--------------------Enemy Checking--------------------- 
enemies_check:
    lea     FIRST_ENEMY,A5  Load the memory address of the first enemy
    move.b  #0,D5           Move the starting enemy number to D5
    bsr     enemies_loop    Loop through all enemies
    rts                     Return from subroutine
    
enemies_loop:
    CMP.B   #ENEMY_MAX,D5   Compare the enemy number with the maximum enemy number
    BGE     return          Return from the loop if the current enemy number is greater than or equal to the max

    bsr     enemy_check     Check for an enemy
    
    CMP.B   #5,GAME_STATE   Compare the movement gamestate number with the current gamestate
    BNE     return          Return from the loop if the game is not in the movement state anymore
    
    add.b   #1,D5           Add to the current enemy number
    add.w   #12,A5          Add to the current enemy pointer to move to the next enemy (16 for next enemy - 4 to get back from position)
    bra     enemies_loop    Keep looping the enemies
    

enemy_check:
    add.w   #ALIVE,A5       Move into enemy information to check if its alive
    CMP.B   #0,(A5)+        Check if the enemy is alive
    BEQ     return          Return from the check if the enemy is dead
    
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
      
*--------------------Shop Checking----------------------
shops_check:
    lea     FIRST_SHOP,A5   Load the memory address of the first shop
    move.b  #0,D5           Move the starting shop number to D5
    bsr     shops_loop      Loop through all shops
    rts                     Return from subroutine
    
shops_loop:
    CMP.B   #SHOP_MAX,D5    Compare the shop number with the maximum shop number
    BGE     return          Return from the loop if the current shop number is greater than or equal to the max
    
    bsr     shop_check      Check for a shop
    
    CMP.B   #5,GAME_STATE   Compare the movement gamestate number with the current gamestate
    BNE     return          Return from the loop if the game is not in the movement state anymore
    
    add.b   #1,D5           Add to the current shop number
    add.w   #16,A5          Add to the current shop pointer to move to the next shop
    bra     shops_loop      Keep looping the shops
    
shop_check:    
    move.w  A6,D2           Move the player position to D2
    
    *Check if the player is beside a shop
    sub.w   #16,D2          Check north
    CMP.W   (A5),D2           
    BEQ     enter_shop      The player enters a shop
    
    add.w   #32,D2          Check south
    CMP.W   (A5),D2           
    BEQ     enter_shop      The player enters a shop
    
    sub.w   #17,D2          Check west
    CMP.W   (A5),D2           
    BEQ     enter_shop      The player enters a shop
    
    add.w   #2,D2           Check east
    CMP.W   (A5),D2           
    BEQ     enter_shop      The player enters a shop
    
    rts     Return if not touching a shop
    
enter_shop:
    move.b  #7,GAME_STATE       Move to shop game state
    
    bsr     endl                Line break
    
    LEA     shop_enter_msg,A1   Load the encounter message int A1
    move.b  #14,D0              Move #14 to D0 to display message
    trap    #15                 Display the loaded message
    
    bsr     press_continue      Branch to the press to continue subroutine
    
    bsr     clear_screen        Clear the screen
    
    bsr     draw_merchant       Draw the merchant
    bsr     draw_shop_info      Draw the info
    
    rts

*-------------------------------------------------------
*---------------------Combat State---------------------- 
enemy_alive_check:
    CMP.B   #0,(A5)     Compare the enemy health with zero
    BLE     enemy_died  If the enemy health is zero or below, they died
    
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
    CMP.B   #7,GAME_STATE   Check which state the game is in
    BEQ     draw_merchant   If in the shop state, draw the enemy
    rts
    
draw_skeleton:
    lea     skeleton_msg,A1 Load the skeleton message
    move.b  #14,D0          Move literal 14 for display message trap command
    trap    #15             Display the loaded message
    
    rts
    
draw_graveyard:
    lea     graveyard_msg,A1 Load the graveyard message
    move.b  #14,D0           Move literal 14 for display message trap command
    trap    #15              Display the loaded message
    rts                      Return from the subroutine

draw_castle:
    lea     castle_msg,A1   Load the castle message
    move.b  #14,D0          Move literal 14 for display message trap command
    trap    #15             Display the loaded message
    rts                     Return from the subroutine
    
draw_merchant:
    lea     merchant_msg,A1  Load the merchant message
    move.b  #14,D0           Move literal 14 for display message trap command
    trap    #15              Display the loaded message
    
    rts
    
draw_hud:
    CMP.B   #5,GAME_STATE       Check which state the game is in
    BEQ     draw_player_info    If in the movement state, draw the player info
    CMP.B   #6,GAME_STATE       Check which state the game is in
    BEQ     draw_battle_info    If in the combat state, draw the combat info
    CMP.B   #7,GAME_STATE       Check which state the game is in
    BEQ     draw_shop_info      If in the shop state, draw the shop info
    
    rts

draw_player_info:
    move.w  #255,D1         Move the word #255 to D1 to set the type of trap 11
    move.b  #11,D0          Move the byte #11 to D0 for trap command 11
    trap    #15             Trap to get the cursor position in D1
    
    move.w  D1,D3           Move the current cursor position to D3 for later
    
    * Display the player health
    move.w  #CSR_POS_MOVE,D1           
    trap    #15             Set the cursor position with trap command 11
    clr     D1              Clear D1 of the cursor position
    
    lea     health_msg,A1   Load the hud message
    move.b  #14,D0          Move literal 14 for display message trap command
    trap    #15             Display the loaded message
    
    move.b  PLAYER,D1       Move the player health value to D1 to display
    move.b  #3,D0           Move literal 3 for display number trap command
    trap    #15             Display the number in D1
    
    * Display the torch life
    move.b  #11,D0          Move the byte #11 to D0 for trap command 11
    move.w  #CSR_POS_MOVE,D1         
    add.w   #1,D1  
    trap    #15             Set the cursor position with trap command 11
    clr     D1              Clear D1 of the cursor position
    
    lea     torch_msg,A1   Load the hud message
    move.b  #14,D0          Move literal 14 for display message trap command
    trap    #15             Display the loaded message
    
    move.b  PLA_TORCH,D1    Move the player torch life value to D1 to display
    move.b  #3,D0           Move literal 3 for display number trap command
    trap    #15             Display the number in D1
    
    * Display the inventory
    move.b  #11,D0          Move the byte #11 to D0 for trap command 11
    move.w  #CSR_POS_MOVE,D1
    add.w   #2,D1          
    trap    #15             Set the cursor position with trap command 11
    clr     D1              Clear D1 of the cursor position
    
    lea     inventory_msg,A1   Load the hud message
    move.b  #14,D0          Move literal 14 for display message trap command
    trap    #15             Display the loaded message
    
    * Display the player gold
    move.b  #11,D0          Move the byte #11 to D0 for trap command 11
    move.w  #CSR_POS_MOVE,D1         
    add.w   #3,D1  
    trap    #15             Set the cursor position with trap command 11
    clr     D1              Clear D1 of the cursor position
    
    lea     gold_msg,A1   Load the hud message
    move.b  #14,D0          Move literal 14 for display message trap command
    trap    #15             Display the loaded message
    
    lea     PLA_GOLD,A4
    bsr     draw_item_number
    
    * Display the player potions
    move.b  #11,D0          Move the byte #11 to D0 for trap command 11
    move.w  #CSR_POS_MOVE,D1         
    add.w   #4,D1  
    trap    #15             Set the cursor position with trap command 11
    clr     D1              Clear D1 of the cursor position
    
    lea     potions_msg,A1   Load the hud message
    move.b  #14,D0          Move literal 14 for display message trap command
    trap    #15             Display the loaded message
    
    lea     PLA_POTIONS,A4
    bsr     draw_item_number
    
    * Display the player keys
    move.b  #11,D0          Move the byte #11 to D0 for trap command 11
    move.w  #CSR_POS_MOVE,D1         
    add.w   #5,D1  
    trap    #15             Set the cursor position with trap command 11
    clr     D1              Clear D1 of the cursor position
    
    lea     key_msg,A1   Load the hud message
    move.b  #14,D0          Move literal 14 for display message trap command
    trap    #15             Display the loaded message
    
    lea     PLA_KEYS,A4
    bsr     draw_item_number
    
    bsr     draw_map_legend Draw the map legend
    
    move.w  D3,D1           Move the previos cursor position to D1 to put it back in place
    
    move.b  #11,D0          Move the byte #11 to D0 for trap command 11          
    trap    #15             Set the cursor position with trap command 11
    
    clr     D1              Clear D1 for later use
    
    rts
    
draw_map_legend:
    * Display the legend message
    move.b  #11,D0          Move the byte #11 to D0 for trap command 11
    move.w  #CSR_POS_MOVE,D1    Get the base cursor position    
    add.w   #8,D1           Move down rows
    trap    #15             Set the cursor position with trap command 11
    
    move.b  #14,D0          Move literal 14 for display message trap command
    lea     map_legend_msg,A1 Load the message into A1
    trap    #15             Display the loaded message
    
    * Display the player mark
    move.b  #11,D0          Move the byte #11 to D0 for trap command 11
    move.w  #CSR_POS_MOVE,D1    Get the base cursor position    
    add.w   #9,D1           Move down rows
    trap    #15             Set the cursor position with trap command 11
    
    move.l  #GREEN,D1       Load the colour green to D1
    bsr     change_font_colour  Change the font colour
    
    move.b  #14,D0          Move literal 14 for display message trap command
    lea     player_mark,A1  Load the message into A1
    trap    #15             Display the loaded message
    lea     map_player_msg,A1 Load the message into A1
    trap    #15             Display the loaded message
    
    * Display the enemy mark
    move.b  #11,D0          Move the byte #11 to D0 for trap command 11
    move.w  #CSR_POS_MOVE,D1    Get the base cursor position    
    add.w   #10,D1           Move down rows
    trap    #15             Set the cursor position with trap command 11
    
    move.l  #RED,D1         Load the colour red to D1
    bsr     change_font_colour  Change the font colour
    
    move.b  #14,D0          Move literal 14 for display message trap command
    lea     enemy_mark,A1   Load the message into A1
    trap    #15             Display the loaded message
    lea     map_enemy_msg,A1 Load the message into A1
    trap    #15             Display the loaded message
    
    * Display the win point mark
    move.b  #11,D0          Move the byte #11 to D0 for trap command 11
    move.w  #CSR_POS_MOVE,D1    Get the base cursor position    
    add.w   #11,D1          Move down rows
    trap    #15             Set the cursor position with trap command 11
    
    move.l  #BLUE,D1       Load the colour blue to D1
    bsr     change_font_colour  Change the font colour
    
    move.b  #14,D0          Move literal 14 for display message trap command
    lea     win_point_mark,A1   Load the message into A1
    trap    #15             Display the loaded message
    lea     map_win_point_msg,A1 Load the message into A1
    trap    #15             Display the loaded message
   
    * Display the shop mark
    move.b  #11,D0          Move the byte #11 to D0 for trap command 11
    move.w  #CSR_POS_MOVE,D1    Get the base cursor position    
    add.w   #12,D1          Move down rows
    trap    #15             Set the cursor position with trap command 11
    
    move.l  #PURPLE,D1      Load the colour purple to D1
    bsr     change_font_colour  Change the font colour
    
    move.b  #14,D0          Move literal 14 for display message trap command
    lea     shop_mark,A1   Load the message into A1
    trap    #15             Display the loaded message
    lea     map_shop_msg,A1 Load the message into A1
    trap    #15             Display the loaded message
    
    * Display the loot mark
    move.b  #11,D0          Move the byte #11 to D0 for trap command 11
    move.w  #CSR_POS_MOVE,D1    Get the base cursor position    
    add.w   #13,D1          Move down rows
    trap    #15             Set the cursor position with trap command 11
    
    move.l  #GOLD,D1       Load the colour gold to D1
    bsr     change_font_colour  Change the font colour
    
    move.b  #14,D0          Move literal 14 for display message trap command
    lea     loot_mark,A1    Load the message into A1
    trap    #15             Display the loaded message
    lea     map_loot_msg,A1 Load the message into A1
    trap    #15             Display the loaded message
    
    * Display the door mark
    move.b  #11,D0          Move the byte #11 to D0 for trap command 11
    move.w  #CSR_POS_MOVE,D1    Get the base cursor position    
    add.w   #14,D1          Move down rows
    trap    #15             Set the cursor position with trap command 11
    
    move.l  #BROWN,D1       Load the colour brown to D1
    bsr     change_font_colour  Change the font colour
    
    move.b  #14,D0          Move literal 14 for display message trap command
    lea     door_mark,A1    Load the message into A1
    trap    #15             Display the loaded message
    lea     map_door_msg,A1 Load the message into A1
    trap    #15             Display the loaded message
    
    move.l  #WHITE,D1       Load the colour brown to D1
    bsr     change_font_colour  Change the font colour
    
    rts                     Return from subroutine
    
draw_item_number:
    move.b  #14,D0          Move literal 3 for display number trap command
    lea     bracket_open_msg,A1
    trap    #15

    move.b  #3,D0           Move literal 3 for display number trap command
    move.b  (A4),D1         Move the value in the register A4 to D1 to display
    trap    #15             Display the number in D1
    
    move.b  #14,D0          Move literal 3 for display number trap command
    lea     bracket_close_msg,A1
    trap    #15
    rts
    

draw_battle_info:
    move.w  #255,D1         Move the word #255 to D1 to set the type of trap 11
    move.b  #11,D0          Move the byte #11 to D0 for trap command 11
    trap    #15             Trap to get the cursor position in D1
    
    move.w  D1,D3           Move the current cursor position to D3 for later
    
    * Move cursor to draw player info
    move.w  #CSR_POS_BATTLE,D1           
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
    move.w  #CSR_POS_BATTLE,D1
    add.w   #1,D1
    trap    #15             Set the cursor position with trap command 11
    clr     D1              Clear D1 of the cursor position
    
    lea     enemy_health_msg,A1 Load the hud message
    move.b  #14,D0              Move literal 14 for display message trap command
    trap    #15                 Display the loaded message
    
    move.b  (A5),D1         Move the enemy health value to D1 to display
    move.b  #3,D0           Move literal 3 for display number trap command
    trap    #15             Display the number in D1
    
    * Move the cursor to draw potion information
    move.b  #11,D0          Move the byte #11 to D0 for trap command 11
    move.w  #CSR_POS_BATTLE,D1
    add.w   #3,D1
    trap    #15             Set the cursor position with trap command 11
    clr     D1              Clear D1 of the cursor position
    
    lea     potions_msg,A1   Load the hud message
    move.b  #14,D0          Move literal 14 for display message trap command
    trap    #15             Display the loaded message
    
    lea     PLA_POTIONS,A4
    bsr     draw_item_number
    
    * Move the cursor back to its previous position
    move.w  D3,D1           Move the previous cursor position back to D1
    move.b  #11,D0          Move the byte #11 to D0 for trap command 11          
    trap    #15             Set the cursor position with trap command 11
    
    clr     D1              Clear D1 for later use
    
    rts
    
draw_shop_info:
    move.w  #255,D1         Move the word #255 to D1 to set the type of trap 11
    move.b  #11,D0          Move the byte #11 to D0 for trap command 11
    trap    #15             Trap to get the cursor position in D1
    
    move.w  D1,D3           Move the current cursor position to D3 for later
    
    * Move cursor to draw shop info
    move.w  #CSR_POS_SHOP_S,D1           
    trap    #15             Set the cursor position with trap command 11
    clr     D1              Clear D1 of the cursor position
    
    lea     shop_stock_msg,A1   Load the hud message
    move.b  #14,D0          Move literal 14 for display message trap command
    trap    #15             Display the loaded message
    
    
    * Display the shop's potions
    move.b  #11,D0          Move the byte #11 to D0 for trap command 11
    move.w  #CSR_POS_SHOP_S,D1         
    add.w   #1,D1  
    trap    #15             Set the cursor position with trap command 11
    clr     D1              Clear D1 of the cursor position
    
    lea     potions_msg,A1   Load the hud message
    move.b  #14,D0          Move literal 14 for display message trap command
    trap    #15             Display the loaded message
    
    add.w   #S_POTIONS,A5
    lea     (A5),A4
    bsr     draw_item_number
    
    * Display the shop's keys
    move.b  #11,D0          Move the byte #11 to D0 for trap command 11
    move.w  #CSR_POS_SHOP_S,D1         
    add.w   #2,D1  
    trap    #15             Set the cursor position with trap command 11
    clr     D1              Clear D1 of the cursor position
    
    lea     key_msg,A1      Load the hud message
    move.b  #14,D0          Move literal 14 for display message trap command
    trap    #15             Display the loaded message
    
    add.w   #1,A5
    lea     (A5),A4
    bsr     draw_item_number
    
    * Display the shop's torches
    move.b  #11,D0          Move the byte #11 to D0 for trap command 11
    move.w  #CSR_POS_SHOP_S,D1         
    add.w   #3,D1  
    trap    #15             Set the cursor position with trap command 11
    clr     D1              Clear D1 of the cursor position
    
    lea     torches_msg,A1  Load the torches message
    move.b  #14,D0          Move literal 14 for display message trap command
    trap    #15             Display the loaded message
    
    add.w   #1,A5
    lea     (A5),A4
    bsr     draw_item_number
    
    * Display the shop's damage upgrades
    move.b  #11,D0          Move the byte #11 to D0 for trap command 11
    move.w  #CSR_POS_SHOP_S,D1         
    add.w   #4,D1  
    trap    #15             Set the cursor position with trap command 11
    clr     D1              Clear D1 of the cursor position
    
    lea     damage_up_msg,A1 Load the damage upgrades message
    move.b  #14,D0           Move literal 14 for display message trap command
    trap    #15              Display the loaded message
    
    add.w   #1,A5               Increment A5 to get to the damage upgrades
    lea     (A5),A4             Load the memory address in A5 to A4
    bsr     draw_item_number    Draw the number of items
    sub.w   #S_DAMAGE_IN,A5     Bring the pointer back to the root of the shop
    
    * Display the inventory
    move.b  #11,D0          Move the byte #11 to D0 for trap command 11
    move.w  #CSR_POS_SHOP_P,D1       
    trap    #15             Set the cursor position with trap command 11
    clr     D1              Clear D1 of the cursor position
    
    lea     inventory_msg,A1   Load the hud message
    move.b  #14,D0          Move literal 14 for display message trap command
    trap    #15             Display the loaded message
    
    * Display the player gold
    move.b  #11,D0          Move the byte #11 to D0 for trap command 11
    move.w  #CSR_POS_SHOP_P,D1         
    add.w   #1,D1  
    trap    #15             Set the cursor position with trap command 11
    clr     D1              Clear D1 of the cursor position
    
    lea     gold_msg,A1   Load the hud message
    move.b  #14,D0          Move literal 14 for display message trap command
    trap    #15             Display the loaded message
    
    lea     PLA_GOLD,A4
    bsr     draw_item_number
    
    * Display the player potions
    move.b  #11,D0          Move the byte #11 to D0 for trap command 11
    move.w  #CSR_POS_SHOP_P,D1         
    add.w   #2,D1  
    trap    #15             Set the cursor position with trap command 11
    clr     D1              Clear D1 of the cursor position
    
    lea     potions_msg,A1   Load the hud message
    move.b  #14,D0          Move literal 14 for display message trap command
    trap    #15             Display the loaded message
    
    lea     PLA_POTIONS,A4
    bsr     draw_item_number
    
    * Display the player keys
    move.b  #11,D0          Move the byte #11 to D0 for trap command 11
    move.w  #CSR_POS_SHOP_P,D1         
    add.w   #3,D1  
    trap    #15             Set the cursor position with trap command 11
    clr     D1              Clear D1 of the cursor position
    
    lea     key_msg,A1   Load the hud message
    move.b  #14,D0          Move literal 14 for display message trap command
    trap    #15             Display the loaded message
    
    lea     PLA_KEYS,A4
    bsr     draw_item_number
    
    * Display the torch life
    move.b  #11,D0          Move the byte #11 to D0 for trap command 11
    move.w  #CSR_POS_SHOP_P,D1
    add.w   #5,D1       
    trap    #15             Set the cursor position with trap command 11
    clr     D1              Clear D1 of the cursor position
    
    lea     torch_msg,A1   Load the hud message
    move.b  #14,D0          Move literal 14 for display message trap command
    trap    #15             Display the loaded message
    
    move.b  PLA_TORCH,D1    Move the player torch life value to D1 to display
    move.b  #3,D0           Move literal 3 for display number trap command
    trap    #15             Display the number in D1
    
    * Display the player's damage level
    move.b  #11,D0          Move the byte #11 to D0 for trap command 11
    move.w  #CSR_POS_SHOP_P,D1
    add.w   #6,D1       
    trap    #15             Set the cursor position with trap command 11
    clr     D1              Clear D1 of the cursor position
    
    lea     damage_lvl_msg,A1   Load the damage level message
    move.b  #14,D0              Move literal 14 for display message trap command
    trap    #15                 Display the loaded message
    
    move.b  PLA_DAMAGE,D1   Move the player's damage level to D1 to display
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
    bsr     endl            Break to a new line
    CMP.B   #0,GAME_STATE   Check which stage the game is in
    BEQ     pick_role       Branch to the pick role subroutine
    CMP.B   #5,GAME_STATE   Check which stage the game is in
    BEQ     movement        Branch to the movement subroutine
    CMP.B   #6,GAME_STATE   Check which stage the game is in
    BEQ     combat          branch to the combat subroutine
    CMP.B   #7,GAME_STATE   Check which stage the game is in
    BEQ     shop            branch to the shop subroutine
    rts                     Return from 'gameplay' subroutine

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
    lea     replay_msg,A1   Load the Replay message
    move.b  #14,D0          Move the number literal 14 to D0 for trap command
    trap    #15             Display the loaded message
    
    move.b  #2,D5           Move the number of input options to D5
    bsr     input           Take user input
    move.b  D1,D2           Move the input to D2 so it's not trampled by the clear screen
    
    bsr     clear_screen    Clear the screen
    
    cmp.b   #1,D2           Compare the user input against the two options
    beq     start           Restart if the user enters 1
    bsr     end             Quit if the user enters 2

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

    move.l  #5,D5           Move the number 4 to D5 to tell the program how many options there are
    
    bsr     input           branch to the input subroutine
    bsr     wall_collisions Branch to check wall collisions and movement
    
    CMP.B   #5,D1           Check the input against taking a potion
    BEQ     take_potion     Branch to take a potion
    
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
    
    bsr     check_blocked       Check if the player is in a door
    bsr     decrement_torch     Remove one from the player's torch life

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
    
    bsr     check_blocked       Check if the player is in a door
    bsr     decrement_torch     Remove one from the player's torch life
    
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
    
    bsr     check_blocked       Check if the player is in a door
    bsr     decrement_torch     Remove one from the player's torch life
    
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
    
    move.w  A6,PLA_P_POS        Move the player's previous location to a memory address for storage
    add     #1,A6               Move the player east
    
    bsr     check_blocked       Check if the player is in a door
    bsr     decrement_torch     Remove one from the player's torch life
    
    rts

movement_blocked:
    lea     movement_blocked_msg,A1 Load the message
    move.b  #14,D0                  Move the trap command to display a message
    trap    #15                     Display the movement blocked message
    bsr     press_continue          Pause the game until a key is pressed
    
    rts                             Return from the subroutine
    
check_blocked:
    lea     FIRST_DOOR,A5   Load the memory address of the first door
    move.b  #0,D7           Move the starting door number to D5
    bsr     loop_thru_doors Loop through all doors
    rts                     Return from subroutine
    
loop_thru_doors:
    bsr     check_for_a_door  Check for a door
    
    CMP.B   #DOOR_MAX,D5    Compare the door number with the maximum door number
    BGE     return          Return from the loop if the current door number is greater than or equal to the max
    
    add.b   #1,D7           Add to the current door number
    add.w   #2,A5           Add to the current door pointer to move to the next door
    bra     loop_thru_doors Keep looping the doors

check_for_a_door:
    move.w  (A5),D3         Move the door coordinates into data register D3 for large-value comparisons
    CMP.L   D3,A6           Check if the door is in the current position
    BEQ     in_a_door       Collide with the door if it is
    rts                     Return if the door is not in the current position
    
in_a_door:
    CMP.B   #0,PLA_KEYS     Check if the player has keys left
    BLE     blocked_door    If the player has no keys they're blocked
    
    lea     locked_door_msg,A1  Load the locked door message
    move.b  #14,D0          Move the number literal for trap command
    trap    #15             Display the loaded message
    
    move.b  #2,D5           Move the number of input options
    bsr     input           Take user input
    
    CMP.B   #1,D1           Compare the user input with num 1
    BEQ     unlock_door     Unlock the door if the user chooses to
    BNE     blocked_door    Branch to blocked door if the player doesn't unlock the door
    
unlock_door:
    lea     unlocked_door_msg,A1  Load the unlocked door message
    move.b  #14,D0          Move the number literal for trap command
    trap    #15             Display the loaded message
    
    move.w  #OPEN_DOOR_POS,(A5) Move the door position out of the game for an open door
    sub.b   #1,PLA_KEYS     Remove a key from the player
    bsr     press_continue  Wait for player input
    
    rts                     Return from subroutine

blocked_door:
    lea     blocked_door_msg,A1  Load the blocked door message
    move.b  #14,D0          Move the number literal for trap command
    trap    #15             Display the loaded message
    
    move.w  PLA_P_POS,D3    Move the previous player position to D3
    move.l  D3,A6           Move the player to their previous position
    
    bsr     press_continue  Wait for player input
    
    rts                     Return from subroutine
    
*-------------------------------------------------------
*---------------------Manage Combat---------------------
*-------------------------------------------------------
combat:
    bsr endl                Break to a new line

    lea     combat_msg,A1   Load the combat message
    move.b  #14,D0          Move literal 14 for display message trap command
    trap    #15             Display the loaded message

    move.l  #5,D5           Move the number 4 to D5 to tell the program how many options there are
    bsr     input           branch to the input subroutine
    move.b  D1,D4           Move the input to D4 for later use
    
    CMP.B   #1,D1           Compare input with number literal 1
    BEQ     block_counter   Branch to block/counter subroutine
    CMP.B   #2,D1           Compare input with number literal 2
    BEQ     cast_magic      Branch to cast magic subroutine
    CMP.B   #3,D1           Compare input with number literal 3
    BEQ     melee_attack    Branch to melee subroutine
    CMP.B   #4,D1           Compare input with number literal 4
    BEQ     try_run         Branch to try run subroutine
    CMP.B   #5,D1           Compare input with number literal 5
    BEQ     take_potion     Branch to take potion subroutine
    
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
    bsr     random_number       Get a random number
    
    CMP.W   #40,D2              Compare the random number to 40
    BLT     escape_attack       If the random number is less than 40 the player escapes
    BGE     fail_escape         If the random number is more than 40 the player gets damaged
    
escape_attack:
    move.w  PLA_P_POS,D3    Move the player's previous position to D3 to avoid treating it as a negative number
    move.l  D3,A6           Move the player to their position before entering the battle
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
    
    add.w   #DAMAGE,A5           Move the enemy pointer to its damage value
    move.b  (A5),D5             Store the damage value in D5
    sub.w   #DAMAGE,A5           Move the enemy pointer back to the enemy health/root
    sub.b   D5,PLAYER           Remove the enemy's damage from the player's health
    
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
    
    bsr     damage_enemy    Deal damage to the enemy
    
    bsr     press_continue
    rts

hit_against_magic:
    move.b  #14,D0
    lea     hit_against_magic_msg,A1
    trap    #15
    
    bsr     damage_enemy    Deal damage to the enemy
    
    bsr     press_continue
    rts

hit_against_melee:
    move.b  #14,D0
    lea     hit_against_melee_msg,A1
    trap    #15
    
    bsr     damage_enemy    Deal damage to the enemy
    
    bsr     press_continue
    rts

hit_by_counter:
    move.b  #14,D0
    lea     hit_by_counter_msg,A1
    trap    #15  
    
    move.b  #1,D2               Move the enemy attack type to D2
    bsr     damage_player       Deal damage to the player
    
    bsr     press_continue
    rts

hit_by_magic:
    move.b  #14,D0
    lea     hit_by_magic_msg,A1
    trap    #15  
    
    move.b  #2,D2               Move the enemy attack type to D2
    bsr     damage_player       Deal damage to the player
    
    bsr     press_continue
    rts

hit_by_melee:
    move.b  #14,D0
    lea     hit_by_melee_msg,A1
    trap    #15
    
    move.b  #3,D2               Move the enemy attack type to D2
    bsr     damage_player       Deal damage to the player
    
    bsr     press_continue
    rts
    
damage_enemy:
    move.b  PLA_DAMAGE,D5       Store the player damage value in D5
    CMP.B   PLA_CLASS,D4        Check if the player attack type matches the player class
    BEQ     double_damage_enemy Deal double damage to the enemy if attack type matches the class
    sub.b   D5,(A5)             Remove the player's damage from the enemy's health
    rts                         Return from subroutine
    
double_damage_enemy:
    LSL     #1,D5               Double the player damage
    sub.b   D5,(A5)             Remove double the player's damage from the enemy's health
    
    bsr     endl                Break to new line
    move.l  #PURPLE,D1          Load colour purple
    bsr     change_font_colour  Change the font colour
    
    lea     double_damage_msg,A1    Load the double damage message
    move.b  #14,D0              Move number literal 14 to D0 for trap command
    trap    #15
    
    move.l  #WHITE,D1           Load colour white
    bsr     change_font_colour  Change the font colour
    
    rts                         Return from subroutine

damage_player:
    add.w   #DAMAGE,A5          Move the enemy pointer to its damage value
    move.b  (A5),D5             Store the damage value in D5
    
    sub.w   #DAMAGE,A5          Move the enemy pointer back to the enemy health/root
    add.w   #CLASS,A5           Move the enemy pointer to its class value
    
    CMP.B   (A5),D2             Compare the enemy attack type to its class
    sub.w   #CLASS,A5           Move the enemy pointer back to the enemy health/root
    BEQ     double_damage_player    Deal double damage to the player
    
    sub.b   D5,PLAYER           Remove the enemy's damage from the player's health

    rts                         Return from subroutine
    
double_damage_player:
    LSL     #1,D5               Double the enemy damage
    sub.b   D5,PLAYER           Remove double the enemy's damage from the player's health
    
    bsr     endl                Break to new line
    move.l  #RED,D1          Load colour purple
    bsr     change_font_colour  Change the font colour
    
    lea     double_damage_msg,A1    Load the double damage message
    move.b  #14,D0              Move number literal 14 to D0 for trap command
    trap    #15
    
    move.l  #WHITE,D1           Load colour white
    bsr     change_font_colour  Change the font colour
    
    rts                         Return from subroutine

*-------------------------------------------------------
*----------------------Shop State-----------------------
*-------------------------------------------------------
shop:
    lea     shop_msg,A1     Load the shop message
    move.b  #14,D0          Move the number literal 14 to D0 for trap command
    trap    #15             Display the loaded message

    move.l  #5,D5           Move the number 4 to D5 to tell the program how many options there are
    bsr     input           branch to the input subroutine
    
    CMP.B   #1,D1           Compare input with number literal 1
    BEQ     buy_potion      Branch to buy potion subroutine
    CMP.B   #2,D1           Compare input with number literal 2
    BEQ     buy_key         Branch to buy key subroutine
    CMP.B   #3,D1           Compare input with number literal 3
    BEQ     buy_torch       Branch to buy torch subroutine
    CMP.B   #4,D1           Compare input with number literal 4
    BEQ     upgrade_dmg     Branch to buy damage upgrade subroutine
    CMP.B   #5,D1           Compare input with number literal 5
    BEQ     leave_shop      Branch to leave shop subroutine

    rts                     Return from subroutine
    
buy_potion:
    CMP.B   #POTION_PRICE,PLA_GOLD  Check if the player has money for a potion
    BLT     no_money                If not enough money branch to no money subroutine
    
    add.w   #S_POTIONS,A5           Move the shop pointer to the potions
    CMP.B   #0,(A5)                 Check that the shop still has potions left
    BLE     no_shop_potions         If no potions left branch to no shop potions subroutine
    
    sub.b   #POTION_PRICE,PLA_GOLD  Remove the potion price from the player's gold
    sub.b   #1,(A5)                 Remove one potion from the shop
    add.b   #1,PLA_POTIONS          Add one potion to the player's inventory
    
    sub.w   #S_POTIONS,A5           Move the shop pointer back to root
    
    lea     buy_item_msg,A1         Load the buy item message into A1
    move.b  #14,D0                  Move the number literal 14 to D0 for trap command
    trap    #15                     Display the loaded message
    
    bsr     press_continue          Pause for user input
    
    rts                             Return from subroutine
    
buy_key:
    CMP.B   #KEY_PRICE,PLA_GOLD     Check if the player has money for a key
    BLT     no_money                If not enough money branch to no money subroutine
    
    add.w   #S_KEYS,A5              Move the shop pointer to the keys
    CMP.B   #0,(A5)                 Check that the shop still has keys left
    BLE     no_shop_keys            If no keys left branch to no shop keys subroutine
    
    sub.b   #KEY_PRICE,PLA_GOLD     Remove the key price from the player's gold
    sub.b   #1,(A5)                 Remove one key from the shop
    add.b   #1,PLA_KEYS             Add one key to the player's inventory
    
    sub.w   #S_KEYS,A5              Move the shop pointer back to root

    lea     buy_item_msg,A1         Load the buy item message into A1
    move.b  #14,D0                  Move the number literal 14 to D0 for trap command
    trap    #15                     Display the loaded message
    
    bsr     press_continue          Pause for user input
    
    rts                             Return from subroutine
    
buy_torch:
    CMP.B   #TORCH_PRICE,PLA_GOLD   Check if the player has money for a torch
    BLT     no_money                If not enough money branch to no money subroutine
    
    add.w   #S_TORCHES,A5           Move the shop pointer to the torches
    CMP.B   #0,(A5)                 Check that the shop still has torches left
    BLE     no_shop_torches         If no torches left branch to no shop torches subroutine
    
    sub.b   #TORCH_PRICE,PLA_GOLD   Remove the torch price from the player's gold
    sub.b   #1,(A5)                 Remove one torch from the shop
    add.b   #LIFE_PER_TORCH,PLA_TORCH           Add ten to the player's torches life
    
    sub.w   #S_TORCHES,A5           Move the shop pointer back to root

    lea     buy_item_msg,A1         Load the buy item message into A1
    move.b  #14,D0                  Move the number literal 14 to D0 for trap command
    trap    #15                     Display the loaded message
    
    bsr     press_continue          Pause for user input
    
    rts                             Return from subroutine
    
upgrade_dmg:
    CMP.B   #DAMAGE_UP_PRICE,PLA_GOLD   Check if the player has money for a damage upgrade
    BLT     no_money                    If not enough money branch to no money subroutine
    
    add.w   #S_DAMAGE_IN,A5         Move the shop pointer to the damage upgrades
    CMP.B   #0,(A5)                 Check that the shop still has damage upgrades left
    BLE     no_shop_damage_up       If no damage upgrades left branch to no shop torches subroutine
    
    sub.b   #DAMAGE_UP_PRICE,PLA_GOLD   Remove the damage upgrade price from the player's gold
    sub.b   #1,(A5)                     Remove one damage upgrade from the shop
    add.b   #1,PLA_DAMAGE               Add one to the player's damage value
    
    sub.w   #S_DAMAGE_IN,A5         Move the shop pointer back to root

    lea     buy_item_msg,A1         Load the buy item message into A1
    move.b  #14,D0                  Move the number literal 14 to D0 for trap command
    trap    #15                     Display the loaded message
    
    bsr     press_continue          Pause for user input
    
    rts                             Return from subroutine
    
leave_shop:
    move.w  PLA_P_POS,D3        Move the player's previous position to D3 to avoid treating it as a negative number
    move.l  D3,A6               Move the player to their position before entering the shop
    move.b  #5,GAME_STATE       Switch game state to movement
    
    lea     leave_shop_msg,A1   Load escape message
    move.b  #14,D0              Move literal for trap command
    trap    #15                 Trap 15 to display messgae
    
    bsr     press_continue      Pause until the player presses to continue
    rts                         Return from subroutine
    
no_money:
    lea     no_money_msg,A1 Load the no money message
    move.b  #14,D0          Move the number literal 14 to D0 for trap command
    trap    #15             Display the loaded message
    
    bsr     press_continue  Wait for player input
    rts                     Return from subroutine
    
no_shop_potions:
    lea     no_item_msg,A1  Load the no money message
    move.b  #14,D0          Move the number literal 14 to D0 for trap command
    trap    #15             Display the loaded message
    sub.w   #S_POTIONS,A5   Move the shop pointer back to root
    
    bsr     press_continue  Wait for player input
    rts                     Return from subroutine
    
no_shop_keys:
    lea     no_item_msg,A1  Load the no money message
    move.b  #14,D0          Move the number literal 14 to D0 for trap command
    trap    #15             Display the loaded message
    sub.w   #S_KEYS,A5      Move the shop pointer back to root
    
    bsr     press_continue  Wait for player input
    rts                     Return from subroutine
    
no_shop_torches:
    lea     no_item_msg,A1  Load the no money message
    move.b  #14,D0          Move the number literal 14 to D0 for trap command
    trap    #15             Display the loaded message
    sub.w   #S_TORCHES,A5   Move the shop pointer back to root
    
    bsr     press_continue  Wait for player input
    rts                     Return from subroutine

no_shop_damage_up:
    lea     no_item_msg,A1  Load the no money message
    move.b  #14,D0          Move the number literal 14 to D0 for trap command
    trap    #15             Display the loaded message
    sub.w   #S_DAMAGE_IN,A5 Move the shop pointer back to root
    
    bsr     press_continue  Wait for player input
    rts                     Return from subroutine

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
    
take_potion:
    CMP.B   #0,PLA_POTIONS      Check if the player has potions to drink
    BLE     no_potions          If the potions are zero or below branch to no_potions
    
    add.b   #3,PLAYER           Add 3 to the player's health
    sub.b   #1,PLA_POTIONS      Remove one potion
    
    lea     take_potion_msg,A1  Load the take potion message
    move.b  #14,D0              Move the number literal 14 to D0 for trap command
    trap    #15                 Display the loaded message
    
    bsr     press_continue      Wait for player input
    
    rts                         Return from subroutine

no_potions:
    lea     no_potions_msg,A1   Load the no potions message
    move.b  #14,D0              Move the number literal 14 to D0 for trap command
    trap    #15                 Display the loaded message
    
    bsr     press_continue      Wait for player input
    
    rts                         Return from subroutine
    
decrement_torch:
    CMP.B   #0,PLA_TORCH    Compare the torch life to 0
    BLE     return          If it's less than or equalt to zero, return
    sub.b   #1,PLA_TORCH    Decrement by one if it's above zero
    rts                     Return from subroutine
    
change_font_colour:        * Changes the font colour to the colour loaded in D1
    move.b  #21,D0      Move #21 to D0 for trap command 21
    move.l  #FONT,D2    Move the font to D2
    trap    #15         Set the colour
    clr.l   D1          Clear D1 for later use
    clr.l   D2          Clear D2 for later use
    rts                 Return from subroutine
    
get_cursor_pos:
    move.w  #255,D1         Move the word #255 to D1 to set the type of trap 11
    move.b  #11,D0          Move the byte #11 to D0 for trap command 11
    trap    #15             Trap to get the cursor position in D1
    
    move.l  D1,D3           Move the value in D1 to D3 for storage
    rts
    
*-------------------------------------------------------
*----------------------Draw loop------------------------
*-------------------------------------------------------
draw_loop:
    lea     MAP_START_POINT,A2     Load starting memory location into A7
    move.b  #0,D6           Data register used for rows
    move.b  #0,D7           Data register used for columns
    move.l  #0,D1           Clear the D1 data register
    
    bsr     loop_rows       Loop for every row
    rts
    
loop_rows:
    CMP     #MAP_LENGTH,D6          Check the rows don't go out of bounds
    BGT     return          If the rows are greater than 22 end the loop
    
    move.b  #0,D7           Reset to column 0
    bsr     loop_columns    Loop for every column
    
    add.b   #1,D6           Add to the rows
    
    bsr     endl            Break to the next line
    bra     loop_rows       Loop through the rows again
    
loop_columns:
    CMP.B   #15,D7              Check the rows don't go out of bounds
    BGT     return              If the rows are greater than 22 end the loop
    
    bsr     draw_tile           Draw the current tile
    bsr     check_for_loot_piles Draw the loot piles if there is one on the current tile
    bsr     check_for_player    Draw the player in the current tile if they're there
    bsr     check_for_enemies   Draw an enemy in the current tile if they is one there
    bsr     check_for_win_point Draw the win point in the current tile if it's there
    bsr     check_for_shops     Draw a shop in the current tile if there is one
    bsr     check_for_doors     Draw a door in the current ile if there is one
    
    add.b   #1,D7               Add to the column count
    add     #1,A2               Move to the next memory location
    bra     loop_columns        Loop the columns again
    
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

*----------------------Draw Loot------------------------
check_for_loot_piles:
    lea     FIRST_LOOT,A5   Load the memory address of the first loot pile
    move.b  #0,D5           Move the starting loot number to D5
    bsr     loop_loot_piles Loop through all loot piles
    rts                     Return from subroutine
    
loop_loot_piles:
    bsr     check_for_loot  Check for a loot pile
    
    CMP.B   #ENEMY_MAX,D5   Compare the enemy number with the maximum loot number
    BGE     return          Return from the loop if the current loot number is greater than or equal to the max
    
    add.b   #1,D5           Add to the current loot number
    add.w   #16,A5          Add to the current loot pointer to move to the next loot pile
    sub.w   #L_ACTIVE,A5    Move to the root
    bra     loop_loot_piles Keep looping the loot piles
    
check_for_loot:
    add.w   #L_ACTIVE,A5    Move to the active state
    CMP.B   #0,(A5)         Return if the loot is not active
    BEQ     return
    sub.w   #L_ACTIVE,A5    Move to the root

    move.w  (A5),D3         Move the enemy coordinates into data register D3 for large-value comparisons
    CMP.L   D3,A2           Check if the enemy is in the current position
    BEQ     draw_loot       Draw the enemy if it is
    add.w   #L_ACTIVE,A5    Move to the active state
    rts                     Return if the enemy is not in the current position
    
draw_loot:
    add.w   #L_ACTIVE,A5    Move to the active state

    move.w  #255,D1         Move the word #255 to D1 to set the type of trap 11
    move.b  #11,D0          Move the byte #11 to D0 for trap command 11
    trap    #15             Trap to get the cursor position in D1
    
    sub.w   #512,D1         Move the cursor back by two columns
    trap    #15             Set the cursor position with trap command 11
    
    move.l  D1,D3           Move the value in D1 to D3 for storage
    
    move.l  #GOLD,D1         Move the colour red to D1
    bsr     change_font_colour  Change the font colour
    
    lea     loot_mark,A1   load the enemy symbol
    move.b  #14,D0          Move #14 to D0 for trap command 14
    trap    #15             Draw the player mark
    
    move.l  #WHITE,D1       Move the colour white to D1
    bsr     change_font_colour  Change the font colour
    
    move.l  D3,D1           Move the value in D3 to D1 for previous cursor position
    
    add.w   #512,D1         Move the cursor position two columns forward
    move.b  #11,D0          Move byte #11 for trap command 11 
    trap    #15             Set the cursor position
    
    rts 

*---------------------Draw Player-----------------------
check_for_player:
    CMP.L   A6,A2
    BEQ     draw_player
    rts
    
draw_player:
    move.w  #255,D1         Move the word #255 to D1 to set the type of trap 11
    move.b  #11,D0          Move the byte #11 to D0 for trap command 11
    trap    #15             Trap to get the cursor position in D1
    
    sub.w   #512,D1         Move the cursor back by two columns
    trap    #15             Set the cursor position with trap command 11
    
    move.l  D1,D3          Move the value in D1 to D3 for storage
    
    move.l  #GREEN,D1       Move the colour green to D1
    bsr     change_font_colour  Change the font colour
    
    lea     player_mark,A1  load the player symbol
    move.b  #14,D0          Move #14 to D0 for trap command 14
    trap    #15             Draw the player mark
    
    move.l  #WHITE,D1       Move the colour white to D1
    bsr     change_font_colour  Change the font colour
    
    move.l  D3,D1           Move the value in D3 to D1 for previous cursor position
    
    add.w   #512,D1         Move the cursor position two columns forward
    move.b  #11,D0          Move byte #11 for trap command 11 
    trap    #15             Set the cursor position
    
    rts
    
*---------------------Draw Enemies----------------------
check_for_enemies:
    lea     FIRST_ENEMY,A5  Load the memory address of the first enemy
    move.b  #0,D5           Move the starting enemy number to D5
    bsr     loop_enemies    Loop through all enemies
    rts                     Return from subroutine
    
loop_enemies:
    bsr     check_for_enemy Check for an enemy
    
    CMP.B   #ENEMY_MAX,D5   Compare the enemy number with the maximum enemy number
    BGE     return          Return from the loop if the current enemy number is greater than or equal to the max
    
    add.b   #1,D5           Add to the current enemy number
    add.w   #12,A5          Add to the current enemy pointer to move to the next enemy (16 for next enemy - 4 to get back from position)
    bra     loop_enemies    Keep looping the enemies
    
check_for_enemy:
    add.w   #ALIVE,A5       Add to the enemy memory address to get the enemy's alive state
    CMP.B   #0,(A5)+        Check if the enemy is alive
    BEQ     return          Return from the subroutine if not
    
    move.w  (A5),D3         Move the enemy coordinates into data register D3 for large-value comparisons
    CMP.L   D3,A2           Check if the enemy is in the current position
    BEQ     draw_enemy      Draw the enemy if it is
    rts                     Return if the enemy is not in the current position
    
draw_enemy:
    move.w  #255,D1         Move the word #255 to D1 to set the type of trap 11
    move.b  #11,D0          Move the byte #11 to D0 for trap command 11
    trap    #15             Trap to get the cursor position in D1
    
    sub.w   #512,D1         Move the cursor back by two columns
    trap    #15             Set the cursor position with trap command 11
    
    move.l  D1,D3          Move the value in D1 to D3 for storage
    
    move.l  #RED,D1         Move the colour red to D1
    bsr     change_font_colour  Change the font colour
    
    lea     enemy_mark,A1   load the enemy symbol
    move.b  #14,D0          Move #14 to D0 for trap command 14
    trap    #15             Draw the player mark
    
    move.l  #WHITE,D1       Move the colour white to D1
    bsr     change_font_colour  Change the font colour
    
    move.l  D3,D1           Move the value in D3 to D1 for previous cursor position
    
    add.w   #512,D1         Move the cursor position two columns forward
    move.b  #11,D0          Move byte #11 for trap command 11 
    trap    #15             Set the cursor position
    
    rts 
 
*----------------------Draw Shops-----------------------
check_for_shops:
    lea     FIRST_SHOP,A5   Load the memory address of the first shop
    move.b  #0,D5           Move the starting shop number to D5
    bsr     loop_shops      Loop through all shops
    rts                     Return from subroutine
    
loop_shops:
    bsr     check_for_shop  Check for a shop
    
    CMP.B   #SHOP_MAX,D5    Compare the shop number with the maximum shop number
    BGE     return          Return from the loop if the current shop number is greater than or equal to the max
    
    add.b   #1,D5           Add to the current shop number
    add.w   #16,A5          Add to the current shop pointer to move to the next shop
    bra     loop_shops      Keep looping the shops
    
check_for_shop:
    move.w  (A5),D3         Move the shop coordinates into data register D3 for large-value comparisons
    CMP.L   D3,A2           Check if the shop is in the current position
    BEQ     draw_shop       Draw the shop if it is
    rts                     Return if the shop is not in the current position
    
draw_shop:
    move.w  #255,D1         Move the word #255 to D1 to set the type of trap 11
    move.b  #11,D0          Move the byte #11 to D0 for trap command 11
    trap    #15             Trap to get the cursor position in D1
    
    sub.w   #512,D1         Move the cursor back by two columns
    trap    #15             Set the cursor position with trap command 11
    
    move.l  D1,D3           Move the value in D1 to D3 for storage
    
    move.l  #PURPLE,D1      Move the colour red to D1
    bsr     change_font_colour  Change the font colour
    
    lea     shop_mark,A1    load the enemy symbol
    move.b  #14,D0          Move #14 to D0 for trap command 14
    trap    #15             Draw the player mark
    
    move.l  #WHITE,D1       Move the colour white to D1
    bsr     change_font_colour  Change the font colour
    
    move.l  D3,D1           Move the value in D3 to D1 for previous cursor position
    
    add.w   #512,D1         Move the cursor position two columns forward
    move.b  #11,D0          Move byte #11 for trap command 11 
    trap    #15             Set the cursor position
    
    rts

*----------------------Draw Doors-----------------------
check_for_doors:
    lea     FIRST_DOOR,A5   Load the memory address of the first door
    move.b  #0,D5           Move the starting door number to D5
    bsr     loop_doors      Loop through all doors
    rts                     Return from subroutine
    
loop_doors:
    bsr     check_for_door  Check for a door
    
    CMP.B   #DOOR_MAX,D5    Compare the door number with the maximum door number
    BGE     return          Return from the loop if the current door number is greater than or equal to the max
    
    add.b   #1,D5           Add to the current door number
    add.w   #2,A5          Add to the current door pointer to move to the next door
    bra     loop_doors      Keep looping the doors
    
check_for_door:
    move.w  (A5),D3         Move the door coordinates into data register D3 for large-value comparisons
    CMP.L   D3,A2           Check if the door is in the current position
    BEQ     draw_door       Draw the door if it is
    rts                     Return if the door is not in the current position
    
draw_door:
    bsr     get_cursor_pos  Get the position of the cursor and save the value to D1 and D3
    
    sub.w   #512,D1         Move the cursor back by two columns
    trap    #15             Set the cursor position with trap command 11
    
    move.l  #BROWN,D1       Move the colour red to D1
    bsr     change_font_colour  Change the font colour
    
    lea     door_mark,A1    load the door symbol
    move.b  #14,D0          Move #14 to D0 for trap command 14
    trap    #15             Draw the door mark
    
    move.l  #WHITE,D1       Move the colour white to D1
    bsr     change_font_colour  Change the font colour
    
    move.l  D3,D1           Move the value in D3 to D1 for previous cursor position
    move.b  #11,D0          Move byte #11 for trap command 11 
    trap    #15             Set the cursor position
    
    rts                     Return from subroutine

*--------------------Draw Win Point---------------------
check_for_win_point:
    CMP.L   #WIN_POINT,A2   Check if the win point is in the current tile
    BEQ     draw_win_point  Branch to draw the win point if so
    rts                     Return from subroutine if not
    
draw_win_point:
    move.w  #255,D1         Move the word #255 to D1 to set the type of trap 11
    move.b  #11,D0          Move the byte #11 to D0 for trap command 11
    trap    #15             Trap to get the cursor position in D1
    
    sub.w   #512,D1         Move the cursor back by two columns
    trap    #15             Set the cursor position with trap command 11
    
    move.l  D1,D3           Move the value in D1 to D3 for storage
    
    move.l  #BLUE,D1        Move the colour blue to D1
    bsr     change_font_colour  Change the font colour
    
    lea     win_point_mark,A1   load the win point symbol
    move.b  #14,D0              Move #14 to D0 for trap command 14
    trap    #15                 Draw the win point mark
    
    move.l  #WHITE,D1       Move the colour white to D1
    bsr     change_font_colour  Change the font colour
    
    move.l  D3,D1           Move the value in D3 to D1 for previous cursor position
    
    add.w   #512,D1         Move the cursor position two columns forward
    move.b  #11,D0          Move byte #11 for trap command 11 
    trap    #15             Set the cursor position
    
    rts
    
*-------------------------------------------------------
*-------------------Setup the world---------------------
*-------------------------------------------------------
setup_world:
    move.b  #14,$814A   Setup the starting corridor
    move.b  #7,$813A    T junction upwards from starting corridor
    move.b  #4,$8139    Left corridor
    move.b  #1,$8129
    move.b  #1,$8119
    
    move.b  #4,$8108    First shop
    move.b  #0,$8109    Entrance
    move.b  #5,$810A
    move.b  #8,$80F8
    move.b  #0,$80F9
    move.b  #10,$80FA
    move.b  #3,$80E8
    move.b  #7,$80E9
    move.b  #6,$80EA
    
    move.b  #5,$813B    Right corridor
    move.b  #1,$812B
    move.b  #1,$811B
    move.b  #8,$810B    Path continues up with a turn off to the right
    
    move.b  #2,$810C    Right path
    move.b  #2,$810D    Continue right
    move.b  #5,$810E    Path upwards and to the left
    move.b  #1,$80FE    Leads upwards into a room
    
    move.b  #4,$80ED    First monster room
    move.b  #0,$80EE    Entrance
    move.b  #5,$80EF
    move.b  #8,$80DD
    move.b  #0,$80DE
    move.b  #10,$80DF
    move.b  #3,$80CD
    move.b  #7,$80CE
    move.b  #6,$80CF
    
    move.b  #1,$80FB    Path that continues up
    move.b  #1,$80EB    Path continues upwards
    move.b  #1,$80DB
    
    *Bottom row of room
    move.b  #4,$80C8    Large monster room with locked door
    move.b  #9,$80C9
    move.b  #9,$80CA
    move.b  #0,$80CB    Entrance
    move.b  #5,$80CC
    *Middle row of room
    move.b  #0,$80B8    Exit to the left
    move.b  #0,$80B9
    move.b  #0,$80BA
    move.b  #0,$80BB
    move.b  #10,$80BC
    *Top row of room
    move.b  #3,$80A8
    move.b  #7,$80A9
    move.b  #7,$80AA
    move.b  #7,$80AB    Locked door
    move.b  #6,$80AC
    
    move.b  #2,$80B7    Exit large room leftwards
    move.b  #2,$80B6    Continue to the left
    move.b  #7,$80B5    Continue to the left and a path downwards
    move.b  #2,$80B4    Continue to the left
    
    move.b  #3,$80A1    Room to the left
    move.b  #7,$80A2
    move.b  #6,$80A3
    move.b  #8,$80B1
    move.b  #0,$80B2
    move.b  #0,$80B3    Entrance to the right
    move.b  #4,$80C1
    move.b  #9,$80C2
    move.b  #5,$80C3
    
    move.b  #1,$80C5    Path leading downwards
    move.b  #1,$80D5
    move.b  #10,$80E5   Path leading downward and to the left
    move.b  #2,$80E4    Path on the left
    move.b  #2,$80E3
    move.b  #3,$80E2    Path takes a turn downwards
    move.b  #1,$80F2    Path continues downwards
    
    move.b  #3,$8101    Regular enemy room
    move.b  #0,$8102    Entrance
    move.b  #6,$8103
    move.b  #8,$8111
    move.b  #0,$8112
    move.b  #10,$8113
    move.b  #4,$8121
    move.b  #9,$8122
    move.b  #10,$8123   Exit at the bottom
    
    move.b  #1,$80F5    Path leading downward
    move.b  #1,$8105
    move.b  #1,$8115
    move.b  #1,$8125
    
    *Top row of room
    move.b  #8,$8133    Large enemy room - Exit at top
    move.b  #7,$8134
    move.b  #0,$8135    Entrance
    move.b  #6,$8136
    
    *Middle row of room
    move.b  #8,$8143
    move.b  #0,$8144
    move.b  #0,$8145
    move.b  #10,$8146
    
    *Bottom row of room
    move.b  #4,$8153
    move.b  #9,$8154
    move.b  #9,$8155
    move.b  #5,$8156
    
    * Setup the doors
    move.w  #$80EB,FIRST_DOOR    Set the location of the first door
    
    rts

setup_enemies:
    * Setup first enemy
    move.b  #3,$6000    Health - Setup the first enemy
    move.b  #1,$6001    Damage/level
    move.b  #1,$6002    Class type (Knight)
    move.b  #1,$6003    Alive state (Alive)
    move.w  #$80DE,$6004  Move enemy coordinates
    
    * Setup second enemy
    move.b  #3,$6010    Health - Setup the first enemy
    move.b  #2,$6011    Damage/level
    move.b  #1,$6012    Class type (Knight)
    move.b  #1,$6013    Alive state (Alive)
    move.w  #$8155,$6014  Move enemy coordinates
    
    rts
    
setup_loot:
    * Setup first loot pile
    move.w  #$80DE,$7000  Move loot coordinates
    move.b  #1,$7002  Move loot potions
    move.b  #2,$7003  Move loot keys
    move.b  #LIFE_PER_TORCH,$7004  Move loot torches
    move.b  #5,$7005  Move loot gold
    move.b  #1,$7006  Move loot active state
    
    * Setup second loot pile
    move.w  #$8155,$7010  Move loot coordinates
    move.b  #3,$7012  Move loot potions
    move.b  #5,$7013  Move loot keys
    move.b  #1,$7014  Move loot torches
    move.b  #2,$7015  Move loot gold
    move.b  #1,$7016  Move loot active state

    
setup_player:
    move.b  #10,PLAYER      put score/health in memory location $5FF0
    move.b  #1,PLA_DAMAGE   Assign the default damage for the player
    move.b  #0,GAME_STATE   Put game state number in memory location $5FF3
    *0 = Pick role/intro | 5 = Move around | 6 = Combat | 7 = Shop | 64 = End game

    move.b  #0,PLA_CLASS    put class number in memory location $5FF2
    * 1 corresponds to knight - 2 corresponds to mage - 3 corresponds to rogue
    
    move.b  #100,PLA_GOLD    Assign the player's base gold value
    move.b  #1,PLA_POTIONS  Assign the player's base potions value
    move.b  #0,PLA_KEYS     Assign the player's base keys value
    *move.b  #LIFE_PER_TORCH,PLA_TORCH   Assign the player's base torch value
    move.b  #50,PLA_TORCH   Assign the player's base torch value
    
    lea     $814A,A6        Set the player coordinate to the first corridor
    move.w  A6,PLA_P_POS    Set the player's previous position to their current
    
    rts
    
setup_shops:
    * Setup the first shop
    move.w  #$80F9,$6500    Set the position
    move.b  #2,$6502        Set the potions
    move.b  #3,$6503        Set the keys
    move.b  #4,$6504        Set the torches
    move.b  #5,$6505        Set the damage
    
    * Setup the second shop
    move.w  #$80B2,$6510    Set the position
    move.b  #4,$6512        Set the potions
    move.b  #3,$6513        Set the keys
    move.b  #2,$6514        Set the torches
    move.b  #1,$6515        Set the damage

    rts
    
*-------------------------------------------------------
*-------------------Data Delarations--------------------
*-------------------------------------------------------

crlf:           dc.b    $0D,$0A,0
welcome_msg:    dc.b    '*****************************************************************',$0D,$0A
                dc.b    '      __  ___      ___  __      ___        ______    _____  ___',$0D,$0A
                dc.b    '     /""\|"  \    /"  |/""\    |"  |      /    " \  (\"   \|"  \',$0D,$0A
                dc.b    '    /    \\   \  //  //    \   ||  |     // ____  \ |.\\   \    |',$0D,$0A
                dc.b    '   /  /\  \\\  \/. .//  /\  \  |:  |    /  /    ) :)|: \.   \\  |',$0D,$0A
                dc.b    '  //  __   \\.    ////  __   \  \  |___(: (____/ // |.  \    \. |',$0D,$0A
                dc.b    ' /   /  \\  \\\   //   /  \\  \( \_|:  \\        /  |    \    \ |',$0D,$0A
                dc.b    '(___/    \___)\__/(___/    \___)\_______)\"_____/    \___|\____\)',$0D,$0A,$0D,$0A
                dc.b    '*****************************************************************',$0D,$0A,0
loop_msg:       dc.b    '.',0
blank_msg:      dc.b    '                                                                                   ',0
tutorial_msg    dc.b    'The darkness here is dangerious, keep your torch close and dont let it go out.',$0D,$0A
                dc.b    'Every movement you make decreases your torch life, so think before you move.',$0D,$0A
                dc.b    'You can buy more torches in the shop, thats probably a good place to start...',$0D,$0A,0
replay_msg:     dc.b    '1> Restart the game.',$0D,$0A
                dc.b    '2> Quit the game.',$0D,$0A,0
wake_up_msg:    dc.b    'You awake in a room, on a bed of red velvet, with no memory',$0D,$0A
                dc.b    'of how you got here. Stones crumble from the ceiling, the place looks like an',$0D,$0A
                dc.b    'old castle. You get a dark feeling from this place, and you know you must',$0D,$0A
                dc.b    'escape...',$0D,$0A
                dc.b    'You climb from the bed and look in a nearby mirror:',$0D,$0A,0
pick_role_msg:  dc.b    '1> You wear armour of polished iron, a short sword and heavy shield laying',$0D,$0A
                dc.b    'close by. (Knight class)',$0D,$0A,$0D,$0A
                dc.b    '2> You wear a cloak with mystic symbols sewn into the fabrics, an ancient',$0D,$0A
                dc.b    'looking staff lays near. (Mage class)',$0D,$0A,$0D,$0A
                dc.b    '3> You wear tight, well-fitting leather armour with reminents of black dye',$0D,$0A
                dc.b    'stained to the material. Two knives are fastened to your belt. (Rogue class)',$0D,$0A,0
input_nums_msg: dc.b    'Enter num between 1 and ',0
colon_msg:      dc.b    ': ',0

input_error_msg:    dc.b    'Inputted number is outside of range.',$0D,$0A,0
fake_gamestate_msg: dc.b    'Gamestate doesnt exist',$0D,$0A,0
knight_role_msg:    dc.b    'You grab your sword and shield, pull a torch from the wall, and leave the room.',$0D,$0A,0
knight_spec_msg:    dc.b    'You have chosen the KNIGHT class. You specialise in blocking and countering',$0D,$0A,0
mage_role_msg:  dc.b    'You pick up your staff, grab a torch from the wall, and leave the room.',$0D,$0A,0
mage_spec_msg:  dc.b    'You have chosen the MAGE class. You specialise in magic attacks.',$0D,$0A,0
rogue_role_msg: dc.b    'You fasten your belt, grab a torch from the wall, and leave the room.',$0D,$0A,0
rogue_spec_msg: dc.b    'You have chosen the ROGUE class. You specialise in quick melee attacks.',$0D,$0A,0
movement_msg:   dc.b    '1> Move north.',$0D,$0A
                dc.b    '2> Move south.',$0D,$0A
                dc.b    '3> Move west.',$0D,$0A
                dc.b    '4> Move east.',$0D,$0A
                dc.b    '5> Drink health potion.',$0D,$0A,0
move_north_msg: dc.b    'Moved north.',$0D,$0A,0
move_east_msg:  dc.b    'Moved east.',$0D,$0A,0
move_south_msg: dc.b    'Moved south.',$0D,$0A,0
move_west_msg:  dc.b    'Moved west.',$0D,$0A,0
movement_blocked_msg:  dc.b    'A wall blocks your path.',$0D,$0A,0
continue_msg:   dc.b    'Enter any key to continue... ',0
blank_tile      dc.b    '   ',0
both_tile       dc.b    '| |',0
left_tile       dc.b    '|  ',0
right_tile      dc.b    '  |',0
blocked_tile:   dc.b    '\/\',0
player_mark:    dc.b    '*',0
enemy_mark:     dc.b    'X',0
win_point_mark: dc.b    '@',0
shop_mark:      dc.b    '$',0
loot_mark:      dc.b    '%',0
door_mark:      dc.b    '#',0
map_legend_msg:     dc.b    'Map Legend:',0
map_player_msg:     dc.b    ' = Player',0
map_enemy_msg:      dc.b    ' = Enemy',0
map_win_point_msg:  dc.b    ' = Objective',0
map_shop_msg:       dc.b    ' = Shop',0
map_loot_msg:       dc.b    ' = Loot Pile',0
map_door_msg:       dc.b    ' = Locked Door',0
encounter_msg:  dc.b    'A monster blocks your path, it looks ready to attack!',$0D,$0A,0
combat_msg:     dc.b    '1> Block and Counter.',$0D,$0A
                dc.b    '2> Cast Magic.',$0D,$0A
                dc.b    '3> Attack Swiftly.',$0D,$0A
                dc.b    '4> Try Run.',$0D,$0A
                dc.b    '5> Drink Health Potion.',$0D,$0A,0
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
damage_lvl_msg          dc.b    'Damage lvl: ',0
inventory_msg:          dc.b    'Inventory:',0
gold_msg:               dc.b    '- Gold ',0
key_msg:                dc.b    '- Key ',0
potions_msg:            dc.b    '- Potion ',0
torches_msg:            dc.b    '- Torch ',0
damage_up_msg:          dc.b    '- Damage Upgrades ',0
battle_won_msg:         dc.b    'The monster collapses at your feet. It is dead!',$0D,$0A,0
bracket_open_msg:       dc.b    '(',0
bracket_close_msg:      dc.b    ')',0
death_msg:          dc.b    'You feel your last breath of air leave your lungs...',$0D,$0A
                    dc.b    'Your knees hit the ground...',$0D,$0A
                    dc.b    'You have died.',$0D,$0A,0
win_msg:            dc.b    'You feel the outside breeze hit your face...',$0D,$0A
                    dc.b    'You have escaped the castle!',$0D,$0A,0
take_potion_msg:    dc.b    'You drink a health potion...',$0D,$0A
                    dc.b    '3 health points restored!',$0D,$0A,0
no_potions_msg:     dc.b    'You are out of potions.',$0D,$0A,0
shop_enter_msg:     dc.b    '"Looking to lighten that coin pouch of yours?!"',$0D,$0A,0
shop_msg:       dc.b    '1> Buy Potion. (5g)',$0D,$0A
                dc.b    '2> Buy Key. (15g)',$0D,$0A
                dc.b    '3> Buy Torch. (10g)',$0D,$0A
                dc.b    '4> Buy Damage Upgrade. (20g)',$0D,$0A
                dc.b    '5> Leave Shop.',$0D,$0A,0
leave_shop_msg: dc.b    '"Pleasure doing business with you."',$0D,$0A,0
buy_item_msg:   dc.b    '"...And its yours!"',$0D,$0A,0
shop_stock_msg: dc.b    'Shop Stock:',0
player_msg:     dc.b    'Your Items:',0
no_money_msg:   dc.b    '"Not enough gold, traveller."',$0D,$0A,0
no_item_msg:    dc.b    '"Sorry, I dont have any of them left..."',$0D,$0A,0
no_torch_msg:   dc.b    'The darkness burns...',$0D,$0A,0
pickup_loot_msg:    dc.b    'You picked up a loot pile',$0D,$0A,0
pickup_gold_msg:    dc.b    '+ Gold ',0
pickup_potion_msg:  dc.b    '+ Potion ',0
pickup_key_msg:     dc.b    '+ Key ',0
pickup_torch_msg:   dc.b    '+ Torch life ',0
double_damage_msg:  dc.b    'Class Bonus - Double Damage!',$0D,$0A,0
locked_door_msg:    dc.b    'The door seems locked, you have a key that might fit it.',$0D,$0A
                    dc.b    'Do you want to try unlock it?',$0D,$0A,$0D,$0A
                    dc.b    '1> Yes. (-1 key)',$0D,$0A
                    dc.b    '2> No.',$0D,$0A,0
unlocked_door_msg:  dc.b    'The door swings open, the key lodged stuck in the keyhole.',$0D,$0A,0
blocked_door_msg:   dc.b    'The door seems solid, it wont budge.',$0D,$0A,0
graveyard_msg:  dc.b    '      ,-=-.       ______     _',$0D,$0A
                dc.b    '     /  +  \     />----->  _|1|_',$0D,$0A
                dc.b    '     | ~~~ |    // -/- /  |_ H _|',$0D,$0A
                dc.b    '     |R.I.P|   //  /  /     |S|',$0D,$0A
                dc.b    '\vV,,|_____|V,//_____/VvV,v,|_|/,,vhjwv/,',$0D,$0A,0
skeleton_msg:   dc.b    '           .-.',$0D,$0A
                dc.b    ' /\____/\ (o.o)',$0D,$0A
                dc.b    '|  _||_  | |=|',$0D,$0A
                dc.b    ' \/ || \/ __|__',$0D,$0A
                dc.b    '    ||\_//.=|=.\\',$0D,$0A
                dc.b    '    ||\_/ .=|=. \\',$0D,$0A
                dc.b    '    ||    .=|=. //',$0D,$0A
                dc.b    '    ||    (_=_)//',$0D,$0A
                dc.b    '    ||   (:| |:)',$0D,$0A
                dc.b    '    ||    || ||',$0D,$0A
                dc.b    '    ||    () ()',$0D,$0A
                dc.b    '    /\    || ||',$0D,$0A
                dc.b    '    ||    || ||',$0D,$0A
                dc.b    '    \/  ==   ==',$0D,$0A,0
merchant_msg:   dc.b    '         ____',$0D,$0A
                dc.b    '        |    |',$0D,$0A
                dc.b    '      --:<<>>:--',$0D,$0A
                dc.b    '        :~_~ :',$0D,$0A
                dc.b    '        _:"":\___',$0D,$0A
                dc.b    '  ____./ :::     \._',$0D,$0A
                dc.b    '<<=)           \    :',$0D,$0A
                dc.b    ' \/---/\_      /\._. ',$0D,$0A
                dc.b    ' ||       \====:_ ""',$0D,$0A
                dc.b    ' ||      ./     \\',$0D,$0A
                dc.b    ' ||     :       :',$0D,$0A
                dc.b    ' ||    /   :    \',$0D,$0A
                dc.b    ' ||   :   .      \.',$0D,$0A
                dc.b    ' ||   :  : :      :',$0D,$0A
                dc.b    ' ||   :__:-:__.;--',$0D,$0A,0
castle_msg:     dc.b    '                T~~',$0D,$0A
                dc.b    '                |',$0D,$0A
                dc.b    '               /"\',$0D,$0A
                dc.b    '       T~~     |.| T~~',$0D,$0A
                dc.b    '   T~~ |    T~ WWWW|',$0D,$0A
                dc.b    '   |  /"\   |  |  |/\T~~',$0D,$0A
                dc.b    '  /"\ WWW  /"\ |. |WW|',$0D,$0A
                dc.b    ' WWWWW/\| /   \|./\|/"\',$0D,$0A
                dc.b    ' |   /__\/]WWW[\/__\WWWW',$0D,$0A
                dc.b    ' |"  WWWW.|I_I|.WWWW.   |',$0D,$0A
                dc.b    ' |   |. |/  -  \|. |.  |',$0D,$0A
                dc.b    ' |.  |  |LI=H=LI|. |   |',$0D,$0A
                dc.b    ' |   |. | |[_]| |  |.  |',$0D,$0A
                dc.b    ' |   |  |_|###|_|  |   |',$0D,$0A
                dc.b    '  --- -- -/___\- -- --- ',$0D,$0A,0
                
















    end start























*~Font name~Courier New~
*~Font size~11~
*~Tab type~1~
*~Tab size~4~
