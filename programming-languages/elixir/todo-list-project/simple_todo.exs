defmodule TodoList do
  def new(), do: %{}
   
  def add_entry(list, date, task) do
    # How the book solved it
    Map.update(
      list, 
      date,
      [task],
      fn other_tasks -> [task | other_tasks] end 
    )

    # Personal way of solving it
    # other_tasks = Map.get(list, date, [])
    # Map.put(list, date, [task] ++ other_tasks) 
  end
  
  def entries(list, date) do
    # solved it the same way as the book
    Map.get(list, date, [])
  end
end

# expect ["Movies", "Dentist"]
TodoList.new()
|> TodoList.add_entry(~D[2023-12-19], "Dentist")
|> TodoList.add_entry(~D[2023-12-20], "Shopping")
|> TodoList.add_entry(~D[2023-12-19], "Movies")
|> TodoList.entries(~D[2023-12-19])
|> IO.inspect()
