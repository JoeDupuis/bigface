class TurnCredentialsController < ApplicationController
  def show
    credentials = TurnCredentials.fetch
    render json: credentials
  rescue TurnCredentials::ApiError => e
    render json: { error: e.message }, status: :service_unavailable
  end

  private

  def request_authentication
    head :unauthorized
  end
end
