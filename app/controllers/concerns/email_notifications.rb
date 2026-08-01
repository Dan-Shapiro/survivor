module EmailNotifications
  extend ActiveSupport::Concern

  private

  # A mail server hiccup must not undo (or appear to undo) game actions
  # that already succeeded — the DB change is the source of truth, not the
  # notification, so a delivery failure is logged and swallowed rather than
  # raised back into the controller action.
  def notify_safely
    yield
  rescue StandardError => e
    Rails.logger.error("[mailer] delivery failed: #{e.message}")
  end
end
