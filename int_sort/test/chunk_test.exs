defmodule IntSort.ChunkTest do
  use ExUnit.Case, async: true

  alias IntSort.Chunk
  alias LargeSort.Shared.TestStream
  alias LargeSort.Shared.TestData
  alias IntSort.Test

  doctest Chunk

  describe "create_chunks -" do
    test "Moderate number of integers with moderate chunk size with integers evenly divisible by chunk size " do
      test_chunking(1000, 50)
    end

    test "Moderate number of integers that are not evenly divisible by chunk size " do
      test_chunking(1000, 23)
    end

    test "Large number of integers with moderate chunk size " do
      test_chunking(100_000, 100)
    end

    test "Large number of integers with small chunk size " do
      test_chunking(100_000, 5)
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

    test "Chunking zero integers" do
      test_chunking(0, 10)
    end

    @spec test_chunking(non_neg_integer(), pos_integer()) :: non_neg_integer()
    defp test_chunking(num_integers, chunk_size) do
      # Randomly generate the integers needed for the test
      integers =
        TestData.random_integer_stream(-1000..1000)
        |> Enum.take(num_integers)

      # Create any mocks that need to be created
      create_chunking_mocks()

      # Call create_chunks and get the transformed stream
      chunk_stream = Chunk.create_chunks(integers, chunk_size)

      # Verify the results
      verify_chunk_results(chunk_stream, integers, chunk_size)
    end

    # Mocks any modules that need to be mocked
    @spec create_chunking_mocks() :: :ok
    defp create_chunking_mocks() do
      # For this test, we want to use the functions in the actual module
      # for the mock module, so we'll just have mock module share the
      # functionality
      Test.Common.stub_integer_file_mock()

      :ok
    end

    # Verifies the results of the chunking test
    @spec verify_chunk_results(Enum.t(), list(integer()), non_neg_integer()) :: :ok
    defp verify_chunk_results(chunk_stream, integers, chunk_size) do
      # Calculate expected chunks
      expected_chunks = Test.Common.expected_chunks(integers, chunk_size)

      # Retrieve the actual chunks
      actual_chunks = Enum.to_list(chunk_stream)

      # The chunks are in order, so zip them together and verify that the expected
      # chunks were written to the output streams
      expected_chunks
      |> Enum.zip(actual_chunks)
      |> Enum.each(fn {expected, actual} -> assert expected == actual end)

      :ok
    end
  end

  describe "sort_chunks -" do
    test "Sort moderate number of chunks" do
      test_sorting(100, 100)
    end

    test "Sort large number of chunks" do
      test_sorting(10000, 100)
    end

    test "Sort small number of chunks" do
      test_sorting(10, 100)
    end

    test "Sort large chunks" do
      test_sorting(100, 10000)
    end

    test "Sort small chunks" do
      test_sorting(100, 10)
    end

    test "Sort zero chunks" do
      test_sorting(0, 100)
    end

    test "Sort single integer chunks" do
      test_sorting(100, 1)
    end

    @spec test_sorting(non_neg_integer(), pos_integer()) :: :ok
    defp test_sorting(num_chunks, chunk_size) do
      # Create chunks for use in testing
      test_chunks = create_test_chunks(num_chunks, chunk_size)

      # Call sort_chunks and get the transformed stream
      sorted_chunk_stream = Chunk.sort_chunks(test_chunks)

      # Verify the results
      verify_sort_results(sorted_chunk_stream, test_chunks)
    end

    # Verifies the results of the sorting test
    @spec verify_sort_results(Enum.t(), Enum.t()) :: :ok
    defp verify_sort_results(sorted_chunk_stream, test_chunks) do
      # Calculate expected chunks
      expected_chunks =
        test_chunks
        |> Enum.map(&Enum.sort/1)

      # Retrieve the actual chunks
      actual_chunks = Enum.to_list(sorted_chunk_stream)

      # The chunks are in order, so zip them together and verify that the expected
      # chunks match the actual chunks
      expected_chunks
      |> Enum.zip(actual_chunks)
      |> Enum.each(fn {expected, actual} -> assert expected == actual end)

      :ok
    end
  end

  describe "write_chunks_to_separate_streams -" do
    test "Write a moderate number of chunks" do
      test_chunk_writing(100, 10)
    end

    test "Write a large number of chunks" do
      test_chunk_writing(10000, 10)
    end

    test "Write a small number of chunks" do
      test_chunk_writing(10, 10)
    end

    test "Write a single chunk" do
      test_chunk_writing(1, 10)
    end

    test "Write zero chunks" do
      test_chunk_writing(0, 10)
    end

    test "Write big chunks" do
      test_chunk_writing(10, 10000)
    end

    test "Write small chunks" do
      test_chunk_writing(10, 100)
    end

    test "Write single item chunks" do
      test_chunk_writing(10, 1)
    end

    @type chunk_stream_key :: {pos_integer(), non_neg_integer()}
    @type chunk_stream_value :: {pid(), Enum.t()}
    @type chunk_stream_map :: %{optional(chunk_stream_key()) => chunk_stream_value()}

    @spec test_chunk_writing(non_neg_integer(), pos_integer()) :: non_neg_integer()
    defp test_chunk_writing(num_chunks, chunk_size) do
      chunk_gen = 1

      # Create chunks for use in testing
      test_chunks = create_test_chunks(num_chunks, chunk_size)

      # Create any mocks that need to be created
      create_chunk_write_mocks()

      # Create a test chunk stream for each chunk
      chunk_streams = create_test_chunk_streams(chunk_gen, length(test_chunks))

      # Create a create_chunk_stream callback function to pass to write_chunks_to_separate_streams
      create_chunk_stream = fn gen, chunk_num ->
        get_test_chunk_stream(gen, chunk_num, chunk_streams)
      end

      # Call write_chunks_to_separate_streams
      final_stream =
        Chunk.write_chunks_to_separate_streams(test_chunks, chunk_gen, create_chunk_stream)

      # Verify the results
      verify_chunk_results(final_stream, test_chunks, chunk_gen, chunk_streams)
    end

    # Mocks any modules that need to be mocked
    @spec create_chunk_write_mocks() :: :ok
    defp create_chunk_write_mocks() do
      # For this test, we want to use the functions in the actual module
      # for the mock module, so we'll just have mock module share the
      # functionality
      Test.Common.stub_integer_file_mock()

      :ok
    end

    # Verifies the results of the chunking test
    @spec verify_chunk_results(
            Enum.t(),
            list(list(integer())),
            non_neg_integer(),
            chunk_stream_map()
          ) :: :ok
    defp verify_chunk_results(final_stream, test_chunks, gen, chunk_streams) do
      # Add a verification step to the stream to verify that the final stream
      # output is what we are expecting. Then start processing the stream
      final_stream
      |> Stream.with_index(1)
      |> Stream.each(fn chunk_item ->
        verify_stream_output(chunk_item, gen, chunk_streams)
      end)
      |> Stream.run()

      # Retrieve the actual chunks that were written to the test streams
      actual_chunks = chunks_from_test_streams(gen, chunk_streams)

      # The chunks are in order, so zip them together and verify that the expected
      # chunks were written to the output streams
      test_chunks
      |> Enum.zip(actual_chunks)
      |> Enum.each(fn {expected, actual} -> assert expected == actual end)

      :ok
    end

    @spec verify_stream_output(
            {{list(integer()), pid()}, pos_integer()},
            non_neg_integer(),
            chunk_stream_map()
          ) :: :ok
    defp verify_stream_output({{_, actual_chunk_stream}, chunk_num}, gen, test_streams) do
      expected_chunk_stream = get_test_chunk_stream(gen, chunk_num, test_streams)

      assert actual_chunk_stream == expected_chunk_stream

      :ok
    end

    # Extracts the chunks that were actually written from the test streams
    @spec chunks_from_test_streams(non_neg_integer(), chunk_stream_map()) :: list(list(integer()))
    defp chunks_from_test_streams(_, chunk_streams)
         when map_size(chunk_streams) == 0,
         do: []

    defp chunks_from_test_streams(gen, chunk_streams) do
      # Start with a range of chunk streams
      1..map_size(chunk_streams)
      # Map the cunk numbers to a collection of streams associated with those chunks
      |> Enum.map(fn chunk_num -> chunk_streams[{gen, chunk_num}] end)
      # Close the stream and extract the contents
      |> Enum.map(&get_string_stream_contents/1)
    end

    # Closes a test stream device and extracts the integer contents of the
    # stream device, returning it as a list of integers
    @spec get_string_stream_contents(chunk_stream_value()) :: list(String.t())
    defp get_string_stream_contents({device, _}) do
      # Close the test stream and get the data that was written to it
      {:ok, {_, written_data}} = StringIO.close(device)

      # Extract a list of integers from the data that was written
      TestStream.stream_data_to_integers(written_data)
    end

    # Retrieves a test chunk stream from the map of test chunks streams
    # This function forms the basis of the callback function that is passed into
    # create_chunks, so it contains assertions
    @spec get_test_chunk_stream(pos_integer(), non_neg_integer(), chunk_stream_map()) :: Enum.t()
    defp get_test_chunk_stream(gen, chunk_num, test_streams) do
      key = {gen, chunk_num}

      assert Map.has_key?(test_streams, key)

      {_, test_stream} = test_streams[key]

      test_stream
    end

    # Creates a test stream for every generation and chunk number combination
    # and returns the result in a map
    @spec create_test_chunk_streams(pos_integer(), non_neg_integer()) :: chunk_stream_map()
    defp create_test_chunk_streams(_, 0), do: %{}

    defp create_test_chunk_streams(gen, num_chunks) do
      test_streams =
        Enum.map(1..num_chunks, fn chunk_num ->
          {{gen, chunk_num}, TestStream.create_test_stream()}
        end)

      # We should end up with a stream map whose key is the {gen, chunk_num} tuple
      # and whose value is a tuple containing the stream and the stream device
      Enum.into(test_streams, %{})
    end
  end

  describe "num_chunks -" do
    test "Calculating the number of chunks when the integers are evenly divisible by the chunk size" do
      test_chunk_calculation(100, 10, 10)
    end

    test "Calculating the number of chunks when the integers are not evenly divisible by the chunk size" do
      test_chunk_calculation(100, 9, 12)
      test_chunk_calculation(23, 10, 3)
    end

    test "Calculating the number of chunks when the chunk size is larger than the integers" do
      test_chunk_calculation(18, 25, 1)
    end

    test "Calculating the number of chunks when the chunk size is 1" do
      test_chunk_calculation(15, 1, 15)
    end

    test "Calculating the number of chunks when the number of integers is 1" do
      test_chunk_calculation(1, 10, 1)
    end

    test "Calculating the number of chunks when the number of integers is 1 and the chunk size is 1" do
      test_chunk_calculation(1, 1, 1)
    end

    test "Calculating the number of chunks when the number of integers is 0" do
      test_chunk_calculation(0, 10, 0)
    end

    @spec test_chunk_calculation(non_neg_integer(), pos_integer(), non_neg_integer()) :: :ok
    defp test_chunk_calculation(integer_count, chunk_size, expected_chunk_count) do
      chunk_count = Chunk.num_chunks(integer_count, chunk_size)

      assert chunk_count == expected_chunk_count

      :ok
    end
  end

  # Creates chunks for use in testing
  @spec create_test_chunks(non_neg_integer(), pos_integer()) :: list(list(integer()))
  defp create_test_chunks(num_chunks, chunk_size) do
    TestData.random_integer_stream(-1000..1000)
    |> Stream.chunk_every(chunk_size)
    |> Enum.take(num_chunks)
  end
end
