{{/*
Expand the name of the chart.
*/}}
{{- define "insureguard.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
*/}}
{{- define "insureguard.fullname" -}}
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
Common labels
*/}}
{{- define "insureguard.labels" -}}
helm.sh/chart: {{ include "insureguard.name" . }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/part-of: insureguard
{{- end }}

{{/*
Selector labels for a component
*/}}
{{- define "insureguard.selectorLabels" -}}
app.kubernetes.io/name: {{ .component }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
NGC image pull secret name
*/}}
{{- define "insureguard.imagePullSecretName" -}}
{{ include "insureguard.fullname" . }}-ngc-pull
{{- end }}

{{/*
NVIDIA API secret name
*/}}
{{- define "insureguard.nvidiaSecretName" -}}
{{ include "insureguard.fullname" . }}-nvidia-api
{{- end }}

{{/*
OpenShift SecurityContext for non-root containers
*/}}
{{- define "insureguard.securityContext" -}}
runAsNonRoot: true
seccompProfile:
  type: RuntimeDefault
{{- end }}

{{/*
OpenShift container-level SecurityContext
*/}}
{{- define "insureguard.containerSecurityContext" -}}
allowPrivilegeEscalation: false
capabilities:
  drop: [ "ALL" ]
{{- end }}
