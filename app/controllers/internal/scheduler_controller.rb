module Internal
  # Hit on a fixed interval by an external cron (GitHub Actions primary,
  # cron-job.org backup — see .github/workflows/scheduler.yml) since Render's
  # free tier has no built-in scheduler and no always-on process to run one.
  #
  # Runs synchronously inline rather than enqueuing a background job: at this
  # app's scale (a handful of seasons, dozens of players) the full unit of
  # work per tick is trivial, and a queue would need a worker process the
  # free hosting tier can't sustain.
  class SchedulerController < ActionController::Base
    include EmailNotifications

    skip_before_action :verify_authenticity_token

    before_action :authenticate!

    def run
      # A real query on every tick, even when nothing is due, keeps the
      # Supabase free project from pausing after 7 days of no DB traffic.
      ActiveRecord::Base.connection.execute("SELECT 1")

      results = run_due_jobs

      render json: { ok: true, ran_at: Time.current, results: results }
    end

    private

    def authenticate!
      token = request.headers["Authorization"].to_s.delete_prefix("Bearer ").strip
      expected = ENV["SCHEDULER_TOKEN"]

      if expected.blank? || !ActiveSupport::SecurityUtils.secure_compare(token, expected)
        head :unauthorized
      end
    end

    # Scheduled announcements (Phase 9) land here too. Each job is
    # idempotent by construction: it only acts on rows still in the
    # "due" state (a status/deadline query), so an overlapping or
    # double-fired tick just finds nothing left to do.
    def run_due_jobs
      {
        challenges_auto_closed: auto_close_challenges,
        votes_auto_closed: auto_close_votes,
        announcements_sent: send_due_announcements,
        challenge_reminders_sent: send_challenge_reminders,
        vote_reminders_sent: send_vote_reminders,
        message_digests_sent: send_message_digests
      }
    end

    # Only stops new submissions — entering results and revealing tribal
    # council stay explicit host actions (see docs/REQUIREMENTS.md#timing-model),
    # since those are judgment calls / dramatic moments the host should
    # trigger deliberately, not have happen silently in the background.
    def auto_close_challenges
      Round.challenge_past_due.find_each.count do |round|
        round.close_challenge!(auto: true)
        true
      rescue => e
        Rails.logger.error("[scheduler] round #{round.id} challenge auto-close failed: #{e.message}")
        false
      end
    end

    def auto_close_votes
      Round.voting_past_due.find_each.count do |round|
        round.close_voting!(auto: true)
        true
      rescue => e
        Rails.logger.error("[scheduler] round #{round.id} voting auto-close failed: #{e.message}")
        false
      end
    end

    def send_due_announcements
      Announcement.due.find_each.count do |announcement|
        announcement.send_now!
        announcement.season.season_memberships.each do |membership|
          notify_safely { SeasonMailer.announcement_sent(announcement: announcement, membership: membership).deliver_now }
        end
        true
      rescue => e
        Rails.logger.error("[scheduler] announcement #{announcement.id} send failed: #{e.message}")
        false
      end
    end

    def send_challenge_reminders
      Round.challenge_reminder_due.find_each.count do |round|
        round.season.active_players.each do |membership|
          notify_safely { SeasonMailer.deadline_reminder(round: round, kind: :challenge, membership: membership).deliver_now }
        end
        round.update!(challenge_reminder_sent_at: Time.current)
        true
      rescue => e
        Rails.logger.error("[scheduler] round #{round.id} challenge reminder failed: #{e.message}")
        false
      end
    end

    def send_vote_reminders
      Round.vote_reminder_due.find_each.count do |round|
        session = round.current_voting_session
        member_ids = session ? session.eligible_voter_ids : []
        SeasonMembership.where(id: member_ids).each do |membership|
          notify_safely { SeasonMailer.deadline_reminder(round: round, kind: :vote, membership: membership).deliver_now }
        end
        round.update!(vote_reminder_sent_at: Time.current)
        true
      rescue => e
        Rails.logger.error("[scheduler] round #{round.id} vote reminder failed: #{e.message}")
        false
      end
    end

    # At most one digest per recipient per scheduler tick (~20 min), no
    # matter how many messages arrived — the real defense against blowing
    # through Resend's 100/day cap with per-message emails. `since:` is the
    # later of "last read" or "last digested", so a player who never opens
    # the app gets notified about newly-arrived messages each tick, not the
    # same unread backlog resent forever.
    def send_message_digests
      SeasonMembership.where(role: %w[host player]).where(status: "active").find_each.count do |membership|
        threads = (membership.message_threads.to_a + [ membership.season.public_thread ]).uniq

        unread = threads.filter_map do |thread|
          count = thread.unread_count_for(membership, since: membership.last_message_digest_sent_at)
          [ thread, count ] if count.positive?
        end
        next false if unread.empty?

        notify_safely { MessageMailer.unread_digest(membership: membership, unread_threads: unread).deliver_now }
        membership.update!(last_message_digest_sent_at: Time.current)
        true
      rescue => e
        Rails.logger.error("[scheduler] membership #{membership.id} message digest failed: #{e.message}")
        false
      end
    end
  end
end
