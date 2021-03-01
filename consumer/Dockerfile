FROM confluentinc/cp-kafka:6.1.0

ENV KAFKA_BENCHMARK_CMD=/usr/bin/kafka-consumer-perf-test
ENV KAFKA_TOPICS_CMD=/usr/bin/kafka-topics

COPY ./scripts/* /tmp/
WORKDIR /tmp

#CMD [ "--bootstrap-server", "localhost:9091" ]
ENTRYPOINT [ "/tmp/benchmark-consumer.sh" ]