{{- define "troubleshoot.collectors.shared" -}}
# Collect information about the cluster the chart is installed in
- clusterInfo: {}
 
# Collects details about the following Kubernetes resources in the cluster:
#
#    * Nodes
#    * Namespaces
#    * Storage Classes
#    * CRDs
#    * DaemonSets
#    * Deployments
#    * Jobs and CronJobs
#    * Replicasets
#    * Statefulsets
#    * Services
#    * Endpoints
#    * Pods
#    * Ingress
#    * Configmaps
#    * Service Accounts
#    * Leases
#    * API Resource Groups
#    * Resources
#    * Events
#    * Services Accounts
# 
# The collector will collect all of the resources of these kinds that the account
# can access in the cluster. To limit to visible cluster-level resources and the installed 
# namspace switch to the following:
#    
#    clusterResources:
#      namespace: {{ .Release.Namespace }}
#
- clusterResources: {}
 
# Collect helm release history and values for this chart
- helm:
    collectorName: {{ include "enterprise.fullname" . }}
    namespace: {{ .Release.Namespace }}
    releaseName: {{ .Release.Name }}
    collectValues: true
 
# Collect data about configured images to assure they exist and are accessible
- registryImages:
    images:
      - {{ .Values.cloudsql.image }}
      - {{ .Values.image }}
      - {{ .Values.migrationPodImage }}
      - {{ .Values.scratchVolume.fixerInitContainerImage }}
      - {{ .Values.ui.image }}
      - {{ .Values.upgradeJob.kubectlImage }}
      - replicated/replicated-sdk:v1.0.0-beta.16
      - bitnami/kubectl:1.27
    imagePullSecret:
      type: kubernetes.io/dockerconfigjson
      name: {{ .Values.imagePullSecretName }}
# Test connectivity to the Postgres database and collect information about the version
{{- if (not .Values.postgresql.enabled ) }}
- postgres:
    collectorName: postgres
    uri: "postgresql://{{- template "enterprise.ui.dbUser" . -}}:{{- template "enterprise.ui.dbPassword" . -}}@{{ template "enterprise.dbHostname" . }}/{{ index .Values "postgresql" "auth" "database" }}"
    {{- if .Values.anchoreConfig.database.ssl -}}
    tls:
      skipVerify: {{- (not ( eq .Values.anchoreConfig.database.sslMode "verify-full" ) ) -}}
    {{- end -}}
{{- end -}}

{{- define "troubleshoot.analyzers.shared" -}}
# Confirm that the cluster is running a supported version based on the docs for the chart and the
# current release/EOL status
- clusterVersion:
    checkName: Is this cluster running a supported Kubernetes verison
    outcomes:
      - fail:
          when: "< 1.23.0"
          message: |
            Anchore Enterprise is only supported on Kubernetes 1.23 or later
          uri: https://github.com/anchore/anchore-charts/tree/main/stable/enterprise#prerequisites
      - warn:
          when: "< 1.27.0"
          message: |
            You can run Anchore Enterprise on your current cluster version, but
            your cluster is no longer supported by the Kubernetes community. If
            you have extended support available from your Kubernetes vendor you
            can ignore this warning.
          uri: https://kubernetes.io/releases
      - pass:
          message: |
            Your current Kubernetes version is able to run Anchore Enterprise
            and is a version currently supported by the Kubernetes community

# Validate whether the distribution is supported by Anchore Enterprise, since the docs don't specify
# whether any distributions are supported or not we allow all of the possible server-oriented versions
# and warn on the desktop/dev style ones.
- distribution:
    checkName: Are we installing into a supported Kubernetes distribution
    outcomes:
      - warn:
          when: "== docker-desktop"
          message: | 
            You are able to run Anchore Enterprise in Docker Desktop, but we recommend using a different
            Kubernetes distribution for your production installation.
      - warn:
          when: "== microk8s"
          message: | 
            You are able to run Anchore Enterprise in MicroK8s, but we recommend using a different
            Kubernetes distribution for your production installation.
      - warn:
          when: "== minikube"
          message: | 
            You are able to run Anchore Enterprise in Minikube, but we recommend using a different
            Kubernetes distribution for your production installation.
      - pass:
          when: "== eks"
          message: Amazon EKS is a suppored Kubernetes distribution to run Anchore Enterprise in production
      - pass:
          when: "== gke"
          message: Google Kubernetes Enterprise is a suppored Kubernetes distribution to run Anchore Enterprise in production
      - pass:
          when: "== aks"
          message: Azure Kubernetes Services is a supported Kubernetes distributiion to run Anchore Enterprise in production
      - pass:
          when: "== tanzu"
          message: VMware Tanzu is a supported Kubernetes distribution to run Anchore Enterprise in production
      - pass:
          when: "== kurl"
          message: The Replicated embedded Kubernetes distribution is supported to run Anchore Enterprise in production
      - pass:
          when: "== digitalocean"
          message: DigitalOcean is a supported Kubernetes distribution to run Anchore Enterprise in production
      - pass:
          when: "== oke"
          message: Oracle is a supported Kubernetes distribution to run Anchore Enterprise in production
      - pass:
          when: "== ibm"
          message: IBM Cloud is a supported Kubernetes distribution to run Anchore Enterprise in production
      - pass:
          when: "== ibm"
          message: IBM Cloud is a supported Kubernetes distribution to run Anchore Enterprise in production
      - pass:
          when: "== rke"
          message: Rancher is a supported Kubernetes distribution to run Anchore Enterprise in production
      - pass:
          message: We are unable to detect the Kubernetes distribution you are running


# Confirm sufficient allocatable CPU in the cluster, this does not confirm that allocatable CPU
# is available to allocate to the pods in the chart. Commented out since the docs don't specify any
# requirements and the objects in the chart don't specify any minimums.
# - nodeResources:
#     checkName: Are sufficient CPU resources available in the cluster
#     outcomes:
#       - fail:
#           when: "sum(cpuAllocatable) < 250m"
#           message: Your cluster currently has too few CPU resources available to install Anchore Enterprise
#       - pass:
#           message: Your cluster has sufficient CPU resources available to install Anchore Enterprise
 
# confirm sufficient allocatable memory in the cluster, this does not confirm that allocatable memory
# is available to allocate to the pods in the chart
- nodeResources:
    checkName: Is sufficient memory available in the cluster
    outcomes:
      - fail:
          when: "min(memoryAllocatable) < 8Gi" 
          message: Your cluster currently has too little memory available to install Anchore Enterprise
      - pass:
          message: Your cluster has sufficient memory available to install Anchore Enterprise

# report out whether configured images exist and are accessible
- registryImages:
    name: Registry Images
    outcomes:
      - fail:
        when: "missing > 0"
        message: Images are missing from registry
      - warn:
          when: "errors > 0"
          message: Failed to check if images are present in registry
      - pass:
          message: All images are present in registry
# Validate connection to an external database. 
{{- if (not .Values.postgresql.enabled ) }}
- postgres:
    checkName: Postgress connection
    collectorName: postgress
    outcomes:
      - fail:
          when: connected == false
          message: Cannot connect to the Postgres server {{ template "enterprise.dbHostname" . }}
      - pass:
          message: Postgres server {{ template "enterprise.dbHostname" . }} is ready and connected
{{- end -}}
{{- end -}}
