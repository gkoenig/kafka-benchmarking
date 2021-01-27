## Kafka benchmarking
Scripts to run a performance test against a Kafka cluster.  
Uses the kafka-producer-perf-test/kafka-consumer-perf-test scripts, which are included in Kafka deplyoments.  
In the OpenSource Kafka tgz, these scripts have a suffix ```.sh```, whereas in the Confluent distribution they don't....just be aware of that ;)

### Prerequisites
- a running Kafka cluster
- a host which has the Kafka client tools installed (scripts _kafka-topics_, _kafka-producer-perf-test_, _kafka-consumer-perf-test_, ...)
- tools _readlink_ and _tee_ installed
- ensure that your Kafka cluster has enough free space to maintain the data which is being created during the benchmark run(s)

### Single benchmark execution

#### Producer benchmark
A single benchmark execution for a Producer can be executed via calling ```benchmark-producer.sh``` directly, providing commandline parameters.  
Parameters are:
 | parameter | description | default |
 | --------- | ----------- | ------- |
 | -p\|--partitions _\<number\>_  | where _\<number\>_ is an int, telling how many partitions the benchmark topic shall have. **Only required if argument ```--enable-topic-management``` is specified** | 2
 | -r\|--replicas _\<number\>_  | where _\<number\>_ is an int, telling how many replicas the benchmark topic shall have. **Only required if argument ```--enable-topic-management``` is specified** | 2  
 |--enable-topic-management  |  setting this property will trigger the creation of the topic before the benchmark as well as the deletion of the topic afterwards. |
 | --num-records _\<number\>_ |  where _\<number\>_ specifies how many messages shall be created during the benchmark. | 100000  
 | --record-size _\<number\>_ |  where _\<number\>_ specifies how big (in bytes) each record shall be. | 1024  
 | --producer-props _<string\>_ | comma separated list of additional properties for the benchmark execution, like e.g. ```acks```, ```linger.ms```, ... | 'acks=1 compression.type=lz4'
 | --bootstrap-servers _\<string\>_ | comma separated list of \<host\>:\<port\> of your Kafka brokers |
 | --throughput _\<string\>_ | specifies the throughput to use during the benchmark run | -1
 | --topic _\<string\>_ |  specifies the topic to use for the benchmark execution. This topic **must** exist before you execute this script.  |
  
> Either  ```--enable-topic-management``` or ```--topic``` is required.  
> If you don't have a pre-existing topic and you don't want to manage the topic by yourself, just provide ```--enable-topic-management```. This will create the topic before the benchmark run, and delete it afterwards.  
> If you already have a topic you want to use for the benchmark execution, then provide its name via ```--topic```

The output of the benchmark execution will be stored within a .txt file in the same directory as the benchmark-producer.sh script.

### Batch of benchmark executions