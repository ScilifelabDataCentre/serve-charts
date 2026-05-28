{{/*
HTTPRoute for a serve app.
Usage: {{ include "common.httproute" . }}
*/}}
{{- define "common.httproute" -}}
{{- if .Values.gateway.enabled }}
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: {{ .Release.Name }}-httproute
  namespace: {{ .Release.Namespace }}
spec:
  hostnames:
  - "{{ .Release.Name }}.{{ .Values.global.domain }}"
  parentRefs:
  - group: gateway.networking.k8s.io
    kind: Gateway
    name: {{ .Values.gateway.name | default "default" }}
    namespace: {{ .Values.gateway.namespace | default "gateway" }}
    sectionName: {{ .Values.gateway.sectionName | default "serve-dev-subdomains" }}
    port: {{ .Values.gateway.port | default 80 }}
  rules:
  - backendRefs:
    - name: {{ .Values.service.name }}
      kind: Service
      port: {{ .Values.service.port }}
    matches:
    - path:
        type: PathPrefix
        value: /
    {{- if and (ne .Values.permission "public") (ne .Values.permission "link") }}
    filters:
    - type: ExtensionRef
      extensionRef:
        group: gateway.nginx.org
        kind: SnippetsFilter
        name: {{ .Release.Name }}-auth
    {{- end }}
{{- end }}
{{- end }}

{{/*
SnippetsFilter for auth_request-based login redirect on private/protected apps.
Usage: {{ include "common.authSnippetsFilter" . }}
*/}}
{{- define "common.authSnippetsFilter" -}}
{{- if and .Values.gateway.enabled (ne .Values.permission "public") (ne .Values.permission "link") }}
{{- $scheme := "https" }}
{{- if eq (int .Values.gateway.port) 80 }}{{- $scheme = "http" }}{{- end }}
apiVersion: gateway.nginx.org/v1alpha1
kind: SnippetsFilter
metadata:
  name: {{ .Release.Name }}-auth
  namespace: {{ .Release.Namespace }}
spec:
  snippets:
  - context: http.server.location
    value: |
      auth_request /auth/;
      error_page 401 = @login_redirect;
  - context: http.server
    value: |
      location /auth/ {
        internal;
        resolver 10.43.0.10;
        proxy_pass {{ .Values.global.protocol | lower }}://{{ .Values.global.auth_domain }}:8080/auth/?release={{ .Values.release | default .Release.Name }};
        proxy_pass_request_body off;
        proxy_set_header Content-Length "";
        proxy_set_header X-Original-URI $request_uri;
      }
      location @login_redirect {
        return 302 {{ $scheme }}://{{ .Values.global.domain }}/accounts/login/?next=$request_uri;
      }
{{- end }}
{{- end }}

{{/*
RateLimitPolicy targeting the app's HTTPRoute.
Usage: {{ include "common.rateLimitPolicy" . }}
*/}}
{{- define "common.rateLimitPolicy" -}}
{{- if and .Values.gateway.enabled .Values.gateway.rateLimit.enabled }}
apiVersion: gateway.nginx.org/v1alpha1
kind: RateLimitPolicy
metadata:
  name: {{ .Release.Name }}-rate-limit
  namespace: {{ .Release.Namespace }}
spec:
  targetRefs:
  - group: gateway.networking.k8s.io
    kind: HTTPRoute
    name: {{ .Release.Name }}-httproute
  rateLimit:
    local:
      rules:
      - key: $binary_remote_addr
        rate: {{ .Values.gateway.rateLimit.rate | default "2r/s" }}
        burst: {{ .Values.gateway.rateLimit.burst | default 20 }}
        noDelay: {{ .Values.gateway.rateLimit.noDelay | default true }}
        zoneSize: {{ .Values.gateway.rateLimit.zoneSize | default "10m" }}
{{- end }}
{{- end }}
