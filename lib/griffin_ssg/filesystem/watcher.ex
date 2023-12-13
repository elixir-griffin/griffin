defmodule GriffinSSG.Filesystem.Watcher do
  @moduledoc """
  Module for non-named GenServer responsible for watching for changes.
  Executes a generic callback when file changes are detected.
  Used for the LiveReload HTTPServer that is launched as part of `mix grf.server`.
  """
  use GenServer

  @swap_file_extnames [".swp", ".swx"]

  def start_link([directories, callback]) do
    GenServer.start_link(__MODULE__, {directories, callback})
  end

  def init({directories, callback}) do
    {:ok, pid} = FileSystem.start_link(dirs: directories)
    FileSystem.subscribe(pid)
    {:ok, %{callback: callback}}
  end

  def handle_info({:file_event, _watcher_pid, {file_path, [:modified, :closed]}}, state) do
    unless Path.extname(file_path) in @swap_file_extnames do
      state.callback.()
    end

    {:noreply, state}
  end

  def handle_info({:file_event, _, _}, state) do
    {:noreply, state}
  end
end
