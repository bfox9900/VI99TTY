\ DRIVEMNGR.FTH for TI-99 Camel99 Forth   Brian Fox

NEEDS WRITE-FILE FROM DSK2.HEAPSTR2

: ?DOT   ( $ len -- $ len) 
  2DUP  [CHAR] . SCAN NIP 0= ABORT" Missing '.'" ;

\ ========================
\ get current drive string
\ ========================
DECIMAL
24 USER 'R12  \ access register 12 as a user variable. ;-) 

HEX
CODE 0SBO  ( -- ) 1D00 ,  NEXT, ENDCODE
CODE 0SBZ  ( -- ) 1E00 ,  NEXT, ENDCODE

\ for reference 
\ 83D0 CONSTANT DISKCARD
\ 83D2 CONSTANT DEVLIST

CREATE $HOME 8 ALLOT
: +PLACE  ( addr n $ -- )  2DUP 2>R  COUNT +  SWAP MOVE 2R> C+! ;

: GETDEV  (  --) \ $HOME will contain "DSK1." 
  83D0 @ 'R12 !
  0SBO
  83D2 @ 4 + COUNT $HOME PLACE
  0SBZ
  S" ." $HOME +PLACE \ add the '.' char
;

\ append missing path to a filename 
: +PATH ( addr len -- addr' len') \ add disk path if missing from filename 
  2DUP [CHAR] . SCAN NIP 0=       \ scan for '.' char 
  IF                              \ if '.' not found  
  \ PAD OFF                       \ set pad length to zero  
    $HOME COUNT PAD PLACE         \ place the current drive string in PAD 
   ( addr len ) PAD +PLACE        \ append the given string argument 
    PAD COUNT                     \ return the full path as stack string pair
  THEN                                 
;
