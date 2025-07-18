defmodule PolicrMiniWeb.Admin.Api.AntiSpamConfigView do
  use PolicrMiniWeb, :view

  def render("show.json", %{anti_spam_config: config}) do
    %{
      anti_spam_config: %{
        chat_id: config.chat_id,
        enabled: config.enabled,
        time_window: config.time_window,
        max_messages: config.max_messages,
        max_duplicate_messages: config.max_duplicate_messages,
        action: config.action,
        mute_duration: config.mute_duration,
        inserted_at: config.inserted_at,
        updated_at: config.updated_at
      }
    }
  end
end