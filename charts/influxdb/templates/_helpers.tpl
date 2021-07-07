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
Format service config key values
todo: Numeric values require special handling due to the Helm upstream issue, otherwise they may be converted to scientific
notation, for example 1073741824 -> 1.073741824e+09.
Reference: https://github.com/helm/helm/issues/1707
*/}}
{{- define "influxdb.formatConfigMap" }}
{{- range $key, $value := index . }}
{{- $tp := typeOf $value }}
{{- if eq $tp "string" }}
{{ $key }} = {{ $value | quote }}
{{- else }}
{{ $key }} = {{ $value }}
{{- end }}
{{- end }}
{{- end -}}
