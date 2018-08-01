# A concurrent Sudoku solver in Elixir

This is just a random one-day project I threw together to solve Sudoku puzzles concurrently using Elixir.

I don't claim this to be a particularly efficient method, nor do I have any expertise in writing Sudoku solvers.  This was simply an educational project, and a benchmark against a similar Ruby solution.

## Algorithm

The approach is as follows:

* For every empty cell, determine all possible values.
  * If a cell has no possible values, the puzzle (or this attempted solution branch) is impossible.  Abort.
  * If a cell has only one possible value, skip remaining cells and continue below.
  * If there are no empty cells, register the current puzzle as a valid solution.
* Take the cell with the least possible values:
  * For the first possible value, set the cell to that value, and solve again.
  * For other possible values (if any), launch a new solver worker with the cell set to that value.
* Once all workers have exited, return a list of solutions, along with some extra stats:
  * `launched` (deterministic): The number of solver workers launched.  Larger values indicate more complex puzzles with more backtracking.
  * `max_active` (nondeterministic): The highest number of active workers seen at one time.  Larger values indicate more concurrency.

Most of the complexity is in the `Sudoku.Solver.Manager` module that launches and keeps track of the workers.

## Usage

* Elixir version: `mix solve <file>`
  * This uses the algorithm as described above.
* Ruby version: `ruby other/sudoku.rb <file>`
  * This uses a basically similar algorithm, except it simply tries each possible value in sequence, rather than launching extra workers or doing any sort of concurrency.

There are no dependencies, so no `mix deps.get` is required.

## Results

On my 2013 Macbook Pro, the Ruby version (`other/sudoku.rb`) can solve the hardest puzzle (`data/hard.txt`) in between 4.3 and 4.5 seconds (both CPU and clock time), using 99% CPU (i.e. a single core).

The Elixir version tends to take about 4.7 seconds of CPU time.  However, it also uses around 475% CPU, meaning it solves the hardest puzzle in only 1.0 seconds of clock time.

Results on a more modern CPU (an 8-core i7-6700K) are similar: In Ruby, ~2.5 seconds; in Elixir, 2.9 CPU seconds, but only 0.5 clock seconds.  CPU is over 500% and `max_active` can reach upwards of 30 on some runs.

## Conclusion

All in all, a decently successful approach.

Of course, the problem is not especially difficult, even with the hardest puzzles I can find, but this is a satisfactory solution, if perhaps somewhat over-engineered.

Given the relatively low maximum concurrency seen so far (`max_active` no higher than about 15 at most), it could also probably have been done in a much less controlled manner, just using `spawn_link` or `Task.async` calls to try out every possibility (in something of a "fork bomb" style).  But this was also a good chance to try out the new `DynamicSupervisor` module, even if it's just a rework of the old `simple_one_for_one` Supervisor behaviour.
