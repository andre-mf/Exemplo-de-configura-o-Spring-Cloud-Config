FROM openjdk:11-jre-slim

WORKDIR /app
COPY 'sccServer-0.0.1-SNAPSHOT.jar' .

ENTRYPOINT ["java", "-jar", "sccServer-0.0.1-SNAPSHOT.jar"]
EXPOSE 8888