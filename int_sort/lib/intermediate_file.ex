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
end
