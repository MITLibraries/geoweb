class User < ApplicationRecord

  if Blacklight::Utils.needs_attr_accessible?
    attr_accessible :email, :password, :password_confirmation
  end
  # Connects this user object to Blacklights Bookmarks.
  include Blacklight::User
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable

  auth_types = []
  auth_types.push(:developer) if ENV['AUTH_TYPE'].include?('developer')
  auth_types.push(:saml) if ENV['AUTH_TYPE'].include?('saml')
  auth_types.push(:shibboleth) if ENV['AUTH_TYPE'].include?('shibboleth')

  devise :omniauthable, :omniauth_providers => auth_types


  def self.from_omniauth(auth)
    where(uid: auth.info.email).first_or_create do |user|
      user.email = auth.info.email
      user.name = auth.info.name
    end
  end
  # Method added by Blacklight; Blacklight uses #to_s on your
  # user class to get a user-displayable login/identifier for
  # the account.
  def to_s
    email
  end
end
