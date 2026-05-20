#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────
# restic-restore — Restore encrypted backup from .tar.zst archive
# ─────────────────────────────────────────────────────────────
# Extracts restic repo from archive, restores files to ~/
#
# Usage:  ./restore.sh <archive.tar.zst> [--target DIR] [--dry-run]
# ─────────────────────────────────────────────────────────────

set -euo pipefail

# ── Colours ──────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

# ── Configuration ────────────────────────────────────────────
ARCHIVE_PATH=""
RESTORE_TARGET="$HOME"
DRY_RUN=false
SNAPSHOT_ID="latest"
TEMP_DIR=""

# ── Functions ────────────────────────────────────────────────
log()   { echo -e "${CYAN}[INFO]${NC}  $*"; }
ok()    { echo -e "${GREEN}[OK]${NC}    $*"; }
warn()  { echo -e "${YELLOW}[WARN]${NC}  $*"; }
err()   { echo -e "${RED}[ERR]${NC}   $*" >&2; }
die()   { err "$@"; exit 1; }

usage() {
    cat <<EOF
${BOLD}restic-restore${NC} — Restore encrypted backup from .tar.zst archive

${BOLD}Usage:${NC}
    ./restore.sh <archive.tar.zst> [OPTIONS]

${BOLD}Arguments:${NC}
    <archive.tar.zst>   Path to the backup archive

${BOLD}Options:${NC}
    --target PATH       Restore to a custom directory (default: ~/)
    --snapshot ID       Restore a specific snapshot (default: latest)
    --list              List snapshots in the archive and exit
    --dry-run           Show what would be restored without doing it
    -h, --help          Show this help message

${BOLD}Environment:${NC}
    RESTIC_PASSWORD     Restic repo password (prompted if not set)

${BOLD}Examples:${NC}
    ./restore.sh restic-backup-2026-05-20.tar.zst           # Restore to ~/
    ./restore.sh backup.tar.zst --target /tmp/test-restore   # Restore elsewhere
    ./restore.sh backup.tar.zst --list                       # List snapshots
    ./restore.sh backup.tar.zst --dry-run                    # Preview restore
EOF
    exit 0
}

cleanup() {
    if [[ -n "$TEMP_DIR" ]] && [[ -d "$TEMP_DIR" ]]; then
        log "Cleaning up temp directory..."
        rm -rf "$TEMP_DIR"
        ok "Cleanup complete"
    fi
}
trap cleanup EXIT

check_deps() {
    local missing=()
    for cmd in restic tar zstd; do
        command -v "$cmd" &>/dev/null || missing+=("$cmd")
    done
    if [[ ${#missing[@]} -gt 0 ]]; then
        die "Missing required tools: ${missing[*]}"
    fi
}

get_password() {
    if [[ -z "${RESTIC_PASSWORD:-}" ]]; then
        echo -e "${BOLD}Enter restic repository password:${NC}"
        read -rsp "Password: " RESTIC_PASSWORD
        echo
        if [[ -z "$RESTIC_PASSWORD" ]]; then
            die "Password cannot be empty"
        fi
        export RESTIC_PASSWORD
    fi
}

extract_archive() {
    TEMP_DIR="$(mktemp -d /tmp/restic-restore-XXXXXX)"
    log "Extracting archive to temp directory..."
    log "Archive: ${BOLD}${ARCHIVE_PATH}${NC}"

    zstd -d --stdout "$ARCHIVE_PATH" | tar -xf - -C "$TEMP_DIR"

    # Find the restic repo directory inside the extracted archive
    local repo_dir
    repo_dir=$(find "$TEMP_DIR" -maxdepth 2 -name "config" -path "*/data/../config" -o -name "config" -exec test -d "{}" \; 2>/dev/null | head -1)

    # Try to find the repo by looking for restic config file
    REPO_DIR=$(find "$TEMP_DIR" -maxdepth 2 -name "config" -type f 2>/dev/null | while read -r cfg; do
        parent="$(dirname "$cfg")"
        if [[ -d "$parent/data" ]] && [[ -d "$parent/snapshots" ]]; then
            echo "$parent"
            break
        fi
    done)

    if [[ -z "$REPO_DIR" ]]; then
        # Fallback: look for common repo dir name
        if [[ -d "$TEMP_DIR/.restic-backup-repo" ]]; then
            REPO_DIR="$TEMP_DIR/.restic-backup-repo"
        else
            # Last resort: first directory in temp
            REPO_DIR=$(find "$TEMP_DIR" -maxdepth 1 -mindepth 1 -type d | head -1)
        fi
    fi

    if [[ -z "$REPO_DIR" ]] || [[ ! -f "$REPO_DIR/config" ]]; then
        die "Could not find restic repository in archive"
    fi

    ok "Repo found at: ${BOLD}$REPO_DIR${NC}"
}

list_snapshots() {
    log "Snapshots in archive:"
    echo
    restic snapshots --repo "$REPO_DIR"
}

run_restore() {
    log "Verifying repo integrity..."
    restic check --repo "$REPO_DIR"
    ok "Repo integrity verified"
    echo

    log "Available snapshots:"
    restic snapshots --repo "$REPO_DIR"
    echo

    log "Restoring snapshot '${BOLD}${SNAPSHOT_ID}${NC}' to ${BOLD}${RESTORE_TARGET}${NC}..."
    echo

    if $DRY_RUN; then
        warn "DRY RUN — showing what would be restored:"
        echo
        restic ls --repo "$REPO_DIR" "$SNAPSHOT_ID" | head -50
        local total
        total=$(restic ls --repo "$REPO_DIR" "$SNAPSHOT_ID" | wc -l)
        echo
        warn "... and $((total - 50)) more files (total: $total files)"
        return
    fi

    # Create target directory if needed
    mkdir -p "$RESTORE_TARGET"

    restic restore "$SNAPSHOT_ID" \
        --repo "$REPO_DIR" \
        --target "$RESTORE_TARGET" \
        --verbose

    ok "Restore complete!"
}

fix_permissions() {
    if $DRY_RUN; then
        return
    fi

    log "Fixing permissions on sensitive directories..."

    local ssh_dir="${RESTORE_TARGET}/.ssh"
    local gnupg_dir="${RESTORE_TARGET}/.gnupg"

    if [[ -d "$ssh_dir" ]]; then
        chmod 700 "$ssh_dir"
        find "$ssh_dir" -type f -name "id_*" ! -name "*.pub" -exec chmod 600 {} \;
        find "$ssh_dir" -type f -name "*.pub" -exec chmod 644 {} \;
        [[ -f "$ssh_dir/config" ]] && chmod 600 "$ssh_dir/config"
        [[ -f "$ssh_dir/known_hosts" ]] && chmod 644 "$ssh_dir/known_hosts"
        ok "SSH permissions fixed"
    fi

    if [[ -d "$gnupg_dir" ]]; then
        chmod 700 "$gnupg_dir"
        find "$gnupg_dir" -type f -exec chmod 600 {} \;
        find "$gnupg_dir" -type d -exec chmod 700 {} \;
        ok "GPG permissions fixed"
    fi
}

print_summary() {
    echo
    echo -e "${BOLD}╔══════════════════════════════════════════════════════╗${NC}"
    echo -e "${BOLD}║              RESTORE COMPLETE ✓                     ║${NC}"
    echo -e "${BOLD}╚══════════════════════════════════════════════════════╝${NC}"
    echo

    if ! $DRY_RUN; then
        echo -e "  ${BOLD}Target:${NC}   $RESTORE_TARGET"
        echo -e "  ${BOLD}Snapshot:${NC} $SNAPSHOT_ID"
        echo

        echo -e "  ${BOLD}Restored folders:${NC}"
        local dirs=(.gnupg .ssh .tmux Documents Downloads "Obsidian Vault" Personal Pictures Postman)
        for d in "${dirs[@]}"; do
            local full_path="${RESTORE_TARGET}/${d}"
            if [[ -d "$full_path" ]]; then
                local size
                size=$(du -sh "$full_path" 2>/dev/null | cut -f1)
                echo -e "    ${GREEN}✓${NC} ${d} (${size})"
            else
                echo -e "    ${YELLOW}✗${NC} ${d} (not in snapshot)"
            fi
        done
        echo
        echo -e "  ${GREEN}All files restored to their original locations!${NC}"
    fi
}

# ── Parse Arguments ──────────────────────────────────────────
LIST_ONLY=false

while [[ $# -gt 0 ]]; do
    case "$1" in
        --target)    RESTORE_TARGET="$2"; shift 2 ;;
        --snapshot)  SNAPSHOT_ID="$2"; shift 2 ;;
        --list)      LIST_ONLY=true; shift ;;
        --dry-run)   DRY_RUN=true; shift ;;
        -h|--help)   usage ;;
        -*)          die "Unknown option: $1" ;;
        *)
            if [[ -z "$ARCHIVE_PATH" ]]; then
                ARCHIVE_PATH="$1"
            else
                die "Unexpected argument: $1"
            fi
            shift
            ;;
    esac
done

if [[ -z "$ARCHIVE_PATH" ]]; then
    die "Archive path required. Use --help for usage."
fi

if [[ ! -f "$ARCHIVE_PATH" ]]; then
    die "Archive not found: $ARCHIVE_PATH"
fi

# ── Main ─────────────────────────────────────────────────────
echo
echo -e "${BOLD}━━━ restic-restore ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo

check_deps
get_password
extract_archive

if $LIST_ONLY; then
    list_snapshots
    exit 0
fi

run_restore
fix_permissions
print_summary
