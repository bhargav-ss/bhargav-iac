{{/*
Define a common name template. This is used to generate the names for
the NodeClass and NodePool resources to ensure they match.
*/}}
{{- define "karpenter-custom-resources.name" -}}
{{- printf "%s-%s" .Release.Name .Values.nameSuffix | trunc 63 | trimSuffix "-" -}}
{{- end -}} 