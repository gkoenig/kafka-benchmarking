#!/bin/bash

KAFKA_BENCHMARK_CMD=$(which kafka-consumer-perf-test.sh)
TIMEMS=$(date +%s)

##########
# parsing args
##########
OPTS=`getopt -o '' --long topic:,bootstrap-server:,broker-list:,messages:,fetch-max-wait-ms:,fetch-min-bytes:,fetch-size:,enable-auto-commit:,isolation-level:,output-to-file,verbose -- "$@"`
eval set -- "$OPTS"
while true ; do
    case "$1" in
        --topic)
            case "$2" in
                "") exit_out "option $1 requires an argument" 1 ; shift 2 ;;
                *) TOPICNAME=$2 ; shift 2 ;;
            esac ;;
        --bootstrap-server|--broker-list)
            case "$2" in
                "") exit_out "option $1 requires an argument" 1 ; shift 2 ;;
                *) BROKER_LIST=$2 ; shift 2 ;;
            esac ;;
        --messages)
            case "$2" in
                "") exit_out "option $1 requires an argument" 1 ; shift 2 ;;
                *) MESSAGES=$2 ; shift 2 ;;
            esac ;;
        --fetch-max-wait-ms)
            case "$2" in
                "") exit_out "option $1 requires an argument" 1 ; shift 2 ;;
                *) FETCH_MAX_WAIT_MS=$2 ; shift 2 ;;
            esac ;;
        --fetch-min-bytes)
            case "$2" in
                "") exit_out "option $1 requires an argument" 1 ; shift 2 ;;
                *) FETCH_MIN_BYTES=${2} ; shift 2 ;;
            esac ;;
        --fetch-size)
            case "$2" in
                "") exit_out "option $1 requires an argument" 1 ; shift 2 ;;
                *) FETCH_SIZE=${2} ; shift 2 ;;
            esac ;;
        --enable-auto-commit)
            case "$2" in
                "") exit_out "option $1 requires an argument" 1 ; shift 2 ;;
                *) ENABLE_AUTO_COMMIT=${2} ; shift 2 ;;
            esac ;;
        --isolation-level)
            case "$2" in
                "") exit_out "option $1 requires an argument" 1 ; shift 2 ;;
                *) ISOLATION_LEVEL=${2} ; shift 2 ;;
            esac ;;
        --output-to-file)
            OUTPUT_TO_FILE=1 ; shift  ;;
        --verbose)
            VERBOSE=1 ; shift  ;;        
        --) shift ; break ;;
        *) echo "Internal error!" ; exit 1 ;;
    esac
done

##########
# variables
##########

BROKER_LIST=${BROKER_LIST:=localhost:9091}
MESSAGES=${MESSAGES:=10000}
FETCH_SIZE=${FETCH_SIZE:=1048576}
FETCH_MAX_WAIT_MS=${FETCH_MAX_WAIT_MS:=500}
FETCH_MIN_BYTES=${FETCH_MIN_BYTES:=1}
ENABLE_AUTO_COMMIT=${ENABLE_AUTO_COMMIT:=true}
ISOLATION_LEVEL=${ISOLATION_LEVEL:=read_uncommitted}
VERBOSE=${VERBOSE:=0}

CONSUMER_CONFIG_FILE="$(dirname "$(readlink -f "$0")")"/_consumer.properties

function prepare_consumer_config {
  echo "fetch.min.bytes=$FETCH_MIN_BYTES" > $CONSUMER_CONFIG_FILE
  echo "fetch.max.wait.ms=$FETCH_MAX_WAIT_MS" >> $CONSUMER_CONFIG_FILE
  echo "enable.auto.commit=$ENABLE_AUTO_COMMIT" >> $CONSUMER_CONFIG_FILE
  echo "isolation.level=$ISOLATION_LEVEL" >> $CONSUMER_CONFIG_FILE
}

function run_benchmark {
  OUTPUT_FILENAME="Consumer-$TOPICNAME-$MESSAGES-$FETCH_SIZE".txt
  prepare_consumer_config 

  if [ "$OUTPUT_TO_FILE" == "1" ]
  then
    REDIRECT_OUTPUT='| tee -a "$(dirname "$(readlink -f "$0")")"/output/$OUTPUT_FILENAME'
  else
    REDIRECT_OUTPUT=""
  fi

	echo_out "starting consumer performance test"
	
  # first, print out the final cmd before executing it
  echo_out "Consumer perf test cmd:\n"	\
    $KAFKA_BENCHMARK_CMD --topic $TOPICNAME \
    --messages $MESSAGES \
    --fetch-size $FETCH_SIZE \
    --consumer.config ${CONSUMER_CONFIG_FILE} \
    --bootstrap-server $BROKER_LIST "\n" $REDIRECT_OUTPUT
  
  $KAFKA_BENCHMARK_CMD --topic $TOPICNAME \
    --messages $MESSAGES \
    --fetch-size $FETCH_SIZE \
    --consumer.config $CONSUMER_CONFIG_FILE \
    --bootstrap-server $BROKER_LIST  $REDIRECT_OUTPUT
  
}

function exit_out {
	if [ "$VERBOSE" == "1" ]
  then
    echo "=========="
    echo -e ${1}
    echo "=========="
  fi
	exit $2
}

function echo_out {
	if [ "$VERBOSE" == "1" ]
  then
    echo "***"
    echo -e ${1}
    echo "***"
  fi
}


#############
# start benchmark procedure
#############
[[ -z "$TOPICNAME" ]] && exit_out "\n!!!\n Topic name unknown. Parameter --topic <name> missing ?\n!!!\n" 1
run_benchmark
exit_out "performance test run finished." 0