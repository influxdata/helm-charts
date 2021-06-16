{{/* vim: set filetype=mustache: */}}
{{/*
Expand the name of the chart.
*/}}
{{- define "telegraf-operator.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "telegraf-operator.fullname" -}}
{{- if .Values.fullnameOverride -}}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- if contains $name .Release.Name -}}
{{- .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "telegraf-operator.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Common labels
*/}}
{{- define "telegraf-operator.labels" -}}
helm.sh/chart: {{ include "telegraf-operator.chart" . }}
{{ include "telegraf-operator.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end -}}

{{/*
Selector labels
*/}}
{{- define "telegraf-operator.selectorLabels" -}}
app.kubernetes.io/name: {{ include "telegraf-operator.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end -}}

{{/*
Create the name of the service account to use
*/}}
{{- define "telegraf-operator.serviceAccountName" -}}
{{- if .Values.serviceAccount.create -}}
    {{ default (include "telegraf-operator.fullname" .) .Values.serviceAccount.name }}
{{- else -}}
    {{ default "default" .Values.serviceAccount.name }}
{{- end -}}
{{- end -}}

{{/*
Generate certificates for telegraf-operator mutating webhook
*/}}
{{- define "telegraf-operator.non_certmanager" -}}
{{- $altNames := list ( printf "%s.%s" (include "telegraf-operator.fullname" .) .Release.Namespace ) ( printf "%s.%s.svc" (include "telegraf-operator.fullname" .) .Release.Namespace ) -}}
{{- $ca := genCA "telegraf-operator-ca" 365 -}}
{{- $cert := genSignedCert ( include "telegraf-operator.fullname" . ) nil $altNames 365 $ca -}}
apiVersion: admissionregistration.k8s.io/v1
kind: MutatingWebhookConfiguration
metadata:
  annotations:
    cert-manager.io/inject-ca-from: "{{ .Values.namespace }}/{{ include "telegraf-operator.fullname" . }}"
  labels:
    {{- include "telegraf-operator.labels" . | nindent 4 }}
  name: {{ include "telegraf-operator.fullname" . }}
webhooks:
- clientConfig:
    service:
      name: {{ include "telegraf-operator.fullname" . }}
      namespace: {{ .Release.Namespace }}
      path: /mutate-v1-pod
    caBundle: {{ $ca.Cert | b64enc }}
  failurePolicy: Ignore
  sideEffects: None
  admissionReviewVersions:
  - 'v1'
  name: telegraf.influxdata.com
  rules:
  - apiGroups:
    - '*'
    apiVersions:
    - '*'
    operations:
    - CREATE
    - DELETE
    resources:
    - pods
---
apiVersion: v1
kind: Secret
type: kubernetes.io/tls
metadata:
  name: telegraf-operator-tls
  labels:
    {{- include "telegraf-operator.labels" . | nindent 4 }}
  annotations:
    "helm.sh/hook": "pre-install,pre-upgrade"
    "helm.sh/hook-delete-policy": "before-hook-creation"
data:
  tls.crt: {{ $cert.Cert | b64enc }}
  tls.key: {{ $cert.Key | b64enc }}
{{- end -}}
