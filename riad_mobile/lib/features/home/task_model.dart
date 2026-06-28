import 'package:equatable/equatable.dart';

enum TaskType { visit, checklist, service, remoteInspection, estimate }

class Task extends Equatable {
  final String id;
  final TaskType type;
  final String title;
  final String objectName;
  final String address;
  final String status;
  final String? dueTime;

  const Task({
    required this.id,
    required this.type,
    required this.title,
    required this.objectName,
    required this.address,
    required this.status,
    this.dueTime,
  });

  factory Task.fromJson(Map<String, dynamic> json) => Task(
        id: json['id'] as String,
        type: _parseType(json['type'] as String),
        title: json['title'] as String,
        objectName: json['object_name'] as String,
        address: json['address'] as String,
        status: json['status'] as String,
        dueTime: json['due_time'] as String?,
      );

  static TaskType _parseType(String t) => switch (t) {
        'visit' => TaskType.visit,
        'checklist' => TaskType.checklist,
        'service' => TaskType.service,
        'remote_inspection' => TaskType.remoteInspection,
        'estimate' => TaskType.estimate,
        _ => TaskType.visit,
      };

  @override
  List<Object?> get props => [id, type, status];
}
