.PHONY: help build run check fmt clippy appimage appimage-install \
        install install-langs uninstall test-docker clean release \
        test-makefile test-makefile-rust test-act test-act-ci test-act-release

# Default target
help:
	@echo "RustyLens — developer task shortcuts"
	@echo ""
	@echo "  make build           cargo build --release"
	@echo "  make run             build and run the GUI"
	@echo "  make check           cargo check (fast type check)"
	@echo "  make fmt             cargo fmt"
	@echo "  make clippy          cargo clippy"
	@echo ""
	@echo "  make appimage        build RustyLens-x86_64.AppImage"
	@echo "  make appimage-install build AppImage and install to ~/.local/bin"
	@echo ""
	@echo "  make install         install AppImage + English tessdata to ~/.local"
	@echo "  make install-langs   install additional tessdata (set LANGS=eng+fra+...)"
	@echo "  make uninstall       remove installed files"
	@echo ""
	@echo "  make test-docker     run full Docker test suite (install + build + Makefile)"
	@echo "  make test-makefile   run Makefile targets test only (Docker, all distros)"
	@echo "  make test-makefile-rust  also test Rust targets on ubuntu (slow)"
	@echo "  make test-act        run CI + release workflows locally via act"
	@echo "  make test-act-ci     run CI workflow only via act"
	@echo "  make test-act-release  run release linux jobs via act (slow)"
	@echo "  make clean           remove build artefacts"
	@echo "  make release         build release binary"

# ── Rust build targets ──────────────────────────────────────────────────────

build:
	cargo build --release

run: build
	./target/release/rustylens

check:
	cargo check

fmt:
	cargo fmt

clippy:
	cargo clippy

# ── AppImage targets ────────────────────────────────────────────────────────

appimage:
	./build-appimage.sh

appimage-install:
	./build-appimage.sh --install

# ── Install targets ─────────────────────────────────────────────────────────

# Default language pack; override with: make install LANGS=eng+fra+jpn
LANGS ?= minimal

install:
	./install.sh --$(LANGS)

install-langs:
	@if [ -z "$(LANGS)" ] || [ "$(LANGS)" = "minimal" ]; then \
		./install.sh --minimal; \
	else \
		./install.sh --langs "$(LANGS)"; \
	fi

uninstall:
	./install.sh --uninstall

# ── Testing ─────────────────────────────────────────────────────────────────

test-docker:
	./local-scripts/test-install.sh
	./local-scripts/test-build-appimage.sh
	./local-scripts/test-makefile.sh

test-makefile:
	./local-scripts/test-makefile.sh

test-makefile-rust:
	./local-scripts/test-makefile.sh --rust

test-act:
	./local-scripts/test-act.sh --no-flatpak

test-act-ci:
	./local-scripts/test-act.sh --ci

test-act-release:
	./local-scripts/test-act.sh --release --no-flatpak

# ── Maintenance ─────────────────────────────────────────────────────────────

clean:
	-cargo clean
	rm -rf AppDir build-dir _runtime.elf _app.squashfs
	rm -f RustyLens-*.AppImage

release: build
	@echo "Binary: target/release/rustylens"
	@echo "Set version in Cargo.toml, CHANGELOG.md and data/*.metainfo.xml, then:"
	@echo "  git add -A && git commit -m 'release: vX.Y.Z' && git tag -a vX.Y.Z -m 'vX.Y.Z'"
