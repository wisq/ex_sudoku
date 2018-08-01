# A concurrent Sudoku solver in Elixir

This is just a random one-day project I threw together to solve Sudoku puzzles concurrently using Elixir.

I don't claim this to be a particularly efficient method, nor do I have any expertise in writing Sudoku solvers.  This was simply an educational project, and a benchmark against a similar Ruby solution that I wrote a few years ago.

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

**Several performance changes have been made, and an inline (non-managed) solver has been added.  Previous results are outdated.  The current text summarises lessons learned to date; actual benchmarks numbers are still pending.**

In general, the following performance characteristics have been observed:

### Higher CPU, lower clock time

In general, the Elixir version tends to take more raw CPU time than the Ruby version.  However, for complex puzzles, it makes up for this by running with much higher concurrency, thus taking a fraction of the actual time that Ruby takes.

On 4-core systems, typical speedups are 6x, i.e. the Elixir version runs at over 600% CPU and takes 1/6th the amount of time.

### Bottleneck at ~10x performance

On 6-core systems and higher, typical speedups are 10x.  The regular solver seems to cap out at this point, probably due to bottlenecking on the `Manager` class.

There are two recent developments that might break this trend, and need benchmarking:

* Previously, I had to use `GenServer.call` for `Manager.queue/2` and `Manager.solved/2`, because of a race condition that would cause the solver to exit prematurely.  This has been resolved, and the previous `GenServer.cast` behaviour restored, so concurrency may be improved.
* There is a new `Solver.solve_inline/1` call that may have completely different performance characteristics compared to the "regular" (managed) solver.  Initial results show it to be equally as fast as the managed version on 4-core systems, but testing on 6-core and higher systems is needed.

### More processes are not always better

For the hardest puzzle so far (`data/harder.txt`), performance actually decreased on highly multi-core systems.  This seemed to be due to extreme concurrency — on the order of 2500 processes or more — and potentially due to the `Manager` class being overloaded.

Limiting the number of processes to 100 (from the original 10,000) helped this, and highly multi-core systems were once again performing better than systems with fewer cores.

As per above, this may have changed with the `GenServer.cast` change.  It is also entirely unknown how the inline solver will react on highly multi-core systems.

### Higher initial startup cost

Elixir has a higher startup cost than Ruby — at least for these simple Sudoku solver programs.  Typically, this is perhaps 3-4x or so, e.g. 40ms for Ruby and 150ms for Elixir.

Ruby's startup time improves more with better CPUs than Elixir's does.  This suggests Ruby's startup is more about speed (including parsing the code from scratch), while Elixir's is probably a bit more about scheduling.

## Conclusion

All in all, a decently successful approach.

Of course, the problem is not especially difficult, even with the hardest puzzles I can find, but this is a satisfactory solution, if perhaps somewhat over-engineered.

I appreciated the chance to try out the new `DynamicSupervisor` module (even if it's just a rework of the old `simple_one_for_one` Supervisor behaviour).  In particular, it was neat to use a "dynamic `DynamicSupervisor`", in that it's created on the fly, not given a name, not attached to any supervisor tree, and passed around by PID.  This allows multiple puzzles to be solved at once, without stomping all over each other.
