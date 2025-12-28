import 'dart:io';
import 'package:whph/presentation/api/api.dart' as api;
import 'package:whph/presentation/api/crud_endpoints.dart';
// DO NOT import main.dart here
import 'package:whph/presentation/ui/shared/services/app_bootstrap_service.dart';
import 'package:acore/acore.dart';
import 'package:mediatr/mediatr.dart';

void main() async {
  print('Starting WHPH Server...');

  // 1. Initialize the DI container WITHOUT starting Flutter
  // Note: If AppBootstrapService.initializeApp() depends on Flutter, 
  // you may need to create a AppBootstrapService.initServer() method.
  final container = await AppBootstrapService.initializeApp();
  
  // 2. Start the WebSocket server
  await api.startWebSocketServer();
  
  // 3. Get environment variables
  final auditLogHost = Platform.environment['AUDIT_LOG_HOST'] ?? 'localhost';
  final auditLogPort = Platform.environment['AUDIT_LOG_PORT'] ?? '44042';
  final auditLogUrl = 'http://$auditLogHost:$auditLogPort/audit';
  
  // 4. Start the CRUD endpoints server
  final crudServer = await HttpServer.bind(InternetAddress.anyIPv4, api.httpPort, shared: true);
  
  // We resolve the Mediator from the container we just initialized
  final crudEndpoints = CrudEndpoints(
    crudServer, 
    container.resolve<Mediator>(), 
    auditLogUrl: auditLogUrl
  );
  
  await crudEndpoints.start();
  
  print('WHPH Server is running on port ${api.webSocketPort}');
  print('CRUD Endpoints are running on port ${api.httpPort}');
  print('Audit logs are being sent to $auditLogUrl');
}