

CPU_ACCESS_BANK = $1
PROC_ADDR = $0100

;--------------------------------------------------------------------
; Zero page variables
;--------------------------------------------------------------------

src_addr = $50
page_count = $52
tmp_byte = $53

;--------------------------------------------------------------------
; I/O chip ports
;--------------------------------------------------------------------

CRTC_RegNo = $d800
CRTC_RegVal = $d801

;--------------------------------------------------------------------
; KERNAL routines
;--------------------------------------------------------------------

PLOT = $fff0

;--------------------------------------------------------------------
; Load address for the PRG file
;--------------------------------------------------------------------

    .word $0400
    * = $0400

ipc_buffer = $0805

    jmp ipc_1d_console
    rts

;--------------------------------------------------------------------
; IPC function 1D (console services) additional handler.
;--------------------------------------------------------------------
    
ipc_1d_console:
    cmp #$05
    bne console_not_05
    jsr screen_convert
    lda ipc_buffer+3
    tay
    lda ipc_buffer+4
    tax
    clc
    jmp PLOT
console_not_05:
    cmp #$06
    bne console_not_06
    jsr screen_init
    lda #$FF
    sta ipc_buffer+2
    lda #0
    sta ipc_buffer+3
    sta ipc_buffer+4
    jmp screen_search
console_not_06:
    cmp #$07
    bne console_not_07
    inc $D000+1999
console_not_07:
    rts

;--------------------------------------------------------------------
; String to search for in video memory
;--------------------------------------------------------------------

screen_marker:
    .byt $4d, $69, $43, $68, $41, $75

;--------------------------------------------------------------------
; Search for a magic string placed by the 8088
;--------------------------------------------------------------------

screen_search:
    ldx #$01
    stx CPU_ACCESS_BANK
    inx
    stx src_addr
    ldx #$00
    stx src_addr+1
screen_search_1:
    ldy #5
screen_search_2:
    lda (src_addr), y
    cmp screen_marker, y
    bne screen_search_3
    dey
    bpl screen_search_2
    lda src_addr+1
    sta screen_location+1
    sta ipc_buffer+4
    lda CPU_ACCESS_BANK
    sta screen_location
    sta ipc_buffer+3
    rts
screen_search_3:
    inc src_addr+1
    bne screen_search_2
    ldx CPU_ACCESS_BANK
    inx
    stx CPU_ACCESS_BANK
    cpx #$0D
    bne screen_search_2
    ldy #$0C
    sty CPU_ACCESS_BANK
screen_notfound:
    lda (src_addr), y
    sta $0180, y
    dey
    bpl screen_notfound
    lda #$0F
    sta CPU_ACCESS_BANK
    rts
    
    
;--------------------------------------------------------------------
; Convert the PC screen to video memory.
;--------------------------------------------------------------------
    
screen_convert:
    lda screen_location
    sta CPU_ACCESS_BANK
    lda #8
    sta page_count
    lda #$D0
    sta screen_proc_dst-screen_proc+PROC_ADDR+2
    lda ipc_buffer+5
    asl 
    asl 
    asl 
    asl
    ora screen_location+1
    sta src_addr+1
    ldy #$01
    sty src_addr
    jsr PROC_ADDR
    lda #15
    sta CPU_ACCESS_BANK
    rts
    
;--------------------------------------------------------------------
; Initialize the screen conversion routine.
;--------------------------------------------------------------------

screen_init:
    ldx #screen_proc_end-screen_proc-1
screen_init_1:
    lda screen_proc,x
    sta PROC_ADDR,x
    dex
    bpl screen_init_1    
	lda #$0e
	sta CRTC_RegNo
	lda CRTC_RegVal
	and #$10
	beq screen_init_2
	inc screen_proc_src-screen_proc+PROC_ADDR+2
screen_init_2:
    rts
    
;--------------------------------------------------------------------
; Self-modifying screen conversion routine.
;--------------------------------------------------------------------

screen_proc:
    lda (src_addr),y
    tax
screen_proc_src:
    lda petscii_table_1,x
    sta tmp_byte
    inc src_addr
    bne screen_proc_page
    inc src_addr+1
screen_proc_page:
    lda (src_addr),y
    tax
    lda petscii_table_3,x
    ora tmp_byte
screen_proc_dst:
    sta $D000,y
    iny
    bne screen_proc
    inc src_addr+1
    inc screen_proc_dst-screen_proc+PROC_ADDR+2
    dec page_count
    bne screen_proc
    lda $D7D0
    sta $D000
    rts
screen_proc_end:

;--------------------------------------------------------------------
; Location of the screen memory
;--------------------------------------------------------------------

screen_location:
    .byt 4
    .byt $80

    .dsb ($0500-*), $AA


;--------------------------------------------------------------------
; ASCII to PETSCII (standard char ROM)
;--------------------------------------------------------------------

petscii_table_1:
	.byt $60, $64, $64, $64, $64, $64, $64, $2a, $aa, $2a, $aa, $64, $64, $64, $64, $64
	.byt $3e, $3c, $5d, $64, $64, $64, $62, $5d, $1e, $16, $3e, $3c, $64, $64, $1e, $16
	.byt $20, $21, $22, $23, $24, $25, $26, $27, $28, $29, $2a, $2b, $2c, $2d, $2e, $2f
	.byt $30, $31, $32, $33, $34, $35, $36, $37, $38, $39, $3a, $3b, $3c, $3d, $3e, $3f
	.byt $00, $41, $42, $43, $44, $45, $46, $47, $48, $49, $4a, $4b, $4c, $4d, $4e, $4f
	.byt $50, $51, $52, $53, $54, $55, $56, $57, $58, $59, $5a, $1b, $1c, $1d, $1e, $1f
	.byt $40, $01, $02, $03, $04, $05, $06, $07, $08, $09, $0a, $0b, $0c, $0d, $0e, $0f
	.byt $10, $11, $12, $13, $14, $15, $16, $17, $18, $19, $1a, $5b, $5c, $5d, $5e, $1e
	.byt $64, $64, $64, $64, $64, $64, $64, $64, $64, $64, $64, $64, $64, $64, $64, $64
	.byt $64, $64, $64, $64, $64, $64, $64, $64, $64, $64, $64, $64, $0c, $64, $64, $64
	.byt $64, $64, $64, $64, $64, $64, $64, $64, $64, $64, $64, $64, $64, $64, $3c, $3e
	.byt $66, $5f, $5f, $5d, $73, $73, $73, $6e, $6e, $73, $5d, $6e, $7d, $7d, $7d, $6e
	.byt $6d, $71, $72, $6b, $40, $5b, $6b, $6b, $6d, $70, $71, $72, $6b, $40, $5b, $71
	.byt $71, $72, $72, $6d, $6d, $70, $70, $5b, $5b, $7d, $70, $e0, $62, $61, $e1, $e2
	.byt $64, $64, $64, $64, $64, $64, $64, $64, $64, $64, $64, $64, $64, $64, $64, $64
	.byt $64, $64, $64, $64, $64, $64, $64, $64, $64, $2a, $2a, $7a, $64, $64, $2a, $60

;--------------------------------------------------------------------
; ASCII to PETSCII (modified char ROM)
;--------------------------------------------------------------------
	
petscii_table_2:
	.byt $7f, $5f, $5f, $5f, $5f, $5f, $5f, $7c, $7d, $7c, $7d, $5f, $5f, $5f, $5f, $5f
	.byt $76, $75, $7a, $5f, $5f, $5f, $62, $7a, $77, $78, $76, $75, $5f, $5f, $77, $78
	.byt $20, $21, $22, $23, $24, $25, $26, $27, $28, $29, $2a, $2b, $2c, $2d, $2e, $2f
	.byt $30, $31, $32, $33, $34, $35, $36, $37, $38, $39, $3a, $3b, $3c, $3d, $3e, $3f
	.byt $00, $41, $42, $43, $44, $45, $46, $47, $48, $49, $4a, $4b, $4c, $4d, $4e, $4f
	.byt $50, $51, $52, $53, $54, $55, $56, $57, $58, $59, $5a, $1b, $1c, $1d, $1e, $1f
	.byt $40, $01, $02, $03, $04, $05, $06, $07, $08, $09, $0a, $0b, $0c, $0d, $0e, $0f
	.byt $10, $11, $12, $13, $14, $15, $16, $17, $18, $19, $1a, $5b, $5c, $5d, $5e, $77
	.byt $5f, $5f, $5f, $5f, $5f, $5f, $5f, $5f, $5f, $5f, $5f, $5f, $5f, $5f, $5f, $5f
	.byt $5f, $5f, $5f, $5f, $5f, $5f, $5f, $5f, $5f, $5f, $5f, $5f, $7e, $5f, $5f, $5f
	.byt $5f, $5f, $5f, $5f, $5f, $5f, $5f, $5f, $5f, $5f, $5f, $5f, $5f, $5f, $75, $76
	.byt $69, $68, $6a, $65, $6c, $6c, $6c, $6f, $6f, $6c, $65, $6f, $71, $71, $71, $6f
	.byt $72, $6d, $6e, $6b, $66, $67, $6b, $6b, $72, $70, $6d, $6e, $6b, $66, $67, $6d
	.byt $6d, $6e, $6e, $72, $72, $70, $70, $67, $67, $71, $70, $60, $62, $61, $64, $63
	.byt $5f, $5f, $5f, $5f, $5f, $5f, $5f, $5f, $5f, $5f, $5f, $5f, $5f, $5f, $5f, $5f
	.byt $5f, $5f, $5f, $5f, $5f, $5f, $5f, $5f, $5f, $7c, $7c, $79, $5f, $5f, $74, $7f

;--------------------------------------------------------------------
; Attribute conversion (MDA to reverse bit)
;--------------------------------------------------------------------
	
petscii_table_3:
	.byt $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	.byt $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	.byt $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	.byt $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	.byt $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	.byt $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	.byt $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	.byt $80, $00, $00, $00, $00, $00, $00, $00, $80, $00, $00, $00, $00, $00, $00, $00
	.byt $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	.byt $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	.byt $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	.byt $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	.byt $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	.byt $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	.byt $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	.byt $80, $00, $00, $00, $00, $00, $00, $00, $80, $00, $00, $00, $00, $00, $00, $00
