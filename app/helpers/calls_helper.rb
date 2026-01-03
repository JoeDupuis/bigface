module CallsHelper
  def format_duration(seconds)
    seconds = seconds.to_i
    minutes = seconds / 60
    remaining_seconds = seconds % 60
    format("%d:%02d", minutes, remaining_seconds)
  end
end
