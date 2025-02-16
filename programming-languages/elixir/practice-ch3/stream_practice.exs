defmodule StreamHelper do
  def large_lines!(file) do
    File.stream!(file)
    |> Stream.map(&String.trim_leading(&1, "\n"))
    |> Enum.filter(&(String.length(&1) > 20))
  end

  def lines_length!(file) do
    File.stream!(file)
    |> Stream.map(&String.trim_leading(&1, "\n"))
    |> Stream.map(&String.length/1)
    |> Enum.to_list()
  end

  def longer_line_length!(file) do
    lines_length!(file)
    |> Enum.reduce(0, fn cur, max -> max(cur, max) end)
  end
  
  def words_per_line!(file) do
    File.stream!(file)
    |> Stream.map(&String.trim_leading(&1, "\n"))
    |> Stream.map(&length(String.split(&1, " ", trim: true)))
    |> Enum.to_list()
  end
end

IO.puts "large lines > 20"
StreamHelper.large_lines!("lines.txt")
|> IO.puts()

IO.puts "lines length"
StreamHelper.lines_length!("lines.txt")
|> IO.inspect()

IO.puts "longer_line_length"
StreamHelper.longer_line_length!("lines.txt")
|> IO.inspect()

IO.puts "words per line"
StreamHelper.words_per_line!("lines.txt")
|> IO.inspect()
