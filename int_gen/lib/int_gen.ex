defmodule IntGen do
  @moduledoc """
  Contains the functionality for creating a file of random integers
  """
  alias LargeSort.Shared.IntegerFile

  @doc """
  Creates a stream that generates an endless number of random integers
  from min_value to max_value (inclusive)

  ## Parameters

  - min_value: the lower bound (inclusive) of the range of integers to
  be generated
  - max_value: the upper bound (inclusive) of the range of integers to
  be generated

  ## Returns

  A stream that will generate an endless number of random integers
  """
  @spec random_integer_stream(integer(), integer()) :: Enumerable.t()
  def random_integer_stream(min_value, max_value) do
    Stream.repeatedly(fn -> Enum.random(min_value..max_value) end)
  end

  @doc """
  Creates a random integer file that contains a random integer on each line

  This function will throw an exception if anything goes wrong.

  ## Parameters

  - path: the path of the file to be created. If the file already exists, it will
  be overwritten
  - num: the number of random integers to be generated
  - min_value: the lower bound (inclusive) of the range of integers to
  be generated
  - max_value: the upper bound (inclusive) of the range of integers to
  be generated
  """
  @spec create_random_integer_file!(String.t(), non_neg_integer(), integer(), integer()) :: :ok
  def create_random_integer_file!(path, num, min_value, max_value) do
    #Create the integer file stream
    file_stream = IntegerFile.create_integer_file_stream(path)

    #Create the random integer stream
    random_int_stream = random_integer_stream(min_value, max_value)

    #Pipe N random integers to the file stream
    random_int_stream
    |> Stream.take(num)
    |> IntegerFile.write_integers_to_stream(file_stream)
    |> Stream.run()
  end
end
