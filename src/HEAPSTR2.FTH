\ heapstr2.fth  loads dv80 into heap as strings Sept 2022 Brian Fox
\ Loads file data as counted strings in low RAM.
\ Provides high density storage

\ Updates Jun 5 2023
\ added INSERTLN, DELETELN, REPLACELN
\ added SEEK$ variable to remember last seek string
\ PURGE now inserts a null string as the first string.


NEEDS READ-LINE FROM DSK1.ANSFILES

HERE

\ ===[ heap management ]====
\ low RAM is file TXTBUFFER
HEX
2000 CONSTANT TXTBUFFER  \ base address of the heap
2000 CONSTANT 8K      \ max size of the heap
TXTBUFFER 8K +  CONSTANT BUFFEND

DECIMAL
\ variable H is our memory management pointer

: HALLOT ( n --)  \ WITH memory protection
  H
  2DUP @ + BUFFEND TXTBUFFER WITHIN ABORT" HEAP error"
  +! ;

: HEAP   H @ ;
: HC,   ( c --)  HEAP C!  1 HALLOT ;  \ compile c into heap

: ERASE  0 FILL ;
\ purge sets the heap to addr and then erases it & compiles a null string
: PURGE    ( addr len -- ) OVER H !  ERASE  0 HC,  LINES OFF  ;

: FSIZE    ( -- n) HEAP TXTBUFFER - ;

\ : NEXT$    ( addr -- addr' ) COUNT + ;
HEX
CODE NEXT$ ( addr -- addr' )
     C044 , \   TOS R1 MOV,
     0584 , \      TOS INC,
     D051 , \ R1 ** R1 MOVB,
     0981 , \    R1  8 SRL,
     A101 , \   R1 TOS ADD,
     NEXT,
ENDCODE

: LEN  ( $adrr -- n)  POSTPONE C@ ; IMMEDIATE  \ syntax sugar

: NTH ( addr n -- Caddr)  0 ?DO NEXT$ LOOP ; \ seek to nth line

DECIMAL
: V$,  ( Vaddr u -- ) \ compile VDP stack string as counted string in HEAP
      1 MAX               \ smallest string we store is 1 byte
      TUCK                \ tuck a copy of length under Vaddr
      DUP HC,             \ compile the length in heap
      HEAP SWAP VREAD     \ copy VRAM to RAM
      HALLOT ;            \ Allocate the heap space

: FDATA  ( -- Vaddr len ) [PAB FBUFF] V@  [PAB CHARS] VC@ ;

\ seek to the address of the LINE# and remember the string address
VARIABLE SEEK$
: SEEKLN  ( line# -- $addr) TXTBUFFER SWAP NTH DUP SEEK$ ! ;

\ open space for a string in HEAP, return the HEAP address
: MAKEROOM ( len line# -- addr)
  OVER 1+ HALLOT
  SEEKLN DUP>R     ( len $ )   ( r: $addr)
  OVER R@ + 1+     ( len $ $+len+1 )
  HEAP R@ - 0 MAX  ( len $ $' size )
  MOVE R> ;

: DELLN ( lnaddr-- len )
  DUP NEXT$ SWAP  ( $2 $1)
  DUP C@ 1+ DUP>R ( $2 $1 len)
  FSIZE SWAP -  MOVE R> ;

: DEALLOT ( n -- )
  HEAP OVER - C/L@ ERASE
  HEAP SWAP - TXTBUFFER  MAX H ! ;

\ ----------------------------
\ user API ...
 usage:  S" DSK1.MYFILE" READ-FILE
: READ-FILE ( addr len -- )
        TXTBUFFER 8K PURGE
        DV80 R/O OPEN-FILE ?FILERR >R

        LINES OFF
        BEGIN
           R@ SELECT 2 FILEOP 0= \ faster than ANS read-line
        WHILE
           FDATA V$,
           LINES 1+!
        REPEAT
        R> CLOSE-FILE DROP
;

\ usage:  S" DSK1.MYFILE" WRITE-FILE
: WRITE-FILE ( addr len -- )
        DV80 W/O  OPEN-FILE ?FILERR >R
        TXTBUFFER NEXT$ ( caddr )
        BEGIN
          DUP LEN
        WHILE
          DUP COUNT R@ WRITE-LINE ?FILERR
          NEXT$
        REPEAT
        DROP
        R> CLOSE-FILE DROP ;

\ len must always be MORE THAN ZERO
: INSERTLN ( addr len line# --) MAKEROOM PLACE ;
: DELETELN ( line# --) SEEKLN DELLN DEALLOT ;
: REPLACELN  ( addr len line# --) DUP DELETELN  INSERTLN ;

DECIMAL HERE SWAP - CR . .( bytes)   

\ test code
\ : TESTSEEK  TMR@   TXTBUFFER 10 NTH TMR@ NIP - . ;
\ : PRINT ( $ -- ) COUNT ( C/L@ 1- MIN)  CR TYPE ;
\ : .HEAP ( -- ) TXTBUFFER BEGIN  DUP LEN WHILE   DUP PRINT NEXT$   REPEAT DROP ;
