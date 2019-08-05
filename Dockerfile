FROM openjdk:8
COPY target/DockeriseSpringDataRestOnK8-0.0.1-SNAPSHOT /app.jar
EXPOSE 8080/tcp
ENTRYPOINT ["java", "-jar", "/app.jar"]
