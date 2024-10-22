
SHADOW_FREQ_A = Vec_Snd_Shadow
SHADOW_FREQ_B = Vec_Snd_Shadow+2
SHADOW_FREQ_C = Vec_Snd_Shadow+4

SHADOW_VOL_A = Vec_Snd_Shadow+8
SHADOW_VOL_B = Vec_Snd_Shadow+8
SHADOW_VOL_C = Vec_Snd_Shadow+8

SHADOW_VOL_7 = Vec_Snd_Shadow+7


; changes to Arkos tracker exports
; a) Config variables must start the line! (no tabs before the config item names!)
;
;***************************************************************************
; DEFINE SECTION
;***************************************************************************
; load vectrex bios routine definitions
                    INCLUDE  "VECTREX.I"                  ; vectrex function includes
                    INCLUDE  "macro.i"                    ; vectrex function includes
;***************************************************************************
; Variable / RAM SECTION
;***************************************************************************
; insert your variables (RAM usage) in the BSS section
; user RAM starts at $c880 
                    BSS      
                    ORG      $c880                        ; start of our ram space 

                    struct   ParticleBase
                        ds       P_SCALE, 1 
                        ds       P_ANGLE, 1 
                        ds       BEHAVIOUR, 2 
                        ds       NEXT_OBJECT, 2 
                    end struct 

u_offset1           =        -NEXT_OBJECT                 ; behaviour offset is determined by next structure element 

PARTICLES_DONE_A    ds       2                            ; 
PARTICLES_DONE      =        PARTICLES_DONE_A-2 
; jump back addresses
; for "last" behaviour routine
;
PLIST_COMPARE_ADDRESS: 
startParticleRAM ds 0
PARTICLE1_MAX_COUNT  =       120 ;133                          ; max with below RAM 
;PARTICLE1_MAX_COUNT  =       70                          ; max with below RAM 
; Structures
                    struct   Emitter 
                        ds       EMITTER_DATA, 2 
                        ds       BEHAVIOUR, 2 
                        ds       NEXT_OBJECT, 2 
                    end struct 

                    struct   EmitterData 
                        ds       YPOS,1 
                        ds       XPOS,1 
                        ds       ECOUNTER_RESET, 1 
                        ds       EDATA, 1 
                        ds       ECOUNTER, 1 
                        ds       EANGLE_INC, 1 
                    end struct 

                    struct   Particle 
                        ds       P_SCALE, 1 
                        ds       P_ANGLE, 1 
                        ds       BEHAVIOUR, 2 
                        ds       NEXT_OBJECT, 2 
                    end struct 
; RAM
;
anglechangeCountDown  ds     1 
angleChangePointer  ds       2 
emitterData1        ds       EmitterData 
emitterData2        ds       EmitterData 
emitterData3        ds       EmitterData 
random_seed         ds       1 
plist_empty_head    ds       2                            ; if empty these contain a value that points to a RTS, smaller than OBJECT_LIST_COMPARE_ADDRESS 
plist_objects_head  ds       2                            ; if greater OBJECT_LIST_COMPARE_ADDRESS, than this is a pointer to a RAM location of an Object 
pCount              ds       1 
sinSpeed ds 1
sinAmplitude ds 1

gensin ds 0

pobject_list        ds       Particle*PARTICLE1_MAX_COUNT 
pobject_list_end    ds       0 



arkosRamStart ds 0

;***************************************************************************
; HEADER SECTION
;***************************************************************************
; The cartridge ROM starts at address 0
                    CODE     
                    ORG      0 
; the first few bytes are mandatory, otherwise the BIOS will not load
; the ROM file, and will start MineStorm instead
                    DB       "g GCE 2021", $80 ; 'g' is copyright sign
                    DW       music1                       ; music from the rom 
                    DB       $F8, $50, $20, -$80          ; hight, width, rel y, rel x (from 0,0) 
hello_world_string:
                    DB       "AKY PLAYER", $80              ; some game information, ending with $80
                    DB       0                            ; end of game header 
;***************************************************************************
; CODE SECTION
;***************************************************************************
; here the cartridge program starts off
                    ldy      #Main_Subsong0               ; song to be played 
;                   ldy      #Hokus_Subsong0               ; rom 
 clr sinSpeed
 lda #1
 sta sinAmplitude 

;??? clr currentSubSong
                    jsr      PLY_AKY_INIT 

MOVE_SCALE          =        $7f 
                    lda      #13 
                    sta      random_seed 
                    jsr      initParticle1 

main: 
                    JSR      Wait_Recal                   ; Vectrex BIOS recalibration 
                    JSR      Intensity_5F                 ; Sets the intensity of the 
; jsr     playParticleBySound; playParticle1 ;playParticleInteractive 
                                                          ; vector beam to $5f 
;;; jsr Reset0Ref
;;; jsr lineBySound

 jsr Reset0Ref
 jsr sinusBySoundA
;; jsr Reset0Ref
;; jsr sinusBySoundB
;; jsr Reset0Ref
;; jsr sinusBySoundC

 jsr Reset0Ref
 jsr lineBySound2_A
 jsr Reset0Ref
 jsr lineBySound2_B
 jsr Reset0Ref
 jsr lineBySound2_C


                    tst      PLY_error 
                    bne      nosong 
                    jsr      PLY_AKY_PLAY 
                    bsr      do_ym_sound2 
nosong 
                    BRA      main                         ; and repeat forever 


;
;                    struct   EmitterData 
;                        ds       YPOS,1 
;                        ds       XPOS,1 
;                        ds       ECOUNTER_RESET, 1 
;                        ds       EDATA, 1 
;                        ds       ECOUNTER, 1 
;                        ds       EANGLE_INC, 1 
;                    end struct 

lineBySound

 ldd #0x2000
 jsr Moveto_d_7F
 clra 
 ldb SHADOW_VOL_A
 addd SHADOW_FREQ_A
 lslb
 jsr Draw_Line_d
 jsr Reset0Ref

 ldd #0xd0d0
 jsr Moveto_d_7F
 clra 
 ldb SHADOW_VOL_B
 addd SHADOW_FREQ_B
 lslb
 jsr Draw_Line_d
 jsr Reset0Ref

 ldd #0xd020
 jsr Moveto_d_7F
 clra 
 ldb SHADOW_VOL_C
 addd SHADOW_FREQ_C
 lslb
 jsr Draw_Line_d
 jsr Reset0Ref
 rts

playParticleBySound 



                    lda      SHADOW_VOL_A
;                    lsla
;                    lsla

 adda SHADOW_FREQ_A+1 


 ldb SHADOW_VOL_7
 bitb #8
 bne noNoiseA
 nega
noNoiseA
                    sta      emitterData1+EANGLE_INC 

                    lda      SHADOW_VOL_B
 adda SHADOW_FREQ_B+1
;                    lsla

 ldb SHADOW_VOL_7
 bitb #16
 bne noNoiseB
 nega
noNoiseB

                    sta      emitterData2+EANGLE_INC 

                    lda      SHADOW_VOL_C
 adda SHADOW_FREQ_C+1
;                    lsla

 ldb SHADOW_VOL_7
 bitb #32
 bne noNoiseC
 nega
noNoiseC

                    sta      emitterData3+EANGLE_INC 





; pointer to circle data - is a constant!
                    ldy      #circleData 
                    ldu      plist_objects_head 
                    pulu     d,pc                         ; (D = y,x) ; do all objects 
objectsFinished1 
                    rts      

;***************************************************************************

doymsound100 
do_ym_sound2                                              ;#isfunction  
                    direct   $d0 
copySoundRegs 
; copy all shadows
                    lda      #13                          ; number of regs to copy (+1) 
                    ldx      #Vec_Music_Work              ; music players write here 
                    ldu      #Vec_Snd_Shadow              ; shadow of actual PSG 
next_reg_dsy: 
                    ldb      a, x 
                    cmpb     a, u 
                    beq      inc_reg_dsy 
; no put to psg
                    stb      a,u                          ; ensure shadow has copy 
; a = register
; b = value
                    STA      <VIA_port_a                  ;store register select byte 
                    LDA      #$19                         ;sound BDIR on, BC1 on, mux off _ LATCH 
                    STA      <VIA_port_b 
                    LDA      #$01                         ;sound BDIR off, BC1 off, mux off - INACTIVE 
                    STA      <VIA_port_b 
                    LDA      <VIA_port_a                  ;read sound chip status (?) 
                    STB      <VIA_port_a                  ;store data byte 
                    LDB      #$11                         ;sound BDIR on, BC1 off, mux off - WRITE 
                    STB      <VIA_port_b 
                    LDB      #$01                         ;sound BDIR off, BC1 off, mux off - INACTIVE 
                    STB      <VIA_port_b 
inc_reg_dsy: 
                    deca     
                    bpl      next_reg_dsy 
doneSound_2: 
                    rts      
;***************************************************************************
; DATA SECTION
;***************************************************************************

                    include  "HarmlessGrenade_vectrex.asm"
                    include  "HarmlessGrenade_vectrex_playerconfig.asm"
; or
;                    include  "HokusPokus_aky.asm"
;                    include  "HokusPokus_aky_playerconfig.asm"

                    include  "aky_player.i"
                    include  "objectHandling.asm"
                    include  "Particles.asm"


sin:
; sin generated 0°-360° in 360 steps, radius: 127
 db $00 ; degrees: 0°
 db $02 ; degrees: 1°
 db $04 ; degrees: 2°
 db $06 ; degrees: 3°
 db $08 ; degrees: 4°
 db $0B ; degrees: 5°
 db $0D ; degrees: 6°
 db $0F ; degrees: 7°
 db $11 ; degrees: 8°
 db $13 ; degrees: 9°
 db $16 ; degrees: 10°
 db $18 ; degrees: 11°
 db $1A ; degrees: 12°
 db $1C ; degrees: 13°
 db $1E ; degrees: 14°
 db $20 ; degrees: 15°
 db $23 ; degrees: 16°
 db $25 ; degrees: 17°
 db $27 ; degrees: 18°
 db $29 ; degrees: 19°
 db $2B ; degrees: 20°
 db $2D ; degrees: 21°
 db $2F ; degrees: 22°
 db $31 ; degrees: 23°
 db $33 ; degrees: 24°
 db $35 ; degrees: 25°
 db $37 ; degrees: 26°
 db $39 ; degrees: 27°
 db $3B ; degrees: 28°
 db $3D ; degrees: 29°
 db $3F ; degrees: 30°
 db $41 ; degrees: 31°
 db $43 ; degrees: 32°
 db $45 ; degrees: 33°
 db $47 ; degrees: 34°
 db $48 ; degrees: 35°
 db $4A ; degrees: 36°
 db $4C ; degrees: 37°
 db $4E ; degrees: 38°
 db $4F ; degrees: 39°
 db $51 ; degrees: 40°
 db $53 ; degrees: 41°
 db $54 ; degrees: 42°
 db $56 ; degrees: 43°
 db $58 ; degrees: 44°
 db $59 ; degrees: 45°
 db $5B ; degrees: 46°
 db $5C ; degrees: 47°
 db $5E ; degrees: 48°
 db $5F ; degrees: 49°
 db $61 ; degrees: 50°
 db $62 ; degrees: 51°
 db $64 ; degrees: 52°
 db $65 ; degrees: 53°
 db $66 ; degrees: 54°
 db $68 ; degrees: 55°
 db $69 ; degrees: 56°
 db $6A ; degrees: 57°
 db $6B ; degrees: 58°
 db $6C ; degrees: 59°
 db $6D ; degrees: 60°
 db $6F ; degrees: 61°
 db $70 ; degrees: 62°
 db $71 ; degrees: 63°
 db $72 ; degrees: 64°
 db $73 ; degrees: 65°
 db $74 ; degrees: 66°
 db $74 ; degrees: 67°
 db $75 ; degrees: 68°
 db $76 ; degrees: 69°
 db $77 ; degrees: 70°
 db $78 ; degrees: 71°
 db $78 ; degrees: 72°
 db $79 ; degrees: 73°
 db $7A ; degrees: 74°
 db $7A ; degrees: 75°
 db $7B ; degrees: 76°
 db $7B ; degrees: 77°
 db $7C ; degrees: 78°
 db $7C ; degrees: 79°
 db $7D ; degrees: 80°
 db $7D ; degrees: 81°
 db $7D ; degrees: 82°
 db $7E ; degrees: 83°
 db $7E ; degrees: 84°
 db $7E ; degrees: 85°
 db $7E ; degrees: 86°
 db $7E ; degrees: 87°
 db $7E ; degrees: 88°
 db $7E ; degrees: 89°
 db $7F ; degrees: 90°
 db $7E ; degrees: 91°
 db $7E ; degrees: 92°
 db $7E ; degrees: 93°
 db $7E ; degrees: 94°
 db $7E ; degrees: 95°
 db $7E ; degrees: 96°
 db $7E ; degrees: 97°
 db $7D ; degrees: 98°
 db $7D ; degrees: 99°
 db $7D ; degrees: 100°
 db $7C ; degrees: 101°
 db $7C ; degrees: 102°
 db $7B ; degrees: 103°
 db $7B ; degrees: 104°
 db $7A ; degrees: 105°
 db $7A ; degrees: 106°
 db $79 ; degrees: 107°
 db $78 ; degrees: 108°
 db $78 ; degrees: 109°
 db $77 ; degrees: 110°
 db $76 ; degrees: 111°
 db $75 ; degrees: 112°
 db $74 ; degrees: 113°
 db $74 ; degrees: 114°
 db $73 ; degrees: 115°
 db $72 ; degrees: 116°
 db $71 ; degrees: 117°
 db $70 ; degrees: 118°
 db $6F ; degrees: 119°
 db $6D ; degrees: 120°
 db $6C ; degrees: 121°
 db $6B ; degrees: 122°
 db $6A ; degrees: 123°
 db $69 ; degrees: 124°
 db $68 ; degrees: 125°
 db $66 ; degrees: 126°
 db $65 ; degrees: 127°
 db $64 ; degrees: 128°
 db $62 ; degrees: 129°
 db $61 ; degrees: 130°
 db $5F ; degrees: 131°
 db $5E ; degrees: 132°
 db $5C ; degrees: 133°
 db $5B ; degrees: 134°
 db $59 ; degrees: 135°
 db $58 ; degrees: 136°
 db $56 ; degrees: 137°
 db $54 ; degrees: 138°
 db $53 ; degrees: 139°
 db $51 ; degrees: 140°
 db $4F ; degrees: 141°
 db $4E ; degrees: 142°
 db $4C ; degrees: 143°
 db $4A ; degrees: 144°
 db $48 ; degrees: 145°
 db $47 ; degrees: 146°
 db $45 ; degrees: 147°
 db $43 ; degrees: 148°
 db $41 ; degrees: 149°
 db $3F ; degrees: 150°
 db $3D ; degrees: 151°
 db $3B ; degrees: 152°
 db $39 ; degrees: 153°
 db $37 ; degrees: 154°
 db $35 ; degrees: 155°
 db $33 ; degrees: 156°
 db $31 ; degrees: 157°
 db $2F ; degrees: 158°
 db $2D ; degrees: 159°
 db $2B ; degrees: 160°
 db $29 ; degrees: 161°
 db $27 ; degrees: 162°
 db $25 ; degrees: 163°
 db $23 ; degrees: 164°
 db $20 ; degrees: 165°
 db $1E ; degrees: 166°
 db $1C ; degrees: 167°
 db $1A ; degrees: 168°
 db $18 ; degrees: 169°
 db $16 ; degrees: 170°
 db $13 ; degrees: 171°
 db $11 ; degrees: 172°
 db $0F ; degrees: 173°
 db $0D ; degrees: 174°
 db $0B ; degrees: 175°
 db $08 ; degrees: 176°
 db $06 ; degrees: 177°
 db $04 ; degrees: 178°
 db $02 ; degrees: 179°
 db $00 ; degrees: 180°
 db $FE ; degrees: 181°
 db $FC ; degrees: 182°
 db $FA ; degrees: 183°
 db $F8 ; degrees: 184°
 db $F5 ; degrees: 185°
 db $F3 ; degrees: 186°
 db $F1 ; degrees: 187°
 db $EF ; degrees: 188°
 db $ED ; degrees: 189°
 db $EA ; degrees: 190°
 db $E8 ; degrees: 191°
 db $E6 ; degrees: 192°
 db $E4 ; degrees: 193°
 db $E2 ; degrees: 194°
 db $E0 ; degrees: 195°
 db $DD ; degrees: 196°
 db $DB ; degrees: 197°
 db $D9 ; degrees: 198°
 db $D7 ; degrees: 199°
 db $D5 ; degrees: 200°
 db $D3 ; degrees: 201°
 db $D1 ; degrees: 202°
 db $CF ; degrees: 203°
 db $CD ; degrees: 204°
 db $CB ; degrees: 205°
 db $C9 ; degrees: 206°
 db $C7 ; degrees: 207°
 db $C5 ; degrees: 208°
 db $C3 ; degrees: 209°
 db $C1 ; degrees: 210°
 db $BF ; degrees: 211°
 db $BD ; degrees: 212°
 db $BB ; degrees: 213°
 db $B9 ; degrees: 214°
 db $B8 ; degrees: 215°
 db $B6 ; degrees: 216°
 db $B4 ; degrees: 217°
 db $B2 ; degrees: 218°
 db $B1 ; degrees: 219°
 db $AF ; degrees: 220°
 db $AD ; degrees: 221°
 db $AC ; degrees: 222°
 db $AA ; degrees: 223°
 db $A8 ; degrees: 224°
 db $A7 ; degrees: 225°
 db $A5 ; degrees: 226°
 db $A4 ; degrees: 227°
 db $A2 ; degrees: 228°
 db $A1 ; degrees: 229°
 db $9F ; degrees: 230°
 db $9E ; degrees: 231°
 db $9C ; degrees: 232°
 db $9B ; degrees: 233°
 db $9A ; degrees: 234°
 db $98 ; degrees: 235°
 db $97 ; degrees: 236°
 db $96 ; degrees: 237°
 db $95 ; degrees: 238°
 db $94 ; degrees: 239°
 db $93 ; degrees: 240°
 db $91 ; degrees: 241°
 db $90 ; degrees: 242°
 db $8F ; degrees: 243°
 db $8E ; degrees: 244°
 db $8D ; degrees: 245°
 db $8C ; degrees: 246°
 db $8C ; degrees: 247°
 db $8B ; degrees: 248°
 db $8A ; degrees: 249°
 db $89 ; degrees: 250°
 db $88 ; degrees: 251°
 db $88 ; degrees: 252°
 db $87 ; degrees: 253°
 db $86 ; degrees: 254°
 db $86 ; degrees: 255°
 db $85 ; degrees: 256°
 db $85 ; degrees: 257°
 db $84 ; degrees: 258°
 db $84 ; degrees: 259°
 db $83 ; degrees: 260°
 db $83 ; degrees: 261°
 db $83 ; degrees: 262°
 db $82 ; degrees: 263°
 db $82 ; degrees: 264°
 db $82 ; degrees: 265°
 db $82 ; degrees: 266°
 db $82 ; degrees: 267°
 db $82 ; degrees: 268°
 db $82 ; degrees: 269°
 db $81 ; degrees: 270°
 db $82 ; degrees: 271°
 db $82 ; degrees: 272°
 db $82 ; degrees: 273°
 db $82 ; degrees: 274°
 db $82 ; degrees: 275°
 db $82 ; degrees: 276°
 db $82 ; degrees: 277°
 db $83 ; degrees: 278°
 db $83 ; degrees: 279°
 db $83 ; degrees: 280°
 db $84 ; degrees: 281°
 db $84 ; degrees: 282°
 db $85 ; degrees: 283°
 db $85 ; degrees: 284°
 db $86 ; degrees: 285°
 db $86 ; degrees: 286°
 db $87 ; degrees: 287°
 db $88 ; degrees: 288°
 db $88 ; degrees: 289°
 db $89 ; degrees: 290°
 db $8A ; degrees: 291°
 db $8B ; degrees: 292°
 db $8C ; degrees: 293°
 db $8C ; degrees: 294°
 db $8D ; degrees: 295°
 db $8E ; degrees: 296°
 db $8F ; degrees: 297°
 db $90 ; degrees: 298°
 db $91 ; degrees: 299°
 db $93 ; degrees: 300°
 db $94 ; degrees: 301°
 db $95 ; degrees: 302°
 db $96 ; degrees: 303°
 db $97 ; degrees: 304°
 db $98 ; degrees: 305°
 db $9A ; degrees: 306°
 db $9B ; degrees: 307°
 db $9C ; degrees: 308°
 db $9E ; degrees: 309°
 db $9F ; degrees: 310°
 db $A1 ; degrees: 311°
 db $A2 ; degrees: 312°
 db $A4 ; degrees: 313°
 db $A5 ; degrees: 314°
 db $A7 ; degrees: 315°
 db $A8 ; degrees: 316°
 db $AA ; degrees: 317°
 db $AC ; degrees: 318°
 db $AD ; degrees: 319°
 db $AF ; degrees: 320°
 db $B1 ; degrees: 321°
 db $B2 ; degrees: 322°
 db $B4 ; degrees: 323°
 db $B6 ; degrees: 324°
 db $B8 ; degrees: 325°
 db $B9 ; degrees: 326°
 db $BB ; degrees: 327°
 db $BD ; degrees: 328°
 db $BF ; degrees: 329°
 db $C1 ; degrees: 330°
 db $C3 ; degrees: 331°
 db $C5 ; degrees: 332°
 db $C7 ; degrees: 333°
 db $C9 ; degrees: 334°
 db $CB ; degrees: 335°
 db $CD ; degrees: 336°
 db $CF ; degrees: 337°
 db $D1 ; degrees: 338°
 db $D3 ; degrees: 339°
 db $D5 ; degrees: 340°
 db $D7 ; degrees: 341°
 db $D9 ; degrees: 342°
 db $DB ; degrees: 343°
 db $DD ; degrees: 344°
 db $E0 ; degrees: 345°
 db $E2 ; degrees: 346°
 db $E4 ; degrees: 347°
 db $E6 ; degrees: 348°
 db $E8 ; degrees: 349°
 db $EA ; degrees: 350°
 db $ED ; degrees: 351°
 db $EF ; degrees: 352°
 db $F1 ; degrees: 353°
 db $F3 ; degrees: 354°
 db $F5 ; degrees: 355°
 db $F8 ; degrees: 356°
 db $FA ; degrees: 357°
 db $FC ; degrees: 358°
 db $FE ; degrees: 359°

 db -1

sinDif
; sin generated 0°-360° in 360 steps, radius: 127
 db $00 ; degrees: 0°
 db $02 ; degrees: 1°
 db $02 ; degrees: 2°
 db $02 ; degrees: 3°
 db $02 ; degrees: 4°
 db $03 ; degrees: 5°
 db $02 ; degrees: 6°
 db $02 ; degrees: 7°
 db $02 ; degrees: 8°
 db $02 ; degrees: 9°
 db $03 ; degrees: 10°
 db $02 ; degrees: 11°
 db $02 ; degrees: 12°
 db $02 ; degrees: 13°
 db $02 ; degrees: 14°
 db $02 ; degrees: 15°
 db $03 ; degrees: 16°
 db $02 ; degrees: 17°
 db $02 ; degrees: 18°
 db $02 ; degrees: 19°
 db $02 ; degrees: 20°
 db $02 ; degrees: 21°
 db $02 ; degrees: 22°
 db $02 ; degrees: 23°
 db $02 ; degrees: 24°
 db $02 ; degrees: 25°
 db $02 ; degrees: 26°
 db $02 ; degrees: 27°
 db $02 ; degrees: 28°
 db $02 ; degrees: 29°
 db $02 ; degrees: 30°
 db $02 ; degrees: 31°
 db $02 ; degrees: 32°
 db $02 ; degrees: 33°
 db $02 ; degrees: 34°
 db $01 ; degrees: 35°
 db $02 ; degrees: 36°
 db $02 ; degrees: 37°
 db $02 ; degrees: 38°
 db $01 ; degrees: 39°
 db $02 ; degrees: 40°
 db $02 ; degrees: 41°
 db $01 ; degrees: 42°
 db $02 ; degrees: 43°
 db $02 ; degrees: 44°
 db $01 ; degrees: 45°
 db $02 ; degrees: 46°
 db $01 ; degrees: 47°
 db $02 ; degrees: 48°
 db $01 ; degrees: 49°
 db $02 ; degrees: 50°
 db $01 ; degrees: 51°
 db $02 ; degrees: 52°
 db $01 ; degrees: 53°
 db $01 ; degrees: 54°
 db $02 ; degrees: 55°
 db $01 ; degrees: 56°
 db $01 ; degrees: 57°
 db $01 ; degrees: 58°
 db $01 ; degrees: 59°
 db $01 ; degrees: 60°
 db $02 ; degrees: 61°
 db $01 ; degrees: 62°
 db $01 ; degrees: 63°
 db $01 ; degrees: 64°
 db $01 ; degrees: 65°
 db $01 ; degrees: 66°
 db $00 ; degrees: 67°
 db $01 ; degrees: 68°
 db $01 ; degrees: 69°
 db $01 ; degrees: 70°
 db $01 ; degrees: 71°
 db $00 ; degrees: 72°
 db $01 ; degrees: 73°
 db $01 ; degrees: 74°
 db $00 ; degrees: 75°
 db $01 ; degrees: 76°
 db $00 ; degrees: 77°
 db $01 ; degrees: 78°
 db $00 ; degrees: 79°
 db $01 ; degrees: 80°
 db $00 ; degrees: 81°
 db $00 ; degrees: 82°
 db $01 ; degrees: 83°
 db $00 ; degrees: 84°
 db $00 ; degrees: 85°
 db $00 ; degrees: 86°
 db $00 ; degrees: 87°
 db $00 ; degrees: 88°
 db $00 ; degrees: 89°
 db $01 ; degrees: 90°
 db $FF ; degrees: 91°
 db $00 ; degrees: 92°
 db $00 ; degrees: 93°
 db $00 ; degrees: 94°
 db $00 ; degrees: 95°
 db $00 ; degrees: 96°
 db $00 ; degrees: 97°
 db $FF ; degrees: 98°
 db $00 ; degrees: 99°
 db $00 ; degrees: 100°
 db $FF ; degrees: 101°
 db $00 ; degrees: 102°
 db $FF ; degrees: 103°
 db $00 ; degrees: 104°
 db $FF ; degrees: 105°
 db $00 ; degrees: 106°
 db $FF ; degrees: 107°
 db $FF ; degrees: 108°
 db $00 ; degrees: 109°
 db $FF ; degrees: 110°
 db $FF ; degrees: 111°
 db $FF ; degrees: 112°
 db $FF ; degrees: 113°
 db $00 ; degrees: 114°
 db $FF ; degrees: 115°
 db $FF ; degrees: 116°
 db $FF ; degrees: 117°
 db $FF ; degrees: 118°
 db $FF ; degrees: 119°
 db $FE ; degrees: 120°
 db $FF ; degrees: 121°
 db $FF ; degrees: 122°
 db $FF ; degrees: 123°
 db $FF ; degrees: 124°
 db $FF ; degrees: 125°
 db $FE ; degrees: 126°
 db $FF ; degrees: 127°
 db $FF ; degrees: 128°
 db $FE ; degrees: 129°
 db $FF ; degrees: 130°
 db $FE ; degrees: 131°
 db $FF ; degrees: 132°
 db $FE ; degrees: 133°
 db $FF ; degrees: 134°
 db $FE ; degrees: 135°
 db $FF ; degrees: 136°
 db $FE ; degrees: 137°
 db $FE ; degrees: 138°
 db $FF ; degrees: 139°
 db $FE ; degrees: 140°
 db $FE ; degrees: 141°
 db $FF ; degrees: 142°
 db $FE ; degrees: 143°
 db $FE ; degrees: 144°
 db $FE ; degrees: 145°
 db $FF ; degrees: 146°
 db $FE ; degrees: 147°
 db $FE ; degrees: 148°
 db $FE ; degrees: 149°
 db $FE ; degrees: 150°
 db $FE ; degrees: 151°
 db $FE ; degrees: 152°
 db $FE ; degrees: 153°
 db $FE ; degrees: 154°
 db $FE ; degrees: 155°
 db $FE ; degrees: 156°
 db $FE ; degrees: 157°
 db $FE ; degrees: 158°
 db $FE ; degrees: 159°
 db $FE ; degrees: 160°
 db $FE ; degrees: 161°
 db $FE ; degrees: 162°
 db $FE ; degrees: 163°
 db $FE ; degrees: 164°
 db $FD ; degrees: 165°
 db $FE ; degrees: 166°
 db $FE ; degrees: 167°
 db $FE ; degrees: 168°
 db $FE ; degrees: 169°
 db $FE ; degrees: 170°
 db $FD ; degrees: 171°
 db $FE ; degrees: 172°
 db $FE ; degrees: 173°
 db $FE ; degrees: 174°
 db $FE ; degrees: 175°
 db $FD ; degrees: 176°
 db $FE ; degrees: 177°
 db $FE ; degrees: 178°
 db $FE ; degrees: 179°
 db $FE ; degrees: 180°
 db $FE ; degrees: 181°
 db $FE ; degrees: 182°
 db $FE ; degrees: 183°
 db $FE ; degrees: 184°
 db $FD ; degrees: 185°
 db $FE ; degrees: 186°
 db $FE ; degrees: 187°
 db $FE ; degrees: 188°
 db $FE ; degrees: 189°
 db $FD ; degrees: 190°
 db $FE ; degrees: 191°
 db $FE ; degrees: 192°
 db $FE ; degrees: 193°
 db $FE ; degrees: 194°
 db $FE ; degrees: 195°
 db $FD ; degrees: 196°
 db $FE ; degrees: 197°
 db $FE ; degrees: 198°
 db $FE ; degrees: 199°
 db $FE ; degrees: 200°
 db $FE ; degrees: 201°
 db $FE ; degrees: 202°
 db $FE ; degrees: 203°
 db $FE ; degrees: 204°
 db $FE ; degrees: 205°
 db $FE ; degrees: 206°
 db $FE ; degrees: 207°
 db $FE ; degrees: 208°
 db $FE ; degrees: 209°
 db $FE ; degrees: 210°
 db $FE ; degrees: 211°
 db $FE ; degrees: 212°
 db $FE ; degrees: 213°
 db $FE ; degrees: 214°
 db $FF ; degrees: 215°
 db $FE ; degrees: 216°
 db $FE ; degrees: 217°
 db $FE ; degrees: 218°
 db $FF ; degrees: 219°
 db $FE ; degrees: 220°
 db $FE ; degrees: 221°
 db $FF ; degrees: 222°
 db $FE ; degrees: 223°
 db $FE ; degrees: 224°
 db $FF ; degrees: 225°
 db $FE ; degrees: 226°
 db $FF ; degrees: 227°
 db $FE ; degrees: 228°
 db $FF ; degrees: 229°
 db $FE ; degrees: 230°
 db $FF ; degrees: 231°
 db $FE ; degrees: 232°
 db $FF ; degrees: 233°
 db $FF ; degrees: 234°
 db $FE ; degrees: 235°
 db $FF ; degrees: 236°
 db $FF ; degrees: 237°
 db $FF ; degrees: 238°
 db $FF ; degrees: 239°
 db $FF ; degrees: 240°
 db $FE ; degrees: 241°
 db $FF ; degrees: 242°
 db $FF ; degrees: 243°
 db $FF ; degrees: 244°
 db $FF ; degrees: 245°
 db $FF ; degrees: 246°
 db $00 ; degrees: 247°
 db $FF ; degrees: 248°
 db $FF ; degrees: 249°
 db $FF ; degrees: 250°
 db $FF ; degrees: 251°
 db $00 ; degrees: 252°
 db $FF ; degrees: 253°
 db $FF ; degrees: 254°
 db $00 ; degrees: 255°
 db $FF ; degrees: 256°
 db $00 ; degrees: 257°
 db $FF ; degrees: 258°
 db $00 ; degrees: 259°
 db $FF ; degrees: 260°
 db $00 ; degrees: 261°
 db $00 ; degrees: 262°
 db $FF ; degrees: 263°
 db $00 ; degrees: 264°
 db $00 ; degrees: 265°
 db $00 ; degrees: 266°
 db $00 ; degrees: 267°
 db $00 ; degrees: 268°
 db $00 ; degrees: 269°
 db $FF ; degrees: 270°
 db $01 ; degrees: 271°
 db $00 ; degrees: 272°
 db $00 ; degrees: 273°
 db $00 ; degrees: 274°
 db $00 ; degrees: 275°
 db $00 ; degrees: 276°
 db $00 ; degrees: 277°
 db $01 ; degrees: 278°
 db $00 ; degrees: 279°
 db $00 ; degrees: 280°
 db $01 ; degrees: 281°
 db $00 ; degrees: 282°
 db $01 ; degrees: 283°
 db $00 ; degrees: 284°
 db $01 ; degrees: 285°
 db $00 ; degrees: 286°
 db $01 ; degrees: 287°
 db $01 ; degrees: 288°
 db $00 ; degrees: 289°
 db $01 ; degrees: 290°
 db $01 ; degrees: 291°
 db $01 ; degrees: 292°
 db $01 ; degrees: 293°
 db $00 ; degrees: 294°
 db $01 ; degrees: 295°
 db $01 ; degrees: 296°
 db $01 ; degrees: 297°
 db $01 ; degrees: 298°
 db $01 ; degrees: 299°
 db $02 ; degrees: 300°
 db $01 ; degrees: 301°
 db $01 ; degrees: 302°
 db $01 ; degrees: 303°
 db $01 ; degrees: 304°
 db $01 ; degrees: 305°
 db $02 ; degrees: 306°
 db $01 ; degrees: 307°
 db $01 ; degrees: 308°
 db $02 ; degrees: 309°
 db $01 ; degrees: 310°
 db $02 ; degrees: 311°
 db $01 ; degrees: 312°
 db $02 ; degrees: 313°
 db $01 ; degrees: 314°
 db $02 ; degrees: 315°
 db $01 ; degrees: 316°
 db $02 ; degrees: 317°
 db $02 ; degrees: 318°
 db $01 ; degrees: 319°
 db $02 ; degrees: 320°
 db $02 ; degrees: 321°
 db $01 ; degrees: 322°
 db $02 ; degrees: 323°
 db $02 ; degrees: 324°
 db $02 ; degrees: 325°
 db $01 ; degrees: 326°
 db $02 ; degrees: 327°
 db $02 ; degrees: 328°
 db $02 ; degrees: 329°
 db $02 ; degrees: 330°
 db $02 ; degrees: 331°
 db $02 ; degrees: 332°
 db $02 ; degrees: 333°
 db $02 ; degrees: 334°
 db $02 ; degrees: 335°
 db $02 ; degrees: 336°
 db $02 ; degrees: 337°
 db $02 ; degrees: 338°
 db $02 ; degrees: 339°
 db $02 ; degrees: 340°
 db $02 ; degrees: 341°
 db $02 ; degrees: 342°
 db $02 ; degrees: 343°
 db $02 ; degrees: 344°
 db $03 ; degrees: 345°
 db $02 ; degrees: 346°
 db $02 ; degrees: 347°
 db $02 ; degrees: 348°
 db $02 ; degrees: 349°
 db $02 ; degrees: 350°
 db $03 ; degrees: 351°
 db $02 ; degrees: 352°
 db $02 ; degrees: 353°
 db $02 ; degrees: 354°
 db $02 ; degrees: 355°
 db $03 ; degrees: 356°
 db $02 ; degrees: 357°
 db $02 ; degrees: 358°
 db $02 ; degrees: 359°
 db %10000000
 db %10000000
 db %10000000
 db %10000000
 db %10000000
 db %10000000
 db %10000000
 db %10000000
 db %10000000
 db %10000000
 db %10000000
 db %10000000
 db %10000000
 db %10000000
 db %10000000
 db %10000000
 db %10000000
 db %10000000
 db %10000000
 db %10000000

;---------
generateSin
 ldx #gensin
 ldu #sinDif

sinAgain
 ldb ,u
 cmpb #%10000000
 beq generateSinDone
 lda sinSpeed
 leau a,u
 lda sinAmplitude
 mul
 stb ,x+
 bra sinAgain
generateSinDone
 stb ,x
;---------
 rts
amplitudes
 db 1,2,3,4,5,6,6,8,9,10,10,12,12,12,15,15,15,15

; macro D = D /2
MY_LSR_D            macro    
                    ASRA     
                    RORB     
                    endm 


CRUNCH_FREQ macro
 lsrb
 lsrb
 lsrb
 lsrb

 incb ; at least one!
 endm

sinusBySoundA
 ldb SHADOW_FREQ_A
 lda SHADOW_FREQ_A+1
 anda #$f
 CRUNCH_FREQ
; ldb #5
 ldx #amplitudes
 ldb b,x
 stb sinSpeed

; 1, 2, 3, 4, 5, 6
; not 7, 11, 13
 lda SHADOW_VOL_A
 anda #$f
 sta sinAmplitude
 bsr generateSin

 lda #$80 
 sta <VIA_t1_cnt_lo
 ldd #$7f00




displaySinus

 jsr Moveto_d

 lda #$ff 
 sta <VIA_t1_cnt_lo

 ldu #$0010


 lda #-8; $80 ; move down
 STA      <VIA_port_a 
 CLRA     
 STA      <VIA_port_b                  ;Enable mux 
 INC      <VIA_port_b                  ;Disable mux 
 STA      <VIA_port_a 
 stu <VIA_t1_cnt_lo               ;enable timer 
 dec <VIA_shift_reg

 LDb      #$40                         ; 
sinReload
 ldx #gensin
sinAgain
 lda ,x+
 cmpa #%10000000
 beq sinReload
 STa      <VIA_port_a ; x coordinate

 BITb     <VIA_int_flags               
 BEQ      sinAgain
 inc <VIA_shift_reg

 rts



sinusBySoundB
 ldb SHADOW_FREQ_B
 lda SHADOW_FREQ_B+1
 anda #$f
 CRUNCH_FREQ
; ldb #5
 ldx #amplitudes
 ldb b,x
 stb sinSpeed

; 1, 2, 3, 4, 5, 6
; not 7, 11, 13
 lda SHADOW_VOL_B
 anda #$f
 sta sinAmplitude
 bsr generateSin

 lda #$80 
 sta <VIA_t1_cnt_lo
 ldd #$7f40
 jmp displaySinus

sinusBySoundC
 ldb SHADOW_FREQ_C
 lda SHADOW_FREQ_C+1
 anda #$f
 CRUNCH_FREQ
; ldb #5
 ldx #amplitudes
 ldb b,x
 stb sinSpeed

; 1, 2, 3, 4, 5, 6
; not 7, 11, 13
 lda SHADOW_VOL_C
 anda #$f
 sta sinAmplitude
 bsr generateSin

 lda #$80 
 sta <VIA_t1_cnt_lo
 ldd #$7fc0
 jmp displaySinus











lineBySound2_A
 lda #$80
 sta <VIA_t1_cnt_lo

 ldd #$4080
 jsr Moveto_d

 lda #$ff
 sta <VIA_t1_cnt_lo

 ldb SHADOW_FREQ_A
 lda SHADOW_FREQ_A+1
 ; 12 bit 
 MY_LSR_D            
 MY_LSR_D            
 MY_LSR_D            
 MY_LSR_D            
 ; 8 bit
 MY_LSR_D            
 ; 7 bit

 jsr Moveto_d

 lda #$40
 sta <VIA_t1_cnt_lo

 lda SHADOW_VOL_A
 anda #$f
 ; 4 bit
 lsla 
 lsla 
 lsla 
 ; 4 bit
 ldb #0
 jsr Draw_Line_d
 jsr Reset0Ref

 rts


lineBySound2_B
 lda #$80
 sta <VIA_t1_cnt_lo

 ldd #$0080
 jsr Moveto_d

 lda #$ff
 sta <VIA_t1_cnt_lo

 ldb SHADOW_FREQ_B
 lda SHADOW_FREQ_B+1
 ; 12 bit 
 MY_LSR_D            
 MY_LSR_D            
 MY_LSR_D            
 MY_LSR_D            
 ; 8 bit
 MY_LSR_D            
 ; 7 bit

 jsr Moveto_d

 lda #$40
 sta <VIA_t1_cnt_lo

 lda SHADOW_VOL_B
 anda #$f
 ; 4 bit
 lsla 
 lsla 
 lsla 
 ; 4 bit
 ldb #0
 jsr Draw_Line_d
 jsr Reset0Ref
 rts


lineBySound2_C
 lda #$80
 sta <VIA_t1_cnt_lo

 ldd #$c080
 jsr Moveto_d

 lda #$ff
 sta <VIA_t1_cnt_lo

 ldb SHADOW_FREQ_C
 lda SHADOW_FREQ_C+1
 ; 12 bit 
 MY_LSR_D            
 MY_LSR_D            
 MY_LSR_D            
 MY_LSR_D            
 ; 8 bit
 MY_LSR_D            
 ; 7 bit
 clra
 jsr Moveto_d

 lda #$40
 sta <VIA_t1_cnt_lo

 lda SHADOW_VOL_C
 anda #$f
 ; 4 bit
 lsla 
 lsla 
 lsla 
 ; 4 bit
 ldb #0
 jsr Draw_Line_d
 jsr Reset0Ref

 rts


