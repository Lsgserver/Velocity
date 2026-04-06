FROM eclipse-temurin:21-jdk AS builder

RUN apt-get update && apt-get install -y \
    git \
    curl \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /build

ARG VELOCITY_BRANCH=dev/3.0.0
RUN git clone --depth=1 --branch ${VELOCITY_BRANCH} \
    https://github.com/PaperMC/Velocity.git .

# Make Gradle wrapper executable and build
RUN chmod +x ./gradlew && \
    ./gradlew build --no-daemon -x test

# ============================================================
# Stage 2: Runtime image
# ============================================================
FROM eclipse-temurin:21-jre AS runtime

LABEL maintainer="your-name"
LABEL description="VelocityMC Proxy - built from source"

# Create a non-root user for security
RUN useradd -m -u 1000 -s /bin/bash velocity

WORKDIR /velocity

# Copy the compiled -all JAR from the build stage
COPY --from=builder /build/proxy/build/libs/*-all.jar velocity.jar

# Give ownership to the velocity user
RUN chown -R velocity:velocity /velocity

USER velocity

# Velocity default port
EXPOSE 25577

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=30s --retries=3 \
    CMD bash -c 'echo > /dev/tcp/localhost/25577' || exit 1

ENTRYPOINT ["java", \
    "-XX:+UseG1GC", \
    "-XX:G1HeapRegionSize=4M", \
    "-XX:+UnlockExperimentalVMOptions", \
    "-XX:+ParallelRefProcEnabled", \
    "-XX:+AlwaysPreTouch", \
    "-jar", "velocity.jar"]
