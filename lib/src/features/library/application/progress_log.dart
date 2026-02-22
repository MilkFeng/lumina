enum ProgressLogType { info, warning, error, success }

class ProgressLog {
  final String message;
  final ProgressLogType type;

  ProgressLog(this.message, this.type);
}
