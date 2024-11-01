# create basic sinatra app
require 'sinatra'
require 'json'
require 'net/http'

set :port, 3000

post '/webhook' do
    # get the payload
    request.body = request.body.read
    payload = JSON.parse(request.body)
    # get event type
    event_type = request.env['HTTP_X_GITHUB_EVENT']

    # depending on the event type, do something
    case event_type
    when 'pull_request'
        handle_pull_request(payload)
    when 'issues'
        handle_issue(payload)
    else 
        status 400
        return "Event type not supported: #{event_type}"
    end

    status 200
end

def handle_pull_request(payload)
    logger.info "Pull request event received"
end

def handle_issue(payload)
    logger.info "Issue event received"
end