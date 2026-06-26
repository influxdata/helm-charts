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
