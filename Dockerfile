# STAGE 1: Build the executable
FROM dart:stable AS build

WORKDIR /app

# Copy pubspec files. The wildcard * handles cases where pubspec.lock might be missing.
COPY pubspec.* ./
RUN dart pub get

# Copy the rest of the source code
COPY . .

# Ensure dependencies are settled and compile
RUN dart pub get --offline
RUN dart compile exe bin/server.dart -o bin/server

# STAGE 2: Create the runtime image
# We use a slim debian image or even 'scratch' for a tiny footprint
FROM debian:buster-slim

# Copy the compiled binary from the build stage
COPY --from=build /app/bin/server /app/bin/server

# Copy necessary runtime libraries for Dart (SSL certificates, etc.)
COPY --from=build /runtime/ /

# Expose the ports (for documentation)
EXPOSE 44040
EXPOSE 44041

# Start the server
CMD ["/app/bin/server"]