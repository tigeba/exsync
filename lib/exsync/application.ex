require Logger

defmodule ExSync.Application do
  def start(_, _) do
    case Application.get_env(:exsync, :enabled, false) do
      true ->
        case :code.module_status(Mix) do
          :loaded ->
              start_supervisor()
          :not_loaded ->
            Logger.info("ExSync not started. Mix not present.")
            {:ok, self()}
        end
      false ->
        {:ok, self()}
    end
  end

  def start() do
    Application.ensure_all_started(:exsync)
  end

  def start_supervisor do
    children =
      [
        ExSync.Logger.Server,
        maybe_include_src_monitor(),
        ExSync.BeamMonitor
      ]
      |> List.flatten()

    opts = [
      strategy: :one_for_one,
      max_restarts: 2,
      max_seconds: 3,
      name: ExSync.Supervisor
    ]

    Supervisor.start_link(children, opts)
  end

  def maybe_include_src_monitor do
    if ExSync.Config.src_monitor_enabled() do
      [ExSync.SrcMonitor]
    else
      []
    end
  end

  defdelegate register_group_leader, to: ExSync.Logger.Server
end
