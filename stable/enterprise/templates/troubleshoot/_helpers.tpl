{{- define "troubleshoot.enterprise.selectors" -}}
{{- $labels := (include "enterprise.common.labels" (merge (dict "component" "catalog") .) | fromYaml ) -}}
{{- range ( $labels | keys ) }}
- {{ print . "=" (get $labels .) }}
{{- end }}
{{- end -}}
