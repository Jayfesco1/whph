import 'dart:io';
import 'package:whph/presentation/api/api.dart' as api;
import 'package:whph/presentation/api/crud_endpoints.dart';
import 'package:whph/main.dart';

void main() async {
  print('Starting WHPH Server...');
  
  // Start the WebSocket server
  await api.startWebSocketServer();
  
  // Get audit log URL and port from environment variables
  final auditLogHost = Platform.environment['AUDIT_LOG_HOST'] ?? 'localhost';
  final auditLogPort = Platform.environment['AUDIT_LOG_PORT'] ?? '44042';
  final auditLogUrl = 'http://$auditLogHost:$auditLogPort/audit';
  
  // Start the CRUD endpoints server
  final crudServer = await HttpServer.bind(InternetAddress.anyIPv4, api.httpPort, shared: true);
  final crudEndpoints = CrudEndpoints(crudServer, container.resolve<Mediator>(), auditLogUrl: auditLogUrl);
  await crudEndpoints.start();
  
  print('WHPH Server is running on port ${api.webSocketPort}');
  print('CRUD Endpoints are running on port ${api.httpPort}');
  print('Audit logs are being sent to $auditLogUrl');
  print('Press Ctrl+C to stop the server');
}