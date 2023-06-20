{{/* vim: set filetype=mustache: */}}
{{/*
Expand the name of the chart.
*/}}
{{- define "influxdb.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "influxdb.fullname" -}}
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
{{- define "influxdb.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Common labels
*/}}
{{- define "influxdb.labels" -}}
helm.sh/chart: {{ include "influxdb.chart" . }}
{{ include "influxdb.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end -}}

{{/*
Selector labels
*/}}
{{- define "influxdb.selectorLabels" -}}
app.kubernetes.io/name: {{ include "influxdb.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end -}}

{{/*
Create the name of the service account to use
*/}}
{{- define "influxdb.serviceAccountName" -}}
{{- if .Values.serviceAccount.create -}}
  {{ default (include "influxdb.fullname" .) .Values.serviceAccount.name }}
{{- else -}}
  {{ default "default" .Values.serviceAccount.name }}
{{- end -}}
{{- end -}}

{{/*
Define ports for kubernetes.
*/}}
{{- define "influxdb.rpcPortNumber" -}}
  {{ default 8088 (regexReplaceAll ":([0-9]+)" (index .Values "config" "rpc" "bind-address") "${1}") }}
{{- end -}}
{{- define "influxdb.metaPortNumber" -}}
  {{ default 8091 (regexReplaceAll ":([0-9]+)" (index .Values "config" "meta" "bind-address") "${1}") }}
{{- end -}}
{{- define "influxdb.httpPortNumber" -}}
  {{ default 8086 (regexReplaceAll ":([0-9]+)" (index .Values "config" "http" "bind-address") "${1}") }}
{{- end -}}
{{- define "influxdb.graphitePortNumber" -}}
  {{ default 2003 (regexReplaceAll ":([0-9]+)" (index .Values "config" "graphite" "bind-address") "${1}") }}
{{- end -}}
{{- define "influxdb.collectdPortNumber" -}}
  {{ default 25826 (regexReplaceAll ":([0-9]+)" (index .Values "config" "collectd" "bind-address") "${1}") }}
{{- end -}}
{{- define "influxdb.opentsdbPortNumber" -}}
  {{ default 4242 (regexReplaceAll ":([0-9]+)" (index .Values "config" "opentsdb" "bind-address") "${1}") }}
{{- end -}}
{{- define "influxdb.udpPortNumber" -}}
  {{ default 8089 (regexReplaceAll ":([0-9]+)" (index .Values "config" "udp" "bind-address") "${1}") }}
{{- end -}}
