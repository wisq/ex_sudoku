defmodule Sudoku.Solver do
  alias Sudoku.Solver.Manager
  alias Sudoku.Solver.Worker

  def solve(puzzle, opts \\ []) do
    {:ok, manager} = Manager.start_link(opts)
    Manager.queue(manager, puzzle)
    result = Manager.await(manager)
    Manager.stop(manager)

    result
  end

  def solve_inline(puzzle) do
    Worker.solve_inline(puzzle)
  end
end
