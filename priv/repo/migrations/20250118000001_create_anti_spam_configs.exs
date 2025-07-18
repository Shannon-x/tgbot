defmodule PolicrMini.Repo.Migrations.CreateAntiSpamConfigs do
  use Ecto.Migration

  def change do
    create table(:anti_spam_configs) do
      add :chat_id, :bigint, null: false
      # 是否启用反垃圾功能
      add :enabled, :boolean, default: false
      # 检测时间窗口（秒）
      add :time_window, :integer, default: 60
      # 最大消息数量
      add :max_messages, :integer, default: 10
      # 最大重复消息数量
      add :max_duplicate_messages, :integer, default: 3
      # 处理方式: :mute, :kick, :ban
      add :action, :string, default: "mute"
      # 禁言时长（秒），仅当 action 为 :mute 时生效
      add :mute_duration, :integer, default: 300
      
      timestamps()
    end

    create unique_index(:anti_spam_configs, [:chat_id])
  end
end