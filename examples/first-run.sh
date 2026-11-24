#!/bin/sh
set -eu
cd "$(dirname "$0")/.."
./bunker up
./bunker pull llama3.2:3b
./bunker pull nomic-embed-text
./bunker check
docker compose exec -T ollama ollama run llama3.2:3b "Reply with one word: are you running locally?"
