FROM gradle:jdk17-jammy as build

RUN mkdir /tmp/brouter
WORKDIR /tmp/brouter
COPY . .
RUN ./gradlew clean build

FROM openjdk:17.0.1-jdk-slim

RUN apt-get update && apt-get install -y curl unzip && rm -rf /var/lib/apt/lists/*
COPY --from=build /tmp/brouter/brouter-server/build/libs/brouter-*-all.jar /brouter.jar
COPY --from=build /tmp/brouter/misc/scripts/standalone/server.sh /bin/
COPY --from=build /tmp/brouter/misc/* /profiles2/
COPY --from=build /tmp/brouter/misc/scripts/download_segments.sh /download_segments.sh

# Download segment files into /segments4
RUN mkdir /segments4 && chmod +x /download_segments.sh && /download_segments.sh && mv tmp/segments4/* /segments4

RUN chmod +x /bin/server.sh

EXPOSE 17777
CMD /bin/server.sh