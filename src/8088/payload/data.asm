
MemTop              equ 0A000h

Data_Segment		equ MemTop - 30h

; -----------------------------------------------------------------
; Virtual cursor position.
; This is where the cursor would be on the PC.
; -----------------------------------------------------------------

Data_CursorVirtual:		equ 0000h

; -----------------------------------------------------------------
; Physical cursor position.
; This is where the cursor actually is on the CBM.
; -----------------------------------------------------------------

Data_CursorPhysical:	equ 0002h

; -----------------------------------------------------------------
; Cursor visibility (00 = visible, 80 = invisible).
; -----------------------------------------------------------------

Data_CursorVisible:	    equ 0004h

; Unused byte

; Unused byte

; -----------------------------------------------------------------
; Debug flag - valid only in in debug mode.
; -----------------------------------------------------------------

Data_Debug:			equ 0007h

; -----------------------------------------------------------------
; Memory size in segments.
; -----------------------------------------------------------------

Data_MemSize:		equ 0008h

; -----------------------------------------------------------------
; Tick count helper.
; -----------------------------------------------------------------

Data_Ticks:			equ 000Ah

; -----------------------------------------------------------------
; Boot flag - set if the system is booting.
; -----------------------------------------------------------------

Data_Boot:			equ 000Ch

; -----------------------------------------------------------------
; SD card presence flags.
; -----------------------------------------------------------------

Data_SD:			equ 000Dh

; -----------------------------------------------------------------
; Video refresh counter.
; -----------------------------------------------------------------

Data_Refresh:		equ 000Eh

; -----------------------------------------------------------------
; Active video screen page.
; -----------------------------------------------------------------

Data_ScreenPage:	equ 000Fh

Data_Length			equ 16

