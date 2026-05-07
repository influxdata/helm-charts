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
{{- $type := .Values.objectStorage.type | default "s3" -}}
{{- $defaultSecret := printf "%s-object-storage" (include "influxdb3-enterprise.fullname" .) -}}
{{- if eq $type "s3" -}}
{{- $s3 := .Values.objectStorage.s3 | default dict -}}
{{- get $s3 "existingSecret" | default $defaultSecret -}}
{{- else if eq $type "azure" -}}
{{- $azure := .Values.objectStorage.azure | default dict -}}
{{- get $azure "existingSecret" | default $defaultSecret -}}
{{- else if eq $type "google" -}}
{{- $google := .Values.objectStorage.google | default dict -}}
{{- get $google "existingSecret" | default $defaultSecret -}}
{{- else -}}
{{- $defaultSecret -}}
{{- end -}}
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
Validate object storage type
*/}}
{{- define "influxdb3-enterprise.validateObjectStorageType" -}}
{{- $type := default "s3" .Values.objectStorage.type -}}
{{- $valid := list "s3" "azure" "google" "file" "memory" "memory-throttled" -}}
{{- if not (has $type $valid) -}}
{{- fail (printf "Invalid objectStorage.type: %s. Must be one of: %s" $type (join ", " $valid)) -}}
{{- end -}}
{{- end }}

{{/*
Validate Azure object storage auth config
*/}}
{{- define "influxdb3-enterprise.validateAzureObjectStorageAuth" -}}
{{- if eq .Values.objectStorage.type "azure" -}}
{{- $azure := .Values.objectStorage.azure | default dict -}}
{{- $existingSecret := get $azure "existingSecret" | default "" -}}
{{- $storageAccount := get $azure "storageAccount" | default "" -}}
{{- $accessKey := get $azure "accessKey" | default "" -}}
{{- if not $existingSecret -}}
{{- if not (and $storageAccount $accessKey) -}}
{{- fail "When objectStorage.type=azure and objectStorage.azure.existingSecret is not set, both objectStorage.azure.storageAccount and objectStorage.azure.accessKey must be set." -}}
{{- end -}}
{{- end -}}
{{- end -}}
{{- end }}

{{/*
Validate S3 object storage auth config
*/}}
{{- define "influxdb3-enterprise.validateS3ObjectStorageAuth" -}}
{{- if eq .Values.objectStorage.type "s3" -}}
{{- $s3 := .Values.objectStorage.s3 | default dict -}}
{{- $existingSecret := get $s3 "existingSecret" | default "" -}}
{{- $accessKeyID := get $s3 "accessKeyId" | default "" -}}
{{- $secretAccessKey := get $s3 "secretAccessKey" | default "" -}}
{{- $sessionToken := get $s3 "sessionToken" | default "" -}}
{{- if and (not $existingSecret) (or (and $accessKeyID (not $secretAccessKey)) (and (not $accessKeyID) $secretAccessKey)) -}}
{{- fail "When objectStorage.type=s3, objectStorage.s3.accessKeyId and objectStorage.s3.secretAccessKey must be set together." -}}
{{- end -}}
{{- if and (not $existingSecret) $sessionToken (not (and $accessKeyID $secretAccessKey)) -}}
{{- fail "When objectStorage.type=s3 and objectStorage.s3.sessionToken is set, both objectStorage.s3.accessKeyId and objectStorage.s3.secretAccessKey must also be set." -}}
{{- end -}}
{{- end -}}
{{- end }}

{{/*
Validate Google object storage auth config
*/}}
{{- define "influxdb3-enterprise.validateGoogleObjectStorageAuth" -}}
{{- if eq .Values.objectStorage.type "google" -}}
{{- $google := .Values.objectStorage.google | default dict -}}
{{- $existingSecret := get $google "existingSecret" | default "" -}}
{{- $serviceAccountJSON := get $google "serviceAccountJson" | default "" -}}
{{- if not (or $existingSecret $serviceAccountJSON) -}}
{{- fail "When objectStorage.type=google, set either objectStorage.google.existingSecret or objectStorage.google.serviceAccountJson." -}}
{{- end -}}
{{- end -}}
{{- end }}

{{/*
Validate object store TLS CA config
*/}}
{{- define "influxdb3-enterprise.validateObjectStoreTlsCa" -}}
{{- $tlsCa := .Values.objectStorage.tlsCa | default dict -}}
{{- $certPath := get $tlsCa "certPath" | default "" -}}
{{- $existingSecret := get $tlsCa "existingSecret" | default "" -}}
{{- if and $certPath $existingSecret -}}
{{- fail "Set only one of objectStorage.tlsCa.certPath or objectStorage.tlsCa.existingSecret." -}}
{{- end -}}
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
{{- $objectStoreSecretName := include "influxdb3-enterprise.objectStorageSecretName" . }}
{{- if eq .Values.objectStorage.type "s3" }}
  {{- $s3 := .Values.objectStorage.s3 | default dict }}
  {{- $s3ExistingSecret := get $s3 "existingSecret" | default "" }}
  {{- $s3AccessKeyID := get $s3 "accessKeyId" | default "" }}
  {{- $s3SecretAccessKey := get $s3 "secretAccessKey" | default "" }}
  {{- if or $s3ExistingSecret (and $s3AccessKeyID $s3SecretAccessKey) }}
- name: AWS_ACCESS_KEY_ID
  valueFrom:
    secretKeyRef:
      name: {{ $objectStoreSecretName }}
      key: access-key-id
- name: AWS_SECRET_ACCESS_KEY
  valueFrom:
    secretKeyRef:
      name: {{ $objectStoreSecretName }}
      key: secret-access-key
- name: AWS_SESSION_TOKEN
  valueFrom:
    secretKeyRef:
      name: {{ $objectStoreSecretName }}
      key: session-token
      optional: true
  {{- end }}
{{- else if eq .Values.objectStorage.type "azure" }}
  {{- $azure := .Values.objectStorage.azure | default dict }}
  {{- $azureExistingSecret := get $azure "existingSecret" | default "" }}
  {{- $azureStorageAccount := get $azure "storageAccount" | default "" }}
  {{- $azureAccessKey := get $azure "accessKey" | default "" }}
  {{- if $azureExistingSecret }}
- name: AZURE_STORAGE_ACCOUNT
  valueFrom:
    secretKeyRef:
      name: {{ $objectStoreSecretName }}
      key: storage-account
- name: AZURE_STORAGE_ACCESS_KEY
  valueFrom:
    secretKeyRef:
      name: {{ $objectStoreSecretName }}
      key: access-key
  {{- else if $azureStorageAccount }}
- name: AZURE_STORAGE_ACCOUNT
  value: {{ $azureStorageAccount | quote }}
  {{- if $azureAccessKey }}
- name: AZURE_STORAGE_ACCESS_KEY
  valueFrom:
    secretKeyRef:
      name: {{ $objectStoreSecretName }}
      key: access-key
  {{- end }}
  {{- end }}
{{- end }}
{{- end }}

{{/*
License environment (shared across components)
*/}}
{{- define "influxdb3-enterprise.licenseEnv" -}}
{{- if or .Values.license.existingSecret (or .Values.license.email .Values.license.file) }}
{{- $licenseType := .Values.license.type | default "trial" -}}
{{- if and (or (eq $licenseType "trial") (eq $licenseType "home")) (or .Values.license.email .Values.license.existingSecret) }}
- name: INFLUXDB3_ENTERPRISE_LICENSE_EMAIL
  valueFrom:
    secretKeyRef:
      name: {{ include "influxdb3-enterprise.licenseSecretName" . }}
      key: license-email
{{- end }}
{{- if or .Values.license.file .Values.license.existingSecret }}
- name: INFLUXDB3_ENTERPRISE_LICENSE_FILE
  value: "/etc/influxdb/license"
{{- end }}
- name: INFLUXDB3_ENTERPRISE_LICENSE_TYPE
  value: {{ $licenseType | quote }}
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
    {{- if .Values.security.tls.enabled }}
    scheme: HTTPS
    {{- end }}
  initialDelaySeconds: {{ .Values.probes.liveness.initialDelaySeconds }}
  periodSeconds: {{ .Values.probes.liveness.periodSeconds }}
  timeoutSeconds: {{ .Values.probes.liveness.timeoutSeconds }}
  failureThreshold: {{ .Values.probes.liveness.failureThreshold }}
readinessProbe:
  httpGet:
    path: /health
    port: http
    {{- if .Values.security.tls.enabled }}
    scheme: HTTPS
    {{- end }}
  initialDelaySeconds: {{ .Values.probes.readiness.initialDelaySeconds }}
  periodSeconds: {{ .Values.probes.readiness.periodSeconds }}
  timeoutSeconds: {{ .Values.probes.readiness.timeoutSeconds }}
  failureThreshold: {{ .Values.probes.readiness.failureThreshold }}
startupProbe:
  httpGet:
    path: /health
    port: http
    {{- if .Values.security.tls.enabled }}
    scheme: HTTPS
    {{- end }}
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
{{- $tag := .Values.image.tag | default (printf "%s-enterprise" .Chart.AppVersion) }}
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
{{- $s3 := .Values.objectStorage.s3 | default dict }}
{{- if and (eq .Values.objectStorage.type "s3") (get $s3 "credentialsFile") }}
- name: aws-credentials
  mountPath: /etc/influxdb/aws
  readOnly: true
{{- end }}
{{- if or .Values.license.file .Values.license.existingSecret }}
- name: license
  mountPath: /etc/influxdb/license
  subPath: license
  readOnly: true
{{- end }}
{{- if .Values.security.tls.enabled }}
- name: tls
  mountPath: /etc/influxdb/tls
  readOnly: true
{{- end }}
{{- $tlsCa := .Values.objectStorage.tlsCa | default dict }}
{{- if get $tlsCa "existingSecret" }}
- name: object-store-ca
  mountPath: /etc/influxdb/object-store-ca
  readOnly: true
{{- end }}
{{- with .Values.extraVolumeMounts }}
{{ toYaml . }}
{{- end }}
{{- end }}

{{/*
Processor plugin volume mounts (chart-managed plugins PVC or shared mounts)
*/}}
{{- define "influxdb3-enterprise.processorPluginVolumeMounts" -}}
{{- $pluginsPVCEnabled := true -}}
{{- if hasKey . "pluginsPVCEnabled" -}}
{{- $pluginsPVCEnabled = (get . "pluginsPVCEnabled") -}}
{{- end -}}
{{- $pluginDir := .pluginDir | default "/plugins" -}}
{{- $root := .root -}}
{{- if $pluginsPVCEnabled }}
- name: plugins
  mountPath: {{ $pluginDir }}
{{- end }}
{{ include "influxdb3-enterprise.sharedVolumeMounts" $root }}
{{- end }}

{{/*
Whether processor plugin volume mounts are present
*/}}
{{- define "influxdb3-enterprise.hasProcessorPluginVolumeMounts" -}}
{{- $mounts := include "influxdb3-enterprise.processorPluginVolumeMounts" . | trim -}}
{{- ternary "true" "false" (ne $mounts "") -}}
{{- end }}

{{/*
Whether processor pluginDir is actually mounted by processorPluginVolumeMounts
*/}}
{{- define "influxdb3-enterprise.hasProcessorPluginDirMount" -}}
{{- $mounts := include "influxdb3-enterprise.processorPluginVolumeMounts" . -}}
{{- $pluginDir := .pluginDir | default "/plugins" -}}
{{- $needle := printf "mountPath: %s\n" $pluginDir -}}
{{- if contains $needle (printf "%s\n" $mounts) -}}
true
{{- else -}}
false
{{- end -}}
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
{{- $s3 := .Values.objectStorage.s3 | default dict }}
{{- if and (eq .Values.objectStorage.type "s3") (get $s3 "credentialsFile") }}
- name: aws-credentials
  secret:
    secretName: {{ include "influxdb3-enterprise.fullname" . }}-aws-credentials
    items:
      - key: credentials
        path: credentials
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
{{- $tlsCa := .Values.objectStorage.tlsCa | default dict }}
{{- if get $tlsCa "existingSecret" }}
- name: object-store-ca
  secret:
    secretName: {{ get $tlsCa "existingSecret" }}
    items:
      - key: ca.crt
        path: ca.crt
{{- end }}
{{- with .Values.extraVolumes }}
{{ toYaml . }}
{{- end }}
{{- end }}
