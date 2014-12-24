defmodule MyApp.Registry do
  use GenServer

  ## Client API

  @doc """
  Starts the registry
  """
  def start_link(table, event_manager, buckets, opts \\ []) do
    GenServer.start_link(__MODULE__, {table, event_manager, buckets}, opts)
  end

  @doc """
  Returns the pid for the name stored in the server.
  """
  def lookup(table, name) do
    case :ets.lookup(table, name) do
      [{name, bucket}] -> {:ok, bucket}
      [] -> :error
    end
  end

  @doc """
  Create a pid for the name representing the bucket.
  """
  def create(server, name) do
    GenServer.call(server, {:create, name})
  end

  @doc """
  Stop the server.
  """
  def stop(server) do
    GenServer.call(server, :stop)
  end

  ## Server API

  @doc """
  Start the server.
  """
  def init({table, events, buckets}) do
    names = :ets.new(table, [:named_table, read_concurrency: true])
    refs  = HashDict.new
    {:ok, %{names: names, refs: refs, events: events, buckets: buckets}}
  end

  @doc """
  Kill it.
  """
  def handle_call(:stop, _from, state) do
    {:stop, :normal, :ok, state}
  end

  @doc """
  Handle some calls.
  """
  def handle_call({:create, name}, state) do
    case lookup(state.names, name) do
      {:ok, _pid} -> {:noreply, state}
      :error ->
        {:ok, pid} = MyApp.Bucket.Supervisor.start_bucket(state.buckets)
        ref = Process.monitor(pid)
        refs = HashDict.put(state.refs, ref, name)
        :ets.insert(state.names, {name, pid})

        GenEvent.sync_notify(state.events, {:create, name, pid})
        {:noreply, %{state | refs: refs}}
    end
  end

  @doc """
  Catch if a bucket Agent goes down.
  """
  def handle_info({:DOWN, ref, :process, pid, _reason}, state) do
    {name, refs} = HashDict.pop(state.refs, ref)
    :ets.delete(state.names, name)

    GenEvent.sync_notify(state.events, {:stop, name, pid})
    {:noreply, %{state | refs: refs}}
  end

  @doc """
  Catch-all.
  """
  def handle_info(_msg, state) do
    {:noreply, state}
  end
end

