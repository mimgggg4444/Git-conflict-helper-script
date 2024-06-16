#!/bin/bash

# 로컬 모드가 설정되어 있는지 확인하는 함수
local_present() {
  test -n "$local_mode"
}

# 원격 모드가 설정되어 있는지 확인하는 함수
remote_present() {
  test -n "$remote_mode"
}

# 베이스 모드가 설정되어 있는지 확인하는 함수
base_present() {
  test -n "$base_mode"
}

# 임시 파일을 정리하는 함수
cleanup_temp_files() {
  if test "$1" = --save-backup; then
    rm -rf -- "$MERGED.orig"
    test -e "$BACKUP" && mv -- "$BACKUP" "$MERGED.orig"
    rm -f -- "$LOCAL" "$REMOTE" "$BASE"
  else
    rm -f -- "$LOCAL" "$REMOTE" "$BASE" "$BACKUP"
  fi
}

# 주어진 파일의 상태를 설명하는 함수
describe_file() {
  mode="$1"
  branch="$2"
  file="$3"
  printf " {%s}: " "$branch"
  if test -z "$mode"; then
    echo "deleted"
  elif is_symlink "$mode"; then
    echo "a symbolic link -> '$(cat "$file")'"
  elif is_submodule "$mode"; then
    echo "submodule commit $file"
  else
    if base_present; then
      echo "modified"
    else
      echo "created"
    fi
  fi
}

# 사용 예시
local_mode="local"
remote_mode="remote"
base_mode="base"
MERGED="merged.txt"
BACKUP="backup.txt"
LOCAL="local.txt"
REMOTE="remote.txt"
BASE="base.txt"

echo "Checking file states:"
describe_file "$local_mode" "local" "$LOCAL"
describe_file "$remote_mode" "remote" "$REMOTE"
describe_file "$base_mode" "base" "$BASE"

echo "Cleaning up temporary files:"
cleanup_temp_files --save-backup
