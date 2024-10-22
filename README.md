# ArkosTrackerIII_AKY_Player

This package includes a AKY player for Arkos Tracker II (-> https://www.julien-nevo.com/arkostracker/).

Targhan released Arkos Tracker III (Test ->https://julien-nevo.com/at3test/) recently. He suggested a small update to the player due to a bug that was discovered in older versions of the player in the section "PLY_AKY_RRB_NIS_HARDWAREONLY".
I fixed this according to his instructions but I have not tested this extensively - also I have not had the time to try out Arkos Tracker III as of yet.

The sources included here are (apart from the mentioned fix) the sources I did 3 years back.
The "main" player is located in the file "aky_player.i".
The rest of the sources are a "demo" program for the vectrex on how to use the player (a VIDE-Project: http://vide.malban.de/ ) - following is the original describtion:

Player for the Vectrex of the AKY format
inspite of the 6809 being a BIG ENDIAN the AKY must be saved as sources for little ENDIAN, because that is what the code below interprets!

Plays at an average of about 2000 cycles spikes up to 2500 have been seen, it uses 32 bytes of RAM, starting at "arkosRamStart".

This is a manual transcode from the 6502 player, there has been no effort taken, to performance enhance this player.

MACROS for shadow register setting macros assumes; register U pointing to Vec_Music_Work (this is a shadow) assumes var register is positive (always...)


