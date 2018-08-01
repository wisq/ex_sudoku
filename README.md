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

### Amazon 72-vCPU instance (Linux)

On a highly multi-core (c5.18xlarge) Amazon EC2 instance, Ruby results average to 2.7s each — better than the 2011 and 2013 CPUs, but worse than the 2015 CPU.  Elixir results average to 275ms clock time, 3.8s CPU time — the best results so far.

Again, this is a roughly 10x improvement, suggesting that more cores do indeed help, but that this solution does begin to max out at around 10x performance — either due to the nature of the algorithm, or due to overhead and/or bottlenecking.

### Platinum Blonde

To push the 72-vCPU instance further, I found a harder puzzle — the (apparently well-known) "Platinum Blonde" puzzle — stored here as `data/harder.txt`.

Initially — with the original setting of 10k maximum workers for Elixir — the Ruby version took 9.9 seconds to solve this, while the Elixir version took 3.0 seconds.  This seemed to show a substantially reduced benefit to the concurrent Elixir version — as well as reversing the "more cores is better" trend, since the 4-core 2015 CPU solves this puzzle in only 7.9 seconds in Ruby, and 2.85 seconds in Elixir.

However, this seems to be a case of too many children causing too much overhead and/or bottlenecking — with a `max_active` figure of over 2500.  Reducing the maximum children to only 100 was a substantial improvement, coming in at 1.1s average in Elixir on the 72-core instance — a 9x improvement over the Ruby version — and 1.45s on the 4-core 2015 CPU.  Neither CPU saw any major improvement when reducing the child count below this amount.

## Conclusion

All in all, a decently successful approach.

Of course, the problem is not especially difficult, even with the hardest puzzles I can find, but this is a satisfactory solution, if perhaps somewhat over-engineered.

In the early tests, it seemed that maximum concurrency was generally actually pretty low.  In the original fully-asynchronous version, it was rare to see `max_active` higher than 15 to 20 processes at a time, unless the CPU was tied up with something else.  The new version (using `call` instead of `cast`) bumps this to ~250 processes — but most of that is just because of the increased coordination overhead, and the increased bottlenecking on the `Sudoku.Solver.Manager` process.

However, the "Platinum Blonde" test turned this upside-down.  With process counts upwards of 2500, there was just too much overhead, and the concurrency benefits began to disappear.  In this case, limiting the number of children to a more reasonable number (100) was essential for maximum performance.  That might be because of Erlang scheduler overhead, but it seems far more likely to me that the `Manager` process is just too much of a bottleneck when using synchronous `GenServer.call` calls.  (It's probably worth finding a way to safely return this to `GenServer.cast` and solving the race condition that entailed.)

It might also be worth trying out a much less controlled approach — just using `spawn_link` (or `Task.async`) calls to try out every possibility (in something of a "fork bomb" style), without attempting to put any limits on the number of processes.  It's possible that maximum concurrency would be low enough, and/or the lack of single-process bottlenecking would speed things up enough, that controlling the number of workers isn't necessary.

In any case, this was also a good chance to try out the new `DynamicSupervisor` module (even if it's just a rework of the old `simple_one_for_one` Supervisor behaviour).
