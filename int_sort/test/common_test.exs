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
    |> Stream.take(num_integers)
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

  @doc """
  Calculate the number of merge generations in a sequence of merge operations

  ## Parameters

  - file_count: The number of files being merged
  - merge_count: The number of files being merged during each merge

  ## Returns

  The number of merge generations necessary to complete all the merges
  """
  @spec merge_generations(non_neg_integer(), pos_integer()) :: non_neg_integer()
  def merge_generations(file_count, merge_count) do
    ceil(log(file_count, merge_count)) + 1
  end

  @doc """
  The names of the expected chunk files for a set of integers

  ## Parameters

  - integer_count: The number of integers being chunked
  - chunk_size: The size of each chunk

  ## Returns

  A collection of chunk files that will be created
  """
  def chunk_files(integer_count, chunk_size) do
    1..num_chunks(integer_count, chunk_size)
    |> Enum.map(fn chunk_num -> IntSort.gen_file_name(1, chunk_num) end)
  end

  @doc """
  The names of the expected merge files from merging a set of chunk files

  ## Parameters

  - merge_gens: The number of generations it takes to merge a set of integers
  - file_count: The number of files being merged
  - merge_count: The number of files being merged at one time

  ## Returns

  A collection of intermediate file names that will be generated from this merge
  """
  def merge_files(merge_gens, _, _) when merge_gens <= 1, do: []

  def merge_files(merge_gens, file_count, merge_count) do
    2..merge_gens
    |> Enum.map(fn gen -> {gen, ceil(file_count / pow(merge_count, gen - 1))} end)
    |> Enum.flat_map(fn {gen, count} -> Enum.map(1..count, &[gen, &1]) end)
    |> Enum.map(fn [gen, count] -> IntSort.gen_file_name(gen, count) end)
  end

  # TODO: Replace this with a Math library dependency

  @doc """
  Calculates the base-*b* logarithm of *x*
  Note that variants for the most common logarithms exist that are faster and more precise.
  See also `Math.log/1`, `Math.log2/1` and `Math.log10/1`.
  ## Examples
      iex> Math.log(5, 5)
      1.0
      iex> Math.log(20, 2) <~> Math.log2(20)
      true
      iex> Math.log(20, 10) <~> Math.log10(20)
      true
      iex> Math.log(2, 4)
      0.5
      iex> Math.log(10, 4)
      1.6609640474436813
  """
  # @spec log(x, number) :: float
  def log(x, x), do: 1.0

  def log(x, b) do
    :math.log(x) / :math.log(b)
  end

  @spec pow(number, number) :: number
  def pow(x, n)

  def pow(x, n) when is_integer(x) and is_integer(n), do: _pow(x, n)

  # Float implementation. Uses erlang's math library.
  def pow(x, n) do
    :math.pow(x, n)
  end

  # Integer implementation. Uses Exponentiation by Squaring.
  defp _pow(x, n, y \\ 1)
  defp _pow(_x, 0, y), do: y
  defp _pow(x, 1, y), do: x * y
  defp _pow(x, n, y) when n < 0, do: _pow(1 / x, -n, y)
  defp _pow(x, n, y) when rem(n, 2) == 0, do: _pow(x * x, div(n, 2), y)
  defp _pow(x, n, y), do: _pow(x * x, div(n - 1, 2), x * y)
end
