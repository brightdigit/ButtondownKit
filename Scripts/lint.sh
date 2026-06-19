#!/bin/bash

# Remove set -e to allow script to continue running
# set -e  # Exit on any error

ERRORS=0

run_command() {
	"$@" || ERRORS=$((ERRORS + 1))
}

if [ "$LINT_MODE" = "INSTALL" ]; then
	exit
fi

echo "LintMode: $LINT_MODE"

# More portable way to get script directory
if [ -z "$SRCROOT" ]; then
	SCRIPT_DIR=$(dirname "$(readlink -f "$0")")
	PACKAGE_DIR="${SCRIPT_DIR}/.."
else
	PACKAGE_DIR="${SRCROOT}"
fi

# Detect if mise is available
# Check common installation paths for mise
MISE_PATHS=(
    "/opt/homebrew/bin/mise"
    "/usr/local/bin/mise"
    "$HOME/.local/bin/mise"
)

MISE_BIN=""
for mise_path in "${MISE_PATHS[@]}"; do
    if [ -x "$mise_path" ]; then
        MISE_BIN="$mise_path"
        break
    fi
done

# Fallback to PATH lookup
if [ -z "$MISE_BIN" ] && command -v mise &> /dev/null; then
    MISE_BIN="mise"
fi

if [ -n "$MISE_BIN" ]; then
    TOOL_CMD="$MISE_BIN exec --"
else
    echo "Error: mise is not installed"
    echo "Install mise: https://mise.jdx.dev/getting-started.html"
    echo "Checked paths: ${MISE_PATHS[*]}"
    exit 1
fi

if [ "$LINT_MODE" = "NONE" ]; then
	exit
elif [ "$LINT_MODE" = "STRICT" ]; then
	SWIFTFORMAT_LINT_OPTIONS="--strict"
	SWIFTLINT_OPTIONS="--strict"
else
	SWIFTFORMAT_LINT_OPTIONS=""
	SWIFTLINT_OPTIONS=""
fi

pushd $PACKAGE_DIR

# swift-format has no path-exclude config, so enumerate the hand-written Swift
# files only — pruning the committed swift-openapi-generator output under
# Sources/ButtondownKit/Generated, which is never linted or formatted.
# SwiftLint excludes that directory via .swiftlint.yml. Built portably (no
# `mapfile`, which is unavailable on the macOS-default bash 3.2).
SWIFT_FILES=()
while IFS= read -r swift_file; do
	SWIFT_FILES+=("$swift_file")
done < <(find Sources Tests -name '*.swift' -not -path '*/Generated/*')

# Bootstrap tools (mise will install based on .mise.toml)
run_command "$MISE_BIN" install

if [ -z "$CI" ]; then
	run_command $TOOL_CMD swift-format format --configuration .swift-format --parallel --in-place "${SWIFT_FILES[@]}"
	run_command $TOOL_CMD swiftlint --fix
fi

if [ -z "$FORMAT_ONLY" ]; then
	run_command $TOOL_CMD swift-format lint --configuration .swift-format --parallel $SWIFTFORMAT_LINT_OPTIONS "${SWIFT_FILES[@]}"
	run_command $TOOL_CMD swiftlint lint $SWIFTLINT_OPTIONS
	# Check for compilation errors
	run_command swift build --build-tests
fi

# header.sh rewrites file headers in place, so it only runs locally — never in CI.
# (It already skips files under a Generated/ directory.)
if [ -z "$CI" ]; then
	$PACKAGE_DIR/Scripts/header.sh -d $PACKAGE_DIR/Sources -c "Leo Dion" -o "BrightDigit" -p "ButtondownKit"
fi

if [ -z "$CI" ]; then
	run_command $TOOL_CMD periphery scan $PERIPHERY_OPTIONS --disable-update-check
fi

popd

# Exit with error code if any errors occurred
if [ $ERRORS -gt 0 ]; then
	echo "Linting completed with $ERRORS error(s)"
	exit 1
else
	echo "Linting completed successfully"
	exit 0
fi
