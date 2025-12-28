# STAGE 1: Build
FROM dart:stable AS build

WORKDIR /app

# 1. Copy pubspec first
COPY pubspec.* ./
RUN dart pub get

# 2. Copy the rest of the project
COPY . .

# 3. FIX: Move the source code from 'src/lib' to the root 'lib' 
# so 'package:whph/...' imports work correctly.
RUN if [ -d "src/lib" ]; then cp -r src/lib ./lib; fi

# 4. Compile the server
# This will now find lib/main.dart and lib/presentation/api/api.dart
RUN dart compile exe bin/server.dart -o bin/server

# STAGE 2: Runtime
FROM debian:buster-slim

COPY --from=build /runtime/ /
COPY --from=build /app/bin/server /app/bin/server

# Documentation of ports
EXPOSE 44040
EXPOSE 44041

CMD ["/app/bin/server"]