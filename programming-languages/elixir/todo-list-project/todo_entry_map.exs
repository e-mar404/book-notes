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
  
  def add_entry(list, entry) do
    MultiDict.add(list, entry.date, entry)
  end

  def entries(list, date) do
    MultiDict.get(list, date)
  end
end

# expect [%{date: ~D[2023-12-19], task: "Movies"}, %{date: ~D[2023-12-19], task: "Dentist"}]
TodoList.new()
|> TodoList.add_entry(%{date: ~D[2023-12-19], task: "Dentist"})
|> TodoList.add_entry(%{date: ~D[2023-12-20], task: "Shopping"})
|> TodoList.add_entry(%{date: ~D[2023-12-19], task: "Movies"})
|> TodoList.entries(~D[2023-12-19])
|> IO.inspect()
