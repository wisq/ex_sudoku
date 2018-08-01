#!/usr/bin/env ruby

require 'pp'

DEBUG = false

class Board
  class Impossible < StandardError; end
  class Solved < StandardError; end

  def self.from_file(file)
    spaces = File.open(file) do |fh|
      fh.each_line.map do |line|
        next if line !~ /\S/
        line.split(/\s*/).map { |s| s == '_' ? nil : s.to_i }
      end
    end.compact

    new(spaces)
  end

  def initialize(spaces)
    @spaces = spaces
  end

  def to_string
    lines = []
    @spaces.each_with_index do |row, row_index|
      line = []
      row.each_with_index do |col, col_index|
        line << (col || '_').to_s
        line << ' ' if (col_index + 1) % 3 == 0
      end
      lines << line.join
      lines << '' if (row_index + 1) % 3 == 0
    end

    lines.join("\n")
  end

  def possibs(x, y)
    raise "not blank" unless @spaces[x][y].nil?

    remain = (1..9).to_a
    (0..8).each do |i|
      remain.delete(@spaces[x][i])
      remain.delete(@spaces[i][y])
    end

    square_coords(x).each do |sq_x|
      square_coords(y).each do |sq_y|
        remain.delete(@spaces[sq_x][sq_y])
      end
    end

    remain
  end

  def square_coords(n)
    return (0..2) if n <= 2
    return (3..5) if n <= 5
    return (6..8) if n <= 8
    raise "should not happen"
  end

  def least_possibs
    least_xy  = nil
    least_pos = nil

    (0..8).each do |x|
      (0..8).each do |y|
        next unless @spaces[x][y].nil?

        pos = possibs(x, y)
        raise Impossible if pos.empty?

        if least_xy.nil? || pos.count < least_pos.count
          least_xy  = [x, y]
          least_pos = pos
        end

        break if pos.count == 1
      end
      break if least_pos && least_pos.count == 1
    end

    raise Solved if least_xy.nil?
    [least_xy, least_pos]
  end

  def next_boards
    (x, y), pos = least_possibs

    pos.map do |p|
      new_spaces = @spaces.map { |row| row.dup }
      new_spaces[x][y] = p
      #puts "set #{x+1},#{y+1} = #{p}" if DEBUG
      Board.new(new_spaces)
    end
  end
end

def solve_file(file)
  puts "Solving: #{file}"
  board = Board.from_file(file)

  start = Time.now
  solved = solve_board(board)
  duration = "%.2f" % [(Time.now - start) * 1000]

  puts "#{solved.count} solutions in #{duration} ms:"
  solved.each do |board|
    puts
    puts board.to_string
  end

  puts
end

def solve_board(board)
  queue = [board]
  solved = []

  until queue.empty?
    board = queue.shift
    begin
      queue += (nxt = board.next_boards)
      puts "#{nxt.count} possible upcoming boards" if DEBUG
    rescue Board::Impossible
      # nothing added to queue
      puts "board impossible, tossing" if DEBUG
    rescue Board::Solved
      solved << board
    end
  end

  solved
end

if ARGV.first == "--benchmark"
  board = Board.from_file(ARGV[1])

  $stdin.each_line do |id|
    solve_board(board)
    $stdout.puts(id)
    $stdout.flush()
  end
else
  ARGV.each do |file|
    solve_file(file)
  end
end
