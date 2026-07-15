# Testing Standards

- **Unit Tests:** Mandatory for all business logic, residing in the same module (`mod tests`).
- **Integration Tests:** Required for component interactions in `tests/` directory.
- **Fuzz Testing:** Essential for security-critical components (parsers, cryptographic operations).
- **CI/CD:** Tests must pass in CI/CD pipeline before any merge.
EOF
