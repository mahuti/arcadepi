#!/bin/bash
printf "\033[H\033[2J"  #hide attractmode output
# eg: /opt/retropie/supplementary/runcommand/runEmulator.sh  0 _SYS_ arcade "filepath/to/galaga.zip"

VIDEOMODE=$1 # 0
COMMAND=$2 #_SYS_
SYSTEM=$3 #arcade
EMITSYSTEM=$3
ROM=$4 #filepath/to/galaga.zip

romname="${ROM##*/}" # removes the file path
romname="${romname%.*}" #removes the extension

#case $SYSTEM in
#     arcade|fba+*|mame+*|neogeo)$EMITSYSTEM=arcade;;
#     *);;
#esac

# set a default of 8 ways in case there isn't a way specified
#rotator 1 1 8
#emitter LoadProfileByEmulator "$romname" $EMITSYSTEM > /dev/null 2>&1

# this is used to handle special cases using a vanilla version of mame. These are all knocker games. everything else goes through retropie
case $romname in
        3stooges|argusg|curvebal|digdug|galaga|kngtmare|krull|mplanets|qbert|qbertqub|sqbert|wizwarz)
        # read -t 15 -p  "Romname $romname" # 15 second pause and output for testing purposes
        /home/pi/.mame/mame $romname
        ;;
        *)
        /opt/retropie/supplementary/runcommand/runcommand.sh  $VIDEOMODE $COMMAND $SYSTEM $ROM
        ;;
esac

#emitter FinishLastProfile > /dev/null 2>&1
#emitter LoadProfile attract  > /dev/null 2>&1

# set joystick "way"  back to vertical 2 so that the system can't select other displays
#rotator 1 1 vertical2
exit 0