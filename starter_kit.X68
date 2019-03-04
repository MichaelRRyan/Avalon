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

mine_loc    EQU 100    example for a hit


*Start of Game
start:
    move.b  #100,$4000 put score/health in memory location $4000
    lea     $4000,A3   assign address A3 to that memory location
    
    move.b  #0,$4010   put game state number in memory location $4010
    lea     $4010,A4   assign address A4 to that memory location
    *0 = Pick role/intro | 5 = Move around | 6 = Combat | 10 to 20 = Shop | 64 = End game

    move.b  #0,$4020   put class number in memory location $4020
    lea     $4020,A5   assign address A5 to that memory location
    * 1 corresponds to knight - 2 corresponds to mage - 3 corresponds to rogue
    
    *A6 is used for player coordinates
    *D5 is used occasionally for input range
    
    bsr     setup_world

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
    
    move.b  #3,D5           Move the number 3 to D5 to tell the program how many options there are
    
    bsr     input           branch to the input subroutine
    
    bsr     press_continue          Pause the game until a key is pressed
    
    rts                     return from pick_role subroutine
    
role_input:
    move.b  D1,(A5)         Move the role number to A5 to hold the class number
    
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
    
    move.b  #5,(A4)         Change the game state to the movement state
    lea     $514A,A6        Set the player coordinate to the first corridor
    
    rts                     Return from the sub routine

mage_select:
    lea     mage_role_msg,A1 assign message to address register A1
    move.b  #14,D0          move literal 14 to DO
    trap    #15             Display the mage message
    
    move.b  #5,(A4)         Change the game state to the movement state
    lea     $514A,A6         Set the player coordinate to the first corridor
    
    rts                     Return from the sub routine

rogue_select:
    lea     rogue_role_msg,A1 assign message to address register A1
    move.b  #14,D0          move literal 14 to DO
    trap    #15             Display the rogue message
    
    move.b  #5,(A4)         Change the game state to the movement state
    lea     $514A,A6         Set the player coordinate to the first corridor
    
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
    BGT     invalid_input   Error if less than max value
    
    CMP.B   #0,(A4)         Check which state the game is in
    BEQ     role_input      Branch to the manage input for the role picking
    CMP.B   #5,(A4)         Check which state the game is in
    BEQ     wall_collisions Branch to the manage input for the movement
    BNE     fake_gamestate  branch to display a message if the gamestate is undifined
    
    rts                     Return out of subroutine

invalid_input:
    lea     input_error_msg,A1 assign message to address register A1
    move.b  #14,D0          move literal 14 to DO
    trap    #15             Display the error message
    
    bra     input           Go back to taking input
    
fake_gamestate:
    lea     fake_gamestate_msg,A1     assign message to address register A1
    move.b  #14,D0          move literal 14 to DO
    trap    #15             Display the error message
    rts

*-------------------------------------------------------
*----------------Gameloop (main loop)-------------------
*------------------------------------------------------- 
gameloop:
    bsr     update          branch to update game subroutine 
    bsr     clear_screen    clears the screen         
    bsr     draw            branch to draw screen subroutine
    
    bsr     gameplay        branch to gameplay subroutine
   
    bra     gameloop        Continue looping the game loop     
    
    bsr     clear_screen    clears the screen
    bsr     hud             branch to display HUD subroutine
    bsr     clear_screen    clears the screen
    bsr     replay          branch to replay game subroutine
    bsr     clear_screen    clears the screen
    rts                     return from gameloop: subroutine

*-------------------------------------------------------
*----------------Update Quest Progress------------------
*  Complete Quest
*------------------------------------------------------- 
update:
    *Add update code here
    rts
*-------------------------------------------------------
*-----------------Draw Quest Updates--------------------
* Draw the game progress information, status regarding
* quest
*------------------------------------------------------- 
draw:
    CMP.B   #5,(A4)     Check which state the game is in
    BEQ     draw_loop   If in the movement state, draw the map
    rts

*-------------------------------------------------------
*---Game Play (Quest Progress)--------------------------
*------------------------------------------------------- 
gameplay:
    bsr     endl        Break to a new line
    CMP.B   #0,(A4)     Check which stage the game is in
    BEQ     pick_role   branch to the pick role subroutine
    CMP.B   #5,(A4)     Check which stage the game is in
    BEQ     movement    branch to the movement subroutine
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

    move.b  #0,(A5)     Reset the game state for restart
    
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

    move.b  #4,D5           Move the number 3 to D5 to tell the program how many options there are
    
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
    
    sub     #1,A6               Move the player west
    
    *lea     move_west_msg,A1    Load the message
    *move.b  #14,D0              Move the trap command to display a message
    *trap    #15                 Display the move north message
    *bsr     press_continue          Pause the game until a key is pressed
    
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
    
    add     #1,A6                   Move the player east
    
    rts

movement_blocked:
    lea     movement_blocked_msg,A1 Load the message
    move.b  #14,D0                  Move the trap command to display a message
    trap    #15                     Display the movement blocked message
    bsr     press_continue          Pause the game until a key is pressed
    
    rts                             Return from the subroutine
    
*-------------------------------------------------------
*-------------------Misc Subroutines--------------------
*-------------------------------------------------------
press_continue:
    bsr     endl

    lea     continue_msg,A1     Load message into A1
    move.b  #14,D0              Move the trap command to display a message
    trap    #15                 display the "press any ket to continue" text
    
    move.b  #4,D0               Move the trap command to take input
    trap    #15                 take input to freeze the game
    rts                         Return from the 'press continue' subroutine
    
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
    move.w  #255,D1
    move.b  #11,D0
    trap    #15
    
    sub.w   #512,D1
    trap    #15
    
    lea     player_mark,A1
    move.b  #14,D0
    trap    #15
    
    add.w   #512,D1
    move.b  #11,D0
    trap    #15
    
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
pick_role_msg:  dc.b    '1> You wear armour of polished iron, a sword laying close by. (Knight class)',$0D,$0A,$0D,$0A
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

    end start









*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
