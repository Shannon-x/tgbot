defmodule PolicrMini.Chats.AntiSpamConfig do
  @moduledoc """
  反垃圾配置模型。
  """

  use PolicrMini.Schema

  @type t :: %__MODULE__{
          chat_id: integer,
          enabled: boolean,
          time_window: integer,
          max_messages: integer,
          max_duplicate_messages: integer,
          action: String.t(),
          mute_duration: integer,
          inserted_at: NaiveDateTime.t(),
          updated_at: NaiveDateTime.t()
        }

  @required_fields ~w(chat_id)a
  @optional_fields ~w(enabled time_window max_messages max_duplicate_messages action mute_duration)a

  schema "anti_spam_configs" do
    field :chat_id, :integer
    field :enabled, :boolean, default: false
    field :time_window, :integer, default: 60
    field :max_messages, :integer, default: 10
    field :max_duplicate_messages, :integer, default: 3
    field :action, :string, default: "mute"
    field :mute_duration, :integer, default: 300

    timestamps()
  end

  def changeset(anti_spam_config, attrs) do
    anti_spam_config
    |> cast(attrs, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
    |> validate_inclusion(:action, ["mute", "kick", "ban"])
    |> validate_number(:time_window, greater_than: 0, less_than_or_equal_to: 300)
    |> validate_number(:max_messages, greater_than: 0, less_than_or_equal_to: 100)
    |> validate_number(:max_duplicate_messages, greater_than: 0, less_than_or_equal_to: 50)
    |> validate_number(:mute_duration, greater_than: 0, less_than_or_equal_to: 86400)
    |> unique_constraint(:chat_id)
  end
end