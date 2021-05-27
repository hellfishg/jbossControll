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
    local netstatOutput=$(netstat -anp 2>/dev/null | grep $port | grep LISTEN)
    ##hardcoding:
    #local netstatOutput="tcp6       0      0 :::9480                 :::*                    LISTEN      77164/java"

    if [[ -z $netstatOutput ]]; then
        echo "-ERROR: No se encontro la instancia con el puerto:"$port >&2
        exit 1
    fi

    local filtering=${netstatOutput##* } #Borra todo hasta el ultimo espacio.
    local filtering=${filtering%%/*} #Borra todo hasta antes de la slash.
    echo $filtering
}

function searchInstanceDataByPID() {
    #local instanceData=$(ps axfu | grep -i $1)
    #hardcoding:
    local instanceData=$"jbosst    19060  1.0  2.2 3026348 922756 ?      Sl   May18  38:00 /Appweb/Oracle_Java-1.8/bin/java -D[Standalone] -server -verbose:gc -Xloggc:/Appweb/jboss-eap-7/server/OSGSC/log/gc.log -XX:+PrintGCDetails -XX:+PrintGCDateStamps -XX:+UseGCLogFileRotation -XX:NumberOfGCLogFiles=5 -XX:GCLogFileSize=3M -XX:-TraceClassUnloading -Xmx1024m -Denvironment=testing -noverify -Djava.awt.headless=true -XX:+UseCompressedOops -javaagent:/Appweb/Wily10.7/Agent.jar -Dcom.wily.introscope.agentProfile=/Appweb/Wily10.7/core/config/IntroscopeAgent.JbossEAP7_OSGSC_TEST.profile -Djboss.modules.system.pkgs=org.jboss.byteman,com.wily,com.wily.* -Dorg.jboss.boot.log.file=/Appweb/jboss-eap-7/server/OSGSC/log/server.log -Dlogging.configuration=file:/Appweb/jboss-eap-7/server/OSGSC/configuration/logging.properties -jar /Appweb/jboss-eap-7/jboss-modules.jar -mp /Appweb/jboss-eap-7/modules org.jboss.as.standalone -Djboss.home.dir=/Appweb/jboss-eap-7 -Djboss.server.base.dir=/Appweb/jboss-eap-7/server/OSGSC --server-config=standalone.xml -Djboss.server.base.dir=/Appweb/jboss-eap-7/server/OSGSC/ -b 0.0.0.0 -bmanagment 0.0.0.0
    #jbosst    64413  0.0  0.0 112648   960 pts/5    S+   00:52   0:00 grep --color=auto 19060"

    if [[ -z $instanceData ]]; then
        echo "-ERROR: No se encuentra la instancia con el PID:"$1 >&2
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

##########################################################
echo "#######JBOSS CONTROL V.1.0#######"
echo -n -e "${redColour}+ Ingresar puerto: "
read PORT
echo -e ${endColour}

PID=""
nomInstancia=""
RUTE=""
jbossVersion=""

#############
PID=$(searchPIDByPort $PORT)
#echo $PID

##Validar Jboss-4.3:
#jboss4Validate=$(ps axfu | grep -i $PID | grep "/jboss-4")
#hardcoding:
#jboss4Validate="jbosst    1364  4.2 10.5 3026428 2376196 ?     Sl   May13 504:19 /Appweb/IBMJava2-X86-64BIT-60-SR8/bin/java -Dprogram.name=run.sh -Xmx2048m -Denvironment=testing -Dsetup -Dsnmp.port=7802 -Djboss.platform.mbeanserver -Djavax.management.builder.initial=org.jboss.system.server.jmx.MBeanServerBuilderImpl -Dcom.sun.management.jmxremote=true -Dcom.sun.management.jmxremote.port=6789 -Dcom.sun.management.jmxremote.authenticate=false -Dcom.sun.management.jmxremote.ssl=false -Dwebconsole.type=properties -Dwebconsole.jms.url=failover:(tcp://localhost:26647) -Dwebconsole.jmx.url=service:jmx:rmi:///jndi/rmi://localhost:9900/jmxrmi -Dwebconsole.jmx.role= -Dwebconsole.jmx.user=admin -Dwebconsole.jmx.password=admin -javaagent:/Appweb/Wily10.7/Agent.jar -Dcom.wily.introscope.agentProfile=/Appweb/Wily10.7/core/config/IntroscopeAgent.Jboss4.3_OSAuditorESB_TEST.profile -Dorg.apache.activemq.default.directory.prefix=/Appweb/jboss-4.3/server/OSAuditorESB/tmp -Djava.net.preferIPv4Stack=true -Djava.endorsed.dirs=/Appweb/jboss-4.3/lib/endorsed -classpath ::/Appweb/jboss-4.3/bin/run.jar:/Appweb/IBMJava2-X86-64BIT-60-SR8/lib/tools.jar org.jboss.Main -b 0.0.0.0 -c OSAuditorESB"

#jboss4Validate=""

##Valida si es una instancia jboss-4.3, dado que la salida por terminal es diferente.
if [[ -n $jboss4Validate ]]
then
    ##Es Jboss-4
    nomInstancia=${jboss4Validate##* }
    RUTE="/Appweb/jboss-4.3/server/"
else
    ##Es version mayor a 4.3
    instanceRawData=$(searchInstanceDataByPID $PID)
    #echo $instanceRawData
    RUTE=$(searchPathByInstanceRawData "$instanceRawData")
    #echo $RUTE
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
    #TODO: Ver si la carpeta es tmp
    echo "Borrando el contenido..."
    #trashPath="/Appweb/$jbossVersion/$nomInstancia/"
    ##hardcoding:
    trashPath="/home/hellfishg/Appweb/$jbossVersion/$nomInstancia/"
    echo $(rm -r "$trashPath"log/* ; rm -r "$trashPath"tmp/* ; rm -r "$trashPath"work/* )
fi

echo -e "${greenColour}#########################################################"
echo -n -e "${redColour}++Backup de los wars de la instancia(si/no):"
read choose
if [[ "$choose" = "si" || "$choose" = "SI" ]]; then
    echo "Copiando .war´s en la carpeta:"
    #backupPath="/Appweb/$jbossVersion/$nomInstancia/backup/"
    ##hardcoding:
    backupPath="/home/hellfishg/Appweb/$jbossVersion/$nomInstancia/backup/"
    echo $backupPath
    $(mkdir -p $backupPath)
    #echo $(cp /home/hellfishg/Appweb/$jbossVersion/$nomInstancia/deployed/*.war $backupPath)
    ##hardcoding:
    echo $(cp /home/hellfishg/Appweb/$jbossVersion/$nomInstancia/deployed/*.war $backupPath)
    sleep 1
fi

echo -e "${greenColour}#########################################################"
echo -n -e "${redColour}++Iniciar Instancia(si/no):"
read choose
if [[ "$choose" = "si" || "$choose" = "SI" ]]; then
    startPath="./Appweb/$jbossVersion/bin/JBOSSON/$nomInstancia-start.sh"
    echo "Iniciando..."
    echo $startPath
    echo $($startPath)
    sleep 1
fi

echo -e "${greenColour}#########################################################"
echo "Be water my friend"
echo "ps ps axfu | grep -i "$nomInstancia
echo -e "${endColour}"
