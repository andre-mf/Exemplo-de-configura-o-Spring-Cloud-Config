FROM openjdk:11-jre-slim

WORKDIR /app
COPY 'sccClient-0.0.1-SNAPSHOT.jar' .

ENTRYPOINT ["java", "-jar", "sccClient-0.0.1-SNAPSHOT.jar"]
EXPOSE 8888