FROM apache/activemq-classic:latest

RUN apt-get update && apt-get install -y curl && rm -rf /var/lib/apt/lists/*

RUN curl -L https://repo1.maven.org/maven2/io/prometheus/jmx/jmx_prometheus_javaagent/0.20.0/jmx_prometheus_javaagent-0.20.0.jar \
    -o /opt/jmx_prometheus_javaagent.jar

COPY jmx-exporter-config.yaml /opt/jmx-exporter-config.yaml

ENV ACTIVEMQ_OPTS="-javaagent:/opt/jmx_prometheus_javaagent.jar=9405:/opt/jmx-exporter-config.yaml \
-Dcom.sun.management.jmxremote \
-Dcom.sun.management.jmxremote.port=1099 \
-Dcom.sun.management.jmxremote.rmi.port=1099 \
-Dcom.sun.management.jmxremote.local.only=false \
-Dcom.sun.management.jmxremote.authenticate=false \
-Dcom.sun.management.jmxremote.ssl=false"

EXPOSE 61616 8161 9405
