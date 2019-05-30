defmodule IntGen do
  @moduledoc """
  Contains the functionality for creating a file of random integers
  """

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
  def random_integer_stream(min_value, max_value) do
    Stream.repeatedly(fn -> Enum.random(min_value..max_value) end)
  end

  @doc """
  Writes the contents of a stream to an integer file, where each
  element has its own line

  If the file being written to already exists, it will be overwritten

  ## Parameters

  - stream: the stream whose contents are to be written to the file
  - path: the path of the file to be written to

  ## Returns

  `:ok` if the file was written correctly, otherwise `{:error, :reason}`,
  where `:reason` is replaced by a standard Elixir atom from the `File`
  module that describes why it could not be written.
  """
  def stream_to_integer_file(stream, path) do

  end
end
