defmodule PolicrMini.Repo.Migrations.CreateUserMessageRecords do
  use Ecto.Migration

  def change do
    create table(:user_message_records) do
      add :chat_id, :bigint, null: false
      add :user_id, :bigint, null: false
      add :message_id, :bigint, null: false
      # 消息内容的 MD5 哈希，用于检测重复消息
      add :content_hash, :string
      
      timestamps(updated_at: false)
    end

    # 为查询优化创建索引
    create index(:user_message_records, [:chat_id, :user_id])
    create index(:user_message_records, [:chat_id, :user_id, :inserted_at])
    create index(:user_message_records, [:chat_id, :user_id, :content_hash])
  end
end