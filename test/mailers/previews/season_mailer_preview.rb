# Preview all emails at http://localhost:3000/rails/mailers/season_mailer
class SeasonMailerPreview < ActionMailer::Preview
  # Preview this email at http://localhost:3000/rails/mailers/season_mailer/challenge_opened
  def challenge_opened
    SeasonMailer.challenge_opened
  end

  # Preview this email at http://localhost:3000/rails/mailers/season_mailer/tribal_council_revealed
  def tribal_council_revealed
    SeasonMailer.tribal_council_revealed
  end

  # Preview this email at http://localhost:3000/rails/mailers/season_mailer/idol_granted
  def idol_granted
    SeasonMailer.idol_granted
  end

  # Preview this email at http://localhost:3000/rails/mailers/season_mailer/announcement_sent
  def announcement_sent
    SeasonMailer.announcement_sent
  end

  # Preview this email at http://localhost:3000/rails/mailers/season_mailer/deadline_reminder
  def deadline_reminder
    SeasonMailer.deadline_reminder
  end
end
