# practice 3.4 pg 99
# a list_len/1 function that calculates the length of a list
defmodule ListHelper do
  def list_len_rec([_ | tl]) do
    1 + list_len_rec(tl)     
  end 

  def list_len_rec([]), do: 0
  def list_len_rec(_), do: 1

  def list_len_tco(list) do
    do_list_len_tco(list, 0) 
  end

  defp do_list_len_tco([_ | tl], count) do
    do_list_len_tco(tl, count + 1)  
  end

  defp do_list_len_tco([], count) do
    count
  end
end

IO.puts "regular recursive:"

ListHelper.list_len_rec([])
|> IO.puts
ListHelper.list_len_rec([1])
|> IO.puts
ListHelper.list_len_rec([1, 2, 3])
|> IO.puts

IO.puts "tail recursive:"
ListHelper.list_len_tco([])
|> IO.puts
ListHelper.list_len_tco([1])
|> IO.puts
ListHelper.list_len_tco([1, 2, 3])
|> IO.puts
