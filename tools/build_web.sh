#!/usr/bin/env bash
# Exporta o jogo para a web e atualiza site/play (o que a Vercel publica).
# Uso: GODOT=/caminho/do/godot tools/build_web.sh
set -euo pipefail
cd "$(dirname "$0")/.."
GODOT="${GODOT:-godot}"
mkdir -p build/web
"$GODOT" --headless --editor --quit >/dev/null 2>&1 || true
"$GODOT" --headless --export-release "Web" build/web/index.html
rm -rf site/play && mkdir -p site/play
cp build/web/index.{html,js,wasm,pck,png,icon.png,apple-touch-icon.png,audio.worklet.js} site/play/
echo "site/play atualizado:" && ls -la site/play
