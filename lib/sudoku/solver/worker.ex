defmodule Sudoku.Solver.Worker do
  alias Sudoku.Puzzle
  alias Sudoku.Solver.Manager

  def child_spec(puzzle, manager) do
    %{
      id: puzzle,
      restart: :temporary,
      start: {Task, :start_link, [fn -> solve(puzzle, manager) end]}
    }
  end

  def solve(puzzle, manager) do
    case solve_once(puzzle) do
      {:ok, ^puzzle} ->
        Manager.solved(manager, puzzle)
        :ok

      {:pending, [next | others]} ->
        Enum.each(others, fn puz -> Manager.queue(manager, puz) end)
        solve(next, manager)

      {:error, err} ->
        :error
    end
  end

  def solve_once(puzzle) do
    case cell_with_least_options(puzzle) do
      {1, row, col, [option]} ->
        {:pending, [Puzzle.put_value(puzzle, row, col, option)]}

      {0, row, col, []} ->
        {:error, "No possible value for row #{row + 1}, column #{col + 1}"}

      {n, row, col, options} ->
        {:pending,
         Enum.map(options, fn opt ->
           Puzzle.put_value(puzzle, row, col, opt)
         end)}

      nil ->
        {:ok, puzzle}
    end
  end

  defp cell_with_least_options(puzzle) do
    puzzle
    |> Puzzle.empty_spaces()
    |> Enum.reduce_while(nil, &reduce_cell_options(puzzle, &1, &2))
  end

  defp reduce_cell_options(puzzle, {row, column}, old_acc) do
    options = find_cell_options(puzzle, row, column)
    new_count = Enum.count(options)
    new_acc = {new_count, row, column, options}

    if new_count <= 1 do
      # Only one (or no) solution, so short-circuit the rest.
      {:halt, new_acc}
    else
      {:cont,
       case old_acc do
         nil ->
           new_acc

         {old_count, _, _, _} ->
           if new_count < old_count do
             new_acc
           else
             old_acc
           end
       end}
    end
  end

  defp find_cell_options(puzzle, row, column) do
    used =
      [
        Puzzle.get_row(puzzle, row),
        Puzzle.get_column(puzzle, column),
        Puzzle.get_square(puzzle, row, column)
      ]
      |> Enum.map(&MapSet.new/1)
      |> Enum.reduce(&MapSet.union/2)

    MapSet.new(1..9)
    |> MapSet.difference(used)
    |> MapSet.to_list()
  end
end
