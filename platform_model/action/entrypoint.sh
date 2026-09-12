#!/usr/bin/env bash
set -euo pipefail

case "${PRISMPM_ACTION_SDK_IMAGE:-}" in
  *@sha256:????????????????????????????????????????????????????????????????) ;;
  *) printf '%s\n' 'sdk-image must be an immutable sha256 reference' >&2; exit 2 ;;
esac

case "${GITHUB_WORKSPACE:-}" in /*) ;; *) printf '%s\n' 'GITHUB_WORKSPACE must be absolute' >&2; exit 2 ;; esac
context=${PRISMPM_ACTION_CONTEXT:-.}
case "$context" in
  /*|*..*|*\\*) printf '%s\n' 'context must be a confined repository path' >&2; exit 2 ;;
esac
project=$GITHUB_WORKSPACE/$context
command=${PRISMPM_ACTION_COMMAND:-}
reference=${PRISMPM_ACTION_REFERENCE:-}
release=${PRISMPM_ACTION_RELEASE:-}
target=${PRISMPM_ACTION_TARGET:-}
plan=${PRISMPM_ACTION_PLAN:-}
backup=${PRISMPM_ACTION_BACKUP:-}
restore_target=${PRISMPM_ACTION_RESTORE_TARGET:-}
detach=${PRISMPM_ACTION_DETACH:-false}
authorized=${PRISMPM_ACTION_AUTHORIZED:-false}
secret_directory=${PRISMPM_ACTION_SECRET_DIRECTORY:-.prismpm/secrets}
bundle=${PRISMPM_ACTION_BUNDLE:-}
trusted_root=${PRISMPM_ACTION_TRUSTED_ROOT:-}
policy=${PRISMPM_ACTION_POLICY:-}
promotion_to=${PRISMPM_ACTION_PROMOTION_TO:-}
environment=${PRISMPM_ACTION_ENVIRONMENT:-}
args=(--json)
socket_args=()
credential_args=()
network_args=(--network none)

case "${GITHUB_SHA:-}" in
  [0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f])
    credential_args+=(--env "PRISMPM_SOURCE_REVISION=$GITHUB_SHA")
    ;;
  "") ;;
  *) printf '%s\n' 'GITHUB_SHA must be a lowercase 40-character Git object ID' >&2; exit 2 ;;
esac

case "$detach:$authorized" in
  true:true|true:false|false:true|false:false) ;;
  *) printf '%s\n' 'detach and authorized must be true or false' >&2; exit 2 ;;
esac

case "$command" in
  check|verify)
    args=(--project "$project" "${args[@]}")
    args+=("$command")
    ;;
  fetch)
    network_args=()
    args=(--project "$project" "${args[@]}")
    args+=(fetch --locked)
    ;;
  build)
    test -n "$reference"
    args+=(build --locked --tag "$reference" "$project")
    if test -n "$release"; then args+=(--release "$release"); fi
    ;;
  push|pull)
    network_args=()
    test -n "$reference"
    docker_config=${DOCKER_CONFIG:-$HOME/.docker}
    test -d "$docker_config"
    case "$docker_config" in /*) ;; *) printf '%s\n' 'Docker credential directory must be absolute' >&2; exit 2 ;; esac
    credential_args+=(
      --env DOCKER_CONFIG=/home/vscode/.docker
      --volume "$docker_config:/home/vscode/.docker:ro"
    )
    args=(--project "$project" "${args[@]}")
    args+=("$command" "$reference")
    ;;
  inspect|verify-release)
    test -n "$reference"
    args=(--project "$project" "${args[@]}")
    args+=("$command" "$reference")
    ;;
  conformance)
    test -n "$reference"
    test -S /var/run/docker.sock
    socket_group=$(stat -c '%g' /var/run/docker.sock)
    socket_args=(--volume /var/run/docker.sock:/var/run/docker.sock --group-add "$socket_group")
    network_args=()
    args=(--project "$project" "${args[@]}")
    args+=(conformance "$reference")
    ;;
  prepare-promotion)
    test -n "$reference" && test -n "$environment"
    for name in GITHUB_ACTIONS RUNNER_ENVIRONMENT GITHUB_REPOSITORY GITHUB_WORKFLOW GITHUB_WORKFLOW_REF GITHUB_REF GITHUB_SHA; do
      test -n "${!name:-}"
      credential_args+=(--env "$name=${!name}")
    done
    args=(--project "$project" "${args[@]}")
    args+=(prepare-promotion "$reference" --environment "$environment")
    ;;
  sign)
    network_args=()
    test -n "$reference" && test -n "$trusted_root" && test -n "$policy"
    test -n "${ACTIONS_ID_TOKEN_REQUEST_TOKEN:-}" && test -n "${ACTIONS_ID_TOKEN_REQUEST_URL:-}"
    credential_args=(
      --env ACTIONS_ID_TOKEN_REQUEST_TOKEN
      --env ACTIONS_ID_TOKEN_REQUEST_URL
    )
    args=(--project "$project" "${args[@]}")
    args+=(sign "$reference" --trusted-root "$trusted_root" --policy "$policy")
    ;;
  sign-evidence)
    network_args=()
    test -n "$reference" && test -n "$trusted_root" && test -n "$policy"
    test -n "${ACTIONS_ID_TOKEN_REQUEST_TOKEN:-}" && test -n "${ACTIONS_ID_TOKEN_REQUEST_URL:-}"
    credential_args+=(
      --env ACTIONS_ID_TOKEN_REQUEST_TOKEN
      --env ACTIONS_ID_TOKEN_REQUEST_URL
    )
    args=(--project "$project" "${args[@]}")
    args+=(sign-evidence "$reference" --all --trusted-root "$trusted_root" --policy "$policy")
    ;;
  verify-signature)
    test -n "$reference" && test -n "$bundle" && test -n "$trusted_root" && test -n "$policy"
    args=(--project "$project" "${args[@]}")
    args+=(verify-signature "$reference" --bundle "$bundle" --trusted-root "$trusted_root" --policy "$policy")
    ;;
  promote)
    network_args=()
    test -n "$reference" && test -n "$trusted_root" && test -n "$policy" && test -n "$promotion_to"
    test -n "${ACTIONS_ID_TOKEN_REQUEST_TOKEN:-}" && test -n "${ACTIONS_ID_TOKEN_REQUEST_URL:-}"
    credential_args=(
      --env ACTIONS_ID_TOKEN_REQUEST_TOKEN
      --env ACTIONS_ID_TOKEN_REQUEST_URL
    )
    args=(--project "$project" "${args[@]}")
    args+=(promote "$reference" --to "$promotion_to" --trusted-root "$trusted_root" --policy "$policy")
    ;;
  run|plan|deploy|status|rollback|backup|restore|destroy|finalize-contract)
    network_args=()
    test -n "$reference" && test -n "$target"
    test -S /var/run/docker.sock
    socket_group=$(stat -c '%g' /var/run/docker.sock)
    socket_args=(--volume /var/run/docker.sock:/var/run/docker.sock --group-add "$socket_group")
    case "$secret_directory" in /*|*..*|*\\*) printf '%s\n' 'secret-directory must be a confined repository path' >&2; exit 2 ;; esac
    if test -d "$GITHUB_WORKSPACE/$secret_directory"; then
      credential_args+=(--env "PRISMPM_SECRET_DIR=$GITHUB_WORKSPACE/$secret_directory")
    fi
    args=(--project "$project" "${args[@]}")
    case "$command" in
      run)
        args+=(run --target "$target" "$reference")
        if test "$detach" = true; then args+=(--detach); fi
        ;;
      deploy)
        test -n "$plan"
        args+=(deploy --target "$target" --plan "$plan" "$reference")
        ;;
      restore)
        test -n "$backup" && test -n "$restore_target"
        case "$backup" in /*|*..*|*\\*) printf '%s\n' 'backup must be a confined repository path' >&2; exit 2 ;; esac
        args+=(restore --target "$target" --restore-target "$restore_target" --backup "$project/$backup" "$reference")
        ;;
      destroy)
        test "$authorized" = true
        args+=(destroy --target "$target" --authorized "$reference")
        ;;
      finalize-contract)
        test "$authorized" = true
        args+=(finalize-contract --target "$target" --authorized "$reference")
        ;;
      *) args+=("$command" --target "$target" "$reference") ;;
    esac
    ;;
  *) printf 'unsupported PrismPM action command: %s\n' "$command" >&2; exit 2 ;;
esac

result_file=$(mktemp "${RUNNER_TEMP:-/tmp}/prismpm-result.XXXXXX")
cleanup() { rm -f "$result_file"; }
trap cleanup EXIT

docker run --rm \
  --user "$(id -u):$(id -g)" \
  --env HOME=/tmp/prismpm-home \
  --env PRISMPM_EPHEMERAL_HOME=1 \
  --tmpfs /tmp:rw,exec,nosuid,size=1g \
  --cap-drop ALL \
  --security-opt no-new-privileges \
  "${network_args[@]}" \
  --volume "$GITHUB_WORKSPACE:$GITHUB_WORKSPACE" \
  "${socket_args[@]}" \
  "${credential_args[@]}" \
  "$PRISMPM_ACTION_SDK_IMAGE" \
  prismpm "${args[@]}" >"$result_file"

result=$(tr -d '\n' <"$result_file")
printf 'result=%s\n' "$result" >>"$GITHUB_OUTPUT"
for pair in release-digest:release_digest plan-digest:plan_digest evidence-digest:evidence_digest transcript-digest:transcript_digest signature-referrer:signature_referrer; do
  output=${pair%%:*}
  field=${pair#*:}
  value=$(docker run --rm --interactive --network none --user "$(id -u):$(id -g)" \
    --env HOME=/tmp/prismpm-home --tmpfs /tmp:rw,exec,nosuid,size=64m \
    --cap-drop ALL --security-opt no-new-privileges "$PRISMPM_ACTION_SDK_IMAGE" node -e \
    'let s="";process.stdin.on("data",d=>s+=d).on("end",()=>{const v=JSON.parse(s);process.stdout.write(v[process.argv[1]]||"")})' \
    "$field" <"$result_file")
  printf '%s=%s\n' "$output" "$value" >>"$GITHUB_OUTPUT"
done
if test "$command" = prepare-promotion; then
  digest=${reference##*@sha256:}
  printf 'policy-path=.prism/promotion/%s/policy.json\n' "$digest" >>"$GITHUB_OUTPUT"
  printf 'trusted-root-path=.prism/promotion/%s/trusted-root.json\n' "$digest" >>"$GITHUB_OUTPUT"
fi
