defmodule MyApp.Bucket do

  @doc """
  Starts a new bucket.
  """
  def start_link do
    Agent.start_link(fn -> HashDict.new end)
  end

  @doc """
  Get a value from the bucket.
  """
  def get(bucket, key) do
    Agent.get(bucket, &HashDict.get(&1, key))
  end

  @doc """
  Set a value.
  """
  def put(bucket, key, value) do
    Agent.update(bucket, &HashDict.put(&1, key, value))
  end

  @doc """
  Delete a value, returning if key is present.
  """
  def delete(bucket, key) do
    Agent.get_and_update(bucket, fn dict->
      HashDict.pop(dict, key)
    end)
  end
end
