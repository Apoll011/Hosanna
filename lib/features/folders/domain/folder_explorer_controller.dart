import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Tracks which folder [FolderBrowserPage] is currently exploring.
///
/// `null` means the explorer is showing the root level (folders/songs with no
/// parent folder). Kept outside the widget so drawer shortcuts can deep-link
/// the explorer into a specific folder before switching to the folders branch.
class FolderExplorerController extends StateNotifier<String?> {
  FolderExplorerController() : super(null);

  /// Opens [folderId] (or the root when null).
  void open(String? folderId) => state = folderId;

  /// Navigates one level up, falling back to the root when already there.
  void openParent(String? parentId) => state = parentId;
}

final folderExplorerProvider =
    StateNotifierProvider<FolderExplorerController, String?>(
      (ref) => FolderExplorerController(),
    );
