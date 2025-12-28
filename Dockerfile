# --- STAGE 1: Build (Using Flutter SDK to satisfy acore dependency) ---
FROM ghcr.io/cirruslabs/flutter:stable AS build

USER root
WORKDIR /app

# 1. Copy everything
COPY . .

# 2. Get dependencies using 'flutter pub' instead of 'dart pub'
# This satisfies the Flutter SDK requirement in acore/pubspec.yaml
RUN flutter pub get

# 3. MAP THE FOLDERS
# Move everything from src/lib to the root lib folder so package:whph works
RUN mkdir -p lib && cp -r src/lib/* lib/

# 4. Compile the binary
# Even though we are in a Flutter environment, we compile a pure Dart server binary.
# Note: This will ONLY work if the specific code used by bin/server.dart 
# does not actually execute Flutter UI code at runtime.
RUN dart compile exe bin/server.dart -o bin/server

# --- STAGE 2: Runtime (Back to a tiny image) ---
FROM debian:buster-slim

# Copy the runtime and the compiled server binary
COPY --from=build /runtime/ /
COPY --from=build /app/bin/server /app/bin/server

# Standard WHPH ports
EXPOSE 44040
EXPOSE 44041

CMD ["/app/bin/server"]