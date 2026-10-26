import '../services/json_read.dart';

/// One step of the service's own process on a request, as the office
/// published it (the Citizen's Charter): what happens, who is responsible,
/// how many working days, and whether it is done.
class WorkflowStep {
  const WorkflowStep({
    required this.index,
    required this.name,
    this.responsible,
    this.days,
    this.done = false,
    this.doneAt,
  });

  final int index;
  final String name;
  final String? responsible;
  final String? days;
  final bool done;
  final DateTime? doneAt;
}

/// "Steps of your request" (the website's request-extras): the request
/// detail's `workflow` (esperanza-backend ServiceWorkflow::describe), present
/// when the service publishes one.
class RequestWorkflow {
  const RequestWorkflow({required this.steps, this.current, this.stopped = false});

  final List<WorkflowStep> steps;

  /// The step being worked on; null once all are done or the request stopped.
  final int? current;

  /// Rejected or cancelled: the steps after it will not happen.
  final bool stopped;

  int get doneCount => steps.where((s) => s.done).length;

  static RequestWorkflow? fromApi(Map<String, dynamic>? json) {
    if (json == null) return null;
    final steps = JsonRead.rows(json['steps'], (s) {
      final name = JsonRead.nonEmpty(s['name']) ?? JsonRead.nonEmpty(s['label']);
      final index = JsonRead.integer(s['index']);
      if (name == null || index == null) return null;
      final days = s['days'];
      return WorkflowStep(
        index: index,
        name: name,
        responsible: JsonRead.nonEmpty(s['responsible']),
        days: days == null || '$days'.trim().isEmpty ? null : '$days'.trim(),
        done: JsonRead.boolean(s['done']) ?? false,
        doneAt: JsonRead.date(s['done_at']),
      );
    });
    if (steps.isEmpty) return null;
    return RequestWorkflow(
      steps: steps,
      current: JsonRead.integer(json['current']),
      stopped: JsonRead.boolean(json['stopped']) ?? false,
    );
  }
}
