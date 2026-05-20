#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────
# restic-backup — Encrypted, compressed backup of home folders
# ─────────────────────────────────────────────────────────────
# Produces a single .tar.zst archive for manual Google Drive upload.
# Restic encrypts every data pack with AES-256 (file-level).
# Restic compresses with zstd internally (--compression max).
#
# Usage:  ./backup.sh [--dry-run]
# ─────────────────────────────────────────────────────────────

set -euo pipefail

# ── Colours ──────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # No colour

# ── Configuration ────────────────────────────────────────────
REPO_DIR="${RESTIC_REPO:-$HOME/.restic-backup-repo}"
OUTPUT_DIR="${BACKUP_OUTPUT_DIR:-$HOME}"
TIMESTAMP="$(date +%Y-%m-%d_%H%M%S)"
ARCHIVE_NAME="restic-backup-${TIMESTAMP}.tar.zst"
DRY_RUN=false

# Folders to back up (relative to ~)
BACKUP_DIRS=(
    "$HOME/.gnupg"
    "$HOME/.ssh"
    "$HOME/.tmux"
    "$HOME/Documents"
    "$HOME/Downloads"
    "$HOME/Obsidian Vault"
    "$HOME/Personal"
    "$HOME/Pictures"
    "$HOME/Postman"
)

# ── Functions ────────────────────────────────────────────────
log()   { echo -e "${CYAN}[INFO]${NC}  $*"; }
ok()    { echo -e "${GREEN}[OK]${NC}    $*"; }
warn()  { echo -e "${YELLOW}[WARN]${NC}  $*"; }
err()   { echo -e "${RED}[ERR]${NC}   $*" >&2; }
die()   { err "$@"; exit 1; }

usage() {
    cat <<EOF
${BOLD}restic-backup${NC} — Encrypted compressed backup for Google Drive

${BOLD}Usage:${NC}
    ./backup.sh [OPTIONS]

${BOLD}Options:${NC}
    --dry-run       Show what would be backed up without doing it
    --repo PATH     Override restic repo path (default: ~/.restic-backup-repo)
    --output PATH   Override archive output dir (default: ~/)
    -h, --help      Show this help message

${BOLD}Environment:${NC}
    RESTIC_PASSWORD     Restic repo password (prompted if not set)
    RESTIC_REPO         Override repo path
    BACKUP_OUTPUT_DIR   Override output directory

${BOLD}Examples:${NC}
    ./backup.sh                          # Full backup
    ./backup.sh --dry-run                # Preview what will be backed up
    RESTIC_PASSWORD=secret ./backup.sh   # Non-interactive
EOF
    exit 0
}

check_deps() {
    local missing=()
    for cmd in restic tar zstd; do
        command -v "$cmd" &>/dev/null || missing+=("$cmd")
    done
    if [[ ${#missing[@]} -gt 0 ]]; then
        die "Missing required tools: ${missing[*]}"
    fi
}

validate_dirs() {
    local valid=()
    local skipped=()
    for dir in "${BACKUP_DIRS[@]}"; do
        if [[ -d "$dir" ]]; then
            valid+=("$dir")
        else
            skipped+=("$dir")
        fi
    done

    if [[ ${#skipped[@]} -gt 0 ]]; then
        warn "Skipping missing directories:"
        for d in "${skipped[@]}"; do
            echo -e "  ${YELLOW}✗${NC} $d"
        done
    fi

    if [[ ${#valid[@]} -eq 0 ]]; then
        die "No valid directories to back up!"
    fi

    BACKUP_DIRS=("${valid[@]}")
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

init_repo() {
    if [[ -d "$REPO_DIR" ]] && [[ -f "$REPO_DIR/config" ]]; then
        log "Using existing restic repo at ${BOLD}$REPO_DIR${NC}"
    else
        log "Initializing new restic repo at ${BOLD}$REPO_DIR${NC}"
        restic init --repo "$REPO_DIR" --compression max
        ok "Repo initialized"
    fi
}

run_backup() {
    log "Backing up ${#BACKUP_DIRS[@]} directories..."
    echo

    for dir in "${BACKUP_DIRS[@]}"; do
        echo -e "  ${GREEN}→${NC} $(basename "$dir") ($(du -sh "$dir" 2>/dev/null | cut -f1))"
    done
    echo

    if $DRY_RUN; then
        warn "DRY RUN — skipping actual backup"
        restic backup \
            --repo "$REPO_DIR" \
            --compression max \
            --dry-run \
            --verbose \
            "${BACKUP_DIRS[@]}"
        return
    fi

    restic backup \
        --repo "$REPO_DIR" \
        --compression max \
        --verbose \
        "${BACKUP_DIRS[@]}"

    ok "Restic backup complete"
    echo

    # Show snapshot info
    log "Latest snapshot:"
    restic snapshots --repo "$REPO_DIR" --latest 1
    echo

    # Verify repo integrity
    log "Verifying repo integrity..."
    restic check --repo "$REPO_DIR"
    ok "Repo integrity verified"
}

create_archive() {
    if $DRY_RUN; then
        local total_size
        total_size=$(du -sh "$REPO_DIR" 2>/dev/null | cut -f1)
        warn "DRY RUN — would archive repo ($total_size) to ${BOLD}${OUTPUT_DIR}/${ARCHIVE_NAME}${NC}"
        return
    fi

    log "Creating compressed archive..."
    log "Source: ${BOLD}$REPO_DIR${NC}"
    log "Target: ${BOLD}${OUTPUT_DIR}/${ARCHIVE_NAME}${NC}"

    tar -C "$(dirname "$REPO_DIR")" \
        -cf - "$(basename "$REPO_DIR")" \
        | zstd -T0 --long -19 \
        > "${OUTPUT_DIR}/${ARCHIVE_NAME}"

    local archive_size
    archive_size=$(du -sh "${OUTPUT_DIR}/${ARCHIVE_NAME}" | cut -f1)

    ok "Archive created: ${BOLD}${OUTPUT_DIR}/${ARCHIVE_NAME}${NC} (${archive_size})"
}

print_summary() {
    echo
    echo -e "${BOLD}╔══════════════════════════════════════════════════════╗${NC}"
    echo -e "${BOLD}║               BACKUP COMPLETE ✓                     ║${NC}"
    echo -e "${BOLD}╚══════════════════════════════════════════════════════╝${NC}"
    echo

    if ! $DRY_RUN; then
        local archive_path="${OUTPUT_DIR}/${ARCHIVE_NAME}"
        local archive_size
        archive_size=$(du -sh "$archive_path" | cut -f1)

        echo -e "  ${BOLD}Archive:${NC}  $archive_path"
        echo -e "  ${BOLD}Size:${NC}     $archive_size"
        echo -e "  ${BOLD}Folders:${NC}  ${#BACKUP_DIRS[@]} directories"
        echo

        echo -e "  ${BOLD}Next steps:${NC}"
        echo -e "  1. Upload ${CYAN}${ARCHIVE_NAME}${NC} to Google Drive"
        echo -e "  2. On target device, download it and run:"
        echo -e "     ${CYAN}./restore.sh ${ARCHIVE_NAME}${NC}"
        echo
        echo -e "  ${YELLOW}⚠  Remember your restic password — without it the backup is irrecoverable!${NC}"
    fi
}

# ── Parse Arguments ──────────────────────────────────────────
while [[ $# -gt 0 ]]; do
    case "$1" in
        --dry-run)  DRY_RUN=true; shift ;;
        --repo)     REPO_DIR="$2"; shift 2 ;;
        --output)   OUTPUT_DIR="$2"; shift 2 ;;
        -h|--help)  usage ;;
        *)          die "Unknown option: $1" ;;
    esac
done

# ── Main ─────────────────────────────────────────────────────
echo
echo -e "${BOLD}━━━ restic-backup ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo

check_deps
validate_dirs
get_password
init_repo
run_backup
create_archive
print_summary
