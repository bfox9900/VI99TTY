\ VITTY-1.FTH     PART 1                   June 2 2023, Brian Fox 
\ Builds on CAMELTTY Forth for TI-99 with expansion RAM 

NEEDS DUMP        FROM DSK1.TOOLS
NEEDS FORGET      FROM DSK1.FORGET
NEEDS READ-LINE   FROM DSK1.ANSFILES
NEEDS CASE        FROM DSK1.CASE
NEEDS -TRAILING   FROM DSK1.TRAILING
NEEDS MARKER      FROM DSK1.MARKER
NEEDS VALUE       FROM DSK1.VALUES

MARKER /PART1 

NEEDS <ERASELINE> FROM DSK1.VT100+

HERE 
\ *** VI99TTY SPECIFIC FILES *** 
NEEDS READ-FILE   FROM DSK2.HEAPSTR2
NEEDS $PUSH       FROM DSK2.VDPLINSTK 
\ ========================
\ Helpers
: BETWEEN  ( n lo hi -- ?) 1+ WITHIN ;
: CLIP     ( n lo hi -- n) ROT MIN MAX ;
: ERASE    ( addr len -- )  0 FILL ;
: BLANK    ( addr len -- )  BL FILL ;
: GETXY   VROW 2@  ;
: END   POSTPONE EXIT  POSTPONE THEN ; IMMEDIATE 

HEX
: LOWER? ( c -- ?) [CHAR] a [CHAR] z BETWEEN ;
: UPPER? ( c -- ?) [CHAR] A [CHAR] Z BETWEEN ; 

: UPCASE ( c -- c') 05F AND ;
: LOCASE ( c -- c') 060 OR  ;

: TOGGLE-CASE ( c -- c') 
  DUP LOWER? IF UPCASE EXIT THEN 
  DUP UPPER? IF LOCASE THEN 
;

: TOLOWER ( addr len -- addr len)
  2DUP BOUNDS 
  ?DO  I C@ DUP UPPER? IF LOCASE THEN I C!  LOOP ;

: TOUPPER ( addr len -- addr len)
  2DUP BOUNDS 
  ?DO  I C@ DUP LOWER? IF UPCASE THEN I C!  LOOP ;

\ data ...
DECIMAL
VARIABLE INSERTING
VARIABLE MODE
VARIABLE LINESTK
VARIABLE TOPLINE
VARIABLE READONLY 
VARIABLE SPAN      \ length of output string from editline 

C/L@ 1- CONSTANT WIDTH
24 CONSTANT 1SCR
12 CONSTANT 1/2SCR
27 CONSTANT ESC

HEX 
83D6 CONSTANT ALWAYS  \ screen saver address 

DECIMAL 
: PROMPT   0 23 AT-XY <ERASELINE> ;
: INFILE?  ( line# -- ?) 0  LINES @ BETWEEN ;  
\ editor cursor variables
CREATE ROW ( -- addr) 0 , 0 ,
: ROW/COL  ( -- row col)  ROW 2@ ;
ROW CELL+ CONSTANT COL  \ access COL separately if needed

CREATE FILENAME  16 ALLOT   FILENAME OFF

\ ........................................
\ TEMP storage above the Forth dictionary
DECIMAL 
CREATE OUTBUFF ( -- addr)  88 ALLOT    \ used by EDITLINE 256 CHARS MAX 

: TEMP$        ( -- addr) PAD 100 + ; \ free dictionary is available 

\ range limiters
: ASCII?    ( c -- ?) BL [CHAR] ~ BETWEEN ;
: [ASCII]   ( c -- c) BL [CHAR] ~ CLIP ;
: [MARGINS] ( n -- n' )  0  WIDTH CLIP ;

: MARGINS   ( colvar --) DUP @   [MARGINS] SWAP ! ;

: >OUT$ ( addr len -- ) \ "to out$"
  DUP [MARGINS] SPAN !   \ reset span to this string's length with limits 
  OUTBUFF DUP 82 BLANK PLACE ;

\ This string is odd. It uses SPAN to hold the length. 
\ returns address and span that is edited by EDITLINE (see below)k
\ It's easier to manipulate a variable for this single purpose
: OUT$    ( -- addr span) OUTBUFF 1+ SPAN !  ;


INCLUDE DSK2.DRIVEMNGR 
INCLUDE DSK2.COMMANDKEY 

\ line# OF the cursor in the _editor window_
: ELINE#  ( -- n ) TOPLINE @  ROW @ + ;

: EOL     ( -- n) ELINE# SEEKLN LEN  WIDTH MIN ;  
: >EOL    ( -- addr len)  EOL COL ! ;
: 'CURSOR ( -- addr) ELINE# SEEKLN COL @ + 1+  ;

\ more escape codes 
: <SCRDN>   ESC (EMIT) [CHAR] M (EMIT) ;
: <SCRUP>   0 0 AT-XY  <ESC>[  [CHAR] M (EMIT) ;
\ : <ELRIGHT>     <ESC>[ ." [K" ;  \ ERASE line from cursor right 
: <BELL>    7 (EMIT) ;

HEX
: ^ ( c -- ) \ compile ctrl char
  ?COMP  CHAR  1F AND
  POSTPONE LITERAL ; IMMEDIATE

DECIMAL
: GOTOLINE  ( n --) 1  LINES @ 12 - CLIP  TOPLINE ! ;
: TOPLINE+! ( n --) TOPLINE @ +  GOTOLINE ;

\ dec to zero but never less
: DECR!  ( addr -- ) DUP @ 1- 0 MAX  SWAP ! ;

: .LINE ( $addr -- $addr)
    DUP LEN IF  DUP COUNT TYPE  END 
    [CHAR] ~ EMIT 
;

: LIST  ( -- )
  PAGE 
  TXTBUFFER TOPLINE @ NTH ( -- $addr)
  23 0 DO  .LINE CR NEXT$  LOOP DROP ;

: RIGHTSIDE ( addr len -- addr len') COL @  /STRING  0 MAX ;
: LEFTSIDE  ( addr len -- addr len') DROP  COL @ ;

: SPLIT    ( addr len n -- leftaddr len  rightaddr len )
    >R                  \ Rpush n
    2DUP DROP R@        \ dup $, do left$
    2SWAP               \ put original $ on top
    R> /STRING  0 MAX   \ cut remainder string
; 

: SEEKTO ( line# -- addr len ) SEEKLN COUNT ;

: REDRAWLN ( addr len -- )  0 ROW @ AT-XY <ERASELINE>  TYPE ;  

\ redraw the line the cursor is at
: RELINE (  -- ) ELINE# SEEKTO REDRAWLN ; 

\ rightside only relining 
: REFRESHLN  
  ELINE# SEEKTO RIGHTSIDE ROW/COL AT-XY <ERASERIGHT> TYPE ;

\ undo function 
DECIMAL
CREATE UBUFFER  82 ALLOT  \ last change buffer 
CREATE UBUFFER2 82 ALLOT  \ line change undo buffer 

: SAVEUNDO ( --) SEEK$ @ COUNT UBUFFER PLACE ; 
: CMD-UNDO ( --) UBUFFER COUNT ELINE# REPLACELN  RELINE ;
: EDITUNDO      CMD-UNDO  ELINE# SEEKTO >OUT$  ;

\ setup for commands that can loop 
: ARGS ( -- n 0)  ARG# 1 MAX  0 ;  \ Setup for a ?DO/LOOP 

: (GODOWN) ( -- ) \ unconditionally go to next line 
  ROW @ 1+ 22 > 
  IF  <SCRUP>  1 TOPLINE+!   RELINE
  ELSE <DOWN> ROW 1+! 
  THEN ;

: GODOWN ( -- ) \ does not go past end OF file 
  ARGS ?DO 
    ELINE#  LINES @ 1- > 
    IF <BELL> 
    ELSE (GODOWN)
    THEN 
  LOOP ;
 
: GOUP 
  ARGS ?DO 
    ELINE# 1 > 
    IF  ROW @ 0=
        IF  <SCRDN>  -1 TOPLINE+!  RELINE
        ELSE <UP>  ROW DECR!
        THEN 
    THEN 
  LOOP 
;

: GOLEFT     
  ARGS ?DO 
    COL DECR! COL @ 0> 
    IF <LEFT>  THEN 
  LOOP ;

: GORIGHT    
  ARGS ?DO 
    COL @ 1+  
    EOL 1- DUP>R MIN COL ! 
    COL @ R> <> IF <RIGHT> THEN 
  LOOP ; 

: MOVESCR    ( n -- )  TOPLINE+! LIST ;
\ Put single character in HEAP string
: CHAR!      ( c --) 'CURSOR C!  RELINE ; 

\ vi commands:  ~ x r :
: CHANGE-CASE   SAVEUNDO 'CURSOR C@ TOGGLE-CASE CHAR! ; 
: DELETE-CHAR   SAVEUNDO  BL DUP EMIT CHAR! ;            
: REPLACE-CHAR  SAVEUNDO  BL EMIT   ROW/COL AT-XY KEY  CHAR! ; 
: COMMAND-LINE  PROMPT ." :"  TIB DUP 80 ACCEPT INTERPRET ; 

\ EDITLINE 
VARIABLE INSERTING 
C/L@ 1- CONSTANT WIDTH 

\ editing the OUT$ has special words 
: 'ECURS ( -- addr) OUTBUFF CHAR+ COL @ + ; \ EDITLINE's cursor 
: SPAN!  ( n --) 0 SPAN @ CLIP  SPAN ! ; \ changed to clip vs MAX 

\ put character in OUTBUFF if printable char !
: PUTCH  ( c -- )  
  ASCII? 0= IF DROP   END 
 
  DUP 'ECURS C! EMIT  
  COL 1+!  COL @ [MARGINS] SPAN ! 
;

: PUSHRIGHT ( -- )
  OUT$ RIGHTSIDE OVER 1+  SWAP 1+ MOVE 
  BL 'ECURS C!
  1 SPAN +!    \ update span
;

: BACKSPACE ( -- ) COL DECR! ;

: /CHAR ( addr len -- ) 1 /STRING  OVER 1- SWAP 1 MAX  MOVE ;

: MOVERIGHT    COL 1+! COL MARGINS    COL @ SPAN! ;

: SAVELN ( caddr -- ) 
    DUP 0= IF   2DROP S"  " THEN ELINE# REPLACELN ;

CR .( PART 1 COMPILED )
