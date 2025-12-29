# Use the full Flutter image so all dependencies (including Flutter logic) are available
FROM ghcr.io/cirruslabs/flutter:stable

USER root
WORKDIR /app

# 1. Copy everything
COPY . .

# 2. Get dependencies (this satisfies the acore/flutter requirement)
RUN flutter pub get

# 3. Map the folders
# This ensures that 'package:whph/...' imports work correctly
RUN mkdir -p lib && if [ -d "src/lib" ]; then cp -r src/lib/* lib/; fi

# 4. Port exposure
EXPOSE 44040
EXPOSE 44041

# 5. RUN IN JIT MODE
# We do NOT use 'dart compile'. We run the script directly.
# This avoids the "Type Offset not found" errors.
CMD ["dart", "run", "bin/server.dart"]