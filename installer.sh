#!/bin/bash
. functions.sh
while [ ! "$main" == "00" ] ; do
main=$(MENU="Main Menu" menu \
	01 "Disk_Menu" \
	02 "Install_Sulin" \
	03 "Remaster_Sulin" \
	04 "Open_Shell" \
	00 "Exit"
	gg "reboot"
)
unset diskmenu
sync
case "$main" in
	01 )
		disk=$(MENU="Select Disk" getdisk)
		[ $? -eq 0 ] || diskmenu=00
		while [ ! "$diskmenu" == "00" ] ; do
			diskmenu=$(MENU="Disk Menu (/dev/$disk)" menu \
				01 edit \
				02 mount \
				03 umount \
				00 return)
			[ "$diskmenu" == "01" ] && cfdisk /dev/${disk}
			if [ "$diskmenu" == "02" ] ; then
				part=$(DISK=$disk MENU="Select Partition" getpart)
				umount -lf /mnt/${part} || true
				mkdir -p /mnt/${part} || true
				mount /dev/${part} /mnt/${part}
			elif [ "$diskmenu" == "03" ] ; then
				part=$(DISK=$disk MENU="Select Mounted Partition" getmount)
				umount -lf /mnt/${part}
			fi

		done
		;;
	02)
		if MSG="Continue Install Process?" promt ; then
			target=$(DISK="name" MENU="Select Target Partition" getmount)
			mkdir -p /mnt/target
			mkdir -p /mnt/source
			umount -fl -R  /mnt/source/* || true
			if MSG="Do you wanna use default source squashfs?" promt ; then
				mount /data/user/sulin/main.sfs /mnt/source				
			else
				sfs=$(getfile "/")
				mount $sfs /mnt/source

			fi
			copy "/mnt/source/*" "/mnt/target/"
			mount --bind /dev "/mnt/target/dev"
			mount --bind /sys "/mnt/target/sys"
			mount --bind /sys "/mnt/target/proc"
			mount --bind /sys "/mnt/target/run"
			status=1
			while MSG="Do you want to add new user?\nCurrent Users:\n    $(ls /mnt/target/data/user)" promt && [ "$status" != "0" ]; do
				pass=""
				pass2=""
				user=$(MSG="New user Name:" input)
				while [ "$pass"	!= "$pass2" ] || [ "$pass" == "" ] || [ "$pass2" == "" ]; do
					pass=$(MSG="New password for $user:" input)
					pass2=$(MSG="Type again new password for $user:" input)
				done
				chroot /mnt/target/ useradd -d "/data/user/$user" -m -g users -s "/bin/bash" "$user"
				sleep 3
				status=$?
				if [ "$status" != "0" ] ; then
					MSG="User cannot create $user ($status)" msg
				else
					mkdir -p "/mnt/target/data/app/$user"
					chown "$user" "/mnt/target/data/app/$user"
					echo -e "$pass\n$pass2" | chroot /mnt/target/ passwd "$user"
				fi
			done
			pass=""
			pass2=""
			while [ "$pass"	!= "$pass2" ] || [ "$pass" == "" ] || [ "$pass2" == "" ]; do
					pass=$(MSG="New password for root:" input)
					pass2=$(MSG="Type again new password for root:" input)
			done
			echo -e "$pass\n$pass2" | chroot /mnt/target/ passwd "$user"
			if MSG="Do you want to install grub?" promt ; then
				disk=$(MENU="Select grub disk" getdisk)
				[ "$disk" != "" ] && TITLE="Grub installing" CMD="chroot /mnt/target grub-install /dev/$disk && chroot \
				 /mnt/target grub-mkconfig > /mnt/target/boot/grub/grub.cfg" run
			fi
			MSG="Installation done." msg
			umount -lf -R "/mnt/target/*"
		fi
		;;
	03)
		MENU="Select target directory" targetdir=$(getdir "/")
		MENU="Select working directory" workdir=$(getdir "/")
		mkdir -p $workdir/isowork/boot/grub
		CMD="mksquashfs $targetdir $workdir/isowork/main.sfs -comp xz -wildcards" run
		MSG="Input initrd name:" initrd=$(input)
		MSG="Input kernel name:" vmlinuz=$(input)
		cp $targetdir/kernel/boot/$(vmlinuz) $workdir/isowork/vmlinuz
		cp $targetdir/kernel/boot/$(initrd) $workdir/isowork/initrd
		echo "linux /vmlinuz boot=live" > $workdir/isowork/boot/grub
		echo "initrd /initrd" >> $workdir/isowork/boot/grub
		echo "boot" >> $workdir/isowork/boot/grub
		CMD="grub-mkrescue $workdir/isowork -o $workdir/CustomSulin.iso" run
		;;
	04)
		clear
		/bin/bash
		;;
	00)
		clear
		exit
		;;
	gg)
		reboot
		;;
esac
done
