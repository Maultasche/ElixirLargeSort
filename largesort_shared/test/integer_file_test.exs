defmodule LargeSortShared.Test.IntegerFile do
  use ExUnit.Case
  doctest LargeSort.Shared.IntegerFile

  alias LargeSort.Shared.IntegerFile

  @test_integer_file_name "test_integer_file.txt"

  #Tests create_integer_file_stream
  describe "create_integer_file_stream -" do
    setup do
      on_exit(&delete_test_file/0)
    end

    test "Create integer file stream and write to it" do
      #Create the file stream and write some test data to the file stream
      test_data = 1..10
      file_stream = IntegerFile.create_integer_file_stream(@test_integer_file_name)

      file_stream
      |> write_data_to_stream(test_data)
      |> Stream.run()

      #Verify that the stream was created correctly by verifying the data that was
      #written to the file stream
      verify_integer_file(@test_integer_file_name, test_data)
    end

    test "Create integer file stream and read from it" do
      #Create the file stream and write some test data to the file stream
      test_data = 1..10
      file_stream = IntegerFile.create_integer_file_stream(@test_integer_file_name)

      file_stream
      |> write_data_to_stream(test_data)
      |> Stream.run()

      #Create a new file stream, which we will use to read from the file
      file_stream = IntegerFile.create_integer_file_stream(@test_integer_file_name)

      #Verify that the stream can read from the file correctly
      verify_integer_stream(file_stream, test_data)
    end
  end

  describe "write_integers_to_stream -" do
    setup do
      on_exit(&delete_test_file/0)
    end

    test "Write a small number of integers to a stream" do
      test_write_integers_to_stream(-100..100)
    end

    test "Write a large number of integers to a stream" do
      test_write_integers_to_stream(1..100_000)
    end

    test "Write a single integer to a stream" do
      test_write_integers_to_stream([0])
    end

    test "Write an empty enumerable to a stream" do
      test_write_integers_to_stream([])
    end

    defp test_write_integers_to_stream(test_data) do
      #Create the file stream
      file_stream = IntegerFile.create_integer_file_stream(@test_integer_file_name)

      #Write the test data to the file stream
      test_data
      |> IntegerFile.write_integers_to_stream(file_stream)
      |> Stream.run()

      #Verify that the data that was written to the file stream correctly
      verify_integer_file(@test_integer_file_name, test_data)
    end
  end

  describe "read_stream -" do
    test "Read a small number of integers from a stream" do
      test_read_stream(10)
    end

    test "Read a moderate number of integers from a stream" do
      test_read_stream(1000)
    end

    test "Read a large number of integers from a stream" do
      test_read_stream(10000)
    end

    test "Read a single integer from a stream" do
      test_read_stream(1)
    end

    test "Read zero integers from a stream" do
      test_read_stream(1)
    end

    #Tests read_stream with a particular number of integers
    defp test_read_stream(count) do
      # Create the test integer data stream
      test_data = test_integer_stream(count) |> Enum.to_list()

      # Create an integer line stream from the test data
      test_data
      |> integer_line_stream()
      # Create an integer read stream from the test data stream
      |> IntegerFile.read_stream()
      # Verify that the correct data is read from the stream
      |> Stream.zip(test_data)
      |> Stream.each(fn {actual_integer, expected_integer} ->
        assert actual_integer == expected_integer
      end)
    end

    #Creates a stream that emits random test integers up to
    #the specified number of integers
    defp test_integer_stream(count) do
      random_integer_stream(-1000..1000)
      |> Stream.take(count)
    end

    #Creates a stream that emits integer file lines test data
    @spec integer_line_stream(Enumerable.t()) :: Enumerable.t()
    defp integer_line_stream(integer_stream) do
      integer_stream
      |> Stream.map(&Integer.to_string/1)
      |> Stream.map(&(&1 <> "\n"))
    end

    # Creates a random integer stream
    @spec random_integer_stream(Range.t()) :: Enumerable.t()
    defp random_integer_stream(integer_range) do
      Stream.repeatedly(fn -> Enum.random(integer_range) end)
    end
  end

  #Deletes the test file
  defp delete_test_file() do
    File.rm!(@test_integer_file_name)
  end

  #Writes an enumerable containing integers to a stream
  defp write_data_to_stream(stream, data) do
    data
    |> Stream.map(&Integer.to_string/1)
    |> Stream.map(&(&1 <> "\n"))
    |> Stream.into(stream)
  end

  #Verifies that an integer file contains the expected contents
  defp verify_integer_file(path, expected_integers) do
    File.stream!(path, [:utf8], :line)
    |> verify_integer_stream(expected_integers)
  end

  #Verifies that a stream contains the expected contents
  defp verify_integer_stream(stream, expected_integers) do
    stream
    |> Stream.map(&String.trim/1)
    |> Stream.map(&String.to_integer/1)
    |> Stream.zip(expected_integers)
    |> Stream.each(&compare_integers/1)
    |> Stream.run()
  end

  #Compares the integers in a tuple to each other
  defp compare_integers({integer1, integer2}) do
    assert integer1 == integer2
  end
end
