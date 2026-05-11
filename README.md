
  Completed:

   1. The Code: Built a multi-service app with a FastAPI (Python) backend, React frontend, and a background Worker to process
      votes through Redis and Postgres.
   2. Containerization: Wrote custom Dockerfiles for every service, using multi-stage builds and non-root users to keep things
      small and secure.
   3. Local Orchestration: Used Docker Compose to link all 5 containers (App + Worker + Redis + DB + Frontend) on my machine.
   4. Kubernetes Migration: Moved the whole stack to K8s. Set up Deployments, Services, PVCs for storage, and Secrets for
      security.
   5. Networking & Ingress: Set up a Traefik/Nginx Ingress controller to route traffic. No more port-forwarding—the app is live at
      http://pulse.test using path-based routing (/api for backend).
   6. CI/CD Automation: Created GitHub Actions to automatically build and push my images to GHCR every time I push code.
   7. Helm Packaging: Bundled everything into a Helm Chart. Now I can deploy the entire stack with one command: helm install.
   8. Infrastructure as Code (IaC): Used Terraform to provision a VPC and a managed Postgres (RDS) instance in AWS.
   9. Cloud Migration: Successfully moved the app's database from a local container to the AWS Cloud.api

How to run (for now):

  ---


  1. Infrastructure:

    cd terraform && terraform apply

  2. App Deployment:

    helm install pulse ./sentinel -n vote --create-namespace

  ---

What's next:
   * Go Full Cloud: Move the compute from my local cluster to AWS EKS (Managed Kubernetes) using Terraform.
   * GitOps: Set up ArgoCD so the cluster stays in sync with my Git repo automatically.
   * Observability: Add Prometheus and Grafana dashboards to see how many votes are hitting the DB per second.
