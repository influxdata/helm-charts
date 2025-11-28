{{/*
Expand the name of the chart.
*/}}
{{- define "influxdb3-enterprise.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
*/}}
{{- define "influxdb3-enterprise.fullname" -}}
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
{{- define "influxdb3-enterprise.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "influxdb3-enterprise.labels" -}}
helm.sh/chart: {{ include "influxdb3-enterprise.chart" . }}
{{ include "influxdb3-enterprise.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "influxdb3-enterprise.selectorLabels" -}}
app.kubernetes.io/name: {{ include "influxdb3-enterprise.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Component labels
*/}}
{{- define "influxdb3-enterprise.componentLabels" -}}
{{ include "influxdb3-enterprise.labels" . }}
app.kubernetes.io/component: {{ .component }}
{{- end }}

{{/*
Service account name
*/}}
{{- define "influxdb3-enterprise.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "influxdb3-enterprise.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Object storage secret name
*/}}
{{- define "influxdb3-enterprise.objectStorageSecretName" -}}
{{- if and .Values.objectStorage.s3 .Values.objectStorage.s3.existingSecret }}
{{- .Values.objectStorage.s3.existingSecret }}
{{- else if and .Values.objectStorage.azure (hasKey .Values.objectStorage.azure "existingSecret") .Values.objectStorage.azure.existingSecret }}
{{- .Values.objectStorage.azure.existingSecret }}
{{- else if and .Values.objectStorage.google (hasKey .Values.objectStorage.google "existingSecret") .Values.objectStorage.google.existingSecret }}
{{- .Values.objectStorage.google.existingSecret }}
{{- else }}
{{- include "influxdb3-enterprise.fullname" . }}-object-storage
{{- end }}
{{- end }}

{{/*
License secret name
*/}}
{{- define "influxdb3-enterprise.licenseSecretName" -}}
{{- if .Values.license.existingSecret }}
{{- .Values.license.existingSecret }}
{{- else }}
{{- include "influxdb3-enterprise.fullname" . }}-license
{{- end }}
{{- end }}

{{/*
License checksum (handles existingSecret via lookup)
*/}}
{{- define "influxdb3-enterprise.licenseChecksum" -}}
{{- if .Values.license.existingSecret -}}
{{- $secret := (lookup "v1" "Secret" .Release.Namespace .Values.license.existingSecret) -}}
{{- if $secret -}}{{ toYaml $secret.data | sha256sum }}{{- else -}}""{{- end -}}
{{- else -}}
{{ include (print $.Template.BasePath "/secret-license.yaml") . | sha256sum }}
{{- end -}}
{{- end }}

{{/*
TLS secret name
*/}}
{{- define "influxdb3-enterprise.tlsSecretName" -}}
{{- if .Values.security.tls.existingSecret }}
{{- .Values.security.tls.existingSecret }}
{{- else }}
{{- include "influxdb3-enterprise.fullname" . }}-tls
{{- end }}
{{- end }}

{{/*
HTTP/TLS/Auth environment (shared across components)
*/}}
{{- define "influxdb3-enterprise.httpEnv" -}}
- name: INFLUXDB3_HTTP_BIND_ADDR
  value: {{ .Values.http.bind | quote }}
{{- if .Values.security.tls.enabled }}
- name: INFLUXDB3_TLS_CERT
  value: {{ .Values.security.tls.certPath | quote }}
- name: INFLUXDB3_TLS_KEY
  value: {{ .Values.security.tls.keyPath | quote }}
- name: INFLUXDB3_TLS_MINIMUM_VERSION
  value: {{ .Values.security.tls.minVersion | quote }}
{{- end }}
{{- with .Values.security.auth.adminTokenRecovery }}
{{- if .httpBind }}
- name: INFLUXDB3_ADMIN_TOKEN_RECOVERY_HTTP_BIND
  value: {{ .httpBind | quote }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Cluster environment (shared across components)
*/}}
{{- define "influxdb3-enterprise.clusterEnv" -}}
- name: INFLUXDB3_ENTERPRISE_CLUSTER_ID
  valueFrom:
    configMapKeyRef:
      name: {{ include "influxdb3-enterprise.fullname" . }}-config
      key: cluster-id
{{- if .Values.cluster.replicationInterval }}
- name: INFLUXDB3_ENTERPRISE_REPLICATION_INTERVAL
  value: {{ .Values.cluster.replicationInterval | quote }}
{{- end }}
{{- if .Values.cluster.catalogSyncInterval }}
- name: INFLUXDB3_ENTERPRISE_CATALOG_SYNC_INTERVAL
  value: {{ .Values.cluster.catalogSyncInterval | quote }}
{{- end }}
{{- if .Values.security.auth.disableAuthz }}
- name: INFLUXDB3_DISABLE_AUTHZ
  value: {{ join "," .Values.security.auth.disableAuthz | quote }}
{{- end }}
{{- end }}

{{/*
Object storage environment (shared across components)
*/}}
{{- define "influxdb3-enterprise.objectStoreEnv" -}}
- name: INFLUXDB3_OBJECT_STORE
  value: {{ .Values.objectStorage.type | quote }}
{{- if eq .Values.objectStorage.type "file" }}
- name: INFLUXDB3_DB_DIR
  value: {{ .Values.objectStorage.file.dataDir | quote }}
{{- else }}
- name: INFLUXDB3_BUCKET
  value: {{ .Values.objectStorage.bucket | quote }}
{{- if .Values.objectStorage.connectionLimit }}
- name: OBJECT_STORE_CONNECTION_LIMIT
  value: {{ .Values.objectStorage.connectionLimit | quote }}
{{- end }}
{{- if hasKey .Values.objectStorage "http2Only" }}
- name: OBJECT_STORE_HTTP2_ONLY
  value: {{ ternary "true" "false" .Values.objectStorage.http2Only | quote }}
{{- end }}
{{- if .Values.objectStorage.http2MaxFrameSize }}
- name: OBJECT_STORE_HTTP2_MAX_FRAME_SIZE
  value: {{ .Values.objectStorage.http2MaxFrameSize | quote }}
{{- end }}
{{- if .Values.objectStorage.maxRetries }}
- name: OBJECT_STORE_MAX_RETRIES
  value: {{ .Values.objectStorage.maxRetries | quote }}
{{- end }}
{{- if .Values.objectStorage.retryTimeout }}
- name: OBJECT_STORE_RETRY_TIMEOUT
  value: {{ .Values.objectStorage.retryTimeout | quote }}
{{- end }}
{{- if .Values.objectStorage.cacheEndpoint }}
- name: OBJECT_STORE_CACHE_ENDPOINT
  value: {{ .Values.objectStorage.cacheEndpoint | quote }}
{{- end }}
{{- if eq .Values.objectStorage.type "s3" }}
- name: AWS_DEFAULT_REGION
  value: {{ .Values.objectStorage.s3.region | quote }}
{{- if .Values.objectStorage.s3.endpoint }}
- name: AWS_ENDPOINT
  value: {{ .Values.objectStorage.s3.endpoint | quote }}
{{- end }}
{{- if .Values.objectStorage.s3.allowHttp }}
- name: AWS_ALLOW_HTTP
  value: "true"
{{- end }}
  {{- if or .Values.objectStorage.s3.existingSecret (and .Values.objectStorage.s3.accessKeyId .Values.objectStorage.s3.secretAccessKey) }}
- name: AWS_ACCESS_KEY_ID
  valueFrom:
    secretKeyRef:
      name: {{ include "influxdb3-enterprise.objectStorageSecretName" . }}
      key: access-key-id
- name: AWS_SECRET_ACCESS_KEY
  valueFrom:
    secretKeyRef:
      name: {{ include "influxdb3-enterprise.objectStorageSecretName" . }}
      key: secret-access-key
- name: AWS_SESSION_TOKEN
  valueFrom:
    secretKeyRef:
      name: {{ include "influxdb3-enterprise.objectStorageSecretName" . }}
      key: session-token
      optional: true
  {{- end }}
{{- else if eq .Values.objectStorage.type "azure" }}
{{- if .Values.objectStorage.azure.endpoint }}
- name: AZURE_ENDPOINT
  value: {{ .Values.objectStorage.azure.endpoint | quote }}
{{- end }}
{{- if .Values.objectStorage.azure.allowHttp }}
- name: AZURE_ALLOW_HTTP
  value: "true"
{{- end }}
  {{- if or .Values.objectStorage.azure.existingSecret (and .Values.objectStorage.azure.storageAccount .Values.objectStorage.azure.accessKey) }}
- name: AZURE_STORAGE_ACCOUNT
  valueFrom:
    secretKeyRef:
      name: {{ include "influxdb3-enterprise.objectStorageSecretName" . }}
      key: storage-account
- name: AZURE_STORAGE_ACCESS_KEY
  valueFrom:
    secretKeyRef:
      name: {{ include "influxdb3-enterprise.objectStorageSecretName" . }}
      key: access-key
  {{- end }}
{{- else if eq .Values.objectStorage.type "google" }}
- name: GOOGLE_SERVICE_ACCOUNT
  value: "/var/secrets/google/service-account.json"
{{- end }}
{{- end }}
{{- end }}

{{/*
License environment (shared across components)
*/}}
{{- define "influxdb3-enterprise.licenseEnv" -}}
- name: INFLUXDB3_ENTERPRISE_LICENSE_EMAIL
  valueFrom:
    secretKeyRef:
      name: {{ include "influxdb3-enterprise.licenseSecretName" . }}
      key: license-email
      optional: true
- name: INFLUXDB3_ENTERPRISE_LICENSE_FILE
  valueFrom:
    secretKeyRef:
      name: {{ include "influxdb3-enterprise.licenseSecretName" . }}
      key: license-file
      optional: true
- name: INFLUXDB3_ENTERPRISE_LICENSE_TYPE
  value: {{ .Values.license.type | quote }}
{{- end }}

{{/*
Probe configuration (shared across components)
*/}}
{{- define "influxdb3-enterprise.probes" -}}
{{- if .Values.probes.enabled }}
livenessProbe:
  httpGet:
    path: /health
    port: http
  initialDelaySeconds: {{ .Values.probes.liveness.initialDelaySeconds }}
  periodSeconds: {{ .Values.probes.liveness.periodSeconds }}
  timeoutSeconds: {{ .Values.probes.liveness.timeoutSeconds }}
  failureThreshold: {{ .Values.probes.liveness.failureThreshold }}
readinessProbe:
  httpGet:
    path: /health
    port: http
  initialDelaySeconds: {{ .Values.probes.readiness.initialDelaySeconds }}
  periodSeconds: {{ .Values.probes.readiness.periodSeconds }}
  timeoutSeconds: {{ .Values.probes.readiness.timeoutSeconds }}
  failureThreshold: {{ .Values.probes.readiness.failureThreshold }}
startupProbe:
  httpGet:
    path: /health
    port: http
  initialDelaySeconds: {{ .Values.probes.startup.initialDelaySeconds }}
  periodSeconds: {{ .Values.probes.startup.periodSeconds }}
  timeoutSeconds: {{ .Values.probes.startup.timeoutSeconds }}
  failureThreshold: {{ .Values.probes.startup.failureThreshold }}
{{- end }}
{{- end }}

{{/*
Image reference
*/}}
{{- define "influxdb3-enterprise.image" -}}
{{- $registry := .Values.image.registry }}
{{- $repository := .Values.image.repository }}
{{- $tag := .Values.image.tag | default .Chart.AppVersion }}
{{- printf "%s/%s:%s" $registry $repository $tag }}
{{- end }}

{{/*
Shared volume mounts (license/TLS/GCS and user extras)
*/}}
{{- define "influxdb3-enterprise.sharedVolumeMounts" -}}
{{- if eq .Values.objectStorage.type "google" }}
- name: google-service-account
  mountPath: /var/secrets/google
  readOnly: true
{{- end }}
{{- if or .Values.license.file .Values.license.existingSecret }}
- name: license
  mountPath: /etc/influxdb/license
  readOnly: true
{{- end }}
{{- if .Values.security.tls.enabled }}
- name: tls
  mountPath: /etc/influxdb/tls
  readOnly: true
{{- end }}
{{- with .Values.extraVolumeMounts }}
{{ toYaml . }}
{{- end }}
{{- end }}

{{/*
Shared volumes (license/TLS/GCS and user extras)
*/}}
{{- define "influxdb3-enterprise.sharedVolumes" -}}
{{- if eq .Values.objectStorage.type "file" }}
- name: object-storage
  persistentVolumeClaim:
    claimName: {{ include "influxdb3-enterprise.fullname" . }}-object-storage
{{- end }}
{{- if eq .Values.objectStorage.type "google" }}
- name: google-service-account
  secret:
    secretName: {{ include "influxdb3-enterprise.objectStorageSecretName" . }}
    items:
      - key: service-account.json
        path: service-account.json
{{- end }}
{{- if or .Values.license.file .Values.license.existingSecret }}
- name: license
  secret:
    secretName: {{ include "influxdb3-enterprise.licenseSecretName" . }}
    optional: true
    items:
      - key: license-file
        path: license
{{- end }}
{{- if .Values.security.tls.enabled }}
- name: tls
  secret:
    secretName: {{ include "influxdb3-enterprise.tlsSecretName" . }}
{{- end }}
{{- with .Values.extraVolumes }}
{{ toYaml . }}
{{- end }}
{{- end }}
