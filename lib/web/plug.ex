defmodule GriffinSSG.Web.Plug do
  @moduledoc """
  <%= @app_module %> Cowboy Plug to serve files from the output directory
  WARNING: This is a simple webserver written only to serve files from disk.
  It is meant only for usage in development environments. Please do not use
  this as a means to serve your generated website.
  """
  import Plug.Conn

  require Logger

  @output_path Application.compile_env(:griffin_ssg, :output_path, "_site")

  def init(options) do
    options
  end

  @doc """
  Simple route that serves files from the configured Griffin output directory.
  """
  @spec call(Plug.Conn.t(), any) :: Plug.Conn.t()
  def call(conn, _opts) do
    filename = "#{@output_path}/#{conn.request_path}"

    if File.exists?(filename) do
      Logger.info("200 #{@output_path}#{conn.request_path}")
      send_file(conn, 200, filename)
    else
      Logger.info("404 #{@output_path}#{conn.request_path}")
      send_resp(conn, 404, "File not found")
    end
  end
end
