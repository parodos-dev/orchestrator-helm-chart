{{- define "manage-cr-lifecycle-on-action" }}
  {{- $resourceAPIGroup := printf "%s.%s" .kinds .apiGroup }}
  {{- $releaseNameKind := printf "%s-%s" .release.Name .kind |lower }}
  {{ if or .isEnabled (and (not .isEnabled) (and .hasCRDInstalled (not (empty (lookup (printf "%s/%s" .apiGroup .groupVersion) .kind (dig "targetNamespace" "" . ) .resourceName ))))) }}
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: {{ $releaseNameKind }}
  namespace: {{ .release.Namespace }}
  annotations:
    "helm.sh/hook": pre-delete,{{ if .isEnabled }}post-install,post-upgrade,post-rollback{{ else }}pre-upgrade,pre-rollback{{ end }}
    "helm.sh/hook-delete-policy": before-hook-creation,hook-succeeded,hook-failed
    "helm.sh/hook-weight": "-1"
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: {{ $releaseNameKind }}
  annotations:
    "helm.sh/hook": pre-delete,{{ if .isEnabled }}post-install,post-upgrade,post-rollback{{ else }}pre-upgrade,pre-rollback{{ end }}
    "helm.sh/hook-delete-policy": before-hook-creation,hook-succeeded,hook-failed
    "helm.sh/hook-weight": "0"
rules:
  - apiGroups:
    - apiextensions.k8s.io
    resources:
    - customresourcedefinitions
    verbs:
    - get
  - apiGroups:
    - {{ .apiGroup }}
    resources:
    - {{ .kinds |lower}}
    verbs:
    - get
    - list
    - delete
    - patch
    - update
    - create
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: {{ $releaseNameKind }}
  annotations:
    "helm.sh/hook": pre-delete,{{ if .isEnabled }}post-install,post-upgrade,post-rollback{{ else }}pre-upgrade,pre-rollback{{ end }}
    "helm.sh/hook-delete-policy": before-hook-creation,hook-succeeded,hook-failed
    "helm.sh/hook-weight": "0"
subjects:
  - kind: ServiceAccount
    name: {{ $releaseNameKind }}
    namespace: {{ .release.Namespace }}
roleRef:
  kind: ClusterRole
  name: {{ $releaseNameKind }}
  apiGroup: rbac.authorization.k8s.io
    {{- if .isEnabled }}
---
apiVersion: batch/v1
kind: Job
metadata:
  name: {{ trunc -57 (printf "%s-%s" $releaseNameKind (.release.IsInstall | ternary "install" "upgrade" ) ) }} # Fixes https://github.com/parodos-dev/orchestrator-helm-chart/issues/160
  # job name is used in the spec.template.metadata.labels, and labels cannot be more than 63 characters https://kubernetes.io/docs/concepts/overview/working-with-objects/labels/
  namespace: {{ .release.Namespace }}
  annotations:
    "helm.sh/hook": post-install,post-upgrade,post-rollback
    "helm.sh/hook-delete-policy": before-hook-creation,hook-succeeded
    "helm.sh/hook-weight": "1"
spec:
  template:
    metadata:
      name: {{ printf "%s-upgrade" $releaseNameKind }}
    spec:
      serviceAccountName: {{ $releaseNameKind }}
      containers:
        - name: job
          image: registry.redhat.io/openshift4/ose-cli:latest
          env:
            - name: MANIFEST
              value: {{ .manifest }}
          command:
            - "bin/bash"
            - "-c"
          args:
            - |
              echo "Update Job for CR {{ .kind }} of {{ $resourceAPIGroup }} started"
              echo "Checking for availability of CRD {{ printf "%s.%s" .kinds .apiGroup }}"
              count=60
              while [[ count -ne 0 ]]
              do
                kubectl get crd {{ printf "%s.%s" .kinds .apiGroup }} -oname
                if [[ $? -eq 0 ]]; then
                  echo $MANIFEST | base64 -d | kubectl apply -f -
                  echo "Update Job finished"
                  exit 0
                fi
                ((count--))
                sleep 5
              done
              echo "Could not find CRD {{ printf "%s.%s" .kinds .apiGroup }} deployed"
              exit 1

      restartPolicy: Never
    {{- end }}
---
apiVersion: batch/v1
kind: Job
metadata:
  name: {{ trunc -57 (printf "%s-delete" $releaseNameKind) }} # Fixes https://github.com/parodos-dev/orchestrator-helm-chart/issues/160
  # job name is used in the spec.template.metadata.labels, and labels cannot be more than 63 characters https://kubernetes.io/docs/concepts/overview/working-with-objects/labels/
  namespace: {{ .release.Namespace }}
  annotations:
    "helm.sh/hook": {{ if .isEnabled }}pre-delete{{ end }}{{ if and (not .isEnabled) (not (empty (lookup (printf "%s/%s" .apiGroup .groupVersion) .kind (dig "targetNamespace" "" . ) .resourceName ))) }}pre-upgrade,pre-rollback{{ end }}
    "helm.sh/hook-delete-policy": before-hook-creation,hook-succeeded
    "helm.sh/hook-weight": "1"
spec:
  template:
    metadata:
      name: {{ $releaseNameKind }}
    spec:
      serviceAccountName: {{ $releaseNameKind }}
      containers:
        - name: cleanup
          image: registry.redhat.io/openshift4/ose-cli:latest
          command:
            - "bin/bash"
            - "-c"
          args:
            - |
              echo "Cleanup Job for CR {{ .kind }} of {{ $resourceAPIGroup }} started"
              kubectl get crd {{ $resourceAPIGroup }}
              if [ $? -eq 0 ]; then
                kubectl get {{ if (hasKey . "targetNamespace") }} -n {{ .targetNamespace }} {{ end }} {{ $resourceAPIGroup }} {{ .resourceName }}
                if [ $? -eq 0 ]; then
                  kubectl delete {{ if (hasKey . "targetNamespace") }} -n {{ .targetNamespace }} {{ end }} {{ $resourceAPIGroup }} {{ .resourceName }} || exit 1
                fi
              fi
              echo "Cleanup Job finished"
      restartPolicy: Never
  {{- end }}
{{- end }}