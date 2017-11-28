#!/bin/bash

I2C_BUS=${I2C_BUS:-1}
chipAddr=0x54
source ./Functions.sh
echo "==============================================="
echo ""
while true; do
	read -r file_val < master.txt
	if [ "${#file_val}" -eq "8" ]; then
		export SERIAL_NUMBER=$file_val
		i2cget -y $I2C_BUS $chipAddr >>/dev/null 2>&1
		if [ "$?" -eq "0" ]; then
			export SERIAL_NUMBER=$file_val
			./eeprom.sh
			if [ "$?" -eq "0" ]; then
				echo "**********"
				echo "Success.."
				echo "**********"
				echo $file_val >> allocated.txt
				tail -n +2 master.txt > non-allocated.txt
				cat non-allocated.txt > master.txt
			elif [ "$?" -eq "1" ]; then
				echo "Serial number allocated"
			elif [ "$?" -eq "2" ]; then
				echo "Error: Not able to write"
			fi
		else
			sleep 1
			continue
		fi
	else
		echo $file_val >> invalid_serial.txt
		echo "$(tail -n +2 master.txt)" > master.txt
		continue
	fi
	while true; do
		i2cget -y $I2C_BUS $chipAddr >>/dev/null 2>&1;
		if [ "$?" -ne "0" ]; then
			break
		fi
		sleep 1
	done
done
