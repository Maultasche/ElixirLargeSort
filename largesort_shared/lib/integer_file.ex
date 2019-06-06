defmodule LargeSort.Shared.IntegerFile do
  alias LargeSort.Shared.IntegerFileBehavior
  @behaviour IntegerFileBehavior

  @moduledoc """
  Contains functionality for working with integer files
  """

  @doc """
  Creates a stream for an integer file that operates in line mode

  Any existing file will be overwritten.

  If something goes wrong when creating the file stream, this function
  will throw an exception.

  ## Parameters

   - path: the path of the file to be written to

  ## Returns

  A stream that can be used to read from or write to the file
  """
  @impl IntegerFileBehavior
  @spec create_integer_file_stream(String.t()) :: Enumerable.t()
  def create_integer_file_stream(path) do
    File.stream!(path, [:utf8], :line)
  end

  @doc """
  Writes an enumerable containing integers to a stream

  ## Parameters

  - enumerable: the enumerable whose integers are to be written to the file
  - out_stream: the stream to be written to. Actually, this doesn't necessarily
  have to be a stream. Any collectable will do.

  ## Returns

  A stream consisting of the write operations
  """
  @impl IntegerFileBehavior
  @spec write_integers_to_stream(Enumerable.t(), Collectable.t()) :: Enumerable.t()
  def write_integers_to_stream(enumerable, out_stream) do
    enumerable
    |> Stream.map(&Integer.to_string/1)
    |> Stream.map(&(&1 <> "\n"))
    |> Stream.into(out_stream)
  end
end
