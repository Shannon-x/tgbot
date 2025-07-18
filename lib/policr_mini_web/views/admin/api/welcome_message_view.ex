defmodule PolicrMiniWeb.Admin.Api.WelcomeMessageView do
  use PolicrMiniWeb, :view

  def render("show.json", %{welcome_message: message}) do
    %{
      welcome_message: %{
        chat_id: message.chat_id,
        enabled: message.enabled,
        text: message.text,
        parse_mode: message.parse_mode,
        photo_file_id: message.photo_file_id,
        buttons: message.buttons,
        delete_delay: message.delete_delay,
        inserted_at: message.inserted_at,
        updated_at: message.updated_at
      }
    }
  end
end