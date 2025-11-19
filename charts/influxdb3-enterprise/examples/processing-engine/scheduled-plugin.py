"""
Scheduled Plugin Example

This plugin runs on a schedule to perform periodic data aggregation.

Usage:
  influxdb3 create trigger \\
    --trigger-spec "every:5m" \\
    --path "./scheduled-plugin.py" \\
    --upload \\
    --database mydb \\
    --token $INFLUXDB_TOKEN \\
    aggregator
"""

def process_scheduled_call(influxdb3_local, call_time, args=None):
    """
    Process scheduled execution.

    Args:
        influxdb3_local: API for interacting with InfluxDB
        call_time: Timestamp when this execution was triggered
        args: Optional arguments from trigger configuration
    """
    from influxdb3_plugin_types import LineBuilder
    import datetime

    influxdb3_local.info(f"Running scheduled aggregation at {call_time}")

    # Query recent data (last 5 minutes)
    query = """
        SELECT
            mean(temperature) as avg_temp,
            mean(humidity) as avg_humidity,
            count(*) as sample_count
        FROM metrics
        WHERE time > now() - INTERVAL '5 minutes'
    """

    try:
        results = influxdb3_local.query(query)

        if results and len(results) > 0:
            result = results[0]

            # Write aggregated data
            line = LineBuilder("metrics_5m")
            line.float64_field("avg_temperature", result["avg_temp"])
            line.float64_field("avg_humidity", result["avg_humidity"])
            line.int64_field("sample_count", result["sample_count"])

            influxdb3_local.write(line)

            influxdb3_local.info(
                f"Aggregated {result['sample_count']} samples: "
                f"avg_temp={result['avg_temp']:.2f}, "
                f"avg_humidity={result['avg_humidity']:.2f}"
            )

            # Check for anomalies
            if result["avg_temp"] > 35.0:
                influxdb3_local.warn(
                    f"High temperature detected: {result['avg_temp']:.2f}°C"
                )

            if result["sample_count"] < 50:
                influxdb3_local.warn(
                    f"Low sample count: {result['sample_count']} (expected ~300)"
                )
        else:
            influxdb3_local.warn("No data found for aggregation period")

    except Exception as e:
        influxdb3_local.error(f"Aggregation failed: {str(e)}")
        raise
