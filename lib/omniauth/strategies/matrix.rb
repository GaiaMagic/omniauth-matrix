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
          :email    => raw_info['info']['email'],
        }
      end

      extra do
        {
          :storm_id => raw_info['extra']['storm_id']
        }
      end

      def raw_info
        @raw_info ||= access_token.get("/auth/matrix/user.json?access_token=#{access_token.token}").parsed || {}
      end

      def authorize_params
        super.tap do |params|
          if request.params["state"]
            params[:state] = request.params["state"]

            # to support omniauth-oauth2's auto csrf protection
            session['omniauth.state'] = params[:state]
          end
        end
      end
    end
  end
end

OmniAuth.config.add_camelization "matrix", "Matrix"
