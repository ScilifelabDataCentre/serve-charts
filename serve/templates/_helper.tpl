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
