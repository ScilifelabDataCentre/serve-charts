{{/*
Standard Service for a serve app.
Usage: {{ include "common.service" . }}
*/}}
{{- define "common.service" -}}
apiVersion: v1
kind: Service
metadata:
  name: {{ .Values.service.name }}
  namespace: {{ .Release.Namespace }}
  labels:
    run: {{ if .Values.service.runLabel }}{{ .Values.service.runLabel }}{{ else }}{{ .Release.Name }}{{ with .Values.appname }}-{{ . }}{{ end }}{{ end }}
    {{- if .Values.appname }}
    app: {{ .Values.appname }}
    {{- end }}
    {{- if .Values.labels }}
    {{- toYaml .Values.labels | nindent 4 }}
    {{- end }}
spec:
  ports:
  {{- if .Values.service.ports }}
  {{- toYaml .Values.service.ports | nindent 2 }}
  {{- else }}
  - protocol: TCP
    port: {{ .Values.service.port }}
    targetPort: {{ .Values.service.targetport | default (default (default .Values.appconfig.port .Values.service.targetPort) .Values.appconfig.proxyport) }}
  {{- end }}
  selector:
    release: {{ .Release.Name }}
{{- end }}
