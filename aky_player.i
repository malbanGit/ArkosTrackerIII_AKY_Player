; ARKOS TRACKER II 
; Player for the Vectrex of the AKY format
; inspite of the 6809 being a BIG ENDIAN
;
; the AKY must be saved as sources for little ENDIAN, because that is
; what the code below interprets!
;
; Plays at an average of about 2000 cycles
; spikes up to 2500 have been seen.
; it uses 32 bytes of RAM, starting at "arkosRamStart"
;
; This is a manual transcode from the 6502 player, there has been no
; effort taken, to performance enhance this player.
;
;
; MACROS for shadow register setting
; macros assumes; register U pointing to Vec_Music_Work (this is a shadow)
; assumes var register is positive (always...)
;
; destroys a 
SET_PSG_DIR_VAR     macro    direct_register, variable_value 
                    lda      variable_value 
                    sta      direct_register, u 
                    endm     
; destroys d
SET_PSG_VAR_VAR     macro    variable_register, variable_value 
                    lda      variable_value 
                    ldb      variable_register 
                    sta      b,u 
                    endm     
; destroys a, b
SET_PSG_VAR_DIR     macro    variable_register, direct_value 
                    lda      #direct_value 
                    ldb      variable_register 
                    sta      b, u 
                    endm     
; destroys a, b
SET_PSG_VAR_DATA_Y_INC  macro  variable_register 
                    ldb      variable_register 
                    lda      ,y+ 
                    sta      b, u 
                    endm     
;
;
                    bss      
                    org      arkosRamStart 
NO_ERROR            EQU      0 
NO_3_CHANNELS_ERROR  EQU     1 
PLY_error           ds       1 
ACCA                ds       1                            ; senselessly named tmp 
ACCB                ds       1                            ; senselessly named tmp 
volumeRegister      ds       1 
frequencyRegister   ds       1 
r7                  ds       1 
;
; "flag"
; 0 = initial
; 1 = non initial
; no opcode used!
; flag is loaded into reg b upon call of subroutine!
initFlag1           ds       1 
initFlag2           ds       1 
initFlag3           ds       1 
PLY_AKY_PATTERNFRAMECOUNTER_OVER  ds  2                   ; pointer to next pattern start 
PLY_AKY_PATTERNFRAMECOUNTER  ds  2                        ; pointer into the current pattern 
PLY_AKY_CHANNEL1_PTTRACK  ds  2 
PLY_AKY_CHANNEL2_PTTRACK  ds  2 
PLY_AKY_CHANNEL3_PTTRACK  ds  2 
PLY_AKY_CHANNEL1_WAITBEFORENEXTREGISTERBLOCK  ds  1 
PLY_AKY_CHANNEL2_WAITBEFORENEXTREGISTERBLOCK  ds  1 
PLY_AKY_CHANNEL3_WAITBEFORENEXTREGISTERBLOCK  ds  1 
PLY_AKY_CHANNEL1_PTREGISTERBLOCK  ds  2 
PLY_AKY_CHANNEL2_PTREGISTERBLOCK  ds  2 
PLY_AKY_CHANNEL3_PTREGISTERBLOCK  ds  2 
PLY_AKY_PSGREGISTER13_RETRIG  ds  1                       ; compare val 
; -------------------------------------
;Some stored PSG registers. They MUST be consecutive.
PLY_AKY_PSGREGISTER6 
                    ds       1 
PLY_AKY_PSGREGISTER11 
                    ds       1 
PLY_AKY_PSGREGISTER12 
                    ds       1 
PLY_AKY_PSGREGISTER13 
                    ds       1 
; =============================================================================
;Is there a loaded Player Configuration source? If no, use a default configuration.
; => to generate Player Configuration, see export option in Arkos Tracker 2 
; simplified version...
                    ifndef   PLY_CFG_ConfigurationIsPresent 
PLY_CFG_UseHardwareSounds  =  1 
PLY_CFG_UseRetrig   =        1 
PLY_CFG_NoSoftNoHard  =      1                            ; not used 
PLY_CFG_NoSoftNoHard_Noise  =  1                          ; not used 
PLY_CFG_SoftOnly    =        1                            ; not used 
PLY_CFG_SoftOnly_Noise  =    1                            ; not used 
PLY_CFG_SoftToHard  =        1 
PLY_CFG_SoftToHard_Noise  =  1 
PLY_CFG_SoftToHard_Retrig  =  1                           ; not used 
PLY_CFG_HardOnly    =        1 
PLY_CFG_HardOnly_Noise  =    1                            ; not used 
PLY_CFG_HardOnly_Retrig  =   1                            ; not used 
PLY_CFG_SoftAndHard  =       1                            ; not used 
PLY_CFG_SoftAndHard_Noise  =  1 
PLY_CFG_SoftAndHard_Retrig  =  1                          ; not used 
 endif  
;Agglomerates the hardware sound configuration flags, because they are treated the same in this player.
 ifdef  PLY_CFG_SoftToHard 
PLY_AKY_USE_SoftAndHard_Agglomerated  =  1 
 endif  
 ifdef  PLY_CFG_SoftAndHard 
                    PLY_AKY_USE_SoftAndHard_Agglomerated  = 1 
 endif  
 ifdef  PLY_CFG_HardToSoft 
PLY_AKY_USE_SoftAndHard_Agglomerated  =  1 
 endif  
 ifdef  PLY_CFG_HardOnly 
PLY_AKY_USE_SoftAndHard_Agglomerated  =  1 
 endif  
 ifdef  PLY_CFG_SoftToHard_Noise 
PLY_AKY_USE_SoftAndHard_Noise_Agglomerated  =  1 
 endif  
 ifdef  PLY_CFG_SoftAndHard_Noise 
PLY_AKY_USE_SoftAndHard_Noise_Agglomerated  =  1 
 endif  
 ifdef  PLY_CFG_HardToSoft_Noise 
PLY_AKY_USE_SoftAndHard_Noise_Agglomerated  =  1 
 endif  
;Any noise?
 ifdef  PLY_AKY_USE_SoftAndHard_Noise_Agglomerated 
PLY_AKY_USE_Noise   =        1 
 endif  
 ifdef  PLY_CFG_NoSoftNoHard_Noise 
PLY_AKY_USE_Noise   =        1 
 endif  
 ifdef  PLY_CFG_SoftOnly_Noise 
PLY_AKY_USE_Noise   =        1 
 endif  
; =============================================================================
                    code     
; Initializes the player.
; expected in regY the song address, usually something like "Main_Subsong0"
; y is our main "pointer" register
PLY_AKY_INIT 
                    clr      PLY_error                    ; initially no error! 
                                                          ; Skips the header. 
                                                          ; Skips the format version. 
                    LDD      ,y                           ; d now a format, b = channel count 
                    cmpb     #3                           ; channel count 
                    BNE      channelError 
                                                          ; two bytes: format version and channel count 
                                                          ; four bytes: frequency (should for Vectrex hopefully 1500000Hz 
                    leay     6,y 
                                                          ; y/pcData now pointing to subsong 0 linker 
                                                          ; save current linker pointer, this is the 
                                                          ; address of the the next pattern to be initialized! 
                    sty      PLY_AKY_PATTERNFRAMECOUNTER_OVER 
                                                          ; initial state = 0 
                    clr      initFlag1 
                    clr      initFlag2 
                    clr      initFlag3 
                                                          ; init frame counter with 1, so it gets count down immediately to 0 
                                                          ; and reinits the next (FIRST) pattern! 
                    ldd      #1 
                    std      PLY_AKY_PATTERNFRAMECOUNTER 
                    lda      #$ff                         ; malban add, default retrigger 
                    sta      PLY_AKY_PSGREGISTER13_RETRIG 
errorRTS 
                    RTS      

channelError 
; don't really know what the original player is 
; trying to acomplish here (6502)
; if not 3 it goes back to before the frequency skip
; ->looks wrong (checked with z80 code, 6502 is wrong!)
; for now I just exit!
                    lda      #NO_3_CHANNELS_ERROR 
                    sta      PLY_error 
                    rts      

;-----------
;       Plays the music. It must have been initialized before.
PLY_AKY_PLAY 
                    ldu      #Vec_Music_Work              ; prerequisite for writing to PSG shadow register 
                    ldd      PLY_AKY_PATTERNFRAMECOUNTER 
                    subd     #1 
                    std      PLY_AKY_PATTERNFRAMECOUNTER 
                    bne      read_the_tracks              ;The pattern is not over. go on reading the track 
; The pattern is over. Reads the next one.  
PLY_AKY_PTLINKER 
                    ldy      PLY_AKY_PATTERNFRAMECOUNTER_OVER ; get the address of the next frame 
                    ldd      ,y++                         ;Gets the duration of the Pattern, or 0 if end of the song. 
                    BNE      PLY_AKY_LINKERNOTENDSONG 
                    ldy      ,y++                         ; End of the song. Where to loop? 
                                                          ;Gets the duration again. No need to check the end of the song, 
                                                          ;we know it contains at least one pattern. 
                    ldd      ,y++                         ;Gets the duration of the Pattern, or 0 if end of the song. 
PLY_AKY_LINKERNOTENDSONG 
                    std      PLY_AKY_PATTERNFRAMECOUNTER 
                    ldd      ,y++ 
                    std      PLY_AKY_CHANNEL1_PTTRACK 
                    ldd      ,y++ 
                    std      PLY_AKY_CHANNEL2_PTTRACK 
                    ldd      ,y++ 
                    std      PLY_AKY_CHANNEL3_PTTRACK 
                    sty      PLY_AKY_PATTERNFRAMECOUNTER_OVER 
                    lda      #01                          ;Resets the RegisterBlocks of the channel >1. The first one is skipped so there is no need to do so. 
                    sta      PLY_AKY_CHANNEL2_WAITBEFORENEXTREGISTERBLOCK 
                    sta      PLY_AKY_CHANNEL3_WAITBEFORENEXTREGISTERBLOCK 
                    bra      in_read_the_tracks1 

; =====================================
;Reading the Tracks.
; =====================================
read_the_tracks 
; Channel 1
                    dec      PLY_AKY_CHANNEL1_WAITBEFORENEXTREGISTERBLOCK ;Frames to wait before reading the next RegisterBlock. 0 = finished. 
                    bne      PLY_AKY_CHANNEL1_REGISTERBLOCK_PROCESS 
in_read_the_tracks1 
                                                          ;This RegisterBlock is finished. Reads the next one from the Track. 
                    clr      initFlag1                    ;Obviously, starts at the initial state. 
                    ldy      PLY_AKY_CHANNEL1_PTTRACK 
                    lda      ,y+                          ; A is the duration of the block. 
                    sta      PLY_AKY_CHANNEL1_WAITBEFORENEXTREGISTERBLOCK 
                    ldd      ,y++ 
                    std      PLY_AKY_CHANNEL1_PTREGISTERBLOCK 
                    sty      PLY_AKY_CHANNEL1_PTTRACK 
PLY_AKY_CHANNEL1_REGISTERBLOCK_PROCESS 
;
; Channel 2
                    dec      PLY_AKY_CHANNEL2_WAITBEFORENEXTREGISTERBLOCK ;Frames to wait before reading the next RegisterBlock. 0 = finished. 
                    bne      PLY_AKY_CHANNEL2_REGISTERBLOCK_PROCESS 
                                                          ;This RegisterBlock is finished. Reads the next one from the Track. 
                    clr      initFlag2                    ;Obviously, starts at the initial state. 
                    ldy      PLY_AKY_CHANNEL2_PTTRACK 
                    lda      ,y+                          ;A is the duration of the block. 
                    sta      PLY_AKY_CHANNEL2_WAITBEFORENEXTREGISTERBLOCK 
                    ldd      ,y++ 
                    std      PLY_AKY_CHANNEL2_PTREGISTERBLOCK 
                    sty      PLY_AKY_CHANNEL2_PTTRACK 
PLY_AKY_CHANNEL2_REGISTERBLOCK_PROCESS 
;
; channel 3
                    dec      PLY_AKY_CHANNEL3_WAITBEFORENEXTREGISTERBLOCK ;Frames to wait before reading the next RegisterBlock. 0 = finished. 
                    bne      PLY_AKY_CHANNEL3_REGISTERBLOCK_PROCESS 
                                                          ;This RegisterBlock is finished. Reads the next one from the Track. 
                    clr      initFlag3                    ;Obviously, starts at the initial state. 
                    ldy      PLY_AKY_CHANNEL3_PTTRACK 
                    lda      ,y+                          ;a is the duration of the block. 
                    sta      PLY_AKY_CHANNEL3_WAITBEFORENEXTREGISTERBLOCK 
                    ldd      ,y++ 
                    std      PLY_AKY_CHANNEL3_PTREGISTERBLOCK 
                    sty      PLY_AKY_CHANNEL3_PTTRACK 
PLY_AKY_CHANNEL3_REGISTERBLOCK_PROCESS 
; =====================================
;Reading the RegisterBlock.
; =====================================
                    LDA      #08 
                    STA      volumeRegister               ; first volume register 
                    clr      frequencyRegister 
                                                          ; Register 7 with default values: fully sound-open but noise-close. 
                                                          ;R7 has been shift twice to the left, it will be shifted back as the channels are treated. 
                    LDA      #$E0 
                    STA      r7 
;
;Channel 1 
                    ldy      PLY_AKY_CHANNEL1_PTREGISTERBLOCK 
                    ldb      initFlag1 
                    bSR      PLY_AKY_READREGISTERBLOCK 
                    lda      #1 
                    sta      initFlag1 
                    sty      PLY_AKY_CHANNEL1_PTREGISTERBLOCK 
;
; Channel 2 
                    LSR      r7                           ;Shifts the R7 for the next channels. 
                    ldy      PLY_AKY_CHANNEL2_PTREGISTERBLOCK 
                    ldb      initFlag2 
                    bSR      PLY_AKY_READREGISTERBLOCK 
                    lda      #1 
                    sta      initFlag2 
                    sty      PLY_AKY_CHANNEL2_PTREGISTERBLOCK 
;
; Channel 3 
                    ROR      r7                           ;Shifts the R7 for the next channels. 
                    ldy      PLY_AKY_CHANNEL3_PTREGISTERBLOCK 
                    ldb      initFlag3 
                    bSR      PLY_AKY_READREGISTERBLOCK 
                    lda      #1 
                    sta      initFlag3 
                    sty      PLY_AKY_CHANNEL3_PTREGISTERBLOCK 
;
;Almost all the channel specific registers have been sent. Now sends the remaining registers (6, 7, 11, 12, 13).
;Register 7. Note that managing register 7 before 6/11/12 is done on purpose.
                    SET_PSG_DIR_VAR  7, r7 
 ifdef  PLY_AKY_USE_Noise                                 ;CONFIG SPECIFIC 
                    SET_PSG_DIR_VAR  6, PLY_AKY_PSGREGISTER6 
 endif  
 ifdef  PLY_CFG_UseHardwareSounds                         ;CONFIG SPECIFIC 
                    SET_PSG_DIR_VAR  11, PLY_AKY_PSGREGISTER11 
                    SET_PSG_DIR_VAR  12, PLY_AKY_PSGREGISTER12 
                    lda      PLY_AKY_PSGREGISTER13 
                    cmpa     PLY_AKY_PSGREGISTER13_RETRIG ;If IsRetrig?, force the R13 to be triggered. 
                    beq      PLY_AKY_PSGREGISTER13_END 
                    sta      PLY_AKY_PSGREGISTER13_RETRIG 
                    SET_PSG_DIR_VAR  13, PLY_AKY_PSGREGISTER13 
PLY_AKY_PSGREGISTER13_END 
 endif                                                    ;PLY_CFG_UseHardwareSounds 
PLY_AKY_EXIT 
                    RTS      

; ****************************************************************************************
; -----------------------------------------------------------------------------
;Generic code interpreting the RegisterBlock
; IN:   regY = First Byte
;       regB = 0 = initial state, 1 = non-initial state. 
; -----------------------------------------------------------------------------
PLY_AKY_READREGISTERBLOCK 
                    lda      ,y+ 
                    sta      ACCA 
                    tstb     
                    lbne     PLY_AKY_RRB_NONINITIALSTATE 
;Initial state. 
                    ror      ACCA 
                    bcs      PLY_AKY_RRB_IS_SOFTWAREONLYORSOFTWAREANDHARDWARE 
                    ror      ACCA 
 ifdef  PLY_AKY_USE_SoftAndHard_Agglomerated              ;CONFIG SPECIFIC 
                    bcs      PLY_AKY_RRB_IS_HARDWAREONLY 
 endif  
; -----------------------------------------------------------------------------
;Generic code interpreting the RegisterBlock - Initial state.
; IN:   regY = Points after the first byte.
;       ACCA (A) = First byte, twice shifted to the right (type removed).
;       r7 = Register 7. All sounds are open (0) by default, all noises closed (1).
;       volumeRegister = Volume register.
;       frequencyRegister = LSB frequency register.
;
; OUT:  regY MUST point after the structure.
;       r7 = updated (ONLY bit 2 and 5).
;       volumeRegister = Volume register increased of 1 (*** IMPORTANT! The code MUST increase it, even if not using it! ***)
;       frequencyRegister = LSB frequency register, increased of 2.
; -----------------------------------------------------------------------------
PLY_AKY_RRB_IS_NOSOFTWARENOHARDWARE 
                    ror      ACCA                         ;Noise? 
                    bcc      PLY_AKY_RRB_NIS_NOSOFTWARENOHARDWARE_READVOLUME 
                    lda      ,y+                          ;There is a noise. Reads it. 
                    STA      PLY_AKY_PSGREGISTER6 
                    LDA      r7                           ;Opens the noise channel. 
                    anda     #%11011111                   ; reset bit 5 (open) 
                    STA      r7 
;------------
PLY_AKY_RRB_NIS_NOSOFTWARENOHARDWARE_READVOLUME 
;The volume is now in b0-b3. 
;and %1111 ;No need, the bit 7 was 0. 
                    SET_PSG_VAR_VAR  volumeRegister, ACCA ;Sends the volume. 
                    inc      volumeRegister               ;Increases the volume register. 
                    inc      frequencyRegister 
                    inc      frequencyRegister 
                    LDA      r7                           ;Closes the sound channel. 
                    ORA      #%00000100                   ; set bit 2 (close) 
                    STA      r7 
                    RTS      

; -------------------------------------
 ifdef  PLY_AKY_USE_SoftAndHard_Agglomerated              ;CONFIG SPECIFIC 
PLY_AKY_RRB_IS_HARDWAREONLY 
                    ROR      ACCA                         ;Retrig? 
                    BCC      PLY_AKY_RRB_IS_HO_NORETRIG 
                    LDA      ACCA 
                    ORA      #%10000000 
                    STA      ACCA 
                    STA      PLY_AKY_PSGREGISTER13_RETRIG ;A value to make sure the retrig is performed, yet A can still be use. 
PLY_AKY_RRB_IS_HO_NORETRIG 
                    ROR      ACCA                         ;Noise? 
                    BCC      PLY_AKY_RRB_IS_HO_NONOISE 
                    lda      ,y+                          ;Reads the noise. 
                    STA      PLY_AKY_PSGREGISTER6 
                    LDA      r7                           ;Opens the noise channel. 
                    ANDA     #%11011111                   ; reset bit 5 (open) 
                    STA      r7 
PLY_AKY_RRB_IS_HO_NONOISE 
                    LDA      ACCA                         ;The envelope. 
                    ANDA     #15 
                    STA      PLY_AKY_PSGREGISTER13 
                    ldd      ,y++                         ;Copies the hardware period. 
                    STD      PLY_AKY_PSGREGISTER11        ;+12 
                    LDA      r7                           ;Closes the sound channel. 
                    ORA      #%00000100                   ; set bit 2 (close) 
                    STA      r7 
                    SET_PSG_VAR_DIR  volumeRegister, $ff 
                    inc      volumeRegister               ;Increases the volume register. 
                    inc      frequencyRegister 
                    inc      frequencyRegister 
                    RTS      

 endif  
; -------------------------------------
PLY_AKY_RRB_IS_SOFTWAREONLYORSOFTWAREANDHARDWARE 
                    ROR      ACCA                         ;Another decision to make about the sound type. 
 ifdef  PLY_AKY_USE_SoftAndHard_Agglomerated              ;CONFIG SPECIFIC 
                    BCS      PLY_AKY_RRB_IS_SOFTWAREANDHARDWARE 
 endif  
;Software only. Structure: 0vvvvntt. 
                    ROR      ACCA                         ;Noise? 
                    BCC      PLY_AKY_RRB_IS_SOFTWAREONLY_NONOISE 
                                                          ;Noise. Reads it. 
                    lda      ,y+ 
                    STA      PLY_AKY_PSGREGISTER6 
                    LDA      r7                           ;Opens the noise channel. 
                    ANDA     #%11011111                   ; reset bit 5 (open) 
                    STA      r7 
PLY_AKY_RRB_IS_SOFTWAREONLY_NONOISE 
;Reads the volume (now b0-b3). 
;Note: we do NOT peform a "and %1111" because we know the bit 7 of the original byte is 0, so the bit 4 is currently 0. Else the hardware volume would be on! 
                    SET_PSG_VAR_VAR  volumeRegister, ACCA ;Sends the volume. 
                    INC      volumeRegister               ;Increases the volume register. 
                    SET_PSG_VAR_DATA_Y_INC  frequencyRegister ;Sends the LSB software frequency. 
                    inc      frequencyRegister 
                    SET_PSG_VAR_DATA_Y_INC  frequencyRegister ;Sends the MSB software frequency. 
                    inc      frequencyRegister 
                    RTS      

; -------------------------------------
 ifdef  PLY_AKY_USE_SoftAndHard_Agglomerated              ;CONFIG SPECIFIC 
PLY_AKY_RRB_IS_SOFTWAREANDHARDWARE 
                    ROR      ACCA                         ;Retrig? 
 ifdef  PLY_CFG_UseRetrig                                 ;CONFIG SPECIFIC 
                    BCC      PLY_AKY_RRB_IS_SAH_NORETRIG 
                    LDA      ACCA 
                    ORA      #%10000000 
                    STA      PLY_AKY_PSGREGISTER13_RETRIG ;A value to make sure the retrig is performed, yet A can still be use. 
                    STA      ACCA 
PLY_AKY_RRB_IS_SAH_NORETRIG 
 endif                                                    ; PLY_CFG_UseRetrig 
                    ROR      ACCA                         ;Noise? 
 ifdef  PLY_AKY_USE_SoftAndHard_Noise_Agglomerated        ;CONFIG SPECIFIC 
                    BCC      PLY_AKY_RRB_IS_SAH_NONOISE 
                    lda      ,y+                          ;Reads the noise. 
                    STA      PLY_AKY_PSGREGISTER6 
                    LDA      r7                           ;Opens the noise channel. 
                    ANDA     #%11011111                   ; reset bit 5 (open noise) 
                    STA      r7 
PLY_AKY_RRB_IS_SAH_NONOISE 
 endif                                                    ;PLY_AKY_USE_SoftAndHard_Noise_Agglomerated 
                    LDA      ACCA                         ;The envelope. 
                    ANDA     #15 
                    STA      PLY_AKY_PSGREGISTER13 
                    SET_PSG_VAR_DATA_Y_INC  frequencyRegister ;Sends the LSB software frequency. 
                    inc      frequencyRegister 
                    SET_PSG_VAR_DATA_Y_INC  frequencyRegister ;Sends the MSB software frequency. 
                    inc      frequencyRegister 
                    SET_PSG_VAR_DIR  volumeRegister, $ff  ;Sets the hardware volume. 
                    inc      volumeRegister               ;Increases the volume register. 
                    ldd      ,y++                         ;Copies the hardware period. 
                    std      PLY_AKY_PSGREGISTER11        ; 11+12 
                    RTS      

 endif                                                    ; PLY_AKY_USE_SoftAndHard_Agglomerated 
; -------------------------------------
;Manages the loop. This code is put here so that no jump needs to be coded when its job is done. 
PLY_AKY_RRB_NIS_NOSOFTWARENOHARDWARE_LOOP 
;Loops. Reads the next pointer to this RegisterBlock. 
                    ldy      ,y 
                    lda      ,y+ 
                    sta      ACCA 
; -----------------------------------------------------------------------------
;Generic code interpreting the RegisterBlock - Non initial state. See comment about the Initial state for the registers ins/outs.
; -----------------------------------------------------------------------------
PLY_AKY_RRB_NONINITIALSTATE 
                    ROR      ACCA 
                    BCS      PLY_AKY_RRB_NIS_SOFTWAREONLYORSOFTWAREANDHARDWARE 
                    ROR      ACCA 
 ifdef  PLY_AKY_USE_SoftAndHard_Agglomerated              ;CONFIG SPECIFIC 
                    LBCS     PLY_AKY_RRB_NIS_HARDWAREONLY 
 endif  
                    LDA      ACCA                         ;No software, no hardware, OR loop. 
                    STA      ACCB 
                    ANDA     #03                          ;Bit 3:loop?/volume bit 0, bit 2: volume? 
                    CMPA     #02                          ;If no volume, yet the volume is >0, it means loop. 
                    BEQ      PLY_AKY_RRB_NIS_NOSOFTWARENOHARDWARE_LOOP 
;No loop: so "no software no hardware". 
                    LDA      r7                           ;Closes the sound channel. 
                    ORA      #%00000100                   ; set bit 2 (close sound) 
                    STA      r7                           ;Volume? bit 2 - 2. 
                    LDA      ACCB 
                    RORA     
                    BCC      PLY_AKY_RRB_NIS_NOVOLUME 
                    ANDA     #15 
                    STA      ACCA 
                    SET_PSG_VAR_VAR  volumeRegister, ACCA ;Sends the volume. 
PLY_AKY_RRB_NIS_NOVOLUME 
;Sadly, have to lose a bit of CPU here, as this must be done in all cases. 
                    INC      volumeRegister               ;Next volume register. 
                    inc      frequencyRegister 
                    inc      frequencyRegister 
;Noise? Was on bit 7, but there has been two shifts. We can't use A, it may have been modified by the volume AND. 
                    LDA      #%00100000                   ; bit 7-2 
                    BITA     ACCB 
                    BNE      isNoise 
                    RTS      

isNoise 
                    lda      ,y+                          ;Noise. 
                    STA      PLY_AKY_PSGREGISTER6 
                    LDA      r7                           ;Opens the noise channel. 
                    ANDA     #%11011111                   ; reset bit 5 (open noise) 
                    STA      r7 
                    RTS      

; -------------------------------------
PLY_AKY_RRB_NIS_SOFTWAREONLYORSOFTWAREANDHARDWARE 
;Another decision to make about the sound type. 
                    ROR      ACCA 
 ifdef  PLY_AKY_USE_SoftAndHard_Agglomerated              ;CONFIG SPECIFIC 
                    LBCS     PLY_AKY_RRB_NIS_SOFTWAREANDHARDWARE 
 endif  
;Software only. Structure: mspnoise lsp v v v v (0 1). 
                    LDA      ACCA 
                    STA      ACCB 
                    ANDA     #15                          ;Gets the volume (already shifted). 
                    STA      ACCA 
                    SET_PSG_VAR_VAR  volumeRegister, ACCA ;Sends the volume. 
                    INC      volumeRegister               ;Increases the volume register. 
                                                          ;LSP? (Least Significant byte of Period). Was bit 6, but now shifted. 
                    LDA      #%00010000                   ; bit 6-2 
                    BITA     ACCB 
                    BEQ      PLY_AKY_RRB_NIS_SOFTWAREONLY_NOLSP 
                    SET_PSG_VAR_DATA_Y_INC  frequencyRegister ;Sends the LSB software frequency. 
; frequency register is not incremented on purpose. 
PLY_AKY_RRB_NIS_SOFTWAREONLY_NOLSP 
;MSP AND/OR (Noise and/or new Noise)? (Most Significant byte of Period). 
                    LDA      #%00100000                   ; bit 7-2 
                    BITA     ACCB 
                    BNE      PLY_AKY_RRB_NIS_SOFTWAREONLY_MSPANDMAYBENOISE 
;Bit of loss of CPU, but has to be done in all cases. 
                    inc      frequencyRegister 
                    inc      frequencyRegister 
                    RTS      

; -------------------------------------
PLY_AKY_RRB_NIS_SOFTWAREONLY_MSPANDMAYBENOISE 
;MSP and noise?, in the next byte. nipppp (n = newNoise? i = isNoise? p = MSB period). 
                    lda      ,y+                          ;Useless bits at the end, not a problem. 
                    sta      ACCA 
                    inc      frequencyRegister            ;Sends the MSB software frequency. 
                    SET_PSG_VAR_VAR  frequencyRegister, ACCA 
                    inc      frequencyRegister 
                    ROL      ACCA                         ;Carry is isNoise? 
                    BCS      isNoise2 
                    RTS      

isNoise2                                                  ;Opens   the noise channel. 
                    LDA      r7                           ; reset bit 5 (open) 
                    ANDA     #%11011111 
                    STA      r7 
                    ROL      ACCA                         ;Is there a new noise value? If yes, gets the noise. 
                    BCS      newNoise2 
                    RTS      

newNoise2 
                    lda      ,y+                          ;Gets the noise. 
                    STA      PLY_AKY_PSGREGISTER6 
                    RTS      

; -------------------------------------
; Tracker III - Z80 
;PLY_AKY_RRB_NIS_HardwareOnly
;        ;Gets the envelope (initially on b2-b4, but currently on b0-b2). It is on 3 bits, must be encoded on 4. Bit 3 must be 1.
;        ld e,a
;        and %111
;        or %1000                ;To get envelope from 8 to 15.
;        ld (PLY_AKY_PsgRegister13),a
;
;        ;Closes the sound channel.
;        set PLY_AKY_RRB_SoundChannelBit, b

; Tracker II - Z80 
;PLY_AKY_RRB_NIS_HardwareOnly
;        ;Gets the envelope (initially on b2-b4, but currently on b0-b2). It is on 3 bits, must be encoded on 4. Bit 0 must be 0.
;        rla
;        ld e,a
;        and %1110
;        ld (PLY_AKY_PsgRegister13),a
;
;        ;Closes the sound channel.
;        set PLY_AKY_RRB_SoundChannelBit, b





 ifdef  PLY_AKY_USE_SoftAndHard_Agglomerated              ;CONFIG SPECIFIC 
PLY_AKY_RRB_NIS_HARDWAREONLY 
; Pre BugFix
; Gets the envelope (initially on b2-b4, but currently on b0-b2). It is on 3 bits, must be encoded on 4. Bit 0 must be 0. 
;                    ROL      ACCA 
;                    LDA      ACCA 
;                    STA      ACCB 
;                    ANDA     #14 

; BUGFIX V1.1 > Tracker III
; Gets the envelope (initially on b2-b4, but currently on b0-b2). It is on 3 bits, must be encoded on 4. Bit 3 must be 1.
 LDA ACCA
 ANDA #%00000111
 ORA #%00001000


                    STA      PLY_AKY_PSGREGISTER13 
					
                    LDA      r7                           ;Closes the sound channel. 
                    ORA      #%00000100                   ; set bit 2 (close) 
                    STA      r7 
;            ;Hardware volume.
                    SET_PSG_VAR_DIR  volumeRegister, $ff 
                    inc      volumeRegister               ;Increases the volume register. 
                    inc      frequencyRegister 
                    inc      frequencyRegister 
                    LDA      ACCB                         ;LSB for hardware period? Currently on b6. 

; BUGFIX V1.1 > Tracker III

; BugFix -> one additional ROLA (which was taken out above!)
 ROLA     
                    ROLA     
                    ROLA     
                    STA      ACCA 
                    BCC      PLY_AKY_RRB_NIS_HARDWAREONLY_NOLSB 
                    lda      ,y+ 
                    sta      PLY_AKY_PSGREGISTER11 
PLY_AKY_RRB_NIS_HARDWAREONLY_NOLSB 
                    ROL      ACCA                         ;MSB for hardware period? 
                    BCC      PLY_AKY_RRB_NIS_HARDWAREONLY_NOMSB 
                    lda      ,y+ 
                    sta      PLY_AKY_PSGREGISTER12 
PLY_AKY_RRB_NIS_HARDWAREONLY_NOMSB 
                    ROL      ACCA                         ;Noise or retrig? 
                    BCS      PLY_AKY_RRB_NIS_HARDWARE_SHARED_NOISEORRETRIG_ANDSTOP 
                    RTS      

 endif                                                    ;PLY_AKY_USE_SoftAndHard_Agglomerated 
; -------------------------------------
 ifdef  PLY_AKY_USE_SoftAndHard_Agglomerated              ;CONFIG SPECIFIC 
PLY_AKY_RRB_NIS_SOFTWAREANDHARDWARE 
                    SET_PSG_VAR_DIR  volumeRegister, $ff  ;Hardware volume. 
                    inc      volumeRegister               ;Increases the volume register. 
                    ROR      ACCA                         ;LSB of hardware period? 
                    BCC      PLY_AKY_RRB_NIS_SAHH_AFTERLSBH 
                    lda      ,y+ 
                    sta      PLY_AKY_PSGREGISTER11 
PLY_AKY_RRB_NIS_SAHH_AFTERLSBH 
                    ROR      ACCA                         ;MSB of hardware period? 
                    BCC      PLY_AKY_RRB_NIS_SAHH_AFTERMSBH 
                    lda      ,y+ 
                    sta      PLY_AKY_PSGREGISTER12 
PLY_AKY_RRB_NIS_SAHH_AFTERMSBH 
                    LDA      ACCA                         ;LSB of software period? 
                    RORA     
                    BCC      PLY_AKY_RRB_NIS_SAHH_AFTERLSBS 
                    STA      ACCB 
                    SET_PSG_VAR_DATA_Y_INC  frequencyRegister ;Sends the LSB software frequency. 
; frequency register not increased on purpose. 
                    LDA      ACCB 
PLY_AKY_RRB_NIS_SAHH_AFTERLSBS 
                    RORA                                  ;MSB of software period? 
                    BCC      PLY_AKY_RRB_NIS_SAHH_AFTERMSBS 
                    STA      ACCB 
                    inc      frequencyRegister            ;Sends the MSB software frequency. 
                    SET_PSG_VAR_DATA_Y_INC  frequencyRegister 
                    dec      frequencyRegister 
                    LDA      ACCB 
PLY_AKY_RRB_NIS_SAHH_AFTERMSBS 
;A bit of loss of CPU, but this has to be done every time! 
                    inc      frequencyRegister 
                    inc      frequencyRegister 
                    RORa                                  ;New hardware envelope? 
                    STA      ACCA 
                    BCC      PLY_AKY_RRB_NIS_SAHH_AFTERENVELOPE 
                    lda      ,y+ 
                    STA      PLY_AKY_PSGREGISTER13 
PLY_AKY_RRB_NIS_SAHH_AFTERENVELOPE 
                    LDA      ACCA                         ;Retrig and/or noise? 
                    RORA     
                    BCS      isNoise3 
                    RTS      

isNoise3 
 endif  PLY_AKY_USE_SoftAndHard_Agglomerated 
 ifdef  PLY_CFG_UseHardwareSounds                         ;CONFIG SPECIFIC 
;This code is shared with the HardwareOnly. It reads the Noise/Retrig byte, interprets it and exits. 
PLY_AKY_RRB_NIS_HARDWARE_SHARED_NOISEORRETRIG_ANDSTOP 
                    lda      ,y+                          ;Noise or retrig. Reads the next byte. 
                    RORA                                  ;Retrig? 
 ifdef  PLY_CFG_UseRetrig                                 ;CONFIG SPECIFIC 
                    BCC      PLY_AKY_RRB_NIS_S_NOR_NORETRIG 
                    ORA      #%10000000 
                    STA      PLY_AKY_PSGREGISTER13_RETRIG ;A value to make sure the retrig is performed, yet A can still be use. 
PLY_AKY_RRB_NIS_S_NOR_NORETRIG 
 endif  PLY_CFG_UseRetrig 
 ifdef  PLY_AKY_USE_SoftAndHard_Noise_Agglomerated        ;CONFIG SPECIFIC 
                    RORA                                  ;Noise? If no, nothing more to do. 
                    STA      ACCA 
                    BCS      isNoise4 
                    RTS      

isNoise4 
                    LDA      r7                           ;Noise. Opens the noise channel. 
                    ANDA     #%11011111                   ; reset bit 5 (open) 
                    STA      r7 
                    LDA      ACCA 
                    RORA                                  ;Is there a new noise value? If yes, gets the noise. 
                    BCS      isNoise5 
                    RTS      

isNoise5 
                    STA      PLY_AKY_PSGREGISTER6         ;Sets the noise. 
 endif  PLY_AKY_USE_SoftAndHard_Noise_Agglomerated 
                    RTS      

 endif  PLY_CFG_UseHardwareSounds 
; -------------------------------------
