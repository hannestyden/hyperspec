require 'hyperspec'
require 'minitest/autorun'

require 'json'

# Run specs: `cd examples/readme; bundle exec ruby -rubygems service_spec.rb`.

# `before(:all)`-like behavior can be implemented with conditional assignment.
#
# But ...
# `after(:all)`-like behavior requires knowledge about when the last example has
# been run. This is available in `MiniTest::Unit.after_tests` and needs to be
# made accessible in `MiniTest::Spec`.
class MiniTest::Spec < MiniTest::Unit::TestCase
  def self.after(type = :each, &block)
    case type
    when :each
      add_teardown_hook {|tc| tc.instance_eval(&block) }
    when :all
      MiniTest::Unit.after_tests { |tc| tc.instance_eval(&block) }
    else
      raise "unsupported after type: #{type}"
    end
  end
end

module ServiceRunner
  def self.start
    command = 'bundle exec rackup service.ru -p 4567'
    @service_pid ||=
      begin
        pid = Process.spawn(command, { :err => '/dev/null' })
        # Here be monsters: Only tested on Darwin.
        while (bound = `lsof -i :4567`).empty? do
          sleep 0.1
        end
        pid
      end
  end

  def self.stop
    Process.kill('KILL', @service_pid)
    @service_pid = nil
  end
end

service "http://localhost:4567" do
  before do
    ServiceRunner.start
  end

  after(:all) do
    ServiceRunner.stop
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
