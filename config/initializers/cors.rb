# config/initializers/cors.rb

# Be sure to restart your server when you modify this file.

Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins "http://localhost:5174" # フロントエンドのURL

    resource "/graphql",
      headers: :any,
      methods: [ :get, :post, :put, :patch, :delete, :options, :head ],
      credentials: true # Cookie送信を許可
  end
end
