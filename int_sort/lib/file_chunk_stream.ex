defmodule FileChunkStream do
  @doc """
  Creates a stream that can be used to read from or write to a chunk file

  ## Parameters

  - gen: The merge generation that this chunk file represents
  - num: The chunk number in the current generation
  - chunk_file_name: A function that converts the generation and chunk number
    to a chunk file name
  - output_path: The path to the directory in which the chunk file is located

  ## Returns

  A stream for the chunk file
  """
  # @spec create_file_chunk_stream(non_neg_integer(), non_neg_integer(), (non_neg_integer(), non_neg_integer() -> String.t()), String.t()) :: Enum.t()
  # def create_file_chunk_stream(gen, num, chunk_file_name, output_path) do

  # end
end
