defmodule PolicrMiniBot.WelcomeMessageSender do
  @moduledoc """
  欢迎消息发送器。
  """

  alias PolicrMini.{Repo, Chats}
  alias PolicrMini.Chats.WelcomeMessage
  alias Telegex.Type.{InlineKeyboardMarkup, InlineKeyboardButton}
  
  import PolicrMiniBot.Helper
  
  require Logger

  @doc """
  发送欢迎消息给新加入的用户。
  """
  def send_welcome_message(chat_id, user) do
    with {:ok, welcome_msg} <- get_welcome_message(chat_id),
         true <- welcome_msg.enabled do
      send_message(chat_id, user, welcome_msg)
    else
      _ -> :ok
    end
  end

  @doc """
  使用指定的配置发送欢迎消息（用于预览）。
  """
  def send_welcome_message(chat_id, user, welcome_msg) do
    send_message(chat_id, user, welcome_msg)
  end

  # 获取欢迎消息配置
  defp get_welcome_message(chat_id) do
    case Repo.get_by(WelcomeMessage, chat_id: chat_id) do
      nil -> {:error, :not_found}
      config -> {:ok, config}
    end
  end

  # 发送消息
  defp send_message(chat_id, user, welcome_msg) do
    # 替换变量
    text = replace_variables(welcome_msg.text, user)
    
    # 构建键盘
    reply_markup = build_keyboard(welcome_msg.buttons)
    
    # 发送选项
    options = [
      parse_mode: welcome_msg.parse_mode,
      reply_markup: reply_markup
    ] |> Enum.filter(fn {_, v} -> v != nil end)
    
    # 发送消息
    result = if welcome_msg.photo_file_id do
      smart_sender(:send_photo, [chat_id, welcome_msg.photo_file_id, options ++ [caption: text]])
    else
      smart_sender(:send_message, [chat_id, text, options])
    end
    
    # 如果设置了删除延迟，安排删除任务
    case result do
      {:ok, message} when welcome_msg.delete_delay > 0 ->
        schedule_delete_message(chat_id, message.message_id, welcome_msg.delete_delay)
      _ ->
        :ok
    end
    
    result
  end

  # 替换变量
  defp replace_variables(text, user) do
    text
    |> String.replace("{user_id}", to_string(user.id))
    |> String.replace("{username}", "@#{user.username || "user"}")
    |> String.replace("{first_name}", user.first_name || "")
    |> String.replace("{last_name}", user.last_name || "")
    |> String.replace("{full_name}", full_name(user))
    |> String.replace("{mention}", mention_user(user))
  end

  # 获取用户全名
  defp full_name(user) do
    [user.first_name, user.last_name]
    |> Enum.filter(& &1)
    |> Enum.join(" ")
  end

  # 提及用户
  defp mention_user(user) do
    "<a href=\"tg://user?id=#{user.id}\">#{full_name(user)}</a>"
  end

  # 构建键盘
  defp build_keyboard(nil), do: nil
  defp build_keyboard(buttons_json) do
    case Jason.decode(buttons_json) do
      {:ok, buttons} ->
        inline_keyboard = 
          buttons
          |> Enum.map(&build_button_row/1)
          |> Enum.filter(& &1)
        
        if Enum.empty?(inline_keyboard) do
          nil
        else
          %InlineKeyboardMarkup{inline_keyboard: inline_keyboard}
        end
      _ ->
        nil
    end
  end

  # 构建按钮行
  defp build_button_row(row) when is_list(row) do
    buttons = 
      row
      |> Enum.map(&build_button/1)
      |> Enum.filter(& &1)
    
    if Enum.empty?(buttons), do: nil, else: buttons
  end
  defp build_button_row(button), do: build_button_row([button])

  # 构建单个按钮
  defp build_button(%{"text" => text, "url" => url}) do
    %InlineKeyboardButton{text: text, url: url}
  end
  defp build_button(%{"text" => text, "callback_data" => callback_data}) do
    %InlineKeyboardButton{text: text, callback_data: callback_data}
  end
  defp build_button(_), do: nil

  # 安排删除消息
  defp schedule_delete_message(chat_id, message_id, delay) do
    async_run(fn ->
      :timer.sleep(delay * 1000)
      Telegex.delete_message(chat_id, message_id)
    end, delay_secs: delay)
  end
end