{{/*
Get list of service protocol groups
*/}}
{{- define "service.protocols" -}}
{{- if eq .Values.service.type "LoadBalancer" }}
  {{- if (ternary .Values.service.multiprotocol true (hasKey .Values.service "multiprotocol")) -}}
    {{- dict "" (list "TCP" "UDP") | toYaml -}}
  {{- else -}}
    {{- dict "tcp" (list "TCP") "udp" (list "UDP") | toYaml -}}
  {{- end -}}
{{- else -}}
  {{- dict "" (list "TCP" "UDP") | toYaml -}}
{{- end -}}
{{- end -}}

{{/*
Get service port mapping for internal input plugin
*/}}
{{- define "service.health" -}}
{{- $health := include "telegraf.health" . | fromYaml }}
{{- with $health }}
  {{- $port := trimPrefix "http://:" .service_address | int64 }}
  port: {{ $port }}
  targetPort: {{ $port }}
  name: "health-{{ $port }}"
{{- end }}
{{- end -}}

{{/*
Get service port mapping for input plugin
*/}}
{{- define "service.inputs" -}}
{{- $key := index . 0 }}
{{- $value := index . 1 }}
{{- if eq $key "http_listener" }}
  {{- $port := trimPrefix ":" $value.service_address | int64 }}
  port: {{ $port }}
  targetPort: {{ $port }}
  name: "http-listener-{{ $port }}"
{{- end }}
{{- if eq $key "influxdb_listener" }}
  {{- $port := trimPrefix ":" $value.service_address | int64 }}
  port: {{ $port }}
  targetPort: {{ $port }}
  name: "influxdb-listener-{{ $port }}"
{{- end }}
{{- if eq $key "http_listener_v2" }}
  {{- $port := trimPrefix ":" $value.service_address | int64 }}
  port: {{ $port }}
  targetPort: {{ $port }}
  name: "http-listener-v2-{{ $port }}"
{{- end }}
{{- if eq $key "influxdb_v2_listener" }}
  {{- $port := trimPrefix ":" $value.service_address | int64 }}
  port: {{ $port }}
  targetPort: {{ $port }}
  name: "influxdb-v2-listener-{{ $port }}"
{{- end }}
{{- if eq $key "statsd" }}
  {{- $port := trimPrefix ":" $value.service_address | int64 }}
  port: {{ $port }}
  targetPort: {{ $port }}
  protocol: "UDP"
  name: "statsd-{{ $port }}"
{{- end }}
{{- if eq $key "tcp_listener" }}
  {{- $port := trimPrefix ":" $value.service_address | int64 }}
  port: {{ $port }}
  targetPort: {{ $port }}
  name: "tcp-listener-{{ $port }}"
{{- end }}
{{- if eq $key "udp_listener" }}
  {{- $port := trimPrefix ":" $value.service_address | int64 }}
  port: {{ $port }}
  targetPort: {{ $port }}
  protocol: "UDP"
  name: "udp-listener-{{ $port }}"
{{- end }}
{{- if eq $key "webhooks" }}
  {{- $port := trimPrefix ":" $value.service_address | int64 }}
  port: {{ $port }}
  targetPort: {{ $port }}
  name: "webhooks-{{ $port }}"
{{- end }}
{{- if eq $key "syslog" }}
  {{- if regexMatch "^(tcp|udp).*" $value.server }}
  {{- $port := regexFind "[0-9]+$" $value.server  | int64 }}
  port: {{ $port }}
  targetPort: {{ $port }}
  protocol: {{ upper (substr 0 3 $value.server) }}
  name: "syslog-{{ $port }}"
  {{- end }}
{{- end }}
{{- if eq $key "socket_listener" }}
  {{- if or (hasPrefix "udp" $value.service_address) (hasPrefix "tcp" $value.service_address) }}
  {{- $port := regexFind "[0-9]+$" $value.service_address  | int64 }}
  port: {{ $port }}
  targetPort: {{ $port }}
  protocol: {{ upper (substr 0 3 $value.service_address) }}
  name: "socket-listener-{{ $port }}"
  {{- end }}
{{- end }}
{{- end -}}

{{/*
Get service port mapping for output plugin
*/}}
{{- define "service.outputs" -}}
{{- $key := index . 0 }}
{{- $value := index . 1 }}
{{- if eq $key "prometheus_client" }}
  {{- $port := trimPrefix ":" $value.listen | int64 }}
  port: {{ $port }}
  targetPort: {{ $port }}
  name: "prometheus-client-{{ $port }}"
{{- end }}
{{- end -}}
