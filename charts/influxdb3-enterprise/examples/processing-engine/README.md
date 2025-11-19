# Processing Engine Examples

This directory contains example plugins for InfluxDB 3 Enterprise Processing Engine.

## Overview

The Processing Engine is an embedded Python virtual machine that runs inside InfluxDB 3 Enterprise, allowing you to:

- Process data as it's written (WAL triggers)
- Run code on schedules (cron or interval)
- Create custom HTTP endpoints (request triggers)

## Prerequisites

1. Enable Processing Engine in values.yaml:
   ```yaml
   processingEngine:
     enabled: true
     replicas: 1
   ```

2. Deploy the chart:
   ```bash
   helm upgrade influxdb3-enterprise . -n influxdb3 -f values.yaml
   ```

## Example Plugins

### 1. simple-wal-plugin.py
Processes data as it's written to the database, performing basic transformations.

### 2. scheduled-plugin.py
Runs on a schedule to perform periodic data aggregation.

## Usage

### Upload Plugin

```bash
# Upload plugin file
influxdb3 create trigger \
  --trigger-spec "table:metrics" \
  --path "./simple-wal-plugin.py" \
  --upload \
  --database mydb \
  --token $INFLUXDB_TOKEN \
  my_trigger
```

### Using GitHub Plugins

```bash
# Use official plugin from GitHub
influxdb3 create trigger \
  --trigger-spec "every:1m" \
  --plugin-filename "gh:influxdata/system_metrics/system_metrics.py" \
  --database mydb \
  --token $INFLUXDB_TOKEN \
  system_monitor
```

### List Plugins

```bash
influxdb3 show plugins --token $INFLUXDB_TOKEN
```

## Documentation

- Official Docs: https://docs.influxdata.com/influxdb3/enterprise/plugins/
- Plugin Library: https://github.com/influxdata/influxdb3_plugins
