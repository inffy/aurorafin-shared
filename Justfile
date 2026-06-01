just := just_executable()

# Check the syntax of all Justfiles in the repository
check:
    #!/usr/bin/bash
    find . -type f -name "*.just" | while read -r file; do
      echo "Checking syntax: $file"
      {{ just }} --fmt --check -f $file
    done
    echo "Checking syntax: Justfile"
    {{ just }} --fmt --check -f Justfile

# Fix the Just formatting
fix:
    #!/usr/bin/bash
    find . -type f -name "*.just" | while read -r file; do
      echo "Fixing syntax: $file"
      {{ just }} --fmt -f $file
    done
    echo "Fixing syntax: Justfile"
    {{ just }} --fmt -f Justfile || { exit 1; }

# Runs shell check on all Bash scripts
shell-lint dir="system_files":
    #!/usr/bin/env bash
    set -eoux pipefail
    # Check if shellcheck is installed
    if ! command -v shellcheck &> /dev/null; then
        echo "shellcheck could not be found. Please install it."
        exit 1
    fi
    # Run shellcheck on all Bash scripts
    /usr/bin/find {{ dir }} -type d -name ".*" -prune -o -type f \( -name "*.sh" -o -exec sh -c 'head -n 1 "$1" | grep -qE "^#!(.*/bin/(bash|sh|zsh)|/usr/bin/env (bash|sh|zsh))"' _ {} \; \) -exec shellcheck {} +

# Runs shfmt on all Bash scripts
shell-format:
    #!/usr/bin/env bash
    set -eoux pipefail
    # Check if shfmt is installed
    if ! command -v shfmt &> /dev/null; then
        echo "shfmt could not be found. Please install it."
        exit 1
    fi
    # Run shfmt on all Bash scripts
    /usr/bin/find . -iname "*.sh" -type f -exec shfmt --write "{}" ';'

# Validate Brewfiles
brew-lint dir="system_files/shared/usr/share/ublue-os/homebrew":
    #!/usr/bin/env bash
    set -eoux pipefail

    STATUS_FILE=$(mktemp)
    echo "PASS" > "$STATUS_FILE"

    while IFS= read -r -d '' brewfile ; do
      echo "::group:: ===$(basename $brewfile)==="

      grep -E -e "^tap" "$brewfile" > taps.Brewfile || true
      echo "Syncing taps..."
      brew bundle --file=./taps.Brewfile > /dev/null 2>&1 || true

      # Extract combined list for parallel check
      FORMULAS=$(grep -E '^\s*brew\s+["'\'']' "$brewfile" | sed -E 's/^\s*brew\s+["'\'']([^"'\'']+)["'\''].*/formula \1/' || true)
      CASKS=$(grep -E '^\s*cask\s+["'\'']' "$brewfile" | sed -E 's/^\s*cask\s+["'\'']([^"'\'']+)["'\''].*/cask \1/' || true)

      ENTRIES=$(printf "%s\n%s" "$FORMULAS" "$CASKS" | grep -v '^\s*$' || true)

      if [ -n "$ENTRIES" ]; then
        echo "$ENTRIES" | xargs -P 8 -I {} bash -c '
          TYPE=$(echo "{}" | cut -d" " -f1)
          NAME=$(echo "{}" | cut -d" " -f2)
          if ! brew info --$TYPE "$NAME" &> /dev/null; then
            echo "✗ $TYPE \"$NAME\" is invalid or missing tap"
            echo "FAIL" >> "'"$STATUS_FILE"'"
          else
            echo "✓ $TYPE \"$NAME\" is valid"
          fi
        '
      else
        echo "No formulas or casks found."
      fi

      echo "::endgroup::"
    done < <(find "{{ dir }}" -iname '*\.Brewfile*' -print0)

    rm -f taps.Brewfile

    if grep -q "FAIL" "$STATUS_FILE"; then
      echo "Validation complete. Some Brewfiles FAILED."
      exit 1
    else
      echo "Validation complete. All Brewfiles PASSED."
      exit 0
    fi
