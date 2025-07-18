defmodule PolicrMini.Chats.WelcomeMessage do
  @moduledoc """
  欢迎消息配置模型。
  """

  use PolicrMini.Schema

  @type t :: %__MODULE__{
          chat_id: integer,
          enabled: boolean,
          text: String.t(),
          parse_mode: String.t(),
          photo_file_id: String.t() | nil,
          buttons: String.t() | nil,
          delete_delay: integer,
          inserted_at: NaiveDateTime.t(),
          updated_at: NaiveDateTime.t()
        }

  @required_fields ~w(chat_id)a
  @optional_fields ~w(enabled text parse_mode photo_file_id buttons delete_delay)a

  schema "welcome_messages" do
    field :chat_id, :integer
    field :enabled, :boolean, default: false
    field :text, :string
    field :parse_mode, :string, default: "HTML"
    field :photo_file_id, :string
    field :buttons, :string
    field :delete_delay, :integer, default: 0

    timestamps()
  end

  def changeset(welcome_message, attrs) do
    welcome_message
    |> cast(attrs, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
    |> validate_inclusion(:parse_mode, ["HTML", "Markdown", "MarkdownV2"])
    |> validate_number(:delete_delay, greater_than_or_equal_to: 0, less_than_or_equal_to: 3600)
    |> validate_buttons()
    |> unique_constraint(:chat_id)
  end

  # 验证按钮配置的 JSON 格式
  defp validate_buttons(changeset) do
    case get_change(changeset, :buttons) do
      nil -> changeset
      buttons ->
        case Jason.decode(buttons) do
          {:ok, _} -> changeset
          {:error, _} -> add_error(changeset, :buttons, "invalid JSON format")
        end
    end
  end
end