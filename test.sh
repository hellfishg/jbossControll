#!/usr/bin/bash

echo "Puerto APP: "
#read puertoVar
#echo $puertoVar

#perro=$(netstat -ano | grep Chromium)
#echo $perro

##Comandos reales:
#ps axfu | grep -i 18444
#netstat -anp | grep 18444
#cd /Appweb

##netstat -anp | grep 18444 | LISTEN

#netstat=$(netstat -anp | grep 8080)
##echo netstat

outputComm=$"jbosst    19060  1.0  2.2 3026348 922756 ?      Sl   May18  38:00 /Appweb/Oracle_Java-1.8/bin/java -D[Standalone] -server -verbose:gc -Xloggc:/Appweb/jboss-eap-7/server/OSGSC/log/gc.log -XX:+PrintGCDetails -XX:+PrintGCDateStamps -XX:+UseGCLogFileRotation -XX:NumberOfGCLogFiles=5 -XX:GCLogFileSize=3M -XX:-TraceClassUnloading -Xmx1024m -Denvironment=testing -noverify -Djava.awt.headless=true -XX:+UseCompressedOops -javaagent:/Appweb/Wily10.7/Agent.jar -Dcom.wily.introscope.agentProfile=/Appweb/Wily10.7/core/config/IntroscopeAgent.JbossEAP7_OSGSC_TEST.profile -Djboss.modules.system.pkgs=org.jboss.byteman,com.wily,com.wily.* -Dorg.jboss.boot.log.file=/Appweb/jboss-eap-7/server/OSGSC/log/server.log -Dlogging.configuration=file:/Appweb/jboss-eap-7/server/OSGSC/configuration/logging.properties -jar /Appweb/jboss-eap-7/jboss-modules.jar -mp /Appweb/jboss-eap-7/modules org.jboss.as.standalone -Djboss.home.dir=/Appweb/jboss-eap-7 -Djboss.server.base.dir=/Appweb/jboss-eap-7/server/OSGSC --server-config=standalone.xml -Djboss.server.base.dir=/Appweb/jboss-eap-7/server/OSGSC/ -b 0.0.0.0 -bmanagment 0.0.0.0
#jbosst    64413  0.0  0.0 112648   960 pts/5    S+   00:52   0:00 grep --color=auto 19060"

pattern="/Appweb/jboss"
pattern2="/server/"

###

function test () {
    #$1 hace referencia a el parametro.
    local text="$1"
    echo $text
}
##test "Hola como va"
###

MYVAR="/var/cpanel/users/joebloggs:DNS9=domain.com"
function cortar() {
    NAME=${MYVAR%:*}  # retain the part before the colon
    NAME=${NAME##*/}  # retain the part after the last slash
    echo $NAME
}
##cortar $MYVAR
###

##Contar total de caracteres:
#echo ${#MYVAR}
echo ${#outputComm}
#echo ${outputComm:$i:1}

###Buscar el path completo de la instancia:
pathSave=""
for (( i = 0; i < ${#outputComm}; i++ )); do
    if [[ ${outputComm:$i:${#pattern}} = $pattern ]]; then
        #echo ${outputComm:$i + ${#pattern}:15}
        for (( a = i; a < ($i + 25); a++ )); do
            if [[ ${outputComm:$a:${#pattern2}} = $pattern2 ]]; then
                #echo $a "::" ${outputComm:$a:${#pattern2}}
                for (( u = a + ${#pattern2}; u < ${#outputComm}; u++ )); do
                    if [[ ${outputComm:$u:1} = '/' ]]; then
                        resta=$((u-i))
                        pathSave=${outputComm:$i:$resta}
                        echo ++ $pathSave
                        break 3
                    fi
                done
            fi
        done
    fi
done

###Extraer Nombre de instancia:
nomInstancia="${pathSave##*/}"
echo $nomInstancia
