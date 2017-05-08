**This Repo Contains JMXTrans and InfluxDB related content**

## JMXTrans:

> jmxtrans is a tool which allows you to connect to any number of Java Virtual Machines (JVMs) and query them for their attributes without writing a single line of Java code. The attributes are exported from the JVM via Java Management Extensions (JMX). Most Java applications have made their statistics available via this protocol and it is possible to add this to any codebase without a lot of effort. If you use the SpringFramework for your code, it can be as easy as just adding a couple of annotations to a Java class file.

#### High Level Architecture:
```


            Client                                       
          +---------+                    +--------------+              
          |  JVM    |                    |              |              +-------------+               +-------------+  
          |  Tomcat |                    |              |              |             |               |             |
          |  Solr   |    queries         |   jmxtrans   |              |             |               |             |  
          |  AMQ    +------------------->|   server     +------------->|  influxDB   |+------------->|   Grafana   |
          |  Camel  |                    |              |              |             |               |             |  
          |  Kafka  |                    |              |              |             |               |             |
          |  Sys    |                    |              |              +-------------+               +-------------+  
          +---------+                    +--------------+                                            

 ```

 > For more info : https://github.com/jmxtrans/jmxtrans/wiki

### Influxdb:

> InfluxDB is an open-source time series database developed by InfluxData. It is written in Go and optimized for fast, high-availability storage and retrieval of time series data in fields such as operations monitoring, application metrics, Internet of Things sensor data, and real-time analytics.

> For more info : https://docs.influxdata.com/influxdb/v1.2/

## Installation Steps, Manually:

```bash
influxDB : 1.2.2
jmxtrans : 264
Grafana  : 4.1.2
 ```

Check-out jmxtrans repo:
```bash
git clone git@github.com:shahsaifi/jmxtrans.git /opt/jmxtrans

cd /opt/jmxtrans
```

#### Repo Tree structure:
```bash
jmxtrans
├── bin
│   ├── jmxtrans.sh
│   └── yaml2json.py
├── conf.d
│   ├── config.yaml
│   ├── prod_host_set_1.json
│   └── prod_host_set_2.json
├── lib
│   ├── jmxtrans-264-all.jar
│   └── jmxtrans-all.jar -> jmxtrans-264-all.jar
├── logs
│   └── jmxtrans.log
└── README.md
```


#### influxdb:

1. Download & Install influxDB:
```bash
wget https://dl.influxdata.com/influxdb/releases/influxdb-1.2.2.x86_64.rpm
sudo yum localinstall influxdb-1.2.2.x86_64.rpm
```

2. Update `/etc/influxdb/influxdb.conf` with [influxdb.conf](https://github.com/shahsaifi/jmxtrans) in this repo:
```bash
sudo cp -avp /etc/influxdb/influxdb.conf /etc/influxdb/orig_influxdb.conf_$(date +'%Y%m%d%H%M')
cat influxdb.conf > /etc/influxdb/influxdb.conf
```

3. Start & Enable influxDB:
```bash
systemctl enable influxdb
systemctl start influxdb
```

4. Check influxDB status:
```bash
systemctl status influxdb
```

5. Login to influxdb:
```bash
[root@jmxtrans1 ~]# influx
Connected to http://localhost:8086 version 1.2.2
InfluxDB shell version: 1.2.2
>
```

6. Create jmx database with 52 weeks retention:
```bash
> create database jmx with duration 52w
```

7. Check retention:
```bash
> show retention policies on jmx
```

8. Create db user:
```bash
> CREATE USER jmx WITH PASSWORD 'jmx' WITH ALL PRIVILEGES ;
```

9. Verify User:
```bash
> show users
```

10. Grant full privileges on db:
```bash
GRANT ALL ON jmxDB to jmx
```

11. Verify privileges:
```bash
> show grants for jmx
```


### jmxtrans

> Hosts are distinguished based on the metrics and YAML generates multiple giant JSON files so it is highly recommended to use config.yaml to update/modify object definitions. DO NOT FORGET TO CHECK-IN CHANGES TO REPO..

1. Set `JAVA_HOME` environment variable after installing JDK.
```bash
cd ; wget --no-cookies --no-check-certificate --header "Cookie: gpw_e24=http%3A%2F%2Fwww.oracle.com%2F; oraclelicense=accept-securebackup-cookie" "http://download.oracle.com/otn-pub/java/jdk/8u60-b27/jdk-8u60-linux-x64.rpm"
sudo yum localinstall jdk-8u60-linux-x64.rpm
rm ~/jdk-8u60-linux-x64.rpm
echo "export JAVA_HOME=/usr/java/jdk1.8.0_121" >> /etc/environment
```

2. change path to `/opt/jmxtrans`
```bash
cd /opt/jmxtrans
```

3. Fetch jmxtrans jar:
```bash
wget http://central.maven.org/maven2/org/jmxtrans/jmxtrans/264/jmxtrans-264-all.jar -P lib
```

4. Verify jar in `lib` dir:
```bash
[root@jmxtrans1 jmxtrans]# pwd
/opt/jmxtrans

[root@jmxtrans1 jmxtrans]# ls -l lib/
total 32600
-rw-r--r-- 1 root root 33380575 Mar 30 04:55 jmxtrans-264-all.jar
lrwxrwxrwx 1 root root       20 Apr 21 00:58 jmxtrans-all.jar -> jmxtrans-264-all.jar
```

5. Update repo content:
```bash
git pull origin <staging/prod>
```

6. start jmxtrans:
```bash
/opt/jmxtrans/bin/jmxtrans.sh start
```

7. tail logs to see progress:
```bash
tail -f /opt/jmxtrans/logs/jmxtrans.log
```

8. Once you are confirmed, jmxtrans is running with current configs placed `conf.d` with logs, move further to set-up Grafana UI dashboard to add data-source.

## Installation Steps, with `install.sh`:

1. After check-out this repo in `/opt`
```bash
[root@jmxtrans1 jmxtrans]# pwd
/opt/jmxtrans
```
2. Run `install.sh`:
```bash
[root@jmxtrans1 /opt/jmxtrans]# ./install.sh
```

### Adding/updating jmx metrics :

1. Refer `jmxtrans/conf.d/config.yaml` which contains thoroughly commented YAML definitions about metrics e.g.:
```json
- name: classloading
  obj: "java.lang:type=ClassLoading"
  resultAlias: "classloading"
  typeNames:
      - type
  attr:
      - "TotalLoadedClassCount"
      - "LoadedClassCount"
      - "UnloadedClassCount"
```
2. Read comments carefully to understand the parameters and connect to `jmxconsole` with host port to relate objects with attributes:
```bash
jconsole dc1-host01.shah.int:1099
```

3. It is always better to validate YAML with linter like `yamllint` (Warnings can be ignored):
```bash
⇒ pip install yamllint

⇒  yamllint conf.d/config.yaml
conf.d/config.yaml
  85:30     warning  too few spaces before comment  (comments)
  85:31     warning  missing starting space in comment  (comments)
  86:33     warning  too few spaces before comment  (comments)
```
4. After modifying `config.yaml` and linting, re-generate JSON files with:
```bash
[root@jmxtrans1 conf.d]# pwd
/opt/jmxtrans/conf.d

[root@jmxtrans1 conf.d]# ../bin/yaml2json.py --file config.yaml
```
5. check-in updates to git:
```bash
git commit -a -m 'updating classloading object'
git push origin <branch_name>
```
6. Restart jmxtrans on server:
```bash
/opt/jmxtrans/bin/jmxtrans.sh restart
```
7. Tail log file:
```bash
tail -f /opt/jmxtrans/logs/jmxtrans.log
```
8. Log-in to influxDB or use rest API to verify new metrics data:
```bash
# curl -v -G 'http://jmxtrans1.shah.com:8086/query?pretty=true' --data-urlencode "db=jmxDB" --data-urlencode "q=select * from "amq" where "hostname" = 'dc1-host01_shah_com' limit 1"
* About to connect() to jmxtrans1.shah.com port 8086 (#0)
*   Trying 10.20.23.74...
* Connected to jmxtrans1.shah.com (10.20.23.74) port 8086 (#0)
> GET /query?pretty=true&db=jmxDB&q=select%20%2A%20from%20amq%20where%20hostname%20%3D%20%27dc1-host01_shah_com%27%20limit%201 HTTP/1.1
> User-Agent: curl/7.29.0
> Host: jmxtrans1.shah.com:8086
> Accept: */*
>
< HTTP/1.1 200 OK
< Connection: close
< Content-Type: application/json
< Request-Id: f4507314-28fb-11e7-badb-000000000000
< X-Influxdb-Version: 1.2.2
< Date: Mon, 24 Apr 2017 14:40:25 GMT
< Transfer-Encoding: chunked
<
{
    "results": [
        {
            "statement_id": 0,
            "series": [
                {
                    "name": "amq",
                    "columns": [
                        "time",
                        "AverageEnqueueTime",
                        "ConsumerCount",
                        "DequeueCount",
                        "DispatchCount",
                        "EnqueueCount",
                        "MemoryPercentUsage",
                        "ProducerCount",
                        "QueueSize",
                        "_jmx_port",
                        "attributeName",
                        "className",
                        "hostname",
                        "objDomain",
                        "typeName"
                    ],
                    "values": [
                        [
                            "2017-04-21T14:21:11.091Z",
                            null,
                            null,
                            0,
                            null,
                            null,
                            null,
                            null,
                            null,
                            1099,
                            "DequeueCount",
                            "org.apache.activemq.broker.jmx.QueueView",
                            "dc1-host01_shah_com",
                            "org.apache.activemq",
                            "BrokerName=localhost,Type=Queue,Destination=com.apache.fake.queue"
                        ]
                    ]
                }
            ]
        }
    ]
}
* Closing connection 0
```
