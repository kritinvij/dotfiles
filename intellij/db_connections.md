# IntelliJ database connections

Settings read from IntelliJ's data source history. Passwords are not stored here. Create each one as a Global data source so every project sees it.

## Reporting DB (MySQL, read through Teleport)

- Driver: MySQL (`mysql.8`)
- URL: `jdbc:mysql://localhost:33308/` (host `localhost`, port 33308, database field empty)
- User: your database user
- SSL: off, no SSH tunnel
- Password: kept in IntelliJ's secret storage
- Needs a running Teleport proxy: `tsh login --proxy=$TELEPORT_PROXY`, then `tsh proxy app <app> --port 33308`
- Autostart: `dev_setup/teleport_proxy/install.sh <app>`

## ClickHouse (prod, read-only)

- Driver: ClickHouse (`clickhouse`)
- URL: `jdbc:clickhouse://localhost:8125/<database>` (HTTP port 8125)
- User: the read-only user from the secret
- SSL: off
- Password: AWS Secrets Manager, key `clickhouse.prod.reader.password`
- Needs a running SSM tunnel on port 8125 (preview uses 8124)
