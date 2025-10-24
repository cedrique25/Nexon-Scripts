# 🧾 Repository Status Check Script

### Overview
This script audits multiple GitHub repositories under **Nexon-Asia-Pacific-Pty-Ltd** and generates a CSV report containing key repository details such as activity, owners, secrets, and more.  
It’s designed to help quickly assess which repositories are active, maintained, and ready for migration.

---

### 🔧 Features
- ✅ Checks if each repository is **active or archived**
- 🔑 Detects if it has **GitHub Actions secrets or variables**
- 💻 Detects if the repository **contains actual code**
- 👥 Lists top contributors (owners)
- 🔄 Marks if the repository **mentions migration**
- 🕒 Records the **last update timestamp**

---

### 📋 Requirements
Before running the script, ensure the following tools are installed:

| Tool | Purpose | Install Command |
|------|----------|-----------------|
| **GitHub CLI (`gh`)** | Access GitHub API | [Install Guide](https://cli.github.com/) |
| **jq** | Parse JSON data | `sudo apt install jq` (Linux) / `brew install jq` (Mac) / `choco install jq` (Windows) |

Also, make sure you’re logged in to GitHub CLI:
```bash
gh auth login
```

---

### 🚀 How to Use
1. Create a text file named **`repos.txt`** in the same directory as the script.  
   Each line should contain one GitHub repository URL:
   ```
   https://github.com/Nexon-Asia-Pacific-Pty-Ltd/cloud-security-audit
   https://github.com/Nexon-Asia-Pacific-Pty-Ltd/devops-tools
   ```

2. Run the script:
   ```bash
   bash repo_status_check_final_v4.sh
   ```

3. After execution, a new CSV file will be generated:
   ```
   repo_audit_results_YYYYMMDD_HHMMSS.csv
   ```

---

### 📊 Example Output
| repo_name | repo_url | owners | active | has_secrets | has_vars | has_code | migrated | updated_at |
|------------|-----------|---------|---------|--------------|-----------|-----------|------------|-------------|
| cloud-security-audit | https://github.com/Nexon-Asia-Pacific-Pty-Ltd/cloud-security-audit | user1, user2 | Yes | No | Yes | Yes | No | 2025-10-21 |
| devops-tools | https://github.com/Nexon-Asia-Pacific-Pty-Ltd/devops-tools | user3 | No | No | No | No | Yes | 2024-05-12 |

---

### 📝 Notes
- Empty lines in `repos.txt` are ignored.
- The script uses GitHub API — avoid running it too frequently to prevent rate limits.
- Contributors exclude `github-actions[bot]` and your own username for clarity.
- Ideal for repo cleanup, activity checks, or migration readiness tracking.

---

### 👤 Author
**Cedrique Cablao**  
DevOps Engineer @ Nexon Asia Pacific
