defmodule CronParser do
  def next_run_time(cron_string, from \\ DateTime.utc_now()) do
    # Parse the cron string (format: "minute hour day_of_month month day_of_week")
    [minute, hour, day_of_month, month, day_of_week] = String.split(cron_string, " ")

    # Start with the current time and find the next matching time
    candidate = from |> DateTime.truncate(:second) |> Map.put(:second, 0)

    # Add 1 minute to start checking from the next minute
    candidate = DateTime.add(candidate, 60, :second)

    find_next_match(candidate, {
      parse_field(minute, 0..59),
      parse_field(hour, 0..23),
      parse_field(day_of_month, 1..31),
      parse_field(month, 1..12),
      parse_field(day_of_week, 0..6)
    })
  end

  defp find_next_match(datetime, {minutes, hours, days, months, weekdays}) do
    # Check if current datetime matches all cron fields
    if matches_cron?(datetime, {minutes, hours, days, months, weekdays}) do
      datetime
    else
      # If not, try the next minute
      find_next_match(
        DateTime.add(datetime, 60, :second),
        {minutes, hours, days, months, weekdays}
      )
    end
  end

  defp matches_cron?(datetime, {minutes, hours, days, months, weekdays}) do
    # Extract datetime components
    minute = datetime.minute
    hour = datetime.hour
    day = datetime.day
    month = datetime.month
    # Convert day of week (Elixir uses 1-7 where 1 is Monday)
    # But cron typically uses 0-6 where 0 is Sunday
    day_of_week =
      rem(Calendar.ISO.day_of_week(datetime.year, datetime.month, datetime.day) + 5, 7)

    Enum.member?(minutes, minute) and
      Enum.member?(hours, hour) and
      Enum.member?(days, day) and
      Enum.member?(months, month) and
      Enum.member?(weekdays, day_of_week)
  end

  defp parse_field("*", range), do: Enum.to_list(range)

  defp parse_field(field, range) do
    # Handle simple numbers
    if Regex.match?(~r/^\d+$/, field) do
      [String.to_integer(field)]
    else
      # This is a simplified implementation - a real one would handle ranges (1-5),
      # steps (*/5), lists (1,3,5), etc.
      Enum.to_list(range)
    end
  end
end
