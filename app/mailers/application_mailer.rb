class ApplicationMailer < ActionMailer::Base
  default from: ENV.fetch("MAILER_FROM", "Survivor <notifications@example.com>")
  layout "mailer"
end
