defmodule MyApp.Supervisor do
  use Supervisor

  def start_link do
    Supervisor.start_link(__MODULE__, :ok)
  end

  @manager_name MyApp.EventManager
  @registry_name MyApp.Registry
  @ets_registry_name MyApp.Registry
  @bucket_supervisor_name MyApp.Bucket.Supervisor

  def init(:ok) do
    children = [
      worker(GenEvent, [[name: @manager_name]]),
      supervisor(MyApp.Bucket.Supervisor, [[name: @bucket_supervisor_name]]),
      worker(MyApp.Registry, [@ets_registry_name, @manager_name, @bucket_supervisor_name, [name: @registry_name]])
    ]

    supervise(children, strategy: :one_for_one)
  end
end
