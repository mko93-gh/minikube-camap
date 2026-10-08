{{- define "camap.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "camap.fullname" -}}
{{- if .Values.fullnameOverride -}}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- $name := include "camap.name" . -}}
{{- if contains $name .Release.Name -}}
{{- .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{- define "camap.labels" -}}
app.kubernetes.io/name: {{ include "camap.name" . }}
helm.sh/chart: {{ .Chart.Name }}-{{ .Chart.Version | replace "+" "_" }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end -}}

{{/*
  Snippet serveur Ingress API
*/}}
{{- define "camap.ingress.apiServerSnippet" -}}
{{- range .Values.ingress.denyCidrs }}
deny {{ . }};
{{- end }}
{{- end }}

{{/* TLS secret pour l’API */}}
{{- define "camap.tlsSecretNameApi" -}}
{{- if .Values.ingress.api.tls.secretName -}}
{{- .Values.ingress.api.tls.secretName | quote -}}
{{- else -}}
{{- printf "%s-api-tls" (include "camap.fullname" .) | quote -}}
{{- end -}}
{{- end -}}

{{/* TLS secret pour le Web */}}
{{- define "camap.tlsSecretNameWeb" -}}
{{- if .Values.ingress.web.tls.secretName -}}
{{- .Values.ingress.web.tls.secretName | quote -}}
{{- else -}}
{{- printf "%s-web-tls" (include "camap.fullname" .) | quote -}}
{{- end -}}
{{- end -}}
