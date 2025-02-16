# practice 3.4 pg 99
# a positive/1 functions that calculates the length of a list
defmodule ListHelper do
  def positive_rec([hd | tl]) do
    case hd >= 0 do
      true -> [hd] ++ positive_rec(tl)
      false -> [] ++ positive_rec(tl)
    end
  end

  def positive_rec([]), do: []
  def positive_rec(number), do: [number] 

  def positive_tco(list) do
    do_positive(list, [])  
  end  

  defp do_positive([hd | tl], acc) do
    case hd >= 0 do
      true -> do_positive(tl, [hd] ++ acc)
      false -> do_positive(tl, acc)
    end
  end

  defp do_positive([], acc), do: Enum.reverse(acc)
  defp do_positive(last, acc), do: do_positive([], [last] ++ acc)
end

IO.puts "regular recursive:"
ListHelper.positive_rec([])
|> IO.inspect
ListHelper.positive_rec([1])
|> IO.inspect
ListHelper.positive_rec([-1])
|> IO.inspect
ListHelper.positive_rec([1, -2, 3])
|> IO.inspect

IO.inspect "tail recursive:"
ListHelper.positive_tco([])
|> IO.inspect
ListHelper.positive_tco([1])
|> IO.inspect
ListHelper.positive_tco([-1])
|> IO.inspect
ListHelper.positive_tco([1, -2, 3])
|> IO.inspect
