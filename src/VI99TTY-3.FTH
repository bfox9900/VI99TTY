\ vi99tty-3.fth           PART 3 OF 3       June 18 2023 Brian Fox 

MARKER /PART3 

: GOBACK ( addr len -- addr' len') 
    DUP 1 <                    \ test for beginning of line 
    IF    2DROP                \ don't need this string now
          GOUP                 \ go up one line 
          ELINE# SEEKTO        \ re-seek to the new line
          DUP COL ! 
    END
    PREVWORD
;

: CMD-b    
  ELINE# SEEKTO LEFTSIDE 1-   \ start scan at the cursor-1 
  ARGS ?DO  GOBACK  LOOP      
  NIP COL ! ;               

\  : TEST    GOBACK  2DUP  CR TYPE ;
\ -------------------------------------------
\                FORWARD WORDS 
: NEXTWORD  BL SCAN  BL SKIP ;

: GOFORWARD 
    DUP 0=              \ 0 means we are at end of line 
    IF  2DROP 
        GODOWN COL OFF 
        ELINE# SEEKTO 
    END
    NEXTWORD 
;

: CMD-w 
    ELINE# SEEKTO RIGHTSIDE
    ARGS ?DO  GOFORWARD  LOOP      
    NIP SEEK$ @ LEN SWAP - 0 WIDTH CLIP  COL ! 
;

: CMD-x  ( -- ) \ extract character at the cursor position  
    ELINE# DUP>R SEEKTO  COL @ SPLIT  
    2SWAP TEMP$ PLACE                  \ left side to temp
    1 /STRING 0 MAX TEMP$ +PLACE       \ cut rightside char, append
    TEMP$ COUNT R> REPLACELN  RELINE ; \ put it back  

\ ..................................
\ console REPL with prompt for vi99
DECIMAL 
: prompt$  CR  $HOME COUNT TYPE  ." $ " ;

: NEWQUIT 
  RP0 RP! L0 LP !
  SOURCE-ID OFF
  POSTPONE [
  BEGIN
    prompt$  TIB DUP 82 ACCEPT SPACE
   ( addr len) INTERPRET
  AGAIN ;

: HOME     0 0 ROW 2! ;

\ very deep case statements overflow the return stack. (I think)
: CTRL-KEYS ( c -- c)
   DUP CASE
    \ control keys
    ^ F OF  1SCR          MOVESCR    ENDOF
    ^ B OF  1SCR NEGATE   MOVESCR    ENDOF
    ^ D OF  1/2SCR        MOVESCR    ENDOF
    ^ G OF  PROMPT .FSTATS           ENDOF 
    ^ P OF  CTRL-P                   ENDOF 
    ^ U OF  1/2SCR NEGATE MOVESCR    ENDOF
    ^ L OF  LIST                     ENDOF
    ^ M OF  GODOWN  COL OFF          ENDOF
    ^ Z OF   PAGE ." Forth" ABORT    ENDOF
    ENDCASE 
;

: LOWER-KEYS ( c -- c)
 DUP CASE 
       BL OF GORIGHT                 ENDOF 
 [CHAR] 0 OF COL OFF                 ENDOF 
 [CHAR] $ OF >EOL                    ENDOF 
 [CHAR] : OF COMMAND-LINE            ENDOF 
 [CHAR] a OF COL 1+!   INSERT-TEXT   ENDOF 
 [CHAR] b OF CMD-b                   ENDOF 
 [CHAR] d OF CMD-d                   ENDOF 
 [CHAR] h OF GOLEFT                  ENDOF 
 [CHAR] i OF INSERT-TEXT             ENDOF 
 [CHAR] j OF GODOWN                  ENDOF 
 [CHAR] k OF GOUP                    ENDOF 
 [CHAR] l OF GORIGHT                 ENDOF 
 [CHAR] o OF OPEN-LINE               ENDOF 
 [CHAR] p OF CMD-p                   ENDOF 
 [CHAR] r OF REPLACE-CHAR            ENDOF 
 [CHAR] u OF CMD-UNDO                ENDOF 
 [CHAR] w OF CMD-w                   ENDOF 
 [CHAR] x OF CMD-x                   ENDOF 
 [CHAR] y OF CMD-y                   ENDOF 
 ENDCASE 
 ;

 : UPPER-KEYS 
  DUP CASE 
 [CHAR] G OF ARG# GOTOLINE LIST HOME ENDOF 
 [CHAR] A OF >EOL INSERT-TEXT        ENDOF  
 [CHAR] D OF CMD-D                   ENDOF 
 [CHAR] H OF HOME                    ENDOF  
 [CHAR] J OF  ( JOIN FUTURE)         ENDOF 
 [CHAR] L OF 23 ROW !                ENDOF 
 [CHAR] M OF 12 ROW !                ENDOF 
 [CHAR] P OF CMD-P                   ENDOF 
 [CHAR] R OF REPLACE-TEXT            ENDOF 
 [CHAR] Y OF CUTLINES                ENDOF 
 [CHAR] ~ OF CHANGE-CASE             ENDOF 
    ENDCASE
;


\ ..................................
\ command mode loop 
DECIMAL
: COMMANDER  ( -- )
  LIST   
  HOME 
  BEGIN
  \  DEBUG 
    ROW/COL AT-XY CMDKEY 
    CTRL-KEYS 
    LOWER-KEYS
    UPPER-KEYS 
    DROP
  AGAIN 
;

\ File Stuff ...
\ massage input string into a proper path and save in FILENAME 
: >FILENAME ( addr len --  addr len)  TOUPPER +PATH  2DUP FILENAME PLACE ;

\  ==========[ VI command line commands ]===========
\ vi commands are lower case 

\ new inits to 1 empty line
: new    TXTBUFFER 8K PURGE   1 TOPLINE ! ; 

: -R    READONLY ON ; 
: -M    READONLY OFF ;

: x   PROMPT ." Saving..." FILENAME COUNT SAVE  CR ABORT ;
: q   x  ;
: q!  CR ." Not saved"   ABORT ;

: w     PARSE-NAME DUP 
        IF >FILENAME 
        ELSE 2DROP FILENAME COUNT 
        THEN SAVE ;

: w!    -M w ;
: wq     x q ;

: G      GOTOLINE  LIST ;

: r ( <filename> )
    PARSE-NAME TOUPPER  +PATH 
    DV80 R/O OPEN-FILE ?FILERR >R
    LINES @      
    BEGIN
      R@ SELECT 2 FILEOP 0= 
    WHILE
      (GODOWN) S"  " ELINE# INSERTLN 
      TEMP$ DUP FGET ELINE# INSERTLN 
      LINES 1+!
    REPEAT
    R> CLOSE-FILE DROP
    LIST
    LINES @ SWAP -  PROMPT  . ." lines added"  
;


\ add the ls and ls-l  commands 
INCLUDE DSK2.VILS
INCLUDE DSK2.VILS-L

\ internal use version to start the editor with stack string argument
: (vi) ( addr len -- ) 
  DUP 0=
  IF
    2DROP  new  FILENAME OFF
  ELSE 
    >FILENAME READ-FILE
    1 TOPLINE ! 
  THEN PROMPT .FSTATS COMMANDER ;

\ SHELL COMMANDS 
: vi    PARSE-NAME -M (vi) ; 
: view  PARSE-NAME -R (vi) ;
: e     COMMANDER ;    
: help  S" VIMANPAGE" -R (vi) ;

: cd     PARSE-NAME ?DOT TOUPPER  $HOME PLACE ;
: cold   COLD ;
: clear  PAGE ;

: rm     PARSE-NAME TOUPPER +PATH  
         CR ." Delete " 2DUP TYPE SPACE 
         CR ." Are you sure? (Y/N)" 
         KEY UPCASE DUP EMIT  [CHAR] Y =
         IF 
            DV80 R/W DELETE-FILE DROP 
        ELSE 2DROP CR ." Cancelled" CR 
        THEN 
;

\ use with OPEN-TTY 
HEX 
: BA=1200     01A0 BPS ! ;
: BA=4800     0068 BPS ! ;
: BA=2400     00D0 BPS ! ;
\ : BA=9600  ( -- ) 0034 BPS ! ;
\ : BA=19200 ( -- ) 001A BPS ! ;
: BA=38400 ( -- ) 000D BPS ! ;

\ exit to TI99 title page, machine code 
CODE bye  
  04E0 , 83C4 ,  \ 83C4 @@ CLR,   clear interrupt vector
  0420 , 0000 ,  \ 0000 @@ BLWP,  ROM reset vector is at 0000
  NEXT, 
ENDCODE 
DECIMAL 

\ : ?FILE  ( addr len --  addr len) 
\  2DUP DV80 R/O OPEN-FILE   
\  IF   DROP CR CR ." ** " TYPE  ."  not found" CR  
\  ELSE CLOSE-FILE  
\  THEN 
\ ; 

: VDP.BOOT.SCREEN
  VDP.PAGE S" VI99 TTY Editor" VDP.TYPE
  VDP.CR S" RS232/1 8,N,1 RTS/CTS handshake" VDP.TYPE
  VDP.CR
  VDP.CR S" Press enter on your terminal" VDP.TYPE
  VDP.CR S" to set baud rate" VDP.TYPE
;

\ Boot the program 
: VI99
  WARM    
  ALWAYS ON   KILL-BUFFER  
  GETDEV      READONLY OFF 
 \ CR  S" VI99CONFIG" +PATH INCLUDED 

  VDP.BOOT.SCREEN 
  AUTOBAUD 

  PAGE ." VI99 TTY Shell 0.91  12Aug2023   Brian Fox"
  CR
  CR ." help to see manpage"
  CR ." ls or ls-l to see files on disk"
  CR ." cd dsk?.  to change disk"
  CR ." vi <path> to edit a file"
  CR ." Type bye to exit vi99 shell"
  
  ['] NEWQUIT ['] QUIT CELL+ !  \ patch quit (Forth interpreter)

  DECIMAL 
  ABORT ;

HERE SWAP -  DECIMAL . .( bytes)  

LOCK 

INCLUDE DSK1.SAVESYS
' VI99  SAVESYS DSK2.VI99TTY 

