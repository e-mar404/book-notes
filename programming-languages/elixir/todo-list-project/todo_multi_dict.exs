defmodule MultiDict do
  def new(), do: %{}
   
  def add(list, key, value) do
    Map.update(list, key, [value], &[value | &1])
  end
  
  def get(list, key) do
    Map.get(list, key, [])
  end
end

defmodule TodoList do
  def new(), do: MultiDict.new()
  
  def add_entry(list, date, task) do
    MultiDict.add(list, date, task)
  end

  def entries(list, date) do
    MultiDict.get(list, date)
  end
end

# expect ["Movies", "Dentist"]
TodoList.new()
|> TodoList.add_entry(~D[2023-12-19], "Dentist")
|> TodoList.add_entry(~D[2023-12-20], "Shopping")
|> TodoList.add_entry(~D[2023-12-19], "Movies")
|> TodoList.entries(~D[2023-12-19])
|> IO.inspect()
