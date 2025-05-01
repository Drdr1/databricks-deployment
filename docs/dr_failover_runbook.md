# Disaster Recovery Failover Runbook

## Overview
This runbook provides step-by-step instructions for failing over from the primary West US Databricks environment to the DR environment in East US 2 during a disaster event.

## Prerequisites
- Azure CLI installed and configured
- Terraform installed (version 1.0.0+)
- Access to Azure subscription
- Access to Databricks workspaces
- DR team contact information

## DR Team Contacts

| Role | Name | Contact |
|------|------|---------|
| DR Coordinator | [Name] | [Phone/Email] |
| Infrastructure Lead | [Name] | [Phone/Email] |
| Databricks Admin | [Name] | [Phone/Email] |
| Application Owner | [Name] | [Phone/Email] |
| Communications Lead | [Name] | [Phone/Email] |

## Disaster Declaration Criteria
A disaster should be declared if any of the following conditions are met:
- Primary Databricks workspace is unavailable for >30 minutes
- Azure West US region is experiencing a major outage
- Data corruption has occurred in the primary environment

## Failover Procedure

### Step 1: Assess the Situation
1. Confirm that a disaster has occurred based on the criteria above
2. Notify the DR Coordinator
3. DR Coordinator assembles the DR team
4. Determine if failover is necessary

### Step 2: Activate DR Environment

```bash
# Navigate to Terraform directory
cd /path/to/terraform

# Initialize Terraform (if needed)
terraform init

# Apply DR configuration
terraform apply -var-file=environments/east.tfvars
```

### Step 3: Verify DR Environment Readiness

1. Verify Databricks workspace is accessible:
   ```
   https://databricks-dr.azuredatabricks.net
   ```

2. Verify clusters are running:
   - Inference Cluster
   - Monitoring Cluster

3. Verify SQL warehouses are available:
   - Dashboard SQL Warehouse
   - Inference SQL Warehouse

4. Verify data availability:
   ```sql
   -- Run in SQL warehouse
   SELECT COUNT(*) FROM inference_db.predictions;
   ```

5. Verify jobs are configured:
   - Monitoring Job
   - Dashboard Jobs

### Step 4: Update DNS and Access Points

1. Update DNS CNAME records to point to DR environment:
   ```
   databricks.company.com → databricks-dr.azuredatabricks.net
   ```

2. Update application connection strings:
   - Update any applications that connect to Databricks
   - Update API endpoints in dependent systems

### Step 5: Notify Stakeholders

1. Send internal notification:
   - Use emergency Slack channel
   - Send email to distribution list
   - Update status page

2. Send external notification (if applicable):
   - Use corporate communications approved template
   - Update customer-facing status page

### Step 6: Monitor DR Environment

1. Monitor cluster performance
2. Monitor job execution
3. Monitor data consistency
4. Address any issues that arise

## Failback Procedure

Once the primary region is available again, follow these steps to failback:

### Step 1: Assess Primary Region Readiness
1. Verify Azure West US region is stable
2. Verify primary Databricks workspace is accessible

### Step 2: Sync Data Back to Primary
1. Run data sync job from DR to primary:
   ```bash
   # Run notebook with reversed parameters
   databricks jobs run-now --job-id [DR-to-Primary-Sync-Job-ID]
   ```

2. Verify data consistency in primary environment

### Step 3: Reactivate Primary Environment
```bash
# Apply primary configuration
terraform apply -var-file=environments/west.tfvars
```

### Step 4: Update DNS and Access Points
1. Update DNS CNAME records to point back to primary:
   ```
   databricks.company.com → adb-515194348934202.2.azuredatabricks.net
   ```

2. Update application connection strings to point back to primary

### Step 5: Notify Stakeholders
1. Send internal notification about failback
2. Send external notification (if applicable)

### Step 6: Deactivate DR Environment (Optional)
If cost savings are required, scale down the DR environment:
```bash
# Scale down DR environment
terraform apply -var-file=environments/east-minimal.tfvars
```

## Post-Incident Activities

1. Conduct post-incident review
2. Document lessons learned
3. Update DR plan based on findings
4. Schedule next DR drill

## Appendix A: Resource IDs

| Resource | Production ID | DR ID |
|----------|--------------|-------|
| Workspace | `/subscriptions/955faad9-ebe9-4a85-9974-acae429ae877/resourceGroups/rg-databricks-dev/providers/Microsoft.Databricks/workspaces/databricks-dev` | `/subscriptions/955faad9-ebe9-4a85-9974-acae429ae877/resourceGroups/rg-databricks-dr/providers/Microsoft.Databricks/workspaces/databricks-dr` |
| Inference Cluster | `0501-195002-vd8hdcaj` | [To be created] |
| Monitoring Cluster | `0501-195002-koxqj00m` | [To be created] |
| Dashboard SQL Warehouse | `33dd1e771b484207` | [To be created] |
| Inference SQL Warehouse | `902b790a0d84fdd1` | [To be created] |