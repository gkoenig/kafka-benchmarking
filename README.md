# TOC <!-- omit in toc -->

- [Kafka benchmarking](#kafka-benchmarking)
  - [Prerequisites](#prerequisites)
  - [Single benchmark execution](#single-benchmark-execution)
    - [Producer benchmark](#producer-benchmark)
    - [Consumer benchmark](#consumer-benchmark)
  
- [Docker](#docker)
  - [Usage](#usage)
    - [minimal example](#minimal-example)
    - [with authentication](#with-authentication)
    - [providing additinal parameters](#providing-more-parameters)
_______

# Kafka benchmarking

Scripts to run a performance test against a Kafka cluster.  
Uses the kafka-producer-perf-test/kafka-consumer-perf-test scripts, which are included in Kafka deplyoments.  
In the OpenSource Kafka tgz, these scripts have a suffix ```.sh```, whereas in the Confluent distribution they don't....just be aware of that ;)

* ```benchmark-producer.sh``` : execute one producer benchmark run with a dedicated set of properties
* ```benchmark-consumer.sh``` : execute one consumer benchmark run with a dedicated set of properties
* ```benchmark-suite-producer.sh``` : wrapper around _benchmark-producer.sh_ to execute multiple benchmark runs with varying property settings

The output of the benchmark execution will be stored within a .txt file in the same directory as the benchmark-*.sh scripts are, if parameter ```--output-to-file``` is specified only.
Repeating benchmark executions with the same properties will append the output to existing output file.

## Prerequisites

* a running Kafka cluster
* a host which has the Kafka client tools installed (scripts _kafka-topics_, _kafka-producer-perf-test_, _kafka-consumer-perf-test_, ...)
* tools _readlink_ and _tee_ installed
* ensure that your Kafka cluster has enough free space to maintain the data which is being created during the benchmark run(s)

## Single benchmark execution

### Producer benchmark

**NOTE**
> the scripts for running producer benchmark(s) you'll find in directory [**_producer/scripts_**](./producer/scripts/)


A single benchmark execution for a Producer can be executed via calling ```benchmark-producer.sh``` directly, providing commandline parameters. You can set environment variables pointing to the executables for ```kafka-topics```-command as well as for ```kafka-producer-perf-test```-command as shown below.  

* Environment variables
  
  | variable | description | example
  | -------- | ----------- | -------
  | KAFKA_TOPICS_CMD | how to execute the kafka-topics command (full path or relative) | /opt/kafka/bin/kafka-topics.sh
  | KAFKA_BENCHMARK_CMD | how to execute the kafka-producer-perf-test command (full path or relative) | /opt/kafka/bin/kafka-producer-perf-test-sh

* Parameters are:
  
  | parameter | description | default |
  | --------- | ----------- | ------- |
  | -p \| --partitions _\<number\>_  | where _\<number\>_ is an int, telling how many partitions the benchmark topic shall have. **Only required if you want the script manage the topic for the benchmark** | 2
  | -r \| --replicas _\<number\>_  | where _\<number\>_ is an int, telling how many replicas the benchmark topic shall have. **OOnly required if you want the script manage the topic for the benchmark** | 2  
  | --num-records _\<number\>_ |  where _\<number\>_ specifies how many messages shall be created during the benchmark. | 100000  
  | --record-size _\<number\>_ |  where _\<number\>_ specifies how big (in bytes) each record shall be. | 1024  
  | --producer-props _<string\>_ | list of additional properties for the benchmark execution, like e.g. ```acks```, ```linger.ms```, ... | 'acks=1 compression.type=none'
  | --bootstrap-servers _\<string\>_ | comma separated list of \<host\>:\<port\> of your Kafka brokers. This property is **mandatory** |
  | --throughput _\<string\>_ | specifies the throughput to use during the benchmark run | -1
  | --topic _\<string\>_ |  specifies the topic to use for the benchmark execution. This topic **must** exist before you execute this script.  |
  | --producer-config _\<config-file\>_ | config-file to provide additional attributes to connect to broker(s), mainly **SSL** & **authentication** |

* Output
  
  The script generates 2 output files  
  * .txt: **one file per execution**, this file includes all messages printed during the performance test execution
  * .csv: **one file per day**, this file includes the pure metrics, comma separated, and commented the start-/finish-time as well as the parameters for the test execution
  

**NOTE**

> Topic management for the execution:    
> If you don't have a pre-existing topic and you don't want to manage the topic by yourself, just **omit** property ```--topic```. 
> By that the script will create a topic before the benchmark run, and delete it afterwards.  
> If you already have a topic you want to use for the benchmark execution, then provide its name via ```--topic```

---
**Usage examples**

* run benchmark with minimal parameters, use the existing topic _bench-topic_ on local Kafka broker with port 9091:
  
  ```bash
  ./benchmark-producer.sh --bootstrap-servers localhost:9091 --topic bench-topic
  ```

* run benchmark with minimal parameters, let the script manage the topic on local Kafka broker with port 9091:
  
  ```bash
  ./benchmark-producer.sh --bootstrap-servers localhost:9091 --partitions 5 --replicas 2
  ```

* tuning for **Throughput**:
  
  ```bash
  ./benchmark-producer.sh --bootstrap-servers localhost:9091 --partitions 3 --replicas 2 --record-size 1024 --num-records 200000 --producer-props 'acks=1 compression.type=lz4 batch.size=100000 linger.ms=50'
  ```

* tuning for **Latency**:
  
  ```bash
  ./benchmark-producer.sh --bootstrap-servers localhost:9091 --partitions 3 --replicas 2 --record-size 1024 --num-records 200000 --producer-props 'acks=1 compression.type=lz4 batch.size=10000 linger.ms=0'
  ```

* tuning for **Durability**
  
  ```bash
  ./benchmark-producer.sh --bootstrap-servers localhost:9091 --partitions 3 --replicas 2 --record-size 1024 --num-records 200000 --producer-props 'acks=1 compression.type=lz4 batch.size=10000 linger.ms=0'
  ```

* run benchmark with minimal parameters, let the script manage the topic on local Kafka broker with port 9092 and provide producer.config including SASL_PLAINTEXT info:
  
  ```bash
  ./benchmark-producer.sh --bootstrap-servers localhost:9091 --partitions 5 --replicas 2 --producer-config ./sample-producer-sasl.config
  ```
  where content of _sample-producer-sasl.config_ for a PLAINTEXT SASL auth (user + password) can be:  
  ```
  security.protocol=SASL_PLAINTEXT
  sasl.mechanism=PLAIN
  sasl.jaas.config=org.apache.kafka.common.security.plain.PlainLoginModule required username="admin" password="admin-secret";
  ```

---

### Consumer benchmark

A single benchmark execution for a Consumer can be executed via calling ```benchmark-consumer.sh``` directly, providing commandline parameters.  
Parameters are:
 | parameter | description | default |
 | --------- | ----------- | ------- |
 | --topic _\<string\>_ |  specifies the topic to use for the benchmark execution. This property is **mandatory** |
 | --bootstrap-server _\<string\>_ | comma separated list of \<host\>:\<port\> of your Kafka brokers.  | localhost:9091
 | --messages _\<number\>_ |  where _\<number\>_ specifies how many messages shall be consumed during the benchmark. | 10000 
 | --fetch-max-wait-ms _\<number\>_  | specifies the timeout the server waits to collect _fetch-min-bytes_ to return to the client ([official doc](https://kafka.apache.org/documentation/#consumerconfigs_fetch.max.wait.ms)) | 500
 | --fetch-min-bytes _\<number\>_  | The minimum amount of data the server should return for a fetch request. Value of "1" means _do not wait and send data as soon as there is some_ ([official doc](https://kafka.apache.org/documentation/#consumerconfigs_fetch.min.bytes)) | 1  
 | --fetch-size  |  The amount of data to fetch in a single request | 1048576
 | --enable-auto-commit _\<number\>_ |  If true the consumer's offset will be periodically committed in the background | true  
 | --isolation-level _<string\>_ | specifies how transactional message are being read ([official doc](https://kafka.apache.org/documentation/#consumerconfigs_isolation.level)) | read_uncommitted
 | --output-to-file | if provided, the console output will be stored to a text file, too |
 | --verbose | if specified, additional text output will be printed to the terminal |
  
**Usage examples**

* run consumer benchmark with minimal arguments, using kafka broker on localhost:9091 and topicname _my-benchmark-topic_:
  
  ```./benchmark-consumer.sh --topic my-benchmark-topic

* tuning for **Throughput**:

  ```./benchmark-consumer.sh --topic my-benchmark-topic --fetch-min-bytes 100000

* tuning for **Latency**:

  ```./benchmark-consumer.sh --topic my-benchmark-topic --fetch-size 25000 --fetch-max-wait-ms 100

## Batch of benchmark executions

Script ```benchmark-suite-producer.sh``` is just a wrapper around _benchmark-producer.sh_ to run a variety of performance test runs against your Kafka cluster. It loops over the properties you want to change between test runs and calls _benchmark-producer.sh_ once for each single combination of properties.  
The properties, which are possible to iterate over, you'll find within ```benchmark-suite-producer.sh```, section  **variables**.  

The only **mandatory** parameter is: ```--bootstrap-servers``` , the bootstrap server(s) to connect to as comma separated list ```--bootstrap-servers <host>:<port>```

Parameters to adjust for your UseCase, in ```benchmark-suite-producer.sh```, are:

| Parameter | Description | Example
| --------- | ----------- | -------
PARTITIONS | space separated list of number of partitions for the benchmark topic | PARTITIONS="2 10"
REPLICAS | space separated list of number of replicas for the benchmark topic | REPLICAS="2"
NUM_RECORDS | space separated list of number of records to produce | NUM_RECORDS="100000"
RECORD_SIZES | space separated list of record sizes | RECORD_SIZES="1024 10240"
THROUGHPUT | space separated list of desired throughput limits, "-1" means: no limit, full speed | THROUGHPUT="-1"
ACKS | space separated list of values for the producer property "acks", valid values "0 1 -1" | ACKS="0 -1"
COMPRESSION | compression type to use, e.g. "none","lz4",... | COMPRESSION="none"
LINGER_MS | space separated list of desired values for "linger.ms" kafka property | LINGER_MS="0"
BATCH_SIZE | space separated list of desired values for "batch.size" kafka property, "0": disable batching | BATCH_SIZE="10000"

# Docker

to be able to run the benchmarks within a container, you can use the provided Dockerfile to create such a container.  
Alternatively you'll find prebuilt docker container on [gkoenig/kafka-producer-benchmark](https://hub.docker.com/repository/docker/gkoenig/kafka-producer-benchmark) to execute the producer performance test.  

**NOTE**

> - you have to mount a local directory to the container path _/tmp/output_ so that you can save the output files from the benchmark run on your local workstation.
> - ensure that the host directory (which you mount into the container) has permissions, so that the container can write file(s) to it

## Usage

To be able to store the output files from the benchmark run on your local workstation/laptop, create a local dir and mount it into the container. Otherwise you won't be able to access the files after the benchmark run is finished.

### minimal example

the following example shows a scenario with minimal parameters. It will run a producer benchmark, connecting to Kafka (unauthenticated) on port 9091 on IP _000.111.222.333_ **you obviously have to provide you IP address of your Kafka broker here !!!**
```
mkdir ./output
chmod 777 ./output
docker run  -v ./output/:/tmp/output gkoenig/kafka-producer-benchmark:0.1 --bootstrap-servers 000.111.222.333:9091
```

### with authentication

if you have a kafka cluster with authentication, then you can provide additional parameters as you would do on a _plain_ execution of benchmark-producer.sh script, e.g. if your brokers listen on port 9092 for SASL_PLAINTEXT authentication, then specify the port and provide additional producer-config as below (**you obviously have to provide you IP address of your Kafka broker here !!!**):  

```
git clone git@github.com:gkoenig/kafka-benchmarking.git
cd scripts
chmod 777 ./output
docker run  -v ./output/:/tmp/output gkoenig/kafka-producer-benchmark:0.1 --bootstrap-servers 000.111.222.333:9092 --producer-config sample-producer-sasl.config
```

### providing more parameters

You can provide the same list of parameters as if you execute the producer-benchmark outside of Docker containers, means plain on the terminal.
Detailled description of parameters can be found [here](https://github.com/gkoenig/kafka-benchmarking#producer-benchmark)

```
git clone git@github.com:gkoenig/kafka-benchmarking.git
cd scripts
chmod 777 ./output
docker run  -v ./output/:/tmp/output gkoenig/kafka-producer-benchmark:0.1 --bootstrap-servers 000.111.222.333:9092 --producer-config sample-producer-sasl.config --num-records 2000000 --compression lz4
```