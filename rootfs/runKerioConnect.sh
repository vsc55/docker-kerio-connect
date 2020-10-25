#!/bin/bash

#
# Script de control de arranque para demonio Kerio Connect.
#
# @verions 3.0
# @fecha 23/10/2020
# @author Javier Pastor
# @license PENDIENTE
#

DEFAULT_LANG=en_US.utf8

CONFIG_DIR=/config
CONFIG_MODE_CONSOLE=$CONFIG_DIR/consolemode.on
CONFIG_LOG=$CONFIG_DIR/docker.log

KERIO_DEFAULT=/config_default
KERIO_VERSION_F=/KERIO_VERSION
KERIO_VERSION=$(cat $KERIO_VERSION_F)
KERIO_MAINDIR=/opt/kerio/mailserver
KERIO_DAEMON=mailserver
KERIO_DAEMON_NAME=mailserver
KERIO_EXEC=$KERIO_MAINDIR/$KERIO_DAEMON
KERIO_PIDFILE=/var/run/kms.pid
KERIO_WEB_CUSTOM=$KERIO_MAINDIR/web/custom

OPT_STAR_DELAY=4                    # delay in active waiting (in start and stop)
OPT_STAR_TTIMEOUT=30                # max waiting on start (second)
OPT_WATCHDOG_DELAY=10


fun_remove_pid_kerio() {
	if [[ -z "`pidof $KERIO_DAEMON_NAME`" ]] && [[ -f $KERIO_PIDFILE ]]; then
		rm -f $KERIO_PIDFILE
		[[ $? -gt 0 ]] && return 1 || return 0
	fi
}

fun_isRunDaemonKerio() {
	local pid
	if [[ -n "`pidof $KERIO_DAEMON_NAME`" ]]; then
		if [ -e $KERIO_PIDFILE ]; then
			if [[ -r $KERIO_PIDFILE ]]; then
				pid=$( cat $KERIO_PIDFILE )
				if  [[ -z "$pid" ]]; then
					#el archivo pid existe pero esta vacio.
					return 5
				elif [[ -n "$(ps -p $pid -o pid=)" ]]; then
					#proceso se esta ejecutando
					return 0
				fi
				#el proceso no se esta ejecutando
				return 1
			fi
			#existe el archivo pid, pero no hay permiso de lectura
			return 4
		fi
		#no existe el archivo pid
		return 3
	fi
	#no existe ningun proceso en ejecucion
	return 2
	
	#return 0 => [OK]  => EL PROCESO SE ESTA EJECUTADO OK
	#return 1 => [ERR] => EL PROCESO NO SE ESTA EJECUTANDO
	#return 2 => [ERR] => NO EXISTE NINGUN PROCESO EN EJECUCION
	#return 3 => [ERR] => EL ARCHIVO PID NO EXISTE
	#return 4 => [ERR] => EL ARCHIVO PID EXISTE, PERO NO HAY PERMISOS DE LECTURA
	#return 5 => [ERR] => EL ARCHIVO PID EXISTE PERO ESTA VACIO
}

# Waiting to complete start
fun_wait_until_start_kerio() {
	local delay
	sleep 1 # min waiting
	delay=$OPT_STAR_TTIMEOUT
	while [ $delay -gt 0 ] && [ -n "`pidof $KERIO_DAEMON`" ] && [ ! -e $KERIO_PIDFILE ]; do
		sleep $OPT_STAR_DELAY
		delay=$(( $delay - $OPT_STAR_DELAY ))
	done
	fun_isRunDaemonKerio	
	[[ $? -gt 0 ]] && return 1 || return 0
}

fun_start_watchdog_kerio() {
	while true
	do
		fun_isRunDaemonKerio	
		[[ $? -gt 0 ]] && break
		sleep $OPT_WATCHDOG_DELAY
	done
}

f_exit () {
	local exitCode=$1
	echo "[$(date '+%Y/%m/%d %H:%M:%S')] - exitCode: $exitCode" >> $CONFIG_LOG
	[[ -z exitCode ]] && exitCode=0
	if [[ exitCode -le 99999999 ]]; then
		#0 - 99999999
		exit 0
	elif [[ exitCode -le 199999999 ]]; then
		#100000000 - 199999999
		exit 1
	elif [[ exitCode -le 299999999 ]]; then
		#200000000 - 299999999
		exit 2
	elif [[ exitCode -le 399999999 ]]; then
		#300000000 - 399999999
		exit 3
	elif [[ exitCode -le 499999999 ]]; then
		#400000000 - 499999999
		exit 4
	elif [[ exitCode -le 599999999 ]]; then
		#500000000 - 599999999
		exit 5
	elif [[ exitCode -le 699999999 ]]; then
		#600000000 - 699999999
		exit 6
	else
		#700000000 EN ADELANTE
		exit 9
	fi
}

fun_create_item()
{
	local loc_item=$1
	local loc_file=$2

	if [[ -d "$loc_item" ]]; then
		echo -n " [FIX ] - CREATING FOLDER ($loc_file)..."
		mkdir "$loc_file" 2>> $CONFIG_LOG
		if [ $? -gt 0 ]; then
			echo " [ERR!!]"
			return 1
		fi

	elif [[ -f "$loc_item" ]]; then
		echo -n " [FIX ] - CREATING FILE ($loc_file)..."
		touch "$loc_file" 2>> $CONFIG_LOG
		if [ $? -gt 0 ]; then
			echo " [ERR!!]"
			return 2
		fi

	else
		echo -n " [ERR!] - ERROR CREATING ($loc_file) UNKNOWN TYPE!"
		return 3
	fi
	echo " [OK]"
	return 0
}





# *** CONSOLE MODE *** [INI] ***
if [[ -f "$CONFIG_MODE_CONSOLE" ]]; then
	echo "*** CONSOLE MODE [INITIATED] **"
	/bin/bash
	echo "*** CONSOLE MODE [TERMINATED] **"
	f_exit 0
fi
# *** CONSOLE MODE *** [END] ***




# *** GET VERSION KERIO [INI] ***
if [[ "$KERIO_VERSION" = "" ]]; then
	echo "[ERROR] KERIO CONNECT VERSION NOT DETECTED!!!"
	f_exit 200001000
else
	echo "[INFO] - STARTING KERIO CONNECT ($KERIO_VERSION)..."
fi
# *** GET VERSION KERIO [END] ***




# *** CHECK - DAEMON *** [INI] ***
echo -n "[CHECK] - CHECKING KERIO CONNECT INSTALLATION..."
if [[ ! -d "$KERIO_MAINDIR" ]]; then
	echo " [ERROR!!]"
	echo " - NO KERIO CONNECT INSTALLATION DETECTED [$KERIO_MAINDIR]!!!"
	f_exit 310001000
elif [[ ! -f "$KERIO_EXEC" ]]; then
	echo " [ERROR!!]"
	echo " - KERIO CONNECT DEMON NOT LOCATED [$KERIO_EXEC]!!!"
	f_exit 310005000
elif [[ ! -x "$KERIO_EXEC" ]]; then
	echo " [WARN]"
	echo -n " - FIX: PERMISSIONS..."
	chmod +x "$KERIO_EXEC" 2>> $CONFIG_LOG
	if [[ $? -gt 0 ]]; then 
		echo " [ERR!!]"
		f_exit 310010000
	fi
	echo " [OK]"
else
	echo " [OK]"
fi
# *** CHECK - DAEMON *** [END] ***




# *** CHECK - CONFIG *** [INI] ***
echo "CHECKING THE DIRECTORY STRUCTURE..."
if [[ ! -d "$CONFIG_DIR" ]]; then
	echo " [ERR!] - CONFIG FOLDER [$CONFIG_DIR] DOES NOT EXIST!"
	f_exit 320001000
else
	echo " [ OK ] - CONFIG FOLDER [$CONFIG_DIR] EXISTS."
	cp -u "$KERIO_VERSION_F" "$CONFIG_DIR"
	if [[ $? -gt 0 ]]; then 
		echo " [ERR!] - ERROR UPDATING FILE VERSION!"
		f_exit 320002000
	else
		echo " [ OK ] - FILE VERSION UPDATED SUCCESSFULLY."
	fi
fi

for item in $KERIO_DEFAULT/*; do
    item_name=$(basename $item)
    item_config=$CONFIG_DIR/$item_name
	item_kerio=$KERIO_MAINDIR/$item_name

    if [[ ! -e "$item_config" ]]; then
		fun_create_item $item $item_config || f_exit 320006010
    fi
	
	if [[ ! -e "$item_kerio" ]]; then
		fun_create_item $item $item_kerio || f_exit 320006050
    fi
done

# TODO: ACTUALIZAR PROPIETARIO DE TODOS LOS DATOS
# *** CHECK - CONFIG *** [END] ***




# *** MOUNT FOLDER AND FILES [INI] ***
echo -n "[MOUNT] - MOUNT FOLDERS AND FILES..."
mount -a 2>> $CONFIG_LOG
if [ $? -gt 0 ]; then
	echo " [ERRRO!!]"
	echo " - ERROR MOUNT!"
	f_exit 400000000
fi
echo " [OK]"
# *** MOUNT FOLDER AND FILES [END] ***




# *** CHECK - STATUS DEMONIO *** [INI] ***
echo -n "[CHECK] - CHECKING DEMON STATUS..."
if fun_isRunDaemonKerio; then
	echo " [ABORT!!!!]"
	echo " - PROCESS ABORTED AS THE DEMON IS ALREADY RUNNING!"
	f_exit 500000000
fi
echo " [OK]"
fun_remove_pid_kerio
# *** CHECK - STATUS DEMONIO *** [END] ***




# *** DAEMON *** [INI] ***
echo "[DAEMON] - STARTING DAEMON..."

if [[ -z "$LANG" ]]; then
	NEW_LANG=$DEFAULT_LANG
else
	NEW_LANG=$LANG
fi
echo -n " - SET LANG ($NEW_LANG)..."
export LANG=$NEW_LANG
export LC_ALL=$NEW_LANG
echo " [OK]"

echo -n " - SET UNLIMIT'S..."
ulimit -c unlimited
ulimit -s 2048
ulimit -n 10240
echo " [OK]"

echo -n " - STARTING..."
$KERIO_EXEC $KERIO_MAINDIR
if [ $? -eq 0 ]; then
	# Waiting to complete start
	if ! fun_wait_until_start_kerio; then
		echo " [ERRRO!!]"
		echo " - ERROR IN STARTING THE DEMON!"
		f_exit 620000000
	fi
else
	echo " [ERRRO!!]"
	echo " - FAILED TO START!"
	f_exit 610000000
fi
echo " [OK]"
# *** DAEMON *** [END] ***




# *** WATCHDOG *** [INI] ***
echo "[WATCHDOG] - RUNNING..."
fun_start_watchdog_kerio
echo "[WATCHDOG] - PROCESS FINISHED"
# *** WATCHDOG *** [END] ***
