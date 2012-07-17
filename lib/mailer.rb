require 'mail'
class Mailer < Rsync
    def send_email(subject,email,body)
      Mail.defaults do
        delivery_method :smtp,
        :address  => "mailer.mailgrid.com",
        :port  => 25,
        :domain  => "mailer.mailgrid.com",
        :user_name  => "username",
        :password  => "password",
        :authentication  => :login
      end

      mail = Mail.new do
       from "BACKUPADMIN@xyz.net"
       to email
       subject "#{subject}"
       body " \n #{body}"
      end
     mail.cc ["admin@xyz.net","hash#45@mgmail.com"]
     mail.deliver
    end
end
