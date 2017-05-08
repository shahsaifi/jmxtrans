#!/bin/bash

################################################################################################################################################################################
#                                                                                                                                                                              #
#          8                                         8                                8""""8 8""""8       888888        8  8""8""8 8    8 ""8""                                #
#          8  eeeee eeeee eeeee eeeee e     e        8  eeeee eeee e     e   e e    e 8    8 8    8       8   ,         8  8  8  8 8    8   8   eeeee  eeeee eeeee eeeee       #
#          8e 8   8 8   "   8   8   8 8     8        8e 8   8 8    8     8   8 8    8 8e   8 8eeee8ee    88eee8e        8e 8e 8  8 eeeeee   8e  8   8  8   8 8   8 8   "       #
#          88 8e  8 8eeee   8e  8eee8 8e    8e       88 8e  8 8eee 8e    8e  8 eeeeee 88   8 88     8    88   8         88 88 8  8 88   8   88  8eee8e 8eee8 8e  8 8eeee       #
#          88 88  8    88   88  88  8 88    88       88 88  8 88   88    88  8 88   8 88   8 88     8    88   8     e   88 88 8  8 88   8   88  88   8 88  8 88  8    88       #
#          88 88  8 8ee88   88  88  8 88eee 88eee    88 88  8 88   88eee 88ee8 88   8 88eee8 88eeeee8    88eee8     8eee88 88 8  8 88   8   88  88   8 88  8 88  8 8ee88       #
#                                                                                                                                                                              #
################################################################################################################################################################################

echo "Please make sure, JDK is installed and JAVA_HOME env variable is set, going to give 5 seconds to cancel installation"
echo "Press Ctrl+c and set-up JAVA_HOME else jmxtrans start will fail"
sleep 5
INFLUX_HOST=$(hostname -f)
GRAFANA_HOST="grafana.shah.com"
GRAFANA_USER_PASSWORD="admin:admin"
INFLUXDB_DATABASE=jmxDB
INFLUX_DB_USER=jmx
INFLUX_DB_PASSWORD=jmx
INFLUXDB_PKG_VERSION=1.2.2
INFLUXDB_URL="https://dl.influxdata.com/influxdb/releases/influxdb"


if [ $PWD == "/opt/jmxtrans" ]; then
    echo "Downloading and installing Influxdb."
    if [ -f /etc/redhat-release ]; then
        wget ${INFLUXDB_URL}-${INFLUXDB_PKG_VERSION}.x86_64.rpm
        PKG="influxdb-${INFLUXDB_PKG_VERSION}.x86_64.rpm"
        if [ -f ${PKG} ]; then
            sudo yum -y localinstall ${PKG}
            echo "Taking backup of original influxdb config"
            sudo cp -avp /etc/influxdb/influxdb.conf /etc/influxdb/orig_influxdb.conf_$(date +'%Y%m%d%H%M')
            echo "Creating influxdb.conf from repo"
            sudo cat ./influxdb.conf > /etc/influxdb/influxdb.conf
            systemctl enable influxdb
            systemctl start influxdb
            echo "############# Waiting 10 seconds for influxDb initialization ############"
            sleep 10
            echo "########### Creating InfluxDB : ${INFLUXDB_DATABASE} ###############"
            curl -v -GSs -w "\n" http://localhost:8086/query --data-urlencode "q=CREATE DATABASE ${INFLUXDB_DATABASE} WITH DURATION 104w"
            echo "##########  Creating user in influxDB : #############"
            curl -v -GSs -w "\n" http://localhost:8086/query --data-urlencode "q=CREATE USER ${INFLUX_DB_USER} WITH PASSWORD '${INFLUX_DB_PASSWORD}' WITH ALL PRIVILEGES ;"
            echo "####### Updating access for DB: ####"
	    curl -v -GSs -w "\n" http://localhost:8086/query --data-urlencode "q=GRANT ALL ON ${INFLUXDB_DATABASE} to ${INFLUX_DB_USER}"
            echo "####### Showing access for DB: ####"
            curl -v -GSs -w "\n" http://localhost:8086/query --data-urlencode "q=show grants for ${INFLUX_DB_USER}" | python -m json.tool
            #echo "####### Adding Data Source in Grafana : ####"
            #curl -v "http://${GRAFANA_USER_PASSWORD}@${GRAFANA_HOST}:3000/api/datasources" -X POST -H 'Content-Type: application/json;charset=UTF-8' --data-binary '{"name":"influx_jmx","type":"influxdb","url":"http://${INFLUX_HOST}:8086","access":"proxy","isDefault":true,"database":"${INFLUXDB_DATABASE}","user":"${INFLUX_DB_USER}","password":"${INFLUX_DB_PASSWORD}"}'
            echo "####### Installing PiP from Srouce ####"
            echo "curl "https://bootstrap.pypa.io/get-pip.py" -o "get-pip.py" && python get-pip.py"
            #sudo yum -y install python2-pip
            rm -f ${PKG} get-pip.py
            echo "####### Installing PyYaml ####"
            sudo pip install PyYaml
        fi
    fi

    if [ -f /etc/lsb-release ]; then
        wget ${INFLUXDB_URL}_${INFLUXDB_PKG_VERSION}_amd64.deb -P tmp
        PKG="influxdb_${INFLUXDB_PKG_VERSION}_amd64.deb"
        if [ -f ${PKG} ]; then
            sudo dpkg -f ${PKG}
            echo "Taking backup of original influxdb config"
            sudo cp -avp /etc/influxdb/influxdb.conf /etc/influxdb/orig_influxdb.conf_$(date +'%Y%m%d%H%M')
            echo "Creating influxdb.conf from repo"
            sudo cat ./influxdb.conf > /etc/influxdb/influxdb.conf
            # systemctl enable influxdb
            # systemctl start influxdb
            service start influxdb
            sleep 10
            echo "Creating InfluxDB : ${INFLUXDB_DATABASE}"
            curl -v -GSs -w "\n" http://localhost:8086/query --data-urlencode "q=CREATE DATABASE ${INFLUXDB_DATABASE} WITH DURATION 104w"
            echo "Creating user in inflixDB.."
            curl -v -GSs -w "\n" http://localhost:8086/query --data-urlencode "q=CREATE USER ${INFLUX_DB_USER} WITH PASSWORD ${INFLUX_DB_PASSWORD} WITH ALL PRIVILEGES"
            echo "Updating access for DB: "
     	    curl -v -GSs -w "\n" http://localhost:8086/query --data-urlencode "q=GRANT ALL ON ${INFLUXDB_DATABASE} to ${INFLUX_DB_USER}"
            curl -v -GSs -w "\n" http://localhost:8086/query --data-urlencode "q=show grants for ${INFLUX_DB_USER}"
            curl 'http://${GRAFANA_USER_PASSWORD}@${GRAFANA_HOST}:8001/api/datasources' -X POST -H 'Content-Type: application/json;charset=UTF-8' --data-binary '{"name":"influx_jmx","type":"influxdb","url":"http://${INFLUX_HOST}:8086","access":"proxy","isDefault":true,"database":"${INFLUXDB_DATABASE}","user":"${INFLUX_DB_USER}","password":"${INFLUX_DB_PASSWORD}"}'
            sudp apt-get install -y python-pip
            sudo pip install PyYaml
        fi
    fi

    # Setting-up JMXTRANS:
    echo "Setting-up jmxtrans.."
    # git clone git@github.com:shahsaifi/jmxtrans.git /opt/jmxtrans
    if [ ${JAVA_HOME} ] ; then
        cd /opt/jmxtrans
        wget http://central.maven.org/maven2/org/jmxtrans/jmxtrans/264/jmxtrans-264-all.jar -P lib
        #ln -s lib/jmxtrans-264-all.jar lib/jmxtrans-all.jar
        git pull
        bin/jmxtrans.sh start
        echo -e "Configuration complete. You can log-in InfluxDB to see DB details and tail logs/jmxtrans.log for more details.\n"
    else
        echo "Install Java, set JAVA_HOME environment variable and re-run install.sh"
        exit 0
    fi
else
    echo "Please check-out code in /opt because it is hard-coded to set-up in OPT"
    exit 0
fi
