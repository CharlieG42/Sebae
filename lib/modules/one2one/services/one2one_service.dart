import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import '../../../core/storage/box_names.dart';
import '../models/one2one_meeting.dart';
import '../models/one2one_task.dart';

class One2OneService extends ChangeNotifier {
  One2OneService() {
    _reload();
  }

  final Uuid _uuid = const Uuid();
  final List<One2OneMeeting> _meetings = [];

  List<One2OneMeeting> get meetings => List.unmodifiable(_meetings);

  Box get _box => Hive.box(BoxNames.one2OneMeetings);

  void _reload() {
    _meetings
      ..clear()
      ..addAll(_box.values
          .whereType<Map>()
          .map(One2OneMeeting.fromMap)
          .toList()
        ..sort((a, b) => b.date.compareTo(a.date)));
  }

  Future<void> createMeeting({
    required String title,
    required String people,
    required DateTime date,
  }) async {
    final meeting = One2OneMeeting(
      id: _uuid.v4(),
      title: title.trim(),
      people: people.trim(),
      date: date,
    );
    await _box.put(meeting.id, meeting.toMap());
    _reload();
    notifyListeners();
  }

  Future<void> updateMeeting(One2OneMeeting meeting) async {
    await _box.put(meeting.id, meeting.toMap());
    _reload();
    notifyListeners();
  }

  Future<void> deleteMeeting(One2OneMeeting meeting) async {
    if (meeting.presentationPath != null) {
      try {
        final file = File(meeting.presentationPath!);
        if (await file.exists()) await file.delete();
      } catch (_) {}
    }
    await _box.delete(meeting.id);
    _reload();
    notifyListeners();
  }

  Future<String> importPresentation(One2OneMeeting meeting, String sourcePath) async {
    final source = File(sourcePath);
    final appDir = await getApplicationSupportDirectory();
    final folder = Directory(path.join(appDir.path, 'one2one_presentations'));
    if (!await folder.exists()) await folder.create(recursive: true);

    final extension = path.extension(sourcePath);
    final fileName = '${meeting.id}${extension.isEmpty ? '.pptx' : extension}';
    final destination = File(path.join(folder.path, fileName));
    await source.copy(destination.path);

    meeting.presentationPath = destination.path;
    meeting.presentationName = path.basename(sourcePath);
    await updateMeeting(meeting);
    return destination.path;
  }

  void removePresentation(One2OneMeeting meeting) {
    if (meeting.presentationPath != null) {
      try {
        final file = File(meeting.presentationPath!);
        if (file.existsSync()) file.deleteSync();
      } catch (_) {}
    }
    meeting.presentationPath = null;
    meeting.presentationName = null;
    updateMeeting(meeting);
  }

  void addTask(One2OneMeeting meeting, String title, String comments,
      One2OneTaskStatus status, DateTime? dueDate) {
    meeting.tasks.add(One2OneTask(
      id: _uuid.v4(),
      title: title.trim(),
      comments: comments.trim(),
      status: status,
      dueDate: dueDate,
    ));
    updateMeeting(meeting);
  }

  void updateTask(One2OneMeeting meeting, One2OneTask task) {
    updateMeeting(meeting);
  }

  void removeTask(One2OneMeeting meeting, One2OneTask task) {
    meeting.tasks.removeWhere((item) => item.id == task.id);
    updateMeeting(meeting);
  }

  int get totalTasks =>
      _meetings.fold(0, (count, meeting) => count + meeting.tasks.length);

  int get completedTasks => _meetings.fold(
      0,
      (count, meeting) =>
          count + meeting.tasks.where((task) => task.status == One2OneTaskStatus.completed).length);

  int get waitingTasks => _meetings.fold(
      0,
      (count, meeting) =>
          count + meeting.tasks.where((task) => task.status == One2OneTaskStatus.waiting).length);

  int get inProgressTasks => _meetings.fold(
      0,
      (count, meeting) =>
          count + meeting.tasks.where((task) => task.status == One2OneTaskStatus.inProgress).length);

  double get overallProgress => totalTasks == 0 ? 0 : completedTasks / totalTasks;
}
