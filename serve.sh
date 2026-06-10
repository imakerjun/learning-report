#!/usr/bin/env bash
# learning-report 정적 서버 — 빌드/설치 없음
set -e
PORT="${1:-8080}"
echo "📊 learning-report → http://localhost:${PORT}"
echo "   (종료: Ctrl+C)"
python3 -m http.server "${PORT}"
