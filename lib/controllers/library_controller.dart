import 'package:get/get.dart';

import 'package:fretboard/models/library_folder.dart';
import 'package:fretboard/models/saved_session.dart';
import 'package:fretboard/services/library_store.dart';
import 'package:fretboard/services/saved_sessions_service.dart';

enum LibraryViewMode { tiles, list }

enum LibrarySortMode { byDateDesc, byDateAsc, byName }

/// Organises the app's saved practice sessions into folders, with search, sort
/// and view options, mirroring the looper and ear-training libraries. Folders are
/// persisted via [LibraryStore]; each session's folder assignment, colour and
/// display name live on the [SavedSession] itself (owned by
/// [SavedSessionsService]).
class LibraryController extends GetxController {
  final _store = LibraryStore();

  final folders = <LibraryFolder>[].obs;
  final sessions = <SavedSession>[].obs;

  final currentFolderId = Rx<String?>(null);
  final viewMode = LibraryViewMode.tiles.obs;
  final sortMode = LibrarySortMode.byDateDesc.obs;
  final searchQuery = ''.obs;
  final loading = true.obs;

  @override
  void onInit() {
    super.onInit();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    folders.value = await _store.loadFolders();
    sessions.value = await SavedSessionsService.load();
    loading.value = false;
  }

  /// Re-pull the session list from disk (after a resume/save elsewhere).
  Future<void> reloadSessions() async {
    sessions.value = await SavedSessionsService.load();
  }

  void _persistFolders() => _store.saveFolders(folders.toList());
  void _persistSessions() =>
      SavedSessionsService.overwrite(sessions.toList());

  SavedSession? _sessionById(String id) =>
      sessions.firstWhereOrNull((s) => s.id == id);

  // ── Navigation ────────────────────────────────────────────────────────────

  List<String> get breadcrumb {
    final crumb = <String>[];
    var id = currentFolderId.value;
    while (id != null) {
      final f = folders.firstWhereOrNull((f) => f.id == id);
      if (f == null) break;
      crumb.insert(0, f.name);
      id = f.parentId;
    }
    return crumb;
  }

  void enterFolder(String id) => currentFolderId.value = id;

  void goUp() {
    final f = folders.firstWhereOrNull((f) => f.id == currentFolderId.value);
    currentFolderId.value = f?.parentId;
  }

  /// How many items (sub-folders + sessions) live directly inside [folderId].
  int folderItemCount(String folderId) {
    final subFolders = folders.where((f) => f.parentId == folderId).length;
    final s = sessions.where((s) => s.folderId == folderId).length;
    return subFolders + s;
  }

  // ── Visible contents ──────────────────────────────────────────────────────

  List<LibraryFolder> get visibleFolders {
    final q = searchQuery.value.toLowerCase();
    return folders
        .where((f) =>
            f.parentId == currentFolderId.value &&
            (q.isEmpty || f.name.toLowerCase().contains(q)))
        .toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
  }

  List<SavedSession> get visibleSessions {
    final q = searchQuery.value.toLowerCase();
    final list = sessions
        .where((s) =>
            s.folderId == currentFolderId.value &&
            (q.isEmpty ||
                s.displayName.toLowerCase().contains(q) ||
                s.modeGroup.toLowerCase().contains(q) ||
                s.title.toLowerCase().contains(q)))
        .toList();

    switch (sortMode.value) {
      case LibrarySortMode.byDateDesc:
        list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case LibrarySortMode.byDateAsc:
        list.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        break;
      case LibrarySortMode.byName:
        list.sort((a, b) =>
            a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase()));
        break;
    }
    return list;
  }

  // ── Folder mutations ──────────────────────────────────────────────────────

  void createFolder(String name) {
    folders.add(LibraryFolder(
      id: generateFolderId(),
      name: name,
      parentId: currentFolderId.value,
      createdAt: DateTime.now(),
    ));
    _persistFolders();
  }

  void renameFolder(String id, String name) {
    final i = folders.indexWhere((f) => f.id == id);
    if (i == -1) return;
    folders[i] = folders[i].copyWith(name: name);
    folders.refresh();
    _persistFolders();
  }

  /// True when [targetId] is [folderId] itself or one of its descendants.
  bool _isSelfOrDescendant(String folderId, String? targetId) {
    var id = targetId;
    while (id != null) {
      if (id == folderId) return true;
      id = folders.firstWhereOrNull((f) => f.id == id)?.parentId;
    }
    return false;
  }

  /// Whether [folderId] can be moved under [targetParentId] without a cycle.
  bool canMoveFolder(String folderId, String? targetParentId) {
    final f = folders.firstWhereOrNull((f) => f.id == folderId);
    if (f == null) return false;
    if (f.parentId == targetParentId) return false; // already there
    return !_isSelfOrDescendant(folderId, targetParentId);
  }

  void moveFolder(String id, String? targetParentId) {
    if (!canMoveFolder(id, targetParentId)) return;
    final i = folders.indexWhere((f) => f.id == id);
    if (i == -1) return;
    folders[i] = targetParentId == null
        ? folders[i].copyWith(clearParent: true)
        : folders[i].copyWith(parentId: targetParentId);
    folders.refresh();
    _persistFolders();
  }

  void deleteFolder(String id) {
    folders.removeWhere((f) => f.id == id);
    // Orphan any sessions filed here back to the root.
    var changed = false;
    for (var i = 0; i < sessions.length; i++) {
      if (sessions[i].folderId == id) {
        sessions[i] = sessions[i].copyWith(clearFolder: true);
        changed = true;
      }
    }
    _persistFolders();
    if (changed) {
      sessions.refresh();
      _persistSessions();
    }
  }

  void setFolderColor(String id, int? colorValue) {
    final i = folders.indexWhere((f) => f.id == id);
    if (i == -1) return;
    folders[i] = colorValue == null
        ? folders[i].copyWith(clearColor: true)
        : folders[i].copyWith(colorValue: colorValue);
    folders.refresh();
    _persistFolders();
  }

  // ── Session mutations ─────────────────────────────────────────────────────

  void moveSession(String id, String? folderId) {
    final i = sessions.indexWhere((s) => s.id == id);
    if (i == -1) return;
    sessions[i] = sessions[i]
        .copyWith(folderId: folderId, clearFolder: folderId == null);
    sessions.refresh();
    _persistSessions();
  }

  void setSessionColor(String id, int? colorValue) {
    final i = sessions.indexWhere((s) => s.id == id);
    if (i == -1) return;
    sessions[i] = colorValue == null
        ? sessions[i].copyWith(clearColor: true)
        : sessions[i].copyWith(colorValue: colorValue);
    sessions.refresh();
    _persistSessions();
  }

  void renameSession(String id, String newName) {
    final i = sessions.indexWhere((s) => s.id == id);
    if (i == -1) return;
    final trimmed = newName.trim();
    sessions[i] = trimmed.isEmpty
        ? sessions[i].copyWith(clearCustomName: true)
        : sessions[i].copyWith(customName: trimmed);
    sessions.refresh();
    _persistSessions();
  }

  void deleteSession(String id) {
    sessions.removeWhere((s) => s.id == id);
    _persistSessions();
  }

  /// Whether the drop target differs from where [id] currently lives.
  bool sessionCanMove(String id, String? targetFolderId) {
    final s = _sessionById(id);
    return s != null && s.folderId != targetFolderId;
  }
}
