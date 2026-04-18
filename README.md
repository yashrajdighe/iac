# IaC

Infrastructure as Code for managing AWS, GCP, and Cloudflare resources using OpenTofu and Terragrunt.

## Tech Stack

- **[OpenTofu](https://opentofu.org/)** – Terraform-compatible IaC engine
- **[Terragrunt](https://terragrunt.gruntwork.io/)** – DRY configuration and orchestration for OpenTofu
- **Providers** – AWS, GCP, Cloudflare
- **[GitHub Actions](https://docs.github.com/actions)** – CI for `plan`, `apply`, and `import`
- **[pre-commit](https://pre-commit.com/)** – `tofu fmt`, `terragrunt hclfmt`, `yamllint`
- **[Renovate](https://docs.renovatebot.com/)** – Automated dependency updates

## Project Structure

```text
.
├── modules/                  # Reusable OpenTofu modules
│   ├── aws/                  # AWS modules (VPC, IAM, S3, Lambda, ...)
│   ├── gcp/                  # GCP modules (project, folder)
│   └── cloudflare/           # Cloudflare modules (DNS records)
│
├── terragrunt/               # Terragrunt live configuration
│   ├── _shared/              # Shared provider and backend configs
│   ├── infrastructure/
│   │   ├── aws/              # AWS environments (management, production, staging, ...)
│   │   ├── gcp/              # GCP organizations/projects
│   │   └── cloudflare/       # Cloudflare zones
│   └── terragrunt.hcl        # Root Terragrunt config
│
└── .github/workflows/        # CI pipelines (plan, apply, import)
```

## Development Setup

### Pre-commit Hooks

The repository uses pre-commit hooks to format OpenTofu/Terraform, Terragrunt, and YAML files before commits.

1. Create and activate a Python virtual environment:

```bash
python -m venv .venv
source .venv/bin/activate  # On Windows use: .venv\Scripts\activate
```

2. Install pre-commit:

```bash
pip install pre-commit
```

3. Install the git hooks:

```bash
pre-commit install
```

The hooks will automatically run on commit, ensuring:

- `.tf` files are formatted with `tofu fmt`
- `.hcl` files are formatted with `terragrunt hclfmt`
- YAML files are validated with `yamllint`
- Files end with a newline and trailing whitespace is removed
