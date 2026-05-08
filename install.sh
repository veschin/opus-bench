#!/usr/bin/env bash
set -euo pipefail

G='\033[32m' R='\033[31m' Y='\033[33m' B='\033[1m' D='\033[90m' N='\033[0m'

ok()   { printf "  ${G}[+]${N} %s\n" "$1"; }
fail() { printf "  ${R}[-]${N} %s\n" "$1"; }
warn() { printf "  ${Y}[~]${N} %s\n" "$1"; }

BENCH_DIR="${BENCH_DIR:-$(pwd)}"
REPO_RAW="https://raw.githubusercontent.com/veschin/opus-bench/main"

printf "\n${B}  opus-bench installer${N}\n\n"

missing=0

check_dep() {
    local name=$1 hint=$2
    if command -v "$name" >/dev/null 2>&1; then
        ok "$name"
    else
        fail "$name - $hint"
        missing=1
    fi
}

check_dep claude "https://docs.claude.com/en/docs/claude-code"
check_dep gum    "brew install gum / pacman -S gum"
check_dep python3 "ships with most distros"

echo ""

if [[ $missing -eq 1 ]]; then
    fail "Install missing dependencies first"
    exit 1
fi

mkdir -p "$BENCH_DIR/results"

if curl -fsSL "$REPO_RAW/opus-bench" -o "$BENCH_DIR/opus-bench" 2>/dev/null; then
    chmod +x "$BENCH_DIR/opus-bench"
    size=$(du -h "$BENCH_DIR/opus-bench" | cut -f1)
    ok "Downloaded opus-bench (${size})"
else
    fail "Download failed"
    exit 1
fi

if [[ -f "${HOME}/.config/GoLeM/zai_api_key" ]]; then
    ok "Z.AI API key found"
else
    warn "Z.AI key missing - GLM-5.1 will be skipped"
fi

echo ""
ok "Ready: ${BENCH_DIR}/opus-bench"
printf "  ${D}Run: ${BENCH_DIR}/opus-bench --fast${N}\n\n"
