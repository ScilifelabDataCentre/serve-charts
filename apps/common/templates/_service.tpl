{{/*
Kubernetes Service names are DNS labels and must not exceed 63 characters.
*/}}
{{- define "common.serviceName" -}}
{{- .Values.service.name | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Standard Service for a serve app.
Usage: {{ include "common.service" . }}
*/}}
{{- define "common.service" -}}
apiVersion: v1
kind: Service
metadata:
  name: {{ include "common.serviceName" . }}
  namespace: {{ .Release.Namespace }}
  labels:
    run: {{ .Values.service.runLabel | default .Values.appname | default .Release.Name | trunc 63 | trimSuffix "-" }}
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
