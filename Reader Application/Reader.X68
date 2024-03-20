*-----------------------------------------------------------
* Title      : Output.bin Reader
* Written by :
* Date       :
* Description:
*-----------------------------------------------------------

ALL_REG         REG         D0-D7/A0-A6

*Tasks

DISPLAY_STRING_CR       EQU     13
DISPLAY_STRING_NCR      EQU     14
DISPLAY_GETNUM_CR       EQU     18
DISPLAY_UNUM            EQU     15

DECIMAL                 EQU     10

*ReadSection Stack Vars
SECTION                 EQU     0
FILE_ADDRESS            EQU     32

*File Header
HEADER_SECTIONS         EQU     0
HEADER_SECT_OFFSET      EQU     4
HEADER_SECT_SIZE        EQU     4

*Section Header
SECT_BYTE_OFFSET        EQU     2
SECT_BYTE_SIZE          EQU     4
SECT_WORD_OFFSET        EQU     6
SECT_WORD_SIZE          EQU     8
SECT_LONG_OFFSET        EQU     10
SECT_LONG_SIZE          EQU     12

*PrintNum
NUM_TO_PRINT            EQU     0

*PrintFloat
DIV_NUM                 EQU     0
DIVISOR                 EQU     4

    ORG    $1000
    
;Num to print in d0    
PrintNum:
    movem.l ALL_REG,-(sp)
    
    move.l  #DISPLAY_UNUM,d0
    move.l  NUM_TO_PRINT(sp),d1
    move.l  #DECIMAL,d2
    TRAP    #15

    movem.l (sp)+,ALL_REG
    rts    

;num to convert in d0
Long_ToBigEndian:
    rol.w   #$08,d0
    swap    d0
    rol.w   #$08,d0
    rts
    
Word_ToBigEndian:
    rol.w   #$08,d0
    rts    

;Num to print in d0
;Divisor in d1
PrintFloat:
    movem.l ALL_REG,-(sp)
    
     
    move.l  DIV_NUM(sp),d3         ;Get the predivided register
    
    
    move.l  #DISPLAY_UNUM,d0   
    clr.l   d1 
    move.w  d3,d1                   ;Move quotient to d1
    move.l  #DECIMAL,d2
    TRAP    #15
    
    clr.l   d1
    swap    d3                          ;move remainder to lower word
    move.w  d3,d1                       ;move remainder to d1
    mulu.w  #1000,d1                    ;Multiply by 1000 to get 3 decimal places
    move.l  DIVISOR(sp),d2              ;Get Divisor
    divu.w  d2,d1                       ;Divide d1 by original divisor
    
    swap    d1
    move.w  #0,d1                       ;Clear Remainder from quotient
    swap    d1
    
    move.l  d1,d0                      ;Move decimal (3 places) to d0
    
    ;---
    ;ROUNDING: See if remainder of decimal / 10 is >= 5
    ;---
    divu.w  #10,d0                      ;Divide by 10
    swap    d0
    cmp.w   #5,d0                       ;Remainder greater than 5?
    BLT     CheckLeadZero
    
    ;Round up
    addi.w  #10,d1
    
CheckLeadZero
    divu.w  #10,d1          ;1000/ 10 = 100, the decimal place we want
    swap    d1
    move.w  #0,d1                    ;Clear Remainder from quotient
    swap    d1
    
    cmpi.l  #10,d1
    BLT     .pf_leadZero
    
    lea     S_Period,a1
    move.l  #DISPLAY_STRING_NCR,d0
    TRAP    #15
    BRA     .pf_float
    
.pf_leadZero
    lea     S_LeadZero,a1
    move.l  #DISPLAY_STRING_NCR,d0
    TRAP    #15
    
.pf_float    
    move.l  #DISPLAY_UNUM,d0   
    move.l  #DECIMAL,d2
    TRAP    #15
    
    movem.l (sp)+,ALL_REG
    rts     
    
    
    

;address to file in a0
;Section to read in d0

ReadSection

    movem.l ALL_REG,-(sp)
    
    lea     NewLine,a1
    move.l  #DISPLAY_STRING_CR,d0
    TRAP    #15
    
    *Clear data
    clr.l   d0
    clr.l   d1
    
    
    move.l  FILE_ADDRESS(sp),a0
    
    ;---
    ;SEARCH HEADER FOR SECTION OFFSET
    ;---  
    
    ;ERROR IF SECTION NUM > SECTIONS
    move.l  HEADER_SECTIONS(a0),d0
    jsr     Long_ToBigEndian
    cmp.l   SECTION(sp),d0
    BLT     .rs_SectToHigh              ;If Section requested is out of range, say so and exit
    
    ;Print Section Header to Output
    lea     S_Section,a1
    move.l  #DISPLAY_STRING_NCR,d0
    TRAP    #15
    
    move.l  SECTION(sp),d0
    jsr     PrintNum
    
    lea     NewLine,a1
    move.l  #DISPLAY_STRING_CR,d0
    TRAP    #15
    
    ;Get Offset of Section
    move.l  SECTION(sp),d0          ;Get what section we are going for
    mulu.w  #HEADER_SECT_SIZE,d0    ;Multiply by size of section size in header
    add.l   d0,a0                   ;Add to offset  
    
    ;Set a0 to Section Start
    move.l  (a0),d0                 ;Get offset value
    move.l   FILE_ADDRESS(sp),a0    ;Rest a0 to start of header
    jsr     Long_ToBigEndian        ;Transfer to Lil Endian
    add.l   d0,a0                   ;Increment by offset
    
    ;---
    ;PARSE SECTION
    ;---
    
    ;---
    ;PARSE BYTES
    ;---
    move.l  a0,a2
    clr.l   d6
    clr.l   d7
    move.w  SECT_BYTE_OFFSET(a0),d6
    rol.w   #08,d6
    move.w  SECT_BYTE_SIZE(a0),d7
    rol.w   #08,d7
    
    ;# of Bytes to Output
    move.l  d7,d0
    jsr     PrintNum
    move.l  d0,d7
    
    ;Bytes filler string
    lea     S_Bytes,a1
    move.l  #DISPLAY_STRING_NCR,d0
    TRAP    #15
    
    clr.l   d0
    clr.l   d3      ;For average holding
    add.l   d6,a2   ;add offset from header to section header address holder 
    move.l  d7,d1   ;Iterate on d1
    
.rs_byteAvg   
    
    move.b  (a2)+,d0    ;Get byte, store in d0
    add.l   d0,d3       ;add byte to d3 for average
    
    subi.l  #1,d1
    BNE     .rs_byteAvg
    
    divu.w  d7,d3       ;Divide total average (d3, long) by size (d7)
    
    ;Print the float value (2 decimal places)
    move.l  d3,d0
    move.l  d7,d1
    jsr     PrintFloat
    
    lea     NewLine,a1
    move.l  #DISPLAY_STRING_CR,d0
    TRAP    #15
    
    ;---
    ;PARSE SHORTS
    ;---    
    move.l  a0,a2
    clr.l   d6
    clr.l   d7
    move.w  SECT_WORD_OFFSET(a0),d6
    rol.w   #08,d6
    move.w  SECT_WORD_SIZE(a0),d7
    rol.w   #08,d7
    
    ;# of Shorts to Output
    move.l  d7,d0
    jsr     PrintNum
    move.l  d0,d7
    
    ;Shorts filler string
    lea     S_Shorts,a1
    move.l  #DISPLAY_STRING_NCR,d0
    TRAP    #15
    
    clr.l   d0
    clr.l   d3      ;For average holding
    add.l   d6,a2   ;add offset from header to section header address holder 
    move.l  d7,d1   ;Iterate on d1
    
.rs_shortAvg
    move.w  (a2)+,d0    ;Get short, store in d0
    rol.w   #08,d0      ;In Little Endian, convert to Big
    add.l   d0,d3       ;add short to d3 for average
    
    subi.l  #1,d1
    BNE     .rs_shortAvg
    
    divu.w  d7,d3       ;Divide total average (d3, long) by size (d7)
    
    ;Print the float value (2 decimal places)
    move.l  d3,d0
    move.l  d7,d1
    jsr     PrintFloat
    
    lea     NewLine,a1
    move.l  #DISPLAY_STRING_CR,d0
    TRAP    #15
    
    ;---
    ;PARSE LONGS
    ;---
    move.l  a0,a2
    clr.l   d6
    clr.l   d7
    move.w  SECT_LONG_OFFSET(a0),d6
    rol.w   #08,d6
    move.w  SECT_LONG_SIZE(a0),d7
    rol.w   #08,d7
    
    ;# of Longs to Output
    move.l  d7,d0
    jsr     PrintNum
    move.l  d0,d7
    
    ;Longs filler string
    lea     S_Longs,a1
    move.l  #DISPLAY_STRING_NCR,d0
    TRAP    #15
    
    clr.l   d0
    clr.l   d3      ;For average holding
    add.l   d6,a2   ;add offset from header to section header address holder 
    move.l  d7,d1   ;Iterate on d1
    
.rs_longAvg
    move.l  (a2)+,d0            ;Get Long, store in d0
    jsr     Long_ToBigEndian    ;In Little Endian, convert to Big
    add.l   d0,d3               ;add long to d3 for average
    
    subi.l  #1,d1
    BNE     .rs_longAvg
    
    divu.w  d7,d3       ;Divide total average (d3, long) by size (d7)
    
    ;Print the float value (2 decimal places)
    move.l  d3,d0
    move.l  d7,d1
    jsr     PrintFloat
    
    lea     NewLine,a1
    move.l  #DISPLAY_STRING_CR,d0
    TRAP    #15
    
.rs_exit    

    lea     NewLine,a1
    move.l  #DISPLAY_STRING_CR,d0
    TRAP    #15
    
    movem.l (sp)+,ALL_REG
    rts

.rs_sectToHigh
    
    lea     NewLine,a1
    move.l  #DISPLAY_STRING_CR,d0
    TRAP    #15
    
    lea     Sect_OR,a1
    move.l  #DISPLAY_STRING_CR,d0
    TRAP    #15

    BRA .rs_exit



START:                  ; first instruction of program

* Put program code here

   
    lea     UserQuery, a1
    move.l  #DISPLAY_GETNUM_CR,d0
    TRAP    #15


loop:     
    cmpi.l  #0,d1
    BLT     InputError
    cmpi.l  #0,d1
    BEQ     exit
    
        
    lea     FileToRead,a0
    move.l  d1,d0
    jsr     ReadSection

errorReturn:
    lea     UserQuery2, a1
    move.l  #Display_GETNUM_CR,d0
    TRAP    #15
    BRA     loop

exit:
    lea     End,a1
    move.l  #DISPLAY_STRING_CR,d0
    TRAP    #15
    
    SIMHALT             ; halt simulator


InputError:

    lea     Input_Error,a1
    move.l  #DISPLAY_STRING_CR,d0
    TRAP    #15
    BRA     errorReturn


* Put variables and constants here

FileToRead  INCBIN  "output.bin"
TEST_OUT    dc.b    'Input acknowledged',0
    
UserQuery   dc.b    'What section would you like to see statistics for? (Enter 0 to exit) ',0 
UserQuery2  dc.b    'What other sections would you like to see statistics for? (Enter 0 to exit) ',0   
End         dc.b    'Exiting: Have a nice day!',0
Input_Error dc.b    'Input must be a number and not negative',0
Sect_OR     dc.b    'Provided Section is out of range of file',0
NewLine     dc.b    '',0

*Output Strings
S_Section   dc.b    'Section ',0
S_Bytes     dc.b    ' bytes, average value ',0
S_Shorts    dc.b    ' shorts, average value ',0
S_Longs     dc.b    ' longs, average value ',0

S_LeadZero  dc.b    '.0',0
S_Period    dc.b    '.',0




    END    START        ; last line of source
    
    
    

















*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
