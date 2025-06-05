{{/*
Standard labels
*/}}
{{- define "tiptap-collab-server.labels" -}}
helm.sh/chart: {{ include "tiptap-collab-server.chart" . }}
{{ include "tiptap-collab-server.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end -}}

{{/*
Selector labels
*/}}
{{- define "tiptap-collab-server.selectorLabels" -}}
app.kubernetes.io/name: {{ include "tiptap-collab-server.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end -}}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "tiptap-collab-server.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Common name override.
*/}}
{{- define "tiptap-collab-server.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create the name of the service account to use
*/}}
{{- define "tiptap-collab-server.serviceAccountName" -}}
{{- if .Values.serviceAccount.create -}}
    {{ default (include "tiptap-collab-server.name" .) .Values.serviceAccount.name }}
{{- else -}}
    {{ default "default" .Values.serviceAccount.name }}
{{- end -}}
{{- end -}}

{{/*
Create a checksum of the ConfigMap data to trigger pod restarts on change.
We include .Values.config here. If other values that go into the ConfigMap change, 
they should also be included in this checksum calculation.
*/}}
{{- define "tiptap-collab-server.configChecksum" -}}
{{- .Values.config | toYaml | sha256sum }}
{{- end -}} 