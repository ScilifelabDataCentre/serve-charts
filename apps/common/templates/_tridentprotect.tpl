{{/*
Trident Protect Application + Schedule backing up the volumes of a serve app release.
Usage: {{ include "common.tridentprotect" . }}

Rendered only when .Values.backup.enabled is true and the Trident Protect CRDs are installed on the
cluster. Expects in the app chart values:
  backup:
    enabled: true
    appVaultRef: ""
    backupRetention: "1"
    snapshotRetention: "0"
    labelSelector: {}
    schedule:
      granularity: Daily
      windowStartHour: 22
      windowMinutes: 360
      runImmediately: true

The start time of each release is spread over the window using a hash of the release name,
so that many releases do not all back up at the same minute.
*/}}
{{- define "common.tridentprotect" -}}
{{- $tridentProtect := and (.Capabilities.APIVersions.Has "protect.trident.netapp.io/v1/Application") (.Capabilities.APIVersions.Has "protect.trident.netapp.io/v1/Schedule") }}
{{- if and .Values.backup.enabled $tridentProtect }}
{{- $schedule := .Values.backup.schedule }}
{{- $name := printf "%s-backup" .Release.Name | trunc 63 | trimSuffix "-" }}
{{- $selector := .Values.backup.labelSelector | default (dict "app.kubernetes.io/instance" .Release.Name) }}
{{- $offset := mod (atoi (adler32sum .Release.Name)) (max 1 (int $schedule.windowMinutes)) }}
{{- $start := add (mul (int $schedule.windowStartHour) 60) $offset }}
apiVersion: protect.trident.netapp.io/v1
kind: Application
metadata:
  name: {{ $name }}
  namespace: {{ .Release.Namespace }}
  labels:
    {{- include "common.tridentprotect.labels" . | nindent 4 }}
spec:
  includedNamespaces:
    - namespace: {{ .Release.Namespace }}
      labelSelector:
        matchLabels:
          {{- toYaml $selector | nindent 10 }}
  resourceFilter:
    resourceMatchers:
      - kind: PersistentVolumeClaim
        version: v1
      - kind: PersistentVolume
        version: v1
      - kind: VolumeSnapshotClass
        version: v1
    resourceSelectionCriteria: Include
---
apiVersion: protect.trident.netapp.io/v1
kind: Schedule
metadata:
  name: {{ $name }}
  namespace: {{ .Release.Namespace }}
  labels:
    {{- include "common.tridentprotect.labels" . | nindent 4 }}
spec:
  applicationRef: {{ $name }}
  appVaultRef: {{ .Values.backup.appVaultRef | default "storagegrid-s3-bucket" | quote }}
  granularity: {{ $schedule.granularity | quote }}
  hour: {{ mod (div $start 60) 24 | quote }}
  minute: {{ mod $start 60 | quote }}
  runImmediately: {{ $schedule.runImmediately }}
  backupRetention: {{ .Values.backup.backupRetention | quote }}
  snapshotRetention: {{ .Values.backup.snapshotRetention | quote }}
{{- end }}
{{- end -}}

{{- define "common.tridentprotect.labels" -}}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/component: backup
{{- end -}}
