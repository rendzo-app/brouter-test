FROM gradle:jdk17-jammy as build

RUN mkdir /tmp/brouter
WORKDIR /tmp/brouter
COPY . .
RUN ./gradlew clean build

FROM openjdk:17.0.1-jdk-slim

# Download required tools
RUN apt-get update && apt-get install -y wget unzip curl && rm -rf /var/lib/apt/lists/*

COPY --from=build /tmp/brouter/brouter-server/build/libs/brouter-*-all.jar /brouter.jar
COPY --from=build /tmp/brouter/misc/scripts/standalone/server.sh /bin/
COPY --from=build /tmp/brouter/misc/* /profiles2/

COPY --from=build /tmp/brouter/misc/scripts/download_segments.sh /download_segments.sh


# Download all segment files (this can take 10–30 minutes and ~5GB)
RUN chmod +x /download_segments.sh && /download_segments.sh && \
    mkdir -p /segments4 && mv tmp/segments4/* /segments4

EXPOSE 17777
CMD /bin/server.sh

