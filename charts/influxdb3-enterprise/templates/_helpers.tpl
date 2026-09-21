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
Main configuration ConfigMap name.
*/}}
{{- define "influxdb3-enterprise.configMapName" -}}
{{- printf "%s-config" (include "influxdb3-enterprise.fullname" .) }}
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
Require acknowledgement of the InfluxDB 3.10 catalog migration.
*/}}
{{- define "influxdb3-enterprise.validateCatalogMigrationAcknowledgement" -}}
{{- if and .Release.IsUpgrade (ne (toString .Values.acknowledgeCatalogMigration) "true") -}}
{{- $name := include "influxdb3-enterprise.configMapName" . -}}
{{- $configMap := lookup "v1" "ConfigMap" .Release.Namespace $name -}}
{{- $annotations := dict -}}
{{- if $configMap -}}
{{- $annotations = $configMap.metadata.annotations | default dict -}}
{{- end -}}
{{- if ne (get $annotations "influxdata.com/catalog-format") "v3" -}}
{{- fail (printf "Could not verify influxdata.com/catalog-format=v3 on ConfigMap %q. Follow UPGRADING-3.9-TO-3.10.md, then set acknowledgeCatalogMigration: true for the one-time upgrade or client-side preview." $name) -}}
{{- end -}}
{{- end -}}
{{- end }}

{{/*
Validate object storage type
*/}}
{{- define "influxdb3-enterprise.validateObjectStorageType" -}}
{{- $type := default "s3" .Values.objectStorage.type -}}
{{- $valid := list "s3" "azure" "google" "file" -}}
{{- if not (has $type $valid) -}}
{{- fail (printf "Invalid objectStorage.type: %s. Must be one of: %s" $type (join ", " $valid)) -}}
{{- end -}}
{{- end }}

{{/*
Validate license type
*/}}
{{- define "influxdb3-enterprise.validateLicenseType" -}}
{{- $type := default "trial" .Values.license.type -}}
{{- $valid := list "trial" "commercial" -}}
{{- if not (has $type $valid) -}}
{{- fail (printf "Invalid license.type: %s. Must be one of: %s" $type (join ", " $valid)) -}}
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
{{- if and (eq $licenseType "trial") (or .Values.license.email .Values.license.existingSecret) }}
- name: INFLUXDB3_LICENSE_EMAIL
  valueFrom:
    secretKeyRef:
      name: {{ include "influxdb3-enterprise.licenseSecretName" . }}
      key: license-email
{{- end }}
{{- if .Values.license.file }}
- name: INFLUXDB3_LICENSE_FILE
  value: "/etc/influxdb/license"
{{- else if and .Values.license.existingSecret (eq $licenseType "commercial") }}
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
{{- /* The component's logs block. Precedence, lowest first: global extraEnv, these, the
     component's extraEnv - so a filter already set through extraEnv keeps winning, and a name
     is emitted once. Only the INFLUXDB3_ name counts as set: the official images since 3.10
     carry ENV INFLUXDB3_LOG_FILTER=info, which beats a legacy LOG_FILTER on the server, so
     deferring to that spelling would leave the image default. */}}
{{- $logs := .component.logs | default dict -}}
{{- $logsEnv := list -}}
{{- range $mapping := list
  (list "logFilter" "INFLUXDB3_LOG_FILTER")
  (list "logFormat" "INFLUXDB3_LOG_FORMAT")
  (list "logDestination" "INFLUXDB3_LOG_DESTINATION") }}
{{- $name := index $mapping 1 -}}
{{- $value := get $logs (index $mapping 0) -}}
{{- if and (not (kindIs "invalid" $value)) (ne (toString $value) "") (not (hasKey $componentNames $name)) }}
{{- $logsEnv = append $logsEnv (dict "name" $name "value" (toString $value)) -}}
{{- $_ := set $componentNames $name true -}}
{{- end }}
{{- end }}
{{- $extraEnv := list -}}
{{- range $env := $global }}
{{- $name := $env.name | default "" -}}
{{- if or (not $name) (not (hasKey $componentNames $name)) }}
{{- $extraEnv = append $extraEnv $env -}}
{{- end }}
{{- end }}
{{- $extraEnv = concat $extraEnv $logsEnv $component -}}
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
PachaTree environment variables shared by storage roles.
*/}}
{{- define "influxdb3-enterprise.pachaTreeEnv" -}}
{{- $engine := .Values.engine | default dict -}}
{{- $pachaTree := get $engine "pachaTree" | default dict -}}
{{- range $mapping := list
  (list "enginePathPrefix" "INFLUXDB3_ENGINE_PATH_PREFIX")
  (list "maxTotalColumns" "INFLUXDB3_MAX_TOTAL_COLUMNS")
  (list "enableRetention" "INFLUXDB3_ENABLE_RETENTION")
  (list "disableHybridQuery" "INFLUXDB3_DISABLE_HYBRID_QUERY")
  (list "enableAutoDvc" "INFLUXDB3_ENABLE_AUTO_DVC")
  (list "autoDvcMaxCardinality" "INFLUXDB3_AUTO_DVC_MAX_CARDINALITY")
  (list "autoDvcRefreshInterval" "INFLUXDB3_AUTO_DVC_REFRESH_INTERVAL")
  (list "upgradePollInterval" "INFLUXDB3_UPGRADE_POLL_INTERVAL")
  (list "fileCacheEvictAfter" "INFLUXDB3_FILE_CACHE_EVICT_AFTER")
  (list "walFlushConcurrency" "INFLUXDB3_WAL_FLUSH_CONCURRENCY")
  (list "walBufferSize" "INFLUXDB3_WAL_BUFFER_SIZE")
  (list "walSnapshotsToKeep" "INFLUXDB3_WAL_SNAPSHOTS_TO_KEEP")
  (list "snapshotSize" "INFLUXDB3_SNAPSHOT_SIZE")
  (list "snapshotDuration" "INFLUXDB3_SNAPSHOT_DURATION")
  (list "maxConcurrentSnapshots" "INFLUXDB3_MAX_CONCURRENT_SNAPSHOTS")
  (list "mergeThresholdSize" "INFLUXDB3_MERGE_THRESHOLD_SIZE")
  (list "gen0MaxRowsPerFile" "INFLUXDB3_GEN0_MAX_ROWS_PER_FILE")
  (list "gen0MaxFileSize" "INFLUXDB3_GEN0_MAX_FILE_SIZE")
  (list "walReplicaRecoveryConcurrency" "INFLUXDB3_WAL_REPLICA_RECOVERY_CONCURRENCY")
  (list "walReplicaSteadyConcurrency" "INFLUXDB3_WAL_REPLICA_STEADY_CONCURRENCY")
  (list "walReplicaQueueLength" "INFLUXDB3_WAL_REPLICA_QUEUE_LENGTH")
  (list "walReplicaRecoveryTailSkipLimit" "INFLUXDB3_WAL_REPLICA_RECOVERY_TAIL_SKIP_LIMIT")
  (list "replicaGen0LoadConcurrency" "INFLUXDB3_REPLICA_SNAPSHOT_MANIFEST_LOAD_CONCURRENCY")
  (list "replicaMaxBufferSize" "INFLUXDB3_REPLICA_MAX_BUFFER_SIZE")
  (list "shardCount" "INFLUXDB3_SHARD_COUNT")
  (list "compactorInputSizeBudget" "INFLUXDB3_COMPACTOR_INPUT_SIZE_BUDGET")
  (list "finalCompactionAge" "INFLUXDB3_FINAL_COMPACTION_AGE")
  (list "compactorCleanupCooldown" "INFLUXDB3_COMPACTOR_CLEANUP_COOLDOWN")
  (list "l1TailTargetSize" "INFLUXDB3_L1_TAIL_TARGET_SIZE")
  (list "l1TargetFileSize" "INFLUXDB3_L1_TARGET_FILE_SIZE")
  (list "l1PromotionCount" "INFLUXDB3_L1_PROMOTION_COUNT")
  (list "l2TailTargetSize" "INFLUXDB3_L2_TAIL_TARGET_SIZE")
  (list "l2TargetFileSize" "INFLUXDB3_L2_TARGET_FILE_SIZE")
  (list "l2PromotionCount" "INFLUXDB3_L2_PROMOTION_COUNT")
  (list "l3TailTargetSize" "INFLUXDB3_L3_TAIL_TARGET_SIZE")
  (list "l3TargetFileSize" "INFLUXDB3_L3_TARGET_FILE_SIZE")
  (list "l3PromotionCount" "INFLUXDB3_L3_PROMOTION_COUNT")
  (list "l4TailTargetSize" "INFLUXDB3_L4_TAIL_TARGET_SIZE")
  (list "l4TargetFileSize" "INFLUXDB3_L4_TARGET_FILE_SIZE")
}}
{{- $key := index $mapping 0 -}}
{{- if hasKey $pachaTree $key }}
- name: {{ index $mapping 1 }}
  value: {{ get $pachaTree $key | quote }}
{{- end }}
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
Effective image tag.
*/}}
{{- define "influxdb3-enterprise.imageTag" -}}
{{- .Values.image.tag | default (printf "%s-enterprise" .Chart.AppVersion) }}
{{- end }}

{{/*
Return true only when the effective image tag clearly identifies 3.10+.
Unknown tags fail closed by not receiving the catalog v3 marker.
*/}}
{{- define "influxdb3-enterprise.targetUsesCatalogV3" -}}
{{- $tag := include "influxdb3-enterprise.imageTag" . -}}
{{- $version := regexFind "^v?[0-9]+\\.[0-9]+\\.[0-9]+" $tag | trimPrefix "v" -}}
{{- if $version -}}
{{- if semverCompare ">=3.10.0-0" $version -}}true{{- end -}}
{{- end -}}
{{- end }}

{{/*
Image reference
*/}}
{{- define "influxdb3-enterprise.image" -}}
{{- $registry := .Values.image.registry }}
{{- $repository := .Values.image.repository }}
{{- $tag := include "influxdb3-enterprise.imageTag" . }}
{{- printf "%s/%s:%s" $registry $repository $tag }}
{{- end }}

{{/*
Ingester internode gRPC port.
The fallback supports upgrades using --reuse-values from releases that predate
ingester.internode.port.
*/}}
{{- define "influxdb3-enterprise.ingesterInternodePort" -}}
{{- $ingester := .Values.ingester | default dict -}}
{{- $internode := get $ingester "internode" | default dict -}}
{{- get $internode "port" | default 8183 -}}
{{- end }}

{{/*
Ingester Pod name shared by the StatefulSet, per-pod Service, and test.
*/}}
{{- define "influxdb3-enterprise.ingesterPodName" -}}
{{- printf "%s-ingester-%d" (include "influxdb3-enterprise.fullname" .root) (int .ordinal) -}}
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
{{- else if and .Values.license.existingSecret (eq $licenseType "commercial") }}
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
{{- else if and .Values.license.existingSecret (eq $licenseType "commercial") }}
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
Termination grace period for the ingester, querier, compactor and processor pods.

Returns the value as a plain decimal integer, or an empty string when the key is
absent or null so the Kubernetes default of 30s still applies. Leading zeros are
dropped because the field is rendered unquoted and YAML reads 0031 as octal 25.
*/}}
{{- define "influxdb3-enterprise.terminationGracePeriodValue" -}}
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

{{/*
Reject a grace period that ends before the drain does.

Only terminationGracePeriodSeconds, which is new, triggers the check; shutdown.timeout
has shipped since 0.10.0 as a pass-through, so it never fails on its own. The timeout
is read with humantime's unit table, case-sensitive because M is months, and a form
that table does not cover exactly, such as a fraction, is rejected while a grace period
is set. The check is a lower bound: the server finishes its background shutdown before
the drain starts.
*/}}
{{- define "influxdb3-enterprise.validateShutdownConfig" -}}
{{- $shutdown := .Values.shutdown | default dict -}}
{{- if and (hasKey $shutdown "terminationGracePeriodSeconds") (not (kindIs "invalid" (get $shutdown "terminationGracePeriodSeconds"))) -}}
{{- $grace := include "influxdb3-enterprise.terminationGracePeriodValue" . -}}
{{/* kubelet holds the grace period as nanoseconds in an int64, which ends near 9.2e9 seconds. */}}
{{- if not (regexMatch "^(0|[1-9][0-9]{0,8})$" $grace) -}}
{{- fail (printf "shutdown.terminationGracePeriodSeconds must be a whole number of seconds from 0 to 999999999, got %q." $grace) -}}
{{- end -}}
{{- $graceMs := mul ($grace | atoi) 1000 -}}
{{- if and (hasKey $shutdown "timeout") (not (kindIs "invalid" (get $shutdown "timeout"))) -}}
{{- $raw := get $shutdown "timeout" | toString | trim -}}
{{/* humantime 2.3.0's units, longest spelling first so regexFindAll does not stop at m in ms. */}}
{{- $unit := "nanos|nsec|ns|usec|us|µs|millis|msec|ms|seconds|second|secs|sec|s|minutes|minute|mins|min|m|hours|hour|hrs|hr|h|days|day|d|weeks|week|wks|wk|w|months|month|M|years|year|yrs|yr|y" -}}
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

{{/*
Check the per-component logs blocks: known keys, string values, and the value sets the
server accepts for format and destination (closed and identical since 3.9, matched
case-insensitively as the server does).

logFilter is rejected for whitespace, which the server never reads as written: a directive
is [target][=level] with no room for a space, so tracing-subscriber either fails to parse
it and panics, or folds it into the target name and the directive matches nothing. A filter
using the [span] form may legally contain spaces inside the brackets, so there the check
narrows to the ends and the commas.

The top-level logs block is left alone: it has shipped since 0.10.0, and a value that is
wrong in the same way renders there today, so a check on it would refuse an upgrade that
works now.
*/}}
{{- define "influxdb3-enterprise.validateComponentLogs" -}}
{{- $kinds := dict "float64" "number" "int64" "number" "bool" "boolean" "slice" "list" "map" "map" -}}
{{- $allowed := dict "logFormat" (list "full" "pretty" "json" "logfmt") "logDestination" (list "stdout" "stderr") -}}
{{- $keys := list "logFilter" "logFormat" "logDestination" -}}
{{- range $scope := list "ingester" "querier" "compactor" "processingEngine" -}}
{{- $component := get $.Values $scope | default dict -}}
{{- $path := printf "%s.logs" $scope -}}
{{- if and (hasKey $component "logs") (not (kindIs "invalid" (get $component "logs"))) -}}
{{- $logs := get $component "logs" -}}
{{- if not (kindIs "map" $logs) -}}
{{- fail (printf "%s must be a map with %s, got %s." $path (join ", " $keys) (get $kinds (kindOf $logs) | default "string")) -}}
{{- end -}}
{{- range $key, $value := $logs -}}
{{- if not (has $key $keys) -}}
{{- fail (printf "%s.%s is not a per-component log key; %s takes %s. queryLogSize stays in the top-level logs block." $path $key $path (join ", " $keys)) -}}
{{- end -}}
{{- if not (kindIs "invalid" $value) -}}
{{- if not (kindIs "string" $value) -}}
{{- fail (printf "%s.%s must be a string, got %s. YAML reads off, on, yes and no as booleans, so quote the value: \"off\"." $path $key (get $kinds (kindOf $value) | default "string")) -}}
{{- end -}}
{{- if eq $key "logFilter" -}}
{{- /* \s is ASCII only, so name the Unicode separators the server's trim() also folds. */ -}}
{{- $ws := "[\\s\\x{0b}\\x{85}\\p{Zs}]" -}}
{{- $pattern := ternary (printf "^%s|%s$|%s,|,%s" $ws $ws $ws $ws) $ws (contains "[" $value) -}}
{{- if regexMatch $pattern $value -}}
{{- fail (printf "%s.logFilter has whitespace the server cannot read, got %q; a directive is target=level with no space in it, so the server panics on the filter or folds the space into a target name that matches nothing. Remove the whitespace." $path $value) -}}
{{- end -}}
{{- end -}}
{{- if and (hasKey $allowed $key) (ne $value "") (not (has (lower $value) (get $allowed $key))) -}}
{{- fail (printf "%s.%s must be one of %s, got %q." $path $key (join ", " (get $allowed $key)) $value) -}}
{{- end -}}
{{- end -}}
{{- end -}}
{{- end -}}
{{- end -}}
{{- end }}

{{/*
Render a number from a values file as a plain decimal string. Such a number is a float64,
and toString prints 1000000 as 1e+06, which clap rejects for a usize.
*/}}
{{- define "influxdb3-enterprise.plainInteger" -}}
{{- if and (kindIs "float64" .) (eq (floor .) .) -}}
{{- printf "%.0f" . -}}
{{- else -}}
{{- toString . -}}
{{- end -}}
{{- end }}
