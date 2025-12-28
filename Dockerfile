# --- STAGE 1: Build ---
FROM dart:stable AS build

WORKDIR /app

# 1. Copy pubspecs
COPY pubspec.* ./
# 2. Copy local packages so acore is found
COPY src/packages ./src/packages

# 3. Get dependencies
RUN dart pub get

# 4. Copy everything else
COPY . .

# 5. CRITICAL: Map src/lib to lib
# This ensures "package:whph/..." imports resolve to the correct files
RUN mkdir -p lib && cp -r src/lib/* lib/

# 6. Build the binary
# This should now ignore the UI folder entirely because our 
# bin/server.dart doesn't import any UI files anymore.
RUN dart compile exe bin/server.dart -o bin/server

# --- STAGE 2: Runtime ---
FROM debian:buster-slim

COPY --from=build /runtime/ /
COPY --from=build /app/bin/server /app/bin/server

EXPOSE 44040
EXPOSE 44041

CMD ["/app/bin/server"]