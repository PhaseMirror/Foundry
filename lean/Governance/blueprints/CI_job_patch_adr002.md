# CI job patch for `pnt-nightly.yml`

Add the following job **after** the existing `lean-teleportation-check` job:

```yaml
  lean-multiplicity-check:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: leanprover/lean-action@v1
        with:
          toolchain: '4.7.0'
          project-dir: Substrates/MandelbrotMultiplicity
          build-target: MandelbrotMultiplicity
          extra-args: "--warn-on-unfilled-sorry"
      - name: Verify no sorry/admit
        run: |
          ! grep -rE 'sorry|admit' Substrates/MandelbrotMultiplicity/*.lean \
            || (echo "Found unfilled sorry/admit" && exit 1)
```

Copy‑paste this snippet into `.github/workflows/pnt-nightly.yml`.
