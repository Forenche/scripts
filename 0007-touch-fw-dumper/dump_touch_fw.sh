#!/bin/bash

wget "https://android.googlesource.com/platform/system/tools/mkbootimg/+archive/refs/heads/master.tar.gz" &> /dev/null
	tar -xf master.tar.gz unpack_bootimg.py && chmod +x unpack_bootimg.py && rm master.tar.gz

python3 "../unpack_bootimg.py" --boot_img boot.img --out . &> /dev/null

xxd -g 1 zImage | grep "40 71 02 00" -B1 -A8702 | grep -oE "[0-9a-f]+ [0-9a-f]+ [0-9a-f]+ [0-9a-f]+ [0-9a-f]+ [0-9a-f]+ [0-9a-f]+ [0-9a-f]+ [0-9a-f]+ [0-9a-f]+ [0-9a-f]+ [0-9a-f]+ [0-9a-f]+ [0-9a-f]+ [0-9a-f]+ [0-9a-f]+" > firmware.xxd

xxd -r -p <(sed -n '1,8704p'      firmware.xxd | sed "s/ //g" | tr -d '\n') > novatek_nt36675_j3s_fw01.bin
xxd -r -p <(sed -n '8705,17408p'  firmware.xxd | sed "s/ //g" | tr -d '\n') > novatek_nt36675_j3s_mp01.bin
xxd -r -p <(sed -n '17409,26112p' firmware.xxd | sed "s/ //g" | tr -d '\n') > novatek_ts_fw.bin
xxd -r -p <(sed -n '26113,34816p' firmware.xxd | sed "s/ //g" | tr -d '\n') > novatek_ts_mp.bin

dos2unix -f ./*.bin

find . -type f -iname "*.bin" -exec avr-objcopy -I binary -O ihex {} {}.ihex \;

dos2unix -f ./*.ihex

md5sum ./*.bin ./*.ihex >> info.txt

ZIPNAME="APOLLO_TOUCH_FW.zip"
zip -r9 "$ZIPNAME" ./*.bin ./*.ihex info.txt &> /dev/null

if [[ $3 != '' && $3 == 'k' ]]; then
	zip -ur "$ZIPNAME" firmware.xxd kernel
fi

rm ./*.ihex info.txt firmware.xxd

if [[ $2 != '' && $2 == 'u' ]]; then
	UPLOAD=$(curl -s -F f[]=@"$ZIPNAME" "https://oshi.at" | grep DL | sed 's/DL: //g')
	echo -e "$UPLOAD\n" >> ../links.txt
fi

mkdir extracted-fw
mv "$ZIPNAME" extracted-fw/
