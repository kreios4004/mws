require_relative '../../helpers/json_api'
require_relative '../../helpers/auth_filters'
require_relative '../../mutations/websocket_uris/create'

module V1
  class WebsocketUriApi < ::Cuba
    include JsonApi
    include AuthFilters
  end
end

##
# =/v1/websocket_uri
#
V1::WebsocketUriApi.define do

  res.headers['Content-Type'] = 'application/json; charset=utf-8'

  require_valid_token! if restricted_access?

  on get do
    on root do

      ttl = 5.minutes
      outcome = WebsocketUris::Create.run(
          user: nil,
          tags: nil,
          ttl: ttl
      )
      if outcome.success?
        websocket_uri = outcome.result
        json = {
            expires_at: ttl.from_now.utc,
            uri: "wss://#{ENV['APP_DOMAIN']}/?token=#{websocket_uri.socket_id}",
            tags: websocket_uri.tags,
            socket_id: websocket_uri.socket_id
        }
        res.status = 200
        res.write JSON.dump(json)
      else
        res.status = 503
        res.write JSON.dump(outcome.errors.message)
      end
    end
  end
end