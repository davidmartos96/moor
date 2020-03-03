import 'package:test/test.dart';
import 'package:tests/data/sample_data.dart' as people;
import 'package:tests/database/database.dart';

import 'suite.dart';

void migrationTests(TestExecutor executor) {
  test('creates users table when opening version 1', () async {
    final database = Database(executor.createExecutor(), schemaVersion: 1);

    // we write 3 users when the database is created
    final count = await database.userCountQuery().getSingle();
    expect(count, 3);

    await database.close();
  });

  test('saves and restores database', () async {
    var database = Database(executor.createExecutor(), schemaVersion: 1);
    await database.writeUser(people.florian);
    await database.close();

    database = Database(executor.createExecutor(), schemaVersion: 2);

    // the 3 initial users plus People.florian
    final count = await database.userCountQuery().getSingle();
    expect(count, 4);
    expect(database.schemaVersionChangedFrom, 1);
    expect(database.schemaVersionChangedTo, 2);

    await database.close();
  });

  test('runs the migrator when downgrading', () async {
    var database = Database(executor.createExecutor(), schemaVersion: 2);
    await database.executor.ensureOpen(); // Create the database
    await database.close();

    database = Database(executor.createExecutor(), schemaVersion: 1);
    await database.executor.ensureOpen(); // Let the migrator run
    
    expect(database.schemaVersionChangedFrom, 2);
    expect(database.schemaVersionChangedTo, 1);

    await database.close();
  });
}
