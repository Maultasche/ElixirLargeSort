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

  def integer_count(input_file) do
    @integer_file.integer_file_stream(input_file)
    |> @integer_file.integer_count()
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
end
