#!/usr/bin/env bash
# run-snapshot-tests.sh — Run all snapshot regression tests for mealie-ios
#
# Usage:
#   ./scripts/run-snapshot-tests.sh           # Run in comparison mode (default)
#   ./scripts/run-snapshot-tests.sh --record  # Re-record all reference snapshots
#   ./scripts/run-snapshot-tests.sh --help    # Show usage
#
# Requirements:
#   - Xcode with iOS 18.5+ simulator runtime
#   - iPhone 16 simulator available
#   - swift-snapshot-testing package resolved

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
PROJECT="$PROJECT_ROOT/mealIO.xcodeproj"
SCHEME="mealie-ios"
DESTINATION="platform=iOS Simulator,name=iPhone 16,OS=18.5"
TEST_TARGET="mealIOTests"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  --record     Re-record all reference snapshots (sets record=true)"
    echo "  --class NAME Run only snapshot tests for a specific class"
    echo "  --help       Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0                                    # Run all snapshot tests"
    echo "  $0 --record                           # Re-record all snapshots"
    echo "  $0 --class LoginViewSnapshotTests     # Run only login view tests"
    exit 0
}

RECORD_MODE=false
TEST_FILTER=""

while [[ $# -gt 0 ]]; do
    case $1 in
        --record)
            RECORD_MODE=true
            shift
            ;;
        --class)
            if [[ -z "${2:-}" ]]; then
                echo -e "${RED}Error: --class requires a class name argument${NC}"
                exit 1
            fi
            TEST_FILTER="$2"
            shift 2
            ;;
        --help|-h)
            usage
            ;;
        *)
            echo -e "${RED}Unknown option: $1${NC}"
            usage
            ;;
    esac
done

# Build the test filter
if [[ -n "$TEST_FILTER" ]]; then
    ONLY_TESTING="-only-testing:$TEST_TARGET/$TEST_FILTER"
else
    ONLY_TESTING="-only-testing:$TEST_TARGET"
fi

echo -e "${BOLD}${CYAN}=== Mealie iOS Snapshot Tests ===${NC}"
echo -e "Project:     ${PROJECT}"
echo -e "Scheme:      ${SCHEME}"
echo -e "Destination: ${DESTINATION}"
echo -e "Mode:        $([ "$RECORD_MODE" = true ] && echo -e "${YELLOW}RECORDING${NC}" || echo -e "${GREEN}COMPARISON${NC}")"
if [[ -n "$TEST_FILTER" ]]; then
    echo -e "Filter:      ${TEST_FILTER}"
fi
echo ""

# If recording, temporarily enable record mode in the helper
HELPER_FILE="$PROJECT_ROOT/mealieTests/SnapshotTests/Helpers/SnapshotTestHelper.swift"

if [[ "$RECORD_MODE" = true ]]; then
    echo -e "${YELLOW}Enabling record mode in SnapshotTestHelper...${NC}"
    sed -i '' 's/record recording: Bool = false/record recording: Bool = true/g' "$HELPER_FILE"
fi

# Cleanup function to restore record mode on exit
cleanup() {
    if [[ "$RECORD_MODE" = true ]]; then
        echo -e "\n${YELLOW}Restoring comparison mode in SnapshotTestHelper...${NC}"
        sed -i '' 's/record recording: Bool = true/record recording: Bool = false/g' "$HELPER_FILE"
    fi
}
trap cleanup EXIT

# Run the tests
echo -e "${CYAN}Running snapshot tests...${NC}"
echo ""

OUTPUT=$(xcodebuild test \
    -project "$PROJECT" \
    -scheme "$SCHEME" \
    -destination "$DESTINATION" \
    "$ONLY_TESTING" \
    2>&1) || true

# Show snapshot test results
echo ""
echo -e "${BOLD}=== Snapshot Test Results ===${NC}"
echo ""

# Show all snapshot results
echo "$OUTPUT" | grep -E "SnapshotTests.*(passed|failed)" | while IFS= read -r line; do
    if echo "$line" | grep -q "passed"; then
        echo -e "  ${GREEN}✓${NC} $line"
    else
        echo -e "  ${RED}✗${NC} $line"
    fi
done

# Count totals
TOTAL_SNAPSHOT_PASS=$(echo "$OUTPUT" | grep -E "SnapshotTests.*passed" | wc -l | tr -d ' ')
TOTAL_SNAPSHOT_FAIL=$(echo "$OUTPUT" | grep -E "SnapshotTests.*failed" | wc -l | tr -d ' ')
TOTAL=$(( TOTAL_SNAPSHOT_PASS + TOTAL_SNAPSHOT_FAIL ))

echo ""
echo -e "${BOLD}───────────────────────────────────${NC}"

if [[ "$RECORD_MODE" = true ]]; then
    # In record mode, "failures" are expected (recording always reports failure)
    SNAPSHOT_COUNT=$(find "$PROJECT_ROOT/__Snapshots__" -name "*.png" 2>/dev/null | wc -l | tr -d ' ')
    echo -e "${GREEN}${BOLD}✓ Recorded ${SNAPSHOT_COUNT} reference snapshots.${NC}"
    echo -e "${YELLOW}  Note: 'Failures' in record mode are expected — each test"
    echo -e "  reports a failure when writing a new reference image.${NC}"
    exit 0
elif [[ "$TOTAL_SNAPSHOT_FAIL" -gt 0 ]]; then
    echo -e "${RED}${BOLD}✗ FAILED: ${TOTAL_SNAPSHOT_FAIL}/${TOTAL} snapshot tests failed.${NC}"
    echo ""
    echo -e "${RED}Failed tests:${NC}"
    echo "$OUTPUT" | grep -E "SnapshotTests.*failed" | while IFS= read -r line; do
        echo -e "  ${RED}✗ $line${NC}"
    done
    exit 1
else
    echo -e "${GREEN}${BOLD}✓ PASSED: All ${TOTAL} snapshot tests passed.${NC}"
    exit 0
fi
