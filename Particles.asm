; MEGA simple particles and emitters
; one object only has 6 byte
; thus nearly 140 objects can be created!
;
; the demo runs with abour 135 dots

;
; ROM

                    code     
initParticle1 
                    INIT_OBJECTLIST  PARTICLE1_MAX_COUNT, Particle, objectsFinished1 
EMITT_ANGLE_ADD     =        4 
EMITT_DELAY         =        0 
;
                    ldx      #emitterData1 
                    ldd      #0                           ; position of emitter 
                    std      YPOS,x 
                    ldd      #EMITT_DELAY*256+0           ; delay 1, start angle 0 
                    std      ECOUNTER_RESET,x 
                    ldd      #0*256+EMITT_ANGLE_ADD       ; start countdown = 0, angle inc = 3 
                    std      ECOUNTER,x 
                    jsr      buildStationaryEmitter 
;
                    ldx      #emitterData2 
                    ldd      #0                           ; position of emitter 
                    std      YPOS,x 
                    ldd      #EMITT_DELAY*256+(255/3)     ; delay 1, start angle 0 
                    std      ECOUNTER_RESET,x 
                    ldd      #1*256+EMITT_ANGLE_ADD       ; start countdown = 0, angle inc = 3 
                    std      ECOUNTER,x 
                    jsr      buildStationaryEmitter 
;
                    ldx      #emitterData3 
                    ldd      #0                           ; position of emitter 
                    std      YPOS,x 
                    ldd      #EMITT_DELAY*256+0+((255/3)*2) ; delay 1, start angle 0 
                    std      ECOUNTER_RESET,x 
                    ldd      #2*256+EMITT_ANGLE_ADD       ; start countdown = 0, angle inc = 3 
                    std      ECOUNTER,x 
                    jsr      buildStationaryEmitter 
                    clr      anglechangeCountDown 
                    ldd      #angleAddData 
                    std      angleChangePointer 
                    rts      

;***************************************************************************
playParticle1 
                    dec      anglechangeCountDown 
                    bpl      noAngleChange 
                    lda      #5 
                    sta      anglechangeCountDown 
                    ldu      angleChangePointer 
                    leau     1,u 
                    cmpu     #angleAddDataEnd 
                    bne      noAngleReset 
                    ldu      #angleAddData 
noAngleReset 
                    stu      angleChangePointer 
                    lda      ,u 
                    sta      emitterData1+EANGLE_INC 
                    sta      emitterData2+EANGLE_INC 
                    sta      emitterData3+EANGLE_INC 
noAngleChange 
; pointer to circle data - is a constant!
                    ldy      #circleData 
                    ldu      plist_objects_head 
                    pulu     d,pc                         ; (D = y,x) ; do all objects 
objectsFinished1 
                    rts      

;***************************************************************************
playParticleInteractive 
                    JSR      Read_Btns                    ; get button status 
                    ldb      $C811                        ; button pressed - any 
                    bitb     #1                           ; is button 1 
 				  beq button1NotPressed
; button 1 inc angle increase
                    lda      emitterData1+EANGLE_INC 
 inca 
                    sta      emitterData1+EANGLE_INC 
                    sta      emitterData2+EANGLE_INC 
                    sta      emitterData3+EANGLE_INC 
 bra adjustDone
button1NotPressed
                    bitb     #2                           ; is button 1 

 				  beq button2NotPressed
; button 1 inc angle decrease
                    lda      emitterData1+EANGLE_INC 
 deca 
                    sta      emitterData1+EANGLE_INC 
                    sta      emitterData2+EANGLE_INC 
                    sta      emitterData3+EANGLE_INC 
 bra adjustDone
button2NotPressed
                    bitb     #4                           ; is button 1 

 				  beq button3NotPressed
; button 1 inc angle decrease
                    lda      emitterData1+ECOUNTER_RESET 
 beq  adjustDone
 deca 
                    sta      emitterData1+ECOUNTER_RESET 
                    sta      emitterData2+ECOUNTER_RESET 
                    sta      emitterData3+ECOUNTER_RESET 
 bra adjustDone
button3NotPressed

                    bitb     #8                           ; is button 1 

 				  beq button4NotPressed
; button 1 inc angle decrease
                    lda      emitterData1+ECOUNTER_RESET 
 inca 
                    sta      emitterData1+ECOUNTER_RESET 
                    sta      emitterData2+ECOUNTER_RESET 
                    sta      emitterData3+ECOUNTER_RESET 
 bra adjustDone
button4NotPressed



adjustDone
; pointer to circle data - is a constant!
                    ldy      #circleData 
                    ldu      plist_objects_head 
                    pulu     d,pc                         ; (D = y,x) ; do all objects 
objectsFinished1 
                    rts      

;***************************************************************************
angleAddData 
                    db       1,2,3,4,5,6,6,6,6,6,6,6,6,6,6,6,5,4,3,2,1,-1,-2,-3,-4,-5,-6,-6,-6,-6,-6,-6,-6,-6,-6,-6,-6,-5,-4,-3,-2,-1 
 db 1,2,3,4,5,6,7,8,9,10,10,10,10,10,10,10,10,10,10,10,11,12,13,14,14,14,14,14,14,14,14,14,14,15,15,15,15,15,15,15,15,15,15,15,15,15
angleAddDataEnd 
;***************************************************************************
;...........................................................................
buildStationaryEmitter 
                    jsr      newObject 
                    cmpu     #PLIST_COMPARE_ADDRESS 
                    bls      noNewEmitter 
                    stx      EMITTER_DATA,u 
                    ldd      #stationaryEmitterBehaviour 
                    std      BEHAVIOUR, u 
noNewEmitter 
                    rts      

;...........................................................................
stationaryEmitterBehaviour 
                    ldx      EMITTER_DATA+u_offset1,u 
                    lda      EDATA,x 
                    adda     EANGLE_INC,x 
                    sta      EDATA,x 
                    dec      ECOUNTER,x 
                    bpl      noNewParticle 
                    pshs     u 
                    lda      ECOUNTER_RESET,x 
                    sta      ECOUNTER,x 
                    jsr      newObject 
                    cmpu     #PLIST_COMPARE_ADDRESS 
                    bls      noNewParticle2 
                    lda      #1                           ; start scale 
                    ldb      EDATA,x                      ; position / angle 
                    std      P_SCALE,u 
                    ldd      #scaledAngleParticleBehaviour 
                    std      BEHAVIOUR, u 
noNewParticle2 
                    puls     u 
noNewParticle 
                    ldu      NEXT_OBJECT+u_offset1,u      ; preload next user stack 
                    pulu     d,pc 
;...........................................................................
scaledAngleParticleBehaviour 
; position to 
                    sta      <VIA_t1_cnt_lo 
                    clra     
                    MY_LSL_D  
                    ldd      d,y 
                    MY_MOVE_TO_D_START  
                    lda      P_SCALE+u_offset1,u 
                    adda     #2 
                    cmpa     #$56 
                    bhi      destroyPObject 
                    sta      P_SCALE+u_offset1,u 
                    ldu      NEXT_OBJECT+u_offset1,u      ; preload next user stack 
                    LDB      Vec_Dot_Dwell                ;Get dot dwell (brightness) 
                    DECB                                  ;Delay leaving beam in place 
                    MY_MOVE_TO_A_END  
                    dec      <VIA_shift_reg               ;Store in VIA shift register 
LF2CC_1 
                    DECB                                  ;Delay leaving beam in place 
                    BNE      LF2CC_1 
                    stb      <VIA_shift_reg               ;Blank beam in VIA shift register 
                    _ZERO_VECTOR_BEAM  
                    pulu     d,pc 
