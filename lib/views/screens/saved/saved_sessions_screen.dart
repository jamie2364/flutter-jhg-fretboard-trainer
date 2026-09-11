// views/screens/saved/saved_sessions_screen.dart
//
// The saved-sessions **Library** — folders, search, sort, tiles/list views,
// colour tinting and drag-and-drop, matching the looper and ear-training
// libraries. Tapping a session drops back onto the board exactly where it was
// left.

import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter_jhg_elements/jhg_elements.dart';
import 'package:fretboard/controllers/home_controller.dart';
import 'package:fretboard/controllers/library_controller.dart';
import 'package:fretboard/models/library_folder.dart';
import 'package:fretboard/models/saved_session.dart';
import 'package:fretboard/views/widgets/app_nav_bar.dart';
import 'package:fretboard/utils/board_nav.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

const _kBg = Color(0xFF0F0F0F);
const _kSurface = Color(0xFF1A1A1A);
const _kPrimary = Color(0xFFFE5D43);
const _kOnSurface = Color(0xFFF1F1F1);
const _kBorder = Color(0x1FFFFFFF);
const _kFaint = Colors.white38;

class SavedSessionsScreen extends StatelessWidget {
  const SavedSessionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<LibraryController>()) {
      Get.put(LibraryController());
    }
    final ctrl = Get.find<LibraryController>();
    // Pick up anything saved elsewhere since this controller was created.
    ctrl.reloadSessions();

    return Scaffold(
      backgroundColor: _kBg,
      bottomNavigationBar: const AppNavBar(activeTab: AppTab.saved),
      body: SafeArea(
        bottom: false,
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Column(
              children: [
                _buildHeader(context, ctrl),
                _buildSearchBar(ctrl),
                Expanded(child: _buildBody(context, ctrl)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────────────────────

  Widget _buildHeader(BuildContext context, LibraryController ctrl) {
    return Obx(() {
      final crumb = ctrl.breadcrumb;
      final viewMode = ctrl.viewMode.value;
      final sortMode = ctrl.sortMode.value;
      final inFolder = ctrl.currentFolderId.value != null;

      // Inside a folder, a back control appears that doubles as a drop target:
      // dragging an item onto it moves that item up to the parent level. At the
      // library root there's no back button at all — this screen is a nav
      // destination, so the bar below is the way out.
      final backButton = GestureDetector(
        onTap: ctrl.goUp,
        child: DragTarget<_DragPayload>(
          onWillAcceptWithDetails: (d) => _canDrop(
            ctrl,
            d.data,
            ctrl.folders
                .firstWhereOrNull((f) => f.id == ctrl.currentFolderId.value)
                ?.parentId,
          ),
          onAcceptWithDetails: (d) {
            final parent = ctrl.folders
                .firstWhereOrNull((f) => f.id == ctrl.currentFolderId.value)
                ?.parentId;
            _applyDrop(ctrl, d.data, parent);
          },
          builder: (context, candidate, __) {
            final hot = candidate.isNotEmpty;
            return JhgIconChipButton.header(
              icon: LucideIcons.chevronLeft,
              onTap: null,
              isActive: hot,
            );
          },
        ),
      );

      return Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
        child: Row(
          children: [
            if (inFolder) ...[backButton, const SizedBox(width: 12)],
            Expanded(
              child: crumb.isEmpty
                  ? Text(
                      'Saved Sessions',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    )
                  : SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      reverse: true,
                      child: Row(
                        children: crumb
                            .asMap()
                            .entries
                            .map((e) => Text(
                                  e.key == 0 ? e.value : ' › ${e.value}',
                                  style: GoogleFonts.poppins(
                                      color: e.key == crumb.length - 1
                                          ? _kOnSurface
                                          : _kFaint,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600),
                                ))
                            .toList(),
                      ),
                    ),
            ),
            // Tiles ⇄ list
            GestureDetector(
              onTap: () => ctrl.viewMode.value =
                  viewMode == LibraryViewMode.tiles
                      ? LibraryViewMode.list
                      : LibraryViewMode.tiles,
              child: _squareBtn(Icon(
                viewMode == LibraryViewMode.tiles
                    ? LucideIcons.list
                    : LucideIcons.layoutGrid,
                color: Colors.white54,
                size: 16,
              )),
            ),
            const SizedBox(width: 8),
            PopupMenuButton<LibrarySortMode>(
              color: _kSurface,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
              onSelected: (v) => ctrl.sortMode.value = v,
              itemBuilder: (_) => [
                _sortItem(LibrarySortMode.byDateDesc, 'Newest first', sortMode),
                _sortItem(LibrarySortMode.byDateAsc, 'Oldest first', sortMode),
                _sortItem(LibrarySortMode.byName, 'A to Z', sortMode),
              ],
              child: _squareBtn(const Icon(LucideIcons.arrowUpDown,
                  color: Colors.white54, size: 16)),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => _showNameDialog(
                context,
                title: 'New folder',
                actionLabel: 'Create',
                hint: 'Folder name',
                onConfirm: ctrl.createFolder,
              ),
              child: _squareBtn(const Icon(LucideIcons.folderPlus,
                  color: Colors.white54, size: 16)),
            ),
          ],
        ),
      );
    });
  }

  Widget _squareBtn(Widget child) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: _kBorder),
      ),
      child: Center(child: child),
    );
  }

  PopupMenuItem<LibrarySortMode> _sortItem(
      LibrarySortMode mode, String label, LibrarySortMode currentSort) {
    final active = currentSort == mode;
    return PopupMenuItem(
      value: mode,
      child: Text(label,
          style: GoogleFonts.poppins(
              color: active ? _kPrimary : Colors.white70,
              fontWeight: active ? FontWeight.w600 : FontWeight.w400,
              fontSize: 14)),
    );
  }

  Widget _buildSearchBar(LibraryController ctrl) {
    return JhgSearchBar(
      hintText: 'Search sessions and folders',
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      onChanged: (v) => ctrl.searchQuery.value = v,
    );
  }

  // ── Body ──────────────────────────────────────────────────────────────────

  Widget _buildBody(BuildContext context, LibraryController ctrl) {
    return Obx(() {
      if (ctrl.loading.value) {
        return const Center(
            child: CircularProgressIndicator(color: _kPrimary));
      }
      final folders = ctrl.visibleFolders;
      final sessions = ctrl.visibleSessions;

      if (folders.isEmpty && sessions.isEmpty) {
        final searching = ctrl.searchQuery.value.isNotEmpty;
        return Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(LucideIcons.folderOpen, color: _kFaint, size: 52),
                const SizedBox(height: 16),
                Text(
                    searching
                        ? 'Nothing matched that'
                        : 'Nothing saved in here yet',
                    style: GoogleFonts.poppins(
                        color: Colors.white70,
                        fontSize: 16,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                Text(
                    searching
                        ? 'Try a different word.'
                        : 'Hit Save while you practise and the session lands '
                            'here, ready to pick up later.',
                    textAlign: TextAlign.center,
                    style:
                        GoogleFonts.inter(color: _kFaint, fontSize: 13, height: 1.5)),
              ],
            ),
          ),
        );
      }

      if (ctrl.viewMode.value == LibraryViewMode.tiles) {
        return _tilesView(context, ctrl, folders, sessions);
      }
      return _listView(context, ctrl, folders, sessions);
    });
  }

  Widget _tilesView(BuildContext context, LibraryController ctrl,
      List<LibraryFolder> folders, List<SavedSession> sessions) {
    return GridView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        mainAxisExtent: 190,
      ),
      itemCount: folders.length + sessions.length,
      itemBuilder: (_, i) {
        if (i < folders.length) {
          final f = folders[i];
          return _FolderTile(
            ctrl: ctrl,
            folder: f,
            onTap: () => ctrl.enterFolder(f.id),
            onMenu: () => _folderMenu(context, ctrl, f),
          );
        }
        final s = sessions[i - folders.length];
        return _SessionTile(
          session: s,
          onOpen: () => _resume(s),
          onMenu: () => _sessionMenu(context, ctrl, s),
        );
      },
    );
  }

  Widget _listView(BuildContext context, LibraryController ctrl,
      List<LibraryFolder> folders, List<SavedSession> sessions) {
    return ListView.separated(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
      itemCount: folders.length + sessions.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, i) {
        if (i < folders.length) {
          final f = folders[i];
          return _FolderRow(
            ctrl: ctrl,
            folder: f,
            onTap: () => ctrl.enterFolder(f.id),
            onMenu: () => _folderMenu(context, ctrl, f),
          );
        }
        final s = sessions[i - folders.length];
        return _SessionRow(
          session: s,
          onOpen: () => _resume(s),
          onMenu: () => _sessionMenu(context, ctrl, s),
        );
      },
    );
  }

  // ── Drag and drop ─────────────────────────────────────────────────────────

  static bool _canDrop(
      LibraryController ctrl, _DragPayload item, String? targetFolderId) {
    if (item.isFolder) return ctrl.canMoveFolder(item.id, targetFolderId);
    return ctrl.sessionCanMove(item.id, targetFolderId);
  }

  static void _applyDrop(
      LibraryController ctrl, _DragPayload item, String? targetFolderId) {
    if (item.isFolder) {
      ctrl.moveFolder(item.id, targetFolderId);
    } else {
      ctrl.moveSession(item.id, targetFolderId);
    }
  }

  // ── Actions ───────────────────────────────────────────────────────────────

  void _resume(SavedSession s) {
    Get.find<HomeController>()
      ..prepareRestore(s)
      ..quickStartSession = false;
    openBoard(replace: true);
  }

  void _folderMenu(
      BuildContext context, LibraryController ctrl, LibraryFolder f) {
    _showActionDialog(
      context,
      title: f.name,
      icon: LucideIcons.folder,
      actions: [
        _SheetActionData(
          icon: LucideIcons.pencil,
          label: 'Rename',
          onTap: () => _showNameDialog(
            context,
            title: 'Rename folder',
            initial: f.name,
            hint: 'Folder name',
            onConfirm: (n) => ctrl.renameFolder(f.id, n),
          ),
        ),
        _SheetActionData(
          icon: LucideIcons.palette,
          label: 'Colour',
          onTap: () => _showColorSheet(
            selected: f.colorValue,
            onPicked: (c) => ctrl.setFolderColor(f.id, c),
          ),
        ),
        _SheetActionData(
          icon: LucideIcons.folderInput,
          label: 'Move to',
          onTap: () => _showMoveSheet(context, ctrl,
              _DragPayload(isFolder: true, id: f.id, name: f.name)),
        ),
        _SheetActionData(
          icon: LucideIcons.trash2,
          label: 'Delete',
          destructive: true,
          onTap: () => _confirmDelete(
            context,
            'Delete folder',
            'Delete "${f.name}"? Any sessions inside move back to the top level.',
            () => ctrl.deleteFolder(f.id),
          ),
        ),
      ],
    );
  }

  void _sessionMenu(
      BuildContext context, LibraryController ctrl, SavedSession s) {
    _showActionDialog(
      context,
      title: s.displayName,
      icon: JhgIcons.play,
      actions: [
        _SheetActionData(
          icon: JhgIcons.play,
          label: 'Resume',
          onTap: () => _resume(s),
        ),
        _SheetActionData(
          icon: LucideIcons.pencil,
          label: 'Rename',
          onTap: () => _showNameDialog(
            context,
            title: 'Rename session',
            initial: s.displayName,
            hint: 'Session name',
            onConfirm: (n) => ctrl.renameSession(s.id, n),
          ),
        ),
        _SheetActionData(
          icon: LucideIcons.palette,
          label: 'Colour',
          onTap: () => _showColorSheet(
            selected: s.colorValue,
            onPicked: (c) => ctrl.setSessionColor(s.id, c),
          ),
        ),
        _SheetActionData(
          icon: LucideIcons.folderInput,
          label: 'Move to',
          onTap: () => _showMoveSheet(context, ctrl,
              _DragPayload(isFolder: false, id: s.id, name: s.displayName)),
        ),
        _SheetActionData(
          icon: LucideIcons.trash2,
          label: 'Delete',
          destructive: true,
          onTap: () => _confirmDelete(
            context,
            'Delete session',
            'Delete "${s.displayName}"? You cannot get it back.',
            () => ctrl.deleteSession(s.id),
          ),
        ),
      ],
    );
  }

  void _showActionDialog(
    BuildContext context, {
    required String title,
    required IconData icon,
    required List<_SheetActionData> actions,
  }) {
    showJHGBlurDialog(
      context: context,
      builder: (ctx) => JHGFrostedDialog(
        icon: icon,
        title: title,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final a in actions)
              _SheetAction(
                icon: a.icon,
                label: a.label,
                destructive: a.destructive,
                onTap: () {
                  Navigator.of(ctx).pop();
                  a.onTap();
                },
              ),
          ],
        ),
      ),
    );
  }

  void _showMoveSheet(
      BuildContext context, LibraryController ctrl, _DragPayload item) {
    showJHGBlurDialog(
      context: context,
      builder: (ctx) => _MoveDialog(
        ctrl: ctrl,
        item: item,
        onPicked: (targetId) => _applyDrop(ctrl, item, targetId),
      ),
    );
  }

  void _showNameDialog(
    BuildContext context, {
    required String title,
    String actionLabel = 'Save',
    String initial = '',
    String hint = 'Name',
    required void Function(String) onConfirm,
  }) {
    showJHGBlurDialog(
      context: context,
      builder: (ctx) => _LibNameDialog(
        title: title,
        actionLabel: actionLabel,
        initial: initial,
        hint: hint,
        onConfirm: onConfirm,
      ),
    );
  }

  void _confirmDelete(BuildContext context, String title, String message,
      VoidCallback onConfirm) {
    showJHGBlurDialog(
      context: context,
      builder: (ctx) => JHGFrostedDialog(
        icon: LucideIcons.trash2,
        title: title,
        description: message,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            JHGFrostedPrimaryButton(
              label: 'Delete',
              onTap: () {
                Navigator.of(ctx).pop();
                onConfirm();
              },
            ),
            const SizedBox(height: 10),
            _SubtleButton(
                label: 'Cancel', onTap: () => Navigator.of(ctx).pop()),
          ],
        ),
      ),
    );
  }
}

/// Payload carried while dragging a folder or session onto a folder to move it.
class _DragPayload {
  const _DragPayload(
      {required this.isFolder, required this.id, required this.name});
  final bool isFolder;
  final String id; // folder id, or session id
  final String name;
}

// ── Shared card styling ───────────────────────────────────────────────────────

/// The base charcoal every library card sits on.
const Color _cardBase = Color(0xFF161616);

/// A card surface: a soft [tint] wash bleeding out of the top-left over the
/// charcoal base, a hairline border and a low drop shadow. Turns coral and
/// brightens while a drag hovers ([hot]).
BoxDecoration _libCardDecoration({
  required Color tint,
  required bool hot,
  double radius = 18,
}) {
  return BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Color.alphaBlend(tint.withValues(alpha: hot ? 0.22 : 0.12), _cardBase),
        _cardBase,
      ],
      stops: const [0.0, 0.85],
    ),
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(
      color: hot
          ? _kPrimary.withValues(alpha: 0.65)
          : Colors.white.withValues(alpha: 0.07),
      width: hot ? 1.5 : 1,
    ),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.28),
        blurRadius: 14,
        offset: const Offset(0, 6),
      ),
    ],
  );
}

/// A small decorative neck used to fill session cards: six string lines with a
/// couple of tinted dots whose positions are seeded from the session id, so
/// every card gets its own stable shape.
class _LibNeckMotif extends StatelessWidget {
  const _LibNeckMotif(
      {required this.seed, required this.tint, this.height = 42});
  final String seed;
  final Color tint;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: CustomPaint(painter: _LibNeckPainter(seed: seed, tint: tint)),
    );
  }
}

class _LibNeckPainter extends CustomPainter {
  _LibNeckPainter({required this.seed, required this.tint});
  final String seed;
  final Color tint;

  @override
  void paint(Canvas canvas, Size size) {
    const strings = 6;
    final gap = size.height / (strings - 1);
    final line = Paint()
      ..color = tint.withValues(alpha: 0.22)
      ..strokeWidth = 1;
    for (var i = 0; i < strings; i++) {
      final y = i * gap;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), line);
    }

    // Two or three dots placed deterministically from the id.
    final h = seed.hashCode.abs();
    final dots = 2 + h % 2;
    final dot = Paint()..color = tint.withValues(alpha: 0.9);
    for (var i = 0; i < dots; i++) {
      final sIdx = (h >> (i * 5)) % strings;
      final frac = 0.12 + (((h >> (i * 7)) % 70) / 100);
      canvas.drawCircle(
        Offset(size.width * frac.clamp(0.08, 0.9), sIdx * gap),
        3.2,
        dot,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _LibNeckPainter old) =>
      old.seed != seed || old.tint != tint;
}

/// The "contents" motif that fills a folder card: a few stacked tinted bars.
class _FolderContentsPreview extends StatelessWidget {
  const _FolderContentsPreview({required this.tint, required this.count});
  final Color tint;
  final int count;

  @override
  Widget build(BuildContext context) {
    if (count == 0) return const SizedBox.shrink();
    final rows = count.clamp(1, 3);
    const widths = [1.0, 0.72, 0.5];
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < rows; i++) ...[
          if (i > 0) const SizedBox(height: 7),
          FractionallySizedBox(
            widthFactor: widths[i],
            child: Container(
              height: 6,
              decoration: BoxDecoration(
                color: tint.withValues(alpha: 0.32 - i * 0.08),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// A rounded-square tinted icon badge shared by tiles and rows.
class _IconBadge extends StatelessWidget {
  const _IconBadge({
    required this.icon,
    required this.tint,
    this.size = 46,
    this.iconSize = 22,
  });
  final IconData icon;
  final Color tint;
  final double size;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            tint.withValues(alpha: 0.28),
            tint.withValues(alpha: 0.14),
          ],
        ),
        borderRadius: BorderRadius.circular(size * 0.30),
        border: Border.all(color: tint.withValues(alpha: 0.35)),
      ),
      child: Icon(icon, color: tint, size: iconSize),
    );
  }
}

// ── Folder widgets ───────────────────────────────────────────────────────────

class _FolderTile extends StatelessWidget {
  const _FolderTile(
      {required this.ctrl,
      required this.folder,
      required this.onTap,
      required this.onMenu});
  final LibraryController ctrl;
  final LibraryFolder folder;
  final VoidCallback onTap;
  final VoidCallback onMenu;

  @override
  Widget build(BuildContext context) {
    return DragTarget<_DragPayload>(
      onWillAcceptWithDetails: (d) =>
          SavedSessionsScreen._canDrop(ctrl, d.data, folder.id),
      onAcceptWithDetails: (d) =>
          SavedSessionsScreen._applyDrop(ctrl, d.data, folder.id),
      builder: (context, candidate, __) {
        final hot = candidate.isNotEmpty;
        final tint = _libTint(folder.colorValue);
        return LongPressDraggable<_DragPayload>(
          data: _DragPayload(isFolder: true, id: folder.id, name: folder.name),
          feedback: _DragChip(icon: LucideIcons.folder, label: folder.name),
          child: GestureDetector(
            onTap: onTap,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 140),
              decoration: _libCardDecoration(tint: tint, hot: hot),
              padding: const EdgeInsets.all(14),
              child: Obx(() {
                final n = ctrl.folderItemCount(folder.id);
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _IconBadge(
                            icon: LucideIcons.folder, tint: tint, iconSize: 24),
                        const Spacer(),
                        _MenuButton(onTap: onMenu),
                      ],
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: _FolderContentsPreview(tint: tint, count: n),
                        ),
                      ),
                    ),
                    Text(folder.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600)),
                    const SizedBox(height: 3),
                    Text(n == 1 ? '1 item' : '$n items',
                        style: GoogleFonts.poppins(
                            color: _kFaint,
                            fontSize: 11,
                            fontWeight: FontWeight.w500)),
                  ],
                );
              }),
            ),
          ),
        );
      },
    );
  }
}

class _FolderRow extends StatelessWidget {
  const _FolderRow(
      {required this.ctrl,
      required this.folder,
      required this.onTap,
      required this.onMenu});
  final LibraryController ctrl;
  final LibraryFolder folder;
  final VoidCallback onTap;
  final VoidCallback onMenu;

  @override
  Widget build(BuildContext context) {
    return DragTarget<_DragPayload>(
      onWillAcceptWithDetails: (d) =>
          SavedSessionsScreen._canDrop(ctrl, d.data, folder.id),
      onAcceptWithDetails: (d) =>
          SavedSessionsScreen._applyDrop(ctrl, d.data, folder.id),
      builder: (context, candidate, __) {
        final hot = candidate.isNotEmpty;
        final tint = _libTint(folder.colorValue);
        return LongPressDraggable<_DragPayload>(
          data: _DragPayload(isFolder: true, id: folder.id, name: folder.name),
          feedback: _DragChip(icon: LucideIcons.folder, label: folder.name),
          child: GestureDetector(
            onTap: onTap,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 140),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: _libCardDecoration(tint: tint, hot: hot, radius: 16),
              child: Row(
                children: [
                  _IconBadge(
                      icon: LucideIcons.folder,
                      tint: tint,
                      size: 40,
                      iconSize: 19),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(folder.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w600)),
                        const SizedBox(height: 2),
                        Obx(() {
                          final n = ctrl.folderItemCount(folder.id);
                          return Text(n == 1 ? '1 item' : '$n items',
                              style: GoogleFonts.poppins(
                                  color: _kFaint, fontSize: 11));
                        }),
                      ],
                    ),
                  ),
                  _RowMenu(onTap: onMenu),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// ── Session widgets ──────────────────────────────────────────────────────────

const List<String> _kMonths = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

String _fmtDate(DateTime d) => '${_kMonths[d.month - 1]} ${d.day}, ${d.year}';

class _SessionTile extends StatelessWidget {
  const _SessionTile(
      {required this.session, required this.onOpen, required this.onMenu});
  final SavedSession session;
  final VoidCallback onOpen;
  final VoidCallback onMenu;

  @override
  Widget build(BuildContext context) {
    final tint =
        _libTint(session.colorValue, fallback: const Color(0xFF8E8E93));
    return LongPressDraggable<_DragPayload>(
      data: _DragPayload(
          isFolder: false, id: session.id, name: session.displayName),
      feedback: _DragChip(icon: JhgIcons.play, label: session.displayName),
      child: GestureDetector(
        onTap: onOpen,
        child: Container(
          decoration: _libCardDecoration(tint: tint, hot: false),
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _IconBadge(icon: JhgIcons.play, tint: tint, iconSize: 18),
                  const Spacer(),
                  _MenuButton(onTap: onMenu),
                ],
              ),
              Expanded(
                child: Center(
                  child: _LibNeckMotif(seed: session.id, tint: tint),
                ),
              ),
              Text(session.displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600)),
              const SizedBox(height: 3),
              Text('${session.modeGroup} · Score ${session.score}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                      color: _kFaint,
                      fontSize: 11,
                      fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      ),
    );
  }
}

class _SessionRow extends StatelessWidget {
  const _SessionRow(
      {required this.session, required this.onOpen, required this.onMenu});
  final SavedSession session;
  final VoidCallback onOpen;
  final VoidCallback onMenu;

  @override
  Widget build(BuildContext context) {
    final tint =
        _libTint(session.colorValue, fallback: const Color(0xFF8E8E93));
    return LongPressDraggable<_DragPayload>(
      data: _DragPayload(
          isFolder: false, id: session.id, name: session.displayName),
      feedback: _DragChip(icon: JhgIcons.play, label: session.displayName),
      child: GestureDetector(
        onTap: onOpen,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: _libCardDecoration(tint: tint, hot: false, radius: 16),
          child: Row(
            children: [
              _IconBadge(
                  icon: JhgIcons.play, tint: tint, size: 40, iconSize: 19),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(session.displayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text(
                        '${session.modeGroup} · Score ${session.score} · ${_fmtDate(session.createdAt)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                            color: _kFaint, fontSize: 11)),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                width: 64,
                child:
                    _LibNeckMotif(seed: session.id, tint: tint, height: 26),
              ),
              const SizedBox(width: 6),
              _RowMenu(onTap: onMenu),
            ],
          ),
        ),
      ),
    );
  }
}

/// A small circular "⋯" button used in the top-right of tiles.
class _MenuButton extends StatelessWidget {
  const _MenuButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 26,
        height: 26,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.06),
          shape: BoxShape.circle,
        ),
        child: const Icon(LucideIcons.moreVertical,
            color: Colors.white54, size: 15),
      ),
    );
  }
}

/// The three-dots menu for list rows.
class _RowMenu extends StatelessWidget {
  const _RowMenu({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: const Padding(
        padding: EdgeInsets.only(left: 6),
        child: Icon(LucideIcons.moreVertical, color: _kFaint, size: 18),
      ),
    );
  }
}

/// A floating chip shown under the finger while dragging a library item.
class _DragChip extends StatelessWidget {
  const _DragChip({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 220),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: _kSurface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _kPrimary.withValues(alpha: 0.6)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.4),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: _kPrimary, size: 16),
            const SizedBox(width: 8),
            Flexible(
              child: Text(label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Item menu ────────────────────────────────────────────────────────────────

class _SheetActionData {
  const _SheetActionData(
      {required this.icon,
      required this.label,
      this.destructive = false,
      required this.onTap});
  final IconData icon;
  final String label;
  final bool destructive;
  final VoidCallback onTap;
}

class _SheetAction extends StatelessWidget {
  const _SheetAction(
      {required this.icon,
      required this.label,
      this.destructive = false,
      required this.onTap});
  final IconData icon;
  final String label;
  final bool destructive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = destructive ? _kPrimary : Colors.white;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
          child: Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 16),
              Text(label,
                  style: GoogleFonts.poppins(
                      color: color, fontSize: 15, fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      ),
    );
  }
}

/// The muted secondary button used beside the frosted primary one.
class _SubtleButton extends StatelessWidget {
  const _SubtleButton({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: 52,
        width: double.infinity,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
        ),
        child: Text(label,
            style: GoogleFonts.poppins(
                color: Colors.white70,
                fontSize: 15,
                fontWeight: FontWeight.w600)),
      ),
    );
  }
}

// ── Move destination picker ──────────────────────────────────────────────────

class _MoveDialog extends StatelessWidget {
  const _MoveDialog(
      {required this.ctrl, required this.item, required this.onPicked});
  final LibraryController ctrl;
  final _DragPayload item;
  final void Function(String? targetFolderId) onPicked;

  /// All folders as (folder, depth) pairs in a stable depth-first order.
  List<(LibraryFolder, int)> _flatten() {
    final out = <(LibraryFolder, int)>[];
    void walk(String? parentId, int depth) {
      final children = ctrl.folders.where((f) => f.parentId == parentId).toList()
        ..sort((a, b) => a.name.compareTo(b.name));
      for (final f in children) {
        out.add((f, depth));
        walk(f.id, depth + 1);
      }
    }

    walk(null, 0);
    return out;
  }

  bool _enabledFor(String folderId, String? currentParent) {
    if (item.isFolder) return ctrl.canMoveFolder(item.id, folderId);
    return folderId != currentParent;
  }

  @override
  Widget build(BuildContext context) {
    final rows = _flatten();
    final currentParent = item.isFolder
        ? ctrl.folders.firstWhereOrNull((f) => f.id == item.id)?.parentId
        : ctrl.sessions.firstWhereOrNull((s) => s.id == item.id)?.folderId;

    return JHGFrostedDialog(
      icon: LucideIcons.folderInput,
      title: 'Move to',
      content: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.42,
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _MoveRow(
                icon: LucideIcons.house,
                label: 'Top level',
                depth: 0,
                enabled: currentParent != null &&
                    (!item.isFolder || ctrl.canMoveFolder(item.id, null)),
                onTap: () {
                  Navigator.of(context).pop();
                  onPicked(null);
                },
              ),
              for (final (f, depth) in rows)
                _MoveRow(
                  icon: LucideIcons.folder,
                  label: f.name,
                  depth: depth + 1,
                  enabled: _enabledFor(f.id, currentParent),
                  onTap: () {
                    Navigator.of(context).pop();
                    onPicked(f.id);
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MoveRow extends StatelessWidget {
  const _MoveRow(
      {required this.icon,
      required this.label,
      required this.depth,
      required this.enabled,
      required this.onTap});
  final IconData icon;
  final String label;
  final int depth;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1 : 0.35,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: EdgeInsets.fromLTRB(8 + depth * 16.0, 13, 8, 13),
            child: Row(
              children: [
                Icon(icon, color: _kPrimary, size: 18),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Create / rename dialog ───────────────────────────────────────────────────

class _LibNameDialog extends StatefulWidget {
  const _LibNameDialog(
      {required this.title,
      required this.actionLabel,
      required this.initial,
      required this.hint,
      required this.onConfirm});
  final String title;
  final String actionLabel;
  final String initial;
  final String hint;
  final void Function(String) onConfirm;

  @override
  State<_LibNameDialog> createState() => _LibNameDialogState();
}

class _LibNameDialogState extends State<_LibNameDialog> {
  late final TextEditingController _ctrl =
      TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _submit() {
    final v = _ctrl.text.trim();
    if (v.isEmpty) return;
    Navigator.of(context).pop();
    widget.onConfirm(v);
  }

  @override
  Widget build(BuildContext context) {
    return JHGFrostedDialog(
      icon: LucideIcons.pencil,
      title: widget.title,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: TextField(
              controller: _ctrl,
              autofocus: true,
              textCapitalization: TextCapitalization.words,
              onSubmitted: (_) => _submit(),
              style: GoogleFonts.poppins(color: Colors.white, fontSize: 15),
              cursorColor: _kPrimary,
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: widget.hint,
                hintStyle:
                    GoogleFonts.poppins(color: _kFaint, fontSize: 15),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
          const SizedBox(height: 20),
          JHGFrostedPrimaryButton(label: widget.actionLabel, onTap: _submit),
          const SizedBox(height: 10),
          _SubtleButton(
              label: 'Cancel', onTap: () => Navigator.of(context).pop()),
        ],
      ),
    );
  }
}

// ── Colours (macOS-style tinting for folders and sessions) ───────────────────

/// The swatches offered in the colour picker. The stored value is the ARGB int.
const List<Color> _libSwatches = [
  Color(0xFFFE5D43), // coral
  Color(0xFFEF5350), // red
  Color(0xFFFFA726), // orange
  Color(0xFFFFCA28), // yellow
  Color(0xFF66BB6A), // green
  Color(0xFF26C6DA), // teal
  Color(0xFF42A5F5), // blue
  Color(0xFFAB47BC), // purple
  Color(0xFFEC407A), // pink
  Color(0xFF9E9E9E), // graphite
];

/// The tint to paint for a stored [value]; [fallback] when none was picked.
Color _libTint(int? value, {Color fallback = _kPrimary}) =>
    value == null ? fallback : Color(value);

/// Opens the frosted colour picker for a folder or session.
void _showColorSheet({
  required int? selected,
  required void Function(int?) onPicked,
}) {
  Get.bottomSheet(
    _ColorPickerSheet(selected: selected, onPicked: onPicked),
    backgroundColor: Colors.transparent,
  );
}

class _ColorPickerSheet extends StatelessWidget {
  const _ColorPickerSheet({required this.selected, required this.onPicked});
  final int? selected;
  final void Function(int?) onPicked;

  @override
  Widget build(BuildContext context) {
    return _FrostedSheet(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 2, 20, 12),
            child: Text('Colour',
                style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600)),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Wrap(
              spacing: 14,
              runSpacing: 14,
              children: [
                _ColorDot(
                  color: Colors.white.withValues(alpha: 0.08),
                  selected: selected == null,
                  isClear: true,
                  onTap: () {
                    Get.back<void>();
                    onPicked(null);
                  },
                ),
                for (final c in _libSwatches)
                  _ColorDot(
                    color: c,
                    selected: selected == c.toARGB32(),
                    onTap: () {
                      Get.back<void>();
                      onPicked(c.toARGB32());
                    },
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _ColorDot extends StatelessWidget {
  const _ColorDot({
    required this.color,
    required this.selected,
    required this.onTap,
    this.isClear = false,
  });
  final Color color;
  final bool selected;
  final bool isClear;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color:
                selected ? Colors.white : Colors.white.withValues(alpha: 0.18),
            width: selected ? 2.5 : 1,
          ),
        ),
        child: isClear
            ? const Icon(LucideIcons.ban, color: _kFaint, size: 18)
            : (selected
                ? const Icon(Icons.check, color: Colors.white, size: 20)
                : null),
      ),
    );
  }
}

/// Shared frosted container for the colour-picker bottom sheet.
class _FrostedSheet extends StatelessWidget {
  const _FrostedSheet({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
        child: Container(
          decoration: BoxDecoration(
            color: _cardBase.withValues(alpha: 0.86),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
            border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 12, 8, 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.20),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  child,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
