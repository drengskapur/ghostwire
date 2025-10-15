{{/*
Expand the name of the chart.
*/}}
{{- define "ghostwire.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
*/}}
{{- define "ghostwire.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "ghostwire.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "ghostwire.labels" -}}
helm.sh/chart: {{ include "ghostwire.chart" . }}
{{ include "ghostwire.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "ghostwire.selectorLabels" -}}
app.kubernetes.io/name: {{ include "ghostwire.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "ghostwire.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "ghostwire.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Return the proper image name (supports both tag and digest)
*/}}
{{- define "ghostwire.image" -}}
{{- if .Values.image.digest }}
{{- printf "%s@%s" .Values.image.repository .Values.image.digest }}
{{- else }}
{{- printf "%s:%s" .Values.image.repository (.Values.image.tag | default .Chart.AppVersion) }}
{{- end }}
{{- end }}

{{/*
Return the proper tunnel image name (supports both tag and digest)
*/}}
{{- define "ghostwire.tunnelImage" -}}
{{- if .Values.tunnel.image.digest }}
{{- printf "%s@%s" .Values.tunnel.image.repository .Values.tunnel.image.digest }}
{{- else }}
{{- printf "%s:%s" .Values.tunnel.image.repository .Values.tunnel.image.tag }}
{{- end }}
{{- end }}
