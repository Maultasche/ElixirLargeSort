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
  @spec integer_file_stream(String.t()) :: Enumerable.t()
  def integer_file_stream(path) do
    create_file_directory(path)

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

  @doc """
  Creates a stream that reads integers from an integer stream

  ## Parameters

  - integer_stream: A stream that reads lines of integer text,
    most likely lines of text from an integer file

  ## Returns

  A stream that emits the integers in the integer file
  """
  @impl IntegerFileBehavior
  @spec read_stream(Enumerable.t()) :: Enumerable.t()
  def read_stream(integer_stream) do
    integer_stream
    |> Stream.map(&String.trim/1)
    |> Stream.map(&String.to_integer/1)
  end

  #Creates the directory for a file path, if it doesn't already exist
  defp create_file_directory(file_path, directory_exists \\ nil)
  defp create_file_directory(file_path, nil) do
    directory = Path.dirname(file_path)

    create_file_directory(file_path, File.dir?(directory))
  end
  defp create_file_directory(_, true), do: :ok
  defp create_file_directory(file_path, false) do
    directory = Path.dirname(file_path)

    File.mkdir_p(directory)
  end

end
