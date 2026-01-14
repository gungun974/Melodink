import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:melodink_client/core/helpers/app_path_provider.dart';
import 'package:melodink_client/core/logger/logger.dart';
import 'package:path/path.dart';
import 'package:sqlite3/sqlite3.dart';

class DatabaseMigrationFile {
  final int version;
  final String path;

  DatabaseMigrationFile({required this.version, required this.path});
}

class DatabaseService {
  static Database? _database;

  static Future<Database> getDatabase() async {
    if (_database != null) {
      return _database!;
    }

    final String databasePath;

    if (!kIsWeb) {
      try {
        final appDir = await getMelodinkInstanceSupportDirectory();

        databasePath = join(appDir.path, "databases", "melodink.db");

        final dir = Directory(join(appDir.path, "databases"));

        if (!await dir.exists()) {
          await dir.create(recursive: true);
        }
      } catch (_) {
        databaseLogger.w(
          "Database can't be open when no instance is available",
        );

        rethrow;
      }
    } else {
      databasePath = "melodink-web.db";
    }

    final database = sqlite3.open(databasePath);

    database.execute('''
      CREATE TABLE IF NOT EXISTS schema_migrations(
        version uint64
      )
    ''');

    database.execute('''
      CREATE UNIQUE INDEX IF NOT EXISTS version_unique
          on schema_migrations (version);
    ''');

    databaseLogger.i("📀 Database connection established successfully!");

    await _migrateDatabase(database);

    _database = database;

    return database;
  }

  static void disconnectDatabase() {
    if (_database == null) {
      return;
    }

    _database!.dispose();
    _database = null;

    databaseLogger.i("📀 Database connection have been close");
  }

  static Future<List<DatabaseMigrationFile>> _getUpMigrationsFiles() async {
    final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);

    return manifest
        .listAssets()
        .where(
          (path) =>
              path.startsWith("lib/core/database/migrations/") &&
              path.endsWith(".up.sql"),
        )
        .fold<List<DatabaseMigrationFile>>([], (acc, path) {
          final rawVersion = basename(path).split("_").first;

          final version = int.tryParse(rawVersion);

          if (version == null) {
            return acc;
          }

          return [...acc, DatabaseMigrationFile(version: version, path: path)];
        })
        .toList()
      ..sort((a, b) => a.version.compareTo(b.version));
  }

  static int _getDatabaseVersion(Database database) {
    final result = database.select(
      "SELECT version FROM schema_migrations LIMIT 1",
    );

    if (result.isNotEmpty) {
      return result.first["version"] as int;
    }

    return -1;
  }

  static void _setDatabaseVersion(Database database, int version) {
    database.execute('DELETE FROM schema_migrations');

    database.execute('INSERT INTO schema_migrations (version) VALUES (?)', [
      version,
    ]);

    databaseLogger.i("Database is now at version $version");
  }

  static List<String> _parseSqlStatements(String sqlContent) {
    final List<String> statements = [];
    final List<String> lines = sqlContent.split('\n');
    final StringBuffer currentStatement = StringBuffer();
    int beginEndDepth = 0;

    for (String line in lines) {
      String trimmedLine = line.trim();

      if (trimmedLine.isEmpty || trimmedLine.startsWith('--')) {
        continue;
      }

      String upperLine = trimmedLine.toUpperCase();
      if (upperLine == 'BEGIN' || upperLine.startsWith('BEGIN ')) {
        beginEndDepth++;
      }
      if (upperLine == 'END;' || upperLine == 'END') {
        beginEndDepth--;
      }

      currentStatement.write(line);
      currentStatement.write('\n');

      if (trimmedLine.endsWith(';') && beginEndDepth == 0) {
        String statement = currentStatement.toString().trim();
        if (statement.isNotEmpty) {
          statements.add(statement);
        }
        currentStatement.clear();
      }
    }

    String remaining = currentStatement.toString().trim();
    if (remaining.isNotEmpty) {
      statements.add(remaining);
    }

    return statements;
  }

  static Future<void> _migrateDatabase(Database database) async {
    final migrationsFiles = await _getUpMigrationsFiles();

    int currentVersion = _getDatabaseVersion(database);

    bool hasStartedMigration = false;

    for (final migrationFile in migrationsFiles) {
      if (currentVersion < migrationFile.version) {
        if (!hasStartedMigration) {
          databaseLogger.i(
            "Database is starting migration from version $currentVersion",
          );
        }

        hasStartedMigration = true;
        try {
          final rawQueries = await rootBundle.loadString(migrationFile.path);

          List<String> queries = _parseSqlStatements(rawQueries);

          database.execute('BEGIN TRANSACTION;');

          for (String query in queries) {
            database.execute(query);
          }

          _setDatabaseVersion(database, migrationFile.version);

          database.execute('COMMIT;');
        } catch (e) {
          database.execute("ROLLBACK;");
          databaseLogger.e(
            "Failed to apply database migration ${migrationFile.version}",
          );
          databaseLogger.e(e);
          rethrow;
        }

        currentVersion = migrationFile.version;
      }
    }

    if (hasStartedMigration) {
      databaseLogger.i("Database has finish migration process");
    }
  }
}
