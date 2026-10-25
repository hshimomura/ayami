#!/bin/zsh
set -euo pipefail

SCRIPT_DIR="${0:A:h}"
PROJECT_ROOT="${SCRIPT_DIR:h}"
FIXTURE_ROOT="/private/tmp/ayami-1.4-quicklook-public"
FIXTURE_SOURCE="$PROJECT_ROOT/Tests/AyamiMacUITests/Fixtures/PublicSample14.md"

# The UI runner cannot read Documents without a separate TCC grant. These
# public fixtures contain no user data and live outside protected containers.
for directory in "$FIXTURE_ROOT" "$FIXTURE_ROOT/markdown" "$FIXTURE_ROOT/control"; do
  if [[ -e "$directory" || -L "$directory" ]]; then
    [[ -d "$directory" && ! -L "$directory" && "$(stat -f %u "$directory")" == "$EUID" ]] || {
      print -u2 "Refusing to use an unowned or linked fixture directory: $directory"
      exit 1
    }
  else
    mkdir "$directory"
  fi
done

for destination in "$FIXTURE_ROOT/markdown/PublicSample14.md" "$FIXTURE_ROOT/control/PublicSample14.ayamiqltest"; do
  if [[ -e "$destination" || -L "$destination" ]]; then
    [[ -f "$destination" && ! -L "$destination" && "$(stat -f %u "$destination")" == "$EUID" ]] || exit 1
    cmp -s "$FIXTURE_SOURCE" "$destination" || {
      print -u2 "Existing fixture differs; nothing was overwritten: $destination"
      exit 1
    }
  else
    cp -n "$FIXTURE_SOURCE" "$destination"
  fi
done
print "Public Quick Look fixtures ready: $FIXTURE_ROOT"
