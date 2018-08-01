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

### 2013 laptop 4-core CPU (Mac)

On my 2013 Macbook Pro, the Ruby version (`other/sudoku.rb`) can solve the hardest puzzle (`data/hard.txt`) in 4.0 seconds at best, using 99% CPU (i.e. a single core).

The Elixir version tends to take about 4.5 seconds of CPU time.  However, it also uses around 700% CPU, meaning it solves the hardest puzzle in only ~650ms of clock time.

There is, however, a one-time ~400ms Elixir/Erlang startup time cost, compared to a much more modest ~150ms Ruby startup time cost.  This makes single-puzzle `mix solve` calls much less performant than `ruby other/sudoku.rb` calls.

### 2015 desktop 4-core CPU (Linux)

On a more modern CPU (a 4-core, 8-thread i7-6700K), the results are similar: In Ruby, ~2.45 seconds; in Elixir, ~2.7 CPU seconds, but only ~400ms on the clock.  CPU is over 650% and `max_active` is typically around 250.

Startup costs are reduced, with Elixir having ~200ms startup time and Ruby having ~40ms.  (Given that Elixir's startup time is halved while Ruby's is reduced by more than two thirds, this suggests that Elixir/Erlang's startup time is more about scheduling than about raw computation.)

### 2011 desktop 6-core CPU (Windows)

Going back to an even older CPU (a 6-core, 12-thread i7-3930k), the results are even more divergent.  Ruby takes over 3.9 seconds to solve the `hard.txt` puzzle, while Elixir can complete it in 390ms — exactly 10x faster.  (CPU time for Elixir is not measurable on Windows for some reason.)

Given that 4-core CPUs saw a ~6x increase in speed from Ruby to Elixir, it's not totally unexpected that a 6-core CPU would see a 10x increase in speed.  There may also be differences related to the Windows builds of Elixir and Ruby.

Startup times are similar to the 2013 CPU: ~490ms for Elixir, ~150ms for Ruby.

## Conclusion

All in all, a decently successful approach.

Of course, the problem is not especially difficult, even with the hardest puzzles I can find, but this is a satisfactory solution, if perhaps somewhat over-engineered.

In general, maximum concurrency is actually pretty low.  In the original fully-asynchronous version, it was rare to see `max_active` higher than 15 to 20 processes at a time, unless the CPU was tied up with something else.  The new version (using `call` instead of `cast`) bumps this to ~250 processes — but most of that is just because of the increased coordination overhead, and the increased bottlenecking on the `Sudoku.Solver.Manager` process.

As such, this could also probably have been done in a much less controlled manner, just using `spawn_link` (or `Task.async`) calls to try out every possibility (in something of a "fork bomb" style).  But this was also a good chance to try out the new `DynamicSupervisor` module, even if it's just a rework of the old `simple_one_for_one` Supervisor behaviour.
