import 'one2one_task.dart';

class One2OneMeeting {
  One2OneMeeting({
    required this.id,
    required this.title,
    required this.people,
    required this.date,
    this.presentationPath,
    this.presentationName,
    List<One2OneTask>? tasks,
  }) : tasks = tasks ?? <One2OneTask>[];

  final String id;
  String title;
  String people;
  DateTime date;
  String? presentationPath;
  String? presentationName;
  List<One2OneTask> tasks;

  int get completedCount =>
      tasks.where((task) => task.status == One2OneTaskStatus.completed).length;

  int get waitingCount =>
      tasks.where((task) => task.status == One2OneTaskStatus.waiting).length;

  int get inProgressCount =>
      tasks.where((task) => task.status == One2OneTaskStatus.inProgress).length;

  double get progress => tasks.isEmpty ? 0 : completedCount / tasks.length;

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'people': people,
        'date': date.toIso8601String(),
        'presentationPath': presentationPath,
        'presentationName': presentationName,
        'tasks': tasks.map((task) => task.toMap()).toList(),
      };

  factory One2OneMeeting.fromMap(Map<dynamic, dynamic> map) {
    final rawTasks = map['tasks'];
    return One2OneMeeting(
      id: map['id']?.toString() ?? '',
      title: map['title']?.toString() ?? 'One2One',
      people: map['people']?.toString() ?? '',
      date: DateTime.tryParse(map['date']?.toString() ?? '') ?? DateTime.now(),
      presentationPath: map['presentationPath']?.toString(),
      presentationName: map['presentationName']?.toString(),
      tasks: rawTasks is List
          ? rawTasks
              .whereType<Map>()
              .map((item) => One2OneTask.fromMap(item))
              .toList()
          : const <One2OneTask>[],
    );
  }
}
