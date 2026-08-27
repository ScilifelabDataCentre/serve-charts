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
  - "{{ .Release.Name }}.gw.{{ .Values.global.domain }}"
  parentRefs:
  - group: gateway.networking.k8s.io
    kind: Gateway
    name: {{ .Values.gateway.name | default "default" }}
    namespace: {{ .Values.gateway.namespace | default "gateway" }}
    sectionName: {{ .Values.gateway.sectionName | default "serve-dev-subdomains" }}
    port: {{ .Values.gateway.port | default (contains "nip.io" .Values.global.domain | ternary 80 443) }}
  rules:
  - backendRefs:
    - name: {{ include "common.serviceName" . }}
      kind: Service
      port: {{ .Values.service.port }}
    matches:
    - path:
        type: PathPrefix
        value: /
    {{- if or .Values.gateway.errorPagesSnippetsFilter.enabled (and (ne .Values.permission "public") (ne .Values.permission "link")) }}
    filters:
    {{- end }}
    {{- if .Values.gateway.errorPagesSnippetsFilter.enabled }}
    - type: ExtensionRef
      extensionRef:
        group: gateway.nginx.org
        kind: SnippetsFilter
        name: {{ .Release.Name }}-error-pages
    {{- end }}
    {{- if and (ne .Values.permission "public") (ne .Values.permission "link") }}
    - type: ExtensionRef
      extensionRef:
        group: gateway.nginx.org
        kind: SnippetsFilter
        name: {{ .Release.Name }}-auth
    {{- end }}
{{- end }}
{{- end }}

{{/*
SnippetsFilter to intercept upstream 5xx errors and route them to the shared nginx-errors backend
(deployed by the serve chart's custom-default-backend.yaml, in the same namespace).
Usage: {{ include "common.errorPagesSnippetsFilter" . }}
*/}}
{{- define "common.errorPagesSnippetsFilter" -}}
{{- if and .Values.gateway.enabled .Values.gateway.errorPagesSnippetsFilter.enabled }}
apiVersion: gateway.nginx.org/v1alpha1
kind: SnippetsFilter
metadata:
  name: {{ .Release.Name }}-error-pages
  namespace: {{ .Release.Namespace }}
spec:
  snippets:
  - context: http.server
    value: |
      proxy_intercept_errors on;
      error_page 403 = @error_page_403;
      error_page 404 = @error_page_404;
      error_page 500 = @error_page_500;
      error_page 502 = @error_page_502;
      error_page 503 = @error_page_503;
      error_page 504 = @error_page_504;
      location @error_page_403 {
        internal;
        proxy_intercept_errors off;
        proxy_set_header X-Code 403;
        proxy_pass http://nginx-errors.{{ .Release.Namespace }}.svc.cluster.local:80;
      }
      location @error_page_404 {
        internal;
        proxy_intercept_errors off;
        proxy_set_header X-Code 404;
        proxy_pass http://nginx-errors.{{ .Release.Namespace }}.svc.cluster.local:80;
      }
      location @error_page_500 {
        internal;
        proxy_intercept_errors off;
        proxy_set_header X-Code 500;
        proxy_pass http://nginx-errors.{{ .Release.Namespace }}.svc.cluster.local:80;
      }
      location @error_page_502 {
        internal;
        proxy_intercept_errors off;
        proxy_set_header X-Code 502;
        proxy_pass http://nginx-errors.{{ .Release.Namespace }}.svc.cluster.local:80;
      }
      location @error_page_503 {
        internal;
        proxy_intercept_errors off;
        proxy_set_header X-Code 503;
        proxy_pass http://nginx-errors.{{ .Release.Namespace }}.svc.cluster.local:80;
      }
      location @error_page_504 {
        internal;
        proxy_intercept_errors off;
        proxy_set_header X-Code 504;
        proxy_pass http://nginx-errors.{{ .Release.Namespace }}.svc.cluster.local:80;
      }
  - context: http.server.location
    value: |
      error_page 403 = @error_page_403;
      error_page 404 = @error_page_404;
      error_page 500 = @error_page_500;
      error_page 502 = @error_page_502;
      error_page 503 = @error_page_503;
      error_page 504 = @error_page_504;
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
{{- with .Values.ingress.clientMaxBodySize }}
        client_max_body_size {{ . | lower }};
{{- end }}
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
ClientSettingsPolicy for body size limit on the app's HTTPRoute.
Usage: {{ include "common.clientSettingsPolicy" . }}
*/}}
{{- define "common.clientSettingsPolicy" -}}
{{- if and .Values.gateway.enabled .Values.ingress.clientMaxBodySize }}
apiVersion: gateway.nginx.org/v1alpha1
kind: ClientSettingsPolicy
metadata:
  name: {{ .Release.Name }}-client-settings
  namespace: {{ .Release.Namespace }}
spec:
  targetRef:
    group: gateway.networking.k8s.io
    kind: HTTPRoute
    name: {{ .Release.Name }}-httproute
  body:
    maxSize: "{{ .Values.ingress.clientMaxBodySize | lower }}"
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
