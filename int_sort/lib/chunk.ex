defmodule IntSort.Chunk do
  @moduledoc """
  Contains functionality for handling chunk files, which contain chunks
  of sorted integers
  """

  @integer_file Application.get_env(:int_sort, :integer_file)

  @doc """
  Divides the integers in an input stream into chunks and writes each
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

  - input_stream: A stream of integers to be read from
  - chunk_size: The number of integers in a chunk
  - create_chunk_stream: A function that accepts a generation number and a chunk
    number and returns a stream to write the chunk to (fn gen, chunk -> stream end)

  ## Returns

  A stream representing the entire stream operations pipeline
  """
  @spec create_chunks(Enum.t(), pos_integer(), (non_neg_integer(), non_neg_integer() -> Enum.t())) ::
          Enum.t()
  def create_chunks(input_stream, chunk_size, create_chunk_stream) do
    # The chunks created by this process are considered the first chunk generation
    initial_gen = 1

    # Start with the stream of integers
    result = input_stream
    # Create chunks of integers
    |> Stream.chunk_every(chunk_size)
    # Include the chunk number
    |> Stream.with_index(1)
    # Transform tuples into tuples of chunks and chunk output streams
    |> Stream.map(fn {chunk, chunk_num} ->
      chunk_stream = create_chunk_stream.(initial_gen, chunk_num)

      {chunk, chunk_stream}
    end)
    # Write each chunk to its output stream
    |> Stream.each(fn {chunk, chunk_stream} ->
      @integer_file.write_integers_to_stream(chunk, chunk_stream) |> Stream.run()
    end)
  end
end
