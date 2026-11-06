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

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    db = AppDatabase(NativeDatabase.memory());
    sync = SyncController(
      ReplicationEngine(
        api: HosannaApi.fromSharedDio(Dio(), config: AppConfig.instance),
        prefs: prefs,
        adapters: const [],
      ),
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

  test('successful reset stores localOrganizationId', () async {
    await sync.resetForOrganizationSwitch(organizationId: 'org-a');
    expect(sync.localOrganizationId, 'org-a');
    expect(sync.needsResetFor('org-a'), isFalse);
    expect(sync.needsResetFor('org-b'), isTrue);
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
}
