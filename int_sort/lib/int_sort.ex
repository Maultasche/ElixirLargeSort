defmodule IntSort do
  @moduledoc """
  Contains functionality for sorting and chunking integers as well as merging the
  chunk files
  """

  @integer_file Application.get_env(:int_sort, :integer_file)

  # @doc """
  # Chunks an integer file and writes the sorted chunks to chunk files

  # ## Parameters

  # - input_file: the path to the file to be read
  # - output_dir: the path to the directory where the output files are to written
  # - chunk_size: the size of the chunks to be created
  # - gen: the generation number to be used for the chunk files
  # ## Returns

  # :ok
  # """
  # def create_chunk_files(input_file, output_dir, chunk_size, gen) do
  #   #Create a stream pipeline that reads in integers from the input stream,
  #   #chunks them, sorts them, and then writes the chunks to files
  #   @integer_file.create_integer_file_stream(input_file)
  #     |> @integer_file.read_stream()
  #     |> Chunk.create_chunks(chunk_size)
  #     |> Chunk.sort_chunks()
  #     |> Chunk.write_chunks_to_separate_streams(gen, )

  # end

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
end
