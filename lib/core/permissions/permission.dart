/// Permission keys aligned with Hosanna-server / Studio RBAC
/// (`resource.action`).
enum AppPermission {
  songCreate('song.create'),
  songAccess('song.access'),
  songUpdate('song.update'),
  songDelete('song.delete'),
  songImport('song.import'),
  aiUse('ai.use'),
  aiManage('ai.manage'),
  exportPdf('export.pdf');

  const AppPermission(this.key);
  final String key;

  String get resource {
    final i = key.indexOf('.');
    return i < 0 ? key : key.substring(0, i);
  }

  String get action {
    final i = key.indexOf('.');
    return i < 0 ? key : key.substring(i + 1);
  }
}
