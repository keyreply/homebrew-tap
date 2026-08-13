#!/usr/bin/env bash
#
# install.sh — installs the kira CLI standalone binary.
# Usage: curl -fsSL https://raw.githubusercontent.com/keyreply/homebrew-tap/main/install.sh | bash
#
# Optional env overrides:
#   KIRA_VERSION=v0.30.1        pin a version (default: latest)
#   KIRA_INSTALL_DIR=...        install directory (default: /usr/local/bin, fallback: ~/.local/bin)
#   KIRA_SKIP_CHECKSUM=1        skip SHA256 verification (not recommended)
#   KIRA_DISABLE_AUTO_UPDATE=1  disable the installed CLI's daily compatibility gate
#
set -euo pipefail

TAP_REPO="keyreply/homebrew-tap"
BIN_NAME="kira"
INSTALL_DIR="${KIRA_INSTALL_DIR:-/usr/local/bin}"
CACHE_DIR="${HOME}/.cache/kira-cli"
TMPDIR_RAW="${TMPDIR:-/tmp}"
WORKDIR="$(mktemp -d "${TMPDIR_RAW%/}/kira-install-XXXXXX")"
trap 'rm -rf "$WORKDIR"' EXIT

mkdir -p "$CACHE_DIR"

require_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "Missing required command: $1" >&2
    exit 1
  fi
}

sha256_file() {
  local path="$1"
  if command -v shasum >/dev/null 2>&1; then
    shasum -a 256 "$path" | awk '{print $1}'
    return
  fi
  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum "$path" | awk '{print $1}'
    return
  fi
  if command -v certutil >/dev/null 2>&1; then
    certutil -hashfile "$path" SHA256 | awk 'NF == 1 && $1 ~ /^[0-9A-Fa-f]+$/ {print tolower($1); exit}'
    return
  fi
  echo "No SHA256 tool found. Install shasum/sha256sum or set KIRA_SKIP_CHECKSUM=1." >&2
  exit 1
}

detect_platform() {
  local os arch
  os="$(uname -s)"
  arch="$(uname -m)"

  case "$os" in
    Darwin)
      case "$arch" in
        arm64) echo "darwin-arm64:tar:kira" ;;
        x86_64) echo "darwin-x64:tar:kira" ;;
        *) echo "Unsupported macOS architecture: $arch" >&2; exit 1 ;;
      esac
      ;;
    Linux)
      case "$arch" in
        x86_64|amd64) echo "linux-x64:tar:kira" ;;
        aarch64|arm64) echo "linux-arm64:tar:kira" ;;
        *) echo "Unsupported Linux architecture: $arch" >&2; exit 1 ;;
      esac
      ;;
    MINGW*|MSYS*|CYGWIN*)
      case "$arch" in
        x86_64|amd64) echo "windows-x64:zip:kira.exe" ;;
        *) echo "Unsupported Windows architecture: $arch" >&2; exit 1 ;;
      esac
      ;;
    *)
      echo "Unsupported OS: $os" >&2
      echo "Download release assets manually from:" >&2
      echo "  https://github.com/${TAP_REPO}/releases/latest" >&2
      exit 1
      ;;
  esac
}

require_cmd curl

IFS=: read -r PLATFORM ARCHIVE_KIND EXE_NAME <<< "$(detect_platform)"

if [[ "$ARCHIVE_KIND" == "tar" ]]; then
  require_cmd tar
else
  require_cmd unzip
fi

if [[ -n "${KIRA_VERSION:-}" ]]; then
  VERSION="$KIRA_VERSION"
else
  VERSION="$(curl -fsSL "https://api.github.com/repos/${TAP_REPO}/releases/latest" \
    | sed -n 's/.*"tag_name"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' \
    | head -n 1)"
  if [[ -z "$VERSION" ]]; then
    echo "Failed to fetch latest release tag from ${TAP_REPO}." >&2
    exit 1
  fi
fi

VERSION="${VERSION#v}"
BASE_URL="https://github.com/${TAP_REPO}/releases/download/v${VERSION}"
if [[ "$ARCHIVE_KIND" == "tar" ]]; then
  ARCHIVE="${BIN_NAME}-${VERSION}-${PLATFORM}.tar.gz"
else
  ARCHIVE="${BIN_NAME}-${VERSION}-${PLATFORM}.zip"
fi
ARCHIVE_URL="${BASE_URL}/${ARCHIVE}"
CHECKSUMS_URL="${BASE_URL}/checksums.txt"

echo "Downloading kira v${VERSION} (${PLATFORM})..." >&2
curl -fsSL "$ARCHIVE_URL" -o "${WORKDIR}/${ARCHIVE}" || {
  echo "Failed to download ${ARCHIVE}." >&2
  echo "Available release assets:" >&2
  echo "  https://github.com/${TAP_REPO}/releases/tag/v${VERSION}" >&2
  exit 1
}

if curl -fsSL "$CHECKSUMS_URL" -o "${WORKDIR}/checksums.txt" 2>/dev/null; then
  EXPECTED_SHA="$(awk -v a="$ARCHIVE" '$2 ~ a {print $1; exit}' "${WORKDIR}/checksums.txt")"
  ACTUAL_SHA="$(sha256_file "${WORKDIR}/${ARCHIVE}")"

  if [[ -z "$EXPECTED_SHA" ]]; then
    echo "Could not find ${ARCHIVE} in checksums.txt." >&2
    cat "${WORKDIR}/checksums.txt" >&2
    exit 1
  fi

  if [[ "$ACTUAL_SHA" != "$EXPECTED_SHA" ]]; then
    echo "SHA256 mismatch for ${ARCHIVE}." >&2
    echo "  expected: $EXPECTED_SHA" >&2
    echo "  actual:   $ACTUAL_SHA" >&2
    exit 1
  fi

  cp "${WORKDIR}/checksums.txt" "${CACHE_DIR}/checksums-${VERSION}.txt"
else
  if [[ "${KIRA_SKIP_CHECKSUM:-0}" != "1" ]]; then
    echo "checksums.txt not found on the release. Re-run with:" >&2
    echo "  KIRA_SKIP_CHECKSUM=1 bash install.sh" >&2
    echo "to install without SHA verification." >&2
    exit 1
  fi
  echo "WARNING: installing without SHA256 verification (KIRA_SKIP_CHECKSUM=1)." >&2
fi

if [[ "$ARCHIVE_KIND" == "tar" ]]; then
  tar -xzf "${WORKDIR}/${ARCHIVE}" -C "$WORKDIR"
else
  unzip -q "${WORKDIR}/${ARCHIVE}" -d "$WORKDIR"
fi

TMPBIN="${WORKDIR}/${EXE_NAME}"
if [[ ! -f "$TMPBIN" ]]; then
  echo "Archive did not contain expected executable '${EXE_NAME}'." >&2
  exit 1
fi
chmod +x "$TMPBIN" 2>/dev/null || true

if [[ -w "$INSTALL_DIR" ]]; then
  TARGET="${INSTALL_DIR}/${EXE_NAME}"
else
  FALLBACK="${HOME}/.local/bin/${EXE_NAME}"
  mkdir -p "$(dirname "$FALLBACK")"
  TARGET="$FALLBACK"
  echo "No write permission for ${INSTALL_DIR}; installing to ${TARGET}" >&2
fi

mv -f -- "$TMPBIN" "$TARGET"
echo "Installed kira v${VERSION} to ${TARGET}" >&2

echo "Refreshing bundled Kira skills..." >&2
KIRA_DISABLE_AUTO_UPDATE=1 KIRA_DISABLE_SKILL_REFRESH=1 "$TARGET" chatgpt-skills install --force
KIRA_DISABLE_AUTO_UPDATE=1 KIRA_DISABLE_SKILL_REFRESH=1 "$TARGET" claude-skills install --force

case "$TARGET" in
  "$HOME"/.local/bin/*)
    echo "Ensure ${HOME}/.local/bin is on your PATH." >&2
    ;;
esac

echo "Run: ${TARGET} --help" >&2
