# Collect  the appropriate database information based on the major version
# of Anchore Enterprise
{{- define "troubleshoot.collectors.dbInfo" -}}
{{- $dbUser := ( include "enterprise.ui.dbUser" . ) -}}
{{- $dbPassword := ( include "enterprise.ui.dbPassword" . ) -}}
{{- $dbHost := ( include "enterprise.dbHostname" . ) -}}
{{- $dbName := ( index .Values "postgresql" "auth" "database" ) -}}
{{- $version := semver .Chart.AppVersion -}}

{{- if (eq $version.Major 5) -}}
- exec:
    name: deployment_metrics
    selector: {{ include "troubleshoot.enterprise.selectors" . | nindent 6 }}
    namespace: {{ .Release.Namespace }}
    containerName: {{ .Chart.Name }}-catalog
    command: [ sh ]
    args:
      - -c
      - |
        export PGPASSWORD={{ $dbPassword }}
        export PGHOST={{ $dbHost }}
        psql -U {{ $dbUser }} -d {{ $dbName }} -P pager=off -t -A -F"," -c "select * from deployment_metrics;"
{{- end }}
- exec:
    name: image_analysis_events
    selector: {{ include "troubleshoot.enterprise.selectors" . | nindent 6 }}
    namespace: {{ .Release.Namespace }}
    containerName: {{ .Chart.Name }}-catalog
    command: [ sh ]
    args:
      - -c
      - |
        export PGPASSWORD={{ $dbPassword }}
        export PGHOST={{ $dbHost }}
        psql -U {{ $dbUser }} -d {{ $dbName }} -P pager=off -t -A -F"," -c "select type as event_type, count(*) as event_count, date(created_at) as event_date from events where type like 'user.image.analysis.%' group by event_date, resource_type, type order by event_date desc;"
- exec:
    name: statio_user_tables
    selector: {{ include "troubleshoot.enterprise.selectors" . | nindent 6 }}
    namespace: {{ .Release.Namespace }}
    containerName: {{ .Chart.Name }}-catalog
    command: [ sh ]
    args:
      - -c
      - |
        export PGPASSWORD={{ $dbPassword }}
        export PGHOST={{ $dbHost }}
        psql -U {{ $dbUser }} -d {{ $dbName }} -P pager=off -t -A -F"," -c "select * from pg_statio_user_tables;"
- exec:
    name: statio_user_indexes
    selector: {{ include "troubleshoot.enterprise.selectors" . | nindent 6 }}
    namespace: {{ .Release.Namespace }}
    containerName: {{ .Chart.Name }}-catalog
    command: [ sh ]
    args:
      - -c
      - |
        export PGPASSWORD={{ $dbPassword }}
        export PGHOST={{ $dbHost }}
        psql -U {{ $dbUser }} -d {{ $dbName }} -P pager=off -t -A -F"," -c "select * from pg_statio_user_indexes;"
- exec:
    name: stat_user_tables
    selector: {{ include "troubleshoot.enterprise.selectors" . | nindent 6 }}
    namespace: {{ .Release.Namespace }}
    containerName: {{ .Chart.Name }}-catalog
    command: [ sh ]
    args:
      - -c
      - |
        export PGPASSWORD={{ $dbPassword }}
        export PGHOST={{ $dbHost }}
        psql -U {{ $dbUser }} -d {{ $dbName }} -P pager=off -t -A -F"," -c "select * from pg_stat_user_tables;"
- exec:
    name: stat_user_indexes
    selector: {{ include "troubleshoot.enterprise.selectors" . | nindent 6 }}
    namespace: {{ .Release.Namespace }}
    containerName: {{ .Chart.Name }}-catalog
    command: [ sh ]
    args:
      - -c
      - |
        export PGPASSWORD={{ $dbPassword }}
        export PGHOST={{ $dbHost }}
        psql -U {{ $dbUser }} -d {{ $dbName }} -P pager=off -t -A -F"," -c "select * from pg_stat_user_indexes;"
- exec:
    name: stat_database
    selector: {{ include "troubleshoot.enterprise.selectors" . | nindent 6 }}
    namespace: {{ .Release.Namespace }}
    containerName: {{ .Chart.Name }}-catalog
    command: [ sh ]
    args:
      - -c
      - |
        export PGPASSWORD={{ $dbPassword }}
        export PGHOST={{ $dbHost }}
        psql -U {{ $dbUser }} -d {{ $dbName }} -P pager=off -t -A -F"," -c "select * from pg_stat_database;"
- exec:
    name: table_sizes
    selector: {{ include "troubleshoot.enterprise.selectors" . | nindent 6 }}
    namespace: {{ .Release.Namespace }}
    containerName: {{ .Chart.Name }}-catalog
    command: [ sh ]
    args:
      - -c
      - |
        export PGPASSWORD={{ $dbPassword }}
        export PGHOST={{ $dbHost }}
        psql -U {{ $dbUser }} -d {{ $dbName }} -P pager=off -t -A -F"," -c "select tablename, pg_size_pretty(pg_table_size(text(tablename))) as table_size from pg_tables where schemaname = 'public';"
{{- end -}}

