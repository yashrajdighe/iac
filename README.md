## Development Setup

### Pre-commit Hooks

The repository uses pre-commit hooks to format Terraform, Terragrunt, and YAML files before commits.

1. Create and activate the Python virtual environment:
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

The hooks will automatically run when you commit changes, ensuring:
- Terraform files are properly formatted with `terraform fmt`
- Terragrunt files are properly formatted with `terragrunt hclfmt`
- YAML files are validated with `yamllint`
- Files end with a newline
- Trailing whitespace is removed
