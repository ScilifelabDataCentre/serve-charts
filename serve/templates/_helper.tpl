{{/*
Return true if a secret object should be created
*/}}
{{- define "stackn.createSecret" -}}
{{- if not (include "stackn.useExistingSecret" .) -}}
    {{- true -}}
{{- end -}}
{{- end -}}

{{/*
Return true if we should use an existingSecret.
*/}}
{{- define "stackn.useExistingSecret" -}}
{{- if or .Values.global.studio.existingSecret .Values.existingSecret -}}
    {{- true -}}
{{- end -}}
{{- end -}}

{{/*
Get the STACKn password secret.
*/}}
{{- define "stackn.secretName" -}}
{{- if .Values.global.studio.existingSecret }}
    {{- printf "%s" (tpl .Values.global.studio.existingSecret $) -}}
{{- else if .Values.existingSecret -}}
    {{- printf "%s" (tpl .Values.existingSecret $) -}}
{{- else -}}
    {{ include "common.names.fullname" . }}
{{- end -}}
{{- end -}}

{{/*
Return STACKn studio superuser
*/}}
{{- define "stackn.studio.superuser" -}}
{{- if .Values.global.studio.superUser }}
    {{- .Values.global.studio.superUser -}}
{{- else if .Values.studio.superUser -}}
    {{- .Values.studio.superUser -}}
{{- else -}}
    admin
{{- end -}}
{{- end -}}

{{/*
Return STACKn studio superuser password
*/}}
{{- define "stackn.studio.superuser.password" -}}
{{- if .Values.global.studio.superuserPassword }}
    {{- .Values.global.studio.superuserPassword -}}
{{- else if .Values.studio.superuserPassword -}}
    {{- .Values.studio.superuserPassword -}}
{{- else -}}
    {{- randAlphaNum 10 -}}
{{- end -}}
{{- end -}}

{{/*
Return STACKn studio superuser email
*/}}
{{- define "stackn.studio.superuser.email" -}}
{{- if .Values.global.studio.superuserEmail }}
    {{- .Values.global.studio.superuserEmail -}}
{{- else if .Values.studio.superuserEmail -}}
    {{- .Values.studio.superuserEmail -}}
{{- else -}}
    admin@test.com
{{- end -}}
{{- end -}}


{{/*
Return STACKn studio postgres password
*/}}
{{- define "stackn.studio.postgres.password" -}}
{{- if .Values.postgresql.global.postgresql.auth.password -}}
    {{- .Values.postgresql.global.postgresql.auth.password -}}
{{- else -}}
    {{- randAlphaNum 10 -}}
{{- end -}}
{{- end -}}

{{/*
Return STACKn studio postgresql-postgres password
*/}}
{{- define "stackn.studio.postgresql-postgres.password" -}}
{{- if .Values.postgresql.global.postgresql.auth.postgresPassword -}}
    {{- .Values.postgresql.global.postgresql.auth.postgresPassword -}}
{{- else -}}
    {{- randAlphaNum 10 -}}
{{- end -}}
{{- end -}}

{{/*
Return postgres secret
*/}}
{{- define "stackn.postgres.secretName" -}}
{{- if .Values.postgresql.enabled }}
    {{- include "postgresql.secretName" .Subcharts.postgresql -}}
{{- else -}}
    {* HOLDER FOR HA MODE IN FUTURE RELEASE *}
{{- end -}}
{{- end -}}


{{/*
Return redis secret
*/}}
{{- define "stackn.redis.secretName" -}}
{{- include "redis.secretName" .Subcharts.redis -}}
{{- end -}}


{{/*
Return redis secret password key
*/}}
{{- define "stackn.redis.secretPasswordKey" -}}
{{- include "redis.secretPasswordKey" .Subcharts.redis -}}
{{- end -}}

{{/*
Return STACKn studio storageClass
*/}}
{{- define "stackn.studio.storageclass" -}}
{{- if .Values.global.studio.storageClass }}
    {{- .Values.global.studio.storageClass -}}
{{- else if .Values.studio.storage.storageClass -}}
    {{- .Values.studio.storage.storageClass -}}
{{- else -}}
    {{- .Values.global.postgresql.storageClass -}}
{{- end -}}
{{- end -}}

{{/*
Return STACKn studio media storageClass
*/}}
{{- define "stackn.studio.media.storageclass" -}}
{{- if .Values.global.studio.storageClass }}
    {{- .Values.global.studio.storageClass -}}
{{- else if .Values.studio.media.storage.storageClass -}}
    {{- .Values.studio.media.storage.storageClass -}}
{{- else -}}
    {{- .Values.global.postgresql.storageClass -}}
{{- end -}}
{{- end -}}


{{/*
Return STACKn rabbit password
*/}}
{{- define "stackn.rabbit.password" -}}
{{- if .Values.rabbit.password -}}
    {{- .Values.rabbit.password -}}
{{- else -}}
    {{- randAlphaNum 10 -}}
{{- end -}}
{{- end -}}

{{/*
Return STACKn rabbit username
*/}}
{{- define "stackn.rabbit.username" -}}
{{- .Values.rabbitmq.auth.username -}}
{{- end -}}

{{/*
Return STACKn rabbit secret
*/}}
{{- define "stackn.rabbit.secretName" -}}
{{- include "rabbitmq.secretPasswordName" .Subcharts.rabbitmq -}}
{{- end -}}


{{/*
    Return eventuser password
    */}}
    {{- define "stackn.studio.eventuser.password" -}}
    {{- if .Values.global.studio.eventuserPassword }}
        {{- .Values.global.studio.eventuserPassword -}}
    {{- else if .Values.studio.eventuserPassword -}}
        {{- .Values.studio.eventuserPassword -}}
    {{- else -}}
        {{- randAlphaNum 10 -}}
    {{- end -}}
    {{- end -}}
    
    {{/*
    Return eventuser email
    */}}
    {{- define "stackn.studio.eventuser.email" -}}
    {{- if .Values.global.studio.eventuserEmail }}
        {{- .Values.global.studio.eventuserEmail -}}
    {{- else if .Values.studio.eventuserEmail -}}
        {{- .Values.studio.eventuserEmail -}}
    {{- else -}}
        event_user@test.com
    {{- end -}}
    {{- end -}}
