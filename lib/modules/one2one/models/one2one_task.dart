enum One2OneTaskStatus { inProgress, waiting, completed }

extension One2OneTaskStatusX on One2OneTaskStatus {
  String get label => switch (this) {
        One2OneTaskStatus.inProgress => 'En cours',
        One2OneTaskStatus.waiting => 'En attente',
        One2OneTaskStatus.completed => 'Terminée',
      };

  static One2OneTaskStatus fromName(String? name) =>
      One2OneTaskStatus.values.firstWhere(
        (value) => value.name == name,
        orElse: () => One2OneTaskStatus.inProgress,
      );
}

class One2OneTask {
  One2OneTask({
    required this.id,
    required this.title,
    this.comments = '',
    this.status = One2OneTaskStatus.inProgress,
    this.dueDate,
  });

  final String id;
  String title;
  String comments;
  One2OneTaskStatus status;
  DateTime? dueDate;

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'comments': comments,
        'status': status.name,
        'dueDate': dueDate?.toIso8601String(),
      };

  factory One2OneTask.fromMap(Map<dynamic, dynamic> map) => One2OneTask(
        id: map['id']?.toString() ?? '',
        title: map['title']?.toString() ?? '',
        comments: map['comments']?.toString() ?? '',
        status: One2OneTaskStatusX.fromName(map['status']?.toString()),
        dueDate: map['dueDate'] == null
            ? null
            : DateTime.tryParse(map['dueDate'].toString()),
      );
}
