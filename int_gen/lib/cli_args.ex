defmodule IntGen.CLI.Args do
  alias IntGen.CLI.Options

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
    - --count: number of integers to be generated
    - --lower-bound: the lower bound (inclusive) of the integers to be generated
    - --upper-bound: the upper bound (inclusive) of the integers to be generated

  The last argument is a standalone argument containing the path of the file the
  generated integers are to be written to

  Parameters

  - argv: a list containing the command line arguments tokens

  Returns

  An `{:ok, options}` tuple containing parsed options, or `{:ok, :help}` if help was requested,
  or `{:error, messages}` if there was an option validation issue.
  """
  @spec parse_args(list(String.t())) :: options_response()
  def parse_args(argv) do
    OptionParser.parse(argv,
      switches: [help: :boolean, count: :integer, lower_bound: :integer, upper_bound: :integer],
      aliases: [h: :help, c: :count, l: :lower_bound, u: :upper_bound]
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
         Keyword.get(parsed_args, :count),
         Keyword.get(parsed_args, :lower_bound),
         Keyword.get(parsed_args, :upper_bound),
         hd(additional_args)
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
      |> validate_count()
      |> validate_bounds()
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
    {:error, ["The #{arg_description} has not been specified"]}
  end

  @spec validate_switch_exists(parsed_switches(), atom(), String.t()) :: validation_response()
  defp validate_switch_exists(parsed_args, arg_key, arg_description) do
    validate_switch_exists(Keyword.has_key?(parsed_args, arg_key), arg_description)
  end

  # Validates if multiple switches exist, returning a message for each non-existent
  # switch. The switches are specified by a list of tuples, where the first element
  # is the switch key and the second element is the switch description
  @spec validate_switches_exist(parsed_switches(), keyword()) :: validation_response()
  defp validate_switches_exist(parsed_switches, switches) do
    # Validate each switch in the list of key-description pairs
    errors =
      Enum.reduce(switches, [], fn switch, messages ->
        switch_key = elem(switch, 0)
        switch_description = elem(switch, 1)

        case validate_switch_exists(parsed_switches, switch_key, switch_description) do
          :ok -> []
          {:error, error_messages} -> error_messages ++ messages
        end
      end)

    # Return a validation response depending how the switch validation went
    if length(errors) == 0 do
      :ok
    else
      {:error, errors}
    end
  end

  # Validates the count parameter
  @spec validate_count({parsed_switches(), parsed_additional_args(), list(String.t())}) ::
          validation_errors()
  defp validate_count({parsed_args, other_args, errors}) do
    # First we check if the count exists, then we check its value
    with :ok <- validate_switch_exists(parsed_args, :count, "count"),
         :ok <- validate_count_value(Keyword.get(parsed_args, :count)) do
      {parsed_args, other_args, errors}
    else
      {:error, message} ->
        {parsed_args, other_args, message ++ errors}
    end
  end

  # Validates the count value
  @spec validate_count_value(integer()) :: validation_response()
  defp validate_count_value(count_value) when is_integer(count_value) and count_value >= 0 do
    :ok
  end

  defp validate_count_value(_) do
    {:error, ["The count must be a positive integer"]}
  end

  # Validates the bounds parameters
  @spec validate_bounds({parsed_switches(), parsed_additional_args(), list(String.t())}) ::
          validation_errors()
  defp validate_bounds({parsed_args, other_args, errors}) do
    # Check if the bounds exist then check if the bound values make sense
    switches = [lower_bound: "lower bound", upper_bound: "upper bound"]

    with :ok <- validate_switches_exist(parsed_args, switches),
         :ok <-
           validate_bounds_values(
             Keyword.get(parsed_args, :lower_bound),
             Keyword.get(parsed_args, :upper_bound)
           ) do
      {parsed_args, other_args, errors}
    else
      {:error, messages} ->
        {parsed_args, other_args, messages ++ errors}
    end
  end

  # Validates the bounds values
  @spec validate_bounds_values(integer(), integer()) :: validation_response()
  defp validate_bounds_values(lower_bound, upper_bound)
       when is_integer(lower_bound) and
              is_integer(upper_bound) and lower_bound <= upper_bound do
    :ok
  end

  # This clause gets called when both bounds are integers but the lower bound is above
  # the upper bound
  defp validate_bounds_values(lower_bound, upper_bound)
       when is_integer(lower_bound) and
              is_integer(upper_bound) and lower_bound >= upper_bound do
    {:error, ["The lower bound cannot exceed the upper bound"]}
  end

  # This clause gets called when one of the bounds is not an integer
  defp validate_bounds_values(lower_bound, upper_bound) do
    {:error, []}
    |> validate_integer(lower_bound, "lower bound")
    |> validate_integer(upper_bound, "upper bound")
  end

  # Validates a value to see if it is an integer. If not, a message is added to the validation
  # response.
  @spec validate_integer(validation_response(), integer(), String.t()) :: validation_response()
  defp validate_integer(validation_response, value, _) when is_integer(value) do
    validation_response
  end

  defp validate_integer({_, messages}, value, description) when not is_integer(value) do
    {:error, ["The #{description} must be an integer" | messages]}
  end

  # Validates the output file parameter
  @spec validate_output_file({parsed_switches(), parsed_additional_args(), list(String.t())}) ::
          validation_errors()
  defp validate_output_file({parsed_args, other_args, errors}) do
    # Check if the file parameter exists and then verify that the file value is valid
    with :ok <- validate_file_exists(other_args),
         :ok <- validate_file_value(hd(other_args)) do
      {parsed_args, other_args, errors}
    else
      {:error, messages} -> {parsed_args, other_args, messages ++ errors}
    end
  end

  # Validates whether the output file parameter exists
  @spec validate_file_exists(parsed_additional_args()) :: validation_response()
  defp validate_file_exists(other_args) when length(other_args) > 0, do: :ok

  defp validate_file_exists(_) do
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
