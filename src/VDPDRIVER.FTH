
( Simple VDP video driver for CAMEL99 TTY  Fox June 2021)
\ for graphics 1 mode. Wraps back to top of screen 
HERE
.( .)
DECIMAL
CREATE VDP.ROW  0 , 0 ,     VDP.ROW CELL+ CONSTANT VDP.COL

: VDP.AT-XY  ( col row -- ) VDP.ROW 2! ;
: VDP.CURS   ( -- Vaddr) VDP.ROW 2@  5 LSHIFT +  ;
: VDP.PAGE   ( -- )  0 768 BL VFILL  0 0 VDP.AT-XY ;
.( .)
: VDP.WRAP   VDP.CURS 767 > IF  0 0 VDP.AT-XY  THEN ; 
: VDP.COL+!  ( n)   VDP.COL +!  VDP.WRAP ;
.( .)
: VDP.EMIT   ( c -- )  VDP.CURS VC!  1 VDP.COL+! ;
: VDP.TYPE   ( addr n ) 0 DO COUNT VDP.EMIT LOOP DROP ; 
: VDP.SPACES ( n -- ) 0 MAX  0 DO  BL VDP.EMIT  LOOP ;
: VDP.CR     ( -- )   VDP.ROW 1+!  VDP.COL OFF ;
.( .)
\ single number printing 
: VDP.   ( n -- ) (.) VDP.TYPE  BL VDP.EMIT ;
: VDP.R    ( n n -- ) >R (.) R> OVER - VDP.SPACES VDP.TYPE ;
.( .)
\ unsigned double number printing 
: VDP.UD.R ( ud n --) >R  <# #S #>  R> OVER -  VDP.SPACES VDP.TYPE ;

\ unsigned single number printing 
: VDP.U.R   ( u n -- )  0 SWAP  VDP.UD.R ;

HERE SWAP -  SPACE .  .( bytes) CR
VDP.PAGE  S" VDP Driver is resident" VDP.TYPE 

HEX
: TEXT    ( -- )
      E0 DUP 83D4 C!
      ( -- F0) 01 VWTR
      0  2 VWTR   \ set VDP screen page
      VTOP OFF    \ topline VDP offset
      VPG  OFF    \ VDP screen page offset
      17  7 VWTR  \ sets FG & BG color
      28 C/L!     \ 40 chars per line 
      0 0 AT-XY
      2 VMODE !   \ 2=ID for 40 column "TEXT" mode
;

 : GRAPHICS  ( -- )
      1 VMODE !
      0 3C0  0 VFILL \ erase the entire 40 col. screen space
      00  2 VWTR     \ page zero, same as text mode
      E0 DUP 83D4 C! \ KSCAN re-writes VDP Reg1 with this byte
( -- E0) 1 VWTR      \ VDP register 1  bit3 = 0 = Graphics Mode
      0E 3 VWTR        \ color table
      01 4 VWTR        \ pattern table
      06 5 VWTR        \ sprite attribute table
      01 6 VWTR        \ set sprite pattern table to 1x$800=$800
      380 10 10 VFILL  \ color table: black on transparent [1,0]
      17 7 VWTR        \ cyan SCREEN
      20 C/L!          \ 32 chars/line
 ;

: TESTNUM
    VDP.PAGE
    S" VDP Driver Test from TTY Forth" VDP.TYPE
    2001 0
    DO
      10 10 VDP.AT-XY
      I 5 VDP.R
    LOOP
;

: VDP.CHARS  127 BL DO I VDP.EMIT  LOOP  ;
: TESTCHARS  0 ?DO  VDP.CHARS  LOOP  ;

: TESTWRAP ( n) VDP.PAGE  0 ?DO  I VDP.  LOOP ;


NEEDS DEFER  FROM DSK1.DEFER 

DEFER DEBUG 

\ show debug info on VDP screen :-)
: .DEPTHS
      0 10 VDP.AT-XY
      S" S| " VDP.TYPE  DEPTH        3 VDP.R  VDP.CR
      S" R| " VDP.TYPE  RP0 RP@ - 2/ 3 VDP.R  VDP.CR
      HERE 4 VDP.TYPE ;

' .DEPTHS IS DEBUG
