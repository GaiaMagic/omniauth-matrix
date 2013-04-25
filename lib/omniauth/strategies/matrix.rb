require 'omniauth-oauth2'

module OmniAuth
  module Strategies
    class Matrix < OmniAuth::Strategies::OAuth2

      option :name, "matrix"

      option :client_options, {
        :authorize_url => "/auth/matrix/authorize",
        :access_token_url => "/auth/matrix/access_token"
      }

      uid { raw_info['id'] }

      info do
        {
          :email => raw_info['email']
        }
      end

      #extra do
        #{
          #:first_name => raw_info['extra']['first_name'],
          #:last_name  => raw_info['extra']['last_name']
        #}
      #end

      def raw_info
        @raw_info ||= access_token.get("/auth/matrix/user.json?oauth_token=#{access_token.token}").parsed
      end
    end
  end
end
