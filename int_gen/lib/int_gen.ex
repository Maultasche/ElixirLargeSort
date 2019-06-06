defmodule IntGen do
  @moduledoc """
  Contains the functionality for creating a file of random integers
  """
  @integer_file Application.get_env(:int_gen, :integer_file)

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

  @doc """
  Creates an integer file that contains an integer on each line

  ## Parameters

  - path: the path of the file to be created. If the file already exists, it will
  be overwritten
  - num: the number of integers to written to the file. If there aren't enough integers
  in the random integer stream or enumerable to fulfill this number, then only the
  max possible number of integers are written.
  - integers: A stream or enumerable containing the integers to be written
  """
  @spec create_integer_file(String.t(), non_neg_integer(), Enumerable.t()) :: :ok
  def create_integer_file(path, num, integers) do
    # Create the integer file stream
    file_stream = @integer_file.create_integer_file_stream(path)

    # Pipe N integers to the file stream
    integers
    |> Stream.take(num)
    |> @integer_file.write_integers_to_stream(file_stream)
    |> Stream.run()
  end
end
