defmodule IntSort.Test do
  use ExUnit.Case
  import Mox

  doctest IntSort

  alias LargeSort.Shared.IntegerFile
  alias LargeSort.Shared.TestData
  alias IntSort.Test

  describe "gen_file_name -" do
    test "Create a gen file name" do
      file_name = IntSort.gen_file_name(3, 7)

      assert file_name == "gen3-7.txt"
    end
  end

  describe "create_chunk_files -" do
    @input_file "test_data/test_integers.txt"
    @output_dir "test_data/"

    setup do
      on_exit(&delete_test_data/0)
    end

    test "Creating chunk files with a moderate number of integers with moderate chunk size with integers evenly divisible by chunk size" do
      test_create_chunk_files(1000, 50)
    end

    test "Creating chunk files with a moderate number of integers that are not evenly divisible by chunk size " do
      test_create_chunk_files(1000, 23)
    end

    test "Creating a chunk files for a large number of integers with moderate chunk size " do
      test_create_chunk_files(10000, 100)
    end

    test "Creating chunk files for a large number of integers with small chunk size " do
      test_create_chunk_files(10000, 5)
    end

    test "Creating chunk files for a small number of integers with small chunk size " do
      test_create_chunk_files(10, 2)
    end

    test "Creating chunk files for integers with a chunk size of 1" do
      test_create_chunk_files(100, 1)
    end

    test "Creating chunk files for a number of integers equals chunk size" do
      test_create_chunk_files(10, 10)
    end

    test "Creating chunk files where the number of integers is smaller than chunk size" do
      test_create_chunk_files(10, 20)
    end

    test "Creating chunk files for zero integers" do
      test_create_chunk_files(0, 10)
    end

    @spec test_create_chunk_files(non_neg_integer(), pos_integer()) :: :ok
    defp test_create_chunk_files(num_integers, chunk_size) do
      chunk_gen = 1

      # Create an integer file for use in testing
      test_integers = create_test_integers(num_integers)
      IntGen.create_integer_file(@input_file, num_integers, test_integers)

      # Create any mocks that need to be created
      create_chunk_file_mocks()

      # Create chunk files from the integer file
      chunk_files = IntSort.create_chunk_files(@input_file, @output_dir, chunk_size, chunk_gen)

      # Verify the results
      verify_chunk_file_results(chunk_files, test_integers, num_integers, chunk_size, chunk_gen)
    end

    # Mocks any modules that need to be mocked
    @spec create_chunk_file_mocks() :: :ok
    defp create_chunk_file_mocks() do
      # For this test, we want to use the functions in the actual module
      # for the mock module, so we'll just have mock module share the
      # functionality
      stub_with(IntSort.IntegerFileMock, LargeSort.Shared.IntegerFile)

      :ok
    end

    # Verifies that the chunk files were created correctly
    @spec verify_chunk_file_results(
            Enum.t(),
            Enum.t(),
            non_neg_integer(),
            pos_integer(),
            non_neg_integer()
          ) :: :ok
    defp verify_chunk_file_results(
           chunk_files,
           test_integers,
           num_integers,
           chunk_size,
           chunk_gen
         ) do
      # Verify the correct number of chunk files were created
      num_chunks = Test.Common.num_chunks(num_integers, chunk_size)

      # Calculate the expected file names
      expected_chunk_files = expected_file_names(chunk_gen, num_chunks)

      # Calculate the expected chunks
      expected_chunks = Test.Common.expected_sorted_chunks(test_integers, chunk_size)

      # Verify the generated chunk files
      num_chunk_files =
        Stream.zip([chunk_files, expected_chunk_files, expected_chunks])
        |> Stream.each(fn {chunk_file, expected_chunk_file, expected_chunk} ->
          assert chunk_file == expected_chunk_file

          verify_chunk_file(chunk_file, expected_chunk)
        end)
        |> Enum.count()

      # Finally verify that the number of chunk files we got matches the number of
      # chunk files we expected
      assert num_chunk_files == num_chunks

      :ok
    end

    # Verifies an individual chunk file
    @spec verify_chunk_file(String.t(), list(integer)) :: :ok
    defp verify_chunk_file(chunk_file, expected_chunk) do
      # Open a file stream for the chunk file
      Path.join(@output_dir, chunk_file)
      |> IntegerFile.integer_file_stream()
      |> IntegerFile.read_stream()
      |> Stream.zip(expected_chunk)
      |> Stream.each(fn {actual_integer, expected_integer} ->
        assert expected_integer == actual_integer
      end)
      |> Stream.run()
    end

    # Creates a list of expected chunk file names
    @spec expected_file_names(non_neg_integer(), non_neg_integer()) :: list(String.t())
    defp expected_file_names(_, 0), do: []

    defp expected_file_names(gen, num_chunks) do
      1..num_chunks
      |> Enum.map(fn chunk_num -> IntSort.gen_file_name(gen, chunk_num) end)
    end

    # Creates a stream of random integers for use in testing
    @spec create_test_integers(non_neg_integer()) :: Enum.t()
    defp create_test_integers(num_integers) do
      TestData.random_integer_stream(-1000..1000)
      |> Enum.take(num_integers)
    end

    # Deletes the test data directory
    defp delete_test_data() do
      File.rm_rf!(@output_dir)
    end
  end

  describe "integer_count -" do
    @test_input_file "integers.txt"
    @test_integer_count 121

    test "Testing the integer count" do
      integer_count_test()
    end

    @spec integer_count_test() :: :ok
    defp integer_count_test() do
      # Do the mocks
      create_integer_count_mocks(@test_input_file, @test_integer_count)

      # Call the integer_count function
      count = IntSort.integer_count(@test_input_file)

      # Verify the count is what is expected
      assert count == @test_integer_count

      # Verify the mock expectations
      verify!()
    end

    # Mocks any modules that need to be mocked
    @spec create_integer_count_mocks(String.t(), non_neg_integer()) :: :ok
    defp create_integer_count_mocks(input_file, integer_count) do

      IntSort.IntegerFileMock
      # The mock method will verify the parameter and pass an enumerable containing
      # an atom back as the file stream
      |> expect(
        :integer_file_stream,
        fn file ->
          assert file == input_file
          [:file_stream]
        end
      )
      # The mock method will verify that the parameter is the mock file stream
      # and return the specified integer count
      |> expect(
        :integer_count,
        fn stream ->
          assert stream == [:file_stream]
          integer_count
        end
      )
    end
  end
end
