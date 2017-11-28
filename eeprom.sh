#!/bin/bash


# The serial number is written in following format
# -------0x00 0x01 0x02 0x03 0x04 0x05 0x06 0x07 0x08 0x09------
# ------- BA   2C   MSB...........LSB   MSB...........LSB-------
# -------Identifier  Meter serial No.    Checksum (cksum)-------

chipAddr=0x54
bus=${I2C_BUS:-1}
RETURN_VALUE=2

function verify {
	echo "verifying the checksum"
	checksum=""
	for l in {6..9}; do getValue="$(i2cget -y $bus $chipAddr "0x0""$l")"; checksum="$checksum""${getValue:2:2}"; done
	getFile=$(cksum cksum_temp | awk '{print $1}')
	hex_checksum=$(printf "%08x" $getFile)
	if [[ "$hex_checksum" == "$checksum" ]]; then
		echo "checksum is verified"
		if [ $RETURN_VALUE -ne 0 ]; then
			RETURN_VALUE=1
		fi
	else
		echo "checksum verification failed"
		RETURN_VALUE=2
	fi
}

function readFromI2c {
	value=""
	for l in {2..5}; do getValue="$(i2cget -y $bus $chipAddr "0x0""$l")"; value="$value""${getValue:2:2}"; done
	echo "the value identified is: $(printf "%d" "0x""$value")"
	echo "$value" > cksum_temp
}

function writeToI2c {
	RETURN_VALUE=0
	x=$SERIAL_NUMBER
	# read x
	hex_x=$(printf "%08x" "$x")
	for l in {2..5}; do i2cset -y $bus $chipAddr "0x0""$l" "0x""${hex_x:$((2*(l-2))):2}"; done
	echo "generating checksum"
	echo "$hex_x" > cksum_temp
	checksum=$(cksum cksum_temp | awk '{print $1}')
	hex_checksum=$(printf "%08x" $checksum)
	for l in {6..9}; do i2cset -y $bus $chipAddr "0x0""$l" "0x""${hex_checksum:$((2*(l-6))):2}"; done
	verify
}

identifier=""
for l in {0..1}; do identifier="$identifier""$(i2cget -y $bus $chipAddr "0x0""$l")"; done
if [[ "$identifier" == "0xba0x2c" ]]; then
	echo "identifier is found"
	readFromI2c
	verify
	if [ "$?" -eq 2 ]; then
		echo "writing the serial number $SERIAL_NUMBER"
		writeToI2c
	fi
else
	echo "WRITING THE IDENTIFIER"
	i2cset -y $bus $chipAddr "0x00" "0xba"
	i2cset -y $bus $chipAddr "0x01" "0x2c"
	echo "writing the serial number $SERIAL_NUMBER"
	writeToI2c
fi
exit $RETURN_VALUE
