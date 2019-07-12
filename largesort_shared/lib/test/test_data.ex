defmodule LargeSort.Shared.TestData do
  @moduledoc """
  Contains functionality related to test data
  """

  @doc """
  Creates a stream that generates an endless number of random integers
  from min_value to max_value (inclusive)

  ## Parameters

  - integer_range: the range of integers to be generated

  ## Returns

  A stream that will generate an endless number of random integers
  """
  @spec random_integer_stream(Range.t()) :: Enumerable.t()
  def random_integer_stream(integer_range) do
    Stream.repeatedly(fn -> Enum.random(integer_range) end)
  end
end
