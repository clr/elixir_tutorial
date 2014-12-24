defmodule MyApp do
  use Application

  def start(_type, _args) do
    MyApp.Supervisor.start_link
  end
end
