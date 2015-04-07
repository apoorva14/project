

#!/bin/bash  
# Grading script for lab4 CSCI 4113 - Adding Users and Groups
# stat -c %a /my/file
# stat -c %U /my/file 
# that gives the user owner
# stat -c %G /my/file
# gives the group owner
startMachine=$1
endMachine=$2

if [ -z $startMachine ] || [ -z $endMachine ]; then 
	echo "Usage ./lab4.sh <startMachineNum> <endMachineNum>"
	exit $?
fi

nPeople=14
basePortNumber=20
declare -a users=("mscott" "dschrute" "jhalpert" "pbeesly" "abernard" "amartin" "kkapoor" \
	"omartinez" "dphilbin" "tflenderson" "kmalone" "plapin" "shudson" "mpalmer" "cbratton")
declare -a uidList=()
declare -a groups=("managers" "sales" "accounting")
declare -a managers=("mscott" "dschrute" "jhalpert")
declare -a sales=("abernard" "plapin" "shudson")
declare -a accounting=("amartin" "kmalone" "omartinez")
echo "Student #,All Users Exist On E,UIDs all in sync, Manager Groups, Sales Groups, Accounting Groups, /home GID"

# for i in 23; do
for i in $(seq -w $startMachine $endMachine); do
	uidList=()
	if [ $endMachine -lt 10 ]; then # Add a preceding 0
       	ssh_cmd_machineE="ssh -i $(echo ~)/.ssh/id_4113_summer14 -p ${basePortNumber}0${i} root@localhost"
    else # There will be a preceding 0 for numbers less than 10.
        ssh_cmd_machineE="ssh -i $(echo ~)/.ssh/id_4113_summer14 -p $basePortNumber$i root@localhost"
    fi
    if [ $i -lt 10 ]; then
        iClean=$(echo $i | tr -d "0")
    else
        iClean=$i
    fi

	ssh_cmd_machineA="ssh -i $(echo ~)/.ssh/id_4113_summer14 root@100.64.0.$iClean"
	ssh_cmd_machineB="ssh -i $(echo ~)/.ssh/id_4113_summer14 root@100.64.$iClean.2"
	ssh_cmd_machineC="ssh -i $(echo ~)/.ssh/id_4113_summer14 root@100.64.$iClean.3"
	ssh_cmd_machineD="ssh -i $(echo ~)/.ssh/id_4113_summer14 root@100.64.$iClean.4"

	echo -n "$iClean,"
	
	# if [[ $iClean == 12 ]]; then
	# 	continue;
	# fi

	$($ssh_cmd_machineA /bin/true 2> /dev/null)
	if [ $? -ne 0 ]; then echo "failed to connect"; continue; fi # abort this machine if ssh fails


	#1 All Users exist in Machine E's /etc/passwd
	notFound=0
    for n in "${users[@]}"; do
        existance=$($ssh_cmd_machineE getent passwd | cut -d: -f1 | grep $n > /dev/null) 2> /dev/null
        if [[ $? -ne 0 ]]; then
        	# Failure, didn't find a user
            notFound=$((notFound + 1))
            uidList+=("-1")
        else
        	uid=$($ssh_cmd_machineE getent passwd | grep $n | cut -d: -f3 )
        	# echo "uid is $uid"
			uidList+=($uid)
        fi
    done

	if [[ $notFound -gt 0 ]]; then echo -n "Missing $notFound users from Machine E,"; else echo -n "YES,"; fi

	#2 
	notEquals=0
	# Verify UIDs are synced up
	for i in $(seq 0 $nPeople); do
		uidA=$($ssh_cmd_machineA getent passwd | grep ${users[$i]} | cut -d: -f3)
		uidB=$($ssh_cmd_machineB getent passwd | grep ${users[$i]} | cut -d: -f3)
		uidC=$($ssh_cmd_machineC getent passwd | grep ${users[$i]} | cut -d: -f3)
		uidD=$($ssh_cmd_machineD getent passwd | grep ${users[$i]} | cut -d: -f3)
		if [ ! -z $uidA ] && [ ! -z $uidB ] && [ ! -z $uidC ] && [ ! -z $uidD ]; then
			# Found the user, increment notEqual if ID is not correct
			if [ $uidA -ne ${uidList[$i]} ]; then notEqual=$((notEquals + 1)); fi
			if [ $uidB -ne ${uidList[$i]} ]; then notEqual=$((notEquals + 1)); fi
			if [ $uidC -ne ${uidList[$i]} ]; then notEqual=$((notEquals + 1)); fi
			if [ $uidD -ne ${uidList[$i]} ]; then notEqual=$((notEquals + 1)); fi
		fi	
	done
	if [ $notEquals -gt 0 ]; then echo -n "NO  $notEquals UIDs not synced accross all machines,"; else echo -n "YES,"; fi

	#3 Check that all managers are in managers group
	missing=0
	for i in "${managers[@]}"; do
		searchA=$($ssh_cmd_machineA getent group | grep managers | grep $i)
		if [ $? -ne 0 ]; then missing=$((missing + 1)); echo A;	fi
		searchB=$($ssh_cmd_machineB getent group | grep managers | grep $i)
		if [ $? -ne 0 ]; then missing=$((missing + 1)); echo B;	fi
		searchC=$($ssh_cmd_machineC getent group | grep managers | grep $i)
		if [ $? -ne 0 ]; then missing=$((missing + 1)); echo C;	fi
		searchD=$($ssh_cmd_machineD getent group | grep managers | grep $i)
		if [ $? -ne 0 ]; then missing=$((missing + 1)); echo D;	fi
		searchE=$($ssh_cmd_machineE getent group | grep managers | grep $i)
		if [ $? -ne 0 ]; then missing=$((missing + 1)); echo E;	fi
	done
	if [ $missing -gt 0 ]; then echo -n "NO Manager groups missing total $missing users accross all machines,"; else echo -n "YES,"; fi

	#4 Check sales
	missing=0
	for i in "${sales[@]}"; do
		searchA=$($ssh_cmd_machineA getent group | grep sales | grep $i)
		if [ $? -ne 0 ]; then missing=$((missing + 1));	fi
		searchB=$($ssh_cmd_machineB getent group | grep sales | grep $i)
		if [ $? -ne 0 ]; then missing=$((missing + 1));	fi
		searchC=$($ssh_cmd_machineC getent group | grep sales | grep $i)
		if [ $? -ne 0 ]; then missing=$((missing + 1));	fi
		searchD=$($ssh_cmd_machineD getent group | grep sales | grep $i)
		if [ $? -ne 0 ]; then missing=$((missing + 1));	fi
		searchE=$($ssh_cmd_machineE getent group | grep sales | grep $i)
		if [ $? -ne 0 ]; then missing=$((missing + 1));	fi
	done
	if [ $missing -gt 0 ]; then echo -n "NO Sales groups missing total $missing users accross all machines,"; else echo -n "YES,"; fi

	#5 Check accounting
	missing=0
	for i in "${accounting[@]}"; do
		searchA=$($ssh_cmd_machineA getent group | grep accounting | grep $i)
		if [ $? -ne 0 ]; then missing=$((missing + 1));	fi
		searchB=$($ssh_cmd_machineB getent group | grep accounting | grep $i)
		if [ $? -ne 0 ]; then missing=$((missing + 1));	fi
		searchC=$($ssh_cmd_machineC getent group | grep accounting | grep $i)
		if [ $? -ne 0 ]; then missing=$((missing + 1));	fi
		searchD=$($ssh_cmd_machineD getent group | grep accounting | grep $i)
		if [ $? -ne 0 ]; then missing=$((missing + 1));	fi
		searchE=$($ssh_cmd_machineE getent group | grep accounting | grep $i)
		if [ $? -ne 0 ]; then missing=$((missing + 1));	fi
	done
	if [ $missing -gt 0 ]; then echo -n "NO Accounting groups missing total $missing users accross all machines,"; else echo -n "YES,"; fi
	
	searchE=$($ssh_cmd_machineE find /home -perm 2770 -or -perm 2070 | wc -l )

        if [ $searchE -eq 3 ];then
                echo "YES"
        else
                echo "NO E=$searchE"
        fi


done
