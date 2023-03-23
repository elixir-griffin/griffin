defmodule GriffinSSGApp do
  use Application

  @default_port "4000"

  @doc false
  def start(_type, _args) do
    children = [
      {Plug.Cowboy, scheme: :http, plug: GriffinSSG.Web.Plug, options: [port: http_port()]}
    ]

    Supervisor.start_link(children, strategy: :one_for_one, name: Griffin.Supervisor)
  end

  defp http_port do
    fallback =
      "GRIFFIN_HTTP_PORT"
      |> System.get_env(@default_port)
      |> Integer.parse()
      |> then(fn {integer, _remainder} -> integer end)

    Application.get_env(:griffin_ssg, :http_port, fallback)
  end
end
