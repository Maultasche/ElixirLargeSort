defmodule IntSort.IntermediateFile do
  @moduledoc """
  Contains functionality for working with intermediate files
  """

  @integer_file Application.get_env(:int_sort, :integer_file)

  @doc """
  Creates a stream that can be used to read from or write to an intermediate file

  ## Parameters

  - gen: The merge generation that this intermediate file represents
  - num: The file number in the current generation
  - create_file_name: A function that converts the generation and file number
    to an intermediate file name
  - output_path: The path to the directory in which the intermediate file is located

  ## Returns

  A stream for the intermediate file
  """
  @spec intermediate_file_stream(
          non_neg_integer(),
          non_neg_integer(),
          (non_neg_integer(), non_neg_integer() -> String.t()),
          String.t()
        ) :: Enum.t()
  def intermediate_file_stream(gen, num, create_file_name, output_path) do
    # Create a file name for the intermediate file
    file_name = create_file_name.(gen, num)

    # Combine the file name with the output directory to create a file path
    intermediate_file_path = Path.join(output_path, file_name)

    # Create a stream for that file path and return it
    @integer_file.integer_file_stream(intermediate_file_path)
  end

  # @doc """
  # Takes in a stream of file names, merges those files in groups, and returns
  # a stream that emits the file names of the merged files

  # ## Parameters

  # - file_stream: a stream that emits intermediate file names
  # - group_size: the number of files in a merge group.
  # - gen: the generation number that this merge represents
  # - total_gen: the total number of generations needed to merge all the files
  # - output_path: a directory path where the resulting merged files will be written
  # """
  # @spec merge_files(Enum.t(), pos_integer(), non_neg_integer(), non_neg_integer(), String.t()) :: Enum.t()
  # def merge_files(file_stream, _, gen, total_gen, _) when gen > total_gen do
  #   # When we've set up all the merges
  #   file_stream
  # end
  # def merge_files(file_stream, group_size, gen, total_gen, output_path) do
  #   file_stream
  #   # Create a group of files to be merged
  #   |> create_file_group(group_size)
  #   # Merge each group and emit the name of the file that resulted from the merge
  #   |> Stream.map(fn {file_group, num} -> merge_file_group(file_group, num, gen, output_path) end)
  #   # Setup the next round of merges by recursively calling this function
  #   |> merge_files(group_size, gen + 1, total_gen, output_path)
  # end

  @doc """
  Creates a stream of file groups for the purposes of merging.

  Files get merged in groups of N files at a time to prevent excessive resource
  usage when merging large numbers of files.

  ## Parameters

  - file_elements: An enumerable containing file elements, where each element represents
  a file. An element can be a file name or something else that represents a file,
  like an I/O device
  - group_size: The size of the file groups that are to be created

  ## Returns

  A stream of tuples containing the file element chunks in a group, where each group
  has group_size elements in the group, as the first tuple element and the group number
  (starting with 1) as the second tuple element. The last group may be smaller than
  group_size if the number of file elements is not evenly divisible by group_size.
  """
  @spec create_file_groups(Enum.t(), pos_integer()) :: Enum.t()
  def create_file_groups(file_elements, group_size) do
    file_elements
    # Put the intermediate files into groups
    |> Stream.chunk_every(group_size)
    # Associate each group with a group number
    |> Stream.with_index(1)
  end

  @doc """
  Creates a merge stream that emits the next smallest integer from all
  the intermediate files that are being merged

  This is where the merge magic happens. Integers are read from the (sorted)
  intermediate files and the smallest integer among the files gets emitted
  from the stream. The next integer is read from the file where the last
  emitted integer came from and the process happens all over again until
  there are no more integers to emit.

  The devices passed into this function must have been previously opened
  using `IntegerFile.read_device!/1`. I did it this way so rather
  than using file names so that someone could make a merge stream using
  any kind of device, not just files. It certainly makes this function
  more easily testable.

  ## Parameters

  - devices: Open integer file devices, with each device representing an
  intermediate file to be merged. Use `IntegerFile.read_device!/1` to
  open the integer file devices. If the devices were not opened using
  `IntegerFile.read_device!/1`, you'll get an error when attempting
  to read from the stream. Note that even though I call these "integer
  file devices", they don't strictly have to be devices for files. Any
  device containing integer-file-formatted data can be used.
  - close_device: A function that will be called for each file integer
  device when the stream has terminated. This is an optional parameter,
  and if you don't specify it, you'll need to close the devices yourself.

  ## Returns

  A stream that emits the next smallest integer from among the intermediate
  files. The output represents the merged contents of the files and can be
  streamed into another integer file.
  """
  @spec merge_stream(Enum.t(), (IO.device() -> term())) :: Enum.t()
  def merge_stream(devices, close_device \\ fn _ -> :ok end) do
    Stream.resource(
      fn -> initial_merge_stream_state(devices) end,
      &next_merge_integer/1,
      fn stream_state -> cleanup_merge_stream(stream_state, close_device) end
    )
  end

  # This is the accumulator that gets passed between function calls as the
  # next element is retrieved from the stream
  @type merge_stream_acc() :: list({integer() | nil, IO.device()})

  # Creates the initial state of the merge stream, which will be used as the
  # accumulator when retrieving future stream elements
  @spec initial_merge_stream_state(Enum.t()) :: merge_stream_acc()
  defp initial_merge_stream_state(devices) do
    # Create a collection of tuples where the first element is the
    # first integer read from the device and the second element is the
    # device
    devices
    |> Enum.map(fn device -> {read_next_integer(device), device} end)
    |> Enum.to_list()
  end

  # Retrieves the next merge integer from the integer file devices
  @spec next_merge_integer(merge_stream_acc()) ::
          {[integer()], merge_stream_acc()} | {:halt, merge_stream_acc()}
  defp next_merge_integer(stream_state) do
    # Determine the minimum integer in the available integers. This will be the
    # value that the stream emits. This code works with nil values because
    # a nil is always larger than any integers. We'll only get a nil if
    # no integers remain. Remember that this returns a tuple with the min
    # value and the device it was read from
    min_value = Enum.min_by(stream_state, fn {value, _} -> value end, fn -> nil end)

    # Now that we have the min value, calculate the value to be returned
    merge_stream_value(min_value, stream_state)
  end

  # Cleans up after the merge stream terminates, closing all devices
  @spec cleanup_merge_stream(merge_stream_acc(), (IO.device() -> term())) :: :ok
  defp cleanup_merge_stream(stream_state, close_device) do
    stream_state
    |> Enum.map(fn {_, device} -> device end)
    |> Enum.each(close_device)

    :ok
  end

  # Creates the value to be returned from the merge stream's next value function.
  # If the min value is nil, that means there are no more integers and the stream
  # can be terminated. Otherwise, we'll emit the min value and create a new
  # stream state with the latest set of integers from each device
  @spec merge_stream_value({integer() | nil, IO.device()}, merge_stream_acc()) ::
          {[integer()], merge_stream_acc()} | {:halt, merge_stream_acc()}
  defp merge_stream_value(nil, stream_state) do
    # The min value is nil, so there are no more integers. Terminate the stream.
    {:halt, stream_state}
  end

  defp merge_stream_value({nil, _}, stream_state) do
    # The min value is nil, so there are no more integers. Terminate the stream.
    {:halt, stream_state}
  end

  defp merge_stream_value({min_integer, device}, stream_state) do
    # Reading the next number from the device that produced the min value
    # so that we'll get the next integer from the device
    new_value = {read_next_integer(device), device}

    # Update the stream state with the new value tuple
    stream_state = List.keyreplace(stream_state, device, 1, new_value)

    # Return the min integer with the new stream state
    {[min_integer], stream_state}
  end

  # Reads the next integer from a device. Returns nil if there are no
  # more integers to be read
  @spec read_next_integer(IO.device()) :: integer() | nil
  defp read_next_integer(device) do
    @integer_file.read_integer(device)
    |> integer_value()
  end

  # Converts an integer value to itself if the value is an integer
  # or to `nil` if the value is `:eof`
  @spec integer_value(integer() | :eof) :: integer() | nil
  defp integer_value(:eof), do: nil
  defp integer_value(integer), do: integer
end
