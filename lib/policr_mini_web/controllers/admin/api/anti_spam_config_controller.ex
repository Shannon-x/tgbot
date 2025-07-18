defmodule PolicrMiniWeb.Admin.Api.AntiSpamConfigController do
  @moduledoc """
  反垃圾配置 API 控制器。
  """

  use PolicrMiniWeb, :controller

  alias PolicrMini.{Repo, Chats}
  alias PolicrMini.Chats.AntiSpamConfig

  import PolicrMiniWeb.Helper

  action_fallback PolicrMiniWeb.Api.FallbackController

  def show(conn, %{"id" => chat_id}) do
    chat_id = to_int(chat_id)

    with {:ok, _} <- check_permissions(conn, chat_id),
         config <- get_or_create_config(chat_id) do
      render(conn, "show.json", anti_spam_config: config)
    end
  end

  def update(conn, %{"id" => chat_id} = params) do
    chat_id = to_int(chat_id)

    with {:ok, _} <- check_permissions(conn, chat_id),
         config <- get_or_create_config(chat_id),
         {:ok, updated_config} <- update_config(config, params) do
      render(conn, "show.json", anti_spam_config: updated_config)
    end
  end

  # 获取或创建配置
  defp get_or_create_config(chat_id) do
    case Repo.get_by(AntiSpamConfig, chat_id: chat_id) do
      nil ->
        %AntiSpamConfig{chat_id: chat_id}
        |> AntiSpamConfig.changeset(%{})
        |> Repo.insert!()
      config ->
        config
    end
  end

  # 更新配置
  defp update_config(config, params) do
    config
    |> AntiSpamConfig.changeset(params)
    |> Repo.update()
  end

  # 检查权限
  defp check_permissions(conn, chat_id) do
    user = get_user(conn)
    
    case PolicrMini.Businesses.PermissionBusiness.find(chat_id, user.id) do
      {:ok, %{writable: true}} -> {:ok, :authorized}
      _ -> {:error, :forbidden}
    end
  end
end