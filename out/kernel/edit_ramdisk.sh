#!/sbin/sh
#ramdisk_gov_sed.sh by show-p1984
#Features:
#extracts ramdisk
#finds busbox in /system or sets default location if it cannot be found
#add init.d support if not already supported
#removes governor overrides
#removes min freq overrides
#repacks the ramdisk

mkdir /tmp/ramdisk
cp /tmp/boot.img-ramdisk.gz /tmp/ramdisk/
cd /tmp/ramdisk/
gunzip -c /tmp/ramdisk/boot.img-ramdisk.gz | cpio -i
cd /

found=$(find /tmp/ramdisk/init.rc -type f | xargs grep -oh "run-parts /system/etc/init.d");
if [ "$found" != 'run-parts /system/etc/init.d' ]; then
        #find busybox in /system
        bblocation=$(find /system/ -name 'busybox')
        if [ -n "$bblocation" ] && [ -e "$bblocation" ] ; then
                echo "BUSYBOX FOUND!";
                #strip possible leading '.'
                bblocation=${bblocation#.};
        else
                echo "BUSYBOX NOT FOUND! init.d support will not work without busybox!";
                echo "Setting busybox location to /system/xbin/busybox! (install it and init.d will work)";
                #set default location since we couldn't find busybox
                bblocation="/system/xbin/busybox";
        fi
	#append the new lines for this option at the bottom
        echo "" >> /tmp/ramdisk/init.rc
        echo "service userinit $bblocation run-parts /system/etc/init.d" >> /tmp/ramdisk/init.rc
        echo "    oneshot" >> /tmp/ramdisk/init.rc
        echo "    class late_start" >> /tmp/ramdisk/init.rc
        echo "    user root" >> /tmp/ramdisk/init.rc
        echo "    group root" >> /tmp/ramdisk/init.rc
fi

#Don't force encryption
if  grep -qr forceencrypt /tmp/ramdisk/fstab.angler; then
   sed -i "s/forceencrypt/encryptable/" /tmp/ramdisk/fstab.angler
fi

#Disable dm_verity
if  grep -qr verify=/dev/block/platform/msm_sdcc.1/by-name/metadata /tmp/ramdisk/fstab.angler; then
   sed -i "s/\,verify\=\/dev\/block\/platform\/msm_sdcc\.1\/by\-name\/metadata//" /tmp/ramdisk/fstab.angler
fi

chmod 777 /tmp/ramdisk/boot.img-ramdisk.gz
rm -r /tmp/ramdisk/verity_key
chmod 777 /tmp/ramdisk/boot.img-ramdisk.gz
rm -r /tmp/ramdisk/boot.img-ramdisk.gz
rm /tmp/boot.img-ramdisk.gz
cd /tmp/ramdisk/
find . | cpio -o -H newc | gzip > ../boot.img-ramdisk.gz
cd /
rm -rf /tmp/ramdisk


