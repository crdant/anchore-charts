{{- define "troubleshoot.collectors.counts" -}}
{{- $dbUser := ( include "enterprise.ui.dbUser" . ) -}}
{{- $dbPassword := ( include "enterprise.ui.dbPassword" . ) -}}
{{- $dbHost := ( include "enterprise.dbHostname" . ) -}}
{{- $dbName := ( index .Values "postgresql" "auth" "database" ) -}}

- exec:
    name: count-images
    selector: {{ include "troubleshoot.enterprise.selectors" . | nindent 6 }}
    namespace: {{ .Release.Namespace }}
    containerName: {{ .Chart.Name }}-catalog
    command: [ sh ]
    args:
      - -c
      - |
        export PGPASSWORD={{ $dbPassword }}
        export PGHOST={{ $dbHost }}
        psql -U {{ $dbUser }} -d {{ $dbName }} -P pager=off -t -A -F"," -c "SELECT to_timestamp(created_at)::date,COUNT(to_timestamp(created_at)::date) FROM catalog_image GROUP BY to_timestamp(created_at)::date;"
- exec:
    name: count-archived-images
    selector: {{ include "troubleshoot.enterprise.selectors" . | nindent 6 }}
    namespace: {{ .Release.Namespace }}
    containerName: {{ .Chart.Name }}-catalog
    command: [ sh ]
    args:
      - -c
      - |
        export PGPASSWORD={{ $dbPassword }} 
        export PGHOST={{ $dbHost }}
        psql -U {{ $dbUser }} -d {{ $dbName }} -P pager=off -t -A -F"," -c "SELECT to_timestamp(created_at)::date,COUNT(to_timestamp(created_at)::date) FROM catalog_archived_images GROUP BY to_timestamp(created_at)::date;"
- exec:
    name: count-accounts
    selector: {{ include "troubleshoot.enterprise.selectors" . | nindent 6 }}
    namespace: {{ .Release.Namespace }}
    containerName: {{ .Chart.Name }}-catalog
    command: [ sh ]
    args:
      - -c
      - |
        export PGPASSWORD={{ $dbPassword }} 
        export PGHOST={{ $dbHost }}
        psql -U {{ $dbUser }} -d {{ $dbName }} -P pager=off -t -A -F"," -c "SELECT COUNT(*) FROM accounts;"
- exec:
    name: count-users
    selector: {{ include "troubleshoot.enterprise.selectors" . | nindent 6 }}
    namespace: {{ .Release.Namespace }}
    containerName: {{ .Chart.Name }}-catalog
    command: [ sh ]
    args: 
      - -c
      - |
        export PGPASSWORD={{ $dbPassword }} 
        export PGHOST={{ $dbHost }}
        psql -U {{ $dbUser }} -d {{ $dbName }} -P pager=off -t -A -F"," -c "SELECT COUNT(*) FROM account_users;"
- exec:
    name: size-avg-mb
    selector: {{ include "troubleshoot.enterprise.selectors" . | nindent 6 }}
    namespace: {{ .Release.Namespace }}
    containerName: {{ .Chart.Name }}-catalog
    command: [ sh ]
    args:
      - -c 
      - | 
        export PGPASSWORD={{ $dbPassword }} 
        export PGHOST={{ $dbHost }}
        psql -U {{ $dbUser }} -d {{ $dbName }} -P pager=off -t -A -F"," -c "SELECT AVG(image_size)/1000000 AS avg_image_size_mb FROM catalog_image;"
- exec:
    name: size-top-five-mb
    selector: {{ include "troubleshoot.enterprise.selectors" . | nindent 6 }}
    namespace: {{ .Release.Namespace }}
    containerName: {{ .Chart.Name }}-catalog
    command: [ sh ]
    args:
      - -c
      - |
        export PGPASSWORD={{ $dbPassword }} 
        export PGHOST={{ $dbHost }}
        psql -U {{ $dbUser }} -d {{ $dbName }} -P pager=off -t -A -F"," -c "SELECT image_size/1000000 AS top_five_mb FROM catalog_image ORDER BY image_size DESC LIMIT 5;"
{{- end -}}
