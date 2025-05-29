FROM gradle:jdk17-jammy as build

RUN apt-get update && apt-get install -y wget unzip curl && rm -rf /var/lib/apt/lists/*

RUN mkdir /tmp/brouter
WORKDIR /tmp/brouter
COPY . .
RUN ./gradlew clean build

FROM openjdk:17.0.1-jdk-slim

# Install required tools
RUN apt-get update && apt-get install -y wget unzip curl bash && rm -rf /var/lib/apt/lists/*

# Copy built jar and other resources
COPY --from=build /tmp/brouter/brouter-server/build/libs/brouter-*-all.jar /brouter.jar
COPY --from=build /tmp/brouter/misc/* /profiles2/

# Copy server and download scripts
COPY --from=build /tmp/brouter/misc/scripts/standalone/server.sh /bin/server.sh
COPY --from=build /tmp/brouter/misc/scripts/download_segments_test.sh /bin/download_segments.sh

# Make scripts executable
RUN chmod +x /bin/server.sh /bin/download_segments.sh

EXPOSE 17777
CMD ["/bin/server.sh"]
