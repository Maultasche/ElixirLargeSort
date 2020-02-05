defmodule IntGen.CLI do
  @moduledoc """
  Handles the command line and options parsing logic
  """

  alias LargeSort.Shared.CLI
  alias IntGen.CLI.Args

  @type parsed_args() :: {keyword(), list(String.t()), list()}

  # The number of times the progress bar will update between 0% and 100%
  @progress_updates 1000

  # This is the main entry point to the application
  def main(argv) do
    argv
    |> Args.parse_args()
    |> process()
  end

  # Starts the application processing based on the parsing of the arguments
  defp process({:ok, :help}) do
    output_usage_info()

    System.halt(0)
  end

  defp process({:error, messages}) do
    Enum.each(messages, &IO.puts/1)

    IO.puts("")

    output_usage_info()
  end

  defp process({:ok, options}) do
    integer_range = options.lower_bound..options.upper_bound

    # Calculate the progress update frequency
    update_frequency = progress_update_frequency(options.count, @progress_updates)

    # Create the random integer stream
    random_stream = IntGen.random_integer_stream(integer_range)

    # Intercept the integer generation for updating the progress bar
    random_stream =
      random_stream
      # Add an index onto the number being generated
      |> Stream.with_index()
      # Update the progress bar
      |> Stream.each(fn {_, current_index} ->
        update_progress_bar(current_index + 1, options.count, update_frequency)
      end)
      # Transform the integer-index tuple back to an integer
      |> Stream.map(fn {integer, _} -> integer end)

    # Create the integer file using the random integer stream
    time_description = CLI.measure(fn ->
      IntGen.create_integer_file(options.output_file, options.count, random_stream)
    end)
    |> CLI.ellapsed_time_description()

    # Output how much time it took to generate the integers
    output_runtime_description(time_description)
  end

  # Prints usage information
  defp output_usage_info() do
    IO.puts("""
    usage: int_gen --count <count> --lower-bound <lower bound> --upper-bound <upper bound> <file>

    example: int_gen --count 100 --lower-bound -100 --upper-bound 100 "random_integers.txt"
    """)
  end

  # Outputs the runtime description
  defp output_runtime_description(time_description) do
    IO.puts("")
    IO.puts(time_description)
  end

  # Calculates the progress update frequency (the number of items that pass between
  # updates) based on the total number of integers and the number of updates that
  # are to be made to the progress bar
  defp progress_update_frequency(total_integers, num_updates) do
    ceil(total_integers / num_updates)
  end

  # Updates the progress bar
  # This clause updates the progress bar occasionally when a larger number of integers
  # is generated so that the program doesn't spend all its time on progress bar updates
  defp update_progress_bar(current_integer, total_integers, update_frequency)
       when rem(current_integer, update_frequency) == 0 do
    ProgressBar.render(current_integer, total_integers, progress_bar_format())
  end

  # Updates the progress bar when all the integers have finished generating.
  # Otherwise, it won't show at 100% unless the total happens to be evenly
  # divisible by the update frequency
  defp update_progress_bar(current_integer, total_integers, _)
       when current_integer == total_integers do
    ProgressBar.render(current_integer, total_integers, progress_bar_format())
  end

  # If the current integer does not match the update frequency, don't update
  # the progress bar
  defp update_progress_bar(_, _, _), do: :ok

  # Returns the format of the progress bar
  defp progress_bar_format() do
    [
      suffix: :count
    ]
  end
end
