import 'dart:io';
import 'package:whph/presentation/api/api.dart' as api;
import 'package:whph/presentation/api/crud_endpoints.dart';
import 'package:whph/server_bootstrap.dart'; // Use the new file
import 'package:acore/acore.dart';
import 'package:mediatr/mediatr.dart';

void main() async {
  print('Starting WHPH Server (Headless Mode)...');
  
  // Initialize ONLY logic/persistence
  final container = await ServerBootstrapService.initializeServer();
  await ServerBootstrapService.initializeServerServices(container);
  
  await api.startWebSocketServer();
  
  final auditLogHost = Platform.environment['AUDIT_LOG_HOST'] ?? 'localhost';
  final auditLogPort = Platform.environment['AUDIT_LOG_PORT'] ?? '44042';
  final auditLogUrl = 'http://$auditLogHost:$auditLogPort/audit';
  
  final crudServer = await HttpServer.bind(InternetAddress.anyIPv4, api.httpPort, shared: true);
  
  // Resolve Mediator from the logic-only container
  final crudEndpoints = CrudEndpoints(
    crudServer, 
    container.resolve<Mediator>(), 
    auditLogUrl: auditLogUrl
  );
  
  await crudEndpoints.start();
  
  print('WHPH Server running on port ${api.webSocketPort}');
}