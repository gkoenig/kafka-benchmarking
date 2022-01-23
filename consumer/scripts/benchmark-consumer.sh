#!/bin/bash

TIMEMS=$(date +%s)

##########
# parsing args
##########
OPTS=`getopt -o '' --long topic:,bootstrap-servers:,broker-list:,messages:,consumer-config:,consumer.config:,fetch-max-wait-ms:,fetch-min-bytes:,fetch-size:,enable-auto-commit:,isolation-level:,group-id:,verbose -- "$@"`
eval set -- "$OPTS"
while true ; do
    case "$1" in
        --topic)
            case "$2" in
                "") exit_out "option $1 requires an argument" 1 ; shift 2 ;;
                *) TOPICNAME=$2 ; shift 2 ;;
            esac ;;
        --bootstrap-servers|--broker-list)
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
        --consumer-config|consumer.config)
            case "$2" in
                "") echo_out "option $1 requires an argument"
                    CONSUMER_CONFIG_OPT=" "                    
                    ;;
                *) CONSUMER_CONFIG_OPT=${2} ; shift 2 ;;
            esac ;;
        --group-id)
            case "$2" in
                "") echo_out "option $1 requires an argument"
                    CONSUMER_GROUP_ID=" "                    
                    ;;
                *) CONSUMER_GROUP_ID=${2} ; shift 2 ;;
            esac ;;        
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
CONSUMER_GROUP_ID=${CONSUMER_GROUP_ID:=consumer-benchmark}
VERBOSE=${VERBOSE:=0}

CONSUMER_CONFIG_FILE="$(dirname "$(readlink -f "$0")")"/_consumer.properties

function prepare_consumer_config {
  # start with an empty config file
  echo "" > $CONSUMER_CONFIG_FILE
  
  if [ -f $CONSUMER_CONFIG_OPT ]
  then
    cat $CONSUMER_CONFIG_OPT >> $CONSUMER_CONFIG_FILE
  fi
  echo -e "\nfetch.min.bytes=$FETCH_MIN_BYTES" >> $CONSUMER_CONFIG_FILE
  echo "fetch.max.wait.ms=$FETCH_MAX_WAIT_MS" >> $CONSUMER_CONFIG_FILE
  echo "enable.auto.commit=$ENABLE_AUTO_COMMIT" >> $CONSUMER_CONFIG_FILE
  echo "isolation.level=$ISOLATION_LEVEL" >> $CONSUMER_CONFIG_FILE
}

function run_benchmark {
  OUTPUT_FILENAME="Consumer-$TOPICNAME-$MESSAGES-$FETCH_SIZE".txt
  prepare_consumer_config 

  echo_out "starting consumer performance test"
	
  # first, print out the final cmd before executing it
  echo -e "Consumer perf test cmd:\n"	\
    $KAFKA_BENCHMARK_CMD --topic $TOPICNAME \
    --messages $MESSAGES \
    --fetch-size $FETCH_SIZE \
    --consumer.config ${CONSUMER_CONFIG_FILE} \
    --group ${CONSUMER_GROUP_ID} \
    --bootstrap-server $BROKER_LIST "\n" 
  
  $KAFKA_BENCHMARK_CMD --topic $TOPICNAME \
    --messages $MESSAGES \
    --fetch-size $FETCH_SIZE \
    --consumer.config $CONSUMER_CONFIG_FILE \
    --group ${CONSUMER_GROUP_ID} \
    --bootstrap-server $BROKER_LIST  $REDIRECT_OUTPUT | tee -a "$(dirname "$(readlink -f "$0")")"/output/$OUTPUT_FILENAME
  
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
[[ -z "$KAFKA_BENCHMARK_CMD" ]] && KAFKA_BENCHMARK_CMD=$(which kafka-consumer-perf-test)
[[ -z "$KAFKA_BENCHMARK_CMD" ]] && exit_out "missing the config to executable kafka-consumer-perf-test, env varialbe KAFKA_BENCHMARK_CMD not set" 1

if [ -z "$TOPICNAME" ] 
then
  VERBOSE=1; 
  exit_out "\n!!!\n Topic name unknown. Parameter --topic <name> missing ?\n!!!\n" 1
fi
run_benchmark
exit_out "performance test run finished." 0