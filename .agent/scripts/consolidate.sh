#!/usr/bin/env bash
# ============================================================
# FILE: scripts/consolidate.sh
# PURPOSE: Periodic structure optimisation review and proposals
# DEPENDS ON: All project files, .agent/memory/CONTEXT.md
# DEPENDED ON BY: Maintainer agents (R-05), health-check.sh
# USAGE: bash scripts/consolidate.sh [--report-only]
# RUN: Every 5 agent sessions (tracked in CONTEXT.md)
# ============================================================

set -euo pipefail

RED='\033[0;31m'; YELLOW='\033[1;33m'; GREEN='\033[0;32m'
BLUE='\033[0;34m'; CYAN='\033[0;36m'; BOLD='\033[1m'; NC='\033[0m'

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

echo -e "${BOLD}${CYAN}"
echo "╔═══════════════════════════════════════════════════╗"
echo "║    ♻️  STRUCTURE CONSOLIDATION REVIEW              ║"
echo "╠═══════════════════════════════════════════════════╣"
echo "║  $(date '+%Y-%m-%d %H:%M:%S')                              ║"
echo "╚═══════════════════════════════════════════════════╝${NC}"
echo ""

ISSUES=0; PROPOSALS=()

# ── [1] Duplicate file detection ─────────────────────────────
echo -e "${BOLD}[1/5] 🔍 Duplicate File Detection${NC}"
echo "$(printf '─%.0s' {1..50})"
if command -v md5sum &>/dev/null || command -v md5 &>/dev/null; then
  HASH_CMD="md5sum"
  command -v md5 &>/dev/null && HASH_CMD="md5 -r"
  
  DUPES=$(find . -not -path './.git/*' -type f -exec $HASH_CMD {} \; 2>/dev/null | \
    sort | awk 'BEGIN{p=""} {if($1==p){print $2} p=$1}' | head -20)
  
  if [[ -z "$DUPES" ]]; then
    echo -e "${GREEN}✅ No duplicate files detected${NC}"
  else
    echo -e "${YELLOW}🟡 Potential duplicate files:${NC}"
    echo "$DUPES" | while read -r f; do echo "   → $f"; done
    ((ISSUES++))
    PROPOSALS+=("Review and remove duplicate files listed above")
  fi
else
  echo -e "${BLUE}ℹ️ md5sum not available — skipping duplicate check${NC}"
fi

# ── [2] Large file detection ─────────────────────────────────
echo ""
echo -e "${BOLD}[2/5] 📏 Large File Detection (>50KB)${NC}"
echo "$(printf '─%.0s' {1..50})"
LARGE_FILES=$(find . -not -path './.git/*' -type f -size +50k 2>/dev/null | head -20)
if [[ -z "$LARGE_FILES" ]]; then
  echo -e "${GREEN}✅ No unexpectedly large files${NC}"
else
  echo -e "${YELLOW}🟡 Large files detected (may need splitting or gitignore):${NC}"
  echo "$LARGE_FILES" | while read -r f; do
    SIZE=$(du -sh "$f" | cut -f1)
    echo "   → $f ($SIZE)"
  done
  ((ISSUES++))
  PROPOSALS+=("Review large files — consider splitting or adding to .gitignore")
fi

# ── [3] Empty directories ────────────────────────────────────
echo ""
echo -e "${BOLD}[3/5] 📁 Empty Directory Check${NC}"
echo "$(printf '─%.0s' {1..50})"
EMPTY_DIRS=$(find . -not -path './.git/*' -type d -empty 2>/dev/null | \
  grep -v "^.$" | grep -v "node_modules" | head -20)
if [[ -z "$EMPTY_DIRS" ]]; then
  echo -e "${GREEN}✅ No empty directories${NC}"
else
  echo -e "${YELLOW}🟡 Empty directories (add .gitkeep or remove):${NC}"
  echo "$EMPTY_DIRS" | while read -r d; do echo "   → $d"; done
  ((ISSUES++))
  PROPOSALS+=("Add .gitkeep to empty directories or remove them")
fi

# ── [4] Orphaned docs check ──────────────────────────────────
echo ""
echo -e "${BOLD}[4/5] 📚 Documentation Sync Check${NC}"
echo "$(printf '─%.0s' {1..50})"
REQUIRED_DOCS=("docs/CHANGELOG.md" "docs/DEPENDENCIES.md" "docs/TESTS.md" "docs/ARCHITECTURE.md" "docs/SOURCES.md")
ALL_GOOD=true
for doc in "${REQUIRED_DOCS[@]}"; do
  if [[ -f "$doc" ]]; then
    # Check last modified vs git log
    LAST_GIT=$(git log -1 --format="%ci" -- "$doc" 2>/dev/null | cut -d' ' -f1 || echo "unknown")
    echo -e "  ${GREEN}✅ $doc${NC} (last commit: $LAST_GIT)"
  else
    echo -e "  ${RED}❌ MISSING: $doc${NC}"
    ALL_GOOD=false
    ((ISSUES++))
    PROPOSALS+=("Recreate missing documentation file: $doc")
  fi
done

# ── [5] Session counter for consolidation ────────────────────
echo ""
echo -e "${BOLD}[5/5] 🔄 Consolidation Session Counter Update${NC}"
echo "$(printf '─%.0s' {1..50})"
CONTEXT_FILE=".agent/memory/CONTEXT.md"
if [[ -f "$CONTEXT_FILE" ]]; then
  CURRENT=$(grep -o "Sessions Since Last Consolidation Review.*" "$CONTEXT_FILE" | grep -o '[0-9]*' | head -1 || echo "0")
  echo -e "${BLUE}ℹ️ Previous count: $CURRENT${NC}"
  if [[ "${1:-}" != "--report-only" ]]; then
    sed -i.bak "s/Sessions Since Last Consolidation Review.*/Sessions Since Last Consolidation Review | 0/" "$CONTEXT_FILE" && rm -f "${CONTEXT_FILE}.bak"
    echo -e "${GREEN}✅ Reset consolidation counter to 0 in CONTEXT.md${NC}"
  else
    echo -e "${BLUE}ℹ️ Report-only mode — counter not reset${NC}"
  fi
fi

# ── Summary ──────────────────────────────────────────────────
echo ""
echo -e "${BOLD}${CYAN}╔═══════════════════════════════════════════════════╗${NC}"
echo -e "${BOLD}${CYAN}║             CONSOLIDATION SUMMARY                 ║${NC}"
echo -e "${BOLD}${CYAN}╠═══════════════════════════════════════════════════╣${NC}"
echo -e "${BOLD}${CYAN}║${NC}  Issues Found: $ISSUES$(printf '%*s' $((37 - ${#ISSUES})) '')${BOLD}${CYAN}║${NC}"
echo -e "${BOLD}${CYAN}╠═══════════════════════════════════════════════════╣${NC}"

if [[ ${#PROPOSALS[@]} -gt 0 ]]; then
  echo -e "${BOLD}${CYAN}║${NC}  📋 Proposals:$(printf '%*s' 37 '')${BOLD}${CYAN}║${NC}"
  for p in "${PROPOSALS[@]}"; do
    SHORT="${p:0:49}"
    echo -e "${BOLD}${CYAN}║${NC}  • ${YELLOW}$SHORT${NC}$(printf '%*s' $((49 - ${#SHORT})) '')${BOLD}${CYAN}║${NC}"
  done
fi

echo -e "${BOLD}${CYAN}╚═══════════════════════════════════════════════════╝${NC}"

if [[ $ISSUES -eq 0 ]]; then
  echo -e "\n${GREEN}${BOLD}🟢 Project structure is well-optimised!${NC}"
else
  echo -e "\n${YELLOW}${BOLD}🟡 Review proposals above. Implement changes in dev branch.${NC}"
  echo -e "${YELLOW}Document changes in docs/CHANGELOG.md and .agent/memory/DECISIONS.md${NC}"
fi
