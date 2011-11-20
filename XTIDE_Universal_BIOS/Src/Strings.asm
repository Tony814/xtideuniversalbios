; Project name	:	XTIDE Universal BIOS
; Description	:	Strings and equates for BIOS messages.

%ifdef MODULE_STRINGS_COMPRESSED_PRECOMPRESS
%include "Display.inc"
%endif

; Section containing code
SECTION .text

; POST drive detection strings
g_szRomAt:		db	"%s @ %x",LF,CR,NULL

g_szMaster:				db	"IDE Master at ",NULL 
g_szSlave:				db	"IDE Slave  at ",NULL
g_szDetect:				db	"%s%x: ",NULL					   ; IDE Master at 1F0h:
g_szDetectCOM:			db  "%sCOM%c/%u%c: ",NULL              ; IDE Master at COM1/115K:		
g_szDetectCOMAuto:		db  "%sCOM Detect: ",NULL			   ; IDE Master at COM Detect:
				
; Boot loader strings
g_szTryToBoot:			db	"Booting from %s %x",ANGLE_QUOTE_RIGHT,"%x",LF,CR,NULL
g_szBootSectorNotFound:	db	"Boot sector "
g_szNotFound:			db	"not found",LF,CR,NULL
g_szReadError:			db	"Error %x!",LF,CR,NULL

; Boot menu bottom of screen strings
g_szFDD:		db	"FDD     ",NULL
g_szHDD:		db	"HDD     ",NULL
g_szRomBoot:	db	"ROM Boot",NULL
g_szHotkey:		db	"%A%c%c%A%s%A ",NULL


; Boot Menu menuitem strings
g_szDriveNum:	db	"%x ",NULL
g_szFDLetter:	db	"%s %c",NULL
g_szFloppyDrv:	db	"Floppy Drive",NULL
g_szforeignHD:	db	"Foreign Hard Disk",NULL

; Boot Menu information strings
g_szCapacity:	db	"Capacity : ",NULL
g_szSizeSingle:	db	"%s%u.%u %ciB",NULL
g_szSizeDual:	db	"%s%5-u.%u %ciB /%5-u.%u %ciB",LF,CR,NULL
g_szCfgHeader:	db	"Addr.",SINGLE_VERTICAL,"Block",SINGLE_VERTICAL,"Bus",  SINGLE_VERTICAL,"IRQ",  SINGLE_VERTICAL,"Reset",LF,CR,NULL
g_szCfgFormat:	db	"%s"   ,SINGLE_VERTICAL,"%5-u", SINGLE_VERTICAL,"%s",SINGLE_VERTICAL," %2-I",SINGLE_VERTICAL,"%5-x",  NULL
		
g_szAddressingModes:					
g_szLCHS:		db	"L-CHS",NULL
g_szPCHS:		db	"P-CHS",NULL
g_szLBA28:		db	"LBA28",NULL
g_szLBA48:		db	"LBA48",NULL
g_szAddressingModes_Displacement equ (g_szPCHS - g_szAddressingModes)
;
; Ensure that addressing modes are correctly spaced in memory
;
%ifndef CHECK_FOR_UNUSED_ENTRYPOINTS		
%if g_szLCHS <> g_szAddressingModes
%error "g_szAddressingModes Displacement Incorrect 1"
%endif
%if g_szPCHS <> g_szLCHS + g_szAddressingModes_Displacement
%error "g_szAddressingModes Displacement Incorrect 2"
%endif
%if g_szLBA28 <> g_szPCHS + g_szAddressingModes_Displacement		
%error "g_szAddressingModes Displacement Incorrect 3"
%endif
%if g_szLBA48 <> g_szLBA28 + g_szAddressingModes_Displacement		
%error "g_szAddressingModes Displacement Incorrect 4"
%endif
%endif		
		
g_szFddUnknown:	db	"%sUnknown",NULL
g_szFddSizeOr:	db	"%s5",ONE_QUARTER,QUOTATION_MARK," or 3",ONE_HALF,QUOTATION_MARK," DD",NULL
g_szFddSize:	db	"%s%s",QUOTATION_MARK,", %u kiB",NULL	; 3�", 1440 kiB

g_szFddThreeHalf:		db  "3",ONE_HALF,NULL
g_szFddFiveQuarter:		db  "5",ONE_QUARTER,NULL		
g_szFddThreeFive_Displacement equ (g_szFddFiveQuarter - g_szFddThreeHalf)

g_szBusTypeValues:		
g_szBusTypeValues_8Dual:		db		"D8 ",NULL
g_szBusTypeValues_8Reversed:	db		"X8 ",NULL
g_szBusTypeValues_8Single:		db		"S8 ",NULL
g_szBusTypeValues_16:			db		" 16",NULL
g_szBusTypeValues_32:			db		" 32",NULL
g_szBusTypeValues_Serial:		db		"SER",NULL
g_szBusTypeValues_Displacement equ (g_szBusTypeValues_8Reversed - g_szBusTypeValues)
;
; Ensure that bus type strings are correctly spaced in memory
;
%ifndef CHECK_FOR_UNUSED_ENTRYPOINTS				
%if g_szBusTypeValues_8Dual <> g_szBusTypeValues
%error "g_szBusTypeValues Displacement Incorrect 1"
%endif
%if g_szBusTypeValues_8Reversed <> g_szBusTypeValues + g_szBusTypeValues_Displacement
%error "g_szBusTypeValues Displacement Incorrect 2"		
%endif
%if g_szBusTypeValues_8Single <> g_szBusTypeValues_8Reversed + g_szBusTypeValues_Displacement
%error "g_szBusTypeValues Displacement Incorrect 3"				
%endif
%if g_szBusTypeValues_16 <> g_szBusTypeValues_8Single + g_szBusTypeValues_Displacement		
%error "g_szBusTypeValues Displacement Incorrect 4"				
%endif
%if g_szBusTypeValues_32 <> g_szBusTypeValues_16 + g_szBusTypeValues_Displacement
%error "g_szBusTypeValues Displacement Incorrect 5"				
%endif
%if g_szBusTypeValues_Serial <> g_szBusTypeValues_32 + g_szBusTypeValues_Displacement
%error "g_szBusTypeValues Displacement Incorrect 6"				
%endif
%endif
		
g_szSelectionTimeout:	db		DOUBLE_BOTTOM_LEFT_CORNER,DOUBLE_LEFT_HORIZONTAL_TO_SINGLE_VERTICAL,"%ASelection in %2-u s",NULL

g_szDashForZero:		db		"- ",NULL


;------------------------------------------------------------------------------------------
; 
; Tables for StringsCompress.pl
;
;$translate{ord(' ')} = 0;
;$translate{172}      = 1;     # ONE_QUARTER
;$translate{171}      = 2;     # ONE_HALF
;$translate{179}      = 3;     # SINGLE_VERTICAL
;$translate{175}      = 4;     # ANGLE_QUOTE_RIGHT
;$translate{ord('!')} = 5;
;$translate{ord('"')} = 6;
;$translate{ord(',')} = 7;
;$translate{ord('-')} = 8;
;$translate{ord('.')} = 9;
;$translate{ord('/')} = 10;
;$translate{ord('1')} = 11;    
;$translate{ord('2')} = 12;
;$translate{ord('3')} = 13;
;$translate{ord('4')} = 14;
;$translate{ord('5')} = 15;
;$translate{ord('6')} = 16;
;$translate{ord('8')} = 17;
;$translate{200}      = 18;    # DOUBLE_BOTTOM_LEFT_CORNER
;$translate{181}      = 19;    # DOUBLE_LEFT_HORIZONTAL_TO_SINGLE_VERTICAL
;
; Formats begin immediately after the last Translated character (they are in the same table)
;
;$format_begin = 20;
;
;$format{"s"}   = 20;        # n/a
;$format{"c"}   = 21;        # n/a
;$format{"2-I"} = 22;        # must be even
;$format{"u"}   = 23;        # must be odd
;$format{"5-u"} = 24;        # must be even
;$format{"x"}   = 25;        # must be odd
;$format{"5-x"} = 26;        # must be even
;$format{"nl"}  = 27;        # n/a
;$format{"2-u"} = 28;        # must be even
;$format{"A"}   = 29;        # n/a
;
; NOTE: The last $format cannot exceed 31 (stored in a 5-bit quantity).
;
; Starting point for the "normal" range, typically around 0x40 to cover upper and lower case
; letters.  If lower case 'z' is not used, 0x3a can be a good choice as it adds ':' to the 
; front end.
;
;$normal_base = 0x3a;
;
; End of StringsCompress.pl information
;
;------------------------------------------------------------------------------------------




