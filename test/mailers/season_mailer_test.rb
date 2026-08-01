require "test_helper"

class SeasonMailerTest < ActionMailer::TestCase
  test "challenge_opened" do
    mail = SeasonMailer.challenge_opened
    assert_equal "Challenge opened", mail.subject
    assert_equal [ "to@example.org" ], mail.to
    assert_equal [ "from@example.com" ], mail.from
    assert_match "Hi", mail.body.encoded
  end

  test "tribal_council_revealed" do
    mail = SeasonMailer.tribal_council_revealed
    assert_equal "Tribal council revealed", mail.subject
    assert_equal [ "to@example.org" ], mail.to
    assert_equal [ "from@example.com" ], mail.from
    assert_match "Hi", mail.body.encoded
  end

  test "idol_granted" do
    mail = SeasonMailer.idol_granted
    assert_equal "Idol granted", mail.subject
    assert_equal [ "to@example.org" ], mail.to
    assert_equal [ "from@example.com" ], mail.from
    assert_match "Hi", mail.body.encoded
  end

  test "announcement_sent" do
    mail = SeasonMailer.announcement_sent
    assert_equal "Announcement sent", mail.subject
    assert_equal [ "to@example.org" ], mail.to
    assert_equal [ "from@example.com" ], mail.from
    assert_match "Hi", mail.body.encoded
  end

  test "deadline_reminder" do
    mail = SeasonMailer.deadline_reminder
    assert_equal "Deadline reminder", mail.subject
    assert_equal [ "to@example.org" ], mail.to
    assert_equal [ "from@example.com" ], mail.from
    assert_match "Hi", mail.body.encoded
  end
end
