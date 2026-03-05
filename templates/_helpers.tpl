{{/*
Expand the name of the chart.
*/}}
{{- define "insurguard.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
*/}}
{{- define "insurguard.fullname" -}}
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
{{- define "insurguard.labels" -}}
helm.sh/chart: {{ include "insurguard.name" . }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/part-of: insurguard
{{- end }}

{{/*
Selector labels for a component
*/}}
{{- define "insurguard.selectorLabels" -}}
app.kubernetes.io/name: {{ .component }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
NGC image pull secret name
*/}}
{{- define "insurguard.imagePullSecretName" -}}
{{ include "insurguard.fullname" . }}-ngc-pull
{{- end }}

{{/*
NVIDIA API secret name
*/}}
{{- define "insurguard.nvidiaSecretName" -}}
{{ include "insurguard.fullname" . }}-nvidia-api
{{- end }}

{{/*
OpenShift SecurityContext for non-root containers
*/}}
{{- define "insurguard.securityContext" -}}
runAsNonRoot: true
seccompProfile:
  type: RuntimeDefault
{{- end }}

{{/*
OpenShift container-level SecurityContext
*/}}
{{- define "insurguard.containerSecurityContext" -}}
allowPrivilegeEscalation: false
capabilities:
  drop: [ "ALL" ]
{{- end }}
