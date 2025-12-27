# Use the official Dart SDK image as the base image
FROM dart:latest

# Set the working directory in the container
WORKDIR /app

# Copy the pubspec files to the container
COPY pubspec.yaml pubspec.lock ./

# Install dependencies
RUN dart pub get

# Copy the source code to the container
COPY . .

# Build the application
RUN dart compile exe bin/server.dart -o bin/server

# Expose the WebSocket port
EXPOSE 44040
# Expose the HTTP port
EXPOSE 44041

# Start the server when the container is run
CMD ["./bin/server"]