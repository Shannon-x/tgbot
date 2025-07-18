defmodule PolicrMiniBot.RespBanChain do
  @moduledoc """
  /ban 命令处理链，支持封禁、禁言、解除禁言等操作。
  
  使用方法：
  - /ban @username [时长] - 封禁用户
  - /ban 123456789 [时长] - 通过用户ID封禁
  - /mute @username [时长] - 禁言用户（默认5分钟）
  - /unmute @username - 解除禁言
  - /kick @username - 踢出用户
  
  时长格式：
  - 5m - 5分钟
  - 2h - 2小时
  - 1d - 1天
  - 永久封禁不需要指定时长
  """

  use PolicrMiniBot.Chain, only: :message

  alias Telegex.Type.{Message, User}
  import PolicrMiniBot.Helper

  require Logger

  @impl true
  def match?(%{text: "/" <> command} = _message, _context) do
    command |> String.split(" ", parts: 2) |> hd() |> String.downcase() in ["ban", "mute", "unmute", "kick"]
  end

  def match?(_message, _context), do: false

  @impl true
  def handle(%{chat: %{type: chat_type}} = message, _context) when chat_type in ["group", "supergroup"] do
    %{chat: %{id: chat_id}, from: from_user, text: text} = message

    # 检查发送者是否为管理员
    with {:ok, member} <- Telegex.get_chat_member(chat_id, from_user.id),
         true <- is_admin?(member) do
      process_command(message)
    else
      false ->
        smart_sender(:send_message, [chat_id, "❌ 只有管理员才能使用此命令", [reply_to_message_id: message.message_id]])
      _ ->
        :ignored
    end

    :ignored
  end

  def handle(_message, _context), do: :ignored

  # 处理命令
  defp process_command(%{text: text, chat: %{id: chat_id}} = message) do
    [command | args] = text |> String.split(" ", trim: true)
    command = command |> String.trim_leading("/") |> String.downcase()

    case {command, parse_args(args, message)} do
      {"ban", {:ok, user_id, duration}} ->
        ban_user(chat_id, user_id, duration, message)
      
      {"mute", {:ok, user_id, duration}} ->
        mute_user(chat_id, user_id, duration || 300, message)  # 默认5分钟
      
      {"unmute", {:ok, user_id, _}} ->
        unmute_user(chat_id, user_id, message)
      
      {"kick", {:ok, user_id, _}} ->
        kick_user(chat_id, user_id, message)
      
      {_, {:error, reason}} ->
        smart_sender(:send_message, [chat_id, reason, [reply_to_message_id: message.message_id]])
    end
  end

  # 解析命令参数
  defp parse_args([], %{reply_to_message: %{from: %{id: user_id}}}) do
    {:ok, user_id, nil}
  end

  defp parse_args([], _message) do
    {:error, "❌ 请指定要操作的用户（@用户名、用户ID或回复其消息）"}
  end

  defp parse_args([target | rest], message) do
    case parse_target(target, message) do
      {:ok, user_id} ->
        duration = parse_duration(rest)
        {:ok, user_id, duration}
      error ->
        error
    end
  end

  # 解析目标用户
  defp parse_target("@" <> username, %{chat: %{id: chat_id}}) do
    # 通过用户名查找（注意：这需要用户在群组中）
    case Telegex.get_chat_member(chat_id, "@" <> username) do
      {:ok, %{user: %{id: user_id}}} -> {:ok, user_id}
      _ -> {:error, "❌ 找不到用户 @#{username}"}
    end
  end

  defp parse_target(target, _message) do
    case Integer.parse(target) do
      {user_id, ""} -> {:ok, user_id}
      _ -> {:error, "❌ 无效的用户标识：#{target}"}
    end
  end

  # 解析时长
  defp parse_duration([]), do: nil
  defp parse_duration([duration_str | _]) do
    case parse_duration_string(duration_str) do
      {:ok, seconds} -> seconds
      _ -> nil
    end
  end

  defp parse_duration_string(str) do
    regex = ~r/^(\d+)([mhd]?)$/i
    
    case Regex.run(regex, str) do
      [_, number, unit] ->
        num = String.to_integer(number)
        seconds = case String.downcase(unit) do
          "m" -> num * 60
          "h" -> num * 3600
          "d" -> num * 86400
          _ -> num  # ���认为秒
        end
        {:ok, seconds}
      _ ->
        {:error, :invalid_format}
    end
  end

  # 封禁用户
  defp ban_user(chat_id, user_id, duration, message) do
    until_date = if duration, do: DateTime.utc_now() |> DateTime.add(duration, :second) |> DateTime.to_unix()
    
    case Telegex.ban_chat_member(chat_id, user_id, until_date: until_date) do
      {:ok, _} ->
        duration_text = if duration, do: "#{format_duration(duration)}", else: "永久"
        smart_sender(:send_message, [
          chat_id, 
          "✅ 已封禁用户 ##{user_id} (#{duration_text})", 
          [reply_to_message_id: message.message_id]
        ])
      {:error, error} ->
        smart_sender(:send_message, [
          chat_id, 
          "❌ 封禁失败：#{inspect(error)}", 
          [reply_to_message_id: message.message_id]
        ])
    end
  end

  # 禁言用户
  defp mute_user(chat_id, user_id, duration, message) do
    until_date = DateTime.utc_now() |> DateTime.add(duration, :second) |> DateTime.to_unix()
    
    permissions = %Telegex.Type.ChatPermissions{
      can_send_messages: false,
      can_send_audios: false,
      can_send_documents: false,
      can_send_photos: false,
      can_send_videos: false,
      can_send_video_notes: false,
      can_send_voice_notes: false,
      can_send_polls: false,
      can_send_other_messages: false,
      can_add_web_page_previews: false
    }
    
    case Telegex.restrict_chat_member(chat_id, user_id, permissions, until_date: until_date) do
      {:ok, _} ->
        smart_sender(:send_message, [
          chat_id, 
          "🔇 已禁言用户 ##{user_id} (#{format_duration(duration)})", 
          [reply_to_message_id: message.message_id]
        ])
      {:error, error} ->
        smart_sender(:send_message, [
          chat_id, 
          "❌ 禁言失败：#{inspect(error)}", 
          [reply_to_message_id: message.message_id]
        ])
    end
  end

  # 解除禁言
  defp unmute_user(chat_id, user_id, message) do
    permissions = %Telegex.Type.ChatPermissions{
      can_send_messages: true,
      can_send_audios: true,
      can_send_documents: true,
      can_send_photos: true,
      can_send_videos: true,
      can_send_video_notes: true,
      can_send_voice_notes: true,
      can_send_polls: true,
      can_send_other_messages: true,
      can_add_web_page_previews: true
    }
    
    case Telegex.restrict_chat_member(chat_id, user_id, permissions) do
      {:ok, _} ->
        smart_sender(:send_message, [
          chat_id, 
          "🔊 已解除用户 ##{user_id} 的禁言", 
          [reply_to_message_id: message.message_id]
        ])
      {:error, error} ->
        smart_sender(:send_message, [
          chat_id, 
          "❌ 解除禁言失败：#{inspect(error)}", 
          [reply_to_message_id: message.message_id]
        ])
    end
  end

  # 踢出用户
  defp kick_user(chat_id, user_id, message) do
    case Telegex.ban_chat_member(chat_id, user_id) do
      {:ok, _} ->
        # 立即解封以实现踢出效果
        Telegex.unban_chat_member(chat_id, user_id)
        smart_sender(:send_message, [
          chat_id, 
          "👢 已踢出用户 ##{user_id}", 
          [reply_to_message_id: message.message_id]
        ])
      {:error, error} ->
        smart_sender(:send_message, [
          chat_id, 
          "❌ 踢出失败：#{inspect(error)}", 
          [reply_to_message_id: message.message_id]
        ])
    end
  end

  # 检查是否为管理员
  defp is_admin?(member) do
    member.status in ["creator", "administrator"]
  end

  # 格式化时长
  defp format_duration(seconds) when seconds < 60, do: "#{seconds}秒"
  defp format_duration(seconds) when seconds < 3600, do: "#{div(seconds, 60)}分钟"
  defp format_duration(seconds) when seconds < 86400, do: "#{div(seconds, 3600)}小时"
  defp format_duration(seconds), do: "#{div(seconds, 86400)}天"
end