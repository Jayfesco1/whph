import 'dart:async';
import 'package:mediatr/mediatr.dart';
import 'package:whph/core/application/application_container.dart';
import 'package:whph/infrastructure/infrastructure_container.dart';
import 'package:whph/infrastructure/persistence/persistence_container.dart';
import 'package:whph/core/domain/shared/utils/logger.dart';
import 'package:whph/core/application/shared/services/abstraction/i_logger_service.dart';
import 'package:acore/acore.dart';
import 'package:whph/main.mapper.g.dart' show initializeJsonMapper;

class ServerBootstrapService {
  static Future<IContainer> initializeServer() async {
    final container = Container();
    initializeJsonMapper();

    // Register ONLY logic modules
    registerPersistence(container);
    registerInfrastructure(container);
    registerApplication(container, isServer: true); 
    
    // EXCLUDE: registerUIPresentation(container); <--- This was the error source

    Logger.initialize(container);
    Logger.info('ServerBootstrap: Logic initialization completed');

    return container;
  }

  static Future<void> initializeServerServices(IContainer container) async {
    final loggerService = container.resolve<ILoggerService>();
    await loggerService.configureLogger();
    
    // We skip Theme, Translation, and Notification services 
    // as the server doesn't have a screen.
    
    Logger.info('ServerBootstrap: Server services ready');
  }
}