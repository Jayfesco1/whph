# --- STAGE 1: Build ---
FROM dart:stable AS build

WORKDIR /app

# Copy pubspec first to cache dependencies
COPY pubspec.* ./
RUN dart pub get

# Copy all files
COPY . .

# FIX: Map the library folder correctly
# Dart expects 'package:whph/...' to be in /app/lib/
# Your code is in /app/src/lib/
RUN mkdir -p lib && cp -r src/lib/* lib/

# Compile the binary
# We use --suppress-analytics and optimize for the server environment
RUN dart compile exe bin/server.dart -o bin/server

# --- STAGE 2: Runtime ---
FROM debian:buster-slim

# Copy the runtime and binary
COPY --from=build /runtime/ /
COPY --from=build /app/bin/server /app/bin/server

# Standard WHPH ports
EXPOSE 44040
EXPOSE 44041

CMD ["/app/bin/server"]