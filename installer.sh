#!/bin/bash
. functions.sh
. settings.sh
while [ ! "$main" == "00" ] ; do
main=$(MENU="Main Menu - Elsa Installer" menu \
	01 "Disk_Menu" \
	02 "Install_Sulin" \
	03 "Remaster_Sulin" \
	04 "Open_Shell" \
	00 "Exit" \
	gg "Reboot"
)
unset diskmenu
sync
case "$main" in
	01 )
		disk=$(MENU="Select Disk" getdisk)
		[ $? -eq 0 ] || diskmenu=00
		while [ ! "$diskmenu" == "00" ] ; do
			diskmenu=$(MENU="Disk Menu (/dev/$disk)" menu \
				01 "Edit" \
				02 "Mount" \
				03 "Umount" \
				04 "Format" \
				00 "Return")
			[ "$diskmenu" == "01" ] && cfdisk /dev/${disk}
			if [ "$diskmenu" == "02" ] ; then
				part=$(DISK=$disk MENU="Select Partition" getpart)
				umount -lf /mnt/${part} || true
				mkdir -p /mnt/${part} || true
				mount /dev/${part} /mnt/${part}
			elif [ "$diskmenu" == "03" ] ; then
				part=$(DISK=$disk MENU="Select Mounted Partition" getmount)
				umount -lf /mnt/${part}
			elif [ "$diskmenu" == "04" ] ; then
				part=$(DISK=$disk MENU="Select Partition for Format" getmount)
				mkfs.ext4 /dev/$part
			fi

		done
		;;
	02)
		if MSG="Continue Install Process?" promt ; then
		source="$SFSFILE"
		inmenu=""
		while [ "$inmenu" != "00" ] ; do
			inmenu=$(MENU="Install Menu\nTarget=$target\nSource=$source" menu \
				01 "Select_Target" \
				02 "Select_Source" \
				03 "Install" \
				04 "Create_User" \
				05 "Install_Grub" \
				00 "Return")
			if [ "$inmenu" == "01" ] ; then
				export target=$(DISK="name" MENU="Select Target Partition" getmount)
			elif [ "$inmenu" == "02" ] ; then
				export source=$(getfile "/")
			elif [ "$inmenu" == "03" ] ; then
				if [ -f "$source" ] || [ -b "$source" ] && [ "$target" != "" ] ; then
					mkdir -p /mnt/$target
					mkdir -p /mnt/source
					umount -fl  /mnt/source/ || true
					mount $source /mnt/source
					copy "/mnt/source/*" "/mnt/$target/" || exit
					mkdir -p /mnt/$target/dev
					mkdir -p /mnt/$target/sys
					mkdir -p /mnt/$target/proc
					mkdir -p /mnt/$target/run
					mount --bind /dev "/mnt/$target/dev"
					mount --bind /sys "/mnt/$target/sys"
					mount --bind /sys "/mnt/$target/proc"
					mount --bind /sys "/mnt/$target/run"
					pass=""
					pass2=""
					if [ ! -f "/mnt/$target/usr/bin/useradd" ] ; then
						MSG="Unable to connect target filesystem" msg
					else
						while [ "$pass"	!= "$pass2" ] || [ "$pass" == "" ] || [ "$pass2" == "" ]; do
								pass=$(MSG="New password for root:" input)
								pass2=$(MSG="Type again new password for root:" input)
						done
						echo -e "$pass\n$pass2" | chroot /mnt/$target/ passwd "$user"
					fi
				else
					MSG="Missing Value\n\nTarget=$target\nSource=$source" msg
				fi
			elif [ "$inmenu" == "04" ] ; then
				status=1
				if [ ! -f "/mnt/$target/usr/bin/useradd" ] ; then
					MSG="Unable to connect target filesystem" msg
				else
					while MSG="Do you wanna add new user?" promt && [ "$status" != "0" ]; do
						user=$(MSG="New user Name:" input)
						chroot /mnt/$target/ useradd -d "/data/user/$user" -m -g users -s "/bin/bash" "$user"
						status=$?
						if [ "$status" != "0" ] ; then
							MSG="User cannot create $user ($status)" msg
						else
							pass=""
							pass2=""
							while [ "$pass"	!= "$pass2" ] || [ "$pass" == "" ] || [ "$pass2" == "" ]; do
							pass=$(MSG="New password for $user:" input)
								pass2=$(MSG="Type again new password for $user:" input)
							done
							mkdir -p "/mnt/$target/data/app/$user"
							chown "$user" "/mnt/$target/data/app/$user"
							echo -e "$pass\n$pass2" | chroot /mnt/$target/ passwd "$user"
						fi
					done
				fi
			elif [ "$inmenu" == "05" ] ; then
				if [ ! -f "/mnt/$target/sbin/grub-install" ] ; then
					MSG="Unable to connect target filesystem" msg
				elif  MSG="Do you wanna install bootloader?" promt ; then
					disk=""
					while [ "$disk" == "" ] ; do					
						disk=$(MENU="Select grub disk" getdisk)
					done
					MSG="Installing bootloader..." info
					chroot /mnt/$target grub-install /dev/$disk || MSG="Unable to install bootloader on /dev/$disk" msg
					MSG="Generating grub.cfg" info
					chroot /mnt/$target update-grub
				fi
			else
				echo ""
			fi
		done
	fi
	;;
	03)
		remenu=""
		while [ "$remenu" != "00" ] ; do
			remenu=$(MENU="Remastering Menu\nTarget=$targetdir\nWork=$workdir\nVmlinuz=$vmlinuz\nInitrd=$initrd" menu \
				01 "Select_Target" \
				02 "Select_Work" \
				03 "Select_Kernel" \
				04 "Create_Live_Iso" \
				00 "return")
				if [ "$remenu" == "01" ] ; then
					targetdir=""
					while [ ! -d "$targetdir"	] ; do
						export targetdir=$(getdir "/")
					done
				elif [ "$remenu" == "02" ] ; then
					while [ ! -d "$workdir"	] ; do
						export workdir=$(getdir "/")
					done
					mkdir -p $workdir/isowork/boot/grub
				elif [ "$remenu" == "03" ] ; then
					initrd=""
					vmlinuz=""
					while [ ! -f "$targetdir/boot/$initrd" ] || [ ! -f "$targetdir/boot/$vmlinuz" ] ; do
						initrd=$( MSG="Input initrd name:\n$(ls $targetdir/boot | grep initrd)" input)
						vmlinuz=$(MSG="Input kernel name:\n$(ls $targetdir/boot | grep linux)" input)
					done
				elif [ "$remenu" == "04" ] ; then
					if [ ! -f "$targetdir/boot/$initrd" ] || [ ! -f "$targetdir/boot/$vmlinuz" ] || [ ! -d "$workdir"	] || [ ! -d "$targetdir"	] ; then
						MSG="Missing values\n\nInitrd=$initrd\nVmlinuz=$vmlinuz\nWorkdir=$workdir\nTarget=$targetdir" msg
					else
						clear
						mksquashfs $targetdir $workdir/isowork/main.sfs -comp xz -wildcards
						cp $targetdir/boot/$(vmlinuz) $workdir/isowork/vmlinuz
						cp $targetdir/boot/$(initrd) $workdir/isowork/initrd
						echo "linux /vmlinuz boot=live" > $workdir/isowork/boot/grub
						echo "initrd /initrd" >> $workdir/isowork/boot/grub
						echo "boot" >> $workdir/isowork/boot/grub
						grub-mkrescue $workdir/isowork -o $workdir/CustomSulin.iso
					fi
				fi
			done
		;;
	04)
		clear
		/bin/bash
		;;
	00)
		sync
		umount -lf -R /mnt/* 2/>dev/null
		clear
		exit
		;;
	gg)
		reboot
		;;
esac
done
