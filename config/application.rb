require_relative 'boot'

require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

require 'carrierwave/orm/activerecord'

module Conversations
  class Application < Rails::Application
    config.generators do |g|
      g.assets            false
      g.helper            false
      g.jbuilder          false
    end
  end
end
