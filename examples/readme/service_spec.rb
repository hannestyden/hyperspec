require 'hyperspec'
require 'minitest/autorun'

require 'json'

# Shell 1:
# `cd examples/readme`
# Start service: `rackup -p 4567 example.ru`.
#
# Shell 2:
# Run specs: `be ruby -rubygems examples/readme/service_spec.rb`.

service "http://localhost:4567" do
  def responds_with_json_where
    JSON.parse(response.body)
  end

  resource "/lolz" do
    get do

      it { responds_with.status :ok }

      it { responds_with_json_where['lolz'].must_be_instance_of Array }

      with_query("q=monorail") do

        it "only lists lolz that match the query" do
          responds_with_json_where['lolz'].wont_be_empty
          responds_with_json_where['lolz'].each do |lol|
            lol['title'].must_match /monorail/
          end
        end

      end

      with_query("q=looong") do

        it "only lists lolz that match the query" do
          responds_with_json_where['lolz'].wont_be_empty
          responds_with_json_where['lolz'].each do |lol|
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

            it do
              responds_with_json_where['lol']['title'].
                must_equal 'Roflcopter!'
            end

          end
        end
      end
    end
  end
end
