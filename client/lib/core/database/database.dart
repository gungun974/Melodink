import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:melodink_client/core/helpers/app_path_provider.dart';
import 'package:melodink_client/core/logger/logger.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseMigrationFile {
  final int version;
  final String path;

  DatabaseMigrationFile({
    required this.version,
    required this.path,
  });
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
      } catch (_) {
        databaseLogger
            .w("Database can't be open when no instance is available");

        rethrow;
      }
    } else {
      databasePath = "melodink-web.db";
    }

    final database = await openDatabase(
      databasePath,
      version: 1,
      onCreate: (Database db, int version) async {
        var batch = db.batch();

        batch.execute('''
          CREATE TABLE schema_migrations(
            version uint64
          )
        ''');

        batch.execute('''
          CREATE UNIQUE INDEX version_unique
              on schema_migrations (version);
        ''');

        await batch.commit();
      },
    );

    databaseLogger.i("📀 Database connection established successfully!");

    await _migrateDatabase(database);

    _database = database;

    return database;
  }

  static disconnectDatabase() async {
    if (_database == null) {
      return;
    }

    await _database!.close();
    _database = null;

    databaseLogger.i("📀 Database connection have been close");
  }

  static Future<List<DatabaseMigrationFile>> _getUpMigrationsFiles() async {
    final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);

    return manifest
        .listAssets()
        .where((path) =>
            path.startsWith("lib/core/database/migrations/") &&
            path.endsWith(".up.sql"))
        .fold<List<DatabaseMigrationFile>>([], (acc, path) {
      final rawVersion = basename(path).split("_").first;

      final version = int.tryParse(rawVersion);

      if (version == null) {
        return acc;
      }

      return [
        ...acc,
        DatabaseMigrationFile(
          version: version,
          path: path,
        )
      ];
    }).toList()
      ..sort(
        (a, b) => a.version.compareTo(
          b.version,
        ),
      );
  }

  static Future<int> _getDatabaseVersion(Database database) async {
    final result = await database
        .rawQuery("SELECT version FROM schema_migrations LIMIT 1");

    if (result.isNotEmpty) {
      return result.first["version"] as int;
    }

    return -1;
  }

  static _setDatabaseVersion(Transaction txn, int version) async {
    await txn.rawDelete('DELETE FROM schema_migrations');

    await txn.rawInsert(
      'INSERT INTO schema_migrations (version) VALUES (?)',
      [version],
    );

    databaseLogger.i("Database is now at version $version");
  }

  static _migrateDatabase(Database database) async {
    final migrationsFiles = await _getUpMigrationsFiles();

    int currentVersion = await _getDatabaseVersion(database);

    bool hasStartedMigration = false;

    for (final migrationFile in migrationsFiles) {
      if (currentVersion < migrationFile.version) {
        if (!hasStartedMigration) {
          databaseLogger
              .i("Database is starting migration from version $currentVersion");
        }

        hasStartedMigration = true;
        try {
          await database.transaction((txn) async {
            final rawQueries = await rootBundle.loadString(migrationFile.path);

            List<String> queries = rawQueries
                .split(';')
                .map((q) => q.trim())
                .where((q) => q.isNotEmpty)
                .toList();

            for (String query in queries) {
              await txn.execute(query);
            }

            await _setDatabaseVersion(txn, migrationFile.version);
          });
        } catch (e) {
          databaseLogger
              .e("Failed to apply database migration ${migrationFile.version}");
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
