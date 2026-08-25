#!/usr/bin/env bash
set -euo pipefail

scenario_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
manual_dir=$(CDPATH= cd -- "$scenario_dir/.." && pwd)
chart_dir=$(CDPATH= cd -- "$manual_dir/../.." && pwd)

values_file="$manual_dir/values-s3.yaml"
license_file=
admin_token_file="$manual_dir/admin-token.example.json"
kube_context=

while [ "$#" -gt 0 ]; do
  case "$1" in
    --values)
      values_file=$2
      shift 2
      ;;
    --license-file)
      license_file=$2
      shift 2
      ;;
    --context)
      kube_context=$2
      shift 2
      ;;
    *)
      echo "Unknown option: $1" >&2
      exit 2
      ;;
  esac
done

log() {
  printf '\n==> %s\n' "$1"
}

log "Validating prerequisites"

for command in aws helm kubectl awk grep sed; do
  command -v "$command" >/dev/null || {
    echo "Required command not found: $command" >&2
    exit 1
  }
done

[ -n "$license_file" ] || {
  echo "--license-file is required." >&2
  exit 2
}

[ -f "$license_file" ] || {
  echo "License file not found: $license_file" >&2
  exit 1
}

grep -q '^REPLACE_WITH_COMMERCIAL_LICENSE$' "$license_file" && {
  echo "Replace the placeholder in $license_file with a commercial license." >&2
  exit 1
}

auth_token=$(sed -n \
  's/^[[:space:]]*"token"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' \
  "$admin_token_file")
[ -n "$auth_token" ] || {
  echo "No token found in $admin_token_file" >&2
  exit 1
}

s3_endpoint=$(awk '
  $1 == "endpoint:" {
    gsub(/"/, "", $2)
    print $2
    exit
  }
' "$values_file")
[ -n "$s3_endpoint" ] || {
  echo "No S3 endpoint found in $values_file" >&2
  exit 1
}

aws_access_key=$(awk '
  $1 == "accessKeyId:" {
    gsub(/"/, "", $2)
    print $2
    exit
  }
' "$values_file")
aws_secret_key=$(awk '
  $1 == "secretAccessKey:" {
    gsub(/"/, "", $2)
    print $2
    exit
  }
' "$values_file")

export AWS_ACCESS_KEY_ID=$aws_access_key
export AWS_SECRET_ACCESS_KEY=$aws_secret_key

run_id=$(date -u +%Y%m%d%H%M%S)-$$
namespace=influxdb3-upgrade-"$run_id"
bucket=influxdb3-upgrade-"$run_id"
cluster_id=upgrade-"$run_id"
release=upgrade
license_secret="$release-license"
admin_secret="$release-admin-token"
ingester_pod="$release-influxdb3-enterprise-ingester-0"
ingester_host="http://$release-influxdb3-enterprise-ingester:8181"
querier_host="http://$release-influxdb3-enterprise-querier:8181"

kubectl_command=(kubectl)
helm_context=()
if [ -n "$kube_context" ]; then
  kubectl_command=(kubectl --context "$kube_context")
  helm_context=(--kube-context "$kube_context")
fi

query_until_contains() {
  local expected=$1
  local timeout=15
  local deadline=$((SECONDS + timeout))
  local query_output=

  sleep 2

  while [ "$SECONDS" -lt "$deadline" ]; do
    if query_output=$("${kubectl_command[@]}" exec \
      --namespace "$namespace" "$ingester_pod" -- \
      influxdb3 query \
      --host "$querier_host" \
      --database upgrade_test \
      --token "$auth_token" \
      --format csv \
      'SELECT * FROM upgrade_measurement ORDER BY time'); then
      if printf '%s\n' "$query_output" | grep -Fq "$expected"; then
        printf '%s\n' "$query_output"
        return 0
      fi
    fi

    [ "$SECONDS" -lt "$deadline" ] && sleep 1
  done

  printf 'Query result did not contain %s after %s seconds\n' \
    "$expected" "$timeout" >&2
  return 1
}

wait_for_pacha_tree_migration() {
  local timeout=60
  local deadline=$((SECONDS + timeout))
  local status_output=

  while [ "$SECONDS" -lt "$deadline" ]; do
    if status_output=$("${kubectl_command[@]}" exec \
      --namespace "$namespace" "$ingester_pod" -- \
      influxdb3 query \
      --host "$querier_host" \
      --database _internal \
      --token "$auth_token" \
      --format csv \
      'SELECT status FROM system.upgrade_parquet_node'); then
      if printf '%s\n' "$status_output" | awk -F, '
        NR == 1 { next }
        NF {
          count++
          if ($1 != "completed") {
            incomplete = 1
          }
        }
        END {
          exit !(count > 0 && incomplete == 0)
        }
      '; then
        printf '%s\n' "$status_output"
        return 0
      fi
    fi

    [ "$SECONDS" -lt "$deadline" ] && sleep 5
  done

  printf 'PachaTree migration did not complete after %s seconds\n' \
    "$timeout" >&2
  [ -n "$status_output" ] && printf '%s\n' "$status_output" >&2
  return 1
}

namespace_created=false
bucket_created=false

cleanup() {
  status=$?
  trap - EXIT INT TERM
  set +e

  if [ "$namespace_created" = true ]; then
    log "Deleting namespace: $namespace"
    "${kubectl_command[@]}" delete namespace "$namespace" \
      --ignore-not-found --wait=true
  fi

  if [ "$bucket_created" = true ]; then
    log "Deleting temporary S3 bucket: $bucket"
    aws --endpoint-url "$s3_endpoint" \
      s3 rm "s3://$bucket" --recursive --no-cli-pager
    aws --endpoint-url "$s3_endpoint" \
      s3api delete-bucket --bucket "$bucket" --no-cli-pager
  fi

  exit "$status"
}

trap cleanup EXIT
trap 'exit 130' INT TERM

log "Creating temporary S3 bucket: $bucket"
aws --endpoint-url "$s3_endpoint" \
  s3api create-bucket --bucket "$bucket" --no-cli-pager
bucket_created=true

log "Creating namespace and test Secrets: $namespace"
"${kubectl_command[@]}" create namespace "$namespace"
namespace_created=true

"${kubectl_command[@]}" create secret generic "$license_secret" \
  --namespace "$namespace" \
  --from-file=license-file="$license_file"

"${kubectl_command[@]}" create secret generic "$admin_secret" \
  --namespace "$namespace" \
  --from-file=admin-token.json="$admin_token_file"

log "Installing chart 0.9.2 / InfluxDB 3.10.5"
helm install "$release" influxdata/influxdb3-enterprise \
  "${helm_context[@]}" \
  --namespace "$namespace" \
  --version 0.9.2 \
  --values "$values_file" \
  --set-string objectStorage.bucket="$bucket" \
  --set-string cluster.id="$cluster_id" \
  --set license.type=commercial \
  --set-string license.existingSecret="$license_secret" \
  --set-string security.auth.adminToken.existingSecret="$admin_secret" \
  --wait \
  --timeout 15m

log "Writing baseline data"
"${kubectl_command[@]}" exec --namespace "$namespace" "$ingester_pod" -- \
  influxdb3 create database upgrade_test \
  --host "$ingester_host" \
  --token "$auth_token"

"${kubectl_command[@]}" exec --namespace "$namespace" "$ingester_pod" -- \
  influxdb3 write \
  --host "$ingester_host" \
  --database upgrade_test \
  --token "$auth_token" \
  'upgrade_measurement,source=chart-0.9.2 value=92i 1724493600000000000'

log "Upgrading to local chart 0.10.0 / InfluxDB 3.11.2"
helm upgrade "$release" "$chart_dir" \
  "${helm_context[@]}" \
  --namespace "$namespace" \
  --reuse-values \
  --wait \
  --timeout 15m

log "Verifying InfluxDB 3.11.2 on every component"
for component in ingester querier compactor processor; do
  component_pod="$release-influxdb3-enterprise-$component-0"
  version_output=$("${kubectl_command[@]}" exec \
    --namespace "$namespace" "$component_pod" -- \
    influxdb3 --version)
  printf '%s: %s\n' "$component_pod" "$version_output"
  printf '%s\n' "$version_output" | grep -Fq 'InfluxDB 3 Enterprise, 3.11.2'
done

log "Starting PachaTree migration"
helm upgrade "$release" "$chart_dir" \
  "${helm_context[@]}" \
  --namespace "$namespace" \
  --reuse-values \
  --set acknowledgePachaTreeMigration=true \
  --wait \
  --timeout 15m

log "Waiting for PachaTree migration completion"
wait_for_pacha_tree_migration

log "Writing post-upgrade data"
"${kubectl_command[@]}" exec --namespace "$namespace" "$ingester_pod" -- \
  influxdb3 write \
  --host "$ingester_host" \
  --database upgrade_test \
  --token "$auth_token" \
  'upgrade_measurement,source=chart-0.10.0 value=100i 1724493660000000000'

log "Post-upgrade query result"
post_upgrade_query=$(query_until_contains 'chart-0.10.0')
printf '%s\n' "$post_upgrade_query"

printf '%s\n' "$post_upgrade_query" |
  grep -Fq 'chart-0.9.2'
printf '%s\n' "$post_upgrade_query" | grep -Fq 'chart-0.10.0'

log "Final Helm and pod status"
helm list "${helm_context[@]}" --namespace "$namespace"
"${kubectl_command[@]}" get pods --namespace "$namespace"

log "Upgrade verification completed successfully"
