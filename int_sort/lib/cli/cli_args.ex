defmodule IntSort.CLI.Args do
  alias IntSort.CLI.Options

  @type parsed_switches() :: keyword()
  @type parsed_additional_args() :: list(String.t())
  @type parsed_args() :: {parsed_switches(), parsed_additional_args(), list()}
  @type error_response() :: {:error, list(String.t())}
  @type validation_response() :: :ok | error_response()
  @type validation_errors() :: {parsed_switches(), parsed_additional_args(), list()}
  @type options_response() :: {:ok, Options.t()} | {:ok, :help} | error_response()

  @moduledoc """
  Contains functionality for parsing and validating command line arguments
  """

  @doc """
  Parses the command line arguments

  Valid switches are:
    - --help: displays help information
    - --input-file: the input file from which integers are to be read
    - --chunk-size: the size of the integer chunks that are to be loaded and sorted
    - --keep-intermediate: indicates whether intermediate files should be kept or deleted

  The last argument is a standalone argument containing the path of the file the
  final sorted list of integers is to be written to

  Parameters

  - argv: a list containing the command line arguments tokens

  Returns

  An `{:ok, options}` tuple containing parsed options, or `{:ok, :help}` if help was requested,
  or `{:error, messages}` if there was an option validation issue.
  """
  @spec parse_args(list(String.t())) :: options_response()
  def parse_args(argv) do
    OptionParser.parse(argv,
      strict: [help: :boolean, input_file: :string, chunk_size: :integer, keep_intermediate: :boolean],
      aliases: [h: :help, i: :input_file, c: :chunk_size, k: :keep_intermediate]
    )
    |> args_to_options()
  end

  # Performs validation on the parsed arguments and converts any valid parsed arguments
  # to options
  @spec args_to_options(parsed_args()) :: options_response()
  defp args_to_options({parsed_args, additional_args, _}) do
    # Validate the arguments
    validation_response = validate_args(parsed_args, additional_args)

    # Handle the validation response and convert to options
    args_to_options(parsed_args, additional_args, validation_response)
  end

  @spec args_to_options(
          parsed_switches(),
          parsed_additional_args(),
          atom() | validation_response()
        ) ::
          options_response()
  defp args_to_options(parsed_args, additional_args, :ok) do
    args_to_options(parsed_args, additional_args)
  end

  defp args_to_options(_, _, validation_response) do
    validation_response
  end

  # Converts the arguments to either an options struct or a :help atom depending
  # on whether the help switch was set. This function assumes that argument validation
  # was successful.
  @spec args_to_options(parsed_switches(), parsed_additional_args()) ::
          {:ok, Options.t() | :help}
  defp args_to_options(parsed_args, additional_args) do
    # If the help switch was set, return :help, otherwise convert the arguments
    # to an options struct
    if contains_help_switch(parsed_args) do
      {:ok, :help}
    else
      {:ok,
       Options.new(
         Keyword.get(parsed_args, :input_file),
         hd(additional_args),
         Keyword.get(parsed_args, :chunk_size),
         Keyword.get(parsed_args, :keep_intermediate, false)
       )}
    end
  end

  # Validates the arguments
  @spec validate_args(parsed_switches(), parsed_additional_args()) ::
          :ok | error_response()
  defp validate_args(parsed_args, additional_args) do
    if contains_help_switch(parsed_args) do
      :ok
    else
      validate_non_help_args(parsed_args, additional_args)
    end
  end

  # Indicates whether the parse arguments contains the help switch
  @spec contains_help_switch(parsed_switches()) :: boolean()
  defp contains_help_switch(parsed_args) do
    Keyword.has_key?(parsed_args, :help)
  end

  @spec validate_non_help_args(parsed_switches(), parsed_additional_args()) ::
          validation_response()
  # Validates the non-help arguments
  defp validate_non_help_args(parsed_args, other_args) do
    {_, _, errors} =
      {parsed_args, other_args, []}
      |> validate_input_file()
      |> validate_chunk_size()
      |> validate_output_file()

    if length(errors) == 0 do
      :ok
    else
      {:error, errors}
    end
  end

  # Validates whether a switch exists in the parsed arguments
  @spec validate_switch_exists(boolean(), String.t()) :: validation_response()
  defp validate_switch_exists(true, _), do: :ok

  defp validate_switch_exists(false, arg_description) do
    {:error, ["The #{arg_description} must be specified"]}
  end

  @spec validate_switch_exists(parsed_switches(), atom(), String.t()) :: validation_response()
  defp validate_switch_exists(parsed_args, arg_key, arg_description) do
    validate_switch_exists(Keyword.has_key?(parsed_args, arg_key), arg_description)
  end

  # Validates the chunk_size parameter
  @spec validate_chunk_size({parsed_switches(), parsed_additional_args(), list(String.t())}) ::
          validation_errors()
  defp validate_chunk_size({parsed_args, other_args, errors}) do
    # First we check if the chunk size exists, then we check its value
    with :ok <- validate_switch_exists(parsed_args, :chunk_size, "chunk size"),
         :ok <- validate_chunk_size_value(Keyword.get(parsed_args, :chunk_size)) do
      {parsed_args, other_args, errors}
    else
      {:error, message} ->
        {parsed_args, other_args, message ++ errors}
    end
  end

  # Validates the chunk size value
  @spec validate_chunk_size_value(integer()) :: validation_response()
  defp validate_chunk_size_value(chunk_size_value) when is_integer(chunk_size_value) and chunk_size_value > 0 do
    :ok
  end

  defp validate_chunk_size_value(_) do
    {:error, ["The chunk size must be a positive integer"]}
  end

  # Validates the input file parameter
  @spec validate_input_file({parsed_switches(), parsed_additional_args(), list(String.t())}) ::
          validation_errors()
  defp validate_input_file({parsed_args, other_args, errors}) do
    # Check if the file parameter exists and then verify that the file value is valid
    with :ok <- validate_input_file_exists(parsed_args),
         :ok <- validate_file_value(Keyword.get(parsed_args, :input_file)) do
      {parsed_args, other_args, errors}
    else
      {:error, messages} -> {parsed_args, other_args, messages ++ errors}
    end
  end

  # Validates whether the input file parameter exists
  @spec validate_input_file_exists(parsed_switches() | boolean()) :: validation_response()
  defp validate_input_file_exists(true) do
    :ok
  end

  defp validate_input_file_exists(false) do
    {:error, ["The input file must be specified"]}
  end

  defp validate_input_file_exists(parsed_args) do
    Keyword.has_key?(parsed_args, :input_file)
    |> validate_input_file_exists()
  end

  # Validates the output file parameter
  @spec validate_output_file({parsed_switches(), parsed_additional_args(), list(String.t())}) ::
          validation_errors()
  defp validate_output_file({parsed_args, other_args, errors}) do
    # Check if the file parameter exists and then verify that the file value is valid
    with :ok <- validate_output_file_exists(other_args),
         :ok <- validate_file_value(hd(other_args)) do
      {parsed_args, other_args, errors}
    else
      {:error, messages} -> {parsed_args, other_args, messages ++ errors}
    end
  end

  # Validates whether the output file parameter exists
  @spec validate_output_file_exists(parsed_additional_args()) :: validation_response()
  defp validate_output_file_exists(other_args) when length(other_args) > 0, do: :ok

  defp validate_output_file_exists(_) do
    {:error, ["The output file must be specified"]}
  end

  # Validates the file value. Since I don't see any way to validate a file path,
  # I'm just going to check that the file path is a binary
  @spec validate_file_value(any()) :: validation_response()
  defp validate_file_value(file) when is_binary(file), do: :ok

  defp validate_file_value(_) do
    {:error, ["The output file must be a string"]}
  end
end
