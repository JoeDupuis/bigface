module ApplicationHelper
  def form_errors(instance, **locals)
    locals[:instance] = instance
    render partial: "application/form_errors", locals: locals
  end

  def flash_message(type, message)
    message_type = type == "notice" ? "success" : "danger"

    tag.div(
      message,
      class: "flash-alert -#{message_type}",
      role: "alert",
      data: {
        controller: "alert",
        close_btn_class: "close"
      }
    )
  end

  def current_git_branch
    return nil unless Rails.env.development?

    begin
      `git rev-parse --abbrev-ref HEAD`.strip
    rescue
      nil
    end
  end

  AVATAR_COLORS = %w[violet blue emerald orange pink].freeze

  def avatar_color(name)
    AVATAR_COLORS[name.to_s.bytes.sum % AVATAR_COLORS.size]
  end

  def avatar_initials(name)
    name.to_s.split.map { |n| n[0] }.join.upcase.slice(0, 2)
  end
end
