defmodule IntSort.Test.Common do
  @moduledoc """
  Contains functionality that is used in multiple tests
  """

  @doc """
  Calculates the chunks that should be created from a chunking operation

  ## Parameters

  - integers: the integers to be chunked
  - chunk_size: the size of each chunk

  ## Returns

  A stream that emits the expected chunks
  """
  @spec expected_chunks(list(integer()), pos_integer()) :: Enum.t()
  def expected_chunks(integers, chunk_size) do
    Stream.chunk_every(integers, chunk_size)
  end

  @doc """
  Calculates the chunks that should be created from a chunking and sorting operation,
  where each chunk is sorted

  ## Parameters

  - integers: the integers to be chunked
  - chunk_size: the size of each chunk

  ## Returns

  A stream that emits the expected sorted chunks
  """
  @spec expected_chunks(list(integer()), pos_integer()) :: Enum.t()
  def expected_sorted_chunks(integers, chunk_size) do
    expected_chunks(integers, chunk_size) |> Stream.map(&Enum.sort/1)
  end

  @doc """
  Calculates the number of chunks that will result from a chunking operation

  ## Parameters

  num_integers: the number of integers to be chunked
  chunk_size: the size of each chunk

  ## Returns

  The number of expected chunks
  """
  @spec num_chunks(non_neg_integer(), pos_integer()) :: non_neg_integer()
  def num_chunks(num_integers, chunk_size) do
    ceil(num_integers / chunk_size)
  end
end
