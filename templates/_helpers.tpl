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

{{/*
TopologySpreadConstraints — spread GPU pods across nodes (maxSkew 1)
*/}}
{{- define "insurguard.gpuTopologySpread" -}}
topologySpreadConstraints:
  - maxSkew: 1
    topologyKey: kubernetes.io/hostname
    whenUnsatisfiable: ScheduleAnyway
    labelSelector:
      matchLabels:
        insurguard/gpu-workload: "true"
{{- end }}

{{/*
GPU node selector — pin all GPU workloads to nodes matching gpu.nodeSelector.
The map is passed as-is, so any label key/value works (e.g. nvidia.com/gpu.product).
Override at install time:
  --set gpu.nodeSelector."nvidia\.com/gpu\.product"=NVIDIA-L40S-SHARED
  --set gpu.nodeSelector."nvidia\.com/gpu\.product"=NVIDIA-RTX-PRO-6000-Blackwell-Server-Edition-SHARED
*/}}
{{- define "insurguard.gpuNodeSelector" -}}
{{- if .Values.gpu.nodeSelector }}
nodeSelector:
  {{- range $key, $val := .Values.gpu.nodeSelector }}
  {{ $key }}: {{ $val | quote }}
  {{- end }}
{{- end }}
{{- end }}

{{/*
Anti-affinity — prevent heavy NIM services from landing on the same node.
Pass the component name as .component in the context.
*/}}
{{- define "insurguard.nimAntiAffinity" -}}
affinity:
  podAntiAffinity:
    preferredDuringSchedulingIgnoredDuringExecution:
      - weight: 100
        podAffinityTerm:
          labelSelector:
            matchExpressions:
              - key: insurguard/nim-heavy
                operator: In
                values: [ "true" ]
              - key: app.kubernetes.io/name
                operator: NotIn
                values: [ "{{ .component }}" ]
          topologyKey: kubernetes.io/hostname
{{- end }}
