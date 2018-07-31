defmodule Sudoku.Puzzle.Verify do
  alias Sudoku.Puzzle, as: Pz

  def verify(puzzle) do
    Enum.each(0..8, fn n ->
      Pz.get_row(puzzle, n) |> verify_unique("row #{n + 1}")
      Pz.get_column(puzzle, n) |> verify_unique("column #{n + 1}")
      Pz.get_square(puzzle, n) |> verify_unique("square #{n + 1}")
    end)

    puzzle
  end

  defp verify_unique(numbers, desc) do
    numbers
    |> verify_assert_length(desc)
    |> Enum.reject(&is_nil/1)
    |> Enum.reduce(MapSet.new(), fn n, seen ->
      if MapSet.member?(seen, n) do
        raise "Duplicate number #{n} in #{desc}"
      else
        MapSet.put(seen, n)
      end
    end)
  end

  defp verify_assert_length([_, _, _, _, _, _, _, _, _] = ns, _), do: ns

  defp verify_assert_length(nums, desc) do
    raise("Expected nine values for #{desc}, got #{inspect(nums)}")
  end
end
