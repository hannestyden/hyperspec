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

## Example

```ruby
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
```

## Concepts

### `service`

Sets the `BASE_URI` of the API.

### `resource`

Sets the `URI` under test. Absolute or relative to the current scope.

### `get`, `head`, `post`, `put` and `delete`

Selects the HTTP method for the request.

### `with_query_string`

Sets the query parameters used for a request. Merges with previously set parameters.

### `with_headers`

Sets the headers used for a request. Merges with previously set headers.

### `with_body`

Sets the body used for a request. Overrides previously set parameters.

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

## History

### 0.0.2

#### 2012 03 30

- Correcting environment dependencies.
- Adding support for HTTP Basic Auth.

### 0.0.1

#### 2012 02 07

- Initial release
