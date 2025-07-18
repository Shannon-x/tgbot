defmodule PolicrMiniWeb.Admin.Api.WelcomeMessageController do
  @moduledoc """
  欢迎消息配置 API 控制器。
  """

  use PolicrMiniWeb, :controller

  alias PolicrMini.{Repo, Chats}
  alias PolicrMini.Chats.WelcomeMessage

  import PolicrMiniWeb.Helper

  action_fallback PolicrMiniWeb.Api.FallbackController

  def show(conn, %{"id" => chat_id}) do
    chat_id = to_int(chat_id)

    with {:ok, _} <- check_permissions(conn, chat_id),
         config <- get_or_create_config(chat_id) do
      render(conn, "show.json", welcome_message: config)
    end
  end

  def update(conn, %{"id" => chat_id} = params) do
    chat_id = to_int(chat_id)

    with {:ok, _} <- check_permissions(conn, chat_id),
         config <- get_or_create_config(chat_id),
         {:ok, updated_config} <- update_config(config, params) do
      render(conn, "show.json", welcome_message: updated_config)
    end
  end

  # 预览欢迎消息
  def preview(conn, %{"id" => chat_id} = params) do
    chat_id = to_int(chat_id)

    with {:ok, _} <- check_permissions(conn, chat_id) do
      # 发送预览消息到群组
      send_preview_message(chat_id, params)
      json(conn, %{ok: true})
    end
  end

  # 获取或创建配置
  defp get_or_create_config(chat_id) do
    case Repo.get_by(WelcomeMessage, chat_id: chat_id) do
      nil ->
        %WelcomeMessage{chat_id: chat_id}
        |> WelcomeMessage.changeset(%{})
        |> Repo.insert!()
      config ->
        config
    end
  end

  # 更新配置
  defp update_config(config, params) do
    config
    |> WelcomeMessage.changeset(params)
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

  # 发送预览消息
  defp send_preview_message(chat_id, params) do
    # 创建临时用户对象用于预览
    preview_user = %{
      id: 0,
      first_name: "预览",
      last_name: "用户",
      username: "preview_user"
    }

    # 创建临时欢迎消息配置
    temp_config = %WelcomeMessage{
      chat_id: chat_id,
      enabled: true,
      text: params["text"] || "欢迎 {mention} 加入群组！",
      parse_mode: params["parse_mode"] || "HTML",
      photo_file_id: params["photo_file_id"],
      buttons: params["buttons"],
      delete_delay: 30  # 预览消息30秒后删除
    }

    # 使用欢迎消息发送器发送预览
    PolicrMiniBot.WelcomeMessageSender.send_welcome_message(chat_id, preview_user, temp_config)
  end
end