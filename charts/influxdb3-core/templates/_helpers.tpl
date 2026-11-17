{{/*
Expand the name of the chart.
*/}}
{{- define "influxdb3-core.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
*/}}
{{- define "influxdb3-core.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "influxdb3-core.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "influxdb3-core.selectorLabels" -}}
app.kubernetes.io/name: {{ include "influxdb3-core.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "influxdb3-core.labels" -}}
helm.sh/chart: {{ include "influxdb3-core.chart" . }}
{{ include "influxdb3-core.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Service account name
*/}}
{{- define "influxdb3-core.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "influxdb3-core.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Image reference
*/}}
{{- define "influxdb3-core.image" -}}
{{- $registry := .Values.image.registry }}
{{- $repository := .Values.image.repository }}
{{- $tag := .Values.image.tag | default (printf "%s-core" .Chart.AppVersion) }}
{{- printf "%s/%s:%s" $registry $repository $tag }}
{{- end }}

{{/*
Object storage secret name
*/}}
{{- define "influxdb3-core.objectStorageSecretName" -}}
{{- $default := printf "%s-object-storage" (include "influxdb3-core.fullname" .) -}}
{{- if eq .Values.objectStorage.type "s3" -}}
{{- default $default .Values.objectStorage.s3.existingSecret -}}
{{- else if eq .Values.objectStorage.type "google" -}}
{{- default $default .Values.objectStorage.google.existingSecret -}}
{{- else if eq .Values.objectStorage.type "azure" -}}
{{- default $default .Values.objectStorage.azure.existingSecret -}}
{{- else -}}
{{- $default -}}
{{- end -}}
{{- end }}

{{/*
TLS secret name
*/}}
{{- define "influxdb3-core.tlsSecretName" -}}
{{- default (printf "%s-tls" (include "influxdb3-core.fullname" .)) .Values.security.tls.existingSecret }}
{{- end }}

{{/*
Validate chart configuration
*/}}
{{- define "influxdb3-core.validate" -}}
{{- $type := .Values.objectStorage.type -}}
{{- if not (has $type (list "file" "memory" "memory-throttled" "s3" "google" "azure")) }}
{{- fail (printf "Invalid objectStorage.type: %s. Must be one of: file, memory, memory-throttled, s3, google, azure" $type) }}
{{- end }}
{{- if not (has .Values.security.tls.minVersion (list "tls-1.2" "tls-1.3")) }}
{{- fail "Invalid security.tls.minVersion. Must be one of: tls-1.2, tls-1.3." }}
{{- end }}
{{- range .Values.security.auth.disableAuthz }}
{{- if not (has . (list "health" "ping" "metrics" "ready" "pprof")) }}
{{- fail (printf "Invalid security.auth.disableAuthz endpoint: %s. Must be one of: health, ping, metrics, ready, pprof." .) }}
{{- end }}
{{- end }}
{{- if and .Values.probes.enabled (not .Values.security.auth.disabled) (not (has "health" .Values.security.auth.disableAuthz)) }}
{{- fail "probes.enabled=true with authentication requires health in security.auth.disableAuthz." }}
{{- end }}
{{- if and .Values.serviceMonitor.enabled (not .Values.security.auth.disabled) (not (has "metrics" .Values.security.auth.disableAuthz)) }}
{{- fail "serviceMonitor.enabled=true with authentication requires metrics in security.auth.disableAuthz." }}
{{- end }}
{{- $tlsCa := .Values.objectStorage.tlsCa | default dict -}}
{{- if and (get $tlsCa "certPath") (get $tlsCa "existingSecret") }}
{{- fail "Set only one of objectStorage.tlsCa.certPath or objectStorage.tlsCa.existingSecret." }}
{{- end }}
{{- if eq $type "s3" }}
{{- $s3 := .Values.objectStorage.s3 }}
{{- if and $s3.existingSecret (or $s3.accessKeyId $s3.secretAccessKey $s3.sessionToken $s3.credentialsFile) }}
{{- fail "Set objectStorage.s3.existingSecret without inline credentials or credentialsFile." }}
{{- end }}
{{- if and $s3.credentialsFile (or $s3.accessKeyId $s3.secretAccessKey $s3.sessionToken) }}
{{- fail "Set objectStorage.s3.credentialsFile without inline S3 credentials." }}
{{- end }}
{{- if or (and $s3.accessKeyId (not $s3.secretAccessKey)) (and $s3.secretAccessKey (not $s3.accessKeyId)) }}
{{- fail "objectStorage.s3.accessKeyId and objectStorage.s3.secretAccessKey must be set together." }}
{{- end }}
{{- if and $s3.sessionToken (not (and $s3.accessKeyId $s3.secretAccessKey)) }}
{{- fail "objectStorage.s3.sessionToken requires accessKeyId and secretAccessKey." }}
{{- end }}
{{- end }}
{{- if eq $type "google" }}
{{- if and .Values.objectStorage.google.existingSecret .Values.objectStorage.google.serviceAccountJson }}
{{- fail "Set either objectStorage.google.existingSecret or serviceAccountJson, not both." }}
{{- end }}
{{- if not (or .Values.objectStorage.google.existingSecret .Values.objectStorage.google.serviceAccountJson) }}
{{- fail "objectStorage.type=google requires objectStorage.google.existingSecret or serviceAccountJson." }}
{{- end }}
{{- end }}
{{- if eq $type "azure" }}
{{- $azure := .Values.objectStorage.azure }}
{{- if and $azure.existingSecret (or $azure.storageAccount $azure.accessKey) }}
{{- fail "Set either objectStorage.azure.existingSecret or inline Azure credentials, not both." }}
{{- end }}
{{- if and (not $azure.existingSecret) (not (and $azure.storageAccount $azure.accessKey)) }}
{{- fail "objectStorage.type=azure requires existingSecret or both storageAccount and accessKey." }}
{{- end }}
{{- end }}
{{- $adminToken := .Values.security.auth.adminToken | default dict -}}
{{- if and (get $adminToken "existingSecret") (get $adminToken "file") }}
{{- fail "Set only one of security.auth.adminToken.existingSecret or security.auth.adminToken.file." }}
{{- end }}
{{- $processingEngine := .Values.processingEngine | default dict -}}
{{- $packageManager := get $processingEngine "packageManager" | default "" -}}
{{- if and $packageManager (not (has $packageManager (list "discover" "pip" "uv" "disabled"))) }}
{{- fail "Invalid processingEngine.packageManager. Must be one of: discover, pip, uv, disabled." }}
{{- end }}
{{- $persistence := get $processingEngine "persistence" | default dict -}}
{{- if and (get $persistence "enabled") (not (get $processingEngine "pluginDir")) }}
{{- fail "processingEngine.pluginDir is required when processingEngine.persistence.enabled=true." }}
{{- end }}
{{- include "influxdb3-core.validateUpgradeBoundaryAcknowledgement" . }}
{{- include "influxdb3-core.validateShutdownConfig" . }}
{{- include "influxdb3-core.validateMemorySizes" . }}
{{- range $key := list "disablePackageManagement" "asyncTriggerConcurrencyLimit" }}
{{- if and (hasKey $processingEngine $key) (not (kindIs "invalid" (get $processingEngine $key))) }}
{{- $value := get $processingEngine $key }}
{{- if and (eq $key "disablePackageManagement") (not (kindIs "bool" $value)) }}
{{- fail "processingEngine.disablePackageManagement must be a boolean." }}
{{- end }}
{{- if and (eq $key "asyncTriggerConcurrencyLimit") (not (regexMatch "^0*[1-9][0-9]*$" (include "influxdb3-core.plainInteger" $value))) }}
{{- fail "processingEngine.asyncTriggerConcurrencyLimit must be a positive integer." }}
{{- end }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Object storage credential environment variables
*/}}
{{- define "influxdb3-core.objectStorageEnv" -}}
{{- $secret := include "influxdb3-core.objectStorageSecretName" . }}
{{- if eq .Values.objectStorage.type "s3" }}
{{- if or .Values.objectStorage.s3.existingSecret .Values.objectStorage.s3.accessKeyId }}
- name: AWS_ACCESS_KEY_ID
  valueFrom:
    secretKeyRef:
      name: {{ $secret }}
      key: access-key-id
- name: AWS_SECRET_ACCESS_KEY
  valueFrom:
    secretKeyRef:
      name: {{ $secret }}
      key: secret-access-key
- name: AWS_SESSION_TOKEN
  valueFrom:
    secretKeyRef:
      name: {{ $secret }}
      key: session-token
      optional: true
{{- end }}
{{- else if eq .Values.objectStorage.type "azure" }}
- name: AZURE_STORAGE_ACCOUNT
  valueFrom:
    secretKeyRef:
      name: {{ $secret }}
      key: storage-account
- name: AZURE_STORAGE_ACCESS_KEY
  valueFrom:
    secretKeyRef:
      name: {{ $secret }}
      key: access-key
{{- end }}
{{- end }}

{{/*
Pod name environment for stable StatefulSet node IDs
*/}}
{{- define "influxdb3-core.podNameEnv" -}}
- name: POD_NAME
  valueFrom:
    fieldRef:
      fieldPath: metadata.name
{{- end }}

{{/*
Probe configuration
*/}}
{{- define "influxdb3-core.probes" -}}
{{- if .Values.probes.enabled }}
{{- range $name := list "liveness" "readiness" "startup" }}
{{ $name }}Probe:
  httpGet:
    path: /health
    port: http
    {{- if $.Values.security.tls.enabled }}
    scheme: HTTPS
    {{- end }}
  {{- toYaml (get $.Values.probes $name) | nindent 2 }}
{{- end }}
{{- end }}
{{- end }}

{{- define "influxdb3-core.quote" -}}
{{- if not (kindIs "invalid" .) -}}
{{- include "influxdb3-core.plainInteger" . | quote -}}
{{- end -}}
{{- end }}

{{- define "influxdb3-core.annotations" -}}
{{- $annotations := dict }}
{{- range $key, $value := . }}
{{- $_ := set $annotations $key (ternary "" (include "influxdb3-core.plainInteger" $value) (kindIs "invalid" $value)) }}
{{- end }}
{{- toYaml $annotations }}
{{- end }}

{{- define "influxdb3-core.plainInteger" -}}
{{- if and (kindIs "float64" .) (eq (floor .) .) -}}
{{- printf "%.0f" . -}}
{{- else -}}
{{- toString . -}}
{{- end -}}
{{- end }}

{{- define "influxdb3-core.validateMemorySize" -}}
{{- $key := .key -}}
{{- $raw := .value | toString | trim | lower -}}
{{/* Quote the value as the user wrote it. toString on a values-file number goes through %v,
     which switches to exponent form above six digits, so integral floats are printed whole. */}}
{{- $shown := .value | toString -}}
{{- if and (kindIs "float64" .value) (eq (floor .value) .value) -}}
{{- $shown = printf "%.0f" .value -}}
{{- end -}}
{{- $allowPercent := true -}}
{{- if hasKey . "allowPercent" -}}
{{- if not (kindIs "bool" .allowPercent) -}}
{{- fail (printf "internal error: allowPercent for %s must be a bool, got %q." $key ($allowPercent | toString)) -}}
{{- end -}}
{{- $allowPercent = .allowPercent -}}
{{- end -}}
{{/* Spell out what the server takes, since the two size types differ only on percentages. */}}
{{- $units := "a unit suffix the server accepts (b, kb, mb, gb, tb - all 1024-based)" -}}
{{- if eq $raw "" -}}
{{- fail (printf "%s is set to an empty value. Remove the key to use the server default, or give it %s." $key $units) -}}
{{- end -}}
{{- if hasSuffix "%" $raw -}}
{{- if not $allowPercent -}}
{{- fail (printf "%s is an absolute file size and does not take a percentage, got %q. Use %s." $key $shown $units) -}}
{{- end -}}
{{- $pct := trimSuffix "%" $raw | trim | trimPrefix "+" -}}
{{- if not (regexMatch "^[0-9]+$" $pct) -}}
{{- fail (printf "%s must be a whole percentage such as \"20%%\", got %q." $key $shown) -}}
{{- end -}}
{{/* Sprig int64 reads a leading zero as octal (0120 is 80) and returns 0 for a bad digit or an
     overflow, so drop the zeros - the server ignores them - and bound the length before converting. */}}
{{- $pct = regexReplaceAll "^0+([0-9])" $pct "${1}" -}}
{{- if or (gt (len $pct) 3) (gt ($pct | int64) 100) -}}
{{- fail (printf "%s must be between 0 and 100 percent, got %q." $key $shown) -}}
{{- end -}}
{{- else if not (regexMatch "^\\+?[0-9]+\\s*(kb|mb|gb|tb|b)$" $raw) -}}
{{- if $allowPercent -}}
{{- fail (printf "%s must carry %s or be a percentage, got %q. Bare numbers and Kubernetes suffixes such as Gi are rejected by InfluxDB and the pod will not start." $key $units $shown) -}}
{{- else -}}
{{- fail (printf "%s must carry %s, got %q. It is an absolute file size, so a percentage is not accepted either, and bare numbers and Kubernetes suffixes such as Gi are rejected by InfluxDB." $key $units $shown) -}}
{{- end -}}
{{- end -}}
{{- end }}

{{- define "influxdb3-core.validateMemorySizeKey" -}}
{{- $src := .src -}}
{{- $name := .name -}}
{{- if and (hasKey $src $name) (not (kindIs "invalid" (get $src $name))) -}}
{{- $args := dict "key" .key "value" (get $src $name) -}}
{{- if hasKey . "allowPercent" -}}
{{- $args = merge $args (dict "allowPercent" .allowPercent) -}}
{{- end -}}
{{- include "influxdb3-core.validateMemorySize" $args -}}
{{- end -}}
{{- end }}

{{- define "influxdb3-core.terminationGracePeriodValue" -}}
{{- $shutdown := .Values.shutdown | default dict -}}
{{- if hasKey $shutdown "terminationGracePeriodSeconds" -}}
{{- $v := get $shutdown "terminationGracePeriodSeconds" -}}
{{- if not (kindIs "invalid" $v) -}}
{{/* A values-file number is a float64, and toString prints 1000000 as 1e+06. */}}
{{- if and (kindIs "float64" $v) (eq (floor $v) $v) -}}
{{- $v = printf "%.0f" $v -}}
{{- end -}}
{{- regexReplaceAll "^0+([0-9])" ($v | toString | trim) "${1}" -}}
{{- end -}}
{{- end -}}
{{- end }}

{{- define "influxdb3-core.validateShutdownConfig" -}}
{{- $shutdown := .Values.shutdown | default dict -}}
{{- if and (hasKey $shutdown "terminationGracePeriodSeconds") (not (kindIs "invalid" (get $shutdown "terminationGracePeriodSeconds"))) -}}
{{- $grace := include "influxdb3-core.terminationGracePeriodValue" . -}}
{{/* kubelet holds the grace period as nanoseconds in an int64, which ends near 9.2e9 seconds. */}}
{{- if not (regexMatch "^(0|[1-9][0-9]{0,8})$" $grace) -}}
{{- fail (printf "shutdown.terminationGracePeriodSeconds must be a whole number of seconds from 0 to 999999999, got %q." $grace) -}}
{{- end -}}
{{- $graceMs := mul ($grace | atoi) 1000 -}}
{{- if and (hasKey $shutdown "timeout") (not (kindIs "invalid" (get $shutdown "timeout"))) -}}
{{- $raw := get $shutdown "timeout" | toString | trim -}}
{{/* humantime 2.3.0's units, longest spelling first so regexFindAll does not stop at m in ms. */}}
{{- $unit := "nanos|nsec|ns|usec|us|µs|millis|msec|ms|seconds|second|secs|sec|s|minutes|minute|mins|min|months|month|m|hours|hour|hrs|hr|h|days|day|d|weeks|week|wks|wk|w|M|years|year|yrs|yr|y" -}}
{{- if eq $raw "0" -}}
{{/* humantime's bare zero: no drain */}}
{{- else if regexMatch (printf "^([0-9]{1,18} *(%s) *)+$" $unit) $raw -}}
{{/* Every grace period the check allows is under 1e12 ms, so a part at or above that is
     simply longer than it; capping there keeps the int64 arithmetic from overflowing. */}}
{{- $cap := 1000000000000 -}}
{{- $drainMs := 0 -}}
{{- range $part := regexFindAll (printf "[0-9]{1,18} *(%s)" $unit) $raw -1 -}}
{{/* atoi, not int64: int64 reads a leading zero as octal */}}
{{- $n := regexFind "^[0-9]+" $part | atoi -}}
{{- $u := regexReplaceAll "^[0-9]+ *" $part "" -}}
{{- $ms := 0 -}}
{{- if has $u (list "nanos" "nsec" "ns") -}}{{- $ms = div (add $n 999999) 1000000 -}}
{{- else if has $u (list "usec" "us" "µs") -}}{{- $ms = div (add $n 999) 1000 -}}
{{- else -}}
{{- $mult := 31557600000 -}}
{{- if has $u (list "millis" "msec" "ms") -}}{{- $mult = 1 -}}
{{- else if has $u (list "seconds" "second" "secs" "sec" "s") -}}{{- $mult = 1000 -}}
{{- else if has $u (list "minutes" "minute" "mins" "min" "m") -}}{{- $mult = 60000 -}}
{{- else if has $u (list "hours" "hour" "hrs" "hr" "h") -}}{{- $mult = 3600000 -}}
{{- else if has $u (list "days" "day" "d") -}}{{- $mult = 86400000 -}}
{{- else if has $u (list "weeks" "week" "wks" "wk" "w") -}}{{- $mult = 604800000 -}}
{{- else if has $u (list "months" "month" "M") -}}{{- $mult = 2630016000 -}}
{{- end -}}
{{- $ms = ternary $cap (mul $n $mult) (ge $n (div $cap $mult)) -}}
{{- end -}}
{{- $drainMs = min (add $drainMs $ms) $cap -}}
{{- end -}}
{{/* A zero timeout skips the drain, so there is nothing to outlast. */}}
{{- if and (gt $drainMs 0) (le $graceMs $drainMs) -}}
{{- fail (printf "shutdown.terminationGracePeriodSeconds (%s) is not longer than shutdown.timeout (%s), so kubelet sends SIGKILL before the drain finishes. The server also finishes its background shutdown before the drain starts, so leave a margin beyond the timeout." $grace $raw) -}}
{{- end -}}
{{- else -}}
{{- fail (printf "shutdown.timeout (%s) cannot be compared with shutdown.terminationGracePeriodSeconds. Write it in whole units such as 90s or 1h 30m, or remove terminationGracePeriodSeconds." $raw) -}}
{{- end -}}
{{- else if lt $graceMs 30000 -}}
{{- fail (printf "shutdown.terminationGracePeriodSeconds (%s) is shorter than the server's default drain of 30s, so kubelet sends SIGKILL before the drain can finish. Raise it to at least 30, or set a shorter shutdown.timeout." $grace) -}}
{{- end -}}
{{- end -}}
{{- end }}

{{- define "influxdb3-core.upgradeBoundary" -}}
3.12
{{- end }}

{{- define "influxdb3-core.validateUpgradeBoundaryAcknowledgement" -}}
{{- $boundary := include "influxdb3-core.upgradeBoundary" . -}}
{{- $boundaryVersion := printf "%s.0" $boundary -}}
{{- $acknowledgement := get .Values "acknowledgeUpgrade" -}}
{{- if kindIs "invalid" $acknowledgement -}}
{{- $acknowledgement = "" -}}
{{- end -}}
{{- if not (kindIs "string" $acknowledgement) -}}
{{- fail "acknowledgeUpgrade must be a quoted string such as \"3.12\"." -}}
{{- end -}}
{{- if and (ne $acknowledgement "") (not (regexMatch "^[0-9]+\\.[0-9]+$" $acknowledgement)) -}}
{{- fail "acknowledgeUpgrade must be empty or use X.Y form such as \"3.12\"." -}}
{{- end -}}
{{- $name := printf "%s-config" (include "influxdb3-core.fullname" .) -}}
{{- $configMap := lookup "v1" "ConfigMap" .Release.Namespace $name | default dict -}}
{{- $recorded := dig "metadata" "annotations" "influxdata.com/upgrade-boundary-applied" "" $configMap -}}
{{- if and $recorded (not (regexMatch "^[0-9]+\\.[0-9]+$" $recorded)) -}}
{{- fail (printf "influxdata.com/upgrade-boundary-applied on ConfigMap %q must use X.Y form; got %q." $name $recorded) -}}
{{- end -}}
{{- $targetVersion := include "influxdb3-core.targetProductVersion" . -}}
{{- $requiresBoundary := true -}}
{{- if $targetVersion -}}
{{- $requiresBoundary = semverCompare (printf ">=%s-0" $boundaryVersion) $targetVersion -}}
{{- end -}}
{{- $alreadyApplied := false -}}
{{- if $recorded -}}
{{- $alreadyApplied = semverCompare (printf ">=%s" $boundaryVersion) (printf "%s.0" $recorded) -}}
{{- end -}}
{{- if and .Release.IsUpgrade $requiresBoundary (not $alreadyApplied) (ne $acknowledgement $boundary) -}}
{{- fail (printf "Could not verify influxdata.com/upgrade-boundary-applied>=%s on ConfigMap %q. Back up the Core catalog and follow UPGRADING-3.10-TO-3.12.md, then set acknowledgeUpgrade: %q for the one-time upgrade or client-side preview." $boundary $name $boundary) -}}
{{- end -}}
{{- end }}

{{- define "influxdb3-core.targetProductVersion" -}}
{{- $tag := include "influxdb3-core.imageTag" . -}}
{{- regexFind "^v?[0-9]+\\.[0-9]+\\.[0-9]+" $tag | trimPrefix "v" -}}
{{- end }}

{{/*
Effective image version. Custom tags do not imply the chart's appVersion.
*/}}
{{- define "influxdb3-core.imageTag" -}}
{{- .Values.image.tag | default (printf "%s-core" .Chart.AppVersion) -}}
{{- end }}

{{/*
Validate only the newer size keys. Legacy aliases retain their original parsing.
*/}}
{{- define "influxdb3-core.validateMemorySizes" -}}
{{- $memory := .Values.memory | default dict -}}
{{- range $name := list "execMemPoolSize" "forceSnapshotMemSize" -}}
{{- include "influxdb3-core.validateMemorySizeKey" (dict "src" $memory "name" $name "key" (printf "memory.%s" $name)) -}}
{{- end -}}
{{- include "influxdb3-core.validateMemorySizeKey" (dict "src" (.Values.caching | default dict) "name" "fileCacheSize" "key" "caching.fileCacheSize") -}}
{{- end }}
