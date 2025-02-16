# practice 3.4 pg 99
# a range/2 functions that takes two integers from and to and returns a list of all integer numbers in the given range
defmodule ListHelper do
  def range_rec(from, to) when from == to do
    [to]
  end

  def range_rec(from, to) do
    [from] ++ range_rec(from + 1, to)
  end

  def range_tco(from, to) do
    do_range(from, to, [])
  end

  defp do_range(from, to, list) do
    cond do
      from > to -> Enum.reverse(list)
      true -> do_range(from + 1, to, [from] ++ list)
    end
  end
end

IO.puts "regular recursive:"
ListHelper.range_rec(1, 4)
|> IO.inspect()

IO.puts "tail recursive:"
ListHelper.range_tco(1, 4)
|> IO.inspect()
