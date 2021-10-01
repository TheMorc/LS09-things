#!/bin/bash
mkdir dataS_lua
mkdir dataS_lua/missions
mkdir dataS_lua/scripts
mkdir dataS_lua/scripts/environment
mkdir dataS_lua/scripts/gui
mkdir dataS_lua/scripts/objects
mkdir dataS_lua/scripts/sounds
mkdir dataS_lua/scripts/triggers
mkdir dataS_lua/scripts/vehicles
mkdir dataS_lua/scripts/vehicles/specializations

for i in $(find dataS -name '*.luc')
do
	echo "original file =" ${i}
    file_start=${i/dataS/dataS_lua} 
    file_end=${file_start/%.*/.lua}
    java -jar unluac.jar ${i} > ${file_end}
    echo "end file =" ${file_end}
    echo "------------------"
done
    
   