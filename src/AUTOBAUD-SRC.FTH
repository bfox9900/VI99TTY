\ * autobaud for 9902 for CAMEL TTY Forth  July 2023
\ * Source: Software Development, Texas Instruments 1981

\ Polls the Receive Line Input (RIN) BIT and counts the time
\ it takes to return to 0. This count tells you the tms9902
\ speed to READ 8 bits ie: the baud rate of the sender.
\ Use that number to look up the correct baud rate divisor
\ and set the TI-99 UART baud rate. Voila!

\ 9902 bit # references 
\    13 EQU LDIR     \ "load interval register"
\    16 EQU RTSON    \ request to send
\    18 EQU RIENB    \ rcv interrupt enable
\    21 EQU RXRL     \ receive register loaded bit
\    22 EQU TXRE     \ transmit register empty bit
\    27 EQU -DSR     \ NOT data set ready
\    28 EQU -CTS     \ NOT clear to send
\    31 EQU RESET    \ 9902 reset bit

\ Defined in the kernel. Here for reference 
\ HEX 
\ 1300 CONSTANT CARD  \ card CRU base address 
\ 0040 CONTANT  UART  \ RS232/1 uart offset from base
\ VARIABLE PROTO      \ holds protocol
\ VARIABLE BPS        \ holds baud rate divisor for OPEN-TTY 


NEEDS DUMP FROM DSK1.TOOLS
NEEDS MOV, FROM DSK1.ASM9900 

MARKER REMOVE
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


CODE  AUTOBAUD ( -- n)
DECIMAL 
        TOS PUSH,          \ TOS=R4, save R4 to free up for use
        R3 CLR,            \ this is our time counter register  
        CARD @@ R12 MOV,   \ load the card address
        7 SBO,             \ LED on
         5 SBZ,            \ CARD CTS line LOW. You are clear to send

        UART @@ R12 ADD,   \ add 9902 port address
        31 SBO,            \ reset UART
        PROTO @@ 8 LDCR,   \ set protocol (8,n,1)
        13 SBZ,            \ reset LDIR , allows setting baud rate

\ ******* critical time measuring loops ********
\ ** HAD TO ADD THIS INSTRUCTION TO ORIGINAL TI CODE **
        18 SBZ,            \ RIENB resets bit 15 
\ * wait for start bit to go to "mark" (logic 0)
        BEGIN,
          15 TB, 
        NE UNTIL,       
\ * wait until rin goes back to "space" (logic 1)
        BEGIN,
          R3 INC,       
          15 TB,          
        EQ UNTIL,         
        18 SBZ,             \ reset 9902 rcv buffer
\ ************************************************

\ * find the baud rate timer divisor in BAUDTB 
        TOS BAUDTB 2- LI,  \ set table base address-2 in R4 
        BEGIN, 
          TOS INCT,        \ select table record  
          R3 *TOS+ CMP,    \ compare counter to table record, bump R4 
        LE UNTIL, 

\ * baud rate found - set receive and transmit data interval
        *TOS 12 LDCR,      \ need to write 12 bits.
        *TOS bps @@ MOV.   \ and save new divisor in the bps variable

\ * read a char and throw it away
        BEGIN, 
           21 TB,         \ test receive register loaded bit  
        EQ UNTIL,         \ loop until true 
        18 SBZ,           \ reset 9902 rcv buffer
        
        CARD @@ R12 MOV,  \ select the card address
        7 SBZ,            \ LED off
        
        TOS POP,          \ refill top of stack cache register  
        NEXT,
ENDCODE

HERE SWAP - DECIMAL .  .( bytes )
