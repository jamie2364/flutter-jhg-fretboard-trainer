// views/screens/saved/save_session_dialog.dart
//
// Asks for a name and a destination folder before a session is written to the
// library. Same idea as the looper and ear-training save flows, kept to a single
// dialog: the folder list is inline, so nothing is ever nested two deep.

import 'package:flutter/material.dart';
import 'package:flutter_jhg_elements/jhg_elements.dart';
import 'package:fretboard/controllers/library_controller.dart';
import 'package:fretboard/models/library_folder.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

const _kPrimary = Color(0xFFFE5D43);

/// What the player picked: a name and a folder (null folder = top level).
class SaveSessionResult {
  const SaveSessionResult(this.name, this.folderId);
  final String name;
  final String? folderId;
}

/// Returns null if the user backs out.
Future<SaveSessionResult?> showSaveSessionDialog(
  BuildContext context, {
  required String defaultName,
}) {
  // The folder layer belongs to LibraryController, the same one the library
  // screen uses, so a folder made here shows up there straight away.
  if (!Get.isRegistered<LibraryController>()) {
    Get.put(LibraryController());
  }
  return showJHGBlurDialog<SaveSessionResult>(
    context: context,
    builder: (_) => _SaveSessionDialog(defaultName: defaultName),
  );
}

class _SaveSessionDialog extends StatefulWidget {
  const _SaveSessionDialog({required this.defaultName});
  final String defaultName;

  @override
  State<_SaveSessionDialog> createState() => _SaveSessionDialogState();
}

class _SaveSessionDialogState extends State<_SaveSessionDialog> {
  late final TextEditingController _name =
      TextEditingController(text: widget.defaultName);
  String? _folderId; // null = top level

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  LibraryController get _lib => Get.find<LibraryController>();

  /// Folders as (folder, depth) pairs, depth-first, so nesting is readable.
  List<(LibraryFolder, int)> _flatten() {
    final out = <(LibraryFolder, int)>[];
    void walk(String? parentId, int depth) {
      final children = _lib.folders.where((f) => f.parentId == parentId).toList()
        ..sort((a, b) => a.name.compareTo(b.name));
      for (final f in children) {
        out.add((f, depth));
        walk(f.id, depth + 1);
      }
    }

    walk(null, 0);
    return out;
  }

  void _newFolder() {
    final ctrl = TextEditingController();
    showJHGBlurDialog(
      context: context,
      builder: (ctx) => JHGFrostedDialog(
        icon: LucideIcons.folderPlus,
        title: 'New folder',
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _field(ctrl, 'Folder name', autofocus: true),
            const SizedBox(height: 18),
            JHGFrostedPrimaryButton(
              label: 'Create',
              onTap: () {
                final n = ctrl.text.trim();
                if (n.isEmpty) return;
                Navigator.of(ctx).pop();
                // Create at the top level so it is always reachable from here.
                final before = _lib.currentFolderId.value;
                _lib.currentFolderId.value = null;
                _lib.createFolder(n);
                _lib.currentFolderId.value = before;
                setState(() => _folderId = _lib.folders.last.id);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(TextEditingController c, String hint,
      {bool autofocus = false}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: TextField(
        controller: c,
        autofocus: autofocus,
        textCapitalization: TextCapitalization.words,
        style: GoogleFonts.poppins(color: Colors.white, fontSize: 15),
        cursorColor: _kPrimary,
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: hint,
          hintStyle: GoogleFonts.poppins(color: Colors.white38, fontSize: 15),
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }

  void _save() {
    final typed = _name.text.trim();
    Navigator.pop(
      context,
      SaveSessionResult(
          typed.isEmpty ? widget.defaultName : typed, _folderId),
    );
  }

  @override
  Widget build(BuildContext context) {
    final folders = _flatten();
    return JHGFrostedDialog(
      icon: LucideIcons.save,
      title: 'Save this session',
      description: 'Give it a name and pick where it should live.',
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _field(_name, 'Session name'),
          const SizedBox(height: 18),
          Row(
            children: [
              Text('FOLDER',
                  style: GoogleFonts.inter(
                      color: Colors.white38,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2)),
              const Spacer(),
              GestureDetector(
                onTap: _newFolder,
                behavior: HitTestBehavior.opaque,
                child: Row(
                  children: [
                    const Icon(LucideIcons.folderPlus,
                        color: _kPrimary, size: 14),
                    const SizedBox(width: 5),
                    Text('New',
                        style: GoogleFonts.poppins(
                            color: _kPrimary,
                            fontSize: 12,
                            fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ConstrainedBox(
            constraints: BoxConstraints(
                maxHeight: MediaQuery.sizeOf(context).height * 0.26),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _FolderChoice(
                    label: 'Top level',
                    icon: LucideIcons.house,
                    depth: 0,
                    selected: _folderId == null,
                    onTap: () => setState(() => _folderId = null),
                  ),
                  for (final (f, depth) in folders)
                    _FolderChoice(
                      label: f.name,
                      icon: LucideIcons.folder,
                      depth: depth + 1,
                      selected: _folderId == f.id,
                      onTap: () => setState(() => _folderId = f.id),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          JHGFrostedPrimaryButton(label: 'Save', onTap: _save),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            behavior: HitTestBehavior.opaque,
            child: Container(
              height: 52,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
              ),
              child: Text('Cancel',
                  style: GoogleFonts.poppins(
                      color: Colors.white70,
                      fontSize: 15,
                      fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }
}

class _FolderChoice extends StatelessWidget {
  const _FolderChoice({
    required this.label,
    required this.icon,
    required this.depth,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final IconData icon;
  final int depth;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: EdgeInsets.fromLTRB(10 + depth * 16.0, 11, 10, 11),
        decoration: BoxDecoration(
          color: selected
              ? _kPrimary.withValues(alpha: 0.15)
              : Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected
                ? _kPrimary.withValues(alpha: 0.55)
                : Colors.white.withValues(alpha: 0.08),
          ),
        ),
        child: Row(
          children: [
            Icon(icon,
                color: selected ? _kPrimary : Colors.white54, size: 16),
            const SizedBox(width: 10),
            Expanded(
              child: Text(label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                      color: selected ? _kPrimary : Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500)),
            ),
            if (selected)
              const Icon(Icons.check_rounded, color: _kPrimary, size: 16),
          ],
        ),
      ),
    );
  }
}
