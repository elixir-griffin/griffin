defmodule GriffinSSG.Config do
  @moduledoc """
  This module is responsible for storing and retrieving configuration values.
  It exposes a `get/0` function that returns the current configuration and a
  `put/2` function that allows you to update the configuration. Additionally,
  the other functions in this module allow easy configuration of the application.
  """
  use Agent

  def start_link() do
    Agent.start_link(fn -> %{} end, name: __MODULE__)
  end

  def get() do
    Application.get_all_env(:griffin_ssg)
    |> Map.new()
  end

  def get(key) do
    Application.get_env(:griffin_ssg, key)
  end

  def put(key, value) do
    Application.put_env(:griffin_ssg, key, value)
    get()
  end

  def put_all(values) do
    for {option, value} <- values do
      put(option, value)
    end
    get()
  end

  def register_hook(hook, callback) do
    hooks = get(:hooks) || %{}
    hook_list = Map.get(hooks, hook, [])
    put(:hooks, Map.put(hooks, hook, [callback | hook_list]))
    get()
  end
end