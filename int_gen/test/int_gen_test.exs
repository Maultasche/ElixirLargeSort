defmodule IntGenTest do
  use ExUnit.Case, async: true
  doctest IntGen

  import Mox

  alias LargeSort.Shared.TestStream

  @num_stream_elements 1000

  describe "random_integer_stream -" do
    test "Generates integers" do
      random_stream = IntGen.random_integer_stream(1..100)

      random_stream
      |> Enum.take(@num_stream_elements)
      |> test_integers()
    end

    test "Testing range with only positive numbers" do
      test_range(1..100)
    end

    test "Testing range with positive and negative numbers" do
      test_range(-10..10)
    end

    test "Testing range with negative numbers" do
      test_range(-87..-12)
    end

    test "Testing range that starts with 0" do
      test_range(0..23)
    end

    test "Testing range that ends with 0" do
      test_range(-145..0)
    end

    test "Testing range of size 2" do
      test_range(4..5)
    end

    test "Testing range of size 1" do
      test_range(12..12)
    end

    test "Testing range 0..0" do
      test_range(0..0)
    end

    test "Testing descending range" do
      test_range(10..-2)
    end

    test "Testing large range" do
      test_range(-1_000_000_000..1_000_000_000)
    end

    defp test_integers(enumerable) do
      Enum.each(enumerable, fn element -> assert is_integer(element) end)
    end

    defp test_range(integer_range) do
      random_stream = IntGen.random_integer_stream(integer_range)

      random_stream
      |> Enum.take(@num_stream_elements)
      |> Enum.each(fn integer -> integer in integer_range end)
    end
  end

  describe "create_integer_file -" do
    @test_file "test_integer_file.txt"
    @small_num_integers 100
    @large_num_integers 10000

    test "Create a file with a small number of random integers" do
      integer_range = -10..10

      random_stream = IntGen.random_integer_stream(integer_range)

      test_integer_file_with_random_stream(
        @test_file,
        @small_num_integers,
        random_stream,
        integer_range
      )
    end

    test "Create a file with a large number of random integers" do
      integer_range = -1000..1000

      random_stream = IntGen.random_integer_stream(integer_range)

      test_integer_file_with_random_stream(
        @test_file,
        @large_num_integers,
        random_stream,
        integer_range
      )
    end

    test "Create a file with positive integers" do
      integers = [3, 12, 4, 2, 32, 128, 12, 8]

      test_integer_file_with_specific_integers(integers, length(integers))
    end

    test "Create a file with negative integers" do
      integers = [-13, -1, -4, -23, -83, -3, -43, -8]

      test_integer_file_with_specific_integers(integers, length(integers))
    end

    test "Create a file with positive and negative integers" do
      integers = [332, -1, 4, 18, -23, 1345, 0, -83, -3, -43, 19, -8, 2]

      test_integer_file_with_specific_integers(integers, length(integers))
    end

    test "Create a file using a subset of a list of integers" do
      integers = [332, -1, 4, 18, -23, 1345, 0, -83, -3, -43, 19, -8, 2]

      test_integer_file_with_specific_integers(integers, 6)
    end

    test "Create a file with a single integer" do
      integers = [5]

      test_integer_file_with_specific_integers(integers, length(integers))
    end

    test "Create a file with zero random integers" do
      integers = []

      test_integer_file_with_specific_integers(integers, length(integers))
    end

    # Tests creating an integers file with a specific list of integers
    @spec test_integer_file_with_specific_integers(list(integer()), integer()) :: :ok
    defp test_integer_file_with_specific_integers(integers, count) do
      result = test_integer_file(@test_file, count, integers, &verify_written_integers/2)

      assert result == :ok

      :ok
    end

    # Test creating an integer file with a random stream
    @spec test_integer_file_with_random_stream(
            String.t(),
            integer(),
            Enumerable.t(),
            Range.t()
          ) :: :ok
    defp test_integer_file_with_random_stream(
           path,
           num_of_integers,
           random_stream,
           integer_range
         ) do
      verify_integers = fn _, written_data ->
        verify_written_integers_range(num_of_integers, integer_range, written_data)
      end

      result = test_integer_file(path, num_of_integers, random_stream, verify_integers)

      assert result == :ok

      :ok
    end

    # Tests creating an integer file
    defp test_integer_file(path, num_of_integers, integers, verify) do
      # Create the test stream
      {test_device, test_stream} = TestStream.create_test_stream()

      # Setup the IntegerFile mock
      IntGen.IntegerFileMock
      |> expect(
        :integer_file_stream,
        fn actual_path ->
          verify_create_file_stream(path, actual_path, test_stream)
        end
      )
      |> expect(
        :write_integers_to_stream,
        fn enumerable, out_stream ->
          verify_write_integers_to_stream(enumerable, test_stream, out_stream)
        end
      )

      # Call the test method and verify the results
      result = IntGen.create_integer_file(path, num_of_integers, integers)

      assert result == :ok

      # Close the test stream and get the data that was written to it
      {:ok, {_, written_data}} = StringIO.close(test_device)

      # Call the verification method
      verify.(Enum.take(integers, num_of_integers), written_data)
    end

    # Verifies the create file stream parameters and returns the test stream
    defp verify_create_file_stream(expected_path, actual_path, test_stream) do
      assert expected_path == actual_path

      test_stream
    end

    # Verifies the write_integers_to_stream parameters and write space-separated
    # integers to the output stream. Since the integers may be part of a stream
    # (particularly a random integer stream), we won't verify the integers
    # now. We'll just write them to the test stream.
    defp verify_write_integers_to_stream(
           integers,
           expected_stream,
           actual_stream
         ) do
      assert expected_stream == actual_stream

      # Separate each integer with a space
      integers
      |> Stream.map(fn integer -> Integer.to_string(integer) <> " " end)
      |> Stream.into(actual_stream)
    end

    # Verifies that the integers were written correctly
    defp verify_written_integers(integers, written_data) do
      written_integers = TestStream.stream_data_to_integers(written_data, " ")

      # Verify that the exact integer order matches
      written_integers
      |> Enum.zip(integers)
      |> Enum.each(fn {integer1, integer2} -> assert integer1 == integer2 end)

      # Assert that the number of integers is as expected
      assert Enum.count(integers) == Enum.count(written_integers)

      :ok
    end

    # Verifies that the correct number of integers within a certain range
    # were written
    defp verify_written_integers_range(expected_count, integer_range, written_data) do
      written_integers = TestStream.stream_data_to_integers(written_data, " ")

      # Assert that the number of integers is as expected
      assert Enum.count(written_integers) == expected_count

      # Assert that each integer is in the expected range
      Enum.each(written_integers, fn integer -> assert integer in integer_range end)
    end
  end
end
