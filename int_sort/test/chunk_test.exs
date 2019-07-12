defmodule IntSort.ChunkTest do
  use ExUnit.Case
  alias IntSort.Chunk
  alias LargeSort.Shared.TestStream
  alias LargeSort.Shared.TestData

  import Mox

  doctest Chunk

  describe "create_chunks - " do
    test "Moderate number of integers with moderate chunk size with integers evenly divisible by chunk size " do
      test_chunking(1000, 50)
    end

    test "Moderate number of integers that are not evenly divisible by chunk size " do
      test_chunking(1000, 23)
    end

    test "Large number of integers with moderate chunk size " do
      test_chunking(100000, 100)
    end

    test "Large number of integers with small chunk size " do
      test_chunking(100000, 5)
    end

    test "Small number of integers with small chunk size " do
      test_chunking(10, 2)
    end

    test "Chunking integers with a chunk size of 1" do
      test_chunking(100, 1)
    end

    test "Number of integers equals chunk size" do
      test_chunking(10, 10)
    end

    test "Number of integers is smaller than chunk size" do
      test_chunking(10, 20)
    end

    @tag :zero
    test "Chunking zero integers" do
      test_chunking(0, 10)
    end

    @spec test_chunking(non_neg_integer(), pos_integer()) :: non_neg_integer()
    defp test_chunking(num_integers, chunk_size) do
      # Randomly generate the integers needed for the test
      integers = TestData.random_integer_stream(-1000..1000)
        |> Enum.take(num_integers)

      # Create any mocks that need to be created
      create_mocks()

      # Call create_chunks and get the transformed stream
      chunk_stream = Chunk.create_chunks(integers, chunk_size)

      # Verify the results
      verify_chunk_results(chunk_stream, integers, chunk_size)
    end

    # Mocks any modules that need to be mocked
    @spec create_mocks() :: :ok
    defp create_mocks() do
      # For this test, we want to use the functions in the actual module
      # for the mock module, so we'll just have mock module share the
      # functionality
      stub_with(IntGen.IntegerFileMock, LargeSort.Shared.IntegerFile)

      :ok
    end

    # Verifies the results of the chunking test
    @spec verify_chunk_results(Enum.t(), list(integer()), non_neg_integer()) :: :ok
    defp verify_chunk_results(chunk_stream, integers, chunk_size) do
      # Calculate expected chunks
      expected_chunks = expected_chunks(integers, chunk_size)

      # Retrieve the actual chunks
      actual_chunks = Enum.to_list(chunk_stream)

      # The chunks are in order, so zip them together and verify that the expected
      # chunks were written to the output streams
      expected_chunks
      |> Enum.zip(actual_chunks)
      |> Enum.each(fn {expected, actual} -> assert expected == actual end)

      :ok
    end

    #Calculates the chunks that should be created
    @spec expected_chunks(list(integer()), pos_integer()) :: list(list(integer()))
    defp expected_chunks(integers, chunk_size) do
      Enum.chunk_every(integers, chunk_size)
    end
  end

  # @type chunk_stream_key :: {pos_integer(), non_neg_integer()}
  # @type chunk_stream_value :: {pid(), Enum.t()}
  # @type chunk_stream_map :: %{optional(chunk_stream_key()) => chunk_stream_value()}


  # @spec test_chunking(non_neg_integer(), pos_integer()) :: non_neg_integer()
  # defp test_chunking(num_integers, chunk_size) do
  #   chunk_gen = 1

  #   # Randomly generate the integers needed for the test
  #   integers = TestData.random_integer_stream(-1000..1000)
  #     |> Enum.take(num_integers)

  #   # Create any mocks that need to be created
  #   create_mocks()

  #   # Calculate the number of chunks
  #   num_chunks = num_chunks(integers, chunk_size)

  #   # Create a test chunk stream for each chunk
  #   chunk_streams = create_test_chunk_streams(chunk_gen, num_chunks)

  #   # Create a create_chunk_stream callback function to pass to create_chunks
  #   create_chunk_stream = fn gen, chunk_num ->
  #     get_test_chunk_stream(gen, chunk_num, chunk_streams)
  #   end

  #   # Call create_chunks and start stream processing
  #   Chunk.create_chunks(integers, chunk_size, create_chunk_stream)
  #   |> Stream.run()

  #   # Verify the results
  #   verify_chunk_results(integers, chunk_gen, chunk_size, chunk_streams)
  # end

  # # Mocks any modules that need to be mocked
  # @spec create_mocks() :: :ok
  # defp create_mocks() do
  #   # For this test, we want to use the functions in the actual module
  #   # for the mock module, so we'll just have mock module share the
  #   # functionality
  #   stub_with(IntGen.IntegerFileMock, LargeSort.Shared.IntegerFile)

  #   :ok
  # end

  # # Verifies the results of the chunking test
  # @spec verify_chunk_results(list(integer()), non_neg_integer(), non_neg_integer(), chunk_stream_map()) :: :ok
  # defp verify_chunk_results(integers, gen, chunk_size, chunk_streams) do
  #   # Calculate expected chunks
  #   expected_chunks = expected_chunks(integers, chunk_size)

  #   # Retrieve the actual chunks
  #   actual_chunks = chunks_from_test_streams(gen, chunk_streams)

  #   # The chunks are in order, so zip them together and verify that the expected
  #   # chunks were written to the output streams
  #   expected_chunks
  #   |> Enum.zip(actual_chunks)
  #   |> Enum.each(fn {expected, actual} -> assert expected == actual end)

  #   :ok
  # end

  # #Calculates the chunks that should be created
  # @spec expected_chunks(list(integer()), pos_integer()) :: list(list(integer()))
  # defp expected_chunks(integers, chunk_size) do
  #   Enum.chunk_every(integers, chunk_size)
  # end

  # #Extracts the chunks that were actually written from the test streams
  # @spec chunks_from_test_streams(non_neg_integer(), chunk_stream_map()) :: list(list(integer()))
  # defp chunks_from_test_streams(_, chunk_streams)
  #   when map_size(chunk_streams) == 0, do: []

  # defp chunks_from_test_streams(gen, chunk_streams) do
  #   # Start with a range of chunk streams
  #   1..map_size(chunk_streams)
  #   # Map the cunk numbers to a collection of streams associated with those chunks
  #   |> Enum.map(fn chunk_num -> chunk_streams[{gen, chunk_num}] end)
  #   # Close the stream and extract the contents
  #   |> Enum.map(&get_string_stream_contents/1)
  # end

  # #Calculates the number of chunks for a list of integers
  # @spec num_chunks(list(integer()), pos_integer()) :: non_neg_integer()
  # defp num_chunks(integers, chunk_size) do
  #   ceil(length(integers) / chunk_size)
  # end

  # #Closes a test stream device and extracts the integer contents of the
  # #stream device, returning it as a list of integers
  # @spec get_string_stream_contents(chunk_stream_value()) :: list(String.t())
  # defp get_string_stream_contents({device, _}) do
  #   # Close the test stream and get the data that was written to it
  #   {:ok, {_, written_data}} = StringIO.close(device)

  #   # Extract a list of integers from the data that was written
  #   TestStream.stream_data_to_integers(written_data)
  # end

  # #Retrieves a test chunk stream from the map of test chunks streams
  # #This function forms the basis of the callback function that is passed into
  # #create_chunks, so it contains assertions
  # @spec get_test_chunk_stream(pos_integer(), non_neg_integer(), chunk_stream_map()) :: Enum.t()
  # defp get_test_chunk_stream(gen, chunk_num, test_streams) do
  #   key = {gen, chunk_num}

  #   assert Map.has_key?(test_streams, key)

  #   {_, test_stream} = test_streams[key]

  #   test_stream
  # end

  # #Creates a test stream for every generation and chunk number combination
  # #and returns the result in a map
  # @spec create_test_chunk_streams(pos_integer(), non_neg_integer()) :: chunk_stream_map()
  # defp create_test_chunk_streams(_, 0), do: %{}

  # defp create_test_chunk_streams(gen, num_chunks) do
  #   test_streams = Enum.map(1..num_chunks, fn chunk_num ->
  #     {{gen, chunk_num}, TestStream.create_test_stream()}
  #   end)

  #   #We should end up with a stream map whose key is the {gen, chunk_num} tuple
  #   #and whose value is a tuple containing the stream and the stream device
  #   Enum.into(test_streams, %{})
  # end
end
