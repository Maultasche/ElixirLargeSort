defmodule IntSort.CLI do
  @moduledoc """
  Handles the command line and options parsing logic
  """

  alias IntSort.CLI.Args
  alias IntSort.CLI.Options
  alias IntSort.Chunk

  @type parsed_args() :: {keyword(), list(String.t()), list()}
  @type output_func() :: (IO.chardata() | String.Chars.t() -> :ok)

  # The number of times the progress bar will update between 0% and 100%
  @progress_updates 1000

  # The generation number for the chunking process
  @chunk_gen 1

  # The maximum number of intermediate files to be merged at once
  @merge_files 10

  # This is the main entry point to the application
  def main(argv) do
    argv
    |> Args.parse_args()
    |> process()
  end

  # Starts the application processing based on the parsing of the arguments
  defp process({:ok, :help}) do
    output_usage_info(&IO.puts/1)

    System.halt(0)
  end

  defp process({:error, messages}) do
    # Retrieve the function to use for output
    output = &IO.puts/1

    Enum.each(messages, output)

    output.("")

    output_usage_info(output)
  end

  defp process({:ok, options}) do
    # Retrieve the function to use for output
    output = output_func(options)

    # Calculate the number of integers and chunks in the input file
    display_integer_counting_message(output)

    {num_integers, num_chunks} =
      integer_chunk_counts(options.input_file, options.chunk_size)
      |> display_integer_counting_result(output)

    # Create the chunk files
    chunk_files = create_chunks(options, num_chunks, output, options.silent) |> Enum.to_list()

    output.("#{Enum.count(chunk_files)} Gen 1 intermediate files were generated")

    # Merge the chunk files
    output.("Merging Gen 1 intermediate files")

    merge_file =
      merge_chunks(options, chunk_files, num_integers, Path.dirname(options.output_file), output)

    # Move the final merge file to the file specified in the parameters
    File.rename!(merge_file, options.output_file)
  end

  # Returns the function used for output
  @spec output_func(Options.t()) :: output_func()
  defp output_func(%Options{silent: true}) do
    fn _ -> :ok end
  end

  defp output_func(_) do
    fn output -> IO.puts(output) end
  end

  # Prints usage information
  @spec output_usage_info(output_func()) :: :ok
  defp output_usage_info(output) do
    output.("""
    usage: int_sort [--help] --input-file <file> --chunk-size <integer> [--keep-intermediate] [--silent] <file>

    example: int_sort --input-file "data/random_integers.txt" --chunk-size 1000 "sorted_integers.txt"
    """)
  end

  @spec create_chunks(Options.t(), non_neg_integer(), output_func(), boolean()) :: Enum.t()
  defp create_chunks(options, num_chunks, output, silent) do
    output.("Creating Chunk Files")

    # Calculate the progress update frequency for chunk creation
    update_frequency = progress_update_frequency(num_chunks, @progress_updates)

    # Create the chunk files
    IntSort.create_chunk_files(
      options.input_file,
      Path.dirname(options.output_file),
      options.chunk_size,
      @chunk_gen
    )
    # Number each chunk
    |> Stream.with_index(1)
    # Update the progress bar after each chunk has been processed
    |> Stream.each(fn {_, chunk_num} ->
      update_progress_bar(chunk_num, num_chunks, update_frequency, silent)
    end)
    # Transform the stream back into chunk file names
    |> Stream.map(fn {chunk_file, _} -> chunk_file end)
  end

  # Merges the chunk files and returns the path to the final merged file
  @spec merge_chunks(Options.t(), Enum.t(), non_neg_integer(), String.t(), output_func()) ::
          String.t()
  defp merge_chunks(_, [], _, _, output) do
    output.("There were no integers to merge. Creating an empty output file.")

    empty_file = IntSort.gen_file_name(1, 1)

    File.write!(empty_file, "")

    empty_file
  end

  defp merge_chunks(options, chunk_files, num_integers, output_dir, output) do
    # Calculate the progress update frequency for integer merging
    update_frequency = progress_update_frequency(num_integers, @progress_updates)

    # Perform the merge
    gen_file_name = fn gen, count -> Path.join(output_dir, IntSort.gen_file_name(gen, count)) end

    merge_status = fn _, count ->
      file_merge_status(count, num_integers, update_frequency, options.silent)
    end

    merge_gen_completed = fn gen, file_count -> merge_gen_completed(gen, file_count, output) end
    remove_files = remove_files_func(not options.keep_intermediate)

    merged_file =
      IntSort.total_merge(
        chunk_files,
        @merge_files,
        gen_file_name,
        &IntSort.merge_intermediate_files/4,
        remove_files,
        merge_status,
        merge_gen_completed
      )

    merged_file
  end

  # Returns a function that removes a file or does nothing, depending on whether we want
  # to remove files
  @spec remove_files_func(boolean()) :: (Enum.t() -> :ok)
  defp remove_files_func(true) do
    fn files -> Enum.each(files, &File.rm!/1) end
  end

  defp remove_files_func(false) do
    fn _ -> :ok end
  end

  # Outputs the current status of the ongoing file merge
  @spec file_merge_status(non_neg_integer(), non_neg_integer(), non_neg_integer(), boolean()) ::
          :ok
  defp file_merge_status(count, total_count, update_frequency, silent) do
    update_progress_bar(count, total_count, update_frequency, silent)
  end

  # Outputs to the screen when a merge generation is completed
  @spec merge_gen_completed(non_neg_integer(), non_neg_integer(), output_func()) :: :ok
  defp merge_gen_completed(gen, file_count, output) when file_count > 1 do
    output.("Gen #{gen - 1} files were merged into #{file_count} Gen #{gen} files")
  end

  defp merge_gen_completed(gen, _, output) do
    output.("Gen #{gen - 1} files were merged into a single output file")
  end

  defp integer_chunk_counts(input_file, chunk_size) do
    integer_count = IntSort.integer_count(input_file)
    chunk_count = Chunk.num_chunks(integer_count, chunk_size)

    {integer_count, chunk_count}
  end

  @spec display_integer_counting_message(output_func()) :: :ok
  defp display_integer_counting_message(output) do
    output.("Determining the number of integers and chunks in the input file...")
  end

  @spec display_integer_counting_result({non_neg_integer(), non_neg_integer()}, output_func()) ::
          {non_neg_integer(), non_neg_integer()}
  defp display_integer_counting_result(data = {integers, chunks}, output) do
    output.("Number of Integers: #{integers}")
    output.("Number of Chunks: #{chunks}")

    data
  end

  # Calculates the progress update frequency (the number of items that pass between
  # updates) based on the total number of items and the number of updates that
  # are to be made to the progress bar
  @spec progress_update_frequency(non_neg_integer(), non_neg_integer()) :: non_neg_integer()
  defp progress_update_frequency(total_count, num_updates) do
    ceil(total_count / num_updates)
  end

  # Updates the current progress bar
  # This clause updates the progress bar occasionally when a larger number of items
  # are being processed so that the program doesn't spend all its time on progress
  # bar updates
  @spec update_progress_bar(non_neg_integer(), non_neg_integer(), non_neg_integer(), boolean()) ::
          :ok
  defp update_progress_bar(current_count, total_count, update_frequency, false)
       when rem(current_count, update_frequency) == 0 do
    ProgressBar.render(current_count, total_count, progress_bar_format())
  end

  # Updates the progress bar when all the items have finished being processed.
  # Otherwise, it won't show at 100% unless the total happens to be evenly
  # divisible by the update frequency
  defp update_progress_bar(current_count, total_count, _, false)
       when current_count == total_count do
    ProgressBar.render(current_count, total_count, progress_bar_format())
  end

  # If the current item count does not match the update frequency or if the
  # silent option is enabled, don't update the progress bar
  defp update_progress_bar(_, _, _, _), do: :ok

  # Returns the format of the progress bar
  defp progress_bar_format() do
    [
      suffix: :count
    ]
  end

  @doc """
  Retrieves the number of files merged at the same time
  """
  def merge_files(), do: @merge_files
end
