defmodule IntSort.Test.Common do
  import Mox

  alias LargeSort.Shared.IntegerFile
  alias LargeSort.Shared.TestData

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

  @doc """
  Mocks the IntegerFile mock with the actual IntegerFile functionality

  This can be used when you want the real functionality instead of mocked
  functionality.

  ## Returns

  :ok
  """
  @spec stub_integer_file_mock() :: :ok
  def stub_integer_file_mock() do
    stub_with(IntSort.IntegerFileMock, LargeSort.Shared.IntegerFile)
  end

  #
  @doc """
  Creates a stream of random integers for use in testing

  ## Parameters

  - num_integers: the number of integers to generate

  ## Returns

  A stream that generates the specified number of random integers
  """
  @spec create_test_integers(non_neg_integer()) :: Enum.t()
  def create_test_integers(num_integers) do
    TestData.random_integer_stream(-1000..1000)
    |> Enum.take(num_integers)
  end

  @doc """
  Creates an integer file containing the specified integers

  ## Parameters

  - integers: an enumerable containing the integers to be written to the integer file.
  This function assumes that all of the elements in the enumerable are integers
  - file_name: the name (including the path) of the file the integers are to be written

  ## Returns

  The name of the file that was written to
  """
  @spec create_integer_file(Enum.t(), String.t()) :: String.t()
  def create_integer_file(integers, file_name) do
    file_stream = IntegerFile.integer_file_stream(file_name)

    IntegerFile.write_integers_to_stream(integers, file_stream)
    |> Stream.run()

    file_name
  end
end
