\ * autobaud for 9902 for CAMEL TTY Forth  July 2023
\ * Source: Software Development, Texas Instruments 1981
\ MACHINE CODE version so you don't need the Assembler 
\ SOURCE CODE: AUTOBAUD-SRC.FTH

\ NEEDS DUMP FROM DSK1.TOOLS
\ NEEDS MOV, FROM DSK1.ASM9900

HERE
HEX
CREATE BAUDTB
\  counter baudrate
\ -------- --------
    0002  , 000D ,    \ 38400
    0004  , 001A ,    \ 19200
    0008  , 0034 ,    \ 9600
    000F  , 0068 ,    \ 4800
    001E  , 00D0 ,    \ 2400
    003C  , 01A0 ,    \ 1200
    0078  , 0340 ,    \  600
    00F0  , 04D0 ,    \  300
    01E0  , 0638 ,    \  110

CODE AUTOBAUD
    0646 , C584 ,
    04C3 ,
    C320 , CARD ,
    1D07 , 1E05 ,
    A320 , UART , 1D1F ,
    3220 , PROTO ,
    1E0D , 1E12 ,
    1F0F , 13FE ,
    0583 , 1F0F ,
    16FD , 1E12 ,
    0204 , BAUDTB 2- ,
    05C4 , 8D03 , 1BFD ,
    3314 , 1F15 ,
    16FE , 1E12 ,
    C320 , CARD ,
    1E07 ,
    C136 ,
    NEXT,
ENDCODE

HERE SWAP - DECIMAL  SPACE .  .( bytes )