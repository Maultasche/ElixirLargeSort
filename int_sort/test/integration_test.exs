defmodule IntSort.IntegrationTests do
  use ExUnit.Case, async: true

  alias LargeSort.Shared.IntegerFile
  alias IntSort.Test.Common
  alias IntSort


  describe "Integration Tests -" do
    @input_file "test_data/test_integers.txt"
    @output_file "test_data/sorted_integers.txt"
    @test_dir "test_data"

    test "Sorting an empty file" do
      test_data = []

      sort_test(test_data, 0, 10)
    end

    test "Sorting a single integer" do
      num_integers = 1

      test_data = Common.create_test_integers(num_integers)

      sort_test(test_data, num_integers, 10)
    end

    test "Sorting 20 numbers in multiple chunks" do
      num_integers = 20

      test_data = Common.create_test_integers(num_integers)

      sort_test(test_data, num_integers, 10)
    end

    test "Sorting 100 numbers in multiple chunks" do
      num_integers = 100

      test_data = Common.create_test_integers(num_integers)

      sort_test(test_data, num_integers, 10)
    end

    test "Sorting numbers where the number of integers is less than the chunk size" do
      num_integers = 5

      test_data = Common.create_test_integers(num_integers)

      sort_test(test_data, num_integers, 10)
    end

    test "Sorting numbers where the number of integers is equal to the chunk size" do
      num_integers = 10

      test_data = Common.create_test_integers(num_integers)

      sort_test(test_data, num_integers, 10)
    end

    test "Sorting numbers where the number of integers is greater than the chunk size" do
      num_integers = 15

      test_data = Common.create_test_integers(num_integers)

      sort_test(test_data, num_integers, 10)
    end

    test "Sorting numbers where multiple rounds of merges occur" do
      num_integers = 1500

      test_data = Common.create_test_integers(num_integers)

      sort_test(test_data, num_integers, 10)
    end

    test "Sorting numbers where multiple rounds of merges occur and the last chunk file is not full" do
      num_integers = 1503

      test_data = Common.create_test_integers(num_integers)

      sort_test(test_data, num_integers, 10)
    end

    test "Sorting numbers where at least 5 rounds of merges occur" do
      num_integers = 3300

      test_data = Common.create_test_integers(num_integers)

      sort_test(test_data, num_integers, 5)
    end

    test "Sorting numbers with an odd chunk size" do
      num_integers = 10000

      test_data = Common.create_test_integers(num_integers)

      sort_test(test_data, num_integers, 13)
    end

    test "Sorting numbers with an even chunk size" do
      num_integers = 10000

      test_data = Common.create_test_integers(num_integers)

      sort_test(test_data, num_integers, 12)
    end

    test "Sorting 1,000 integers" do
      num_integers = 1000

      test_data = Common.create_test_integers(num_integers)

      sort_test(test_data, num_integers, 12)
    end

    test "Sorting 10,000 integers" do
      num_integers = 1000

      test_data = Common.create_test_integers(num_integers)

      sort_test(test_data, num_integers, 101)
    end

    test "Sorting 1,000,000 integers" do
      num_integers = 1000

      test_data = Common.create_test_integers(num_integers)

      sort_test(test_data, num_integers, 1223)
    end

    # Runs a sort integration test on an input file containing the test data
    defp sort_test(test_data, num_integers, chunk_size, keep_intermediate \\ false) do
      # Stub the IntegerFile mock with the real thing
      Common.stub_integer_file_mock()

      # Create the input file with the test data
      IntGen.create_integer_file(@input_file, num_integers, test_data)

      # Invoke the CLI function with the "--silent" option
      options = cli_options(@input_file, chunk_size, keep_intermediate, @output_file)

      IntSort.CLI.main(options)

      # Verify the results
      verify_merge_results(
        @input_file,
        @output_file,
        num_integers,
        chunk_size,
        IntSort.CLI.merge_files(),
        keep_intermediate
      )

      # Delete the test data
      File.rm_rf!(@test_dir)
    end

    # Creates the CLI options based on the test parameters
    @spec cli_options(String.t(), pos_integer(), boolean(), String.t()) :: list(String.t())
    defp cli_options(input_file, chunk_size, keep_intermediate, output_file) do
      [output_file]
      |> base_options(input_file, chunk_size)
      |> intermediate_option(keep_intermediate)
    end

    # Returns the CLI options with the base options prepended
    @spec base_options(list(String.t()), String.t(), pos_integer()) :: list(String.t())
    defp base_options(options, input_file, chunk_size) do
      base_options_list = [
        "--input-file",
        input_file,
        "--chunk-size",
        Integer.to_string(chunk_size),
        "--silent"
      ]

      base_options_list ++ options
    end

    # Returns the CLI options with the appropriate intermediate option depending on the test
    # parameters
    @spec intermediate_option(list(String.t()), boolean()) :: list(String.t())
    defp intermediate_option(options, _keep_intermediate = true),
      do: ["--keep-intermediate" | options]

    defp intermediate_option(options, _keep_intermediate = false), do: options

    # Verifies the results of the merge process. It verifies the contents of the output file
    # and that the expected intermediate files remain, but it does not verify the contents
    # of the gen files. In this test, we just care about the final results.
    defp verify_merge_results(
           input_file,
           output_file,
           num_integers,
           chunk_size,
           merge_count,
           keep_intermediate
         ) do
      # Verify that the input file still exists
      assert File.exists?(input_file)

      # Verify that the output file exists
      assert File.exists?(output_file)

      verify_output_file(input_file, output_file)

      # Verify that the intermediate files were kept or deleted, depending on what the
      # test parameters are
      verify_intermediate_files(
        input_file,
        output_file,
        num_integers,
        chunk_size,
        merge_count,
        keep_intermediate
      )
    end

    # Verifies that the output file contains the expected contents
    @spec verify_output_file(String.t(), String.t()) :: :ok
    defp verify_output_file(input_file, output_file) do
      # Read the input file and sort it
      expected_integers = integer_file_stream(input_file) |> Enum.sort()

      # Compare the expected results with the contents of the output file
      actual_integers = integer_file_stream(output_file)

      expected_integers
      |> Enum.zip(actual_integers)
      |> Enum.each(&compare/1)
    end

    # Verifies that the expected intermediate files are found
    @spec verify_intermediate_files(
            String.t(),
            String.t(),
            non_neg_integer(),
            pos_integer(),
            pos_integer(),
            boolean()
          ) :: :ok
    defp verify_intermediate_files(input_file, output_file, _, _, _, _keep_intermediate = false) do
      # Check that the only files remaining in the test directory are the input and output files
      expected_files = [input_file, output_file] |> Enum.sort()

      actual_files =
        File.ls!(@test_dir)
        |> Enum.map(&pathify_file/1)
        |> Enum.sort()

      assert Enum.count(expected_files) == Enum.count(actual_files)

      expected_files
      |> Enum.zip(actual_files)
      |> Enum.each(&compare/1)
    end

    defp verify_intermediate_files(
           input_file,
           output_file,
           num_integers,
           chunk_size,
           merge_count,
           _keep_intermediate = true
         ) do
      # Calculate the chunk file names
      chunk_files = Common.chunk_files(num_integers, chunk_size)

      # Calculate the number of merge generations it will take to merge those chunk files
      merge_gens = Common.merge_generations(Enum.count(chunk_files), merge_count)

      # Calculate the merge file names
      merge_files = Common.merge_files(merge_gens, Enum.count(chunk_files), merge_count)

      # Since the last intermediate file will be renamed to the output file, we can remove it
      merge_files = remove_last(merge_files)

      # The contents of the test directory should consist of the input file, output file, andd
      # all the intermediate files
      expected_files =
        chunk_files
        |> Enum.concat(merge_files)
        |> Enum.map(&pathify_file/1)
        |> Enum.concat([input_file, output_file])
        |> Enum.sort()

      # Compare the actual files with the expected files to determine if intermediate files were kept
      actual_files =
        File.ls!(@test_dir)
        |> Enum.map(&pathify_file/1)
        |> Enum.sort()

      assert Enum.count(expected_files) == Enum.count(actual_files)

      expected_files
      |> Enum.zip(actual_files)
      |> Enum.each(&compare/1)
    end

    # Removes the last element in a list
    @spec remove_last(list(any())) :: list(any())
    defp remove_last([]), do: []
    defp remove_last(data), do: data |> Enum.reverse() |> tl() |> Enum.reverse()

    # Adds the test directory to the front of a file name
    @spec pathify_file(String.t()) :: String.t()
    defp pathify_file(file), do: Path.join(@test_dir, file)

    # Returns the integer contents of an integer file as a readable stream
    @spec integer_file_stream(String.t()) :: Enum.t()
    defp integer_file_stream(file) do
      file
      |> IntegerFile.integer_file_stream()
      |> IntegerFile.read_stream()
    end

    # Compares two data elements and asserts that they are equal
    @spec compare({any(), any()}) :: :ok
    defp compare({expected, actual}) do
      assert expected == actual
    end
  end
end
