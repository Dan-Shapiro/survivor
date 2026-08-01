require "test_helper"

class MessageMailerTest < ActionMailer::TestCase
  test "unread_digest" do
    mail = MessageMailer.unread_digest
    assert_equal "Unread digest", mail.subject
    assert_equal [ "to@example.org" ], mail.to
    assert_equal [ "from@example.com" ], mail.from
    assert_match "Hi", mail.body.encoded
  end
end
