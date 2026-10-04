# START HERE

All project files are already in this folder. You do not need to create or paste any file.
Run the steps below in the Codespace terminal (menu Terminal > New Terminal), one block at a time.

Names used: repo `policynet-azure`, region `eastus`, state storage account `pnetstsaran2026`
(if Azure says the name is taken, change it in `envs/dev/providers.tf` and in step 3).

## 1. Log in to Azure
```bash
az login --use-device-code
export TF_VAR_subscription_id=$(az account show --query id -o tsv)
```
(Run the `export` line again whenever you open a new terminal.)

## 2. Install Terraform if `terraform version` says "command not found"
```bash
wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt update && sudo apt install -y terraform
```

## 3. Create the state storage (once)
```bash
az group create -n pnet-state-rg -l eastus
az storage account create -n pnetstsaran2026 -g pnet-state-rg -l eastus --sku Standard_LRS --allow-blob-public-access false
az storage container create -n tfstate --account-name pnetstsaran2026 --auth-mode key
```

## 4. Create your SSH key and variables file
```bash
ssh-keygen -t ed25519 -f ~/.ssh/pnet -N ""
echo "ssh_public_key = \"$(cat ~/.ssh/pnet.pub)\"" > envs/dev/terraform.tfvars
```

## 5. STAGE 2: deploy the flat network (the "before")
```bash
cd envs/dev
terraform init
terraform apply
cd ../..
```
Type `yes`. Wait 90 seconds, then run the test:
```bash
bash tests/run-matrix.sh
```
Expect FAIL lines (web can reach db). Screenshot this. It is your "before".

## 6. STAGE 3: lock it down (the "after")
```bash
mv envs/dev/nsg.tf.stage3 envs/dev/nsg.tf
cd envs/dev && terraform apply && cd ../..
```
Type `yes`. Wait 60 seconds, then:
```bash
bash tests/run-matrix.sh
```
Expect 6 PASS lines. Screenshot this. It is your "after".

## 7. Push to GitHub
```bash
git add -A
git commit -m "policynet project"
git push origin main
```
Refresh the repo page on github.com. You should see all the folders and files.

## 8. STAGE 4: GitHub login for the pipeline (OIDC)
```bash
unset GITHUB_TOKEN
gh auth login            # choose GitHub.com > HTTPS > paste a classic token with repo + workflow scopes
gh auth setup-git
ORG=$(gh repo view --json owner -q .owner.login); REPO=policynet-azure

APP_ID=$(az ad app create --display-name pnet-oidc-app --query appId -o tsv)
az ad sp create --id $APP_ID
SP_OID=$(az ad sp show --id $APP_ID --query id -o tsv)
SUB_ID=$(az account show --query id -o tsv); TENANT_ID=$(az account show --query tenantId -o tsv)
az role assignment create --assignee-object-id $SP_OID --assignee-principal-type ServicePrincipal --role Contributor --scope /subscriptions/$SUB_ID

az ad app federated-credential create --id $APP_ID --parameters "{\"name\":\"pnet-main\",\"issuer\":\"https://token.actions.githubusercontent.com\",\"subject\":\"repo:$ORG/$REPO:ref:refs/heads/main\",\"audiences\":[\"api://AzureADTokenExchange\"]}"
az ad app federated-credential create --id $APP_ID --parameters "{\"name\":\"pnet-env-production\",\"issuer\":\"https://token.actions.githubusercontent.com\",\"subject\":\"repo:$ORG/$REPO:environment:production\",\"audiences\":[\"api://AzureADTokenExchange\"]}"
az ad app federated-credential create --id $APP_ID --parameters "{\"name\":\"pnet-pr\",\"issuer\":\"https://token.actions.githubusercontent.com\",\"subject\":\"repo:$ORG/$REPO:pull_request\",\"audiences\":[\"api://AzureADTokenExchange\"]}"

gh variable set AZURE_CLIENT_ID --body "$APP_ID"
gh variable set AZURE_TENANT_ID --body "$TENANT_ID"
gh variable set AZURE_SUBSCRIPTION_ID --body "$SUB_ID"
```
Then on github.com: repo Settings > Environments > New environment > name `production` > tick Required reviewers > add yourself > Save.

If pull-request runs later fail with `AADSTS70021`, recreate the PR credential using the numeric ID form that worked in your earlier OIDC projects (`gh api repos/$ORG/$REPO --jq '.owner.id, .id'`).

Test the login: GitHub > Actions > hello > Run workflow. It should go green and print your subscription.
Then Actions > apply runs on the push from step 7: open the run > Review deployments > tick production > Approve. The `test` job should print 6 PASS.

## 9. Break it on purpose (best part of the demo)
In `envs/dev/nsg.tf`, inside `module "nsg_db"` rules, add above `deny-all`:
```hcl
    allow-web-5432 = {
      priority    = 110
      access      = "Allow"
      ports       = ["5432"]
      src_asg_ids = [azurerm_application_security_group.tier["web"].id]
      dst_asg_ids = [azurerm_application_security_group.tier["db"].id]
    }
```
Push it, approve the apply run: the test job fails on row 4 (red run, screenshot it). Remove the rule, push again: green run, screenshot it.

## 10. STAGE 5: flow logs
```bash
mv envs/dev/observability.tf.stage5 envs/dev/observability.tf
cd envs/dev && terraform init && terraform apply && cd ../..
bash tests/run-matrix.sh
```
Wait 10 to 30 minutes. Azure portal > Log Analytics workspaces > pnet-law > Logs, then run:
```
NTANetAnalytics
| where TimeGenerated > ago(1h) and FlowStatus == "Denied"
| summarize flows = count() by SrcIp, DestIp, DestPort
```
Screenshot the denied web -> db flow.

Policy check: in `.github/workflows/pr-plan.yml`, remove the leading `# ` from the last four commented lines (the conftest step), push on a branch, and open a PR.

## 11. Finish
Draw the diagram (draw.io) into `docs/`, replace README.md with your write-up, record a 2-minute demo.
Then GitHub > Actions > destroy > Run workflow > approve. Only `pnet-state-rg` should remain.

## If something fails
Copy the exact error message and send it to me.
