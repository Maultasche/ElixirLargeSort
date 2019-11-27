defmodule IntSort do
  @moduledoc """
  Contains functionality for sorting and chunking integers as well as merging the
  chunk files
  """
  alias IntSort.Chunk
  alias IntSort.IntermediateFile

  @integer_file Application.get_env(:int_sort, :integer_file)

  @doc """
  Chunks an integer file and writes the sorted chunks to chunk files

  ## Parameters

  - input_file: the path to the file to be read
  - output_dir: the path to the directory where the output files are to written
  - chunk_size: the size of the chunks to be created
  - gen: the generation number to be used for the chunk files

  ## Returns

  A stream that emits chunk file names
  """
  @spec create_chunk_files(String.t(), String.t(), pos_integer(), non_neg_integer()) :: Enum.t()
  def create_chunk_files(input_file, output_dir, chunk_size, gen) do
    # Create a stream pipeline that reads in integers from the input stream,
    # chunks them, sorts them, and then writes the chunks to files
    @integer_file.integer_file_stream(input_file)
    |> @integer_file.read_stream()
    |> Chunk.create_chunks(chunk_size)
    |> Chunk.sort_chunks()
    |> Chunk.write_chunks_to_separate_streams(gen, fn gen, chunk_num ->
      IntermediateFile.intermediate_file_stream(gen, chunk_num, &gen_file_name/2, output_dir)
    end)
    |> Stream.with_index(1)
    |> Stream.map(fn {_, chunk_num} -> gen_file_name(gen, chunk_num) end)
  end

  @doc """
  Counts the number of integers in an input file

  This function assumes that the input file is a valid integer file.
  ## Parameters

  - input_file: The input file whose integers are to be counted

  ## Returns

  The number of integers found in the file
  """
  @spec integer_count(String.t()) :: non_neg_integer()
  def integer_count(input_file) do
    @integer_file.integer_file_stream(input_file)
    |> @integer_file.integer_count()
  end

  @doc """
  Does a single round of merges on a collection of intermediate files.

  This function only does a single round, merging groups of N intermediate
  files together, where N is defined by the `merge_count` parameter. The merge
  will result in ceil(N/merge_count) files containing the merged integers.
  This function will likely be called multiple times until it results in
  a single file.

  ## Parameters

  - files: A collection of file names of the intermediate files to be merged
  - merge_count: The number of files to be merged at once
  - merge_file_name: A function that takes in the merge group number and
    returns the file name to use for the merge file
  - integer_merged: A function that is called when an integer is merged. This
    function takes a single parameter, which is the number of integers that have
    been merged during this round of merges. This function can be used to display
    or measure merge progress

  ## Returns

  A stream that emits the file names containing the merged integers from this
  round
  """
  @spec merge_intermediate_files(
          Enum.t(),
          pos_integer(),
          (non_neg_integer() -> String.t()),
          (non_neg_integer() -> :ok)
        ) :: Enum.t()
  def merge_intermediate_files(
        files,
        merge_count,
        merge_file_name,
        integer_merged \\ fn _ -> :ok end
      ) do
    files
    # Convert the files to file groups
    |> IntermediateFile.create_file_groups(merge_count)
    # Merge each file group
    |> Stream.scan({[], 0}, fn {file_group, group_num}, {_, total_count} ->
      # Get the file name for this group's merged file
      group_file_name = merge_file_name.(group_num + 1)

      # Create the function that is called every time an integer in the file
      # group is merged
      group_integer_merged = fn count ->
        # Transform the internal group count to an overall integer count
        integer_merged.(total_count + count)
      end

      # Call the function to do the merging for this file group and count how many
      # integers are being merged, which also has the effect of causing the stream
      # processing to start running.
      merge_count = merge_file_group(file_group, group_file_name, group_integer_merged)
      |> Enum.count()

      # Return the file name and the cumulative number of merged integers
      {group_file_name, total_count + merge_count}
    end)
    # We now have a stream of merge file names and integer counts. Strip out the integer counts.
    |> Stream.map(fn {group_file_name, _} -> group_file_name end)
  end

  @doc """
  Creates an intermediate file name based on a generation and chunk number

  ## Parameters

  - gen: the generation the file is associated with
  - num: the chunk number assocatied with the file

  ## Returns

  A file name containing the gen and chunk number
  """
  @spec gen_file_name(non_neg_integer(), non_neg_integer()) :: String.t()
  def gen_file_name(gen, num) do
    "gen#{gen}-#{num}.txt"
  end

  # Merges a group of integer files into a single integer file. Returns a tuple with the stream
  # that emits the integers being merged
  @spec merge_file_group(Enum.t(), String.t(), (non_neg_integer() -> :ok)) :: Enum.t()
  defp merge_file_group(file_group, merged_file, integer_merged) do
    # Open each file in the group as a file device
    file_devices =
      Enum.map(file_group, fn file ->
        @integer_file.read_device!(file)
      end)

    # Create a merge stream to merge the file devices
    merge_stream = IntermediateFile.merge_stream(file_devices, &@integer_file.close_device/1)

    # Open a stream for the output file
    output_stream = @integer_file.integer_file_stream(merged_file)

    # Write the merged integers from the merge stream to the output file
    @integer_file.write_integers_to_stream(merge_stream, output_stream)
    |> Stream.with_index(1)
    |> Stream.each(fn {_, count} -> integer_merged.(count) end)
  end
end
