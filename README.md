# HRGF GCP DevOps Project - Automated Kubernetes Deployment

## Overview

This project automates the deployment of a simple Nginx web application to GCP GKE using Infrastructure as Code (Terraform), containerization (Docker), and CI/CD (GitHub Actions). The solution includes Helm for Kubernetes deployment management and Trivy for container security scanning.

**Tech Stack:** GCP GKE, Terraform, Docker, Kubernetes, Helm, GitHub Actions, Trivy, Artifact Registry

---
## Project Structure

```
├── app/                    # Web application (index.html)
│   └── index.html
│
├── docker/                 # Dockerfile and .dockerignore
│   ├── Dockerfile
│   └── .dockerignore
│
├── terraform/              # Infrastructure as Code
│   ├── main.tf            # GKE cluster, VPC, Artifact Registry
│   ├── variables.tf       # Input variables
│   ├── outputs.tf         # Output values
│   ├── providers.tf       # GCP provider
│   └── terraform.tfvars   # Your project configuration (not in git)
│
├── helm/hrgf-app/         # Helm chart for deployment
│   ├── Chart.yaml
│   ├── values.yaml
│   └── templates/
│       ├── deployment.yaml      # Application deployment
│       └── service.yaml         # LoadBalancer service
│
├── k8s/                   # Alternative K8s manifests
│   ├── deployment.yaml
│   └── service.yaml
│
├── .github/workflows/     # CI/CD pipeline
│   └── deploy.yml
│
├── .gitignore             # Git ignore rules
│
└── README.md
```
---

## How to Run IaC Code

### Prerequisites
- GCP account with billing enabled
- gcloud CLI installed and configured
- Terraform installed
- kubectl installed
- Service account key JSON file

### Deploy Infrastructure

```bash
cd terraform

# Update terraform.tfvars with your project ID
nano terraform.tfvars
# Set: project_id = "your-gcp-project-id"

# Initialize and deploy
terraform init
terraform validate
terraform plan
terraform apply
```

**Deployment time:** ~10-15 minutes

After deployment, configure kubectl:
```bash
gcloud container clusters get-credentials hrgf-gke-cluster \
  --zone us-central1-a \
  --project YOUR_PROJECT_ID

kubectl get nodes
```

---

## CI/CD Pipeline Setup

The pipeline triggers automatically on push to `main` branch.

### Required GitHub Secrets

Navigate to **Settings → Secrets and variables → Actions** and add:

- `GCP_SA_KEY` - Service account JSON key (entire file content)
- `GCP_PROJECT_ID` - GCP project ID (e.g., `hrgf-devops-project-xxxxx`)
- `GCP_REGION` - `us-central1`
- `GCP_ZONE` - `us-central1-a`
- `GKE_CLUSTER_NAME` - `hrgf-gke-cluster`
- `GAR_REPOSITORY` - `hrgf-app`

**How to get values:**
```bash
# Project ID
gcloud config get-value project

# Service Account Key - copy entire JSON file content
cat ~/path/to/service-account-key.json
```

### Trigger Deployment

```bash
git add .
git commit -m "Deploy application"
git push origin main
```

Pipeline runs automatically and deploys the application (~5-8 minutes).


### Cleanup
```bash
helm uninstall hrgf-app
kubectl delete svc hrgf-app
cd terraform
terraform destroy
```


---

## Design Choices

**Infrastructure:**
- **VPC-native GKE cluster** - Better network isolation, IP aliasing for pods and services
- **2 e2-small nodes** - Cost-effective machine type suitable for demo workloads
- **Artifact Registry** - Modern replacement for Container Registry, improved security features
- **LoadBalancer service** - Simple external access, GCP provisions Network Load Balancer
- **Auto-scaling enabled** - Scales between 1-3 nodes based on demand

**Application:**
- **Nginx Alpine** - Minimal image size (~23MB), production-ready
- **Helm over raw manifests** - Enables easy upgrades and rollbacks
- **Resource limits** - Prevents resource contention, ensures cluster stability

**CI/CD:**
- **GitHub Actions** - Native integration, free for public repos
- **Trivy scanning** - Automated vulnerability detection before deployment
- **Artifact Registry** - Native GCP integration, faster image pulls from GKE
- **gke-gcloud-auth-plugin** - Modern authentication method for kubectl

**Cost Optimization:**
- 15GB disk per node (reduced from 20GB default)
- e2-small machines (cheaper than n1-standard-1)
- Auto-scaling (scales down to 1 node when idle)
- GKE Standard tier (no control plane charges with free tier)
- **Estimated cost:** ~$20-25 for 7 days

---

## Live Application URL

After deployment completes, get the application URL:

```bash
kubectl get svc hrgf-app -o jsonpath='{.status.loadBalancer.ingress[0].ip}'
```

**Application URL:** `http://<EXTERNAL-IP>`

*(External IP will be available 2-3 minutes after deployment)*


---

## Quick Test Locally

```bash
docker build -f docker/Dockerfile -t hrgf-app:test .
docker run -d -p 8080:80 --name test hrgf-app:test
curl http://localhost:8080
docker stop test && docker rm test
```

---

## GCP-Specific Commands

### Authenticate with GCP
```bash
# Login to GCP
gcloud auth login

# Set project
gcloud config set project YOUR_PROJECT_ID

# Authenticate Docker with Artifact Registry
gcloud auth configure-docker us-central1-docker.pkg.dev
```

### Manual Image Push (for testing)
```bash
# Build image
docker build -f docker/Dockerfile -t us-central1-docker.pkg.dev/YOUR_PROJECT_ID/hrgf-app/hrgf-app:v1 .

# Push to Artifact Registry
docker push us-central1-docker.pkg.dev/YOUR_PROJECT_ID/hrgf-app/hrgf-app:v1
```

### Cluster Management
```bash
# List clusters
gcloud container clusters list

# Get cluster credentials
gcloud container clusters get-credentials hrgf-gke-cluster --zone us-central1-a

# View cluster details
gcloud container clusters describe hrgf-gke-cluster --zone us-central1-a

# List nodes
kubectl get nodes -o wide

# List all resources
kubectl get all
```

### Cost Monitoring
```bash
# Check current billing
gcloud billing accounts list
gcloud billing projects describe YOUR_PROJECT_ID

# Estimate costs
gcloud compute instances list --format="table(name,zone,machineType,status)"
```

---

## Troubleshooting

### Issue: gcloud authentication fails
```bash
gcloud auth login
gcloud auth application-default login
```

### Issue: kubectl can't connect to cluster
```bash
# Reinstall gke-gcloud-auth-plugin
gcloud components install gke-gcloud-auth-plugin

# Get credentials again
gcloud container clusters get-credentials hrgf-gke-cluster --zone us-central1-a

# Set environment variable
export USE_GKE_GCLOUD_AUTH_PLUGIN=True
```

### Issue: Terraform API errors
```bash
# Enable required APIs
gcloud services enable container.googleapis.com
gcloud services enable artifactregistry.googleapis.com
gcloud services enable compute.googleapis.com
```

### Issue: Permission denied errors
```bash
# Check service account permissions
gcloud projects get-iam-policy YOUR_PROJECT_ID

# Verify service account has required roles:
# - Kubernetes Engine Admin
# - Compute Admin
# - Storage Admin
# - Artifact Registry Administrator
```

### Issue: Docker push fails
```bash
# Reconfigure Docker authentication
gcloud auth configure-docker us-central1-docker.pkg.dev

# Or use access token
gcloud auth print-access-token | docker login -u oauth2accesstoken --password-stdin https://us-central1-docker.pkg.dev
```

---


**Author:** Karthikeya Tenali  
**Email:** tenalikarthikeya67@gmail.com  
**GitHub:** github.com/karthik-tenali  
**Platform:** Google Cloud Platform
