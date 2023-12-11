defmodule GriffinSSG.Web.Plug do
  @moduledoc """
  Defines a simple HTTP server with LiveReload. Spawned from the `grf.server` task.
  PlugLiveReload doesn't work within the context of a Plug.Builder, so we can't use
  Plug.Static to serve the files. Instead, we use Plug.Router and need to implement
  the file serving logic, which is... unfortunate.
  """
  use Plug.Router
  use Plug.ErrorHandler

  plug(PlugLiveReload)

  plug(:match)
  plug(:dispatch)

  match "*path" do
    expanded_path =
      [output_dir() | path]
      |> Path.join()
      |> Path.expand()

    if File.exists?(expanded_path) and File.dir?(expanded_path) do
      send_file(conn, Path.join(expanded_path, "index.html"))
    else
      send_file(conn, expanded_path)
    end
  end

  defp send_file(conn, path) do
    case File.read(path) do
      {:ok, file} ->
        conn
        |> put_resp_content_type(MIME.from_path(path))
        |> send_resp(200, file)

      {:error, :enoent} ->
        send_resp(conn, 404, "not found")
    end
  end

  @impl Plug.ErrorHandler
  def handle_errors(conn, _) do
    send_resp(conn, conn.status, "internal server error")
  end

  defp output_dir do
    Application.get_env(:griffin, :output, "_site")
  end
end
