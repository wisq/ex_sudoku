defmodule Sudoku.Puzzle do
  alias Sudoku.Puzzle.Verify

  def read(file) do
    File.read!(file)
    |> parse_numbers()
    |> new()
  end

  defp parse_numbers(str) do
    Regex.scan(~r/[0-9\._]/, str)
    |> List.flatten()
    |> Enum.map(&parse_number_or_blank/1)
  end

  defp parse_number_or_blank("."), do: nil
  defp parse_number_or_blank("_"), do: nil
  defp parse_number_or_blank(<<_>> = n), do: String.to_integer(n)

  def new(numbers) do
    Enum.chunk_every(numbers, 9)
    |> Verify.verify()
  end

  def get_row(puzzle, row), do: Enum.at(puzzle, row)

  def get_column(puzzle, col) do
    Enum.map(puzzle, fn row ->
      Enum.at(row, col)
    end)
  end

  # in {starting row, starting column} format
  @squares [
    # top left
    {0, 0},
    # top
    {0, 3},
    # top right
    {0, 6},
    # middle left
    {3, 0},
    # middle
    {3, 3},
    # middle right
    {3, 6},
    # bottom left
    {6, 0},
    # bottom
    {6, 3},
    # bottom right
    {6, 6}
  ]

  def get_square(puzzle, num) do
    {start_row, start_col} = @squares |> Enum.at(num)

    puzzle
    |> Enum.drop(start_row)
    |> Enum.take(3)
    |> Enum.map(fn row ->
      row
      |> Enum.drop(start_col)
      |> Enum.take(3)
    end)
    |> List.flatten()
  end

  def get_square(puzzle, row, column) do
    get_square(puzzle, square_number(row, column))
  end

  def square_number(row, column) do
    start_row = div(row, 3) * 3
    start_column = div(column, 3) * 3
    Enum.find_index(@squares, &(&1 == {start_row, start_column}))
  end

  def get_value(puzzle, row, column) do
    puzzle
    |> Enum.at(row)
    |> Enum.at(column)
  end

  def empty_spaces(puzzle) do
    puzzle
    |> Enum.with_index()
    |> Enum.map(fn {row, row_num} ->
      row
      |> Enum.with_index()
      |> Enum.map(fn {value, col_num} ->
        if is_nil(value) do
          {row_num, col_num}
        else
          nil
        end
      end)
    end)
    |> List.flatten()
    |> Enum.reject(&is_nil/1)
  end

  def put_value(puzzle, row, column, value) do
    puzzle
    |> List.replace_at(
      row,
      Enum.at(puzzle, row) |> List.replace_at(column, value)
    )
  end

  def to_string(puzzle) do
    puzzle
    |> Enum.chunk_every(3)
    |> Enum.map(fn chunk ->
      chunk
      |> Enum.map(&row_to_string/1)
      |> Enum.join("\n")
    end)
    |> Enum.join("\n\n")
  end

  defp row_to_string(row) do
    row
    |> Enum.chunk_every(3)
    |> Enum.map(fn chunk ->
      chunk
      |> Enum.map(&cell_to_string/1)
      |> Enum.join("")
    end)
    |> Enum.join(" ")
  end

  defp cell_to_string(nil), do: "_"
  defp cell_to_string(n) when is_integer(n), do: Integer.to_string(n)
end
