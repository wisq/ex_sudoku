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
    {solutions, launched, max_active} = Worker.solve_inline(puzzle)

    {solutions, %{launched: launched, max_active: max_active}}
  end
end
