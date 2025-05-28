FROM gradle:jdk17-jammy as build

RUN mkdir /tmp/brouter
WORKDIR /tmp/brouter
COPY . .
RUN ./gradlew clean build

FROM openjdk:17.0.1-jdk-slim

# Download required tools
RUN apt-get update && apt-get install -y wget unzip curl && rm -rf /var/lib/apt/lists/*

COPY --from=build /tmp/brouter/brouter-server/build/libs/brouter-*-all.jar /brouter.jar
COPY --from=build /tmp/brouter/misc/* /profiles2/
COPY --from=build /tmp/brouter/misc/scripts/standalone/server.sh /bin/server.sh
COPY --from=build /tmp/brouter/misc/scripts/standalone/download_segments.sh /download_segments.sh

RUN chmod +x /bin/server.sh /download_segments.sh

EXPOSE 17777

CMD ["/bin/bash", "-c", "./download_segments.sh && ./bin/server.sh"]

