{{/*
mapTrim will recurse through a map and render it to a template string, without any null or empty values
As a named template partial, mapTrim can only render a result, it cannot modify the larger
context.

for example, let's call this object $map
hello: world
goodnight: moon
never-gonna-give:
you-up:
luke:
    i-am: your father
    join-me:

running mapTrim over that context would strip out the empty values and generate formatted yml (modulo a blank line)
so typical usage would look like
trimmed:{{$map | include "mapTrim" | trim | nindent 2}}

and the final result would be
trimmed:
  hello: world
  goodnight: moon
  luke:
    i-am: your father
*/}}
{{- define "mapTrim" }}
{{- $map := . -}}
{{- if not (kindIs "map" $map) }}{{fail "mapTrim requires a map"}}{{- end}}
{{- range $key, $val := $map -}}
  {{- if kindIs "map" $val -}}
    {{- if ($val | include "mapTrim" | fromYaml)}}
        {{- (dict $key ($val | include "mapTrim" | fromYaml)) | toYaml |  nindent 0 -}}
    {{- end}}
  {{- else if empty $val}}
  {{- else}}
    {{- (dict $key $val) | toYaml | nindent 0 -}}
  {{- end}}
{{- end}}
{{- end}}