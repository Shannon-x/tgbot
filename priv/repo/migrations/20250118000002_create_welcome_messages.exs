defmodule PolicrMini.Repo.Migrations.CreateWelcomeMessages do
  use Ecto.Migration

  def change do
    create table(:welcome_messages) do
      add :chat_id, :bigint, null: false
      # 是否启用欢迎消息
      add :enabled, :boolean, default: false
      # 欢迎消息文本（支持 HTML 或 Markdown）
      add :text, :text
      # 解析模式: "HTML", "Markdown", "MarkdownV2"
      add :parse_mode, :string, default: "HTML"
      # 图片文件ID（可选）
      add :photo_file_id, :string
      # 按钮配置（JSON 格式）
      add :buttons, :text
      # 删除延迟（秒），0 表示不删除
      add :delete_delay, :integer, default: 0
      
      timestamps()
    end

    create unique_index(:welcome_messages, [:chat_id])
  end
end