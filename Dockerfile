# --- STAGE 1: Build ---
FROM ghcr.io/cirruslabs/flutter:stable AS build

# Set environment to suppress the root warning and use a dedicated cache
ENV PUB_CACHE=/root/.pub-cache
USER root
WORKDIR /app

# 1. Copy everything
COPY . .

# 2. Get dependencies
# We use 'flutter pub get' because the acore package requires the Flutter SDK
RUN flutter pub get --no-example

# 3. MAP THE FOLDERS
# Move everything from src/lib to the root lib folder
RUN mkdir -p lib && cp -r src/lib/* lib/

# 4. Compile the binary
# We use 'dart compile' because we are building a standalone server binary
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