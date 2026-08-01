class SeasonMailer < ApplicationMailer
  def challenge_opened(round:, membership:)
    @round = round
    @season = round.season
    @membership = membership

    mail to: membership.user.email, subject: "#{@season.name}: Round #{round.number} challenge is open"
  end

  def tribal_council_revealed(result:, membership:)
    @result = result
    @round = result.voting_session.round
    @season = @round.season
    @membership = membership

    mail to: membership.user.email, subject: "#{@season.name}: tribal council results"
  end

  def idol_granted(idol:)
    @idol = idol
    @season = idol.season

    mail to: idol.holder_membership.user.email, subject: "#{@season.name}: you found a hidden immunity idol"
  end

  def announcement_sent(announcement:, membership:)
    @announcement = announcement
    @season = announcement.season
    @membership = membership

    mail to: membership.user.email, subject: "#{@season.name}: #{@announcement.announcement_type.humanize}"
  end

  def deadline_reminder(round:, kind:, membership:)
    @round = round
    @season = round.season
    @kind = kind
    @deadline = kind == :challenge ? round.challenge_deadline_at : round.vote_deadline_at

    mail to: membership.user.email, subject: "#{@season.name}: Round #{round.number} deadline approaching"
  end
end
