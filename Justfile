[parallel]
dev: dev-client

dev-client:
  @just -f client/Justfile dev

dev-desktop:
  @just -f desktop/Justfile dev

gleam-deps-update:
  cd client && gleam deps update
