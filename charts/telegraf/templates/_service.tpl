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
  port: {{ trimPrefix "http://:" .service_address | int64 }}
  targetPort: {{ trimPrefix "http://:" .service_address | int64 }}
  name: "health"
{{- end }}
{{- end -}}

{{/*
Get service port mapping for input plugin
*/}}
{{- define "service.inputs" -}}
{{- $key := index . 0 }}
{{- $value := index . 1 }}
{{- if eq $key "http_listener" }}
  port: {{ trimPrefix ":" $value.service_address | int64 }}
  targetPort: {{ trimPrefix ":" $value.service_address | int64 }}
  name: "http-listener"
{{- end }}
{{- if eq $key "influxdb_listener" }}
  port: {{ trimPrefix ":" $value.service_address | int64 }}
  targetPort: {{ trimPrefix ":" $value.service_address | int64 }}
  name: "influxdb-listener"
{{- end }}
{{- if eq $key "http_listener_v2" }}
  port: {{ trimPrefix ":" $value.service_address | int64 }}
  targetPort: {{ trimPrefix ":" $value.service_address | int64 }}
  name: "http-listener-v2"
{{- end }}
{{- if eq $key "influxdb_v2_listener" }}
  port: {{ trimPrefix ":" $value.service_address | int64 }}
  targetPort: {{ trimPrefix ":" $value.service_address | int64 }}
  name: "influxdb-v2-listener"
{{- end }}
{{- if eq $key "statsd" }}
  port: {{ trimPrefix ":" $value.service_address | int64 }}
  targetPort: {{ trimPrefix ":" $value.service_address | int64 }}
  protocol: "UDP"
  name: "statsd"
{{- end }}
{{- if eq $key "tcp_listener" }}
  port: {{ trimPrefix ":" $value.service_address | int64 }}
  targetPort: {{ trimPrefix ":" $value.service_address | int64 }}
  name: "tcp-listener"
{{- end }}
{{- if eq $key "udp_listener" }}
  port: {{ trimPrefix ":" $value.service_address | int64 }}
  targetPort: {{ trimPrefix ":" $value.service_address | int64 }}
  protocol: "UDP"
  name: "udp-listener"
{{- end }}
{{- if eq $key "webhooks" }}
  port: {{ trimPrefix ":" $value.service_address | int64 }}
  targetPort: {{ trimPrefix ":" $value.service_address | int64 }}
  name: "webhooks"
{{- end }}
{{- if eq $key "syslog" }}
  {{- if regexMatch "^(tcp|udp).*" $value.server }}
  port: {{ regexFind "[0-9]+$" $value.server  | int64 }}
  targetPort: {{ regexFind "[0-9]+$" $value.server  | int64 }}
  protocol: {{ upper (substr 0 3 $value.server) }}
  name: "syslog"
  {{- end }}
{{- end }}
{{- if eq $key "socket_listener" }}
  {{- if or (hasPrefix "udp" $value.service_address) (hasPrefix "tcp" $value.service_address) }}
  port: {{ regexFind "[0-9]+$" $value.service_address  | int64 }}
  targetPort: {{ regexFind "[0-9]+$" $value.service_address  | int64 }}
  protocol: {{ upper (substr 0 3 $value.service_address) }}
  name: {{ printf "%s-%s" "socket-listener" (regexFind "[0-9]+$" $value.service_address) }}
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
  port: {{ trimPrefix ":" $value.listen | int64 }}
  targetPort: {{ trimPrefix ":" $value.listen | int64 }}
  name: "prometheus-client"
{{- end }}
{{- end -}}
