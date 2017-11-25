

CPU_ACCESS_BANK = $1

;--------------------------------------------------------------------
; Zero page variables
;--------------------------------------------------------------------

tmp_val = $2
buffer_size = $3
old_y = $4
old_x = $5
old_irq = $6
shift_buffer = $10
key_buffer = $20
file_name = $40
load_addr = $43
load_bank = $45

;--------------------------------------------------------------------
; KERNAL variables
;--------------------------------------------------------------------

Status = $9c
CursorLine = $ca
CursorColumn = $cb
LastIndex = $cd
KeybufIndex = $d1
QuoteSwitch = $d2
InsertFlag = $d3
CursorType = $d4
EditorShift = $e0
EditorKey = $e1
IRQVec = $300
GETINVec = $316
SysMemTop = $355
RS232Status = $37a
ScrollFlag = $39b

;--------------------------------------------------------------------
; I/O chip ports
;--------------------------------------------------------------------

CRTC_RegNo = $d800
CRTC_RegVal = $d801
TPI1_ActIntReg = $de07

;--------------------------------------------------------------------
; KERNAL routines
;--------------------------------------------------------------------

DO_GETIN = $f43d
RUNCOPRO = $ff72
SETST = $ff90
SETLFS = $ffba
SETNAM = $ffbd
OPEN = $ffc0
CLOSE = $ffc3
CHKIN = $ffc6
CHKOUT = $ffc9
CLRCH = $ffcc
BASIN = $ffcf
BSOUT = $ffd2
SETTIM = $ffdb
RDTIM = $ffde
GETIN = $ffe4
PLOT = $fff0

;--------------------------------------------------------------------
; Load address for the PRG file
;--------------------------------------------------------------------

    .word $0800
    
;--------------------------------------------------------------------
; Startup routine - sets interrupt vectors and starts 8088 processor.
;--------------------------------------------------------------------
    
    * = $0800
ipc_buffer = *+5

    ldy #$01
    sty CPU_ACCESS_BANK
    dey
    sty load_addr+1
    lda #$1C
    sta load_addr
vector_loop:
    lda vectors, y
    sta (load_addr), y
    iny
    cpy #8
    bne vector_loop
    lda #$0F
    sta CPU_ACCESS_BANK
    jmp RUNCOPRO
        
vectors:
    .word $0000, $0050
    .word $F1E2, $F000

    .dsb ($0830-*), $00
        
;--------------------------------------------------------------------
; Jump table to IPC functions (only for function called from 8088).
; The location of this table is hardcoded to $0830 in the KERNAL.
;--------------------------------------------------------------------

    .word ipc_10_kbd_peek
    .word ipc_11_kbd_in
    .word ipc_12_screen_out
    .word ipc_13_printer_out
    .word ipc_14_modem_out
    .word ipc_15_modem_in
    .word ipc_96_disk_read
    .word ipc_97_disk_write
    .word ipc_18_init
    .word ipc_19_serial_in
    .word ipc_1a_serial_out
    .word ipc_1b_serial_config
    .word 0
    .word ipc_1d_console
    .word ipc_1e_time_set
    .word ipc_1f_time_get
    .word ipc_20_kbd_clear
    .word ipc_21_format
  
;--------------------------------------------------------------------
; Variables used by the code.
;--------------------------------------------------------------------

; Filename to open RS-232 channel.
rs232_param:
    .byt $1e,$00,$20,$20
    
; Secondary address to open RS-232 channel.
rs232_secaddr:
    .byt $03
    
; IEEE device number to use as the modem.
modem_device:
    .byt $05
    
; Secondary address to open the modem channel.
modem_secaddr:
    .byt $00

; Status of the disk operation.
disk_status:
    .byt $a2,$00

; Command to read or write disk sector.    
cmd_u1:
    .byt "u1:8 0 ttt sss",$0d

; Command to read or write disk buffer.
cmd_br:
    .byt "b-p 8 0",$0d

; Command to format disk.
cmd_n:
    .byt "n0:msdos disk,88",$0d

; Filename used to open the data channel.
filename_08:
    .byt "#"

; Filename used to open the command channel.
filename_15:
    .byt "i"

; Temporary variable used in address calculation.
calc_tmp:
    .byt $00

; Last key pressed.
last_key:
    .byt $ff

; Delay before repeating the pressed key.
key_delay:
     .byt $00

;--------------------------------------------------------------------
; IRQ handler function.
; Calls original handler, then launches our keyboard handler.
;--------------------------------------------------------------------
    
my_irq:
    lda #>irq_handler
    pha
    lda #<irq_handler
    pha
    php
    pha
    pha
    pha
    jmp (old_irq)
    
;--------------------------------------------------------------------
; Actual interrupt handler function.
; Checks keyboard scancodes and places them in our own buffer.
;--------------------------------------------------------------------
    
irq_handler:
    sei
    ldx buffer_size
    cpx #$0e
    bcs irq_end             ; End interrupt if buffer full
    lda KeybufIndex
    bne clear_buffer        ; Read keys from the buffer
    lda EditorKey
    cmp #$ff
    bne has_key             ; 
    lda LastIndex
    cmp #$ff
    bne irq_end
    lda #$ff
    sta last_key
    jmp irq_end
has_key:
    cmp last_key
    beq irq_end
    inc key_delay
    lda key_delay
    cmp #$05
    bne irq_end
clear_buffer:
    lda EditorShift
    and #$30
    sta shift_buffer,x
    lda EditorKey
    sta key_buffer,x
    sta last_key
    inx
    stx buffer_size
    lda #$00
    sta key_delay
irq_end:
    lda #$00
    sta KeybufIndex
    pla
    tay
    pla
    tax
    pla
    cli
    rti
    
;--------------------------------------------------------------------
; IPC function 15 - read from modem.
;--------------------------------------------------------------------
    
ipc_15_modem_in:
    ldx #$05
    jsr CHKIN
    jsr BASIN
    sta ipc_buffer+2
ipc_15_end:
    jsr CLRCH
    clc
    jmp ipc_end
    
;--------------------------------------------------------------------
; IPC function 14 - write to modem.
;--------------------------------------------------------------------

ipc_14_modem_out:
    ldx #$05
    jsr CHKOUT
    lda ipc_buffer+2
    jsr BSOUT
    jmp ipc_15_end

;--------------------------------------------------------------------
; Information about IPC function parameters. For every function:
;  * low nibble = number of input parameters.
;  * high nibble = number of output parameters.
; The location of this table is hardcoded to $0910 in the KERNAL.
;--------------------------------------------------------------------        

    .dsb ($0910-*), $00
    
    .byt $00,$01,$02,$03,$04,$05,$06,$07,
    .byt $08,$09,$0a,$0b,$0c,$0d,$0e,$0f
    .byt $40,$40,$23,$23,$23,$30,$4b,$4b
    .byt $40,$30,$23,$25,$00,$55,$04,$40,
    .byt $00,$4b
    
;--------------------------------------------------------------------
; IPC function 11 - read from keyboard.
;--------------------------------------------------------------------
    
ipc_11_kbd_in:
    ldx #$01
    jsr CHKIN
ipc_11_loop:
    jsr GETIN
    beq ipc_11_loop
    sta ipc_buffer+2
    sty ipc_buffer+3
    jsr CLRCH
    clc
    jmp ipc_end
    
;--------------------------------------------------------------------
; IPC function 12 - write to screen.
;--------------------------------------------------------------------

ipc_12_screen_out:
    ldx #$03
    jsr CHKOUT
    lda ipc_buffer+2
    jsr BSOUT
    lda #$00
    sta QuoteSwitch
    sta InsertFlag
    jsr CLRCH
    clc
    jmp ipc_end
    
;--------------------------------------------------------------------
; IPC function 10 - check scancode in keybaord buffer.
;--------------------------------------------------------------------
    
ipc_10_kbd_peek:
    ldx buffer_size
    beq ipc_10_end
    lda key_buffer
    sta ipc_buffer+2
    lda shift_buffer
    sta ipc_buffer+3
ipc_10_end:
    clc
    jmp ipc_end
    
;--------------------------------------------------------------------
; IPC function 20 - clear keyboard buffer.
;--------------------------------------------------------------------    
    
ipc_20_kbd_clear:
    lda #$00
    sta buffer_size
    sta KeybufIndex
    rts
    
;--------------------------------------------------------------------
; IPC function 19 - read from RS-232.
;--------------------------------------------------------------------
    
ipc_19_serial_in:
    ldx #$02
    jsr CHKIN
serial_read:
    jsr DO_GETIN
    sta ipc_buffer+2
    lda RS232Status
    and #$10
    bne serial_read
serial_checkstatus:
    jsr CLRCH
    lda RS232Status
    clc
    and #$77
    beq ipc_19_end
    sec
ipc_19_end:
    jmp ipc_end
    
;--------------------------------------------------------------------
; IPC function 1A - write to RS-232.
;--------------------------------------------------------------------
    
ipc_1a_serial_out:
    ldx #$02
    jsr CHKOUT
    lda ipc_buffer+2
    jsr BSOUT
    jmp serial_checkstatus
    
;--------------------------------------------------------------------
; IPC function 1E - set time-of-day timer.
;--------------------------------------------------------------------
    
ipc_1e_time_set:
    ldy #$00
time_set_1:
    lda ipc_buffer,y
    ldx #$ff
    sec
time_set_2:
    inx
    sbc #$0a
    bcs time_set_2
    adc #$0a
    sta ipc_buffer,y
    txa
    asl
    asl
    asl
    asl
    ora ipc_buffer,y
    sta ipc_buffer,y
    iny
    cpy #$04
    bne time_set_1
    lda ipc_buffer
    cmp #$12
    bcc time_set_3
    sei
    sed
    sbc #$12
    cld
    cli
    ora #$80
    sta ipc_buffer
time_set_3:
    lda #$00
    ror ipc_buffer+3
    ror
    ora ipc_buffer+2
    pha
    lda #$00
    ror ipc_buffer+3
    ror
    ora ipc_buffer+1
    tax
    lda #$00
    ror ipc_buffer+3
    ror
    ror ipc_buffer+3
    ror
    lsr
    ora ipc_buffer
    tay
    pla
    clc
    jmp SETTIM
    
;--------------------------------------------------------------------
; IPC function 1F - read time-of-day timer.
;--------------------------------------------------------------------
    
ipc_1f_time_get:
    jsr RDTIM
    pha
    and #$7f
    sta ipc_buffer+2
    tya
    and #$9f
    php
    and #$1f
    cmp #$12
    bne time_get_1
    lda #$00
time_get_1:
    plp
    bpl time_get_2
    sei
    sed
    clc
    adc #$12
    cld
    cli
time_get_2:
    sta ipc_buffer
    lda #$00
    sta ipc_buffer+3
    tya
    rol
    rol
    rol ipc_buffer+3
    rol
    rol ipc_buffer+3
    txa
    rol
    rol ipc_buffer+3
    lsr
    sta ipc_buffer+1
    pla
    rol
    rol ipc_buffer+3
    ldy #$03
time_get_3:
    lda ipc_buffer,y
    pha
    and #$f0
    lsr
    sta ipc_buffer,y
    lsr
    lsr
    clc
    adc ipc_buffer,y
    sta ipc_buffer,y
    pla
    and #$0f
    adc ipc_buffer,y
    sta ipc_buffer,y
    dey
    bpl time_get_3
    rts
    
;--------------------------------------------------------------------
; IPC function 96 - read disk sector.
;--------------------------------------------------------------------
    
read_init:
    plp
    lda ipc_buffer+2
    and #$02
    bne read_09
    jsr reopen_08
    jmp read_init_2
read_09:
    jsr reopen_09
read_init_2:
    bcs disk_end

ipc_96_disk_read:
    jsr calc_addr
    lda #$31
    jsr set_sector
    php
    lda disk_status
    ora disk_status+1
    cmp #$37
    beq read_init
    plp
    bcs disk_end
    jsr drive_read
    bcs disk_end
    ldx CPU_ACCESS_BANK
    ldy load_bank
    sty CPU_ACCESS_BANK
    ldy #$00
read_loop:
    jsr BASIN
    sta (load_addr),y
    iny
    beq read_end
    lda load_addr+1
    cmp #$ff
    bne read_loop
    tya
    clc
    adc load_addr
    bne read_loop
    inc CPU_ACCESS_BANK
    jmp read_loop
read_end:
    stx CPU_ACCESS_BANK
    clc
disk_end:
    lda disk_status
    sta ipc_buffer+2
    lda disk_status+1
    sta ipc_buffer+3
    jsr ipc_end
    jmp CLRCH
    
;--------------------------------------------------------------------
; IPC function 97 - write disk sector.
;--------------------------------------------------------------------
    
write_init:
    lda ipc_buffer+2
    and #$02
    bne write_09
    jsr reopen_08
    jmp write_init_2
write_09:
    jsr reopen_09
write_init_2:
    bcs disk_end

ipc_97_disk_write:
    jsr calc_addr
    jsr prepare_channel
    bcs disk_end
    ldx #$00
    ldy #$08
loop_br:
    lda cmd_br,x
    jsr BSOUT
    inx
    dey
    bne loop_br
    jsr CLRCH
    jsr read_disk
    bcs disk_end
    cmp #$30
    bne write_init
    jsr CLRCH
    jsr drive_write
    bcs disk_end
    ldx CPU_ACCESS_BANK
    ldy load_bank
    sty CPU_ACCESS_BANK
    ldy #$00
write_loop:
    lda (load_addr),y
    jsr BSOUT
    iny
    bne write_loop
    stx CPU_ACCESS_BANK
    jsr CLRCH
    lda #$32
    jsr set_sector
    jmp disk_end
    
;--------------------------------------------------------------------
; IPC function 96 - read disk sector.
;--------------------------------------------------------------------
    
set_sector:
    sta cmd_u1+1
    lda ipc_buffer+2
    and #$01
    clc
    adc #$30
    sta cmd_u1+5
    ldy ipc_buffer+3
    lda ipc_buffer+4
    jsr bin_to_dec
    sty cmd_u1+7
    stx cmd_u1+8
    sta cmd_u1+9
    ldy ipc_buffer+5
    lda ipc_buffer+6
    jsr bin_to_dec
    sty cmd_u1+11
    stx cmd_u1+12
    sta cmd_u1+13
    jsr prepare_channel
    bcs disk_error
    ldx #$00
loop_u1:
    lda cmd_u1,x
    jsr BSOUT
    inx
    cpx #$0f
    bne loop_u1
    jsr CLRCH
    jsr read_disk
    bcs disk_error
    sta disk_status
    jsr BASIN
    sta disk_status+1
    ora disk_status
    cmp #$30
    bne check_status
    clc
    rts
check_status:
    lda disk_status+1
    cmp #$39
    bne disk_error
    lda disk_status
    cmp #$32
    bne disk_error
    jsr reopen_08
    jmp set_sector
disk_error:
    sec
    rts
    
;--------------------------------------------------------------------
; Disk support functions.
;--------------------------------------------------------------------

; Prepare I/O channels to the disk.    
prepare_error:
    jsr reopen_08
    bcs status_reset
prepare_channel:
    jsr calc_fileno
    jsr CHKOUT
    bcs prepare_error
    ldx #$00
status_reset:
    lda #$3f
    sta disk_status
    sta disk_status+1
    rts
reopen_disk:
    jsr reopen_08
    bcs status_reset
read_disk:
    jsr calc_fileno
    jsr CHKIN
    bcs reopen_disk
    
; Call BASIN function.
my_BASIN:
    jsr BASIN
    rts
    
; Set data channel (8 or 9) as input.
drive_read2:
    jsr reopen_08
    bcs status_reset
drive_read:
    jsr calc_drive
    jsr CHKIN
    bcs drive_read2
    rts
    
; Set data channel (8 or 9) as output.
drive_write2:
    jsr reopen_08
    bcs status_reset
drive_write:
    jsr calc_drive
    jsr CHKOUT
    bcs drive_write2
    rts
    
; Calculate command channel number (15 or 16).
calc_fileno:
    lda ipc_buffer+2
    and #$02
    lsr
    clc
    adc #$0f
    tax
    rts

; Calculate data channel number (8 or 9).
calc_drive:
    lda ipc_buffer+2
    and #$02
    lsr
    clc
    adc #$08
    tax
    rts

; Calculate address from 8088 segment and offset.
calc_addr:
    cli
    sta TPI1_ActIntReg
    lda ipc_buffer+10
    sta load_addr
    lda ipc_buffer+9
    sta load_addr+1
    lda #$00
    sta load_bank
    lda #$04
    sta calc_tmp
loop_addr_1:
    ldy #$00
    ldx #$03
    clc
loop_addr_2:
    lda load_addr,y
    rol
    sta load_addr,y
    iny
    dex
    bne loop_addr_2
    dec calc_tmp
    bne loop_addr_1
    clc
    lda load_addr
    adc ipc_buffer+8
    sta load_addr
    lda load_addr+1
    adc ipc_buffer+7
    sta load_addr+1
    lda load_bank
    adc #$01
    sta load_bank
    rts
    
;--------------------------------------------------------------------
; IPC function 18 - initialize the I/O library.
;--------------------------------------------------------------------
    
ipc_18_init:
    lda #$80
    jsr SETST
    lda #$ff
    sta EditorKey
    jsr reopen_08
    lda #$00
    sta ipc_buffer+2
    jsr reopen_09
    bcs init_diskno
    inc ipc_buffer+2
init_diskno:
    jsr serial_reopen
    lda #$01
    ldx #$00
    stx QuoteSwitch
    stx InsertFlag
    stx buffer_size
    stx KeybufIndex
    jsr SETLFS
    jsr OPEN
    lda #$03
    tax
    jsr SETLFS
    jsr OPEN
    jsr printer_reopen
    lda #$05
    ldx modem_device
    ldy modem_secaddr
    jsr SETLFS
    lda #$00
    jsr SETNAM
    jsr OPEN
    lda #$60
    ldx #$0a
    stx CRTC_RegNo
    sta CRTC_RegVal
    sta CursorType
    lda #$40
    sta ScrollFlag
    sei
    lda IRQVec
    sta old_irq
    lda IRQVec+1
    sta old_irq+1
    lda #<my_irq
    sta IRQVec
    lda #>my_irq
    sta IRQVec+1
    cli
    lda #<my_getin
    sta GETINVec
    lda #>my_getin
    sta GETINVec+1
    jmp ipc_end
    
;--------------------------------------------------------------------
; Further disk support functions.
;--------------------------------------------------------------------

; Reopen data channel 8 to disk #8.
reopen_08:
    lda #$08
    jsr my_CLOSE
    lda #$0f
    jsr my_CLOSE
    lda #$0f
    ldx #$08
    jsr open_15
    bcc do_open_08
    rts
do_open_08:
    lda #$08
    jsr open_08
    rts

; Reopen data channel 9 to disk #9.
reopen_09:
    lda #$09
    jsr my_CLOSE
    lda #$10
    jsr my_CLOSE
    lda #$10
    ldx #$09
    jsr open_15
    bcc do_open_09
    rts
do_open_09:
    lda Status
    and #$80
    beq open_09
    sec
    rts

open_09:
    lda #$09
    jsr open_08
    rts
    
; Open command channel to disk.
open_15:
    ldy #$0f
    jsr SETLFS
    lda #<filename_15
    ldx #>filename_15
    ldy #$0f
    sta file_name
    stx file_name+1
    sty file_name+2
    lda #$01
    ldx #$40
    jsr SETNAM
    jsr my_OPEN
    rts

; Reopen data channel to disk.
open_08:
    tax
    ldy #$08
    jsr SETLFS
    lda #<filename_08
    ldx #>filename_08
    ldy #$0f
    sta file_name
    stx file_name+1
    sty file_name+2
    lda #$01
    ldx #$40
    jsr SETNAM
    jsr my_OPEN
    rts
    
; Reopen channel #3 to RS-232 with new parameters.
serial_reopen:
    lda #$02
    jsr my_CLOSE
    lda #$ff
    sta SysMemTop
    lda #$0f
    sta SysMemTop+1
    sta SysMemTop+2
    lda #$02
    tax
    ldy rs232_secaddr
    jsr SETLFS
    lda #<rs232_param
    ldx #>rs232_param
    ldy #$0f
    sta file_name
    stx file_name+1
    sty file_name+2
    lda #$04
    ldx #$40
    jsr SETNAM
    jmp my_OPEN
    
;--------------------------------------------------------------------
; IPC function 13 - write to printer.
;--------------------------------------------------------------------
    
ipc_13_printer_out:
    lda ipc_buffer+2
    cmp #$0a
    beq printer_skip
    ldx #$04
    jsr CHKOUT
    bcc printer_ok
    jsr printer_reopen
    bcs printer_end
    ldx #$04
    jsr CHKOUT
    bcs printer_end
printer_ok:
    lda ipc_buffer+2
    jsr BSOUT
    jsr CLRCH
printer_skip:
    clc
printer_end:
    jmp ipc_end
    
; Reopen channel #4 to printer in case of error.
printer_reopen:
    lda #$04
    jsr my_CLOSE
    lda #$04
    ldx #$04
    ldy #$67
    jsr SETLFS
    lda #$00
    jsr SETNAM
    jsr my_OPEN
    ldx #$04
    jsr CHKOUT
    lda #$0d
    jsr BSOUT
    jsr CLRCH
    lda #$04
    jsr my_CLOSE
    lda #$04
    ldx #$04
    ldy #$60
    jsr SETLFS
my_OPEN:
    clc
    jmp OPEN
my_CLOSE:
    sec
    jmp CLOSE
    
;--------------------------------------------------------------------
; IPC function 21 - format disk.
;--------------------------------------------------------------------
    
ipc_21_format:
    lda ipc_buffer+2
    and #$01
    clc
    adc #$30
    sta cmd_n+1
    jsr prepare_channel
    bcs format_end
    ldx #$00
    ldy #$11
format_loop:
    lda cmd_n,x
    jsr BSOUT
    bcs format_end
    inx
    dey
    bne format_loop
    jsr CLRCH
    ldx #$0f
    jsr CHKIN
    bcs format_end
    jsr BASIN
    cmp #$30
    bne format_end
    clc
format_end2:
    jsr ipc_end
    jmp CLRCH
format_end:
    sec
    bne format_end2
    
;--------------------------------------------------------------------
; Convert byte to ASCII decimal representation.
;--------------------------------------------------------------------    

bin_to_dec:
    jsr convert_digit
    pha
    dex
    txa
    jsr convert_digit
    pha
    dex
    txa
    clc
    adc #$30
    tay
    pla
    tax
    pla
    rts
    
convert_digit:
    ldx #$00
    sec
convert_1:
    inx
    sbc #$0a
    bcs convert_1
    adc #$3a
    rts
    
;--------------------------------------------------------------------
; Finish IPC function.
; Set status byte and keyboard buffer byte.
;--------------------------------------------------------------------
    
ipc_end:
    lda #$00
    ror
    sta ipc_buffer
    lda buffer_size
    beq end_nokey
    lda #$01
end_nokey:
    ora #$fe
    sta ipc_buffer+1
    rts
    
;--------------------------------------------------------------------
; IPC function 1B - configure RS-232 port.
;--------------------------------------------------------------------
    
ipc_1b_serial_config:
    lda ipc_buffer+2
    sta rs232_param
    lda ipc_buffer+3
    sta rs232_param+1
    lda ipc_buffer+4
    sta rs232_secaddr
    jsr serial_reopen
    jmp ipc_end
    
;--------------------------------------------------------------------
; IPC function 1D - console services.
;--------------------------------------------------------------------
    
ipc_1d_console:
    lda ipc_buffer+2
    bne console_not00

; Console function 00 - clear screen after & below cursor
    ldx #$03
    jsr CHKOUT
    lda #$1b
    jsr BSOUT
    lda #"q"            ; Esc+Q - erase to end of line
    jsr BSOUT
    sec
    jsr PLOT
    cpx #$18
    beq erase_end
    sty old_y
    stx old_x
    stx tmp_val
    sec
    lda #$18
    sbc tmp_val
    sta tmp_val
erase_loop:
    lda #$1b
    jsr BSOUT
    lda #"i"            ; Esc+I - insert empty line
    jsr BSOUT
    dec tmp_val
    bne erase_loop
    ldx old_x
    ldy old_y
    clc
    jsr PLOT
erase_end:
    jsr CLRCH
    rts

console_not00:
    cmp #$01
    bne console_not01
    
; Console function 01 - set cursor position
    lda ipc_buffer+3
    tay
    lda ipc_buffer+4
    tax
    clc
    jsr PLOT
    rts

console_not01:
    cmp #$02
    bne console_not02
    
; Console function 02 - read cursor position.
    sec
    jsr PLOT
    stx ipc_buffer+4
    sty ipc_buffer+3
    jmp ipc_end

console_not02:
    cmp #$04
    bne console_not04
    
; Console function 04 - delete line at cursor position.
    lda #"d"            ; Esc+D - delete line
    bne delete_line
    lda #"i"
delete_line:
    sta old_y
    lda CursorColumn
    sta tmp_val
    lda #$1b
    jsr BSOUT
    lda old_y
    jsr BSOUT
    ldx CursorLine
    ldy tmp_val
    clc
    jmp PLOT

console_not04:
    rts

;--------------------------------------------------------------------
; Replacement function for GETIN.
; Reads scancodes from our own buffer instead of the system one.
;--------------------------------------------------------------------
    
my_getin:
    lda buffer_size
    beq getin_end
    sei
    ldy shift_buffer
    lda key_buffer
    pha
    ldx #$00
getin_loop:
    lda shift_buffer+1,x
    sta shift_buffer,x
    lda key_buffer+1,x
    sta key_buffer,x
    inx
    cpx buffer_size
    bne getin_loop
    dec buffer_size
    pla
    ldx #$03
    cli
getin_end:
    clc
    rts
