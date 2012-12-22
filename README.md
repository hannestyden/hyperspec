             __  __                     ______
            / / / /_  _________________/ ____/________________
           / /_/ / / / / __ \  _ \_ __/____ \/ __ \  _ \  ___/
          / __  / /_/ / /_/ /  __/ /  ____/ / /_/ /  __/ /__
         /_/ /_/\__, / ____/\___/_/  /_____/ ____/\___/\___/
               /____/_/                   /_/

A full stack testing framework for HTTP APIs.

By extending `minitest/spec` HyperSpec provides a Ruby DSL for testing
HTTP APIs from the outside.

[![Build Status](https://secure.travis-ci.org/hannestyden/hyperspec.png)](http://travis-ci.org/hannestyden/hyperspec)
[![Code Climate](https://codeclimate.com/badge.png)](https://codeclimate.com/github/hannestyden/hyperspec)

## Example

```ruby
#source: examples/readme/service_spec.rb

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
```

## Concepts

### `service`

Sets the `BASE_URI` of the API.

### `resource`

Sets the `URI` under test. Absolute or relative to the current scope.

### `get`, `head`, `post`, `put` and `delete`

Selects the HTTP method for the request.

### `with_query`

Sets the query component of a request. Overrides previously set parameters.

### `with_headers`

Sets the headers of a request. Merges with previously set headers.

### `with_body`

Sets the body of a request. Overrides previously set parameters.

### `response`

An object for accessing properties of the "raw" response.

### `responds_with`

Issues the request and returns an object that has the following convenience matchers:

#### `status`

Allows for comparing against named status code symbols.

#### `content_type`

#### `content_charset`

## Upcoming features

### Representations

- DSL for matching representations.

### Documentation

- Adding an output format for docs.

## Concerns

- Efficient ways of building up and verifying precondition state.
- Verify an eventual consistent state.
- Allowing whitebox testing by "wormholing" into the application(s).

## Acknowledgments

Thanks to:

- [Daniel Bornkessel](https://github.com/kesselborn) for inspiring me to do `README` driven development.
- [Matthias Georgi](https://github.com/georgi) for suggestions for code improvements.
- [Lars Gierth](https://github.com/lgierth) for updating the example server to respond with 415 Unsupported Media Type in the appropriate case.
- [Anton Lindqvist](https://github.com/mptre) for adding HTTP Basic Auth
- [Josh Devins](https://github.com/joshdevins) for noticing missing HTTP status codes and `with_query` documentation inconsistency.

## History

### 0.0.5 - 2012-12-04

- Change dependency declaration.

### 0.0.4 - 2012-11-22

- Change behavior of `with_query` to override instead of append.

### 0.0.3 - 2012-08-10

- Add complete list of HTTP response codes.

### 0.0.2 - 2012-03-30

- Correcting environment dependencies.
- Adding support for HTTP Basic Auth.

### 0.0.1 - 2012-02-07

- Initial release
