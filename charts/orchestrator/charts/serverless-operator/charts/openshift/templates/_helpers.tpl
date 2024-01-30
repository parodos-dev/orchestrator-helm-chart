
{{- define "resource-exists" -}}
    {{- $api := index . 0 -}}
    {{- $kind := index . 1 -}}
    {{- $namespace := index . 2 -}}
    {{- $name := index . 3 -}}
    {{- $existingResource := lookup $api $kind $namespace $name }}
    {{- if empty $existingResource }}
        {{- "false" -}}
    {{- else }}
        {{- "true" -}}
    {{- end }}
{{- end }}

{{- define "unmanaged-resource-exists" -}}
    {{- $api := index . 0 -}}
    {{- $kind := index . 1 -}}
    {{- $namespace := index . 2 -}}
    {{- $name := index . 3 -}}
    {{- $releaseName := index . 4 -}}
    {{- $unmanagedSubscriptionExists := "true" -}}
    {{- $existingOperator := lookup $api $kind $namespace $name -}}
    {{- if empty $existingOperator -}}
        {{- "false" -}}
    {{- else -}}
        {{- $isManagedResource := include "is-managed-resource" (list $existingOperator $releaseName) -}}
        {{- if eq $isManagedResource "true" -}}
            {{- "false" -}}
        {{- else -}}
            {{- "true" -}}
        {{- end -}}
    {{- end -}}
{{- end -}}

{{- define "is-managed-resource" -}}
    {{- $resource := index . 0 -}}
    {{- $releaseName := index . 1 -}}
    {{- $resourceReleaseName := dig "metadata" "annotations" (dict "meta.helm.sh/release-name" "NA") $resource -}}
    {{- if eq (get $resourceReleaseName "meta.helm.sh/release-name") $releaseName -}}
        {{- "true" -}}
    {{- else -}}
        {{- "false" -}}
    {{- end -}}
{{- end -}}

{{- define "is-resource-installed" -}}
    {{- $api := index . 0 -}}
    {{- $kind := index . 1 -}}
    {{- $namespace := index . 2 -}}
    {{- $name := index . 3 -}}
    {{- $releaseName := index . 4 -}}
    {{- $unmanagedResourceExists := include "unmanaged-resource-exists" (list $api $kind $namespace $name $releaseName) }}
    {{- if eq $unmanagedResourceExists "false" }}
        {{- "YES" -}}
    {{- else -}}
        {{- "NO" -}}
    {{- end -}}
{{- end }}
