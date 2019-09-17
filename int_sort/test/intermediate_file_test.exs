defmodule IntSort.IntermediateFileTest do
  use ExUnit.Case, async: true

  alias IntSort.IntermediateFile
  # alias LargeSort.Shared.TestStream
  # alias LargeSort.Shared.TestData
  # alias IntSort.Test

  import Mox

  doctest IntermediateFile

  describe "intermediate_file_stream -" do
    test "Create an intermediate file stream" do
      test_intermediate_file_stream(1, 1)
      test_intermediate_file_stream(10, 12)
      test_intermediate_file_stream(4, 2)
    end

    @test_output_dir "output"

    @spec test_intermediate_file_stream(non_neg_integer(), non_neg_integer()) :: :ok
    defp test_intermediate_file_stream(gen, file_num) do
      # Create any mocks that need to be created
      intermediate_file_stream_mocks()

      # Call intermediate_file_stream and get the stream
      intermediate_stream = IntermediateFile.intermediate_file_stream(gen, file_num,
        &intermediate_file_name/2, @test_output_dir)

      # Verify the results
      verify_intermediate_stream_results(intermediate_stream, gen, file_num)
    end

    # Mocks any modules that need to be mocked
    @spec intermediate_file_stream_mocks() :: :ok
    defp intermediate_file_stream_mocks() do
      # Mock IntegerFileMock so that returns a dummy stream when creating
      # an integer file stream. This dummy stream will contain the path
      # passed to the function so that we can later read it and verify
      # that the correct parameters were passed
      IntSort.IntegerFileMock
      |> expect(
        :integer_file_stream,
        fn path ->
          [path]
        end
      )
    end

    # Creates a test intermediate file name
    @spec intermediate_file_name(non_neg_integer(), non_neg_integer()) :: String.t()
    defp intermediate_file_name(gen, file_num) do
      "gen#{gen}file#{file_num}.txt"
    end

    # Verifies the results of the intermediate stream test
    @spec verify_intermediate_stream_results(Enum.t(), list(integer()), non_neg_integer()) :: :ok
    defp verify_intermediate_stream_results(intermediate_stream, gen, file_num) do
      # Get the contents of the intermediate stream
      [file_path] = Enum.to_list(intermediate_stream)

      # Get the expected file path
      expected_file_path = Path.join(@test_output_dir, intermediate_file_name(gen, file_num))

      # Ensure that the expected file path matches the actual file path
      assert file_path == expected_file_path

      verify!()

      :ok
    end
  end

  describe "create_file_groups -" do
    test "Create file groups with the number of files evenly divisible by the file group size" do
      test_create_file_groups(100, 10)
    end

    test "Create file groups with the number of files not evenly divisible by the file group size" do
      test_create_file_groups(100, 12)
    end

    test "Create file groups with the group size the same as the number of files" do
      test_create_file_groups(10, 10)
    end

    test "Create file groups with the group size larger than the number of files" do
      test_create_file_groups(10, 12)
    end

    test "Create file groups with a group size of 1" do
      test_create_file_groups(10, 1)
    end

    test "Create file groups with a single file" do
      test_create_file_groups(1, 10)
    end

    test "Create file groups with no files" do
      test_create_file_groups(0, 10)
    end

    # Tests file group creation
    @spec test_create_file_groups(non_neg_integer(), non_neg_integer()) :: :ok
    defp test_create_file_groups(file_count, group_size) do
      # Create the test files
      test_files = 1..file_count
      |> Enum.map(&test_file_name/1)

      # Calculate the expected file groups
      expected_file_groups = test_files
      |> Enum.chunk_every(group_size)
      |> Enum.with_index(1)

      # Create the file groups
      actual_file_groups = IntermediateFile.create_file_groups(test_files, group_size)
      |> Enum.to_list()

      compare_file_groups(expected_file_groups, actual_file_groups)

      :ok
    end

    # Compares the expected file groups to the actual file groups
    @spec compare_file_groups(Enum.t(), Enum.t()) :: :ok
    defp compare_file_groups(expected_groups, actual_groups) do
      # Assert the number of groups
      assert Enum.count(expected_groups) == Enum.count(actual_groups)

      # Compare each group
      expected_groups
      |> Enum.zip(actual_groups)
      |> Enum.each(&compare_file_group/1)
    end

    # Compares a file group pair
    @spec compare_file_group({Enum.t(), Enum.t()}) :: :ok
    defp compare_file_group({{expected_group, expected_index}, {actual_group, actual_index}}) do
      # Compare the number of files in each group
      assert Enum.count(expected_group) == Enum.count(actual_group)

      # Compare the index
      assert expected_index == actual_index

      # Compare the file names in each group
      expected_group
      |> Enum.zip(actual_group)
      |> Enum.each(fn {expected_file, actual_file} ->
        assert expected_file == actual_file
      end)
    end

    # Creates a test file name based on an integer representing a file number
    @spec test_file_name(non_neg_integer()) :: String.t()
    defp test_file_name(file_num), do: "testfile#{file_num}.txt"
  end
end
