class MessageMailer < ApplicationMailer
  # unread_threads: [[thread, unread_count], ...] — batched so a chatty
  # thread never generates more than one email per digest window (see
  # docs plan's Resend 100/day cap note).
  def unread_digest(membership:, unread_threads:)
    @season = membership.season
    @membership = membership
    @unread_threads = unread_threads

    mail to: membership.user.email, subject: "#{@season.name}: you have new messages"
  end
end
