"""
Simple WAL Plugin Example

This plugin processes data as it's written to the database.
Triggered on WAL flush (approximately every second).

Usage:
  influxdb3 create trigger \\
    --trigger-spec "table:metrics" \\
    --path "./simple-wal-plugin.py" \\
    --upload \\
    --database mydb \\
    --token $INFLUXDB_TOKEN \\
    wal_processor
"""

def process_writes(influxdb3_local, table_batches, args=None):
    """
    Process incoming write batches.

    Args:
        influxdb3_local: API for interacting with InfluxDB
        table_batches: List of batches containing written data
        args: Optional arguments from trigger configuration
    """
    from influxdb3_plugin_types import LineBuilder

    for table_batch in table_batches:
        table_name = table_batch["table_name"]
        rows = table_batch["rows"]

        influxdb3_local.info(f"Processing {len(rows)} rows from {table_name}")

        # Example: Create derived metrics
        for row in rows:
            # Access fields from the row
            if "temperature" in row and "humidity" in row:
                temp = row["temperature"]
                humidity = row["humidity"]

                # Calculate heat index
                heat_index = calculate_heat_index(temp, humidity)

                # Write derived metric back to database
                line = LineBuilder("derived_metrics")
                line.tag("source_table", table_name)
                line.float64_field("heat_index", heat_index)
                line.float64_field("temperature", temp)
                line.float64_field("humidity", humidity)
                line.timestamp(row["time"])

                influxdb3_local.write(line)

        influxdb3_local.info(f"Completed processing {table_name}")


def calculate_heat_index(temp, humidity):
    """
    Simple heat index calculation.

    Args:
        temp: Temperature in Celsius
        humidity: Relative humidity (0-100)

    Returns:
        Heat index value
    """
    # Convert to Fahrenheit for calculation
    temp_f = (temp * 9/5) + 32

    # Simplified heat index formula
    hi = 0.5 * (temp_f + 61.0 + ((temp_f - 68.0) * 1.2) + (humidity * 0.094))

    # Convert back to Celsius
    return (hi - 32) * 5/9
