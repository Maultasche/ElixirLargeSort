defmodule IntSort.CLI do
  @moduledoc """
  Handles the command line and options parsing logic
  """

  alias IntSort.CLI.Args
  alias IntSort.CLI.Options
  alias IntSort.Chunk

  @type parsed_args() :: {keyword(), list(String.t()), list()}

  # The number of times the progress bar will update between 0% and 100%
  @progress_updates 1000

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
    # Calculate the number of integers and chunks in the input file
    display_integer_counting_message()

    {num_integers, num_chunks} =
      integer_chunk_counts(options.input_file, options.chunk_size)
      |> display_integer_counting_result()

    # Create the chunk files
    create_chunks(options, num_chunks)
    # Start stream processing
    |> Stream.run()
  end

  # Prints usage information
  defp output_usage_info() do
    IO.puts("""
    usage: int_sort [--help] --input-file <file> --chunk-size <integer> [--keep-intermediate] <file>

    example: int_sort --input-file "data/random_integers.txt" --chunk-size 1000 "sorted_integers.txt"
    """)
  end

  @spec create_chunks(Options.t(), non_neg_integer()) :: Enum.t()
  defp create_chunks(options, num_chunks) do
    IO.puts "Creating Chunk Files"

    # Calculate the progress update frequency for chunk creation
    update_frequency = progress_update_frequency(num_chunks, @progress_updates)

    # Create the chunk files
    IntSort.create_chunk_files(options.input_file, Path.dirname(options.output_file),
      options.chunk_size, @chunk_gen)
    # Number each chunk
    |> Stream.with_index(1)
    # Update the progress bar after each chunk has been processed
    |> Stream.each(fn {_, chunk_num} -> update_progress_bar(chunk_num, num_chunks, update_frequency) end)
    # Transform the stream back into chunk file names
    |> Stream.map(fn {chunk_file, _} -> chunk_file end)
  end

  defp integer_chunk_counts(input_file, chunk_size) do
    integer_count = IntSort.integer_count(input_file)
    chunk_count = Chunk.num_chunks(integer_count, chunk_size)

    {integer_count, chunk_count}
  end

  defp display_integer_counting_message() do
    IO.puts "Determining the number of integers and chunks in the input file..."
  end

  defp display_integer_counting_result(data = {integers, chunks}) do
    IO.puts "Number of Integers: #{integers}"
    IO.puts "Number of Chunks: #{chunks}"

    data
  end

  # Calculates the progress update frequency (the number of items that pass between
  # updates) based on the total number of items and the number of updates that
  # are to be made to the progress bar
  defp progress_update_frequency(total_count, num_updates) do
    ceil(total_count / num_updates)
  end

  # Updates the current progress bar
  # This clause updates the progress bar occasionally when a larger number of items
  # are being processed so that the program doesn't spend all its time on progress
  # bar updates
  defp update_progress_bar(current_count, total_count, update_frequency)
       when rem(current_count, update_frequency) == 0 do
    ProgressBar.render(current_count, total_count, progress_bar_format())
  end

  # Updates the progress bar when all the items have finished being processed.
  # Otherwise, it won't show at 100% unless the total happens to be evenly
  # divisible by the update frequency
  defp update_progress_bar(current_count, total_count, _)
       when current_count == total_count do
    ProgressBar.render(current_count, total_count, progress_bar_format())
  end

  # If the current item count does not match the update frequency, don't update
  # the progress bar
  defp update_progress_bar(_, _, _), do: :ok

  # Returns the format of the progress bar
  defp progress_bar_format() do
    [
      suffix: :count
    ]
  end
end
