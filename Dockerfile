# Use the Flutter image so all SDK requirements are met
FROM ghcr.io/cirruslabs/flutter:stable

USER root
WORKDIR /app

# 1. Copy everything
COPY . .

# 2. Get all dependencies (satisfies the Flutter SDK constraint)
RUN flutter pub get

# 3. Map the folders
# This makes 'package:whph/...' imports work inside the container
RUN mkdir -p lib && if [ -d "src/lib" ]; then cp -r src/lib/* lib/; fi

# 4. Expose the WHPH server ports
EXPOSE 44040
EXPOSE 44041

# 5. Run the server directly as a script
# This bypasses AOT compilation and ignores UI-only imports (Offset, Color, etc.)
CMD ["dart", "run", "bin/server.dart"]