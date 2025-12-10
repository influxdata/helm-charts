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

{{- define "influxdb3-enterprise.objectStoreSecretEnv" -}}
{{- if eq .Values.objectStorage.type "s3" }}
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
{{- end }}
{{- end }}

{{/*
License environment (shared across components)
*/}}
{{- define "influxdb3-enterprise.licenseEnv" -}}
{{- if or .Values.license.existingSecret (or .Values.license.email .Values.license.file) }}
{{- if .Values.license.email }}
- name: INFLUXDB3_ENTERPRISE_LICENSE_EMAIL
  valueFrom:
    secretKeyRef:
      name: {{ include "influxdb3-enterprise.licenseSecretName" . }}
      key: license-email
{{- end }}
{{- if or .Values.license.file .Values.license.existingSecret }}
- name: INFLUXDB3_ENTERPRISE_LICENSE_FILE
  value: "/etc/influxdb/license/license"
{{- end }}
- name: INFLUXDB3_ENTERPRISE_LICENSE_TYPE
  value: {{ .Values.license.type | quote }}
{{- end }}
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
