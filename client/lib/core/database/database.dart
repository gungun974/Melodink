import 'package:flutter/services.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
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

    final appDir = await getApplicationSupportDirectory();

    final database = await openDatabase(
      join(appDir.path, "databases", "melodink.db"),
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

    await _migrateDatabase(database);

    _database = database;

    return database;
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
  }

  static _migrateDatabase(Database database) async {
    final migrationsFiles = await _getUpMigrationsFiles();

    int currentVersion = await _getDatabaseVersion(database);

    for (final migrationFile in migrationsFiles) {
      if (currentVersion < migrationFile.version) {
        try {
          await database.transaction((txn) async {
            await txn.execute(await rootBundle.loadString(migrationFile.path));

            await _setDatabaseVersion(txn, migrationFile.version);
          });
        } catch (e) {
          print("Failed to upgrade database");
          rethrow;
        }

        currentVersion = migrationFile.version;
      }
    }
  }
}
