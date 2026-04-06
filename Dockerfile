# ============================================================
# Stage 1: Build Velocity from source
# ============================================================
FROM eclipse-temurin:21-jdk AS builder

RUN apt-get update && apt-get install -y git curl && rm -rf /var/lib/apt/lists/*

WORKDIR /build

# Source is cloned by Jenkins before docker build, so we just copy it in
COPY . .

RUN chmod +x ./gradlew && \
    ./gradlew build --no-daemon -x test

# ============================================================
# Stage 2: Lean runtime image
# ============================================================
FROM eclipse-temurin:21-jre AS runtime

LABEL org.opencontainers.image.source="https://github.com/Lsgserver/Velocity"
LABEL description="VelocityMC Proxy"

RUN useradd -m -u 1000 -s /bin/bash velocity

WORKDIR /velocity

COPY --from=builder /build/proxy/build/libs/*-all.jar velocity.jar

RUN chown -R velocity:velocity /velocity

USER velocity

# Velocity default proxy port
EXPOSE 25577

HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD bash -c 'echo > /dev/tcp/localhost/25577' || exit 1

ENTRYPOINT ["java", \
    "-XX:+UseG1GC", \
    "-XX:G1HeapRegionSize=4M", \
    "-XX:+UnlockExperimentalVMOptions", \
    "-XX:+ParallelRefProcEnabled", \
    "-XX:+AlwaysPreTouch", \
    "-jar", "velocity.jar"]
