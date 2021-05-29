#!/usr/bin/bash
#By hellfishg 2021
#v.1.0

set -e #Seteo necesario para que tome el "exit" como salida del script en caso de error.
PATH="$PATH:/usr/bin:/bin" #Seteo de variable para ejecutar comandos.

##Colours
greenColour="\e[0;32m\033[1m"
redColour="\e[0;31m\033[1m"
blueColour="\e[0;34m\033[1m"
yellowColour="\e[0;33m\033[1m"
purpleColour="\e[0;35m\033[1m"
grayColour="\e[0;37m\033[1m"
endColour="\033[0m\e[0m"

function searchPIDByPort() {
    local port=$1
    #echo $port >&2
    local netstatOutput="$(netstat -anp 2>/dev/null | grep $port)"

    if [[ -z $netstatOutput ]]; then
        echo "-ERROR: No se encontro la instancia con el puerto:"$port >&2
        echo -e "${endColour}"
        exit 1
    fi

    #echo "salida por comando: "$netstatOutput >&2
    local filtering=${netstatOutput%% } #Borra el ultimo espacio.
    #echo "primer filtro: "$filtering >&2
    local filtering=${filtering%%/*} #Borra todo hasta antes de la slash.
    #echo "segundo filtro: "$filtering >&2
    local filtering=${filtering##* } #Borra todo hasta el ultimo espacio.
    #echo "tercero filtro: "$filtering >&2
    echo $filtering
}

function searchInstanceDataByPID() {
    local pid=$1
    #echo $pid >&2
    local instanceData=$(ps axfu | grep $pid)

    if [[ -z $instanceData ]]; then
        echo "-ERROR: No se encuentra la instancia con el PID:"$pid >&2
        echo -e "${endColour}"
        exit 1
    fi
    echo $instanceData
}

function searchPathByInstanceRawData() {
    local outputComm=$1
    local pattern1="/Appweb/jboss"
    local pattern2="/server/"

    for (( i = 0; i < ${#outputComm}; i++ )); do
        if [[ ${outputComm:$i:${#pattern1}} = $pattern1 ]]; then
            #echo ${outputComm:$i + ${#pattern}:15}
            for (( a = i; a < ($i + 25); a++ )); do
                if [[ ${outputComm:$a:${#pattern2}} = $pattern2 ]]; then
                    #echo $a "::" ${outputComm:$a:${#pattern2}}
                    for (( u = a + ${#pattern2}; u < ${#outputComm}; u++ )); do
                        if [[ ${outputComm:$u:1} = '/' ]]; then
                            charsCountDiff=$((u-i))
                            echo ${outputComm:$i:$charsCountDiff}
                            break 3
                        fi
                    done
                fi
            done
        fi
    done
}

function extractJbossName() {
    local rawPath=$1
    local filterAppweb="${rawPath:8}"
    echo ${filterAppweb%%/*}
}

# Main Function:
##########################################################
echo -e ${redColour}
echo "#######JBOSS CONTROL V.1.0#######"
echo -n "+ Ingresar puerto: "
read PORT
echo -e ${endColour}

PID=""
nomInstancia=""
RUTE=""
jbossVersion=""

#############
PID=$(searchPIDByPort $PORT)
echo "Este es el PID: "$PID

sleep 1
##Validar Jboss-4.3:
jboss4Validate=$"(ps axfu | grep $PID | grep /jboss-4)"

##Valida si es una instancia jboss-4.3, dado que la salida por terminal es diferente.
if [[ -z $jboss4Validate ]]; then
    ##Es Jboss-4
    nomInstancia="${jboss4Validate##* }"
    RUTE="/Appweb/jboss-4.3/server/"
else
    ##Es version mayor a 4.3
    instanceRawData=$(searchInstanceDataByPID $PID)
    #echo $instanceRawData
    RUTE=$(searchPathByInstanceRawData "$instanceRawData")
    echo $RUTE
    nomInstancia="${RUTE##*/}" #Extraer Nombre de instancia
fi

jbossVersion=$(extractJbossName "$RUTE")
##########################
echo -e "${greenColour}#########################################################"
echo "+Instancia:"$nomInstancia
echo "+Puerto:"$PORT
echo "+Jboss:"$jbossVersion
echo "#########################################################"
echo -n -e "${redColour}++Apagar la instancia(si/no):"
read choose
if [[ "$choose" = "si" || "$choose" = "SI" ]]; then
    echo $(kill -9 $PID)
    echo "Reiniciando..."
    sleep 2
    echo $(ps afxu | grep $PID)
fi

echo -e "${greenColour}#########################################################"
echo -n -e "${redColour}++Borrar contenido de Tmp/ Log/ Work/ (si/no):"
read choose
if [[ "$choose" = "si" || "$choose" = "SI" ]]; then
    echo "Borrando el contenido..."
    trashPath="/Appweb/$jbossVersion/server/$nomInstancia/"
    echo $(rm -r "$trashPath"log/* ; rm -r "$trashPath"tmp/* ; rm -r "$trashPath"work/* )
fi

echo -e "${greenColour}#########################################################"
echo -n -e "${redColour}++Backup de los wars de la instancia(si/no):"
read choose
if [[ "$choose" = "si" || "$choose" = "SI" ]]; then
    echo "Copiando .war´s en la carpeta:"
    backupPath="/Appweb/$jbossVersion/server/$nomInstancia/backup/"
    echo $backupPath
    $(mkdir -p $backupPath)
    echo $(cp /Appweb/$jbossVersion/server/$nomInstancia/deployments/*.war $backupPath)
    sleep 1
fi

echo -e "${greenColour}#########################################################"
echo -n -e "${redColour}++Iniciar Instancia(si/no):"
read choose
if [[ "$choose" = "si" || "$choose" = "SI" ]]; then
    startPath="sh /Appweb/$jbossVersion/bin/JBossON/$nomInstancia-start.sh"
    echo "Iniciando..."
    #echo $startPath
    echo $($startPath &> /dev/null)
    sleep 1
fi

echo -e "${greenColour}#########################################################"
echo "Be water my friend"
echo "ps axfu | grep -i "$nomInstancia
echo -e "${endColour}"
