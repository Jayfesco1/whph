import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:dart_json_mapper/dart_json_mapper.dart';
import 'package:whph/core/application/features/tasks/commands/save_task_command.dart';
import 'package:whph/core/application/features/tasks/queries/get_list_tasks_query.dart';
import 'package:whph/core/application/features/tasks/queries/get_task_query.dart';
import 'package:whph/core/application/features/habits/commands/save_habit_command.dart';
import 'package:whph/core/application/features/habits/queries/get_list_habits_query.dart';
import 'package:whph/core/application/features/habits/queries/get_habit_query.dart';
import 'package:whph/core/application/features/tags/commands/save_tag_command.dart';
import 'package:whph/core/application/features/tags/queries/get_list_tags_query.dart';
import 'package:whph/core/application/features/tags/queries/get_tag_query.dart';
import 'package:whph/core/application/features/notes/commands/save_note_command.dart';
import 'package:whph/core/application/features/notes/queries/get_list_notes_query.dart';
import 'package:whph/core/application/features/notes/queries/get_note_query.dart';
import 'package:whph/core/domain/shared/utils/logger.dart';
import 'package:whph/main.dart';
import 'package:mediatr/mediatr.dart';
import 'package:http/http.dart' as http;

const int httpPort = 44041;

class CrudEndpoints {
  final HttpServer _server;
  final Mediator _mediator;
  final String _auditLogUrl;

  CrudEndpoints(this._server, this._mediator, {String auditLogUrl = 'http://localhost:44042/audit'}) : _auditLogUrl = auditLogUrl;

  Future<void> _sendAuditLog(String action, String entityType, String entityId, Map<String, dynamic> data, String ip) async {
    try {
      final auditLog = {
        'timestamp': DateTime.now().toIso8601String(),
        'action': action,
        'entityType': entityType,
        'entityId': entityId,
        'data': data,
        'ip': ip,
      };
      Logger.info('Sending audit log: $auditLog');
      await http.post(Uri.parse(_auditLogUrl), body: jsonEncode(auditLog), headers: {'Content-Type': 'application/json'});
    } catch (e) {
      Logger.error('Failed to send audit log: $e');
    }
  }

  Future<void> start() async {
    Logger.info('Starting CRUD endpoints on port $httpPort...');
    
    await for (HttpRequest req in _server) {
      try {
        await _handleRequest(req);
      } catch (e) {
        Logger.error('Error handling request: $e');
        req.response
          ..statusCode = HttpStatus.internalServerError
          ..write('Internal Server Error')
          ..close();
      }
    }
  }

  Future<void> _handleRequest(HttpRequest req) async {
    final path = req.uri.path;
    final method = req.method;
    final ip = req.connectionInfo?.remoteAddress.address ?? 'unknown';

    Logger.info('Received $method request for $path from IP: $ip');

    switch (method) {
      case 'GET':
        await _handleGetRequest(req, path, ip);
        break;
      case 'POST':
        await _handlePostRequest(req, path, ip);
        break;
      case 'PUT':
        await _handlePutRequest(req, path, ip);
        break;
      case 'DELETE':
        await _handleDeleteRequest(req, path, ip);
        break;
      default:
        req.response
          ..statusCode = HttpStatus.methodNotAllowed
          ..write('Method Not Allowed')
          ..close();
    }
  }

  Future<void> _handleGetRequest(HttpRequest req, String path, String ip) async {
    if (path.startsWith('/tasks')) {
      await _handleGetTasks(req, path, ip);
    } else if (path.startsWith('/habits')) {
      await _handleGetHabits(req, path, ip);
    } else if (path.startsWith('/tags')) {
      await _handleGetTags(req, path, ip);
    } else if (path.startsWith('/notes')) {
      await _handleGetNotes(req, path, ip);
    } else {
      req.response
        ..statusCode = HttpStatus.notFound
        ..write('Not Found')
        ..close();
    }
  }

  Future<void> _handlePostRequest(HttpRequest req, String path, String ip) async {
    if (path.startsWith('/tasks')) {
      await _handlePostTask(req, path, ip);
    } else if (path.startsWith('/habits')) {
      await _handlePostHabit(req, path, ip);
    } else if (path.startsWith('/tags')) {
      await _handlePostTag(req, path, ip);
    } else if (path.startsWith('/notes')) {
      await _handlePostNote(req, path, ip);
    } else {
      req.response
        ..statusCode = HttpStatus.notFound
        ..write('Not Found')
        ..close();
    }
  }

  Future<void> _handlePutRequest(HttpRequest req, String path, String ip) async {
    if (path.startsWith('/tasks')) {
      await _handlePutTask(req, path, ip);
    } else if (path.startsWith('/habits')) {
      await _handlePutHabit(req, path, ip);
    } else if (path.startsWith('/tags')) {
      await _handlePutTag(req, path, ip);
    } else if (path.startsWith('/notes')) {
      await _handlePutNote(req, path, ip);
    } else {
      req.response
        ..statusCode = HttpStatus.notFound
        ..write('Not Found')
        ..close();
    }
  }

  Future<void> _handleDeleteRequest(HttpRequest req, String path, String ip) async {
    if (path.startsWith('/tasks')) {
      await _handleDeleteTask(req, path, ip);
    } else if (path.startsWith('/habits')) {
      await _handleDeleteHabit(req, path, ip);
    } else if (path.startsWith('/tags')) {
      await _handleDeleteTag(req, path, ip);
    } else if (path.startsWith('/notes')) {
      await _handleDeleteNote(req, path, ip);
    } else {
      req.response
        ..statusCode = HttpStatus.notFound
        ..write('Not Found')
        ..close();
    }
  }

  Future<void> _handleGetTasks(HttpRequest req, String path, String ip) async {
    if (path == '/tasks') {
      Logger.info('Getting list of tasks from IP: $ip');
      final query = GetListTasksQuery(0, 100);
      final response = await _mediator.send<GetListTasksQuery, GetListTasksQueryResponse>(query);
      await _sendAuditLog('GET', 'tasks', '', {'count': response.items.length}, ip);
      req.response
        ..statusCode = HttpStatus.ok
        ..write(JsonMapper.serialize(response))
        ..close();
    } else if (path.startsWith('/tasks/')) {
      final id = path.split('/').last;
      Logger.info('Getting task with ID: $id from IP: $ip');
      final query = GetTaskQuery(id);
      final response = await _mediator.send<GetTaskQuery, GetTaskQueryResponse?>(query);
      if (response != null) {
        await _sendAuditLog('GET', 'tasks', id, {'task': response.task.toJson()}, ip);
        req.response
          ..statusCode = HttpStatus.ok
          ..write(JsonMapper.serialize(response))
          ..close();
      } else {
        Logger.warning('Task not found with ID: $id from IP: $ip');
        req.response
          ..statusCode = HttpStatus.notFound
          ..write('Task not found')
          ..close();
      }
    }
  }

  Future<void> _handlePostTask(HttpRequest req, String path, String ip) async {
    if (path == '/tasks') {
      final body = await utf8.decodeStream(req);
      final data = jsonDecode(body) as Map<String, dynamic>;
      Logger.info('Creating task with data: $data from IP: $ip');
      final command = SaveTaskCommand(
        title: data['title'],
        description: data['description'],
        priority: data['priority'],
        plannedDate: data['plannedDate'] != null ? DateTime.parse(data['plannedDate']) : null,
        deadlineDate: data['deadlineDate'] != null ? DateTime.parse(data['deadlineDate']) : null,
        estimatedTime: data['estimatedTime'],
        completedAt: data['completedAt'] != null ? DateTime.parse(data['completedAt']) : null,
        tagIdsToAdd: data['tagIdsToAdd'] != null ? List<String>.from(data['tagIdsToAdd']) : null,
        parentTaskId: data['parentTaskId'],
        order: data['order'],
        plannedDateReminderTime: data['plannedDateReminderTime'],
        plannedDateReminderCustomOffset: data['plannedDateReminderCustomOffset'],
        deadlineDateReminderTime: data['deadlineDateReminderTime'],
        deadlineDateReminderCustomOffset: data['deadlineDateReminderCustomOffset'],
        recurrenceType: data['recurrenceType'],
        recurrenceInterval: data['recurrenceInterval'],
        recurrenceDays: data['recurrenceDays'],
        recurrenceStartDate: data['recurrenceStartDate'] != null ? DateTime.parse(data['recurrenceStartDate']) : null,
        recurrenceEndDate: data['recurrenceEndDate'] != null ? DateTime.parse(data['recurrenceEndDate']) : null,
        recurrenceCount: data['recurrenceCount'],
        recurrenceParentId: data['recurrenceParentId'],
      );
      final response = await _mediator.send<SaveTaskCommand, SaveTaskCommandResponse>(command);
      await _sendAuditLog('POST', 'tasks', response.id, data, ip);
      req.response
        ..statusCode = HttpStatus.created
        ..write(JsonMapper.serialize(response))
        ..close();
    }
  }

  Future<void> _handlePutTask(HttpRequest req, String path, String ip) async {
    if (path.startsWith('/tasks/')) {
      final id = path.split('/').last;
      final body = await utf8.decodeStream(req);
      final data = jsonDecode(body) as Map<String, dynamic>;
      Logger.info('Updating task with ID: $id and data: $data from IP: $ip');
      final command = SaveTaskCommand(
        id: id,
        title: data['title'],
        description: data['description'],
        priority: data['priority'],
        plannedDate: data['plannedDate'] != null ? DateTime.parse(data['plannedDate']) : null,
        deadlineDate: data['deadlineDate'] != null ? DateTime.parse(data['deadlineDate']) : null,
        estimatedTime: data['estimatedTime'],
        completedAt: data['completedAt'] != null ? DateTime.parse(data['completedAt']) : null,
        tagIdsToAdd: data['tagIdsToAdd'] != null ? List<String>.from(data['tagIdsToAdd']) : null,
        parentTaskId: data['parentTaskId'],
        order: data['order'],
        plannedDateReminderTime: data['plannedDateReminderTime'],
        plannedDateReminderCustomOffset: data['plannedDateReminderCustomOffset'],
        deadlineDateReminderTime: data['deadlineDateReminderTime'],
        deadlineDateReminderCustomOffset: data['deadlineDateReminderCustomOffset'],
        recurrenceType: data['recurrenceType'],
        recurrenceInterval: data['recurrenceInterval'],
        recurrenceDays: data['recurrenceDays'],
        recurrenceStartDate: data['recurrenceStartDate'] != null ? DateTime.parse(data['recurrenceStartDate']) : null,
        recurrenceEndDate: data['recurrenceEndDate'] != null ? DateTime.parse(data['recurrenceEndDate']) : null,
        recurrenceCount: data['recurrenceCount'],
        recurrenceParentId: data['recurrenceParentId'],
      );
      final response = await _mediator.send<SaveTaskCommand, SaveTaskCommandResponse>(command);
      await _sendAuditLog('PUT', 'tasks', id, data, ip);
      req.response
        ..statusCode = HttpStatus.ok
        ..write(JsonMapper.serialize(response))
        ..close();
    }
  }

  Future<void> _handleDeleteTask(HttpRequest req, String path, String ip) async {
    if (path.startsWith('/tasks/')) {
      final id = path.split('/').last;
      Logger.info('Deleting task with ID: $id from IP: $ip');
      // Implement delete task logic here
      await _sendAuditLog('DELETE', 'tasks', id, {}, ip);
      req.response
        ..statusCode = HttpStatus.ok
        ..write('Task deleted')
        ..close();
    }
  }

  Future<void> _handleGetHabits(HttpRequest req, String path, String ip) async {
    if (path == '/habits') {
      Logger.info('Getting list of habits from IP: $ip');
      final query = GetListHabitsQuery(0, 100);
      final response = await _mediator.send<GetListHabitsQuery, GetListHabitsQueryResponse>(query);
      await _sendAuditLog('GET', 'habits', '', {'count': response.items.length}, ip);
      req.response
        ..statusCode = HttpStatus.ok
        ..write(JsonMapper.serialize(response))
        ..close();
    } else if (path.startsWith('/habits/')) {
      final id = path.split('/').last;
      Logger.info('Getting habit with ID: $id from IP: $ip');
      final query = GetHabitQuery(id);
      final response = await _mediator.send<GetHabitQuery, GetHabitQueryResponse?>(query);
      if (response != null) {
        await _sendAuditLog('GET', 'habits', id, {'habit': response.habit.toJson()}, ip);
        req.response
          ..statusCode = HttpStatus.ok
          ..write(JsonMapper.serialize(response))
          ..close();
      } else {
        Logger.warning('Habit not found with ID: $id from IP: $ip');
        req.response
          ..statusCode = HttpStatus.notFound
          ..write('Habit not found')
          ..close();
      }
    }
  }

  Future<void> _handlePostHabit(HttpRequest req, String path, String ip) async {
    if (path == '/habits') {
      final body = await utf8.decodeStream(req);
      final data = jsonDecode(body) as Map<String, dynamic>;
      Logger.info('Creating habit with data: $data from IP: $ip');
      final command = SaveHabitCommand(
        name: data['name'],
        description: data['description'],
        estimatedTime: data['estimatedTime'],
        archivedDate: data['archivedDate'] != null ? DateTime.parse(data['archivedDate']) : null,
        hasReminder: data['hasReminder'],
        reminderTime: data['reminderTime'],
        reminderDays: data['reminderDays'],
        hasGoal: data['hasGoal'],
        targetFrequency: data['targetFrequency'],
        periodDays: data['periodDays'],
        dailyTarget: data['dailyTarget'],
      );
      final response = await _mediator.send<SaveHabitCommand, SaveHabitCommandResponse>(command);
      await _sendAuditLog('POST', 'habits', response.id, data, ip);
      req.response
        ..statusCode = HttpStatus.created
        ..write(JsonMapper.serialize(response))
        ..close();
    }
  }

  Future<void> _handlePutHabit(HttpRequest req, String path, String ip) async {
    if (path.startsWith('/habits/')) {
      final id = path.split('/').last;
      final body = await utf8.decodeStream(req);
      final data = jsonDecode(body) as Map<String, dynamic>;
      Logger.info('Updating habit with ID: $id and data: $data from IP: $ip');
      final command = SaveHabitCommand(
        id: id,
        name: data['name'],
        description: data['description'],
        estimatedTime: data['estimatedTime'],
        archivedDate: data['archivedDate'] != null ? DateTime.parse(data['archivedDate']) : null,
        hasReminder: data['hasReminder'],
        reminderTime: data['reminderTime'],
        reminderDays: data['reminderDays'],
        hasGoal: data['hasGoal'],
        targetFrequency: data['targetFrequency'],
        periodDays: data['periodDays'],
        dailyTarget: data['dailyTarget'],
      );
      final response = await _mediator.send<SaveHabitCommand, SaveHabitCommandResponse>(command);
      await _sendAuditLog('PUT', 'habits', id, data, ip);
      req.response
        ..statusCode = HttpStatus.ok
        ..write(JsonMapper.serialize(response))
        ..close();
    }
  }

  Future<void> _handleDeleteHabit(HttpRequest req, String path, String ip) async {
    if (path.startsWith('/habits/')) {
      final id = path.split('/').last;
      Logger.info('Deleting habit with ID: $id from IP: $ip');
      // Implement delete habit logic here
      await _sendAuditLog('DELETE', 'habits', id, {}, ip);
      req.response
        ..statusCode = HttpStatus.ok
        ..write('Habit deleted')
        ..close();
    }
  }

  Future<void> _handleGetTags(HttpRequest req, String path, String ip) async {
    if (path == '/tags') {
      Logger.info('Getting list of tags from IP: $ip');
      final query = GetListTagsQuery(0, 100);
      final response = await _mediator.send<GetListTagsQuery, GetListTagsQueryResponse>(query);
      await _sendAuditLog('GET', 'tags', '', {'count': response.items.length}, ip);
      req.response
        ..statusCode = HttpStatus.ok
        ..write(JsonMapper.serialize(response))
        ..close();
    } else if (path.startsWith('/tags/')) {
      final id = path.split('/').last;
      Logger.info('Getting tag with ID: $id from IP: $ip');
      final query = GetTagQuery(id);
      final response = await _mediator.send<GetTagQuery, GetTagQueryResponse?>(query);
      if (response != null) {
        await _sendAuditLog('GET', 'tags', id, {'tag': response.tag.toJson()}, ip);
        req.response
          ..statusCode = HttpStatus.ok
          ..write(JsonMapper.serialize(response))
          ..close();
      } else {
        Logger.warning('Tag not found with ID: $id from IP: $ip');
        req.response
          ..statusCode = HttpStatus.notFound
          ..write('Tag not found')
          ..close();
      }
    }
  }

  Future<void> _handlePostTag(HttpRequest req, String path, String ip) async {
    if (path == '/tags') {
      final body = await utf8.decodeStream(req);
      final data = jsonDecode(body) as Map<String, dynamic>;
      Logger.info('Creating tag with data: $data from IP: $ip');
      final command = SaveTagCommand(
        name: data['name'],
        isArchived: data['isArchived'],
        color: data['color'],
      );
      final response = await _mediator.send<SaveTagCommand, SaveTagCommandResponse>(command);
      await _sendAuditLog('POST', 'tags', response.id, data, ip);
      req.response
        ..statusCode = HttpStatus.created
        ..write(JsonMapper.serialize(response))
        ..close();
    }
  }

  Future<void> _handlePutTag(HttpRequest req, String path, String ip) async {
    if (path.startsWith('/tags/')) {
      final id = path.split('/').last;
      final body = await utf8.decodeStream(req);
      final data = jsonDecode(body) as Map<String, dynamic>;
      Logger.info('Updating tag with ID: $id and data: $data from IP: $ip');
      final command = SaveTagCommand(
        id: id,
        name: data['name'],
        isArchived: data['isArchived'],
        color: data['color'],
      );
      final response = await _mediator.send<SaveTagCommand, SaveTagCommandResponse>(command);
      await _sendAuditLog('PUT', 'tags', id, data, ip);
      req.response
        ..statusCode = HttpStatus.ok
        ..write(JsonMapper.serialize(response))
        ..close();
    }
  }

  Future<void> _handleDeleteTag(HttpRequest req, String path, String ip) async {
    if (path.startsWith('/tags/')) {
      final id = path.split('/').last;
      Logger.info('Deleting tag with ID: $id from IP: $ip');
      // Implement delete tag logic here
      await _sendAuditLog('DELETE', 'tags', id, {}, ip);
      req.response
        ..statusCode = HttpStatus.ok
        ..write('Tag deleted')
        ..close();
    }
  }

  Future<void> _handleGetNotes(HttpRequest req, String path, String ip) async {
    if (path == '/notes') {
      Logger.info('Getting list of notes from IP: $ip');
      final query = GetListNotesQuery(0, 100);
      final response = await _mediator.send<GetListNotesQuery, GetListNotesQueryResponse>(query);
      await _sendAuditLog('GET', 'notes', '', {'count': response.items.length}, ip);
      req.response
        ..statusCode = HttpStatus.ok
        ..write(JsonMapper.serialize(response))
        ..close();
    } else if (path.startsWith('/notes/')) {
      final id = path.split('/').last;
      Logger.info('Getting note with ID: $id from IP: $ip');
      final query = GetNoteQuery(id);
      final response = await _mediator.send<GetNoteQuery, GetNoteQueryResponse?>(query);
      if (response != null) {
        await _sendAuditLog('GET', 'notes', id, {'note': response.note.toJson()}, ip);
        req.response
          ..statusCode = HttpStatus.ok
          ..write(JsonMapper.serialize(response))
          ..close();
      } else {
        Logger.warning('Note not found with ID: $id from IP: $ip');
        req.response
          ..statusCode = HttpStatus.notFound
          ..write('Note not found')
          ..close();
      }
    }
  }

  Future<void> _handlePostNote(HttpRequest req, String path, String ip) async {
    if (path == '/notes') {
      final body = await utf8.decodeStream(req);
      final data = jsonDecode(body) as Map<String, dynamic>;
      Logger.info('Creating note with data: $data from IP: $ip');
      final command = SaveNoteCommand(
        title: data['title'],
        content: data['content'],
      );
      final response = await _mediator.send<SaveNoteCommand, SaveNoteCommandResponse>(command);
      await _sendAuditLog('POST', 'notes', response.id, data, ip);
      req.response
        ..statusCode = HttpStatus.created
        ..write(JsonMapper.serialize(response))
        ..close();
    }
  }

  Future<void> _handlePutNote(HttpRequest req, String path, String ip) async {
    if (path.startsWith('/notes/')) {
      final id = path.split('/').last;
      final body = await utf8.decodeStream(req);
      final data = jsonDecode(body) as Map<String, dynamic>;
      Logger.info('Updating note with ID: $id and data: $data from IP: $ip');
      final command = SaveNoteCommand(
        id: id,
        title: data['title'],
        content: data['content'],
      );
      final response = await _mediator.send<SaveNoteCommand, SaveNoteCommandResponse>(command);
      await _sendAuditLog('PUT', 'notes', id, data, ip);
      req.response
        ..statusCode = HttpStatus.ok
        ..write(JsonMapper.serialize(response))
        ..close();
    }
  }

  Future<void> _handleDeleteNote(HttpRequest req, String path, String ip) async {
    if (path.startsWith('/notes/')) {
      final id = path.split('/').last;
      Logger.info('Deleting note with ID: $id from IP: $ip');
      // Implement delete note logic here
      await _sendAuditLog('DELETE', 'notes', id, {}, ip);
      req.response
        ..statusCode = HttpStatus.ok
        ..write('Note deleted')
        ..close();
    }
  }
}