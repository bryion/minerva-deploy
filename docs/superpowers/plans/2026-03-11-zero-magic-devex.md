# Zero-Magic DevEx Setup Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Establish a "zero-magic" development environment by removing custom shell scripts and standardizing on native Ansible/Python dependency files (requirements.yml, requirements.txt) and standard linting configurations.

**Architecture:** We are removing the `scripts/` directory entirely. Python dependencies will be explicitly pinned in `requirements.txt`. Ansible Galaxy collections and roles will be defined in a new `requirements.yml`. The `README.md` will be updated to document the standard native commands for onboarding.

**Tech Stack:** Python (pip), Ansible, Git, Bash

---

## Chunk 1: Create Ansible Requirements and Pin Python Dependencies

### Task 1: Create requirements.yml for Ansible

**Files:**
- Create: `requirements.yml`

- [ ] **Step 1: Write `requirements.yml` content**
Create `requirements.yml` at the project root with the following content:
```yaml
---
roles:
  - name: geerlingguy.docker

collections:
  - name: community.docker
    version: 3.9.0
```

- [ ] **Step 2: Verify `requirements.yml` structure**
Run: `ansible-galaxy install -r requirements.yml --roles-path ansible/roles`
Expected: Ansible Galaxy installs the role and collection successfully without errors.

- [ ] **Step 3: Commit**
```bash
git add requirements.yml
git commit -m "chore(deps): add requirements.yml for ansible galaxy"
```

### Task 2: Pin versions in requirements.txt

**Files:**
- Modify: `requirements.txt`

- [ ] **Step 1: Update `requirements.txt` with strict pins**
Replace the contents of `requirements.txt` with:
```text
ansible==12.3.0
ansible-lint==26.3.0
docker==7.1.0
requests==2.32.5
molecule==26.3.0
molecule-plugins[docker]==25.8.12
```
*(Note: These versions are representative stable versions compatible with Ansible 8+ and Python 3.11+. During execution, the agent should verify these versions or use the exact output of a `pip freeze` in the current working `.venv`.)*

- [ ] **Step 2: Verify dependency installation**
Run: `pip install -r requirements.txt`
Expected: Pip successfully installs or verifies the pinned versions.

- [ ] **Step 3: Commit**
```bash
git add requirements.txt
git commit -m "chore(deps): pin exact python package versions"
```

---

## Chunk 2: Remove Custom Scripts and Update Documentation

### Task 3: Delete the `scripts/` directory

**Files:**
- Delete: `scripts/minerva-setup.sh`
- Delete: `scripts/minerva-wipe.sh`

- [ ] **Step 1: Remove the scripts folder**
Run: `git rm -r scripts/`
Expected: Both files and the directory are staged for deletion.

- [ ] **Step 2: Commit**
```bash
git commit -m "chore: remove custom dev scripts in favor of native tooling"
```

### Task 4: Update README.md Getting Started Section

**Files:**
- Modify: `README.md`

- [ ] **Step 1: Rewrite the Getting Started instructions**
Edit `README.md` to replace the "1. Clone and set up" section.
Find:
```markdown
### 1. Clone and set up

```bash
git clone https://github.com/bryion/minerva-deploy.git
cd minerva-deploy
bash scripts/minerva-setup.sh
source .venv/bin/activate
```
```
Replace with:
```markdown
### 1. Clone and set up

```bash
git clone https://github.com/bryion/minerva-deploy.git
cd minerva-deploy

# Create and activate a virtual environment
python3 -m venv .venv
source .venv/bin/activate

# Install Python dependencies
pip install -r requirements.txt

# Install Ansible roles and collections
ansible-galaxy install -r requirements.yml -p ansible/roles
```
```

- [ ] **Step 2: Verify Markdown formatting**
Run: `cat README.md` and visually inspect the Getting Started section to ensure the code blocks are correctly formatted.

- [ ] **Step 3: Commit**
```bash
git add README.md
git commit -m "docs: update onboarding steps to use native tooling"
```
