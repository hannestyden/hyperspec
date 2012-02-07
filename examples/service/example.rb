require 'sinatra'
require 'json'

get "/lolz" do
  title = params[:q]
  %^{"lolz": [ { "title": "#{title}" } ]}^
end

post "/lolz" do
  if request.env['CONTENT_TYPE'] == "application/json"
    params = JSON.parse(request.env['rack.input'].read)

    if params.nil? || params.empty?
      status 422
      %^{"error": "An error occurred!"}^
    else
      status 201
      %^{"lol": {"title": "Roflcopter!"}}^
    end
  else
    status 422
  end
end
