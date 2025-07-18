defmodule PolicrMiniBot.AntiSpamChain do
  @moduledoc """
  反垃圾消息检测处理链。
  """

  use PolicrMiniBot.Chain

  alias PolicrMini.{Repo, Chats}
  alias PolicrMini.Chats.{AntiSpamConfig, UserMessageRecord}
  alias Telegex.Type.Message

  import Ecto.Query
  import PolicrMiniBot.Helper

  require Logger

  @impl true
  def match?(%{chat: %{type: chat_type}} = message, _context) when chat_type in ["group", "supergroup"] do
    # 只处理群组消息
    message.text != nil || message.caption != nil
  end

  def match?(_message, _context), do: false

  @impl true
  def handle(message, _context) do
    %{chat: %{id: chat_id}, from: %{id: user_id}, message_id: message_id} = message

    with {:ok, config} <- get_anti_spam_config(chat_id),
         true <- config.enabled,
         {:ok, _} <- record_message(chat_id, user_id, message_id, message),
         {:spam, reason} <- check_spam(chat_id, user_id, config) do
      
      Logger.info("Spam detected for user #{user_id} in chat #{chat_id}, reason: #{reason}")
      handle_spam_action(chat_id, user_id, config, reason)
    end

    :ignored
  end

  # 获取反垃圾配置
  defp get_anti_spam_config(chat_id) do
    case Repo.get_by(AntiSpamConfig, chat_id: chat_id) do
      nil -> {:ok, %AntiSpamConfig{enabled: false}}
      config -> {:ok, config}
    end
  end

  # 记录消息
  defp record_message(chat_id, user_id, message_id, message) do
    content = extract_content(message)
    content_hash = if content, do: :crypto.hash(:md5, content) |> Base.encode16(), else: nil

    %UserMessageRecord{}
    |> UserMessageRecord.changeset(%{
      chat_id: chat_id,
      user_id: user_id,
      message_id: message_id,
      content_hash: content_hash
    })
    |> Repo.insert()
  end

  # 提取消息内容
  defp extract_content(message) do
    message.text || message.caption
  end

  # 检查是否为垃圾消息
  defp check_spam(chat_id, user_id, config) do
    time_ago = NaiveDateTime.utc_now() |> NaiveDateTime.add(-config.time_window, :second)

    # 查询时间窗口内的消息
    recent_messages = 
      from(r in UserMessageRecord,
        where: r.chat_id == ^chat_id and r.user_id == ^user_id and r.inserted_at >= ^time_ago,
        order_by: [desc: r.inserted_at]
      )
      |> Repo.all()

    # 检查消息频率
    if length(recent_messages) > config.max_messages do
      {:spam, :too_many_messages}
    else
      # 检查重复消息
      duplicate_count = 
        recent_messages
        |> Enum.filter(& &1.content_hash)
        |> Enum.group_by(& &1.content_hash)
        |> Enum.map(fn {_hash, messages} -> length(messages) end)
        |> Enum.max(fn -> 0 end)

      if duplicate_count > config.max_duplicate_messages do
        {:spam, :duplicate_messages}
      else
        :ok
      end
    end
  end

  # 处理垃圾消息动作
  defp handle_spam_action(chat_id, user_id, config, reason) do
    case config.action do
      "mute" ->
        # 禁言用户
        until_date = DateTime.utc_now() |> DateTime.add(config.mute_duration, :second) |> DateTime.to_unix()
        
        case Telegex.restrict_chat_member(chat_id, user_id, %Telegex.Type.ChatPermissions{
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
        }, until_date: until_date) do
          {:ok, _} ->
            Logger.info("Muted user #{user_id} in chat #{chat_id} for #{config.mute_duration} seconds")
            send_notification(chat_id, user_id, :muted, reason, config.mute_duration)
          {:error, error} ->
            Logger.error("Failed to mute user #{user_id} in chat #{chat_id}: #{inspect(error)}")
        end

      "kick" ->
        # 踢出用户
        case Telegex.ban_chat_member(chat_id, user_id) do
          {:ok, _} ->
            Logger.info("Kicked user #{user_id} from chat #{chat_id}")
            # 立即解封，实现踢出效果
            Telegex.unban_chat_member(chat_id, user_id)
            send_notification(chat_id, user_id, :kicked, reason, nil)
          {:error, error} ->
            Logger.error("Failed to kick user #{user_id} from chat #{chat_id}: #{inspect(error)}")
        end

      "ban" ->
        # 封禁用户
        case Telegex.ban_chat_member(chat_id, user_id) do
          {:ok, _} ->
            Logger.info("Banned user #{user_id} from chat #{chat_id}")
            send_notification(chat_id, user_id, :banned, reason, nil)
          {:error, error} ->
            Logger.error("Failed to ban user #{user_id} from chat #{chat_id}: #{inspect(error)}")
        end
    end

    # 清理旧记录（保留最近1小时的记录）
    clean_old_records(chat_id, user_id)
  end

  # 发送通知
  defp send_notification(chat_id, user_id, action, reason, duration) do
    action_text = case action do
      :muted -> "禁言 #{duration} 秒"
      :kicked -> "踢出群组"
      :banned -> "封禁"
    end

    reason_text = case reason do
      :too_many_messages -> "发送消息过于频繁"
      :duplicate_messages -> "发送重复消息"
    end

    text = "⚠️ 用户 ##{user_id} 因#{reason_text}被#{action_text}"
    
    smart_sender(:send_message, [chat_id, text])
  end

  # 清理旧记录
  defp clean_old_records(chat_id, user_id) do
    one_hour_ago = NaiveDateTime.utc_now() |> NaiveDateTime.add(-3600, :second)
    
    from(r in UserMessageRecord,
      where: r.chat_id == ^chat_id and r.user_id == ^user_id and r.inserted_at < ^one_hour_ago
    )
    |> Repo.delete_all()
  end
end