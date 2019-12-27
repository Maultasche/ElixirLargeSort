defmodule IntSort do
  @moduledoc """
  Contains functionality for sorting and chunking integers as well as merging the
  chunk files
  """
  alias IntSort.Chunk
  alias IntSort.IntermediateFile

  @integer_file Application.get_env(:int_sort, :integer_file)

  # The chunk files represent the first generation of merge files so the first files
  # that are merged will be Gen 2
  @initial_merge_gen 2

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
  Takes a collection of intermediate files and performs merges on those files until a single
  file remains

  ## Parameters

  - files: A collection of the paths of files to be merged
  - merge_count: The number of files to merge at once as part of a single merge group. The
    merge count must be at least 2
  - gen_file_name: The function that creates the file path for a gen file, which is an
    intermediate file associated with a particular merge generation and merge file group,
    which will contain the results of the merge. The first parameter is the merge generation
    number and the second parameter is the merge group number.
  - merge_file_gen: The function that performs the entire merge process for each merge
    generation. See the documentation on `IntSort.merge_intermediate_files/4` for details
    regarding what this function received. Ideally, `IntSort.merge_intermediate_files/4` will
    be passed as this parameter, but under other circumstances (such as testing) a different
    function can be passed.
  - remove_files: The function that will remove any intermediate files that are no longer needed.
    This function receives a collection of file paths to be removed.
    If you don't want to remove intermediate files, then pass in a function that does nothing.
  - integer_merged: A function that is called when an integer is merged. This
    function takes two parameters. The first parameter is the merge generation and the second
    parameter is the number of integers merged during that particular generation. This function
    can be used to display or measure merge progress

  ## Returns

  The path of the file containing all the integers merged together
  """
  @spec total_merge(
          Enum.t(),
          pos_integer(),
          (non_neg_integer(), non_neg_integer() -> String.t()),
          (Enum.t(),
           pos_integer(),
           (non_neg_integer() -> String.t()),
           (non_neg_integer() -> :ok) ->
             Enum.t()),
          (Enum.t() -> :ok),
          (non_neg_integer(), non_neg_integer() -> :ok)
        ) :: String.t()
  def total_merge(
        files,
        merge_count,
        gen_file_name,
        merge_file_gen,
        remove_files,
        integer_merged \\ fn _, _ -> :ok end
      ) when merge_count > 1 do
    # Do a recursive merge
    [merged_file] =
      total_merge(
        files,
        Enum.count(files),
        @initial_merge_gen,
        merge_count,
        gen_file_name,
        merge_file_gen,
        remove_files,
        integer_merged
      )

    # Take the remaining merge file and return it
    merged_file
  end

  # The recursive implementation of the total_merge function, which returns the merge files resulting from each merge iteration
  @spec total_merge(
          Enum.t(),
          non_neg_integer(),
          non_neg_integer(),
          pos_integer(),
          (non_neg_integer(), non_neg_integer() -> String.t()),
          (Enum.t(),
           pos_integer(),
           (non_neg_integer() -> String.t()),
           (non_neg_integer() -> :ok) ->
             Enum.t()),
          (Enum.t() -> :ok),
          (non_neg_integer(), non_neg_integer() -> :ok)
        ) :: Enum.t()
  defp total_merge(files, file_count, _, _, _, _, _, _) when file_count <= 1 do
    files
  end

  defp total_merge(
         files,
         _,
         merge_gen,
         merge_count,
         gen_file_name,
         merge_file_gen,
         remove_files,
         integer_merged
       ) do

    # Create the function that creates a merge file name for this generation
    merge_file_name = fn num -> gen_file_name.(merge_gen, num) end

    # Create the callback function that gets called to keep track of merge progress
    gen_integer_merged = fn count -> integer_merged.(merge_gen, count) end

    # Perform the merge for this merge generation
    merged_files = merge_file_gen.(files, merge_count, merge_file_name, gen_integer_merged)

    # Remove any files that were merged
    remove_files.(files)

    # Do a recursive call to merge the next generation of merged files
    total_merge(
      merged_files,
      Enum.count(merged_files),
      merge_gen + 1,
      merge_count,
      gen_file_name,
      merge_file_gen,
      remove_files,
      integer_merged
    )
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
      merge_count =
        merge_file_group(file_group, group_file_name, group_integer_merged)
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
