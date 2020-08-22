if ! which $dialog 2> /dev/null ; then
    echo "$dialog not found."
    exit 1
fi
exec 3>&1
ifw(){
[ -z $1 ] || echo $2 $3
}
promt(){
	$dialog --yesno "$MSG" 0 0 2>&1 1>&3
}
input(){
	$dialog --inputbox "$MSG" 0 0 2>&1 1>&3
}
msg(){
	$dialog --msgbox "$MSG" 0 0 2>&1 1>&3
}

info(){
	$dialog --infobox "$MSG" 0 0 2>&1 1>&3
}
menu(){
	$dialog --menu "$MENU" 0 0 0 $* 2>&1 1>&3
}
getdir(){
	$dialog --dselect "$1" 14 48 2>&1 1>&3
}
getfile(){
	$dialog --fselect "$1" 14 48 2>&1 1>&3
}
copy(){
	$dialog --prgbox "Copying. Please Wait" "cp -prfv \"$1\" \"$2\" | sed 's/ -> .*//g' ; sync ; echo 'Press enter to continue'" 1000 1000 2>&1 1>&3
}
run(){
	$dialog --programbox "$TITLE" 1000 1000 2>&1 1>&3
}
prepare_disk(){
	for line in $* ; do
		echo -ne $line $(lsblk -J | grep "\"$line\"" | sed "s/.*size\":\"//g" | sed "s/\".*//g") " "
	done
}
getpart(){
	disklist=$(lsblk -J | grep "$DISK" | grep "type\":\"part" | sed "s/.*name\":\"//g" | sed "s/\".*//g")
	$dialog --menu "$MENU" 0 0 0 $(prepare_disk $disklist) 2>&1 1>&3
}
getmount(){
	disklist=$(lsblk -J | grep "$DISK" | grep "mountpoint"  | grep -v "\"/\"" | grep -v null | grep "type\":\"part" | sed "s/.*name\":\"//g" | sed "s/\".*//g")
	if [ "$disklist" == "" ] ; then
		$dialog --msgbox "Cannot find mounted partition" 0 0 2>&1 1>&3 
	else
		$dialog --menu "$MENU" 0 0 0 $(prepare_disk $disklist) 2>&1 1>&3
	fi
}

getdisk(){
	disklist=$(lsblk -J | grep "type\":\"disk" | sed "s/.*name\":\"//g" | sed "s/\".*//g")
	$dialog --menu "$MENU" 0 0 0 $(prepare_disk $disklist) 2>&1 1>&3

}

