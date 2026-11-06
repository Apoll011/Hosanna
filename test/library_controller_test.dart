import 'package:flutter_test/flutter_test.dart';
import 'package:hosanna/features/songs/domain/library_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late SharedPreferences prefs;
  late LibraryController controller;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    controller = LibraryController(prefs);
  });

  test('favorites and recents are scoped per organization', () {
    controller.bindOrganization('org-a');
    controller.toggleFavorite('song-1');
    controller.markPlayed('song-2');

    expect(controller.state.favoriteIds, ['song-1']);
    expect(controller.state.recentIds, ['song-2']);

    controller.bindOrganization('org-b');
    expect(controller.state.favoriteIds, isEmpty);
    expect(controller.state.recentIds, isEmpty);
    expect(controller.state.section, LibrarySection.all);

    controller.toggleFavorite('song-b');
    expect(controller.state.favoriteIds, ['song-b']);

    controller.bindOrganization('org-a');
    expect(controller.state.favoriteIds, ['song-1']);
    expect(controller.state.recentIds, ['song-2']);
    expect(prefs.getStringList('library.org-a.favoriteIds'), ['song-1']);
    expect(prefs.getStringList('library.org-b.favoriteIds'), ['song-b']);
  });

  test('migrates legacy unscoped favorites into the first bound org', () async {
    SharedPreferences.setMockInitialValues({
      'library.favoriteIds': ['legacy-1'],
      'library.recentIds': ['legacy-2'],
    });
    prefs = await SharedPreferences.getInstance();
    controller = LibraryController(prefs);

    controller.bindOrganization('org-a');
    expect(controller.state.favoriteIds, ['legacy-1']);
    expect(controller.state.recentIds, ['legacy-2']);
    expect(prefs.containsKey('library.favoriteIds'), isFalse);
    expect(prefs.containsKey('library.recentIds'), isFalse);

    controller.bindOrganization('org-b');
    expect(controller.state.favoriteIds, isEmpty);
    expect(controller.state.recentIds, isEmpty);
  });

  test('ignores writes when no organization is bound', () {
    controller.toggleFavorite('song-1');
    controller.markPlayed('song-1');
    expect(controller.state.favoriteIds, isEmpty);
    expect(controller.state.recentIds, isEmpty);
  });
}
