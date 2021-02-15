#!/bin/bash

# 2021-01-26
# Author: G. Koenig
#
# Script: benchmark-suite-producer.sh <bootstrap-servers>
# Parameter: <bootstrap-servers> => the Kafka broker(s) to connect to as comma separated list <host>:<port>[,<host>:<port>]
# Benchmark suite to run multiple performance tests for a producer, based on the properties specified in the "variables" section
# The final performance tests will be executed via script "benchmark-producer.sh"
#
# Before running this script, verify and adapt the properties in section "variables" according to your needs.
# This suite only works on topics which are managed by the script itself (see property "--enable-topic-management" to call 
# the underlying script "benchmark-producer.sh") !!

###############
# parsing args
###############
OPTS=`getopt -o b: -l bootstrap-servers:,producer-config: -- "$@"`
VALID_ARGUMENTS=$?
if [ "$VALID_ARGUMENTS" != "0" ]; then
  exit_out "invalid argument list" 1
fi

eval set -- "$OPTS"
while true ; do
  case "$1" in
      -b|--bootstrap-servers)
          case "$2" in
              "") echo "argument missing for option $1 " 
                  ;;
              *)  BOOTSTRAP_SERVERS_OPT=${2} 
                  shift 2 
                  ;;
          esac ;;
      --producer-config)
          case "$2" in
              "") echo "option $1 requires an argument"
                  PRODUCER_CONFIG_OPT=" "                    
                  ;;
              *) PRODUCER_CONFIG_OPT=${2} ; shift 2 ;;
          esac ;;
        --) shift ; break ;;
      *) echo "Internal error!" ; exit 1 ;;
  esac
done

############
# variables
############

# space separated list of number of partitions for the benchmark topic
PARTITIONS="2"                   
# space separated list of number of replicas for the benchmark topic
REPLICAS="2"
# space separated list of number of records to produce    
NUM_RECORDS="200000"
# space separated list of record sizes 
RECORD_SIZES="1024"
# space separated list of desired throughput limits, "-1" means: no limit, full speed
THROUGHPUT="-1"
# space separated list of values for the producer property "acks", valid values "0 1 -1"
ACKS="1"
# compression type to use, e.g. "lz4"
COMPRESSION="none"
# space separated list of desired values for "linger.ms" kafka property
LINGER_MS="0"
# space separated list of desired values for "batch.size" kafka property, "0": disable batching
BATCH_SIZE="16384"
# the bootstrap server(s) to connect to as comma separated list <host>:<port>
BOOTSTRAP_SERVERS="${BOOTSTRAP_SERVERS_OPT:=localhost:9091}"

if [ ! -z "$PRODUCER_CONFIG_OPT" ]
then
  PRODUCER_CONFIG_FILE="${PRODUCER_CONFIG_OPT}"
else
  PRODUCER_CONFIG_FILE=""
fi

BENCHMARK_SCRIPT="$(dirname "$(readlink -f "$0")")/benchmark-producer.sh"

########################
# start benchmark suite
########################
echo -e "\n******\nstarting benchmark suite at $(date)\n***\n"
for _partitions in ${PARTITIONS}; do
  for _replicas in ${REPLICAS}; do 
    for _numrecords in ${NUM_RECORDS}; do
      for _recordsize in ${RECORD_SIZES}; do
        for _acks in ${ACKS}; do
          for _compression in ${COMPRESSION}; do        
            for _lingerms in ${LINGER_MS}; do
              for _batchsize in ${BATCH_SIZE}; do
                _producerprops="acks=${_acks} compression=${_compression} linger.ms=${_lingerms} batch.size=${_batchsize}"
                $BENCHMARK_SCRIPT --partitions $_partitions \
                  --replicas $_replicas \
                  --enable-topic-management \
                  --num-records $_numrecords \
                  --record-size $_recordsize \
                  --producer-props $_producerprops \
                  --throughput $THROUGHPUT \
                  --producer-config $PRODUCER_CONFIG_FILE \
                  --bootstrap-servers $BOOTSTRAP_SERVERS
              done # closing _batchsize
            done # closing _lingerms
          done # closing _compression
        done # closing _acks
      done # closing _record-sizes
    done # closing _num-records
  done # closing _replicas
done # closing _partitions

echo -e "\n***\nfinished benchmark suite at $(date)\n******\n"
