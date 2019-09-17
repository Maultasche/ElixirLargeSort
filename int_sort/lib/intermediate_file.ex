defmodule IntSort.IntermediateFile do
  @moduledoc """
  Contains functionality for working with intermediate files
  """

  @integer_file Application.get_env(:int_sort, :integer_file)

  @doc """
  Creates a stream that can be used to read from or write to an intermediate file

  ## Parameters

  - gen: The merge generation that this intermediate file represents
  - num: The file number in the current generation
  - create_file_name: A function that converts the generation and file number
    to an intermediate file name
  - output_path: The path to the directory in which the intermediate file is located

  ## Returns

  A stream for the intermediate file
  """
  @spec intermediate_file_stream(
          non_neg_integer(),
          non_neg_integer(),
          (non_neg_integer(), non_neg_integer() -> String.t()),
          String.t()
        ) :: Enum.t()
  def intermediate_file_stream(gen, num, create_file_name, output_path) do
    # Create a file name for the intermediate file
    file_name = create_file_name.(gen, num)

    # Combine the file name with the output directory to create a file path
    intermediate_file_path = Path.join(output_path, file_name)

    # Create a stream for that file path and return it
    @integer_file.integer_file_stream(intermediate_file_path)
  end

  # @doc """
  # Takes in a stream of file names, merges those files in groups, and returns
  # a stream that emits the file names of the merged files

  # ## Parameters

  # - file_stream: a stream that emits intermediate file names
  # - group_size: the number of files in a merge group.
  # - gen: the generation number that this merge represents
  # - total_gen: the total number of generations needed to merge all the files
  # - output_path: a directory path where the resulting merged files will be written
  # """
  # @spec merge_files(Enum.t(), pos_integer(), non_neg_integer(), non_neg_integer(), String.t()) :: Enum.t()
  # def merge_files(file_stream, _, gen, total_gen, _) when gen > total_gen do
  #   # When we've set up all the merges
  #   file_stream
  # end
  # def merge_files(file_stream, group_size, gen, total_gen, output_path) do
  #   file_stream
  #   # Create a group of files to be merged
  #   |> create_file_group(group_size)
  #   # Merge each group and emit the name of the file that resulted from the merge
  #   |> Stream.map(fn {file_group, num} -> merge_file_group(file_group, num, gen, output_path) end)
  #   # Setup the next round of merges by recursively calling this function
  #   |> merge_files(group_size, gen + 1, total_gen, output_path)
  # end

  @doc """
  Creates a stream of file groups for the purposes of merging.

  Files get merged in groups of N files at a time to prevent excessive resource
  usage when merging large numbers of files.

  ## Parameters

  - file_elements: An enumerable containing file elements, where each element represents
  a file. An element can be a file name or something else that represents a file,
  like an I/O device
  - group_size: The size of the file groups that are to be created

  ## Returns

  A stream of file element chunks in a group, where each group has group_size
  elements in the group. The last group may be smaller than group_size if the
  number of file elements is not evenly divisible by group_size.
  """
  @spec create_file_groups(Enum.t(), pos_integer()) :: Enum.t()
  def create_file_groups(file_elements, group_size) do
    file_elements
    # Put the intermediate files into groups
    |> Stream.chunk_every(group_size)
    # Associate each group with a group number
    |> Stream.with_index(1)
  end
end
