# frozen_string_literal: true

Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    # origins 'http://localhost:3000', 'https://api.openai.com'
    #     resource '*',
    #              headers: :any,
    #              methods: %i[get post put patch delete options head],
    #              credentials: true,
    #              expose: %w[access-token uid client expiry]
    #   end

    origins '*'

    resource '*',
             headers: :any,
             methods: %i[get post put patch delete options head]
  end
end
