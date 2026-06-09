{{/*
Return true if a secret object should be created
*/}}
{{- define "studio.createSecret" -}}
{{- if not (include "studio.useExistingSecret" .) -}}
    {{- true -}}
{{- end -}}
{{- end -}}

{{/*
Return true if we should use an existingSecret.
*/}}
{{- define "studio.useExistingSecret" -}}
{{- if or .Values.studio.existingSecret .Values.existingSecret -}}
    {{- true -}}
{{- end -}}
{{- end -}}

{{/*
Get the Studio password secret.
*/}}
{{- define "studio.secretName" -}}
{{- if .Values.studio.existingSecret }}
    {{- printf "%s" (tpl .Values.studio.existingSecret $) -}}
{{- else if .Values.existingSecret -}}
    {{- printf "%s" (tpl .Values.existingSecret $) -}}
{{- else -}}
    {{ include "common.names.fullname" . }}
{{- end -}}
{{- end -}}

{{/*
Return Studio superuser
*/}}
{{- define "studio.superuser" -}}
{{- if .Values.studio.superUser }}
    {{- .Values.studio.superUser -}}
{{- else -}}
    admin
{{- end -}}
{{- end -}}

{{/*
Return Studio superuser password
*/}}
{{- define "studio.superuser.password" -}}
{{- if .Values.studio.superuserPassword }}
    {{- .Values.studio.superuserPassword -}}
{{- else -}}
    {{- randAlphaNum 10 -}}
{{- end -}}
{{- end -}}

{{/*
Return Studio superuser email
*/}}
{{- define "studio.superuser.email" -}}
{{- if .Values.studio.superuserEmail }}
    {{- .Values.studio.superuserEmail -}}
{{- else -}}
    admin@test.com
{{- end -}}
{{- end -}}

{{/*
Return Studio PostgreSQL password
*/}}
{{- define "studio.postgres.password" -}}
{{- if .Values.postgresql.auth.password -}}
    {{- .Values.postgresql.auth.password -}}
{{- else -}}
    {{- randAlphaNum 10 -}}
{{- end -}}
{{- end -}}

{{/*
Return PostgreSQL secret
*/}}
{{- define "studio.postgresql.secretName" -}}
{{- if .Values.postgresql.enabled }}
    {{- include "postgresql.secretName" .Subcharts.postgresql -}}
{{- else -}}
    {* HOLDER FOR HA MODE IN FUTURE RELEASE *}
{{- end -}}
{{- end -}}

{{/*
Return Redis secret
*/}}
{{- define "studio.redis.secretName" -}}
{{- include "redis.secretName" .Subcharts.redis -}}
{{- end -}}

{{/*
Return Redis secret password key
*/}}
{{- define "studio.redis.secretPasswordKey" -}}
{{- include "redis.secretPasswordKey" .Subcharts.redis -}}
{{- end -}}

{{/*
Return RabbitMQ username
*/}}
{{- define "studio.rabbitmq.username" -}}
{{- .Values.rabbitmq.auth.username -}}
{{- end -}}

{{/*
Return RabbitMQ password
*/}}
{{- define "studio.rabbitmq.password" -}}
{{- if .Values.rabbitmq.auth.password -}}
    {{- .Values.rabbitmq.auth.password -}}
{{- else -}}
    {{- randAlphaNum 10 -}}
{{- end -}}
{{- end -}}

{{/*
Return RabbitMQ secret
*/}}
{{- define "studio.rabbitmq.secretName" -}}
{{- include "rabbitmq.secretPasswordName" .Subcharts.rabbitmq -}}
{{- end -}}

{{/*
Return Studio storageClass
*/}}
{{- define "studio.storageclass" -}}
{{- if .Values.studio.storageClass }}
    {{- .Values.studio.storageClass -}}
{{- else -}}
    {{- .Values.postgresql.primary.persistence.storageClass -}}
{{- end -}}
{{- end -}}

{{/*
Return Studio media storageClass
*/}}
{{- define "studio.media.storageclass" -}}
{{- if .Values.studio.media.storage.storageClass }}
    {{- .Values.studio.media.storage.storageClass -}}
{{- else -}}
    {{- .Values.postgresql.primary.persistence.storageClass -}}
{{- end -}}
{{- end -}}

{{/*
    Return eventuser password
*/}}
{{- define "studio.eventuser.password" -}}
{{- if .Values.studio.eventuserPassword }}
    {{- .Values.studio.eventuserPassword -}}
{{- else -}}
    {{- randAlphaNum 10 -}}
{{- end -}}
{{- end -}}
    
{{/*
Return eventuser email
*/}}
{{- define "studio.eventuser.email" -}}
{{- if .Values.studio.eventuserEmail }}
    {{- .Values.studio.eventuserEmail -}}
{{- else -}}
    event_user@test.com
{{- end -}}
{{- end -}}

{{/*
Studio container environment variables
*/}}
{{- define "studio.env" -}}
- name: DEBUG
{{- if .Values.studio.debug }}
  value: "true"
{{- else }}
  value: "false"
{{- end }}
- name: DJANGO_SUPERUSER
  value: {{ include "studio.superuser" . }}
- name: DJANGO_SUPERUSER_EMAIL
  value: {{ include "studio.superuser.email" . }}
- name: DJANGO_SUPERUSER_PASSWORD
  valueFrom:
    secretKeyRef:
      {{- if .Values.bitwarden.enabled }}
      name: serve-bitwarden-secret
      key: studio-superuser-password
      {{- else }}
      name: {{ include "studio.secretName" . }}
      key: studio-superuser-password
      {{- end }}
- name: DJANGO_ADMIN_URL_PATH
  value: {{ .Values.studio.djangoAdminUrlPath }}
- name: EVENT_USER_EMAIL
  value: {{ include "studio.eventuser.email" . }}
- name: EVENT_USER_PASSWORD
  valueFrom:
    secretKeyRef:
      {{- if .Values.bitwarden.enabled }}
      name: serve-bitwarden-secret
      key: event-user-password
      {{- else }}
      name: {{ include "studio.secretName" . }}
      key: event-user-password
      {{- end }}
- name: GET_HOSTS_FROM
  value: dns
- name: POSTGRES_PASSWORD
  valueFrom:
    secretKeyRef:
      {{- if .Values.bitwarden.enabled }}
      name: serve-bitwarden-secret
      key: postgresql-password
      {{- else }}
      name: {{ include "studio.postgresql.secretName" . }}
      key: {{ include "postgresql.userPasswordKey" .Subcharts.postgresql }}
      {{- end }}
- name: POSTGRES_USER
  {{- if .Values.bitwarden.enabled }}
  valueFrom:
    secretKeyRef:
      name: serve-bitwarden-secret
      key: postgresql-username
  {{- else }}
  value: {{ .Values.postgresql.auth.username }}
  {{- end }}
- name: POSTGRES_IDLE_SESSION_TIMEOUT
  value: {{ .Values.studio.connectionPool.idleSessionTimeout | default "30min" | quote }}
- name: POSTGRES_IDLE_IN_TRANSACTION_SESSION_TIMEOUT
  value: {{ .Values.studio.connectionPool.idleInTransactionSessionTimeout | default "10min" | quote }}
- name: REDIS_PASSWORD
  valueFrom:
    secretKeyRef:
      {{- if .Values.bitwarden.enabled }}
      name: serve-bitwarden-secret
      key: redis-password
      {{- else }}
      name: {{ include "studio.redis.secretName" . }}
      key: {{ include "studio.redis.secretPasswordKey" . }}
      {{- end }}
{{ if .Values.studio.githubApiTokenToggle }}
- name: GITHUB_API_TOKEN
  valueFrom:
    secretKeyRef:
      {{- if .Values.bitwarden.enabled }}
      name: serve-bitwarden-secret
      key: github-api-token
      {{- else }}
      name: {{ include "studio.secretName" . }}
      key: github-api-token
      {{- end }}
- name: GITHUB_API_USERNAME
  value: {{ .Values.studio.githubApiUsername | quote }}
{{ else }}
- name: GITHUB_API_TOKEN
  value: ""
- name: GITHUB_API_USERNAME
  value: ""
{{ end }}
{{ if .Values.studio.dockerhubUsername }}
- name: DOCKER_HUB_USERNAME
  value: {{ .Values.studio.dockerhubUsername | quote }}
- name: DOCKER_HUB_TOKEN
  valueFrom:
    secretKeyRef:
      {{- if .Values.bitwarden.enabled }}
      name: serve-bitwarden-secret
      key: docker-hub-token
      {{- else }}
      name: {{ include "studio.secretName" . }}
      key: docker-hub-token
      {{- end }}
{{ else }}
- name: DOCKER_HUB_USERNAME
  value: ""
- name: DOCKER_HUB_TOKEN
  value: ""
{{ end }}
- name: ALTCHA_HMAC_KEY
  valueFrom:
    secretKeyRef:
      {{- if .Values.bitwarden.enabled }}
      name: serve-bitwarden-secret
      key: altcha-hmac-key
      {{- else }}
      name: {{ include "studio.secretName" . }}
      key: altcha-hmac-key
      {{- end }}
- name: RABBITMQ_DEFAULT_PASS
  valueFrom:
    secretKeyRef:
      {{- if .Values.bitwarden.enabled }}
      name: serve-bitwarden-secret
      key: rabbitmq-password
      {{- else }}
      name: {{ include "studio.rabbitmq.secretName" . }}
      key: rabbitmq-password
      {{- end }}
- name: RABBITMQ_HOST
  value: {{ .Release.Name }}-rabbitmq
- name: RABBITMQ_USER
  value: {{ include "studio.rabbitmq.username" . | quote }}
- name: REDIS_HOST
  value: {{ .Release.Name }}-redis-master
{{- if .Values.chartcontroller.addSecret }}
- name: KUBECONFIG
  value: {{ .Values.studio.kubeconfig_file | quote }}
{{- end }}
- name: DJANGO_SECRET
  valueFrom:
    secretKeyRef:
      {{- if .Values.bitwarden.enabled }}
      name: serve-bitwarden-secret
      key: django-secret-key
      {{- else }}
      name: {{ include "studio.secretName" . }}
      key: django-secret-key
      {{- end }}
{{ if .Values.studio.emailService.enabled }}
- name: GOOGLE_SERVICE_ACCOUNT_TYPE
  valueFrom:
    secretKeyRef:
      {{- if .Values.bitwarden.enabled }}
      name: serve-bitwarden-secret
      key: email-google-service-account-type
      {{- else }}
      name: {{ include "studio.secretName" . }}
      key: email-google-service-account-type
      {{- end }}
- name: GOOGLE_SERVICE_ACCOUNT_PROJECT_ID
  valueFrom:
    secretKeyRef:
      {{- if .Values.bitwarden.enabled }}
      name: serve-bitwarden-secret
      key: email-google-service-account-project-id
      {{- else }}
      name: {{ include "studio.secretName" . }}
      key: email-google-service-account-project-id
      {{- end }}
- name: GOOGLE_SERVICE_ACCOUNT_PRIVATE_KEY_ID
  valueFrom:
    secretKeyRef:
      {{- if .Values.bitwarden.enabled }}
      name: serve-bitwarden-secret
      key: email-google-service-account-private-key-id
      {{- else }}
      name: {{ include "studio.secretName" . }}
      key: email-google-service-account-private-key-id
      {{- end }}
- name: GOOGLE_SERVICE_ACCOUNT_PRIVATE_KEY
  valueFrom:
    secretKeyRef:
      {{- if .Values.bitwarden.enabled }}
      name: serve-bitwarden-secret
      key: email-google-service-account-private-key
      {{- else }}
      name: {{ include "studio.secretName" . }}
      key: email-google-service-account-private-key
      {{- end }}
- name: GOOGLE_SERVICE_ACCOUNT_CLIENT_EMAIL
  valueFrom:
    secretKeyRef:
      {{- if .Values.bitwarden.enabled }}
      name: serve-bitwarden-secret
      key: email-google-service-account-client-email
      {{- else }}
      name: {{ include "studio.secretName" . }}
      key: email-google-service-account-client-email
      {{- end }}
- name: GOOGLE_SERVICE_ACCOUNT_CLIENT_ID
  valueFrom:
    secretKeyRef:
      {{- if .Values.bitwarden.enabled }}
      name: serve-bitwarden-secret
      key: email-google-service-account-client-id
      {{- else }}
      name: {{ include "studio.secretName" . }}
      key: email-google-service-account-client-id
      {{- end }}
- name: GOOGLE_SERVICE_ACCOUNT_AUTH_URI
  valueFrom:
    secretKeyRef:
      {{- if .Values.bitwarden.enabled }}
      name: serve-bitwarden-secret
      key: email-google-service-account-auth-uri
      {{- else }}
      name: {{ include "studio.secretName" . }}
      key: email-google-service-account-auth-uri
      {{- end }}
- name: GOOGLE_SERVICE_ACCOUNT_TOKEN_URI
  valueFrom:
    secretKeyRef:
      {{- if .Values.bitwarden.enabled }}
      name: serve-bitwarden-secret
      key: email-google-service-account-token-uri
      {{- else }}
      name: {{ include "studio.secretName" . }}
      key: email-google-service-account-token-uri
      {{- end }}
- name: GOOGLE_SERVICE_ACCOUNT_AUTH_PROVIDER_X509_CERT_URL
  valueFrom:
    secretKeyRef:
      {{- if .Values.bitwarden.enabled }}
      name: serve-bitwarden-secret
      key: email-google-service-account-auth-provider-x509-cert-url
      {{- else }}
      name: {{ include "studio.secretName" . }}
      key: email-google-service-account-auth-provider-x509-cert-url
      {{- end }}
- name: GOOGLE_SERVICE_ACCOUNT_CLIENT_X509_CERT_URL
  valueFrom:
    secretKeyRef:
      {{- if .Values.bitwarden.enabled }}
      name: serve-bitwarden-secret
      key: email-google-service-account-client-x509-cert-url
      {{- else }}
      name: {{ include "studio.secretName" . }}
      key: email-google-service-account-client-x509-cert-url
      {{- end }}
- name: GOOGLE_SERVICE_ACCOUNT_UNIVERSE_DOMAIN
  valueFrom:
    secretKeyRef:
      {{- if .Values.bitwarden.enabled }}
      name: serve-bitwarden-secret
      key: email-google-service-account-universe-domain
      {{- else }}
      name: {{ include "studio.secretName" . }}
      key: email-google-service-account-universe-domain
      {{- end }}
{{ end }}
{{ if .Values.studio.invenioEnabled }}
- name: INVENIO_URL
  {{- if .Values.studio.invenioUrl }}
  value: {{ .Values.studio.invenioUrl | quote }}
  {{- else }}
  value: https://invenio.{{ .Values.studio.domain }}
  {{- end }}
- name: INVENIO_API_TOKEN
  valueFrom:
    secretKeyRef:
      {{- if .Values.bitwarden.enabled }}
      name: serve-bitwarden-secret
      key: invenio-token
      {{- else }}
      name: {{ include "studio.secretName" . }}
      key: invenio-token
      {{- end }}
{{ else }}
- name: INVENIO_URL
  value: ""
- name: INVENIO_API_TOKEN
  value: ""
{{- end }}
- name: INVENIO_MOCK_MODE
  value: {{ .Values.studio.invenioMockMode | quote }}
- name: ORCID_CLIENT_ID
  valueFrom:
    secretKeyRef:
      {{- if .Values.bitwarden.enabled }}
      name: serve-bitwarden-secret
      key: orcid-client-id
      {{- else }}
      name: {{ include "studio.secretName" . }}
      key: orcid-client-id
      {{- end }}
- name: ORCID_CLIENT_SECRET
  valueFrom:
    secretKeyRef:
      {{- if .Values.bitwarden.enabled }}
      name: serve-bitwarden-secret
      key: orcid-client-secret
      {{- else }}
      name: {{ include "studio.secretName" . }}
      key: orcid-client-secret
      {{- end }}
{{- end -}}
