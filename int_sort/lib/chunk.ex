defmodule IntSort.Chunk do
  @moduledoc """
  Contains functionality for handling chunk files, which contain chunks
  of sorted integers
  """

  @integer_file Application.get_env(:int_sort, :integer_file)

  @doc """
  Creates a stream that divides the integers in an input stream into chunks

  Note that this function just creates the stream pipeline. It still needs
  to be run with `Stream.run/0` or some other equivalent function.

  ## Parameters

  - input_stream: A stream of integers to be read from
  - chunk_size: The number of integers in a chunk
  - create_chunk_stream: A function that accepts a generation number and a chunk
    number and returns a stream to write the chunk to (fn gen, chunk -> stream end)

  ## Returns

  A stream that emits integer chunks
  """
  @spec create_chunks(Enum.t(), pos_integer()) :: Enum.t()
  def create_chunks(input_stream, chunk_size) do
    Stream.chunk_every(input_stream, chunk_size)
  end

  @doc """
  Creates a stream that emits sorted chunks

  ## Parameters

  - chunk_stream: A stream of chunks to be sorted

  ## Returns

  A stream that emits sorted integer chunks
  """
  @spec sort_chunks(Enum.t()) :: Enum.t()
  def sort_chunks(chunk_stream) do
    Stream.map(chunk_stream, &Enum.sort/1)
  end

  @doc """
  Takes individual chunks from a chunk stream and writes each
  chunk to its own output stream.

  The `create_chunk_stream/2` function passed in as a parameter is used
  to create an output stream for the current chunk.

  Note that this function just creates the stream pipeline. It still needs
  to be run with `Stream.run/0` or some other equivalent function.

  Using streams and stream creators allows this function to be decoupled from
  the details of reading input data and writing chunk data, and makes
  it easier to test this function. Side effects are isolated to their
  own specialized functions.

  ## Parameters

  - chunk_stream: A stream that emits chunks of integers
  - create_chunk_stream: A function that accepts a generation number and a chunk
    number and returns a stream to write the chunk to (fn gen, chunk -> stream end)

  ## Returns

  A stream that emits tuples containing the chunk and the stream it was written to
  """
  @spec write_chunks_to_separate_streams(
          Enum.t(),
          non_neg_integer(),
          (non_neg_integer(), non_neg_integer() -> Enum.t())
        ) :: Enum.t()
  def write_chunks_to_separate_streams(chunk_stream, gen, create_chunk_stream) do
    chunk_stream
    # Include the chunk number
    |> Stream.with_index(1)
    # Transform tuples into tuples of chunks and chunk output streams
    |> Stream.map(fn {chunk, chunk_num} ->
      chunk_stream = create_chunk_stream.(gen, chunk_num)

      {chunk, chunk_stream}
    end)
    # Write each chunk to its output stream
    |> Stream.each(fn {chunk, chunk_stream} ->
      @integer_file.write_integers_to_stream(chunk, chunk_stream) |> Stream.run()
    end)
  end
end
