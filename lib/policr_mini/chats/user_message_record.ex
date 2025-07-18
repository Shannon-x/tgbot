defmodule PolicrMini.Chats.UserMessageRecord do
  @moduledoc """
  用户消息记录模型，用于反垃圾检测。
  """

  use PolicrMini.Schema

  @type t :: %__MODULE__{
          chat_id: integer,
          user_id: integer,
          message_id: integer,
          content_hash: String.t(),
          inserted_at: NaiveDateTime.t()
        }

  @required_fields ~w(chat_id user_id message_id)a
  @optional_fields ~w(content_hash)a

  schema "user_message_records" do
    field :chat_id, :integer
    field :user_id, :integer
    field :message_id, :integer
    field :content_hash, :string

    timestamps(updated_at: false)
  end

  def changeset(record, attrs) do
    record
    |> cast(attrs, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
  end
end