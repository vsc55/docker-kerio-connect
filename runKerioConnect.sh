#!/bin/bash

#
# Script de control de arranque para demonio Kerio Connect.
#
# @verions 2.0
# @fecha 23/10/2020
# @author Javier Pastor
# @license PENDIENTE
#

CONFIG_DIR=/config
CONFIG_LINKS_D=(store license sslcert settings)
CONFIG_LINKS_F=(mailserver.cfg users.cfg cluster.cfg stats.dat charts.dat mailserver.cfg.bak users.cfg.bak cluster.cfg.bak encryption.log derby.log)
CONFIG_WEB_CUSTOM=$CONFIG_DIR/web
CONFIG_MODE_CONSOLE=$CONFIG_DIR/consolemode.on

#     - /opt/kerio/mailserver/store
#     - /opt/kerio/mailserver/license
#     - /opt/kerio/mailserver/sslcert
#     - /opt/kerio/mailserver/settings
#     - /opt/kerio/mailserver/web/custom/*
#     - /opt/kerio/mailserver/mailserver.cfg
#     - /opt/kerio/mailserver/users.cfg
#     - /opt/kerio/mailserver/cluster.cfg
#     - /opt/kerio/mailserver/stats.dat
#     - /opt/kerio/mailserver/charts.dat
#         - /opt/kerio/mailserver/ldapmap

KERIO_VERSION=$(cat /KERIO_VERSION)
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
	echo "[WATCHDOG] - INICIADO..."
	while true
	do
		fun_isRunDaemonKerio	
		[[ $? -gt 0 ]] && break
		sleep $OPT_WATCHDOG_DELAY
	done
	echo "[WATCHDOG] - FINALIZADO - PROCESO TERMINADO!!!"
}

f_exit () {
	local exitCode
	exitCode=$1
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




# *** CONSOLE MODE *** [INI] ***
if [[ -f "$CONFIG_MODE_CONSOLE" ]]; then
	echo "Modo Consola Iniciado"
	/bin/bash
	echo "Modo Consola Finalizado"
	f_exit 0
fi
# *** CONSOLE MODE *** [END] ***




# *** GET VERSION KERIO [INI] ***
if [[ "$KERIO_VERSION" = "" ]]; then
	echo "[ERROR] NO SE DETECTO LA VERSION DE KERIO CONNECT!!!"
	f_exit 200001000
else
	echo "[INFO] - INICIANDO KERIO CONNECT ($KERIO_VERSION)..."
fi
# *** GET VERSION KERIO [END] ***




# *** CHECK - DAEMON *** [INI] ***

echo -n "[CHECK] - COMPROBANDO INSTALACION DE KERIO CONNECT..."
if [[ ! -d "$KERIO_MAINDIR" ]]; then
	echo " [ERROR!!]"
	echo " - NO SE DETECTO INSTALACION DE KERIO CONNECT EN [$KERIO_MAINDIR]!!!"
	f_exit 310001000
elif [[ ! -f "$KERIO_EXEC" ]]; then
	echo " [ERROR!!]"
	echo "[ERROR!!] - NO SE HA LOCALIZADO DEMONIO DE KERIO CONNECT EN [$KERIO_EXEC]!!!"
	f_exit 310005000
elif [[ ! -x "$KERIO_EXEC" ]]; then
	echo " [WARN]"
	echo -n " - FIX: CORRIGIENDO PERMISOS!"
	chmod +x "$KERIO_EXEC"
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

echo "[CHECK] - COMPROBANDO PATH CONFIG Y LINKS..."
if [[ ! -d "$CONFIG_DIR" ]]; then
	mkdir "$CONFIG_DIR"
fi
if [[ ! -d "$CONFIG_DIR" ]]; then
	echo "[ERROR] - NO SE HA PODIDO CREAR EL DIRECTORIO DE CONFIGURACION [$CONFIG_DIR]!!!"
	f_exit 320001000
fi

for i in "${CONFIG_LINKS_D[@]}"
do
	if [[ ! -d "$CONFIG_DIR/$i" ]]; then
		mkdir "$CONFIG_DIR/$i"
		echo "[NEW] - CREANDO DIR CONFIG [$CONFIG_DIR/$i]"
	fi

	if [[ ! -d "$KERIO_MAINDIR/$i" ]]; then
		ln -sf "$CONFIG_DIR/$i" "$KERIO_MAINDIR/$i"
		echo "[FIX] - CREANDO LINK [$KERIO_MAINDIR/$i]"
	fi
done

for i in "${CONFIG_LINKS_F[@]}"
do
	if [[ ! -f "$KERIO_MAINDIR/$i" ]]; then
		ln -sf "$CONFIG_DIR/$i" "$KERIO_MAINDIR/$i"
		echo "[FIX] - CREANDO LINK [$KERIO_MAINDIR/$i]"
	fi
done

if [[ ! -d "$CONFIG_WEB_CUSTOM" ]]; then
	mkdir "$CONFIG_WEB_CUSTOM"
fi
rm -fr "$KERIO_WEB_CUSTOM"
ln -sf "$CONFIG_WEB_CUSTOM" "$KERIO_WEB_CUSTOM"

# *** CHECK - CONFIG *** [END] ***




# *** CHECK - STATUS DEMONIO *** [INI] ***

echo -n "[CHECK] - COMPROBANDO ESTADO DEL DEMONIO..."
if fun_isRunDaemonKerio; then
	echo " [ABORT!!!!]"
	echo " - PROCESO ABORTADO YA QUE EL DEMONIO YA SE ESTA EJECUTANDO!!"
	f_exit 400000000
fi
echo " [OK]"
fun_remove_pid_kerio

# *** CHECK - STATUS DEMONIO *** [END] ***




# *** DAEMON *** [INI] ***

echo "[DAEMON] - INICIANDO DAEMON..."

if [[ -z "$LANG" ]]; then
	export LANG=es_ES.utf8
fi
export LC_ALL=$LANG
echo " - AJUSTANDO LANG Y LC_ALL [$LANG]... [OK]"

echo -n " - AJUSTANDO UNLIMIT'S..."
ulimit -c unlimited
ulimit -s 2048
ulimit -n 10240
echo " [OK]"


$KERIO_EXEC $KERIO_MAINDIR
RETVAL=$?

if [ $RETVAL -eq 0 ]; then
	# Waiting to complete start
	fun_wait_until_start_kerio
	RETVAL=$?
else
	echo " - NO SE PUDO INICIAR [ERROR!!!!]"
	f_exit 610000000
fi

if [ $RETVAL -eq 0 ]; then
	echo " - PROCESO DE INICIO FINALIZADO [OK]"
else
	echo " - ERROR AL INICIAR EL DEMONIO [ERROR!!!!]"
	f_exit 620000000
fi

# *** DAEMON *** [END] ***


# *** WATCHDOG *** [INI] ***
fun_start_watchdog_kerio
# *** WATCHDOG *** [END] ***
