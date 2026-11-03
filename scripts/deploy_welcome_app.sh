#!/usr/bin/env bash
set -euo pipefail

root_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
command_name="${1:-help}"
if [[ $# -gt 0 ]]; then shift; fi

if [[ -f "$root_dir/.env" ]]; then
  set -a
  # shellcheck disable=SC1091
  source "$root_dir/.env"
  set +a
fi

namespace="${WELCOME_NAMESPACE:-default}"
app_name_raw="${WELCOME_APP_NAME:-${APP_NAME_SLUG:-${APP_NAME:-byteplus-welcome}}}"
service_type="${WELCOME_SERVICE_TYPE:-LoadBalancer}"
image="${WELCOME_IMAGE:-nginx:1.27-alpine}"
html_file="${WELCOME_HTML_FILE:-$root_dir/deploy/welcome-page/index.html}"
kubeconfig="${KUBECONFIG:-$root_dir/terraform_script/generated/devops_k8s_config}"

sanitize_dns_label() {
  printf '%s' "$1" | tr '[:upper:]' '[:lower:]' | sed -E 's/[^a-z0-9-]+/-/g; s/^-+//; s/-+$//'
}

app_name="$(sanitize_dns_label "$app_name_raw")"

if [[ -z "$app_name" ]]; then
  echo "WELCOME_APP_NAME must contain at least one lowercase letter or number after sanitization." >&2
  exit 1
fi

usage() {
  cat <<'USAGE'
Usage: ./scripts/deploy_welcome_app.sh <command>

Commands:
  help    Show this help message
  check   Validate local prerequisites and cluster reachability
  deploy  Deploy or update the sample welcome web server
  status  Show Deployment, Service, and Pod status
  delete  Remove the sample welcome web server

Environment overrides:
  KUBECONFIG            Defaults to ./terraform_script/generated/devops_k8s_config
  WELCOME_NAMESPACE     Defaults to default
  WELCOME_APP_NAME      Defaults to APP_NAME_SLUG, then APP_NAME, then byteplus-welcome
  WELCOME_SERVICE_TYPE  Defaults to LoadBalancer
  WELCOME_IMAGE         Defaults to nginx:1.27-alpine
  WELCOME_HTML_FILE     Defaults to ./deploy/welcome-page/index.html
USAGE
}

require() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "Missing required command: $1" >&2
    exit 1
  }
}

check_prereqs() {
  require kubectl

  if [[ ! -f "$html_file" ]]; then
    echo "Welcome page file not found: $html_file" >&2
    exit 1
  fi

  if [[ ! -f "$kubeconfig" ]]; then
    echo "Kubeconfig not found: $kubeconfig" >&2
    echo "Refresh it with ./terraform.sh apply -replace=bytepluscc_vke_kubeconfig.devops_k8s_config if needed." >&2
    exit 1
  fi

  kubectl --kubeconfig "$kubeconfig" version --client >/dev/null
  kubectl --kubeconfig "$kubeconfig" get nodes >/dev/null
}

apply_manifest() {
  kubectl --kubeconfig "$kubeconfig" get namespace "$namespace" >/dev/null 2>&1 || \
    kubectl --kubeconfig "$kubeconfig" create namespace "$namespace" >/dev/null

  kubectl --kubeconfig "$kubeconfig" -n "$namespace" create configmap "${app_name}-html" \
    --from-file=index.html="$html_file" \
    --dry-run=client -o yaml | \
    kubectl --kubeconfig "$kubeconfig" apply -f -

  cat <<EOF | kubectl --kubeconfig "$kubeconfig" apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: ${app_name}
  namespace: ${namespace}
spec:
  replicas: 1
  selector:
    matchLabels:
      app: ${app_name}
  template:
    metadata:
      labels:
        app: ${app_name}
    spec:
      containers:
        - name: web
          image: ${image}
          ports:
            - containerPort: 80
          volumeMounts:
            - name: welcome-html
              mountPath: /usr/share/nginx/html/index.html
              subPath: index.html
      volumes:
        - name: welcome-html
          configMap:
            name: ${app_name}-html
---
apiVersion: v1
kind: Service
metadata:
  name: ${app_name}
  namespace: ${namespace}
spec:
  selector:
    app: ${app_name}
  type: ${service_type}
  ports:
    - name: http
      port: 80
      targetPort: 80
EOF
}

show_status() {
  kubectl --kubeconfig "$kubeconfig" -n "$namespace" get deployment,service,pods -l "app=${app_name}"
}

delete_manifest() {
  kubectl --kubeconfig "$kubeconfig" -n "$namespace" delete service "${app_name}" --ignore-not-found
  kubectl --kubeconfig "$kubeconfig" -n "$namespace" delete deployment "${app_name}" --ignore-not-found
  kubectl --kubeconfig "$kubeconfig" -n "$namespace" delete configmap "${app_name}-html" --ignore-not-found
}

case "$command_name" in
  help)
    usage
    ;;
  check)
    check_prereqs
    echo "Welcome app prerequisites look good."
    ;;
  deploy)
    check_prereqs
    apply_manifest
    kubectl --kubeconfig "$kubeconfig" -n "$namespace" rollout status deployment/"$app_name"
    show_status
    ;;
  status)
    check_prereqs
    show_status
    ;;
  delete)
    check_prereqs
    delete_manifest
    ;;
  *)
    usage
    exit 1
    ;;
esac
