defmodule IntSort.IntermediateFileTest do
  use ExUnit.Case, async: true

  alias LargeSort.Shared.IntegerFile
  alias LargeSort.Shared.TestData
  alias IntSort.Test.Common
  alias IntSort.IntermediateFile

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
      intermediate_stream =
        IntermediateFile.intermediate_file_stream(
          gen,
          file_num,
          &intermediate_file_name/2,
          @test_output_dir
        )

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
      test_files =
        1..file_count
        |> Enum.map(&test_file_name/1)

      # Calculate the expected file groups
      expected_file_groups =
        test_files
        |> Enum.chunk_every(group_size)
        |> Enum.with_index(1)

      # Create the file groups
      actual_file_groups =
        IntermediateFile.create_file_groups(test_files, group_size)
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

  describe "merge_stream -" do
    test "Merging devices with the same number of multiple integers in each device" do
      test_data = [
        [4, 8, 9, 13, 14, 20],
        [-12, -3, 0, 2, 10, 300],
        [-8, -1, 1, 14, 28, 30],
        [-100, -74, -28, -21, -12, -2],
        [-3, 0, 1, 9, 12, 54]
      ]

      test_merge_stream(test_data)
    end

    test "Merging devices with a different number of integers in each device" do
      test_data = [
        [4, 8, 9, 13, 14, 20],
        [-12, -3, 0, 2, 10],
        [-8, -1, 1, 14],
        [-100, -74, -28],
        [-3, 0]
      ]

      test_merge_stream(test_data)
    end

    test "Merging devices with an even number of devices" do
      test_data = [
        random_sorted_data(100),
        random_sorted_data(100)
      ]

      test_merge_stream(test_data)
    end

    test "Merging devices with an odd number of devices" do
      test_data = [
        random_sorted_data(100),
        random_sorted_data(100),
        random_sorted_data(100)
      ]

      test_merge_stream(test_data)
    end

    test "Merging a single device" do
      test_data = [
        random_sorted_data(57)
      ]

      test_merge_stream(test_data)
    end

    test "Merging no devices" do
      test_data = []

      test_merge_stream(test_data)
    end

    test "Merging devices where some devices have a single integer" do
      test_data = [
        random_sorted_data(485),
        random_sorted_data(36),
        random_sorted_data(1),
        random_sorted_data(58),
        random_sorted_data(1),
        random_sorted_data(3),
        random_sorted_data(88),
        random_sorted_data(306)
      ]

      test_merge_stream(test_data)
    end

    test "Merging devices where some devices have no integers" do
      test_data = [
        random_sorted_data(0),
        random_sorted_data(36),
        random_sorted_data(1),
        random_sorted_data(58),
        random_sorted_data(0),
        random_sorted_data(0),
        random_sorted_data(88),
        random_sorted_data(306)
      ]

      test_merge_stream(test_data)
    end

    test "Merging devices with segregated integer devices" do
      # Segregate the data so that one device has all the lower integers
      # and the other device has all the higher integers
      test_data = [
        [12, 18, 19, 22, 25, 30],
        [3, 6, 8, 10, 11]
      ]

      test_merge_stream(test_data)
    end

    test "Merging unbalanced devices" do
      # One device has most of the integers and the other one just has a few
      test_data = [
        random_sorted_data(220),
        random_sorted_data(4)
      ]

      test_merge_stream(test_data)
    end

    test "Merging devices where none of the devices have integers" do
      test_data = [
        [],
        [],
        [],
        [],
        []
      ]

      test_merge_stream(test_data)
    end

    test "Merging devices where devices have only positive integers" do
      test_data = [
        random_sorted_data(30, 1..1000),
        random_sorted_data(36, 1..1000),
        random_sorted_data(10, 1..1000),
        random_sorted_data(58, 1..1000)
      ]

      test_merge_stream(test_data)
    end

    test "Merging devices where devices have only negative integers" do
      test_data = [
        random_sorted_data(100, -1000..-1),
        random_sorted_data(316, -1000..-1),
        random_sorted_data(110, -1000..-1),
        random_sorted_data(528, -1000..-1)
      ]

      test_merge_stream(test_data)
    end

    test "Merging devices where devices have both positive and negative integers" do
      test_data = [
        random_sorted_data(300, -2000..2000),
        random_sorted_data(306, -2000..2000),
        random_sorted_data(102, -2000..2000),
        random_sorted_data(51, -2000..2000)
      ]

      test_merge_stream(test_data)
    end

    test "Merging devices with a random number of devices with random numbers of integers" do
      # Randomly generate 1 to 100 devices containing 1 to 1000 integers
      test_data =
        1..Enum.random(1..100)
        |> Enum.map(fn _ -> random_sorted_data(Enum.random(1..1000)) end)

      test_merge_stream(test_data)
    end

    test "Merging devices with automatic device closing" do
      test_data = [
        random_sorted_data(2),
        random_sorted_data(2),
        random_sorted_data(2)
      ]

      test_merge_stream(test_data, true)
    end

    @spec test_merge_stream(list(list(integer())), boolean()) :: :ok
    defp test_merge_stream(test_data, test_close_device \\ false) do
      # Create any mocks
      create_merge_stream_mocks()

      # Convert the test data into devices containing the test data
      test_devices = Enum.map(test_data, fn data -> test_data_device(data) end)

      # Calculate the expected results
      expected_result = expected_merged_data(test_data)

      # Create a merge stream from the test devices
      merge_stream = create_merge_stream(test_devices, test_close_device)

      # Verify that the contents of the merge stream match the expected results
      verify_merge_results(expected_result, merge_stream)

      # Close the test devices, and if we are testing device closure, verify that
      # the devices were already closed.
      close_verify_devices(test_devices, test_close_device)

      :ok
    end

    # Mocks any modules that need to be mocked
    @spec create_merge_stream_mocks() :: :ok
    defp create_merge_stream_mocks() do
      # For this test, we want to use the functions in the actual module
      # for the mock module, so we'll just have mock module share the
      # functionality
      Common.stub_integer_file_mock()

      :ok
    end

    # Creates a set of sorted randomly-generated integers for use as test data
    @spec random_sorted_data(pos_integer()) :: list(integer())
    defp random_sorted_data(count, range \\ -1000..1000) do
      TestData.random_integer_stream(range)
      |> Enum.take(count)
      |> Enum.sort()
    end

    # Creates a device containing a list of test data in integer file format
    @spec test_data_device(list(integer())) :: IO.device()
    defp test_data_device(test_data) do
      # Convert the test data into integer file lines and then put it in a single string
      device_contents =
        test_data
        |> IntegerFile.integers_to_lines()
        |> Enum.to_list()
        |> List.to_string()

      # Create the StringIO device containing the test data
      {:ok, device} = StringIO.open(device_contents)

      device
    end

    # Creates the merge stream based on whether we are testing the automatic
    # device closing functionality
    @spec create_merge_stream(list(IO.device()), boolean()) :: Enum.t()
    defp create_merge_stream(test_devices, false) do
      IntermediateFile.merge_stream(test_devices)
    end

    defp create_merge_stream(test_devices, true) do
      IntermediateFile.merge_stream(test_devices, &StringIO.close/1)
    end

    # Calculates the expected merged integers
    @spec expected_merged_data(list(list(integer))) :: list(integer)
    defp expected_merged_data(test_data) do
      test_data
      |> Enum.flat_map(& &1)
      |> Enum.sort()
    end

    @spec verify_merge_results(Enum.t(), Enum.t()) :: :ok
    defp verify_merge_results(expected_results, merge_stream) do
      # Verify that the result is an enumerable
      assert Enumerable.impl_for(merge_stream) != nil, "The merge stream is not an enumerable"

      # Retrieve the contents of the merge stream and verify that the correct
      # number of integers were retrieved
      actual_results = Enum.to_list(merge_stream)

      assert Enum.count(expected_results) == Enum.count(actual_results),
             "The merge stream does not contain the expected number of integers"

      Enum.each(actual_results, fn item ->
        assert is_integer(item) == true, "An item in the merge stream is not an integer"
      end)

      # Verify the integers in the enumerable
      expected_results
      |> Enum.zip(actual_results)
      |> Enum.each(fn {expected, actual} -> assert expected == actual end)
    end

    # Closes the test devices or verifies that they were closed, depending on whether
    # devices are to be closed by the merge stream
    @spec close_verify_devices(list(IO.device()), boolean()) :: :ok
    defp close_verify_devices(test_devices, true), do: verify_devices(test_devices)
    defp close_verify_devices(test_devices, false), do: close_devices(test_devices)

    # Verifies that the test devices were already closed
    @spec verify_devices(list(IO.device())) :: :ok
    defp verify_devices(test_devices) do
      Enum.each(test_devices, fn device -> assert Process.alive?(device) == false end)
    end

    # Closes the test devices
    @spec close_devices(list(IO.device())) :: :ok
    defp close_devices(test_devices) do
      Enum.each(test_devices, &StringIO.close/1)
    end
  end
end
