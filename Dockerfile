# Use the full Flutter image
FROM ghcr.io/cirruslabs/flutter:stable

USER root
WORKDIR /app

# 1. Copy and get dependencies
COPY . .
RUN flutter pub get

# 2. Map the folders so 'package:whph/...' works
RUN mkdir -p lib && if [ -d "src/lib" ]; then cp -r src/lib/* lib/; fi

# 3. Expose the server ports
EXPOSE 44040
EXPOSE 44041

# 4. RUN USING FLUTTER TEST
# --timeout none: Prevents the "test" from timing out
# --plain-name "____": We use a name that won't match any real tests
# This satisfies the Offset/Color requirements and runs your server.
CMD ["flutter", "test", "--timeout", "none", "bin/server.dart"]