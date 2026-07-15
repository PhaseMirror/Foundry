# Justfile Templates Library

This library collects 10 industry-standard Justfile patterns for teams that want a common command surface across projects. `just` is a command runner that stores recipes in a `justfile`, supports parameters, can load `.env` files, and can export variables to recipe environments, which makes it well suited for standardized project setup and repeatable developer workflows.[web:75][web:73]

## Core patterns

A team-standard Justfile works best when recipe names are short, descriptions are placed in comments directly above recipes, and environment handling is centralized with settings such as `set dotenv-load := true` and `set export := true`.[web:75][web:94] Recipe parameters use the form `deploy env="staging":` and can be interpolated as `{{env}}`, while parameters prefixed with `$` are exported as environment variables for the recipe body.[web:73][web:76]

`just` statically analyzes recipe and variable references before running, reports unknown recipes and circular dependencies before execution, and supports list/discovery workflows such as `just --list` and chooser-based selection, making it easier for teams to treat the Justfile as a self-documenting operations catalog.[web:75][web:86][web:91]

## Template index

| Template | Primary use | Key features |
|---|---|---|
| 01. Polyglot bootstrap | Team onboarding | Install, format, lint, test, ci |
| 02. Container orchestration | Docker / Compose workflows | Build, up, logs, shell, down |
| 03. Database migrations | Schema lifecycle | Migrate, rollback, seed, status |
| 04. Testing pipeline | Unit / integration / coverage | Fast local and CI entry points |
| 05. Python service | Virtualenv and app tasks | Sync, run, test, lint |
| 06. Node/TypeScript app | Frontend/backend JS projects | Install, dev, build, test |
| 07. Rust workspace | Cargo-based projects | Fmt, clippy, test, release |
| 08. Cloud deployment | Environment promotion | Plan, apply, deploy, smoke |
| 09. Monorepo operations | Workspace-wide orchestration | Filtered targets, package-scoped tasks |
| 10. Security and release | Audits and shipping | Scan, sbom, changelog, release |

## Parameter and environment conventions

The most portable pattern is to define shared variables once, load `.env`, and expose only a few explicit parameters on recipes that vary by environment or target. `just` supports environment functions and dotenv loading, so teams can standardize on a small set of variables like `PORT`, `IMAGE_NAME`, `DATABASE_URL`, `ENV`, and `TAG`.[web:75][web:94]

Example patterns:

```just
set dotenv-load := true
set export := true

port := env_var_or_default("PORT", "3000")
image := env_var_or_default("IMAGE_NAME", "acme/service")

serve host="127.0.0.1" port=port:
  app --host {{host}} --port {{port}}

deploy $env="staging" tag="latest":
  ./scripts/deploy.sh $env {{tag}}
```

In the example above, `{{port}}` is a standard Just interpolation, while `$env` is exported to the shell environment for the recipe body.[web:73][web:75]

## 01. Polyglot bootstrap

Use this for mixed-language repos that need one obvious entry point for setup, formatting, linting, tests, and CI.

```just
set dotenv-load := true

# Show available workflows
default:
  @just --list

# Install all project dependencies
install:
  uv sync
  npm ci
  cargo fetch

# Format codebase
fmt:
  cargo fmt --all
  npm run format
  uv run ruff format .

# Lint codebase
lint:
  cargo clippy --all-targets -- -D warnings
  npm run lint
  uv run ruff check .

# Run test suites
test:
  cargo test --workspace
  npm test
  uv run pytest -q

# Continuous integration entry point
ci: install fmt lint test
  @echo "CI complete"
```

## 02. Container orchestration

Use this for Docker or Docker Compose based development environments.

```just
set dotenv-load := true
project := env_var_or_default("COMPOSE_PROJECT_NAME", "appstack")

# Build images
build:
  docker compose -p {{project}} build

# Start services in background
up:
  docker compose -p {{project}} up -d

# Follow service logs
logs service="":
  docker compose -p {{project}} logs -f {{service}}

# Open a shell in a service container
shell service="app":
  docker compose -p {{project}} exec {{service}} sh

# Stop and remove services
down:
  docker compose -p {{project}} down --remove-orphans
```

## 03. Database migrations

Use this for schema changes with explicit migrate, rollback, seed, and status flows.

```just
set dotenv-load := true

# Apply latest migrations
migrate:
  alembic upgrade head

# Roll back one step
rollback revision="-1":
  alembic downgrade {{revision}}

# Create a named migration
new name:
  alembic revision --autogenerate -m "{{name}}"

# Seed development data
seed env="dev":
  python scripts/seed.py --env {{env}}

# Show migration status
status:
  alembic current
  alembic heads
```

## 04. Testing pipeline

Use this when a team needs local-fast checks plus slower integration and coverage workflows.

```just
set dotenv-load := true

# Fast unit tests
unit:
  pytest tests/unit -q

# Integration tests
integration:
  pytest tests/integration -q

# Coverage report
coverage:
  pytest --cov=src --cov-report=term-missing --cov-report=xml

# Watch tests during development
watch pattern="tests/unit":
  watchexec -r -e py -- pytest {{pattern}} -q

# Full validation gate
ci: unit integration coverage
  @echo "Testing pipeline complete"
```

## 05. Python service

Use this for Python APIs or workers with uv or virtualenv-driven workflows.

```just
set dotenv-load := true
port := env_var_or_default("PORT", "8000")

# Sync dependencies
sync:
  uv sync

# Run development server
run host="127.0.0.1" port=port: sync
  uv run uvicorn app.main:app --reload --host {{host}} --port {{port}}

# Test service
test: sync
  uv run pytest -q

# Lint and format
lint: sync
  uv run ruff check .
  uv run ruff format --check .
```

## 06. Node/TypeScript app

Use this for frontend apps, Next.js services, or Node-based APIs.

```just
set dotenv-load := true
port := env_var_or_default("PORT", "3000")
node_bin := "./node_modules/.bin"

# Install dependencies
install:
  npm ci

# Start dev server
dev port=port: install
  PORT={{port}} npm run dev

# Build application
build: install
  npm run build

# Run tests
test: install
  npm run test -- --passWithNoTests

# Lint project
lint: install
  npm run lint
```

## 07. Rust workspace

Use this for Rust libraries, binaries, or multi-crate workspaces.

```just
set dotenv-load := true
profile := env_var_or_default("PROFILE", "release")

# Format workspace
fmt:
  cargo fmt --all

# Lint workspace
lint:
  cargo clippy --workspace --all-targets -- -D warnings

# Test workspace
test:
  cargo test --workspace

# Build workspace
build profile=profile:
  cargo build --workspace --profile {{profile}}

# Publish dry run
release-check:
  cargo publish --dry-run
```

## 08. Cloud deployment

Use this for infrastructure planning, environment deployment, and smoke testing.

```just
set dotenv-load := true
app := env_var_or_default("APP_NAME", "service")

# Terraform plan
plan env="staging":
  terraform -chdir=infra/{{env}} plan

# Terraform apply
apply env="staging":
  terraform -chdir=infra/{{env}} apply

# Deploy application
deploy $env="staging" sha=`git rev-parse --short HEAD`: plan
  ./scripts/deploy.sh $env {{sha}}

# Smoke test deployment
smoke env="staging":
  ./scripts/smoke.sh {{env}}
```

## 09. Monorepo operations

Use this when a team needs package-targeted commands across many services.

```just
set dotenv-load := true

# Install all workspace deps
bootstrap:
  pnpm install

# Run a command for one package
pkg name cmd:
  pnpm --filter {{name}} {{cmd}}

# Test one package
test-pkg name:
  pnpm --filter {{name}} test

# Build all packages
build:
  pnpm -r build

# Validate whole monorepo
ci: bootstrap build
  pnpm -r test
```

## 10. Security and release

Use this for dependency audits, SBOM generation, changelog capture, and release workflows.

```just
set dotenv-load := true
version := env_var_or_default("VERSION", "patch")

# Audit dependencies
audit:
  cargo audit || true
  npm audit --audit-level=high || true
  pip-audit || true

# Generate SBOM
sbom:
  syft . -o spdx-json > sbom.spdx.json

# Build changelog
changelog:
  git cliff -o CHANGELOG.md

# Tag and release
release bump=version: audit sbom changelog
  cargo release {{bump}}
```

## Adoption guidance

Teams should keep recipe names stable across repositories where possible, use `default` to print the recipe catalog, and reserve only a small set of high-variance parameters for user input. `just --list`, dotenv loading, parameterized recipes, and exported environment variables make it possible to build a recognizable operational surface that remains simple enough for broad team use.[web:75][web:73][web:94]

A lightweight governance model also helps: maintain one baseline template library, one style guide for naming and comments, and one short review checklist for whether a new recipe belongs in the shared command vocabulary.
