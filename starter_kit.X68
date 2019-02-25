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
    
    move.b  #0,$4010   put stage number in memory location $4010
    lea     $4010,A4   assign address A4 to that memory location

    move.b  #0,$4020   put class number in memory location $4010
    lea     $4020,A5   assign address A4 to that memory location
    * 1 corresponds to knight - 2 corresponds to mage - 3 corresponds to rogue
    
    move.b  #0,$4030   put torches number in memory location $4010
    lea     $4030,A6   assign address A4 to that memory location

    bsr     welcome    branch to the welcome subroutine
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
    
    move.b  #4,D0           Move the number 4 to D0
    trap    #15             Take input
    
    rts                     return from pick_role: subroutine
    
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
    
    CMP.B   #0,(A4)          Check which state the game is in
    BEQ     role_input      Branch to the manage input for the role picking
    BNE     fake_gamestate  branch to display a message if the gamestate is undifined
    
    rts                     Return out of subroutine

invalid_input:
    lea     input_error_msg,A1 assign message to address register A1
    move.b  #14,D0          move literal 14 to DO
    trap    #15             Display the error message
    
    bra     input           Go back to taking input
    
role_input:
    lea     congrats,A1     assign message to address register A1
    move.b  #14,D0          move literal 14 to DO
    trap    #15             Display the congrats message
    
    move.b  D1,(A5)         Move the role number to A5 to hold the class number
    
*Give the player a message depending on the role chosen
    CMP.B   #1,D1
    BEQ     knight_select   Branch to knight message if role selected
    
    CMP.B   #2,D1
    BEQ     mage_select     Branch to mage message if role selected
    
    CMP.B   #3,D1
    BEQ     rogue_select    Branch to rogue message if role selected
    
    move.b  #1,(A4)         Change the game state
    
    rts
    
knight_select:
    lea     knight_role_msg,A1 assign message to address register A1
    move.b  #14,D0          move literal 14 to DO
    trap    #15             Display the knight message
    rts                     Return from the sub routine

mage_select:
    lea     mage_role_msg,A1 assign message to address register A1
    move.b  #14,D0          move literal 14 to DO
    trap    #15             Display the mage message
    rts                     Return from the sub routine

rogue_select:
    lea     rogue_role_msg,A1 assign message to address register A1
    move.b  #14,D0          move literal 14 to DO
    trap    #15             Display the rogue message
    rts                     Return from the sub routine

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
    bsr     clear_screen    clears the screen
    bsr     gameplay        branch to gameplay subroutine
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
    bsr     endl            print a CR and LF
    bsr     decorate        decorate with dots using a loop
    lea     update_msg,A1   
    move.b  #14,D0
    trap    #15
    bsr     decorate
    rts
*-------------------------------------------------------
*-----------------Draw Quest Updates--------------------
* Draw the game progress information, status regarding
* quest
*------------------------------------------------------- 
draw:
    bsr     endl
    bsr     decorate
    lea     draw_msg,A1
    move.b  #14,D0
    trap    #15
    bsr     decorate
    rts
*-------------------------------------------------------
*------------------------Potions------------------------
* Input the ingredients for each potion. Ingredients costs 
* money. For an advanced mark you need to manage this 
* resource
*------------------------------------------------------- 
feed:
    bsr     endl
    bsr     decorate
    lea     potion_msg,A1
    move.b  #14,D0
    trap    #15
    bsr     decorate
    rts

*-------------------------------------------------------
*--------------------Potions Inventory---------------------
* Number of potions to be used in a Quest 
*------------------------------------------------------- 
potions:
    bsr     endl
    bsr     decorate
    lea     potions_msg,A1
    move.b  #14,D0
    trap    #15
    bsr     decorate
    rts

*-------------------------------------------------------
*-------------------------Weapons-----------------------
* Number of weapons
*-------------------------------------------------------   
weapons:
    bsr     endl
    bsr     decorate
    lea     weapons_msg,A1
    move.b  #14,D0
    trap    #15
    bsr     decorate
    rts

*-------------------------------------------------------
*---Game Play (Quest Progress)--------------------------
*------------------------------------------------------- 
gameplay:
    bsr     endl
    CMP.B   #0,(A4)     Check which stage the game is in
    BEQ     pick_role  branch to the pick role subroutine
    bsr     collision
    rts

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
*-----------------------Being Attacked------------------
* This could be used for collision detection
*-------------------------------------------------------
collision:
    move.b  #mine_loc,D1
    cmp     #100,D1 is( x == 100)?
	bne     collision_miss if x is equal to 100, then hit
collision_hit:
    *hit
    lea     hit_msg,A1
    move    #14,D0
    trap    #15
    rts
    
collision_miss:
    *miss
    lea     miss_msg,A1
    move    #14,D0
    trap    #15
    rts

*-------------------------------------------------------
*--------------------------Loop-------------------------
*-------------------------------------------------------
loop:
    move.b  #5, D3 loop counter D3=5
next:
    lea     loop_msg,A1
    move.b  #14,D0
    trap    #15
	sub     #1,D3   decrement loop counter
    bne     next    repeat until D0=0

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
input_nums_msg  dc.b    'Enter num between 1 and ',0
colon_msg       dc.b    ': ',0

input_error_msg dc.b    'Inputted number is outside of range.',$0D,$0A,0
congrats        dc.b    'You picked a role!',$0D,$0A,0
fake_gamestate_msg dc.b    'Gamestate doesnt exist',$0D,$0A,0
knight_role_msg dc.b    'You pick up your sword, grab a torch from the wall, and leave the room.',$0D,$0A
                dc.b    '- You have chosen the KNIGHT class. You specialise in slow, strong attacks.',$0D,$0A,0
mage_role_msg   dc.b    'You pick up your staff, grab a torch from the wall, and leave the room.',$0D,$0A
                dc.b    '- You have chosen the MAGE class. You specialise in ranged magic attacks.',$0D,$0A,0
rogue_role_msg  dc.b    'You fasten your belt, grab a torch from the wall, and leave the room.',$0D,$0A
                dc.b    '- You have chosen the ROGUE class. You specialise in fast, weak attacks.',$0D,$0A,0

    end start




*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
