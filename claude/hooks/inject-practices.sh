#!/usr/bin/env bash
set -e

INPUT=$(cat)
CWD=$(echo "$INPUT" | jq -r '.cwd // empty')
[ -z "$CWD" ] && CWD="."

GLOBAL_DIR="$HOME/.claude/practices"
GLOBAL_INDEX="$GLOBAL_DIR/INDEX.md"
LOCAL_DIR="$CWD/.practices"
LOCAL_INDEX="$LOCAL_DIR/INDEX.md"

INJECTED=""
FALLBACK=""
SEEN_FILES=""

process_index() {
  local index_file="$1"
  local base_dir="$2"
  local source_label="$3"

  [ ! -f "$index_file" ] && return 0

  while IFS='|' read -r _ practice file _ detect _; do
    practice=$(echo "$practice" | xargs)
    file=$(echo "$file" | xargs | tr -d '`')
    detect=$(echo "$detect" | xargs)

    [ -z "$file" ] && continue
    [ ! -f "$base_dir/$file" ] && continue

    # Local is processed first; skip if filename already seen (local overrides global).
    case " $SEEN_FILES " in
      *" $file "*) continue ;;
    esac
    SEEN_FILES="$SEEN_FILES $file"

    matched=false

    if [ "$detect" = "always" ]; then
      matched=true

    elif [ -z "$detect" ]; then
      FALLBACK="${FALLBACK}\n- ${practice} (${source_label}:${file})"
      continue

    else
      IFS=',' read -ra RULES <<< "$detect"
      for rule in "${RULES[@]}"; do
        rule=$(echo "$rule" | xargs)

        if [[ "$rule" == *:* ]]; then
          CHECK_FILE="${rule%%:*}"
          CHECK_STRING="${rule#*:}"
          if [ -f "$CWD/$CHECK_FILE" ] && grep -q "$CHECK_STRING" "$CWD/$CHECK_FILE" 2>/dev/null; then
            matched=true
            break
          fi

        elif [[ "$rule" == *\** ]]; then
          if compgen -G "$CWD/$rule" > /dev/null 2>&1; then
            matched=true
            break
          fi

        else
          if [ -f "$CWD/$rule" ]; then
            matched=true
            break
          fi
        fi
      done
    fi

    if [ "$matched" = true ]; then
      INJECTED="$INJECTED
--- [${source_label}] ${practice} (${file}) ---
$(cat "$base_dir/$file")"
    fi

  done < <(grep '^|' "$index_file" | tail -n +3)
}

# Local first so it wins on filename clash with global.
process_index "$LOCAL_INDEX" "$LOCAL_DIR" "local"
process_index "$GLOBAL_INDEX" "$GLOBAL_DIR" "global"

CONTENT=""

if [ -n "$INJECTED" ]; then
  CONTENT="ACTIVE PRACTICES (auto-detected):
$INJECTED"
fi

if [ -n "$FALLBACK" ]; then
  CONTENT="$CONTENT

Additional practices available if relevant (not auto-detected):$(echo -e "$FALLBACK")
Review and apply if they match this project."
fi

if [ -n "$CONTENT" ]; then
  jq -n --arg ctx "$CONTENT" '{"additionalContext": $ctx}'
fi

exit 0
