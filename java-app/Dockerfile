FROM maven:3.9-eclipse-temurin-17 AS build
WORKDIR /app
COPY pom.xml .
RUN mvn dependency:go-offline
COPY src ./src
RUN mvn clean package -DskipTests

FROM eclipse-temurin:17-jre-alpine
WORKDIR /app

RUN addgroup -g 1001 javauser && \
    adduser -D -u 1001 -G javauser javauser

COPY --from=build /app/target/demo-1.0.0.jar app.jar

RUN chown -R javauser:javauser /app

USER javauser

ENV JAVA_OPTS="-Dcom.sun.management.jmxremote \
-Dcom.sun.management.jmxremote.port=9010 \
-Dcom.sun.management.jmxremote.rmi.port=9010 \
-Dcom.sun.management.jmxremote.local.only=false \
-Dcom.sun.management.jmxremote.authenticate=false \
-Dcom.sun.management.jmxremote.ssl=false \
-Djava.rmi.server.hostname=localhost"

EXPOSE 8080 9010

ENTRYPOINT ["sh", "-c", "java $JAVA_OPTS -jar app.jar"]
