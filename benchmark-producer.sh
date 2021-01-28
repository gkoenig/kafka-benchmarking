#!/bin/bash

KAFKA_TOPICS_CMD=$(which kafka-topics.sh)
KAFKA_BENCHMARK_CMD=$(which kafka-producer-perf-test.sh)

##########
# parsing args
##########
OPTS=`getopt -o p:r: --long topic:,partitions:,replicas:,num-records:,record-size:,producer-props:,bootstrap-servers:,throughput:,enable-topic-management -- "$@"`
eval set -- "$OPTS"
while true ; do
    case "$1" in
        -p|--partitions)
            case "$2" in
                "") exit_out "option $1 requires an argument" 1 ; shift 2 ;;
                *) PARTITION_OPT=$2 ; shift 2 ;;
            esac ;;
        -r|--replicas)
            case "$2" in
                "") exit_out "option $1 requires an argument" 1 ; shift 2 ;;
                *) REPLICATION_OPT=$2 ; shift 2 ;;
            esac ;;
        --num-records)
            case "$2" in
                "") exit_out "option $1 requires an argument" 1 ; shift 2 ;;
                *) NUM_RECORDS_OPT=$2 ; shift 2 ;;
            esac ;;
        --record-size)
            case "$2" in
                "") exit_out "option $1 requires an argument" 1 ; shift 2 ;;
                *) RECORD_SIZE_OPT=$2 ; shift 2 ;;
            esac ;;
        --producer-props)
            case "$2" in
                "") exit_out "option $1 requires an argument" 1 ; shift 2 ;;
                *) PRODUCER_PROPS_OPT=${2} ; shift 2 ;;
            esac ;;
        --bootstrap-servers)
            case "$2" in
                "") exit_out "option $1 requires an argument" 1 ; shift 2 ;;
                *) BOOTSTRAP_SERVERS_OPT=${2} ; shift 2 ;;
            esac ;;
        --throughput)
            case "$2" in
                "") exit_out "option $1 requires an argument" 1 ; shift 2 ;;
                *) THROUGHPUT_OPT=${2} ; shift 2 ;;
            esac ;;
        --topic)
            case "$2" in
                "") exit_out "option $1 requires an argument" 1 ; shift 2 ;;
                *) TOPICNAME_OPT=${2} ; shift 2 ;;
            esac ;;
        --enable-topic-management)
            TOPIC_MANAGEMENT_OPT=1 ; shift  ;;
        --) shift ; break ;;
        *) echo "Internal error!" ; exit 1 ;;
    esac
done



##########
# variables
##########
PARTITION="${PARTITION_OPT:=2}"
REPLICATION="${REPLICATION_OPT:=2}"
RETENTION_MS=900000 # retention: 15min
TOPICNAME="${TOPICNAME_OPT:=benchmark-r$REPLICATION-p$PARTITION}"
NUM_RECORDS=${NUM_RECORDS_OPT:=100000}
RECORD_SIZE=${RECORD_SIZE_OPT:=1024}
BOOTSTRAP_SERVERS="${BOOTSTRAP_SERVERS_OPT:=localhost:9091}"
THROUGHPUT=${THROUGHPUT_OPT:=-1}
PRODUCER_PROPS=${PRODUCER_PROPS_OPT:='acks=1 compression.type=lz4'}
TOPIC_MANAGEMENT=${TOPIC_MANAGEMENT_OPT:=0}

##########
# functions
##########

function create_topic {
	echo_out "creating topic $TOPICNAME"
	$KAFKA_TOPICS_CMD --bootstrap-server $BOOTSTRAP_SERVERS \
		--replication-factor $REPLICATION \
		--partitions $PARTITION \
		--topic $TOPICNAME \
		--config retention.ms=$RETENTION_MS \
		--create
}

function delete_topic {
	echo_out "deleting topic $TOPICNAME"
	$KAFKA_TOPICS_CMD --bootstrap-server $BOOTSTRAP_SERVERS \
		--topic $TOPICNAME \
		--delete
}

function run_benchmark {
    _STRIPPED_PROD_PROPS="${PRODUCER_PROPS// /_}"
    OUTPUT_FILENAME="$TOPICNAME-$NUM_RECORDS-$RECORD_SIZE-$_STRIPPED_PROD_PROPS".txt

	echo_out "starting producer performance test"
	
    #echo 	$KAFKA_BENCHMARK_CMD --topic $TOPICNAME \
	#	--num-records $NUM_RECORDS \
	#	--record-size $RECORD_SIZE \
	#	--throughput $THROUGHPUT \
	#	--producer-props ${PRODUCER_PROPS} bootstrap.servers=$BOOTSTRAP_SERVERS

    echo -e "\n******\n* starting benchmark at: $(date)\n" >> $OUTPUT_FILENAME
	
    $KAFKA_BENCHMARK_CMD --topic $TOPICNAME \
		--num-records $NUM_RECORDS \
		--record-size $RECORD_SIZE \
		--throughput $THROUGHPUT \
		--producer-props ${PRODUCER_PROPS} bootstrap.servers=$BOOTSTRAP_SERVERS | tee -a "$(dirname "$(readlink -f "$0")")"/$OUTPUT_FILENAME
    
    echo -e "\n* finished benchmark at: $(date)\n******\n" >> $OUTPUT_FILENAME
	
}

function finish {
	echo_out "Benchmark run finished."
	exit
}

function exit_out {
	echo "=========="
	echo $1
	echo "=========="
	exit $2
}

function echo_out {
	echo "***"
	echo $1
	echo "***"
}

#############
# start benchmark procedure
#############
if [[ "$TOPIC_MANAGEMENT" -eq 1 ]]; then
	create_topic
fi
run_benchmark
if [[ "$TOPIC_MANAGEMENT" -eq 1 ]]; then
	delete_topic
fi
finish 

