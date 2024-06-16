#!/bin/bash

# 파일 상태를 나타내는 상수
DELETED=0
MODIFIED=1
CREATED=2
SYMLINK=3
SUBMODULE=4

# 파일 상태를 확인하는 함수
get_file_state() {
  local file="$1"
  if ! test -e "$file"; then
    echo $DELETED
  elif test -L "$file"; then
    echo $SYMLINK
  elif test -d "$file/.git"; then
    echo $SUBMODULE
  elif test -e "$BACKUP/$file"; then
    echo $MODIFIED
  else
    echo $CREATED
  fi
}

# 파일 상태에 따라 적절한 작업을 수행하는 함수
handle_file_state() {
  local state="$1"
  local file="$2"
  case $state in
    $DELETED)
      git rm --cached "$file" >/dev/null 2>&1
      ;;
    $MODIFIED)
      git checkout --ours -- "$file"
      git add "$file"
      ;;
    $CREATED)
      git add "$file"
      ;;
    $SYMLINK)
      git rm --cached "$file" >/dev/null 2>&1
      git add "$file"
      ;;
    $SUBMODULE)
      git submodule update --init --recursive "$file"
      ;;
  esac
}

# 백업 디렉토리 생성
backup_dir() {
  local backup_dir="$1"
  mkdir -p "$backup_dir"
  for file in $(git ls-files -u | cut -f2 | sort -u); do
    cp --parents -r "$file" "$backup_dir"
  done
}

# 충돌 해결 함수
resolve_conflicts() {
  local backup_dir="$1"
  for file in $(git ls-files -u | cut -f2 | sort -u); do
    echo "Resolving conflict in $file"
    local state=$(get_file_state "$file")
    handle_file_state $state "$file"
  done
  git commit -m "Resolved conflicts"
  rm -rf "$backup_dir"
}

# 사용 예시
BACKUP_DIR=".backup_$(date +%Y%m%d_%H%M%S)"

echo "Backing up conflicted files..."
backup_dir "$BACKUP_DIR"

echo "Resolving conflicts..."
resolve_conflicts "$BACKUP_DIR"

echo "Conflict resolution completed successfully!"
