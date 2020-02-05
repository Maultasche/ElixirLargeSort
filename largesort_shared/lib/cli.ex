defmodule LargeSort.Shared.CLI do
  @moduledoc """
  Contains CLI functionality that can be reused in multiple projects
  """

  @doc """
  Measures how long it takes for a function to complete and returns the amount
  # of time in milliseconds

  ## Parameters

  - function: The function to be run and measured

  ## Return

  The number of milliseconds it takes for the function to be completed
  """
  #
  @spec measure(function()) :: non_neg_integer()
  def measure(function) do
    function
    |> :timer.tc()
    |> elem(0)
    |> Kernel.div(1_000)
  end

  @doc """
  Returns a text description of the a timespan

  ## Parameters

  - num_ms: The number of milliseconds in the timespan

  ## Returns

  A text description containing a description of the hours, minutes, seconds,
  and milliseconds (the time units) that ellapsed, but showing only the two largest
  non-zero time units. If only one of the time units is non-zero, then only that
  time unit will be shown. If 0 milliseconds have ellapsed, then the string will
  simply be "0ms".
  """
  #
  @spec ellapsed_time_description(non_neg_integer()) :: String.t()
  def ellapsed_time_description(0), do: "0ms"

  def ellapsed_time_description(num_ms) do
    # The number of time units (hours, minutes, seconds, ms) are stored in a list
    # that is built up and the remaining milliseconds are passed to the next function
    # until we've built up a list of time units. We have to reverse the time units
    # at the end because they've been in reverse order
    {time_units, _} =
      {[], num_ms}
      |> hours_ms()
      |> minutes_ms()
      |> seconds_ms()
      |> milliseconds_ms()

    # Take the first two non-zero time units and assign them a unit type number
    time_units =
      time_units
      |> Enum.reverse()
      |> Enum.with_index(1)
      |> Enum.filter(fn {unit_count, _} -> unit_count > 0 end)
      |> Enum.take(2)

    # Take the time units and unit type numbers and convert them into a description string
    time_units
    |> Enum.map(&time_description/1)
    |> Enum.join(" ")
  end

  # Keeps track of the current time units
  @type time_unit_list() :: list(non_neg_integer)

  # Keeps track of the current time units and the remaining milliseconds
  @type time_units_remaining() :: {time_unit_list(), non_neg_integer()}

  # Extracts the number of milliseconds that will go evenly into a unit of time and returns number
  # of time units and the remainder of milliseconds that did not fit evenly into a time unit
  @spec unit_ms(time_units_remaining(), non_neg_integer()) :: time_units_remaining()
  defp unit_ms({units, num_ms}, ms_in_unit) do
    current_units = div(num_ms, ms_in_unit)
    remainder = rem(num_ms, ms_in_unit)

    {[current_units | units], remainder}
  end

  @ms_in_hour 3_600_000
  @ms_in_minute 60_000
  @ms_in_second 1000
  @ms_in_ms 1

  # Calculates the number of milliseconds in an hour and returns that along with the remaining
  # milliseconds
  @spec hours_ms(time_units_remaining()) :: time_units_remaining()
  defp hours_ms(time_units), do: unit_ms(time_units, @ms_in_hour)

  # Calculates the number of milliseconds in a minute and returns that along with the remaining
  # milliseconds
  @spec minutes_ms(time_units_remaining()) :: time_units_remaining()
  defp minutes_ms(time_units), do: unit_ms(time_units, @ms_in_minute)

  # Calculates the number of milliseconds in a second and returns that along with the remaining
  # milliseconds
  @spec seconds_ms(time_units_remaining()) :: time_units_remaining()
  defp seconds_ms(time_units), do: unit_ms(time_units, @ms_in_second)

  # Calculates the number of milliseconds in a millisecond and returns that along with the remaining
  # milliseconds
  @spec milliseconds_ms(time_units_remaining()) :: time_units_remaining()
  defp milliseconds_ms(time_units), do: unit_ms(time_units, @ms_in_ms)

  # Takes a time count count and a time unit type number and converts that into a time description
  @spec time_description({non_neg_integer, pos_integer}) :: String.t()
  defp time_description({unit_count, 1}), do: hours_description(unit_count)
  defp time_description({unit_count, 2}), do: minutes_description(unit_count)
  defp time_description({unit_count, 3}), do: seconds_description(unit_count)
  defp time_description({unit_count, 4}), do: ms_description(unit_count)

  # Produces a text description of the number of hours
  @spec hours_description(time_unit_list()) :: String.t()
  defp hours_description(num_hours) do
    "#{num_hours}h"
  end

  # Produces a text description of the number of minutes
  @spec minutes_description(non_neg_integer()) :: String.t()
  defp minutes_description(num_minutes) do
    "#{num_minutes}m"
  end

  # Produces a text description of the number of seconds
  @spec seconds_description(non_neg_integer()) :: String.t()
  defp seconds_description(num_seconds) do
    "#{num_seconds}s"
  end

  # Produces a text description of the number of milliseconds
  @spec ms_description(non_neg_integer()) :: String.t()
  defp ms_description(num_ms) do
    "#{num_ms}ms"
  end
end
