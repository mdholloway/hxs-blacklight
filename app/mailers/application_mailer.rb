# Application base mailer
class ApplicationMailer < ActionMailer::Base
  default from: "from@example.com"
  layout "mailer"
end
