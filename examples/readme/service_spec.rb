require 'hyperspec'
require 'minitest/autorun'

require 'json'

# Run specs: `cd examples/readme; bundle exec ruby -rubygems service_spec.rb`.

service "http://localhost:4567" do
  # TODO
  #   It should be possible to set this up **once** per test suite.
  #   MiniTest::Spec seems to lack support for this though.
  before do
    @service_pid =
      Process.spawn('bundle exec rackup -p 4567 service.ru', {
        :err => '/dev/null'
      })
    sleep 3
  end

  after do
    Process.kill('KILL', @service_pid)
  end

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
