import 'package:dio/dio.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hosanna/core/config/app_config.dart';
import 'package:hosanna/core/db/database.dart';
import 'package:hosanna/core/network/hosanna_api.dart';
import 'package:hosanna/core/sync/replication_engine.dart';
import 'package:hosanna/core/sync/sync_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late SharedPreferences prefs;
  late AppDatabase db;
  late SyncController sync;
  late ReplicationEngine engine;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    db = AppDatabase(NativeDatabase.memory());
    engine = ReplicationEngine(
      api: HosannaApi.fromSharedDio(Dio(), config: AppConfig.instance),
      prefs: prefs,
      adapters: const [],
    );
    sync = SyncController(
      engine,
      prefs,
      db,
      () => db.clearAllReplicatedData(),
    );
  });

  tearDown(() async {
    await db.close();
  });

  test('needsResetFor is true until a successful reset binds the org', () {
    expect(sync.needsResetFor('org-a'), isTrue);
    expect(sync.localOrganizationId, isNull);
  });

  test('successful reset stores localOrganizationId and checkpoint scheme',
      () async {
    await sync.resetForOrganizationSwitch(organizationId: 'org-a');
    expect(sync.localOrganizationId, 'org-a');
    expect(sync.needsResetFor('org-a'), isFalse);
    expect(sync.needsResetFor('org-b'), isTrue);
    expect(prefs.getInt('sync.checkpointScheme'), 2);
  });

  test('clearLocalTenantState drops the org binding', () async {
    await sync.resetForOrganizationSwitch(organizationId: 'org-a');
    await sync.clearLocalTenantState();
    expect(sync.localOrganizationId, isNull);
    expect(sync.needsResetFor('org-a'), isTrue);
  });

  test('prepareOrganizationSwitch aborts a queued sync without dropping later reset',
      () async {
    final syncing = sync.syncAll();
    await sync.prepareOrganizationSwitch();
    await sync.resetForOrganizationSwitch(organizationId: 'org-b');
    await syncing;
    expect(sync.localOrganizationId, 'org-b');
  });

  test('legacy global checkpoints are cleared and force a reset', () async {
    await prefs.setString('replication.checkpoint.songs', '999|song-z');
    await prefs.setString('sync.localOrganizationId', 'org-a');
    // Old installs look "bound" but still carry a pre-scoping cursor.
    expect(sync.needsResetFor('org-a'), isTrue);

    await sync.syncAll(organizationId: 'org-a');
    expect(prefs.getString('replication.checkpoint.songs'), isNull);
    expect(sync.localOrganizationId, 'org-a');
    expect(sync.needsResetFor('org-a'), isFalse);
  });

  test('checkpoints are org-scoped and not shared across tenants', () async {
    engine.bindOrganization('org-a');
    await prefs.setString(
      'replication.checkpoint.org-a.songs',
      '100|a1',
    );
    await prefs.setString(
      'replication.checkpoint.org-b.songs',
      '200|b1',
    );

    // Bound to A: clear only drops A's key (plus legacy), never B's.
    await engine.clearAllCheckpoints();
    expect(prefs.getString('replication.checkpoint.org-a.songs'), isNull);
    expect(prefs.getString('replication.checkpoint.org-b.songs'), '200|b1');

    engine.bindOrganization('org-b');
    await engine.clearAllCheckpoints();
    expect(prefs.getString('replication.checkpoint.org-b.songs'), isNull);
  });
}
