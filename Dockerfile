# --- STAGE 1: Build ---
FROM dart:stable AS build

WORKDIR /app

# 1. Copy everything in the current directory (including src/ and bin/)
COPY . .

# 2. Get dependencies
# Since we copied the whole folder, the 'acore' path in pubspec.yaml will resolve
RUN dart pub get

# 3. MAP THE FOLDERS
# Dart looks for 'package:whph/...' in /app/lib/
# We move everything from src/lib to the root lib folder
RUN mkdir -p lib && cp -r src/lib/* lib/

# 4. Compile the binary
# This handles all the logic imports now that the folders are mapped
RUN dart compile exe bin/server.dart -o bin/server

# --- STAGE 2: Runtime ---
FROM debian:buster-slim

COPY --from=build /runtime/ /
COPY --from=build /app/bin/server /app/bin/server

# Standard WHPH ports
EXPOSE 44040
EXPOSE 44041

CMD ["/app/bin/server"]