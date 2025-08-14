import 'package:logger/logger.dart';

import 'package:intl/intl.dart';

class CustomPrinter extends LogPrinter {
  final String loggerName;

  final DateFormat _dateFormat = DateFormat('yyyy-MM-dd HH:mm:ss.SSS');

  CustomPrinter({required this.loggerName});

  @override
  List<String> log(LogEvent event) {
    final levelText =
        event.level.toString().toUpperCase().split('.').last.padRight(7);

    final levelColor = switch (event.level) {
      Level.trace => "\x1b[37m",
      Level.debug => "\x1b[32m",
      Level.info => "\x1b[34m",
      Level.warning => "\x1b[33m",
      Level.error => "\x1b[31m",
      Level.fatal => "\x1b[91m",
      _ => "\x1bm[0m",
    };

    final stackInfo = _getCallerInfo(StackTrace.current);

    final timestamp = _dateFormat.format(DateTime.now());

    return [
      '${'$timestamp '
          '$levelColor\x1b[1m$levelText \x1b[0m'} $stackInfo ${'\x1b[1m$loggerName\x1b[0m'} ${event.message}'
    ];
  }

  String _getCallerInfo(StackTrace stackTrace) {
    final traceString = stackTrace.toString().split('\n');
    for (final trace in traceString) {
      if (trace.contains('package:logger') ||
          trace.contains('<asynchronous suspension>') ||
          trace.contains('logger.dart')) {
        continue;
      }

      final match = RegExp(r'\((.*\.dart):(\d+):.*\)').firstMatch(trace);
      if (match != null) {
        final fileName =
            match.group(1)?.replaceFirst("package:melodink_client", "lib");
        final lineNumber = match.group(2);
        return '$fileName:$lineNumber'.padRight(30);
      }
    }
    return 'unknown:0'.padRight(30);
  }
}

final mainLogger = Logger(
  printer: CustomPrinter(loggerName: "MainLogger"),
);

final audioControllerLogger = Logger(
  printer: CustomPrinter(loggerName: "AudioControllerLogger"),
);

final databaseLogger = Logger(
  printer: CustomPrinter(loggerName: "DatabaseLogger"),
);

final syncLogger = Logger(
  printer: CustomPrinter(loggerName: "SyncLogger"),
);
