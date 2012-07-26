require 'mail'
class Mailer < Rsync
    def send_email(subject,email,body)
      Mail.defaults do
        delivery_method :smtp,
        :address  => "mailer.emailifiedhq.com",
        :port  => 6610,
        :domain  => "mailer.emailifiedhq.com",
        :user_name  => "capture",
        :password  => "betaca2011zakas",
        :authentication  => :login
      end

      mail = Mail.new do
       from "BACKUPADMIN@betterlabs.net"
       to email
       subject "#{subject}"
       body " \n #{body}"
      end
     mail.cc ["chetan.muneshwar@betterlabs.net","chetan.muneshwar@gmail.com"]
     mail.deliver
    end
end
