# Terraform Assignment — VPC, NLB, EKS, EC2 on AWS (ap-south-1)

This provisions the 4 required resources with **Terraform**, deployable through
**either** a Jenkins pipeline or a GitHub Actions workflow (both are included
and point at the same Terraform code).

## What gets created (and why it's kept minimal)

| Resource | Details | Cost-saving choice |
|---|---|---|
| VPC | `10.0.0.0/16`, 1 Internet Gateway | — |
| Subnets | 2 **public** subnets only, 2 AZs (`ap-south-1a`, `ap-south-1b`) | No private subnets → **no NAT Gateway** (NAT Gateway is the single biggest avoidable cost, ~$32+/month) |
| NLB | 1 internet-facing Network Load Balancer, TCP listener on port 80 | Forwards straight to the EC2 instance |
| EC2 | 1× `t2.micro` (free-tier eligible), Amazon Linux 2023, nginx installed via user_data | Single instance, no ASG |
| EKS | 1 control plane + 1 managed node group with **exactly 1 node** (`t3.medium`) | Smallest viable EKS footprint — EKS control plane itself has a fixed hourly cost (~$0.10/hr) that Terraform can't reduce further, so **remember to destroy it when done** |

Total resources: ~20 Terraform resources, all in `ap-south-1`.

## File layout

```
provider.tf   - Terraform/provider config (+ optional S3 backend, commented out)
variables.tf  - All configurable inputs (region, CIDR, instance sizes, etc.)
vpc.tf        - VPC, subnets, IGW, route table
ec2.tf        - EC2 instance + its security group
nlb.tf        - Network Load Balancer + target group + listener
eks.tf        - EKS cluster, IAM roles, 1-node managed node group
outputs.tf    - Useful values printed after apply (NLB DNS, kubeconfig cmd, etc.)
Jenkinsfile   - Jenkins declarative pipeline
.github/workflows/terraform.yml - GitHub Actions workflow
```

## 1. Run it locally first (recommended before wiring up CI/CD)

```bash
terraform init
terraform plan
terraform apply      # type "yes" when prompted
```

When done experimenting:
```bash
terraform destroy    # IMPORTANT — EKS + NLB cost money while they exist
```

## 2. Jenkins pipeline setup

1. In Jenkins, install the **Pipeline** plugin (usually pre-installed) and
   make sure `terraform` and `awscli` are on the Jenkins agent's `PATH`
   (or use a Docker agent with those tools baked in).
2. Go to **Manage Jenkins → Credentials** and add a
   **"Username with password"** credential:
   - Username = your `AWS_ACCESS_KEY_ID`
   - Password = your `AWS_SECRET_ACCESS_KEY`
   - ID = `aws-creds` (must match the ID used in the `Jenkinsfile`)
3. Create a new **Pipeline** job → "Pipeline script from SCM" → point it at
   this repo → Script Path = `Jenkinsfile`.
4. Run the job. It will `init` → `validate` → `plan` automatically, then
   **pause for manual approval** before `apply` or `destroy` (choose the
   `ACTION` build parameter: `plan`, `apply`, or `destroy`).

## 3. GitHub Actions setup

1. In your GitHub repo, go to **Settings → Secrets and variables → Actions**
   and add two repository secrets:
   - `AWS_ACCESS_KEY_ID`
   - `AWS_SECRET_ACCESS_KEY`
2. Push this code to the `main` branch — the workflow
   (`.github/workflows/terraform.yml`) runs automatically:
   `fmt check → init → validate → plan → apply`.
3. To destroy, go to the **Actions** tab → select the workflow →
   **Run workflow** → choose `destroy` from the dropdown (manual trigger only,
   so you can't accidentally tear things down on a normal push).

## 4. Remote state (recommended once you move past local testing)

Right now Terraform state is stored **locally** (a `terraform.tfstate` file),
which is fine for a single person testing manually, but Jenkins and GitHub
Actions run on separate machines each time — they won't share that local
file. For real CI/CD, uncomment the `backend "s3"` block in `provider.tf`,
create an S3 bucket first (`aws s3 mb s3://your-bucket --region ap-south-1`),
fill in the bucket name, then run `terraform init -migrate-state`.

## 5. Verifying it worked

```bash
# EC2 behind the NLB
curl http://$(terraform output -raw nlb_dns_name)

# EKS cluster
$(terraform output -raw configure_kubectl)
kubectl get nodes
```

## 6. Customizing

All the knobs are in `variables.tf` — e.g. change `eks_node_instance_type`,
`ec2_instance_type`, `vpc_cidr`, or `my_ip_cidr` (for SSH access) without
touching any other file.

## 7. Cleaning up (don't skip this!)

```bash
terraform destroy
```
EKS and the NLB both bill hourly while they exist — destroy them once you've
demonstrated the assignment.
