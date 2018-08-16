#!/bin/bash
# Wrapper script for speech recognition
# Dependencies:
#    speech recognition service: (google or pocketsphinx installation for offline processing..etc)
#    If using offline support through pocketsphinx, also need language model and dictionary setup and configured below
#    SoX needs to be installed for sound preprocessing/filtering
resource_dir="/home/pi/jarvis/resources/en-us_ha_lm"
noise_prof="$resource_dir/noise.prof"
hardware="default"
duration="3"
lang="en"
ps_lm="$resource_dir/min-en-us_ha.lm.bin"
ps_dic="$resource_dir/min-en-us_ha.dic"
hw_bool=0
dur_bool=0
lang_bool=0
lm_bool=0
dic_bool=0
for var in "$@"
do
    if [ "$var" == "-D" ] ; then
        hw_bool=1
    elif [ "$var" == "-d" ] ; then
        dur_bool=1
    elif [ "$var" == "-l" ] ; then
        lang_bool=1
    elif [ "$var" == "-m" ] ; then
        lm_bool=1
    elif [ "$var" == "-M" ] ; then
        dic_bool=1
    elif [ $hw_bool == 1 ] ; then
        hw_bool=0
        hardware="$var"
    elif [ $dur_bool == 1 ] ; then
        dur_bool=0
        duration="$var"
    elif [ $lang_bool == 1 ] ; then
        lang_bool=0
        lang="$var"
    elif [ $lm_bool == 1 ] ; then
        lm_bool=0
        ps_lm="$var"
    elif [ $dic_bool == 1 ] ; then
        dic_bool=0
        ps_dic="$var"
    else
        echo "Invalid option, valid options are -D for hardware and -d for duration"
    fi
done

#this works really inconsistently and I don't know why. I would love to implement it
#arecord -D $hardware -t wav -d $duration -r 16000 | flac - -f --best -o /dev/shm/out.flac 1>/dev/shm/voice.log 2>/dev/shm/voice.log; curl -X POST --data-binary @/dev/shm/out.flac --user-agent 'Mozilla/5.0' --header 'Content-Type: audio/x-flac; rate=16000;' "https://www.google.com/speech-api/v2/recognize?output=json&lang=$lang&key=AIzaSyBOti4mM-6x9WDnZIjIeyEU21OpBXqWBgw&client=Mozilla/5.0" | sed -e 's/[{}]/''/g' | awk -F":" '{print $4}' | awk -F"," '{print $1}' | tr -d '\n'
#pocketsphinx offline speech to text resolution with sox filtering
arecord -D $hardware -f S16_LE -d $duration -r 16000 > /dev/shm/out.wav; sox /dev/shm/out.wav /dev/shm/out2.wav noisered $noise_prof 0.2 norm vad reverse vad reverse pad 1 0 2>/dev/shm/speech.log; pocketsphinx_continuous -agc max -remove_dc yes -vad_threshold 2.0 -topn 5 -ds 1 -maxwpf 4 -pl_window 0 -maxhmmpf 3000 -lm $ps_lm -dict $ps_dic -infile /dev/shm/out2.wav 2>/dev/shm/speech.log | tr '[:upper:]' '[:lower:]' | grep .
#pocketsphinx offline speech to text resolution
#arecord -D $hardware -f S16_LE -d $duration -r 16000 > /dev/shm/out.wav; pocketsphinx_continuous -agc max -remove_dc yes -vad_threshold 3.0 -topn 3 -ds 2 -maxwpf 3 -pl_window 0 -maxhmmpf 1000 -lm $ps_lm -dict $ps_dic -infile /dev/shm/out.wav 2>/dev/shm/speech.log | tr '[:upper:]' '[:lower:]'

# clear out file
#echo > /dev/shm/out.wav
#echo > /dev/shm/out2.wav
