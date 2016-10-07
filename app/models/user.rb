class User < ApplicationRecord
  after_initialize :set_instance_variables

  def info(key = nil)
    key.nil? ? @user : @user[key.to_s]
  end

  private

  def set_instance_variables
    @user ||= auth0_api.user auth0_id
  end

  def auth0_api
    Auth0Client.new(
      client_id: Rails.application.secrets.auth0_client_id,
      token: Rails.application.secrets.auth0_management_jwt,
      domain: Rails.application.secrets.auth0_domain,
      api_version: 2
    )
  end
end
