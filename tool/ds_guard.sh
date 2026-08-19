#!/usr/bin/env bash
#
# ds_guard.sh — JHG design-system governance guard (Phase 6).
#
# Bans NEW raw `Color(0x…)` literals and direct `GoogleFonts.` calls in an app's
# lib/, so every colour/font flows from the `flutter_jhg_elements` tokens
# (`context.jhg` / `JhgTypography`) instead of being hardcoded — which is the one
# thing that makes a central palette/font change actually propagate.
#
# The fleet is mid-migration and still carries HUNDREDS of legitimate literals in
# domain screens (fretboards, mixers, waveforms). So the default enforcement is a
# RATCHET, not a zero-gate: snapshot a baseline, then fail CI only when the count
# grows. Migrated dirs that are already clean can be locked at zero with --strict.
#
# Usage:
#   tools/ds_guard.sh [TARGET_DIR] [MODE]
#
#   TARGET_DIR   directory to scan (default: lib)
#   MODE:
#     (none)      report — list violations + count, always exit 0
#     --baseline  write the current count to <TARGET_DIR>/../.ds_guard_baseline
#     --check     CI ratchet — fail (exit 1) only if count > baseline
#     --strict    fail (exit 1) on ANY violation (for already-clean dirs)
#     --help
#
# Waive a deliberate literal by appending `// ds-guard: allow` on its line.
# Token-definition files (where literals legitimately live) are always excluded.

set -u

TARGET="${1:-lib}"
MODE="${2:-}"

if [[ "${1:-}" == "--help" || "$MODE" == "--help" ]]; then
  sed -n '2,30p' "$0" | sed 's/^# \{0,1\}//'
  exit 0
fi

if [[ ! -d "$TARGET" ]]; then
  echo "ds_guard: target dir '$TARGET' not found" >&2
  exit 2
fi

BASELINE_FILE="$(dirname "$TARGET")/.ds_guard_baseline"

# Files that are the CANONICAL home of raw literals — the token/type layer — and
# are therefore exempt. Matched against the full path.
is_exempt() {
  case "$1" in
    */jhg_tokens.dart|*/jhg_type.dart|*/jhg_typography.dart|*/jhg_colors.dart|\
    */jhg_text_styles.dart|*/jhg_theme.dart) return 0 ;;
    *) return 1 ;;
  esac
}

# Collect violations: `Color(0x…)` or `GoogleFonts.`, minus waived lines and
# exempt files.
violations=""
count=0
while IFS= read -r file; do
  is_exempt "$file" && continue
  while IFS= read -r hit; do
    [[ -z "$hit" ]] && continue
    case "$hit" in
      *"// ds-guard: allow"*) continue ;;
    esac
    # Skip comment lines (doc/`//`/`*` block) that merely MENTION the pattern —
    # strip the "<lineno>:" prefix, then the leading whitespace, and test.
    code="${hit#*:}"
    trimmed="${code#"${code%%[![:space:]]*}"}"
    case "$trimmed" in
      '//'*|'/*'*|'*'*|'///'*) continue ;;
    esac
    violations+="$file:$hit"$'\n'
    count=$((count + 1))
  done < <(grep -nE 'Color\(0x|GoogleFonts\.' "$file" 2>/dev/null)
done < <(find "$TARGET" -name '*.dart' -type f)

print_report() {
  if [[ "$count" -eq 0 ]]; then
    echo "ds_guard: 0 hardcoded colour/font literals in $TARGET ✓"
  else
    printf '%s' "$violations"
    echo "ds_guard: $count hardcoded colour/font literal(s) in $TARGET"
  fi
}

case "$MODE" in
  --baseline)
    echo "$count" > "$BASELINE_FILE"
    echo "ds_guard: baseline set to $count ($BASELINE_FILE)"
    ;;
  --check)
    base=0
    [[ -f "$BASELINE_FILE" ]] && base="$(cat "$BASELINE_FILE" 2>/dev/null || echo 0)"
    if [[ "$count" -gt "$base" ]]; then
      print_report
      echo "ds_guard: FAIL — $count > baseline $base ($((count - base)) new). Route new colours/fonts through context.jhg / JhgTypography, or waive with '// ds-guard: allow'." >&2
      exit 1
    fi
    echo "ds_guard: OK — $count <= baseline $base in $TARGET"
    [[ "$count" -lt "$base" ]] && echo "ds_guard: tip — down from $base; run --baseline to ratchet the gate tighter."
    ;;
  --strict)
    print_report
    if [[ "$count" -gt 0 ]]; then exit 1; fi
    exit 0
    ;;
  "")
    print_report
    ;;
  *)
    echo "ds_guard: unknown mode '$MODE' (use --baseline | --check | --strict | --help)" >&2
    exit 2
    ;;
esac
