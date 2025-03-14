class Facebook::DeleteController < ApplicationController
  include FacebookConcern

  def create
    signed_request = params['signed_request']
    payload = parse_fb_signed_request(signed_request)
    id_to_process = payload['user_id']

    delete_request = DeleteRequest.create(fb_id: id_to_process)
    status_url = "#{app_url_base}/facebook/confirm/#{delete_request.confirmation_code}"

    # IMPORTANT: Do not change the response format below.
    # Facebook's Data Deletion Request system specifically expects responses in this format
    # with a 'url' for status confirmation and a 'confirmation_code' field.
    # See: https://developers.facebook.com/docs/development/create-an-app/app-dashboard/data-deletion-callback/#implementing
    render json: { url: status_url, confirmation_code: delete_request.confirmation_code }, status: :ok
  rescue InvalidDigestError
    render json: { error: 'Invalid signature' }, status: :unprocessable_entity
  rescue StandardError => e
    ChatwootExceptionTracker.new(e).capture_exception
    render json: { error: e.message }, status: :malformed_request
  end
end
