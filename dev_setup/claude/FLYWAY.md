# Flyway Migration Against ClickHouse

This is a separate flow from `clickhouse_ro_tunnel.sh`. That script is read-only and holds no write or DDL grants.

## Steps

### 1. Get AWS Credentials

Sign in to AWS, go to Coursera > Wls-Enterprise-Analytics-0, and use "access keys" to get temporary credentials, then paste the resulting env vars into the shell.

Or, from the CLI: `aws sso login --profile antics --region us-east-1`.

### 2. Get On Latest Main

```
cd enterprise-summary-application
git switch main && git pull
```

### 3. Start the SSM Tunnel

Preferred method:

```
./clickhouse-ssm-connect.sh
```

Select `prod` or `preview`, pick any instance, and accept the defaults.

Manual fallback:

```
aws ssm start-session --profile antics --target <instance-id> --region us-east-1 \
  --document-name AWS-StartPortForwardingSessionToRemoteHost \
  --parameters '{"host":["<private-ip>"],"portNumber":["8123"],"localPortNumber":["<local-port>"]}'
```

Resolve `<instance-id>` and `<private-ip>` with:

```
aws ec2 describe-instances --filters Name=tag:Name,Values=enterprise-analytics-clickhouse-preview
```

For prod, use the same tag with the `-preview` suffix dropped.

**Ports:** preview uses local port `8123`. The prod write tunnel uses local port `8127`; port `8124` is reserved for the separate read-only tunnel and must not be reused here.

### 4. Run the Migration

In a second shell, with fresh AWS credentials pasted in again:

```
printf '%s\n%s\n' "$CH_USER" "$CH_PASS" | ./scripts/flyway.sh flywayMigrate -PchHost=localhost -PchPort=<tunnel-port> -PchDatabase=eal
```

Credentials live in Secrets Manager:
- Preview: `/java/enterprise-summary-application`
- Prod: `/java/enterprise-summary-application_production`

Try `clickhouse.preview.writer.user` and `.password` (or the prod equivalent) first. If that user hits `ACCESS_DENIED` on `CREATE VIEW` or `DROP VIEW`, switch to `clickhouse.flyway.user` and `clickhouse.flyway.password`, the dedicated migration-runner account, which connects as `flyway_migrator`.

### 5. On Failure

Run `flywayRepair` before retrying `flywayMigrate`. Do not retry `flywayMigrate` directly after a failure without running `flywayRepair` first.

### 6. Rollout Order

Run against preview first. Once preview succeeds, repeat the same migration once against any single prod instance; the other prod instances sync automatically, so the migration does not need to be repeated per instance.

## Verification (Required, Not Optional)

Query `eal.flyway_schema_history WHERE version = '<version>'` on the target cluster and confirm `success = true` before treating the migration as done. Do not treat a migration as done based on the tool's exit status alone.

A successful update to preview's schema history is the go/no-go gate before touching prod: do not run the migration against prod until preview's `flyway_schema_history` row confirms `success = true`.
