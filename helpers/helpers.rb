def post_comment_on_issue(repo, issue_number, comment, installation_token)
    uri = URI("https://api.github.com/repos/#{repo}/issues/#{issue_number}/comments")
    http = Net::HTTP.new(uri.host, uri.port)

    http.use_ssl = true
    request = Net::HTTP::Post.new(uri)
    request["Authorization"] = "Bearer #{installation_token}"
    request["Accept"] = "application/vnd.github.v3+json"
    request["Content-Type"] = "application/json"
    
    request.body = {
        body: comment
    }.to_json
    
    response = http.request(request)
    
    puts response.read_body
end