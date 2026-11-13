
---
name: preflight-check
description: Validate that the Journal API capstone project is ready for submission. Checks required project files, Docker build, Terraform configuration, and Kubernetes manifest YAML.
---

# Capstone Preflight Check

You are responsible for checking whether this capstone project is ready for submission.

Run the checks below from the repository root. Do not assume a check passed without running it and inspecting its result.

## 1. Inspect the project

- Confirm the current working directory is the project root.
- Inspect the repository structure.
- Identify the Dockerfile, Terraform configuration, Kubernetes manifests, API source code, and project documentation.

## 2. Check required files

Verify that the following files or directories exist:

- `Dockerfile`
- `README.md`
- `api/main.py`
- `.dockerignore`
- `.gitignore`
- `.devcontainer/`
- At least one Terraform `.tf` file.
- At least one Kubernetes YAML manifest.

Report any missing items. DO NOT create placeholder files just to make the check pass!

## 3. Verify the Docker build

If a Dockerfile exists, run:

```bash
docker build --platform linux/amd64 -t journal-api:preflight .
```

- Inspect the build output.
- If it fails, identify the cause and attempt to fix the relevant project files.
- Re-run the build after making a correction.
- DO NOT push the image to a registry!!

## 4. Validate Terraform

Find the directories containing Terraform `.tf` files.

For each Terraform root module:

```bash
terraform init -backend=false -input=false
terraform validate
```

- DO NOT provision or destroy infrastructure.
- DO NOT run `terraform apply` or `terraform destroy`.
- DO NOT change AWS resources.
- If validation fails, inspect the configuration and fix issues where possible.
- Run `terraform validate` again after corrections.

## 5. Validate Kubernetes manifests

Find Kubernetes `.yaml` and `.yml` manifests in the project, excluding dependency and generated directories.

Use Ruby's YAML parser to check that each manifest is syntactically valid:

```bash
ruby -e 'require "yaml"; ARGV.each { |f| YAML.load_stream(File.read(f)); puts "VALID: #{f}" }' FILES
```

Replace `FILES` with the discovered manifest paths.

- Check every relevant manifest.
- Report the exact file and error for invalid YAML.
- Fix syntax errors where possible and repeat the check.
- DO NOT run `kubectl apply` or modify the live cluster.

## 6. Final review

Run:

```bash
git status --short
```

Summarise the results under these headings:

- Required files
- Docker build
- Terraform validation
- Kubernetes YAML validation
- Issues found
- Fixes applied
- Remaining issues

Classify each check as PASS, FAIL, or BLOCKED.

DO NOT claim the project is submission-ready if any required check is FAIL or BLOCKED.

DO NOT expose secrets, print `.env` contents, commit changes, push code, or modify live AWS/Kubernetes resources.

DO NOT make ANY corrections!!!!
