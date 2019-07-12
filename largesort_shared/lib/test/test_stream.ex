defmodule LargeSort.Shared.TestStream do
  @moduledoc """
  Contains test stream functionality for use in unit testing
  """

  @doc """
  Creates a test stream that reads from and writes to a string I/O device

  ## Returns

  A tuple containing the stream and the device that it wraps so that the contents
  of the device can be read later on
  """
  @spec create_test_stream() :: {pid(), Enumerable.t()}
  def create_test_stream() do
    # Open a string I/O device
    {:ok, device} = StringIO.open("")

    # Turn the string I/O device into a text line stream
    {device, IO.stream(device, :line)}
  end

  @doc """
  Converts integer stream data to an enumerable containing integers

  This function assumes that the data being written to the stream was
  written in integer file format.

  ## Parameters

  - data: The contents of a string stream
  - separateor: The separator between integer values

  ## Returns

  A list of integers that were extracted from the string contents
  """
  @spec stream_data_to_integers(String.t()) :: list(integer())
  def stream_data_to_integers(data, separator \\ "\n") do
    data
    |> String.trim()
    |> String.split(separator)
    |> Stream.reject(fn line -> line == "" end)
    |> Enum.map(&String.to_integer/1)
  end

end
