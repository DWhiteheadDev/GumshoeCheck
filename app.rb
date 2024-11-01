# create basic sinatra app
require 'sinatra'
require 'json'
require 'net/http'
require 'openssl'
require 'jwt'
require_relative 'helpers'

set :port, 3000

# Auth callback
get '/auth/github/callback' do
    code = params[:code}
    
    # Exchange the auth code for an access token
    uri = URI("https://github.com/login/oauth/access_token")
    res = Net::HTTP.post_form(uri, {
        'client_id' => ENV['GITHUB_CLIENT_ID'],
        'client_secret' => ENV['GITHUB_CLIENT_SECRET'],
        'code' => code
    })

    # Parse the response to get the access token
    access_token = URI.decode_www_form(res.body).to_h['access_token']

    # Store or use the access token as needed
    puts "Access Token: #{access_token}"

    # Redirect the user to the main app or another page
    redirect '/'
end

# Webhook endpoint
post '/webhook' do
    # get the payload
    request_body = request.body.read
    payload = JSON.parse(request_body)
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
    # get the issue number
    issue_number = payload['issue']['number']
    # get the repository name
    repo = payload['repository']['name']
    comment_message = "Gumshoe thanks you for opening a new issue. The team will review it shortly!"

    jwt_token = generate_jwt
    installation_token = get_installation_token(installation_id, jwt_token)

    post_comment_on_issue(repo, issue_number, comment_message, installation_token)
end

get '/auth/github' do
    redirect "https://github.com/login/oauth/authorize?client_id=#{ENV['GITHUB_CLIENT_ID']}&scope=repo"
end

# Generate a JWT for authenticating as the GitHub App
def generate_jwt
    private_key = OpenSSL::PKey::RSA.new(ENV['GITHUB_APP_PRIVATE_KEY'])
    payload = {
        # issued at time
        iat: Time.now.to_i,
        # JWT expiration time (10 minute maximum)
        exp: 10.minutes.from_now.to_i,
        # GitHub App's identifier
        iss: ENV['GITHUB_APP_ID']
    }

    # generate the JWT token
    JWT.encode(payload, private_key, "RS256")
end

# Generate an installation access token
def get_installation_token(installation_id, jwt_token)
    uri = URI("https://api.github.com/app/installations/#{installation_id}/access_tokens")

    request = Net::HTTP::Post.new(uri)
    request['Authorization'] = "Bearer #{jwt_token}"
    request['Accept'] = "application/vnd.github.v3+json"

    response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
        http.request(request)
    end

    # Parse and return the installation token
    data = JSON.parse(response.body)
    token = data['token']
    return token
end

