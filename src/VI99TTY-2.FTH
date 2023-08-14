\ 

MARKER /PART2 

INCLUDE DSK1.AUTOBAUD 

: DO-ENTERKEY 
    OUT$ TEMP$ PLACE 
    TEMP$ COUNT LEFTSIDE SAVELN
    (GODOWN)
    TEMP$ COUNT RIGHTSIDE 2DUP >OUT$ ELINE# INSERTLN 
    COL OFF   \ can't change column until strings are cut
    LINES 1+! 
    LIST 
;    

\ --------------------------------------------
\         DEBUG ON VDP SCREEN 
INCLUDE DSK2.VDPDRIVER
NEEDS DEFER FROM DSK1.DEFER 

DEFER DEBUG 
: VDP.S        ( -- )
    DEPTH IF 0 DEPTH 2- DO    I PICK  VDP.   -1 +LOOP THEN ;

\ show debug info on VDP screen :-)
\ LDEPTH is found in the VDPLINSTK file
: .DEPTHS
    ALWAYS ON 
    0 10 VDP.AT-XY   
    VDP.CURS  C/L@ 5 *  BL VFILL
    S" S| "   VDP.TYPE VDP.S  VDP.CR
    S" R| "   VDP.TYPE RP0 RP@ - 2/  3 VDP.R  VDP.CR
 \   S" X/Y "  VDP.TYPE ROW/COL SWAP VDP. VDP. VDP.CR 
 \   S" ARG#=" VDP.TYPE  ARG# VDP. VDP.CR  VDP.CR
 \   S" Topline="  VDP.TYPE  TOPLINE @ VDP. S" SPAN=" VDP.TYPE  SPAN @ VDP. 
    S" LSTK=" VDP.TYPE    LDEPTH  VDP. ; 
;

DECIMAL 

' .DEPTHS IS DEBUG

\ ------------------------------------------
CR .( file stats line)
: .LINES     LINES @ (.) TYPE ." L, "  ;
: .FSIZE     FSIZE   (.) TYPE ." C " ;

: QUOTE  ( -- ) [CHAR] " EMIT ;
: "TYPE" ( addr len --) QUOTE TYPE QUOTE ;

: .FILE ( $ -- )
  FILENAME COUNT DUP 0=
  IF 2DROP S" new file"
  THEN PROMPT "TYPE" ;

: .FSTATS ( -- )  .FILE SPACE .LINES .FSIZE ;

: SAVE  ( addr len -- )  
  READONLY @ IF PROMPT ." Mode is READONLY" 1000 MS  EXIT 
  THEN WRITE-FILE 
       PROMPT .FSTATS  ." written" ;


\ ------------------------------------------
: .RIGHT ( addr len -- )  RIGHTSIDE  ROW/COL AT-XY <ERASERIGHT> TYPE ;  

: DELCHAR  ( -- ) 
  OUT$ RIGHTSIDE DUP 1 < IF  2DROP  END 
  /CHAR  SPAN DECR! ;  


: BS-KEY
  COL @ 1 U< IF  DROP  END 
  INSERTING @ 
  IF   BACKSPACE DELCHAR 
  ELSE BACKSPACE 
  THEN ;

DECIMAL
: EDITLINE ( addr len -- )
  >OUT$ REFRESHLN
  BEGIN
    OUT$ .RIGHT 
  \  DEBUG 
    ROW/COL AT-XY KEY 
    DUP ESC <>  
  WHILE   
      OUT$ UBUFFER PLACE  ( save for undo )
      CASE
       127 OF  DELCHAR            ENDOF
         8 OF  BS-KEY             ENDOF
        13 OF  DO-ENTERKEY        ENDOF 
       ^ Z OF  EDITUNDO           ENDOF 
        \ ascii char handler 
            DUP ASCII? 
            IF 
              INSERTING @ 
              IF PUSHRIGHT THEN DUP PUTCH
            THEN 
      ENDCASE
      .FSTATS
  REPEAT  
  DROP
  PROMPT 
  OUT$ SAVELN 
;

\ VI COMMAND ROUTINES .................:
: INSERT-TEXT 
    PROMPT ." -- INSERT --" 
    INSERTING ON  
    ELINE# SEEKTO EDITLINE
;   

: REPLACE-TEXT 
    PROMPT ." -- REPLACE --"
    INSERTING OFF
    ELINE# SEEKTO EDITLINE
;

: OPEN-LINE
   (GODOWN)  \ forces going past end OF file
   COL OFF
   S"  " ELINE# INSERTLN 
   LINES 1+! 
   LIST 
   INSERT-TEXT
;


\ ................................................
\                  COPY  

: COPYLN ( line# ) SEEKTO $PUSH  ;

: COPYLINES  ARGS ?DO  ELINE# I + COPYLN  LOOP ;

: CMD-y  KEY [CHAR] y = IF  COPYLINES  THEN ;

\ ................................................
\               DELETE LINES
: LINES+!     ( n --) LINES @  +  0 MAX  LINES !  ;
: DELETE-LINE ( -- ) ELINE# DUP COPYLN  DELETELN  -1 LINES+! ;

: CUTLINES  ( -- ) ARGS ?DO  DELETE-LINE  LOOP LIST ;

\ ................................................
\               DELETE WORDS

: -LEADING  ( addr len -- addr' len' ) \ skip leading spaces 
   BEGIN  OVER C@ BL = 
   WHILE  1 /STRING  
   REPEAT ;

\ : A$  S"         NOW IS THE TIME FOR ALL GOOD MEN" ;

: /WORD  ( addr len -- addr' len')  2DUP  BL SCAN  NIP - 0 MAX  ;

: CUTWORD   ( addr len --  addr' len' addr2 len2) 
  BL SKIP                       \ skip leading blanks  
  2DUP  /WORD DUP>R             \ get first word. copy length 
  2SWAP  R> /STRING 0 MAX       \ cut first word from input string 
  2SWAP ; 

: CUTWORDS   
  ELINE# SEEKTO COL @ SPLIT  ( left len right len)                 
  OUTBUFF OFF                          \ empty buffer holds the cut words
  ARGS ?DO 
    CUTWORD OUTBUFF +PLACE             \ cut word & append to OUTBUFF
    S"  " OUTBUFF +PLACE               \ append a trailing space 
  LOOP
  OUTBUFF COUNT $PUSH                  \ cut words go into linestack buffer    

  ( -- left$ len 'right$ 'len)         \ leftover from RIGHTSIDE on stack 
\ reconstruct a new line with the words removed in the outbuffer   
  2SWAP OUTBUFF PLACE                  \ move LEFTSIDE into buffer 
  OUTBUFF +PLACE                       \ append RIGHTSIDE to buffer  
  OUTBUFF COUNT ELINE# REPLACELN       \ put NEW line back into storage 
  RELINE                               \ update the screen  
;  

\ delete right of cursor 
: CMD-D ( -- )  
  SAVEUNDO  
  ELINE# SEEKTO TEMP$ PLACE
  TEMP$ COUNT LEFTSIDE  ELINE# REPLACELN REFRESHLN ;


: CMD-d   \ lower case 'd' takes numeric args for multi-word/line
  SAVEUNDO 
  KEY ( -- char)
  CASE 
      [CHAR] d OF  CUTLINES    ENDOF 
      [CHAR] w OF  CUTWORDS    ENDOF 
      [CHAR] b OF  KILL-BUFFER ENDOF 
      [CHAR] $ OF  CMD-D       ENDOF 
  ENDCASE ;

\ ...........................................
\                  PASTE 
DECIMAL 
: INSERT@CURSOR ( addr len  -- )
  ELINE# DUP>R SEEKTO 2DUP ( -- addr len addr len)

  LEFTSIDE OUTBUFF PLACE       \ store leftside in outbuffer 
  RIGHTSIDE                    \ extract right of cursor string

  2SWAP OUTBUFF +PLACE         \ append string from data stack 
  OUTBUFF +PLACE               \ Append rightside

  OUTBUFF COUNT R> REPLACELN   \ write back line 
; 

: PASTE
  BEGIN 
    LDEPTH 
  WHILE
    $POP ELINE# INSERTLN
    1 LINES+! 
  REPEAT
  LIST 
;

: .EMPTY  PROMPT ." Buffer is empty" ;

: CMD-P \ place saved lines above cursor line 
  LDEPTH 0= IF  .EMPTY END  PASTE ;

: CMD-p  \ place saved lines below cursor line 
  LDEPTH 0= IF .EMPTY END  (GODOWN) PASTE ; 

: CTRL-P 
  LDEPTH 0= IF .EMPTY END  
  $POP INSERT@CURSOR RELINE ;  

\ ............................................
\             back words 
: LASTCHAR  ( addr len -- char) 2DUP + 1- C@ ;

: -ASCII ( addr len -- addr' len') 
    BEGIN  
      DUP 
    WHILE   
      LASTCHAR BL <> 
    WHILE  
       1-  0 MAX 
    REPEAT 
    THEN ;

: PREVWORD  -TRAILING  -ASCII ;

CR .( Part 2 compiled )

