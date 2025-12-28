# STAGE 1: Build
FROM dart:stable AS build

WORKDIR /app

# Copy pubspec files first to leverage Docker cache
COPY pubspec.* ./
RUN dart pub get

# Copy the entire project
COPY . .

# Ensure dependencies are settled and compile the server
RUN dart pub get --offline
RUN dart compile exe bin/server.dart -o bin/server

# STAGE 2: Runtime
FROM debian:buster-slim

# Copy the compiled binary and runtime libraries
COPY --from=build /app/bin/server /app/bin/server
COPY --from=build /runtime/ /

# Ports (for documentation)
EXPOSE 44040
EXPOSE 44041

# Start the server
CMD ["/app/bin/server"]