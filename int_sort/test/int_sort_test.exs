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
      verify_chunk_file_results(
        chunk_files,
        test_integers,
        num_integers,
        chunk_size,
        chunk_gen,
        @output_dir
      )
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
            non_neg_integer(),
            String.t()
          ) :: :ok
    defp verify_chunk_file_results(
           chunk_files,
           test_integers,
           num_integers,
           chunk_size,
           chunk_gen,
           output_dir
         ) do
      # Verify the correct number of chunk files were created
      num_chunks = Test.Common.num_chunks(num_integers, chunk_size)

      # Calculate the expected file names
      expected_chunk_files = expected_file_names(chunk_gen, num_chunks, output_dir)

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
      chunk_file
      |> IntegerFile.integer_file_stream()
      |> IntegerFile.read_stream()
      |> Stream.zip(expected_chunk)
      |> Stream.each(fn {actual_integer, expected_integer} ->
        assert expected_integer == actual_integer
      end)
      |> Stream.run()
    end

    # Creates a list of expected chunk file names
    @spec expected_file_names(non_neg_integer(), non_neg_integer(), String.t()) ::
            list(String.t())
    defp expected_file_names(_, 0, _), do: []

    defp expected_file_names(gen, num_chunks, output_dir) do
      1..num_chunks
      |> Enum.map(fn chunk_num -> IntSort.gen_file_name(gen, chunk_num) end)
      |> Enum.map(fn file_name -> Path.join(output_dir, file_name) end)
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

  describe "total_merge" do
    test "Testing a single merge" do
      test_total_merge(10, 10)
    end

    test "Testing two merges" do
      test_total_merge(34, 10)
    end

    test "Testing with a large number of merges" do
      test_total_merge(1045, 2)
    end

    test "Testing with a merge count of 2" do
      test_total_merge(10, 2)
    end

    test "Testing with a merge count larger than number of files" do
      test_total_merge(8, 12)
    end

    test "Testing with a merge count equal to number of files" do
      test_total_merge(12, 12)
    end

    test "Testing with a merge count smaller than number of files" do
      test_total_merge(12, 7)
    end

    # Performs a total merge test
    defp test_total_merge(file_num, merge_count) do
      # Create the test files. These do not have to be real files because we aren't testing
      # the real file merge functionality. There are different tests for that.
      test_files = test_file_names(1, file_num)

      # Create the function that creates the name of the merge files
      {gen_file_name, gen_file_device} = gen_file_name_func()

      # Create the function that performs the merge of each merge generation. All the test
      # version of this function does is note which files that data that was passed to it
      {merge_file_gen, merge_device} = merge_file_gen_func()

      # Create the function that removes the unneeded intermediate files
      {remove_files, remove_files_device} = remove_files_func()

      # Create the function that is called every time an integer is merged
      {integer_merged, integer_merged_device} = integer_merged_func()

      # Create the function that is called every time a merge generation is completed
      {merge_gen_completed, merge_gen_completed_device} = merge_gen_completed_func()

      # Test the total merge process
      output_file =
        IntSort.total_merge(
          test_files,
          merge_count,
          gen_file_name,
          merge_file_gen,
          remove_files,
          integer_merged,
          merge_gen_completed
        )

      # Verify the results
      verify_total_merge_results(output_file, Enum.count(test_files), merge_count, %{
        gen_file: gen_file_device,
        merge: merge_device,
        remove: remove_files_device,
        integer_merged: integer_merged_device,
        merge_gen: merge_gen_completed_device
      })
    end

    # Creates a sequence of file names for use in the test
    defp test_file_names(gen, count) do
      1..count
      |> Enum.map(fn file_num -> IntSort.gen_file_name(gen, file_num) end)
    end

    # Creates and returns the test gen_file_name function along with the StringIO device it writes to
    @spec gen_file_name_func() ::
            {(non_neg_integer(), non_neg_integer() -> String.t()), IO.device()}
    defp gen_file_name_func() do
      gen_file_device = test_output_device()

      gen_file_name = fn gen, num ->
        IO.puts(gen_file_device, "#{gen} #{num}")

        IntSort.gen_file_name(gen, num)
      end

      {gen_file_name, gen_file_device}
    end

    # Create and returns the merge_file_gen function along with the StringIO device it writes to
    @spec merge_file_gen_func() ::
            {(Enum.t(),
              pos_integer(),
              (non_neg_integer() -> String.t()),
              (non_neg_integer() -> :ok) ->
                Enum.t()), IO.device()}
    defp merge_file_gen_func() do
      merge_device = test_output_device()

      merge_file_gen = fn files, merge_count, merge_file_name, integer_merged ->
        # Verify that the callback functions are actually functions with the expected arity
        assert is_function(merge_file_name, 1) == true
        assert is_function(integer_merged, 1) == true

        # Call the integer_merged function once to test that the function works correctly
        integer_merged.(1)

        # Return a new set of test files that similates merge
        output_file_count = ceil(Enum.count(files) / merge_count)

        # Generate the names of the files that would have resulted from this fake merge
        merge_files = 1..output_file_count |> Enum.map(merge_file_name)

        # Write the files, the merge count, and a merge file name to the StringIO device as JSON
        merge_data = %{merge_count: merge_count, files: files, merge_files: merge_files}

        IO.puts(merge_device, Poison.encode!(merge_data))

        # The merge files are the output
        merge_files
      end

      {merge_file_gen, merge_device}
    end

    # Create and returns the remove_files function along with the StringIO device it writes to
    @spec remove_files_func() :: {(Enum.t() -> :ok), IO.device()}
    defp remove_files_func() do
      remove_files_device = test_output_device()

      remove_files = fn files ->
        IO.puts(remove_files_device, Poison.encode!(files))

        :ok
      end

      {remove_files, remove_files_device}
    end

    # Create and returns the integer_merged function along with the StringIO device it writes to
    defp integer_merged_func() do
      integer_merged_device = test_output_device()

      integer_merged = fn gen, count ->
        merged_data = %{gen: gen, count: count}

        IO.puts(integer_merged_device, Poison.encode!(merged_data))

        :ok
      end

      {integer_merged, integer_merged_device}
    end

    # Create and returns the merge_gen_completed function along with the StringIO device it writes to
    @spec merge_gen_completed_func() ::
            {(non_neg_integer(), non_neg_integer() -> :ok), IO.device()}
    defp merge_gen_completed_func() do
      merge_gen_completed_device = test_output_device()

      merge_gen_completed = fn gen, file_count ->
        IO.puts(merge_gen_completed_device, Poison.encode!(%{gen: gen, file_count: file_count}))

        :ok
      end

      {merge_gen_completed, merge_gen_completed_device}
    end

    # Creates a test StringIO device and stream for writing to
    defp test_output_device() do
      {:ok, device} = StringIO.open("")

      device
    end

    # Verifies the total merge results
    @spec verify_total_merge_results(String.t(), non_neg_integer(), non_neg_integer(), %{
            gen_file: IO.device(),
            merge: IO.device(),
            remove: IO.device(),
            integer_merged: IO.device()
          }) :: :ok
    defp verify_total_merge_results(output_file, file_count, merge_count, test_devices) do
      # Reusable function for extracting the contents of a test device
      device_contents = fn key -> test_devices |> Map.get(key) |> StringIO.close() end

      # Calculate the number of merge generations
      merge_gens = ceil(log(file_count, merge_count)) + 1

      # Verify the name of the output file to ensure that it has the correct name
      verify_output_file(output_file, merge_gens)

      # Verify that the gen file name function was called the correct number of times
      {:ok, {_, gen_file_contents}} = device_contents.(:gen_file)

      verify_gen_files(gen_file_contents, merge_gens, file_count, merge_count)

      # Verify that the file merge function was called the correct number of times
      {:ok, {_, merge_file_contents}} = device_contents.(:merge)

      verify_merge_files(merge_file_contents, merge_gens, file_count, merge_count)

      # Verify that the remove file function was called correctly
      {:ok, {_, remove_file_contents}} = device_contents.(:remove)

      verify_remove_files(remove_file_contents, merge_gens, file_count, merge_count)

      # Verify that the integer_merged function was called correctly
      {:ok, {_, integer_merged_contents}} = device_contents.(:integer_merged)

      verify_integer_merged(integer_merged_contents, merge_gens)

      # Verify that the merge_gen_completed function was called correctly
      {:ok, {_, merge_gen_contents}} = device_contents.(:merge_gen)

      verify_merge_gen_completed(merge_gen_contents, merge_gens, file_count, merge_count)

      :ok
    end

    # Verifies the output file name
    @spec verify_output_file(String.t(), non_neg_integer()) :: :ok
    defp verify_output_file(output_file, merge_gens) do
      assert output_file == IntSort.gen_file_name(merge_gens, 1)
    end

    # Verifies that the gen file name function was called the correct number of times
    # with the correct data]
    @spec verify_gen_files(String.t(), non_neg_integer(), non_neg_integer(), non_neg_integer()) ::
            :ok
    defp verify_gen_files(gen_file_contents, merge_gens, file_count, merge_count) do
      expected_data =
        2..merge_gens
        |> Enum.map(fn gen -> {gen, ceil(file_count / pow(merge_count, gen - 1))} end)
        |> Enum.flat_map(fn {gen, count} -> Enum.map(1..count, &[gen, &1]) end)

      actual_data =
        gen_file_contents
        |> String.trim()
        |> String.split([" ", "\n"])
        |> Enum.map(&String.to_integer/1)
        |> Enum.chunk_every(2)

      compare(expected_data, actual_data)
    end

    # Verifies that the file merging function was called correctly for each merge generation
    @spec verify_merge_files(String.t(), non_neg_integer(), non_neg_integer(), non_neg_integer()) ::
            :ok
    defp verify_merge_files(merge_file_contents, merge_gens, file_count, merge_count) do
      expected_data =
        1..merge_gens
        # Create the file counts for each merge generation
        |> Enum.map(fn gen ->
          %{
            gen: gen,
            file_count: ceil(file_count / pow(merge_count, gen - 1)),
            merge_file_count: ceil(file_count / pow(merge_count, gen))
          }
        end)
        # Transform the counts into file names
        |> Enum.map(fn %{gen: gen, file_count: file_count, merge_file_count: merge_file_count} ->
          %{
            "files" =>
              1..file_count |> Enum.map(fn file_num -> IntSort.gen_file_name(gen, file_num) end),
            "merge_count" => merge_count,
            "merge_files" =>
              1..merge_file_count
              |> Enum.map(fn file_num -> IntSort.gen_file_name(gen + 1, file_num) end)
          }
        end)

      actual_data =
        merge_file_contents
        |> String.trim()
        |> String.split("\n")
        |> Enum.map(&Poison.decode!/1)

      compare(expected_data, actual_data)
    end

    # Verifies that the file removal function was called correctly for each merge generation
    @spec verify_remove_files(String.t(), non_neg_integer(), non_neg_integer(), non_neg_integer()) ::
            :ok
    defp verify_remove_files(remove_file_contents, merge_gens, file_count, merge_count) do
      expected_data =
        1..(merge_gens - 1)
        # Create the file counts for each merge generation
        |> Enum.map(fn gen -> {gen, ceil(file_count / pow(merge_count, gen - 1))} end)
        # Transform file count into file names
        |> Enum.map(fn {gen, count} ->
          1..count |> Enum.map(fn file_num -> IntSort.gen_file_name(gen, file_num) end)
        end)

      actual_data =
        remove_file_contents
        |> String.trim()
        |> String.split("\n")
        |> Enum.map(&Poison.decode!/1)

      compare(expected_data, actual_data)
    end

    # Verifies that the integer merged function was called correctly for each merge generation
    @spec verify_integer_merged(String.t(), non_neg_integer()) :: :ok
    defp verify_integer_merged(integer_merged_contents, merge_gens) do
      expected_data =
        2..merge_gens
        # Create the integer counts for each merge generation. For test purposes, only one integer
        # is in each merge generation
        |> Enum.map(fn gen -> %{"gen" => gen, "count" => 1} end)

      actual_data =
        integer_merged_contents
        |> String.trim()
        |> String.split("\n")
        |> Enum.map(&Poison.decode!/1)

      compare(expected_data, actual_data)
    end

    # Verifies that the merge_gen_completed function was called correctly for each merge generation
    @spec verify_merge_gen_completed(
            String.t(),
            non_neg_integer(),
            non_neg_integer(),
            non_neg_integer()
          ) :: :ok
    defp verify_merge_gen_completed(merge_gen_contents, merge_gens, file_count, merge_count) do
      expected_data =
        2..merge_gens
        # Create the file counts for each merge generation
        |> Enum.map(fn gen ->
          %{
            "gen" => gen,
            "file_count" => ceil(file_count / pow(merge_count, gen - 1))
          }
        end)

      actual_data =
        merge_gen_contents
        |> String.trim()
        |> String.split("\n")
        |> Enum.map(&Poison.decode!/1)

      compare(expected_data, actual_data)
    end

    # Compares a collection of data to another collection of data and asserts that they contain
    # the same data
    @spec compare(any(), any()) :: :ok
    defp compare(expected_data, actual_data) do
      expected_data
      |> Enum.zip(actual_data)
      |> Enum.each(fn {expected, actual} -> assert expected == actual end)
    end

    # TODO: Replace this with a Math library dependency

    @doc """
    Calculates the base-*b* logarithm of *x*
    Note that variants for the most common logarithms exist that are faster and more precise.
    See also `Math.log/1`, `Math.log2/1` and `Math.log10/1`.
    ## Examples
        iex> Math.log(5, 5)
        1.0
        iex> Math.log(20, 2) <~> Math.log2(20)
        true
        iex> Math.log(20, 10) <~> Math.log10(20)
        true
        iex> Math.log(2, 4)
        0.5
        iex> Math.log(10, 4)
        1.6609640474436813
    """
    # @spec log(x, number) :: float
    def log(x, x), do: 1.0

    def log(x, b) do
      :math.log(x) / :math.log(b)
    end

    @spec pow(number, number) :: number
    def pow(x, n)

    def pow(x, n) when is_integer(x) and is_integer(n), do: _pow(x, n)

    # Float implementation. Uses erlang's math library.
    def pow(x, n) do
      :math.pow(x, n)
    end

    # Integer implementation. Uses Exponentiation by Squaring.
    defp _pow(x, n, y \\ 1)
    defp _pow(_x, 0, y), do: y
    defp _pow(x, 1, y), do: x * y
    defp _pow(x, n, y) when n < 0, do: _pow(1 / x, -n, y)
    defp _pow(x, n, y) when rem(n, 2) == 0, do: _pow(x * x, div(n, 2), y)
    defp _pow(x, n, y), do: _pow(x * x, div(n - 1, 2), x * y)
  end
end
