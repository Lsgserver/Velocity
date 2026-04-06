FROM eclipse-temurin:21-jdk AS builder

RUN apt-get update && apt-get install -y \
    git \
    curl \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /build

ARG VELOCITY_BRANCH=dev/3.0.0
RUN git clone --depth=1 --branch ${branch} \
    https://github.com/Lsgserver/Velocity.git .

RUN chmod +x ./gradlew && \
    ./gradlew build --no-daemon -x test

FROM eclipse-temurin:21-jre AS runtime

LABEL maintainer="Lsgserver"
LABEL description="VelocityMC Proxy - built for kubernetes"

RUN useradd -m -u 1000 -s /bin/bash velocity

WORKDIR /velocity

COPY --from=builder /build/proxy/build/libs/*-all.jar velocity.jar

RUN chown -R velocity:velocity /velocity

USER velocity

EXPOSE 25577

HEALTHCHECK --interval=30s --timeout=10s --start-period=30s --retries=3 \
    CMD bash -c 'echo > /dev/tcp/localhost/25577' || exit 1

ENTRYPOINT ["java", \
    "-XX:+UseG1GC", \
    "-XX:G1HeapRegionSize=4M", \
    "-XX:+UnlockExperimentalVMOptions", \
    "-XX:+ParallelRefProcEnabled", \
    "-XX:+AlwaysPreTouch", \
    "-jar", "velocity.jar"]
