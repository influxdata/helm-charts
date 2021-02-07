{{/* vim: set filetype=mustache: */}}
{{/*
Expand the name of the chart.
*/}}
{{- define "influxdb-enterprise.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "influxdb-enterprise.fullname" -}}
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
{{- define "influxdb-enterprise.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "influxdb-enterprise.labels" -}}
helm.sh/chart: {{ include "influxdb-enterprise.chart" . }}
{{ include "influxdb-enterprise.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "influxdb-enterprise.selectorLabels" -}}
app.kubernetes.io/name: {{ include "influxdb-enterprise.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account
*/}}
{{- define "influxdb-enterprise.serviceAccountName" -}}
{{- if .Values.serviceAccount.create -}}
    {{ default (include "influxdb-enterprise.fullname" .) .Values.serviceAccount.name }}
{{- else -}}
    {{ default "default" .Values.serviceAccount.name }}
{{- end -}}
{{- end -}}

{{- define "influxdb-enterprise.image" -}}
{{- $dataTagName := (printf "%s-%s" .chart.AppVersion .podtype) -}}
{{- if (.imageroot) }}
{{- if (.imageroot.tag) -}}
{{- $dataTagName = .imageroot.tag -}}
{{- end -}}
{{- if (.imageroot.addsuffix) -}}
{{- $dataTagName = printf "%s-%s" $dataTagName .podtype -}}
{{- end -}}
{{- end }}
image: "{{ .podvals.image.repository | default "influxdb" }}:{{ $dataTagName }}"
{{- end }}
