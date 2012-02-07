require 'hyperspec'
require 'minitest/autorun'

require 'json'

# Run `shotgun -p 4567 example.ru` from `examples/service/`.

service "http://localhost:4567" do
  def response_json
    JSON.parse(response.body)
  end

  resource "/lolz" do
    get do
      it { responds_with.status :ok }
      it { response_json['lolz'].must_be_instance_of Array }

      with_query("q=monorail") do
        it "only lists lolz that match the query" do
          response_json['lolz'].wont_be_empty
          response_json['lolz'].each do |lol|
            lol['title'].must_match /monorail/
          end
        end
      end

      with_query("q=looong") do
        it "only lists lolz that match the query" do
          response_json['lolz'].wont_be_empty
          response_json['lolz'].each do |lol|
            lol['title'].must_match /looong/
          end
        end
      end
    end

    post do
      describe "without request body" do
        it { responds_with.status :unprocessable_entity }
      end

      describe "with request body" do
        with_headers({ 'Content-Type' => 'application/json' }) do
          with_request_body({ "title" => "Roflcopter!" }.to_json) do
            it { responds_with.status :created }
            it { response_json['lol']['title'].must_equal 'Roflcopter!' }
          end
        end
      end
    end
  end
end
