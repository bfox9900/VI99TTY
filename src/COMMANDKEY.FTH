\ COMMANDKEY.FTH      Jun 11 2023 Brian Fox 
\ number argument collector used to get numeric arguments for VI commands

DECIMAL 
CREATE ArgBUFF 6 ALLOT    ArgBUFF 6 0 FILL 

\ append char to buffer 
: ARG$+   ( char -- ) HERE C!  HERE 1 ArgBUFF +PLACE ; 
: CLRARG#  ( -- ) ArgBUFF OFF ;

: ARG#    ( -- n)  \ n always 1 or more 
  ArgBUFF COUNT NUMBER? ( n ?) \ ?=0 means valid conversion
  IF   DROP HONK 0  
  ELSE 0 MAX 
  THEN CLRARG# ;


\ if key is a digit, accumulate as a decimal number
: ACCUMULATE ( char -- char' )
  CLRARG# ARG$+                \ it's number key so start a new arg string 
  BEGIN 
    KEY DUP 
    [CHAR] 0 [CHAR] 9 BETWEEN \ get next key, 0 is valid, test for digit 
  WHILE                       \ while it is a digit 
    ARG$+                     \ append to ARG$ 
  REPEAT                      \ end loop and return last key value  
;

HEX 
: CMDKEY ( -- char ) \ accumulate numbers or return key stroke 
  KEY DUP  [CHAR] 1 [CHAR] 9 BETWEEN IF ACCUMULATE THEN 
; 
