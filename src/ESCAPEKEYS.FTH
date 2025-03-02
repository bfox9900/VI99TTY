\ ESCAPEKEYS.FTH  
\ Adapted from block editor in Mecrisp Forth, Mathias Luft. 

\ TI-99 is very slow and catching all the values that come from
\ the keyboard when the arrow keys, pgup, pgup down are sent
\ can be a problem.  This idea simplifies interpreting escape sequences 

NEEDS DUMP FROM DSK1.TOOLS 
NEEDS CASE FROM DSK1.CASE 

: HANDLER ( --)
   BEGIN
    KEY
    DUP 32 -1 >
    IF  EMIT 
    ELSE   
      .S 
      CASE \ HANDLE CONTROL CHARACTERS
         8 OF CR ." BACKSPACE REDRAW-LINE" ENDOF
         9 OF CR ." TAB" 
        10 OF CR ." linefeed" ENDOF
        13 OF CR ." carriage return" ENDOF
        17 OF CR ." EOL"   ENDOF 
  
        27 OF
            KEY 91 = IF 
                KEY CASE
                50 OF KEY 126 = IF CR ." TOGGLEMODE"         THEN ENDOF
                51 OF KEY 126 = IF CR ." DELETE REDRAW-LINE" THEN ENDOF
                65 OF CR ." UP"   ENDOF
                66 OF CR ." DOWN" ENDOF
                67 OF CR ." RIGHT-WRAP" ENDOF
                68 OF CR ." LEFT-WRAP"  ENDOF
                70 OF CR ." GOTOEOL"    ENDOF   
                72 OF CR ." FLUSHLEFT" ENDOF 
            ENDCASE
            THEN 
            ENDOF 
      ENDCASE 
    THEN
    AGAIN ; 