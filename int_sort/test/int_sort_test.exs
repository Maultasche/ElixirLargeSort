defmodule IntSort.Test do
  use ExUnit.Case
  import Mox

  doctest IntSort

  alias LargeSort.Shared.IntegerFile
  alias IntSort.Test.Common
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
      test_integers = Test.Common.create_test_integers(num_integers)
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
      Test.Common.stub_integer_file_mock()

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

  describe "merge_intermediate_files" do
    @test_file_dir "test_files"

    test "Merging multiple intermediate files of the same size" do
      test_data = [
        [-3, -1, 0, 5, 12, 15, 22, 23, 23, 25],
        [-10, -8, -3, -1, 0, 1, 2, 6, 7, 11],
        [-21, -19, -12, 4, 9, 13, 14, 19, 21, 23]
      ]

      test_file_merging(test_data, 10)
    end

    test "Test merging only negative numbers" do
      test_data = [
        [-30, -22, -15, -8],
        [-10, -8, -3, -1],
        [-21, -19, -12, -4],
        [-21, -11, -10, -9]
      ]

      test_file_merging(test_data, 10)
    end

    test "Test merging only positive numbers" do
      test_data = [
        [8, 15, 22, 30, 34],
        [1, 3, 133, 220, 1013],
        [4, 19, 22, 445, 87],
        [7, 22, 35, 48, 53],
        [2, 3, 10, 11, 12]
      ]

      test_file_merging(test_data, 10)
    end

    test "Test merging positive and negative numbers" do
      test_data = [
        [-22, -15, 22],
        [1, 5, 8],
        [-4, 0, 87],
        [-7, -3, -1],
        [-2, 0, 10]
      ]

      test_file_merging(test_data, 10)
    end

    test "Merging multiple intermediate files into a single file" do
      test_data = [
        [-22, -15, 22],
        [1, 5, 8],
        [-4, 0, 87],
        [-7, -3, -1],
        [-2, 0, 10]
      ]

      test_file_merging(test_data, Enum.count(test_data))
    end

    test "Merging multiple intermediate files into a multiple files" do
      test_data = [
        [8, 15, 22, 30, 34],
        [1, 3, 133, 220, 1013],
        [4, 19, 22, 445, 87],
        [7, 22, 35, 48, 53],
        [2, 3, 10, 11, 12]
      ]

      test_file_merging(test_data, 3)
    end

    test "Merging intermediate files of varying sizes" do
      test_data = [
        [-3, -1, 0, 5, 12, 15, 22, 23, 23, 25],
        [6, 7],
        [],
        [-10, -8, -3, -1, 0, 1, 2, 6, 7, 11],
        [-21, -19, -12, 4, 9, 13, 21, 23],
        [8],
        [-3, -1, 0, 7]
      ]

      test_file_merging(test_data, 8)
    end

    test "Merging a single intermediate file" do
      test_data = [
        [-3, -1, 0, 7]
      ]

      test_file_merging(test_data, 5)
    end

    test "Merging a single intermediate file containing no data" do
      test_data = [
        []
      ]

      test_file_merging(test_data, 5)
    end

    @tag :merge
    test "Test with intermediate files containing random integers" do
      file_count = 87

      # Create the test data for the test files where the number of integers in
      # each test file randomly varies from 1 to 1000
      test_data =
        1..file_count
        |> Enum.map(fn _ -> Common.create_test_integers(Enum.random(1..10)) end)

      test_file_merging(test_data, 10, true)
    end

    test "Test with the progress callback" do
      test_data = [
        [-3, -1, 0, 5, 12, 15, 22, 23, 23, 25],
        [6, 7],
        [],
        [-10, -8, -3, -1, 0, 1, 2, 6, 7, 11],
        [-21, -19, -12, 4, 9, 13, 21, 23],
        [8],
        [-3, -1, 0, 7]
      ]

      test_file_merging(test_data, 12, true)
    end

    @spec test_file_merging(Enum.t(), pos_integer(), boolean()) :: :ok
    defp test_file_merging(file_contents, merge_count, test_callback \\ false) do
      # Do any necessary mocking
      create_merge_mocks()

      # Create the test files for merging
      file_names =
        file_contents
        |> Enum.with_index(1)
        |> Enum.map(fn {file_contents, file_num} -> create_test_file(file_contents, file_num) end)

      # Calculate the expected results
      expected_merges = expected_results(file_contents, merge_count)

      # Retrieve the integer IO device for callback testing
      integer_device = integer_io_device(test_callback)

      # Run the intermediate file merge
      merged_files =
        test_merge_intermediate_files(
          file_names,
          merge_count,
          &merge_file_name/1,
          test_callback,
          integer_device
        )

      # Verify the results
      verify_merge_results(expected_merges, merged_files)

      # Verify the results of the merge callback
      verify_merge_callback(integer_device, expected_merges)

      # Delete the test directory
      File.rm_rf!(@test_file_dir)

      :ok
    end

    # Runs the merge intermediate files step, calling the function that is being tested.
    @spec test_merge_intermediate_files(
            Enum.t(),
            pos_integer(),
            (non_neg_integer() -> String.t()),
            boolean(),
            IO.device()
          ) :: Enum.t()
    defp test_merge_intermediate_files(file_names, merge_count, merge_file_name, false, _) do
      IntSort.merge_intermediate_files(file_names, merge_count, merge_file_name)
      |> Enum.to_list()
    end

    defp test_merge_intermediate_files(
           file_names,
           merge_count,
           merge_file_name,
           true,
           integer_device
         ) do
      # Set up the callback that will log calls to the integer device
      merge_callback = fn count -> IntegerFile.write_integer(integer_device, count) end

      IntSort.merge_intermediate_files(file_names, merge_count, merge_file_name, merge_callback)
      |> Enum.to_list()
    end

    # Creates a file name for a test file
    @spec file_name(pos_integer()) :: String.t()
    defp file_name(file_number) do
      Path.join(@test_file_dir, "testfile#{file_number}.txt")
    end

    # Creates a file name for a merge file
    @spec merge_file_name(pos_integer()) :: String.t()
    defp merge_file_name(group_number) do
      Path.join(@test_file_dir, "mergefile#{group_number}.txt")
    end

    # Creates a test file with the specified integer contents
    @spec create_test_file(Enum.t(), String.t()) :: String.t()
    defp create_test_file(file_content, file_num) do
      file_name = file_name(file_num)

      Test.Common.create_integer_file(file_content, file_name)
    end

    # Takes a collection of integer collections and a merge count and produces
    # the expected result of merging those integer collections in groups the size
    # of merge_count
    @spec expected_results(Enum.t(), pos_integer()) :: Enum.t()
    defp expected_results(file_contents, merge_count) do
      file_contents
      |> Enum.chunk_every(merge_count)
      |> Enum.map(&expected_results(&1))
    end

    # Takes a collection of integer collections and produces the expected
    # result of merging those integer collections
    @spec expected_results(Enum.t()) :: Enum.t()
    defp expected_results(file_contents) do
      file_contents
      |> Enum.concat()
      |> Enum.sort()
    end

    # Verifies that the expected results match the actual merge results in the merge files
    @spec verify_merge_results(Enum.t(), Enum.t()) :: :ok
    defp verify_merge_results(expected_merges, merged_files) do
      merged_files
      # Verify that each merged file actually exists
      |> Stream.each(fn file -> assert File.exists?(file) == true end)
      # Load the contents of each file
      |> Enum.map(fn file ->
        file_contents = IntegerFile.integer_file_stream(file) |> Enum.to_list()

        {file, file_contents}
      end)
      # Zip the expected and actual merge results together
      |> Enum.zip(expected_merges)
      # Compare the expected and actual merge results
      |> Enum.each(fn {{file, actual_results}, expected_results} ->
        assert Enum.count(actual_results) == Enum.count(expected_results),
               "The file #{file} does not contain the expected number of integers"
      end)
    end

    # When testing callback functionality, verifies that the callback was called correctly
    @spec verify_merge_callback(IO.device(), Enum.t()) :: :ok
    defp verify_merge_callback(nil, _), do: :ok

    defp verify_merge_callback(integer_device, expected_merges) do
      # Calculate the number of expected integers in the merges
      total_count =
        expected_merges
        # Convert each collection of integers into a count
        |> Enum.map(&Enum.count/1)
        # Add all the counts together to get the total count
        |> Enum.sum()

      # Retrieve the counts from the integer device
      {:ok, {_, device_contents}} = StringIO.close(integer_device)

      callback_values =
        device_contents
        |> String.split()
        |> Enum.map(&String.to_integer/1)

      # Verify the counts are correct. The count is the number of integers that
      # have been merged, so the count should start at one and end at the number
      # of integers being merged.
      1..total_count
      |> Enum.zip(callback_values)
      |> Enum.each(fn {expected_value, actual_value} ->
        assert expected_value == actual_value
      end)
    end

    # Creates any mocks needed to run the merge intermediate file testing
    defp create_merge_mocks() do
      Test.Common.stub_integer_file_mock()
    end

    # Creates a StringIO device to use in callback testing depending on whether
    # callback testing is being performed
    @spec integer_io_device(boolean()) :: IO.device()
    defp integer_io_device(false), do: nil

    defp integer_io_device(true) do
      {:ok, device} = StringIO.open("")

      device
    end
  end
end
