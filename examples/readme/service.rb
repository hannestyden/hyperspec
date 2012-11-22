require 'sinatra'
require 'json'

get "/lolz" do
  title = params[:q]
  %^{"lolz": [ { "title": "#{title}" } ]}^
end

post "/lolz" do
  request_body = request.env['rack.input'].read

  if request_body == ''
    status 422
  else
    if request.env['CONTENT_TYPE'] == "application/json"
      params = JSON.parse(request_body)

      if params.nil? || params.empty?
        status 422
        %^{"error": "An error occurred!"}^
      else
        status 201
        %^{"lol": {"title": "Roflcopter!"}}^
      end
    else
      status 415
    end
  end
end
