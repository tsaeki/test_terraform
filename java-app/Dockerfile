FROM maven:3.9-eclipse-temurin-17 AS build
WORKDIR /app
COPY pom.xml .
RUN mvn dependency:go-offline
COPY src ./src
RUN mvn clean package -DskipTests

FROM eclipse-temurin:17-jre-alpine
WORKDIR /app

RUN addgroup -g 1001 javauser && \
    adduser -D -u 1001 -G javauser javauser && \
    apk add --no-cache curl

# Download JMX Exporter
RUN curl -L https://repo1.maven.org/maven2/io/prometheus/jmx/jmx_prometheus_javaagent/0.20.0/jmx_prometheus_javaagent-0.20.0.jar \
    -o /app/jmx_prometheus_javaagent.jar

COPY --from=build /app/target/demo-1.0.0.jar app.jar
COPY jmx-exporter-config.yaml /app/jmx-exporter-config.yaml

RUN chown -R javauser:javauser /app

USER javauser

# Updated JAVA_OPTS to include JMX Exporter as Java agent
ENV JAVA_OPTS="-javaagent:/app/jmx_prometheus_javaagent.jar=9404:/app/jmx-exporter-config.yaml \
-Dcom.sun.management.jmxremote \
-Dcom.sun.management.jmxremote.port=9010 \
-Dcom.sun.management.jmxremote.rmi.port=9010 \
-Dcom.sun.management.jmxremote.local.only=false \
-Dcom.sun.management.jmxremote.authenticate=false \
-Dcom.sun.management.jmxremote.ssl=false \
-Djava.rmi.server.hostname=localhost"

EXPOSE 8080 9404

ENTRYPOINT ["sh", "-c", "java $JAVA_OPTS -jar app.jar"]
