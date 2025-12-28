# STAGE 1: Build
FROM dart:stable AS build

WORKDIR /app

# Copy pubspec files first
COPY pubspec.* ./
RUN dart pub get

# Copy everything (lib/, bin/, etc.)
COPY . .

# Compile the server
# If your server needs the lib/ folder, 'dart compile' handles it automatically 
# as long as the pubspec.yaml 'name' matches the package imports.
RUN dart compile exe bin/server.dart -o bin/server

# STAGE 2: Runtime
FROM debian:buster-slim

# Copy runtime dependencies and the binary
COPY --from=build /runtime/ /
COPY --from=build /app/bin/server /app/bin/server

EXPOSE 44040
EXPOSE 44041

CMD ["/app/bin/server"]