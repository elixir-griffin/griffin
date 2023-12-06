defmodule GriffinSSG.Web.Plug do
  use Plug.Router
  use Plug.Debugger
  use Plug.ErrorHandler

  plug(PlugLiveReload)
  plug(Plug.Logger, log: :debug)
  plug(:match)
  plug(:dispatch)

  @output_path Application.compile_env(:griffin_ssg, :output_path, "_site")

  match "*path" do
    file_path = Path.join([@output_path | path])
    handle_request(conn, file_path)
  end

  @impl Plug.ErrorHandler
  def handle_errors(conn, %{kind: _kind, reason: _reason, stack: _stack}) do
    send_resp(conn, conn.status, "Something went wrong")
  end

  def handle_request(conn, file_path) do
    mime_type = MIME.from_path(file_path)

    case File.read(file_path) do
      {:ok, body} ->
        conn
        |> put_resp_content_type(mime_type)
        |> send_resp(200, body)

      {:error, :enoent} ->
        conn
        |> put_resp_content_type(mime_type)
        |> send_resp(404, "Not found")

      {:error, :eisdir} ->
        # request was for a directory
        conn
        |> handle_request(Path.join(file_path, "index.html"))
    end
  end
end
