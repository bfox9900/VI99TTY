\ VDPLINESTK.FTH     June 7 2023 Brian Fox 

\ Concept: 
\ To allow for maximum storage, strings are stored "compressed" as 
\ counted strings starting at HEX C00 in VDP RAM.
\ At the opposite end of VDP RAM, an integer stack keeps track 
\ of the address of each string added to the heap. 

NEEDS VHERE  FROM DSK1.VDPMEM 

HEX 
200  CONSTANT VSTKSIZE

\ leave room for 2 PABs in VDP RAM  (PSZ is pab size) 
VDPTOP PSZ 3 * - CONSTANT VSTACK    

\ integer stack in VDP RAM
VARIABLE VSP                  \ Stack pointer for VDP stack  
: ?VSTACK   VSP @ VSTACK > ABORT" VDP stack underflow" ;
: >VSTK  ( n -- ) -2 VSP +!   VSP @ V! ;
: VSTK@  ( -- VAddr)  VSP @  V@ ;
: VSTK>  ( -- Vaddr)  VSTK@  2 VSP +! ?VSTACK ;

\ compile CPU string into VDP memory, return the address 
: V$,   ( addr len -- Vaddr) 
   VHERE DUP>R  OVER 1+ VALLOT  VPLACE  R> ;

\ get VDP string into CPU RAM as a counted string 
: V$PLACE ( Vaddr len addr -- )  2DUP C! 1+ SWAP VREAD ;

\ -----------------------------------------------------------------
\                 VDP string stack API 
: LDEPTH    ( -- n) VSTACK VSP @ - 2/ ;
: ?VSTKFULL  ( -- ?) LDEPTH VSTKSIZE > ABORT" VDP stack overflow" ;

: $PUSH ( addr len ) ?VSTKFULL  V$, >VSTK ;

: $POP  ( --  addr len ) 
  VSTK> VCOUNT PAD V$PLACE  \ read the string to PAD 
  PAD COUNT                 \ convert to addr,len 
  DUP 1+ NEGATE VALLOT  ;   \ de-allocated the string & count byte

HEX 
:  KILL-BUFFER   VSTACK VSP !   C00 VP ! ;

  KILL-BUFFER   \ inits the VSTACK 
