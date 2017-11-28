#!/bin/bash

bus=1
chipAddr=0x54

function readFromI2c {
	value=""
	for l in {2..5}; do getValue="$(i2cget -y $bus $chipAddr "0x0""$l")"; value="$value""${getValue:2:2}"; done
	echo $value
	echo "$value" > cksum_temp
}

function verify {
	echo "verifying the checksum"
	checksum=""
	for l in {6..9}; do getValue="$(i2cget -y $bus $chipAddr "0x0""$l")"; checksum="$checksum""${getValue:2:2}"; done
	getFile=$(cksum cksum_temp | awk '{print $1}')
	hex_checksum=$(printf "%08x" $getFile)
	if [[ "$hex_checksum" == "$checksum" ]]; then
		echo "checksum is verified"
		return 0
	else
		echo "checksum verification failed"
		return 1
	fi
}
