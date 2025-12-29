# --- STAGE 1: Build ---
FROM ghcr.io/cirruslabs/flutter:stable AS build

# Set environment to ignore root warnings
ENV PUB_CACHE=/root/.pub-cache
USER root
WORKDIR /app

# 1. Copy everything
COPY . .

# 2. Force a clean get to apply dependency_overrides
# We use --suppress-analytics to keep the logs clean
RUN flutter pub env && flutter pub get --no-example

# 3. MAP THE FOLDERS
RUN mkdir -p lib && cp -r src/lib/* lib/

# 4. Compile the binary
# We use 'dart compile' because we are building a server, not a UI app
RUN dart compile exe bin/server.dart -o bin/server

# --- STAGE 2: Runtime ---
FROM debian:buster-slim

# Copy the runtime and the compiled server binary
COPY --from=build /runtime/ /
COPY --from=build /app/bin/server /app/bin/server

# Standard WHPH ports
EXPOSE 44040
EXPOSE 44041

CMD ["/app/bin/server"]