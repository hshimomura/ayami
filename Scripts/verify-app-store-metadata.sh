#!/bin/zsh
set -euo pipefail

export LC_ALL=en_US.UTF-8

SCRIPT_DIR="${0:A:h}"
PROJECT_ROOT="${SCRIPT_DIR:h}"
METADATA_ROOT="${1:-$PROJECT_ROOT/AppStore/metadata}"

typeset -A limits
limits=(
    name 30
    subtitle 30
    promotional-text 170
    keywords 100
    description 4000
    whats-new 4000
)

typeset -a locales fields
locales=(en-US ja)
fields=(name subtitle promotional-text keywords description whats-new)

for locale in "$locales[@]"; do
    for field in "$fields[@]"; do
        file_path="$METADATA_ROOT/$locale/$field.txt"

        if [[ ! -f "$file_path" ]]; then
            print -u2 "Missing metadata file: $file_path"
            exit 1
        fi

        content="$(<"$file_path")"
        character_count="${#content}"
        maximum="${limits[$field]}"

        if (( character_count == 0 )); then
            print -u2 "Metadata must not be empty: $file_path"
            exit 1
        fi

        if (( character_count > maximum )); then
            print -u2 \
                "$locale/$field exceeds $maximum characters: $character_count"
            exit 1
        fi

        print "$locale/$field: $character_count/$maximum"
    done
done

for locale in "$locales[@]"; do
    for field in promotional-text description whats-new; do
        file_path="$METADATA_ROOT/ios/$locale/$field.txt"
        [[ -f "$file_path" ]] || { print -u2 "Missing metadata file: $file_path"; exit 1; }
        content="$(<"$file_path")"
        character_count="${#content}"
        maximum="${limits[$field]}"
        (( character_count > 0 && character_count <= maximum )) || {
            print -u2 "Invalid iOS metadata length: $locale/$field ($character_count/$maximum)"
            exit 1
        }
        print "ios/$locale/$field: $character_count/$maximum"
    done
done

print "Verified App Store metadata character limits for en-US and ja."
