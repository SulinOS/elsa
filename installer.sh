#!/bin/bash
. settings.sh
. functions.sh
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
				umount -lf /esla/${part} || true
				mkdir -p /esla/${part} || true
				mount /dev/${part} /esla/${part}
			elif [ "$diskmenu" == "03" ] ; then
				part=$(DISK=$disk MENU="Select Mounted Partition" getmount)
				umount -lf /esla/${part}
			elif [ "$diskmenu" == "04" ] ; then
				part=$(DISK=$disk MENU="Select Partition for Format" getpart)
				umount -lf /dev/$part
				if  MSG="Do you wanna format /dev/$part as ext4?" promt ; then
					TITLE="Format: /dev/$part" yes | mkfs.ext4 /dev/$part | run
				fi
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
					mkdir -p /esla/$target
					mkdir -p /esla/source
					umount -fl  /esla/source/ || true
					mount $source /esla/source
					copy "/esla/source/" "/esla/$target/" || exit
					mkdir -p /esla/$target/dev
					mkdir -p /esla/$target/sys
					mkdir -p /esla/$target/proc
					mkdir -p /esla/$target/run
					mount --bind /dev "/esla/$target/dev"
					mount --bind /sys "/esla/$target/sys"
					mount --bind /sys "/esla/$target/proc"
					mount --bind /sys "/esla/$target/run"
					pass=""
					pass2=""
					read -n 1
					if [ ! -f "/esla/$target/usr/sbin/useradd" ] ; then
						MSG="Unable to connect target filesystem" msg
					else
						while [ "$pass"	!= "$pass2" ] || [ "$pass" == "" ] || [ "$pass2" == "" ]; do
								pass=$(MSG="New password for root:" input)
								pass2=$(MSG="Type again new password for root:" input)
						done
						echo -e "$pass\n$pass2" | chroot /esla/$target/ passwd "$user"
					fi
				else
					MSG="Missing Value\n\nTarget=$target\nSource=$source" msg
				fi
			elif [ "$inmenu" == "04" ] ; then
				status=1
				if [ ! -f "/esla/$target/usr/sbin/useradd" ] ; then
					MSG="Unable to connect target filesystem" msg
				else
					while MSG="Do you wanna add new user?" promt && [ "$status" != "0" ]; do
						user=$(MSG="New user Name:" input)
						chroot /esla/$target/ useradd -d "/data/user/$user" -m -g users -s "/bin/bash" "$user"
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
							mkdir -p "/esla/$target/data/app/$user"
							chown "$user" "/esla/$target/data/app/$user"
							echo -e "$pass\n$pass2" | chroot /esla/$target/ passwd "$user"
						fi
					done
				fi
			elif [ "$inmenu" == "05" ] ; then
				if [ ! -f "/esla/$target/sbin/grub-install" ] ; then
					MSG="Unable to connect target filesystem" msg
				elif  MSG="Do you wanna install bootloader?" promt ; then
					disk=""
					while [ "$disk" == "" ] ; do					
						disk=$(MENU="Select grub disk" getdisk)
					done
					MSG="Installing bootloader..." info
					if [ -d /sys/firmware/efi ] ; then
						efidisk=""
						while [ "$efidisk" == "" ] ; do		
							efidisk=$(MENU="Select efi partition" DISK="$disk" getpart)
						done
						mkdir -p /esla/$target/boot/efi || true
						mount /dev/$efidisk /esla/$target/boot/efi
					fi
					chroot /esla/$target grub-install /dev/$disk || MSG="Unable to install bootloader on /dev/$disk" msg
					MSG="Generating grub.cfg" info
					chroot /esla/$target update-grub
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
					while [ ! -f "$targetdir/boot/$initrd" ] ; do
						initrd=$( MSG="Input initrd name:\n$(ls $targetdir/boot | grep initrd)" input)
					done
					vmlinuz=""
					while [ ! -f "$targetdir/boot/$vmlinuz" ] ; do
						vmlinuz=$(MSG="Input kernel name:\n$(ls $targetdir/boot | grep linux)" input)
					done
				elif [ "$remenu" == "04" ] ; then
					if [ ! -f "$targetdir/boot/$initrd" ] || [ ! -f "$targetdir/boot/$vmlinuz" ] || [ ! -d "$workdir"	] || [ ! -d "$targetdir"	] ; then
						MSG="Missing values\n\nInitrd=$initrd\nVmlinuz=$vmlinuz\nWorkdir=$workdir\nTarget=$targetdir" msg
					else
						clear
						umount -R -lf $targetdir/* 2>/dev/null
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
		umount -lf -R /esla/* 2/>dev/null
		clear
		exit
		;;
	gg)
		reboot
		;;
esac
done
