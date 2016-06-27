class FrdaMailer < ActionMailer::Base
  default from: "no-reply@frda.stanford.edu"

  def contact_message(opts={})
    params=opts[:params]
    @request=opts[:request]
    @message=params[:message]
    @email=params[:email]
    @name=params[:name]
    @subject=params[:subject]
    @from=params[:from]
    to=Frda::Application.config.contact_us_recipients[@subject]
    cc=Frda::Application.config.contact_us_cc_recipients[@subject]
    mail(:to=>to,:cc=>cc, :subject=>"Contact Message from the French Revolution Digital Archive - #{@subject}")
  end

end
