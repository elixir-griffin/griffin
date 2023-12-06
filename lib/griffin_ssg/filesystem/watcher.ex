defmodule GriffinSSG.Filesystem.Watcher do
  use GenServer

  @swap_file_extnames [".swp", ".swx"]

  @spec start_link(any()) :: :ignore | {:error, any()} | {:ok, pid()}
  def start_link(directories) do
    GenServer.start_link(__MODULE__, [directories])
  end

  def init(directories) do
    {:ok, pid} = FileSystem.start_link(dirs: [directories])
    FileSystem.subscribe(pid)
    {:ok, []}
  end

  def handle_info({:file_event, _watcher_pid, {file_path, [:modified, :closed]}}, state) do
    # Can we do more clever builds here? (e.g. building only changed files)
    unless Path.extname(file_path) in @swap_file_extnames do
      Mix.Tasks.Grf.Build.run([])
    end

    {:noreply, state}
  end

  def handle_info({:file_event, _, _}, state) do
    {:noreply, state}
  end
end
