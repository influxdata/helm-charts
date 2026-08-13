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
Validate admin token bootstrap config
*/}}
{{- define "influxdb3-enterprise.validateAdminTokenConfig" -}}
{{- $security := .Values.security | default dict -}}
{{- $auth := get $security "auth" | default dict -}}
{{- $adminToken := get $auth "adminToken" | default dict -}}
{{- $existingSecret := get $adminToken "existingSecret" | default "" -}}
{{- $adminTokenFile := get $adminToken "file" | default "" -}}
{{- if and $existingSecret $adminTokenFile -}}
{{- fail "Set only one of security.auth.adminToken.existingSecret or security.auth.adminToken.file." -}}
{{- end -}}
{{- end }}

{{/*
Validate permission tokens bootstrap config
*/}}
{{- define "influxdb3-enterprise.validatePermissionTokensConfig" -}}
{{- $security := .Values.security | default dict -}}
{{- $auth := get $security "auth" | default dict -}}
{{- $permissionTokens := get $auth "permissionTokens" | default dict -}}
{{- $existingSecret := get $permissionTokens "existingSecret" | default "" -}}
{{- $permissionTokensFile := get $permissionTokens "file" | default "" -}}
{{- if and $existingSecret $permissionTokensFile -}}
{{- fail "Set only one of security.auth.permissionTokens.existingSecret or security.auth.permissionTokens.file." -}}
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
- name: INFLUXDB3_LICENSE_EMAIL
  valueFrom:
    secretKeyRef:
      name: {{ include "influxdb3-enterprise.licenseSecretName" . }}
      key: license-email
{{- end }}
{{- if .Values.license.file }}
- name: INFLUXDB3_LICENSE_FILE
  value: "/etc/influxdb/license"
{{- else if and .Values.license.existingSecret (and (ne $licenseType "trial") (ne $licenseType "home")) }}
- name: INFLUXDB3_LICENSE_FILE
  value: "/etc/influxdb/license"
{{- end }}
- name: INFLUXDB3_LICENSE_TYPE
  value: {{ $licenseType | quote }}
{{- end }}
{{- end }}

{{/*
Preconfigured admin token environment
*/}}
{{- define "influxdb3-enterprise.adminTokenEnv" -}}
{{- $security := .Values.security | default dict -}}
{{- $auth := get $security "auth" | default dict -}}
{{- $adminToken := get $auth "adminToken" | default dict -}}
{{- $adminTokenFile := get $adminToken "file" | default "" -}}
{{- if get $adminToken "existingSecret" }}
- name: INFLUXDB3_ADMIN_TOKEN_FILE
  value: "/etc/influxdb/admin-token/admin-token.json"
{{- else if $adminTokenFile }}
- name: INFLUXDB3_ADMIN_TOKEN_FILE
  value: {{ $adminTokenFile | quote }}
{{- end }}
{{- end }}

{{/*
Preconfigured permission tokens environment
*/}}
{{- define "influxdb3-enterprise.permissionTokensEnv" -}}
{{- $security := .Values.security | default dict -}}
{{- $auth := get $security "auth" | default dict -}}
{{- $permissionTokens := get $auth "permissionTokens" | default dict -}}
{{- $permissionTokensFile := get $permissionTokens "file" | default "" -}}
{{- if get $permissionTokens "existingSecret" }}
- name: INFLUXDB3_PERMISSION_TOKENS_FILE
  value: "/etc/influxdb/permission-tokens/permission-tokens.json"
{{- else if $permissionTokensFile }}
- name: INFLUXDB3_PERMISSION_TOKENS_FILE
  value: {{ $permissionTokensFile | quote }}
{{- end }}
{{- end }}

{{/*
Pod name environment for stable StatefulSet node IDs
*/}}
{{- define "influxdb3-enterprise.podNameEnv" -}}
- name: POD_NAME
  valueFrom:
    fieldRef:
      fieldPath: metadata.name
{{- end }}

{{/*
Global plus component-specific extra environment variables.
Component-specific entries override global entries with the same name.
*/}}
{{- define "influxdb3-enterprise.componentExtraEnv" -}}
{{- $global := .root.Values.extraEnv | default (list) -}}
{{- $component := .component.extraEnv | default (list) -}}
{{- $componentNames := dict -}}
{{- range $env := $component }}
{{- with $env.name }}
{{- $_ := set $componentNames . true -}}
{{- end }}
{{- end }}
{{- $extraEnv := list -}}
{{- range $env := $global }}
{{- $name := $env.name | default "" -}}
{{- if or (not $name) (not (hasKey $componentNames $name)) }}
{{- $extraEnv = append $extraEnv $env -}}
{{- end }}
{{- end }}
{{- $extraEnv = concat $extraEnv $component -}}
{{- if $extraEnv }}
{{- toYaml $extraEnv }}
{{- end }}
{{- end }}

{{/*
Air-gap protection for non-processor pods. If the user explicitly sets
INFLUXDB3_UNSET_VARS through extraEnv, that value is authoritative.
Docs:
https://docs.influxdata.com/influxdb3/enterprise/reference/config-options/#disable-the-processing-engine
*/}}
{{- define "influxdb3-enterprise.nonProcessorUnsetVars" -}}
{{- $global := .root.Values.extraEnv | default (list) -}}
{{- $component := .component.extraEnv | default (list) -}}
{{- $userSet := false -}}
{{- range (concat $global $component) -}}
{{- if eq (.name | default "") "INFLUXDB3_UNSET_VARS" -}}
{{- $userSet = true -}}
{{- end -}}
{{- end -}}
{{- if not $userSet }}
- name: INFLUXDB3_UNSET_VARS
  value: "INFLUXDB3_PLUGIN_DIR"
{{- end -}}
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
{{- if eq .Values.objectStorage.type "file" }}
- name: object-storage
  mountPath: {{ .Values.objectStorage.file.dataDir }}
{{- end }}
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
{{- $licenseType := .Values.license.type | default "trial" -}}
{{- if .Values.license.file }}
- name: license
  mountPath: /etc/influxdb/license
  subPath: license
  readOnly: true
{{- else if and .Values.license.existingSecret (and (ne $licenseType "trial") (ne $licenseType "home")) }}
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
Admin token volume mounts
*/}}
{{- define "influxdb3-enterprise.adminTokenVolumeMounts" -}}
{{- $security := .Values.security | default dict -}}
{{- $auth := get $security "auth" | default dict -}}
{{- $adminToken := get $auth "adminToken" | default dict -}}
{{- if get $adminToken "existingSecret" }}
- name: admin-token
  mountPath: /etc/influxdb/admin-token
  readOnly: true
{{- end }}
{{- end }}

{{/*
Permission tokens volume mounts
*/}}
{{- define "influxdb3-enterprise.permissionTokensVolumeMounts" -}}
{{- $security := .Values.security | default dict -}}
{{- $auth := get $security "auth" | default dict -}}
{{- $permissionTokens := get $auth "permissionTokens" | default dict -}}
{{- if get $permissionTokens "existingSecret" }}
- name: permission-tokens
  mountPath: /etc/influxdb/permission-tokens
  readOnly: true
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
{{- $licenseType := .Values.license.type | default "trial" -}}
{{- if .Values.license.file }}
- name: license
  secret:
    secretName: {{ include "influxdb3-enterprise.licenseSecretName" . }}
    optional: true
    items:
      - key: license-file
        path: license
{{- else if and .Values.license.existingSecret (and (ne $licenseType "trial") (ne $licenseType "home")) }}
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

{{/*
Web UI session secret name
*/}}
{{- define "influxdb3-enterprise.webuiSecretName" -}}
{{- $webui := .Values.webui | default dict -}}
{{- get $webui "existingSecret" | default (printf "%s-webui" (include "influxdb3-enterprise.fullname" .)) -}}
{{- end }}

{{/*
Web UI session secret environment
*/}}
{{- define "influxdb3-enterprise.webuiSessionSecretEnv" -}}
{{- $webui := .Values.webui | default dict -}}
{{- if or (get $webui "existingSecret") (get $webui "sessionSecret") }}
- name: INFLUXDB3_WEBUI_SESSION_SECRET
  valueFrom:
    secretKeyRef:
      name: {{ include "influxdb3-enterprise.webuiSecretName" . }}
      key: session-secret
{{- end }}
{{- end }}

{{/*
Admin token volumes
*/}}
{{- define "influxdb3-enterprise.adminTokenVolumes" -}}
{{- $security := .Values.security | default dict -}}
{{- $auth := get $security "auth" | default dict -}}
{{- $adminToken := get $auth "adminToken" | default dict -}}
{{- if get $adminToken "existingSecret" }}
- name: admin-token
  secret:
    secretName: {{ get $adminToken "existingSecret" }}
    items:
      - key: admin-token.json
        path: admin-token.json
{{- end }}
{{- end }}

{{/*
Permission tokens volumes
*/}}
{{- define "influxdb3-enterprise.permissionTokensVolumes" -}}
{{- $security := .Values.security | default dict -}}
{{- $auth := get $security "auth" | default dict -}}
{{- $permissionTokens := get $auth "permissionTokens" | default dict -}}
{{- if get $permissionTokens "existingSecret" }}
- name: permission-tokens
  secret:
    secretName: {{ get $permissionTokens "existingSecret" }}
    items:
      - key: permission-tokens.json
        path: permission-tokens.json
{{- end }}
{{- end }}

{{/*
PachaTree engine environment variables
*/}}
{{- define "influxdb3-enterprise.pachaTreeEnv" -}}
{{- with .Values.engine.pachaTree }}
{{- if .enginePathPrefix }}
- name: INFLUXDB3_ENGINE_PATH_PREFIX
  value: {{ .enginePathPrefix | quote }}
{{- end }}
{{- if .shardCount }}
- name: INFLUXDB3_SHARD_COUNT
  value: {{ .shardCount | quote }}
{{- end }}
{{- if .maxTotalColumns }}
- name: INFLUXDB3_MAX_TOTAL_COLUMNS
  value: {{ .maxTotalColumns | quote }}
{{- end }}
{{- if hasKey . "enableRetention" }}
- name: INFLUXDB3_ENABLE_RETENTION
  value: {{ ternary "true" "false" .enableRetention | quote }}
{{- end }}
{{- if .snapshotSize }}
- name: INFLUXDB3_SNAPSHOT_SIZE
  value: {{ .snapshotSize | quote }}
{{- end }}
{{- if .gen0MaxFileSize }}
- name: INFLUXDB3_GEN0_MAX_FILE_SIZE
  value: {{ .gen0MaxFileSize | quote }}
{{- end }}
{{- if .walReplicaQueueLength }}
- name: INFLUXDB3_WAL_REPLICA_QUEUE_LENGTH
  value: {{ .walReplicaQueueLength | quote }}
{{- end }}
{{- if .walBufferSize }}
- name: INFLUXDB3_WAL_BUFFER_SIZE
  value: {{ .walBufferSize | quote }}
{{- end }}
{{- if .walFlushConcurrency }}
- name: INFLUXDB3_WAL_FLUSH_CONCURRENCY
  value: {{ .walFlushConcurrency | quote }}
{{- end }}
{{- if .snapshotDuration }}
- name: INFLUXDB3_SNAPSHOT_DURATION
  value: {{ .snapshotDuration | quote }}
{{- end }}
{{- if .maxConcurrentSnapshots }}
- name: INFLUXDB3_MAX_CONCURRENT_SNAPSHOTS
  value: {{ .maxConcurrentSnapshots | quote }}
{{- end }}
{{- if .walSnapshotsToKeep }}
- name: INFLUXDB3_WAL_SNAPSHOTS_TO_KEEP
  value: {{ .walSnapshotsToKeep | quote }}
{{- end }}
{{- if .gen0MaxRowsPerFile }}
- name: INFLUXDB3_GEN0_MAX_ROWS_PER_FILE
  value: {{ .gen0MaxRowsPerFile | quote }}
{{- end }}
{{- if .mergeThresholdSize }}
- name: INFLUXDB3_MERGE_THRESHOLD_SIZE
  value: {{ .mergeThresholdSize | quote }}
{{- end }}
{{- if .l1TailTargetSize }}
- name: INFLUXDB3_L1_TAIL_TARGET_SIZE
  value: {{ .l1TailTargetSize | quote }}
{{- end }}
{{- if .l1ConsolidationTargetSize }}
- name: INFLUXDB3_L1_CONSOLIDATION_TARGET_SIZE
  value: {{ .l1ConsolidationTargetSize | quote }}
{{- end }}
{{- if .l1ConsolidationMinAge }}
- name: INFLUXDB3_L1_CONSOLIDATION_MIN_AGE
  value: {{ .l1ConsolidationMinAge | quote }}
{{- end }}
{{- if .l1ConsolidationMinRunSets }}
- name: INFLUXDB3_L1_CONSOLIDATION_MIN_RUN_SETS
  value: {{ .l1ConsolidationMinRunSets | quote }}
{{- end }}
{{- if .l1TargetFileSize }}
- name: INFLUXDB3_L1_TARGET_FILE_SIZE
  value: {{ .l1TargetFileSize | quote }}
{{- end }}
{{- if .l1PromotionCount }}
- name: INFLUXDB3_L1_PROMOTION_COUNT
  value: {{ .l1PromotionCount | quote }}
{{- end }}
{{- if .l2TailTargetSize }}
- name: INFLUXDB3_L2_TAIL_TARGET_SIZE
  value: {{ .l2TailTargetSize | quote }}
{{- end }}
{{- if .l2TargetFileSize }}
- name: INFLUXDB3_L2_TARGET_FILE_SIZE
  value: {{ .l2TargetFileSize | quote }}
{{- end }}
{{- if .l2PromotionCount }}
- name: INFLUXDB3_L2_PROMOTION_COUNT
  value: {{ .l2PromotionCount | quote }}
{{- end }}
{{- if .l3TailTargetSize }}
- name: INFLUXDB3_L3_TAIL_TARGET_SIZE
  value: {{ .l3TailTargetSize | quote }}
{{- end }}
{{- if .l3TargetFileSize }}
- name: INFLUXDB3_L3_TARGET_FILE_SIZE
  value: {{ .l3TargetFileSize | quote }}
{{- end }}
{{- if .l3PromotionCount }}
- name: INFLUXDB3_L3_PROMOTION_COUNT
  value: {{ .l3PromotionCount | quote }}
{{- end }}
{{- if .l4TailTargetSize }}
- name: INFLUXDB3_L4_TAIL_TARGET_SIZE
  value: {{ .l4TailTargetSize | quote }}
{{- end }}
{{- if .l4TargetFileSize }}
- name: INFLUXDB3_L4_TARGET_FILE_SIZE
  value: {{ .l4TargetFileSize | quote }}
{{- end }}
{{- if .finalCompactionAge }}
- name: INFLUXDB3_FINAL_COMPACTION_AGE
  value: {{ .finalCompactionAge | quote }}
{{- end }}
{{- if .compactorInputSizeBudget }}
- name: INFLUXDB3_COMPACTOR_INPUT_SIZE_BUDGET
  value: {{ .compactorInputSizeBudget | quote }}
{{- end }}
{{- if .compactorMaxConcurrentMerges }}
- name: INFLUXDB3_COMPACTOR_MAX_CONCURRENT_MERGES
  value: {{ .compactorMaxConcurrentMerges | quote }}
{{- end }}
{{- if .compactorMaxSourceRunSetsPerPromotion }}
- name: INFLUXDB3_COMPACTOR_MAX_SOURCE_RUN_SETS_PER_PROMOTION
  value: {{ .compactorMaxSourceRunSetsPerPromotion | quote }}
{{- end }}
{{- if .compactorJobHeartbeatTimeout }}
- name: INFLUXDB3_COMPACTOR_JOB_HEARTBEAT_TIMEOUT
  value: {{ .compactorJobHeartbeatTimeout | quote }}
{{- end }}
{{- if .compactorCleanupCooldown }}
- name: INFLUXDB3_COMPACTOR_CLEANUP_COOLDOWN
  value: {{ .compactorCleanupCooldown | quote }}
{{- end }}
{{- if .walReplicaRecoveryConcurrency }}
- name: INFLUXDB3_WAL_REPLICA_RECOVERY_CONCURRENCY
  value: {{ .walReplicaRecoveryConcurrency | quote }}
{{- end }}
{{- if .walReplicaSteadyConcurrency }}
- name: INFLUXDB3_WAL_REPLICA_STEADY_CONCURRENCY
  value: {{ .walReplicaSteadyConcurrency | quote }}
{{- end }}
{{- if .walReplicaRecoveryTailSkipLimit }}
- name: INFLUXDB3_WAL_REPLICA_RECOVERY_TAIL_SKIP_LIMIT
  value: {{ .walReplicaRecoveryTailSkipLimit | quote }}
{{- end }}
{{- if .replicaGen0LoadConcurrency }}
- name: INFLUXDB3_REPLICA_GEN0_LOAD_CONCURRENCY
  value: {{ .replicaGen0LoadConcurrency | quote }}
{{- end }}
{{- if .replicaMaxBufferSize }}
- name: INFLUXDB3_REPLICA_MAX_BUFFER_SIZE
  value: {{ .replicaMaxBufferSize | quote }}
{{- end }}
{{- if .fileCacheEvictAfter }}
- name: INFLUXDB3_FILE_CACHE_EVICT_AFTER
  value: {{ .fileCacheEvictAfter | quote }}
{{- end }}
{{- if hasKey . "enableAutoDvc" }}
- name: INFLUXDB3_ENABLE_AUTO_DVC
  value: {{ ternary "true" "false" .enableAutoDvc | quote }}
{{- end }}
{{- if .autoDvcMaxCardinality }}
- name: INFLUXDB3_AUTO_DVC_MAX_CARDINALITY
  value: {{ .autoDvcMaxCardinality | quote }}
{{- end }}
{{- if .autoDvcRefreshInterval }}
- name: INFLUXDB3_AUTO_DVC_REFRESH_INTERVAL
  value: {{ .autoDvcRefreshInterval | quote }}
{{- end }}
{{- if hasKey . "disableHybridQuery" }}
- name: INFLUXDB3_DISABLE_HYBRID_QUERY
  value: {{ ternary "true" "false" .disableHybridQuery | quote }}
{{- end }}
{{- end }}
{{- end }}
