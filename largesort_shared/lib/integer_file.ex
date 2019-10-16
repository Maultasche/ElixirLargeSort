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
    |> integers_to_lines()
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

  @doc """
  Counts the number of lines in an raw integer text stream

  This function makes no attempt to parse the integers or determine the
  validity of the integers in the stream. It just counts the number of
  items it encounters.

  Note that when the function has completed, all the items will have been
  read from the stream. So the stream is not likely to be that useful
  after this function has completed and you'd have to create a new
  stream with the same data to do anything else with that data.

  ## Parameters

  - integer_stream: A stream that reads lines of integer text,
    most likely lines of text from an integer file

  ## Returns

  The number of lines found in the stream
  """
  @impl IntegerFileBehavior
  @spec integer_count(Enumerable.t()) :: non_neg_integer()
  def integer_count(integer_stream) do
    Enum.count(integer_stream)
  end

  # Creates the directory for a file path, if it doesn't already exist
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

  @doc """
  Creates an integer file device for reading

  This function assumes that the integer file exists and can be opened for reading

  ## Parameters

  - path: The path of the file to be opened for reading

  ## Returns

  An IO device that can be used to read from the integer file
  """
  @impl IntegerFileBehavior
  @spec read_device!(String.t()) :: IO.device()
  def read_device!(path) do
    File.open!(path, [:utf8, :read, :read_ahead])
  end

  @doc """
  Creates an integer file device for writing

  This function assumes that the integer file exists and can be opened for writing

  ## Parameters

  - path: The path of the file to be opened for writing

  ## Returns

  An IO device that can be used to write to the integer file
  """
  @impl IntegerFileBehavior
  @spec write_device!(String.t()) :: IO.device()
  def write_device!(path) do
    File.open!(path, [:utf8, :write, :delayed_write])
  end

  @doc """
  Closes an integer file device

  ## Parameters

  - device: The integer file device to be closed

  ## Returns

  `:ok`
  """
  @impl IntegerFileBehavior
  @spec close_device(IO.device()) :: :ok
  def close_device(device) do
    File.close(device)
  end

  @doc """
  Reads an integer from a device that contains integer file-formatted data

  This function assumes that the IO device is operating in a read mode as well
  as :utf8 mode.

  ## Parameters

  - device: The IO device to be read from

  ## Returns

  The integer that was read from the device, an `:eof` when the end of file
  was encountered, or `{:error, reason}` when there was an error reading
  from the device.
  """
  @impl IntegerFileBehavior
  @spec read_integer(IO.device()) :: integer() | IO.no_data()
  def read_integer(device) do
    device
    |> IO.read(:line)
    |> data_to_integer()
  end

  @doc """
  Writes an integer to a device using the integer file format

  This function assumes that the IO device is operating in a write mode as well
  as :utf8 mode.

  ## Parameters

  - device: The IO device to be written to

  ## Returns

  :ok to indicate success
  """
  @impl IntegerFileBehavior
  @spec write_integer(IO.device(), integer()) :: :ok
  def write_integer(device, integer) do
    integer
    # Convert the integer to a string
    |> Integer.to_string()
    # Concatenate the integer string with a newline character
    |> Kernel.<>("\n")
    # Write the resulting line to the device
    |> (fn line -> IO.write(device, line) end).()
  end

  @doc """
  Converts an enumerable containing integers
  to a stream of integer file lines (including the newline
  characters)

  ## Parameters

  - integers: an enumerable containing integers to be converted

  ## Returns

  A collection of strings that contain the integers in integer file format,
  with each element an integer file line
  """
  @impl IntegerFileBehavior
  @spec integers_to_lines(Enum.t()) :: Enum.t()
  def integers_to_lines(integers) do
    integers
    |> Stream.map(&Integer.to_string/1)
    |> Stream.map(&(&1 <> "\n"))
  end

  # Converts data read from an IO device to an integer
  defp data_to_integer(:eof), do: :eof
  defp data_to_integer(data = {:error, _}), do: data

  defp data_to_integer(data) do
    data
    |> String.trim()
    |> String.to_integer()
  end
end
