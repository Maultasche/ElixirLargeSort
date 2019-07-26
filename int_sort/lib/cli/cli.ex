defmodule IntSort.CLI do
  @moduledoc """
  Handles the command line and options parsing logic
  """

  alias IntSort.CLI.Args
  alias IntSort.CLI.Options

  @type parsed_args() :: {keyword(), list(String.t()), list()}

  # @progress_update_frequency 1000

  # The generation number for the chunking process
  @chunk_gen 1

  # The maximum number of intermediate files to be merged at once
  #@merge_files 10

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
    # Create the chunk files
    create_chunks(options) |> Stream.run()
  end

  # Prints usage information
  defp output_usage_info() do
    IO.puts("""
    usage: int_sort [--help] --input-file <file> --chunk-size <integer> [--keep-intermediate] <file>

    example: int_sort --input-file "data/random_integers.txt" --chunk-size 1000 "sorted_integers.txt"
    """)
  end

  @spec create_chunks(Options.t()) :: Enum.t()
  defp create_chunks(options) do
    IntSort.create_chunk_files(options.input_file, Path.dirname(options.output_file),
      options.chunk_size, @chunk_gen)
    |> Stream.each(fn file_name -> IO.puts "Generated #{file_name}" end)
  end

  # # Updates the progress bar
  # # This clause updates the progress bar occasionally when a larger number of integers
  # # is generated so that the program doesn't spend all its time on progress bar updates
  # defp update_progress_bar(current_integer, total_integers)
  #      when rem(current_integer, @progress_update_frequency) == 0 do
  #   ProgressBar.render(current_integer, total_integers, progress_bar_format())
  # end

  # # Updates the progress bar when all the integers have finished generating.
  # # Otherwise, it won't show at 100% unless the total happens to be evenly
  # # divisible by the update frequency
  # defp update_progress_bar(current_integer, total_integers)
  #      when current_integer == total_integers do
  #   ProgressBar.render(current_integer, total_integers, progress_bar_format())
  # end

  # # If the current integer does not match the update frequency, don't update
  # # the progress bar
  # defp update_progress_bar(_, _), do: :ok

  # # Returns the format of the progress bar
  # defp progress_bar_format() do
  #   [
  #     suffix: :count
  #   ]
  # end
end
