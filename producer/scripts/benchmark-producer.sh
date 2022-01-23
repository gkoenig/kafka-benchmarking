#!/bin/bash

# 2021-01-26
# Author: G. Koenig
#
# Script: benchmark-producer.sh 
#
# Parameters:
# all parameters (see README.md) are optional, but you have to either specify "--enable-topic-management", so that the scripts creates and
# deletes the topic for the perf-test, or provide the topic to use via "--topic <name>"
#
# Environment variables:
# KAFKA_TOPICS_CMD => full path to executable for the kafka-topics command
# KAFKA_BENCHMARK_CMD => full path to executable for the kafka-producer-perf-test command
#
# Benchmark suite to run multiple performance tests for a producer, based on the properties specified in the "variables" section
# The final performance tests will be executed via script "benchmark-producer.sh"
#

##################
# helper functions
##################
function exit_out {
	echo -e "\n---\n${1}\n---\n"
  exit $2
}

function echo_out {
	TIMEUTC=$(date --utc +%F_%T)
	echo -e "## $TIMEUTC=>${1}" | tee -a $OUTPUT_FILENAME_TXT
}

##########
# variables
##########
RETENTION_MS=900000 # retention: 15min
PARTITION=2
REPLICATION=2
NUM_RECORDS=100000
RECORD_SIZE=1024
BOOTSTRAP_SERVERS=localhost:9091
THROUGHPUT=-1
PRODUCER_PROPS='acks=1 compression.type=none'
TOPIC_MANAGEMENT=0

##########
# parsing args
##########
OPTS=`getopt -o p:r: --long topic:,partitions:,replicas:,num-records:,record-size:,producer-props:,bootstrap-servers:,throughput:,enable-topic-management,producer-config: -- "$@"`
VALID_ARGUMENTS=$?
if [ "$VALID_ARGUMENTS" != "0" ]; then
  exit_out "invalid argument list" 1
fi

eval set -- "$OPTS"
while true ; do
    case "$1" in
        -p|--partitions)
            case "$2" in
                "") echo_out "option $1 requires an argument, using default value"
                    PARTITION=2
                    ;;
                *)  PARTITION=$2
                    shift 2 
                    ;;
            esac ;;
        -r|--replicas)
            case "$2" in
                "") echo_out "option $1 requires an argument, using default value"
                    REPLICATION=2
                    ;;
                *) REPLICATION=$2 ; shift 2 ;;
            esac ;;
        --num-records)
            case "$2" in
                "") echo_out "option $1 requires an argument, using default value"
                    NUM_RECORDS=100000
                    ;;
                *) NUM_RECORDS=$2 ; shift 2 ;;
            esac ;;
        --record-size)
            case "$2" in
                "") echo_out "option $1 requires an argument, using default value"
                    RECORD_SIZE=1024
                    ;;
                *) RECORD_SIZE=$2 ; shift 2 ;;
            esac ;;
        --producer-props)
            case "$2" in
                "") echo_out "option $1 requires an argument, using default value"
                    PRODUCER_PROPS="acks=1 compression.type=none"
                    ;;
                *) PRODUCER_PROPS=${2} ; shift 2 ;;
            esac ;;
        --producer-config)
            case "$2" in
                "") echo_out "option $1 requires an argument"
                    PRODUCER_CONFIG_OPT=" "                    
                    ;;
                *) PRODUCER_CONFIG_OPT=${2} ; shift 2 ;;
            esac ;;
        --bootstrap-servers)
            case "$2" in
                "") echo_out "option $1 requires an argument, using default value"
                    BOOTSTRAP_SERVERS="localhost:9091"
                    ;;
                *) BOOTSTRAP_SERVERS=${2} ; shift 2 ;;
            esac ;;
        --throughput)
            case "$2" in
                "") echo_out "option $1 requires an argument, using default value"
                    THROUGHPUT="-1"
                    ;;
                *) THROUGHPUT=${2} ; shift 2 ;;
            esac ;;
        --topic)
            case "$2" in
                "") echo_out "option $1 requires an argument"
                    TOPICNAME_OPT="missing"
                    ;;
                *) TOPICNAME_OPT=${2} ; shift 2 ;;
            esac ;;
        --) shift ; break ;;
        *) echo "Internal error!" ; exit 1 ;;
    esac
done

TIMEMS=$(date --utc +%s)

if [ -z "$TOPICNAME_OPT" ] 
then
  TOPICNAME="benchmark-r$REPLICATION-p$PARTITION-$TIMEMS"
  TOPICNAME_LIGHT="benchmark-r$REPLICATION-p$PARTITION"
  TOPIC_MANAGEMENT=1
else
  TOPICNAME=$TOPICNAME_OPT
  TOPICNAME_LIGHT=$TOPICNAME_OPT
fi

if [ ! -z "$PRODUCER_CONFIG_OPT" ]
then
  PRODUCER_CONFIG_FILE="--producer.config ${PRODUCER_CONFIG_OPT}"
  COMMAND_CONFIG_FILE="--command-config ${PRODUCER_CONFIG_OPT}"
else
  PRODUCER_CONFIG_FILE=""
  COMMAND_CONFIG_FILE=""
fi

# one plain output file per execution
OUTPUT_FILENAME_TXT="$(dirname "$(readlink -f "$0")")/output/benchmark-producer-$TIMEMS.txt"
# one csv formatted output file per day
OUTPUT_FILENAME_CSV="$(dirname "$(readlink -f "$0")")/output/benchmark-producer-$(date --utc +%F).csv"

##########
# functions
##########

function create_topic {
	echo -e "creating topic $TOPICNAME\n"
	$KAFKA_TOPICS_CMD --bootstrap-server $BOOTSTRAP_SERVERS \
		--replication-factor $REPLICATION \
		--partitions $PARTITION \
		--topic $TOPICNAME \
		--config retention.ms=$RETENTION_MS \
		--create $COMMAND_CONFIG_FILE
}

function delete_topic {
	echo -e "deleting topic $TOPICNAME \n"
	$KAFKA_TOPICS_CMD --bootstrap-server $BOOTSTRAP_SERVERS \
		--topic $TOPICNAME \
		--delete $COMMAND_CONFIG_FILE
}

function run_benchmark {
  _STRIPPED_PROD_PROPS="${PRODUCER_PROPS// /_}"
   
  echo_out "start-perf-test"

  echo_out "$KAFKA_BENCHMARK_CMD --topic $TOPICNAME \
    --num-records $NUM_RECORDS \
    --record-size $RECORD_SIZE \
    --throughput $THROUGHPUT \
    --producer-props ${PRODUCER_PROPS} bootstrap.servers=$BOOTSTRAP_SERVERS $PRODUCER_CONFIG_FILE"
  
  
  $KAFKA_BENCHMARK_CMD --topic $TOPICNAME \
  --num-records $NUM_RECORDS \
  --record-size $RECORD_SIZE \
  --throughput $THROUGHPUT \
   $PRODUCER_CONFIG_FILE \
  --producer-props ${PRODUCER_PROPS} bootstrap.servers=$BOOTSTRAP_SERVERS | tee -a $OUTPUT_FILENAME_TXT

  # comment the summary line, which is the last line of the output
  sed -i "$(cat $OUTPUT_FILENAME_TXT | wc -l)"' s/^/## /' $OUTPUT_FILENAME_TXT

  echo_out "end-perf-test"  
}

#########################################
# start benchmark procedure
#########################################

[[ -z "$KAFKA_TOPICS_CMD" ]] && KAFKA_TOPICS_CMD=$(which kafka-topics)
[[ -z "$KAFKA_BENCHMARK_CMD" ]] && KAFKA_BENCHMARK_CMD=$(which kafka-producer-perf-test)

[[ -z "$KAFKA_TOPICS_CMD" ]] && exit_out "missing the config to executable kafka-topics, env variable KAFKA_TOPICS_CMD not set." 1
[[ -z "$KAFKA_BENCHMARK_CMD" ]] && exit_out "missing the config to executable kafka-producer-perf-test, env varialbe KAFKA_BENCHMARK_CMD not set" 1

if [[ "$TOPIC_MANAGEMENT" -eq 1 ]]; then
	create_topic
fi
run_benchmark
if [[ "$TOPIC_MANAGEMENT" -eq 1 ]]; then
  delete_topic
fi

echo -e "\n---\nreformatting output file\n---\n"
OUTPUT_FILENAME_CSV__TEMP=$(echo $OUTPUT_FILENAME_CSV".temp")
[ ! -s ${OUTPUT_FILENAME_CSV} ] && echo -e "records_sent,records_per_sec,throughput,avg_latency,max_latency\n" > $OUTPUT_FILENAME_CSV
sed '/^[[:blank:]]*#/!s/[(),]//g' $OUTPUT_FILENAME_TXT > $OUTPUT_FILENAME_CSV__TEMP
awk '/^[[:blank:]]*#/{print $0;next}{print $1","$4","$6","$8","$12}' $OUTPUT_FILENAME_CSV__TEMP >> $OUTPUT_FILENAME_CSV
rm -f $OUTPUT_FILENAME_CSV__TEMP
echo -e "\n---\nFinished. Bye.\n---\n"


 

