class User < ApplicationRecord

  if Blacklight::Utils.needs_attr_accessible?
    attr_accessible :email, :password, :password_confirmation
  end
  # Connects this user object to Blacklights Bookmarks.
  include Blacklight::User
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  if ENV['AUTH_TYPE'] == 'developer'
    devise :omniauthable, omniauth_providers: [:developer]
  elsif ENV['AUTH_TYPE'] == 'saml'
    devise :omniauthable, :omniauth_providers => [:saml]
  else
    devise :omniauthable, :omniauth_providers => [:shibboleth]
  end

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
