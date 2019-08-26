defmodule LargeSortShared.Test.IntegerFile do
  use ExUnit.Case
  doctest LargeSort.Shared.IntegerFile

  alias LargeSort.Shared.IntegerFile

  @test_integer_file_name "test_integer_file.txt"

  #Tests integer_file_stream
  describe "integer_file_stream -" do
    setup do
      on_exit(&delete_test_file/0)
    end

    test "Create integer file stream and write to it" do
      #Create the file stream and write some test data to the file stream
      test_data = 1..10
      file_stream = IntegerFile.integer_file_stream(@test_integer_file_name)

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
      file_stream = IntegerFile.integer_file_stream(@test_integer_file_name)

      file_stream
      |> write_data_to_stream(test_data)
      |> Stream.run()

      #Create a new file stream, which we will use to read from the file
      file_stream = IntegerFile.integer_file_stream(@test_integer_file_name)

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
      file_stream = IntegerFile.integer_file_stream(@test_integer_file_name)

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

    #Creates a stream that emits integer file lines test data
    @spec integer_line_stream(Enumerable.t()) :: Enumerable.t()
    defp integer_line_stream(integer_stream) do
      integer_stream
      |> Stream.map(&Integer.to_string/1)
      |> Stream.map(&(&1 <> "\n"))
    end
  end

  describe "integer_count -" do
    test "Testing with multiple lines of integers" do
      data = [
        "234\n",
        "3\n",
        "22\n",
        "-4\n",
        "8\n",
        "-33243\n",
        "87\n",
        "-93\n",
        "0\n"
      ]

      test_integer_count(data, length(data))
    end

    test "Testing with multiple lines of text" do
      data = [
        "The bibble babble bubble\n",
        "Fluffykins\n",
        "-1\n",
        "Snorlax\n",
        "O93nssLL",
        "\n",
        "",
        "FizzBuzz\n"
      ]

      test_integer_count(data, length(data))
    end

    test "Testing with an single line of integers" do
      data = [ "58\n" ]

      test_integer_count(data, length(data))
    end

    test "Testing with no lines of integers" do
      data = []

      test_integer_count(data, length(data))
    end

    @spec test_integer_count(Enum.t(), non_neg_integer()) :: :ok
    defp test_integer_count(data, expected_count) do
      actual_count = IntegerFile.integer_count(data)

      assert actual_count == expected_count
    end
  end

  describe "read_device - " do
    @non_existent_file "non_existent_file.txt"

    test "Creating a read device from an existing file" do
      test_data = create_test_file(@test_integer_file_name, 10)

      file = IntegerFile.read_device(@test_integer_file_name)

      expected_line = Integer.to_string(hd(test_data)) <> "\n"
      first_line = IO.read(file, :line)

      assert(first_line == expected_line)

      File.close(file)

      delete_test_file(@test_integer_file_name)
    end

    test "Creating a read device from a non-existent file" do
      assert_raise File.Error, fn ->
        IntegerFile.read_device(@non_existent_file)
      end
    end
  end

  describe "write_device - " do
    @non_existent_file "non_existent_file.txt"

    test "Creating a write device for an existing file" do
      # Create a file with test data
      create_test_file(@test_integer_file_name, 10)

      # Run the test with the file
      do_write_test(@test_integer_file_name)
    end

    test "Creating a write device for a non-existent file" do
      do_write_test(@non_existent_file)
    end

    defp do_write_test(file_name) do
      # Create a write device for the file
      file = IntegerFile.write_device(file_name)

      # Write a line to the file
      data_line = "34\n"

      IO.write(file, data_line)

      File.close(file)

      # Read the line from the file and verify that it is the same
      # one that was written
      file = IntegerFile.read_device(file_name)

      first_line = IO.read(file, :line)
      assert(first_line == data_line)

      # Read the next line of the file and verify that it is the end of the file
      next_line = IO.read(file, :line)
      assert(next_line == :eof)

      File.close(file)

      # Clean up by deleting the file
      delete_test_file(file_name)
    end
  end

  # Creates a test integer file filled with random integer data
  defp create_test_file(file_name, count) do
    # Create the test data
    test_data = test_integer_stream(count) |> Enum.to_list()

    # Create the test file
    file_stream = IntegerFile.integer_file_stream(file_name)

    # Stream the data to the file
    file_stream
    |> write_data_to_stream(test_data)
    |> Stream.run()

    test_data
  end

  #Deletes the test file
  defp delete_test_file() do
    delete_test_file(@test_integer_file_name)
  end

  defp delete_test_file(file_name) do
    File.rm!(file_name)
  end

  # Creates a random integer stream
  @spec random_integer_stream(Range.t()) :: Enumerable.t()
  defp random_integer_stream(integer_range) do
    Stream.repeatedly(fn -> Enum.random(integer_range) end)
  end

  #Creates a stream that emits random test integers up to
  #the specified number of integers
  defp test_integer_stream(count) do
    random_integer_stream(-1000..1000)
    |> Stream.take(count)
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
