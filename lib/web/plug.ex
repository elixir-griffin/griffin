defmodule GriffinSSG.Web.Plug do
  @moduledoc """
  <%= @app_module %> Cowboy Plug to serve files from the output directory
  WARNING: This is a simple webserver written only to serve files from disk.
  It is meant only for usage in development environments. Please do not use
  this as a means to serve your generated website.
  """

  @output_path Application.compile_env(:griffin_ssg, :output_path, "_site")

  use Plug.Builder

  plug(:implicit_index_html)

  plug(Plug.Static, at: "/", from: @output_path)

  plug(:not_found)

  def implicit_index_html(conn, _) do
    path = conn.request_path
    if Path.extname(path) == "" do
      path = if String.ends_with?(path, "/"), do: path, else: "#{path}/"
      %{conn | request_path: "#{path}index.html", path_info: conn.path_info ++ ["index.html"] }
    else
      conn
    end
  end

  def not_found(conn, _) do
    send_resp(conn, 404, "not found")
  end
end
