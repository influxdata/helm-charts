{{/* vim: set filetype=mustache: */}}
{{/*
Expand the name of the chart.
*/}}
{{- define "telegraf.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "telegraf.fullname" -}}
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
{{- define "telegraf.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Common labels
*/}}
{{- define "telegraf.labels" -}}
helm.sh/chart: {{ include "telegraf.chart" . }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{ include "telegraf.selectorLabels" . }}
{{- end -}}

{{/*
Selector labels
*/}}
{{- define "telegraf.selectorLabels" -}}
app.kubernetes.io/name: {{ include "telegraf.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end -}}


{{/*
  CUSTOM TEMPLATES: This section contains templates that make up the different parts of the telegraf configuration file.
  - global_tags section
  - agent section
*/}}

{{- define "global_tags" -}}
{{- if . -}}
[global_tags]
  {{- range $key, $val := . }}
      {{ $key }} = {{ $val | quote }}
  {{- end }}
{{- end }}
{{- end -}}

{{- define "agent" -}}
[agent]
{{- range $key, $value := . -}}
  {{- $tp := typeOf $value }}
  {{- if eq $tp "string"}}
      {{ $key }} = {{ $value | quote }}
  {{- end }}
  {{- if eq $tp "float64"}}
      {{ $key }} = {{ $value | int64 }}
  {{- end }}
  {{- if eq $tp "int"}}
      {{ $key }} = {{ $value | int64 }}
  {{- end }}
  {{- if eq $tp "bool"}}
      {{ $key }} = {{ $value }}
  {{- end }}
{{- end }}
{{- end -}}

{{- define "outputs.v1" -}}
{{- range $outputIdx, $configObject := . -}}
    {{- range $output, $config := . -}}

    [[outputs.{{- $output }}]]
    {{- if $config -}}
    {{- $tp := typeOf $config -}}
    {{- if eq $tp "map[string]interface {}" -}}
        {{- range $key, $value := $config -}}
          {{- $tp := typeOf $value -}}
          {{- if eq $tp "string" }}
      {{ $key }} = {{ $value | quote }}
          {{- end }}
          {{- if eq $tp "float64" }}
      {{ $key }} = {{ $value | int64 }}
          {{- end }}
          {{- if eq $tp "int" }}
      {{ $key }} = {{ $value | int64 }}
          {{- end }}
          {{- if eq $tp "bool" }}
      {{ $key }} = {{ $value }}
          {{- end }}
          {{- if eq $tp "[]interface {}" }}
      {{ $key }} = [
              {{- $numOut := len $value }}
              {{- $numOut := sub $numOut 1 }}
              {{- range $b, $val := $value }}
                {{- $i := int64 $b }}
                {{- $tp := typeOf $val }}
                {{- if eq $i $numOut }}
                  {{- if eq $tp "string" }}
        {{ $val | quote }}
                  {{- end }}
                  {{- if eq $tp "float64" }}
        {{ $val | int64 }}
                  {{- end }}
                {{- else }}
                  {{- if eq $tp "string" }}
        {{ $val | quote }},
                  {{- end}}
                  {{- if eq $tp "float64" }}
        {{ $val | int64 }},
                  {{- end }}
                {{- end }}
              {{- end }}
      ]
          {{- end }}
        {{- end }}
        {{- range $key, $value := $config -}}
          {{- $tp := typeOf $value -}}
          {{- if eq $tp "map[string]interface {}" }}
      [outputs.{{ $output }}.{{ $key }}]
            {{- range $k, $v := $value }}
              {{- $tps := typeOf $v }}
              {{- if eq $tps "string" }}
        {{ $k }} = {{ $v | quote }}
              {{- end }}
              {{- if eq $tps "float64" }}
        {{ $k }} = {{ $v | int64 }}.0
              {{- end }}
              {{- if eq $tps "int64" }}
        {{ $k }} = {{ $v | int64 }}
              {{- end }}
              {{- if eq $tps "bool" }}
        {{ $k }} = {{ $v }}
              {{- end }}
              {{- if eq $tps "[]interface {}"}}
        {{ $k }} = [
                {{- $numOut := len $v }}
                {{- $numOut := sub $numOut 1 }}
                {{- range $b, $val := $v }}
                  {{- $i := int64 $b }}
                  {{- if eq $i $numOut }}
            {{ $val | quote }}
                  {{- else }}
            {{ $val | quote }},
                  {{- end }}
                {{- end }}
        ]
              {{- end }}
              {{- if eq $tps "map[string]interface {}"}}
          [outputs.{{ $output }}.{{ $key }}.{{ $k }}]
                {{- range $foo, $bar := $v }}
            {{ $foo }} = {{ $bar | quote }}
                {{- end }}
              {{- end }}
            {{- end }}
          {{- end }}
          {{- end }}
    {{- end }}
    {{- end }}
    {{ end }}
{{- end }}
{{- end -}}

{{- define "inputs.v1" -}}
{{- range $inputIdx, $configObject := . -}}
    {{- range $input, $config := . -}}

    [[inputs.{{- $input }}]]
    {{- if $config -}}
    {{- $tp := typeOf $config -}}
    {{- if eq $tp "map[string]interface {}" -}}
        {{- range $key, $value := $config -}}
          {{- $tp := typeOf $value -}}
          {{- if eq $tp "string" }}
      {{ $key }} = {{ $value | quote }}
          {{- end }}
          {{- if eq $tp "float64" }}
      {{ $key }} = {{ $value | int64 }}
          {{- end }}
          {{- if eq $tp "int" }}
      {{ $key }} = {{ $value | int64 }}
          {{- end }}
          {{- if eq $tp "bool" }}
      {{ $key }} = {{ $value }}
          {{- end }}
          {{- if eq $tp "[]interface {}" }}
            {{- if eq (index $value 0 | typeOf) "map[string]interface {}" -}}
              {{- range $b, $val := $value }}
      [[inputs.{{- $input }}.{{- $key }}]]
                {{- range $k, $v := $val }}
                  {{- $tps := typeOf $v }}
                  {{- if eq $tps "string" }}
         {{ $k }} = {{ $v | quote }}
                  {{- end }}
                  {{- if eq $tps "float64" }}
         {{ $k }} = {{ $v | int64 }}
                  {{- end }}
                  {{- if eq $tps "bool" }}
         {{ $k }} = {{ $v }}
                  {{- end }}
                {{- end }}
              {{- end }}
            {{- else }}
      {{ $key }} = [
              {{- $numOut := len $value }}
              {{- $numOut := sub $numOut 1 }}
              {{- range $b, $val := $value }}
                {{- $i := int64 $b }}
                {{- $tp := typeOf $val }}
                {{- if eq $tp "string" }}
        {{ $val | quote }}
                {{- end }}
                {{- if eq $tp "float64" }}
                  {{- if eq $key "percentiles" }}
                    {{- $xval := float64 (int64 $val) }}
                    {{- if eq $val $xval }}
        {{ $val | int64 }}.0
                    {{- else }}
        {{ $val | float64 }}
                    {{- end }}
                  {{- else }}
        {{ $val | int64 }}
                  {{- end }}
                {{- end }}
                {{- if ne $i $numOut -}}
        ,
                {{- end -}}
              {{- end }}
      ]
            {{- end }}
          {{- end }}
          {{- end }}
          {{- range $key, $value := $config -}}
          {{- $tp := typeOf $value -}}
          {{- if eq $tp "map[string]interface {}" }}
      [inputs.{{ $input }}.{{ $key }}]
            {{- range $k, $v := $value }}
              {{- $tps := typeOf $v }}
              {{- if eq $tps "string" }}
        {{ $k }} = {{ $v | quote }}
              {{- end }}
              {{- if eq $tps "[]interface {}"}}
        {{ $k }} = [
                {{- $numOut := len $v }}
                {{- $numOut := sub $numOut 1 }}
                {{- range $b, $val := $v }}
                  {{- $i := int64 $b }}
                  {{- if eq $i $numOut }}
            {{ $val | quote }}
                  {{- else }}
            {{ $val | quote }},
                  {{- end }}
                {{- end }}
        ]
              {{- end }}
              {{- end }}
              {{- range $k, $v := $value }}
              {{- $tps := typeOf $v }}
              {{- if eq $tps "map[string]interface {}"}}
          [inputs.{{ $input }}.{{ $key }}.{{ $k }}]
                {{- range $foo, $bar := $v }}
            {{ $foo }} = {{ $bar | quote }}
                {{- end }}
              {{- end }}
            {{- end }}
          {{- end }}
          {{- end }}
    {{- end }}
    {{- end }}
    {{ end }}
{{- end }}
{{- end -}}

{{- define "processors.v1" -}}
{{- range $processorIdx, $configObject := . -}}
    {{- range $processor, $config := . -}}

    [[processors.{{- $processor }}]]
    {{- if $config -}}
    {{- $tp := typeOf $config -}}
    {{- if eq $tp "map[string]interface {}" -}}
        {{- range $key, $value := $config -}}
          {{- $tp := typeOf $value -}}
          {{- if eq $tp "string" }}
      {{ $key }} = {{ $value | quote }}
          {{- end }}
          {{- if eq $tp "float64" }}
      {{ $key }} = {{ $value | int64 }}
          {{- end }}
          {{- if eq $tp "int" }}
      {{ $key }} = {{ $value | int64 }}
          {{- end }}
          {{- if eq $tp "bool" }}
      {{ $key }} = {{ $value }}
          {{- end }}
          {{- if eq $tp "[]interface {}" }}
      {{ $key }} = [
              {{- $numOut := len $value }}
              {{- $numOut := sub $numOut 1 }}
              {{- range $b, $val := $value }}
                {{- $i := int64 $b }}
                {{- $tp := typeOf $val }}
                {{- if eq $i $numOut }}
                  {{- if eq $tp "string" }}
        {{ $val | quote }}
                  {{- end }}
                  {{- if eq $tp "float64" }}
        {{ $val | int64 }}
                  {{- end }}
                {{- else }}
                  {{- if eq $tp "string" }}
        {{ $val | quote }},
                  {{- end}}
                  {{- if eq $tp "float64" }}
        {{ $val | int64 }},
                  {{- end }}
                {{- end }}
              {{- end }}
      ]
          {{- end }}
          {{- end }}
          {{- range $key, $value := $config -}}
          {{- $tp := typeOf $value -}}
          {{- if eq $tp "map[string]interface {}" }}
      {{- if or (eq $processor "converter") (eq $processor "override") (eq $processor "clone") }}
      [processors.{{ $processor }}.{{ $key }}]
            {{- range $k, $v := $value }}
              {{- $tps := typeOf $v }}
              {{- if eq $tps "string" }}
        {{ $k }} = {{ $v | quote }}
              {{- end }}
              {{- if eq $tps "[]interface {}"}}
        {{ $k }} = [
                {{- $numOut := len $v }}
                {{- $numOut := sub $numOut 1 }}
                {{- range $b, $val := $v }}
                  {{- $i := int64 $b }}
                  {{- if eq $i $numOut }}
            {{ $val | quote }}
                  {{- else }}
            {{ $val | quote }},
                  {{- end }}
                {{- end }}
        ]
              {{- end }}
              {{- end }}
      {{- else }}
       [[processors.{{ $processor }}.{{ $key }}]]
            {{- range $k, $v := $value }}
              {{- $tps := typeOf $v }}
              {{- if eq $tps "string" }}
        {{ $k }} = {{ $v | quote }}
              {{- end }}
              {{- if eq $tps "[]interface {}"}}
        {{ $k }} = [
                {{- $numOut := len $v }}
                {{- $numOut := sub $numOut 1 }}
                {{- range $b, $val := $v }}
                  {{- $i := int64 $b }}
                  {{- if eq $i $numOut }}
            {{ $val | quote }}
                  {{- else }}
            {{ $val | quote }},
                  {{- end }}
                {{- end }}
        ]
              {{- end }}
              {{- end }}
              {{- range $k, $v := $value }}
              {{- $tps := typeOf $v }}
              {{- if eq $tps "map[string]interface {}"}}
        [processors.{{ $processor }}.{{ $key }}.{{ $k }}]
                {{- range $foo, $bar := $v }}
                {{- $tp := typeOf $bar -}}
                {{- if eq $tp "string" }}
            {{ $foo }} = {{ $bar | quote }}
                {{- end }}
                {{- if eq $tp "int" }}
            {{ $foo }} = {{ $bar }}
                {{- end }}
                {{- if eq $tp "float64" }}
            {{ $foo }} = {{ int64 $bar }}
                {{- end }}
                {{- end }}
              {{- end }}
            {{- end }}
          {{- end }}
          {{- end }}
      {{- end }}
    {{- end }}
    {{- end }}
    {{ end }}
{{- end }}
{{- end -}}

{{- define "aggregators.v1" -}}
{{- range $aggregatorIdx, $configObject := . -}}
    {{- range $aggregator, $config := . -}}

    [[aggregators.{{- $aggregator }}]]
    {{- if $config -}}
    {{- $tp := typeOf $config -}}
    {{- if eq $tp "map[string]interface {}" -}}
        {{- range $key, $value := $config -}}
          {{- $tp := typeOf $value -}}
          {{- if eq $tp "string" }}
      {{ $key }} = {{ $value | quote }}
          {{- end }}
          {{- if eq $tp "float64" }}
      {{ $key }} = {{ $value | int64 }}
          {{- end }}
          {{- if eq $tp "int" }}
      {{ $key }} = {{ $value | int64 }}
          {{- end }}
          {{- if eq $tp "bool" }}
      {{ $key }} = {{ $value }}
          {{- end }}
          {{- if eq $tp "[]interface {}" }}
      {{ $key }} = [
              {{- $numOut := len $value }}
              {{- $numOut := sub $numOut 1 }}
              {{- range $b, $val := $value }}
                {{- $i := int64 $b }}
                {{- $tp := typeOf $val }}
                {{- if eq $i $numOut }}
                  {{- if eq $tp "string" }}
        {{ $val | quote }}
                  {{- end }}
                  {{- if eq $tp "float64" }}
        {{ $val | int64 }}
                  {{- end }}
                {{- else }}
                  {{- if eq $tp "string" }}
        {{ $val | quote }},
                  {{- end}}
                  {{- if eq $tp "float64" }}
        {{ $val | int64 }},
                  {{- end }}
                {{- end }}
              {{- end }}
      ]
          {{- end }}
          {{- end }}
          {{- range $key, $value := $config -}}
          {{- $tp := typeOf $value -}}
          {{- if eq $tp "map[string]interface {}" }}
          {{- if or (eq $key "tagpass") (eq $key "tagdrop") }}
      [aggregators.{{ $aggregator }}.{{ $key }}]
          {{- else }}
      [[aggregators.{{ $aggregator }}.{{ $key }}]]
          {{- end }}
            {{- range $k, $v := $value }}
              {{- $tps := typeOf $v }}
              {{- if eq $tps "string" }}
        {{ $k }} = {{ $v | quote }}
              {{- end }}
              {{- if eq $tps "[]interface {}"}}
        {{ $k }} = [
                {{- $numOut := len $v }}
                {{- $numOut := sub $numOut 1 }}
                {{- range $b, $val := $v }}
                  {{- $i := int64 $b }}
                  {{- $tv := typeOf $val -}}
                  {{- if eq $i $numOut }}
                      {{- if eq $tv "string" }}
                  {{ $val | quote }}
                      {{- end }}
                      {{- if eq $tv "float64" }}
                        {{- $xval := float64 (int64 $val) -}}
                        {{- if eq $val $xval -}}
                  {{ $val | float64 }}.0
                        {{- else -}}
                  {{ $val | float64 }}
                        {{- end -}}
                      {{- end }}
                      {{- if eq $tv "int64" }}
                  {{ $val | int64 }}
                      {{- end }}
                  {{- else }}
                      {{- if eq $tv "string" }}
                  {{ $val | quote }},
                      {{- end }}
                      {{- if eq $tv "float64" }}
                        {{- $xval := float64 (int64 $val) -}}
                        {{- if eq $val $xval -}}
                  {{ $val | float64 }}.0,
                        {{- else -}}
                  {{ $val | float64 }},
                        {{- end -}}
                      {{- end }}
                      {{- if eq $tv "int64" }}
                  {{ $val | int64 }},
                      {{- end }}
                  {{- end }}
                {{- end }}
        ]
              {{- end }}
              {{- end }}
              {{- range $k, $v := $value }}
              {{- $tps := typeOf $v }}
              {{- if eq $tps "map[string]interface {}"}}
        [aggregators.{{ $aggregator }}.{{ $key }}.{{ $k }}]
                {{- range $foo, $bar := $v }}
                {{- $tp := typeOf $bar -}}
                {{- if eq $tp "string" }}
            {{ $foo }} = {{ $bar | quote }}
                {{- end }}
                {{- if eq $tp "int" }}
            {{ $foo }} = {{ $bar }}
                {{- end }}
                {{- if eq $tp "float64" }}
            {{ $foo }} = {{ int64 $bar }}
                {{- end }}
                {{- end }}
              {{- end }}
            {{- end }}
          {{- end }}
          {{- end }}
    {{- end }}
    {{- end }}
    {{ end }}
{{- end }}
{{- end -}}

{{/*
Backward compatible version support.
*/}}

{{- define "outputs" -}}
{{- include "section" (prepend . "outputs") -}}
{{- end -}}

{{- define "inputs" -}}
{{- include "section" (prepend . "inputs") -}}
{{- end -}}

{{- define "processors" -}}
{{- include "section" (prepend . "processors") -}}
{{- end -}}

{{- define "aggregators" -}}
{{- include "section" (prepend . "aggregators") -}}
{{- end -}}

{{- define "detect.version" -}}
{{ (default 1 .Values.tplVersion) | int64 }}
{{- end -}}

{{- define "section" -}}
{{- $name := index . 0 -}}
{{- $version := index . 1 | int64 -}}
{{- $suffix := ternary "v2" "v1" (eq 2 $version) -}}
{{- $templateName := printf "%s.%s" $name $suffix -}}
{{- with index . 2 -}}
  {{ include $templateName . }}
{{- end }}
{{- end -}}

{{- define "processors.v2" -}}
  {{ include "section.v2" (list "processors" .) }}
{{- end -}}

{{- define "aggregators.v2" -}}
  {{ include "section.v2" (list "aggregators" .) }}
{{- end -}}

{{- define "inputs.v2" -}}
  {{ include "section.v2" (list "inputs" .) }}
{{- end -}}

{{- define "outputs.v2" -}}
  {{ include "section.v2" (list "outputs" .) }}
{{- end -}}

{{- define "section.v2" -}}
{{- $name := index . 0 -}}
{{- with index . 1 -}}
{{- range $itemIdx, $configObject := . -}}
    {{- range $item, $config := . }}
    [[{{ $name }}.{{- $item }}]]
    {{- if $config -}}
    {{- $tp := typeOf $config -}}
    {{- if eq $tp "map[string]interface {}" -}}
      {{- $args := dict "key" $item "value" $config "level" 1 "type" $name -}}
      {{ include "any.table" $args }}
    {{- end }}
    {{- end }}
    {{ end }}
{{- end -}}
{{- end -}}
{{- end -}}

{{/*
Renders indented table.
*/}}

{{- define "any.table" -}}
{{- $n := (mul .level 2) | add 2 | int }}
{{- $args := dict "key" .key "value" .value "type" .type -}}
{{- include "any.table.raw" $args | indent $n }}
{{- end }}

{{/*
Renders a table.
Renders primitive and arrays of primitive types first, then nested tables and arrays of nested tables.
*/}}

{{- define "any.table.raw" -}}
{{- $key := .key }}
{{- $type := .type }}
{{- range $k, $v := .value }}
  {{- $tps := typeOf $v }}
  {{- if eq $tps "string" }}
  {{ $k }} = {{ $v | quote }}
  {{- else if eq $tps "float64" }}
    {{- $rv := float64 (int64 $v) }}
    {{- if eq $rv $v }}
  {{ $k }} = {{ $v | int64 }}
    {{- else }}
  {{ $k }} = {{ $v }}
    {{- end }}
  {{- else if eq $tps "int64" }}
  {{ $k }} = {{ $v }}
  {{- else if eq $tps "bool" }}
  {{ $k }} = {{ $v }}
  {{- else if eq $tps "[]interface {}" }}
    {{- if ne (index $v 0 | typeOf) "map[string]interface {}" }}
  {{ $k }} = [
      {{- $numOut := len $v }}
      {{- $numOut := sub $numOut 1 }}
      {{- range $b, $xv := $v }}
        {{- $i := int64 $b }}
        {{- $xtps := typeOf $xv }}
        {{- if eq $xtps "string" }}
    {{ $xv | quote }}
        {{- else if eq $xtps "float64" }}
          {{- $rxv := float64 (int64 $xv) }}
          {{- if eq $rxv $xv }}
            {{- if eq $k "percentiles" }}
    {{ $xv | int64 }}.0
            {{- else }}
    {{ $xv | int64 }}
            {{- end }}
          {{- else }}
    {{ $xv }}
          {{- end }}
        {{- else if eq $xtps "int64" }}
    {{ $xv }}
        {{- end }}
        {{- if ne $i $numOut -}}
        ,
        {{- end -}}
      {{- end }}
  ]
    {{- end }}
  {{- end }}
{{- end }}
{{- range $k, $v := .value }}
  {{- $tps := typeOf $v }}
  {{- if eq $tps "map[string]interface {}" }}
      {{- $args := dict "key" (printf "%s.%s" $key $k) "value" $v "type" $type }}
      {{- /* hack for existing incorrect mapping in values.yaml */ -}}
      {{- if eq "processors.enum.mapping" (printf "%s.%s" $type $args.key) }}
  [[{{ $type }}.{{ $args.key }}]]
      {{- else }}
  [{{ $type }}.{{ $args.key }}]
      {{- end }}
      {{- include "any.table" $args -}}
  {{- else if eq $tps "[]interface {}" }}
    {{- if eq (index $v 0 | typeOf) "map[string]interface {}" }}
      {{- range $b, $xv := $v }}
        {{- $args := dict "key" (printf "%s.%s" $key $k) "value" $xv  "type" $type }}
  [[{{ $type }}.{{ $args.key }}]]
        {{- include "any.table" $args -}}
      {{- end }}
    {{- end }}
  {{- end }}
{{- end }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "telegraf.serviceAccountName" -}}
{{- if .Values.serviceAccount.create -}}
    {{ default (include "telegraf.fullname" .) .Values.serviceAccount.name }}
{{- else -}}
    {{ default "default" .Values.serviceAccount.name }}
{{- end -}}
{{- end -}}

{{/*
Get health configuration
*/}}
{{- define "telegraf.health" -}}
{{- if .Values.metrics.health.enabled -}}
    {{- .Values.metrics.health | toYaml -}}
{{- else -}}
    {{- $health := dict -}}
    {{- range $objectKey, $objectValue := .Values.config.outputs }}
        {{- range $key, $value := . -}}
        {{- if eq $key "health" -}}
            {{- $health = $value -}}
        {{- end -}}
        {{- end -}}
    {{- end }}
    {{- $health | toYaml -}}
{{- end -}}
{{- end -}}
