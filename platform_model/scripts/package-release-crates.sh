#!/bin/sh
set -eu

root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd -P)
mode=${1:-}

prepare() {
    destination=$1
    test ! -e "$destination"
    mkdir -p "$destination/lean4-prod" "$destination/stdlib" "$destination/packages"

    cp -a "$root/vendor/lean4-prod/rust/." "$destination/lean4-prod/"
    cp -a "$root/stdlib/generated/package/." "$destination/stdlib/"
    rm -rf "$destination/lean4-prod/target" "$destination/stdlib/target"

    mkdir -p "$destination/lean4-prod/.cargo"
    printf '[patch.crates-io]\nprod-ir = { path = "%s" }\n' \
        "$destination/lean4-prod/prod-ir" \
        > "$destination/lean4-prod/.cargo/config.toml"

    (
        cd "$destination/lean4-prod"
        CARGO_NET_OFFLINE=true cargo package --locked --offline --package prod-ir
        CARGO_NET_OFFLINE=true cargo package --locked --offline --package prod-codegen
    )
    (
        cd "$destination/stdlib"
        CARGO_NET_OFFLINE=true cargo package --locked --offline
    )

    cp "$destination/lean4-prod/target/package/prod-ir-0.1.0.crate" \
        "$destination/packages/prod-ir-0.1.0.crate"
    cp "$destination/lean4-prod/target/package/prod-codegen-0.1.0.crate" \
        "$destination/packages/prod-codegen-0.1.0.crate"
    cp "$destination/stdlib/target/package/prism-stdlib-0.2.0.crate" \
        "$destination/packages/prism-stdlib-0.2.0.crate"
}

case "$mode" in
    --prepare)
        test "$#" -eq 2
        prepare "$2"
        ;;
    --check)
        test "$#" -eq 1
        work=$(mktemp -d)
        trap 'rm -rf "$work"' EXIT HUP INT TERM
        stage="$work/release-crates"
        prepare "$stage"
        cmp "$stage/packages/prod-ir-0.1.0.crate" \
            "$root/vendor/lean4-prod/crates/prod-ir-0.1.0.crate"
        cmp "$stage/packages/prod-codegen-0.1.0.crate" \
            "$root/vendor/lean4-prod/crates/prod-codegen-0.1.0.crate"
        cmp "$stage/packages/prism-stdlib-0.2.0.crate" \
            "$root/stdlib/generated/prism-stdlib-0.2.0.crate"
        sha256sum "$stage/packages/"*.crate
        ;;
    *)
        printf 'usage: %s --check | --prepare DIRECTORY\n' "$0" >&2
        exit 64
        ;;
esac
