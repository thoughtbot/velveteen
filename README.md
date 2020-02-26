# Velveteen [![Build Status](https://travis-ci.com/thoughtbot/velveteen.svg?branch=master)](https://travis-ci.com/thoughtbot/velveteen)

Transform your background jobs into a real data pipeline with Velveteen.

## About

Background jobs are an inevitable addition for many Rails applications. They
typically start with a need to send email, then quickly grow into a collection
of interdependent data processing jobs that are yearning to be a pipeline.
Velveteen aims to insert itself near the beginning, providing support to build
out the pipeline in a maintainable way.

## 🚧 A work in-progress 🚧

Prior to version 1.0, minor version updates are susceptible to breaking changes.

## Getting started

Velveteen requires Ruby `>= 2.5` and access to [RabbitMQ]. If you're new to
RabbitMQ, check out this [handy tutorial].

[RabbitMQ]: https://www.rabbitmq.com/
[handy tutorial]: https://www.rabbitmq.com/tutorials/amqp-concepts.html

Add the following line to Gemfile:

```ruby
gem "velveteen"
```

Run the bundle command to install it.

Define a worker:

```ruby
# do_something.rb
require "velveteen"

Velveteen::Config.exchange_name = "velveteen_development"

class DoSomething < Velveteen::Worker
  self.routing_key = "something.do"

  def perform
    # do something
  end
end
```

Run it:

```shell
velveteen work do_something.rb DoSomething
```

Within the worker, you have access to the following:

* `message` - A representation of the Rabbit message, which responds to:
  * `body` - the raw message body
  * `data` - the parsed JSON representation of the body
  * `delivery_info` - the delivery info from Rabbit
  * `headers` - the headers from Rabbit, from `properties.headers`
  * `properties` - the properties Rabbit
* `publish(payload, [options])` - Publishes the message to the exchange
  * `payload` - the message body
  * `options` - the message properties and delivery settings

## Pipeline design

In general, try to follow the best practices laid out in thoughtbot's [data
guide].

[data guide]: https://github.com/thoughtbot/guides/tree/master/data

When using Velveteen in particular, try to follow:

* Keep workers focused on a single task and interact with at most one service
  (e.g. S3, Postgres, third-party API).
* Name workers after the actions they perform. E.g. a worker that fetches a
  user's most recent GitHub commits could be called `FetchUserCommits`.
  Velveteen will use the same name for the worker's queue.
* For workers that are the first step in a pipeline (e.g. runs on a schedule),
  or perform a one-off task (e.g. upload to S3), name routing keys in the
  present tense – `user.commits.fetch` or `s3.upload`.
* For workers that process the output of another worker, name routing keys in
  the past tense. For example, `FetchUserCommits` publishes the fetched commits
  with a routing key of `user.commits.fetched`, which is consumed by the
  `RegenerateUserCommitGraph` and `NotifyCollaborators` workers.

## Message validation

Velveteen can validate incoming messages with a JSON Schema.

```ruby
Velveteen::Config.schema_directory = "app/schemas"

class FetchUserCommits < Velveteen::Worker
  ...
  self.message_schema = "fetch_user_commits.json"

  def perform
    # do something with the GitHub API
  end
end
```

_app/schemas/fetch_user_commits.json_
```json
{
  "type": "object",
  "required": ["username"],
  "properties": {
    "username": {"type": "string"}
  }
}
```

When a message is added to this worker's queue and it does not match the schema,
a `Velveteen::InvalidMessage` exception will be raised and handled by the
configured error handler. The worker's `perform` method will not be invoked.

## Rate limiting

Limiting workers to processing a certain number of messages per minute is
supported. This is implemented by periodically publishing tokens to a dedicated
queue (with a max size of 1), where the worker must successfully take a token
before it begins.

To produce tokens, Velveteen needs the name of the queue to publish to and the
number of messages per minute. For example, [GitHub's API limit] is 5000
requests per hour (~83.3 per minute). With Velveteen, that looks like:

[GitHub's API limit]: https://developer.github.com/v3/#rate-limiting

```shell
velveteen rate-limit github_tokens 83
```

Limiting the worker can be enabled by specifying the rate limit queue:

```ruby
class FetchCommits < Velveteen::Worker
  ...
  self.rate_limit_queue = "github_tokens"

  def perform
    # fetch commits
  end
end
```

Multiple workers can share the same token queue, which can be helpful when API
calls to an external service are spread among many workers and are all governed
by the same rate limit.

The provided implementation does not support other techniques, such as bursting,
throttling, or quotas.

## Message headers

When a worker publishes a message, the headers from the message being consumed
will automatically be passed. This can be useful when, e.g., passing a database
id through the pipeline so it can be updated at the end of the line, without
needing to manually propagate it.

## Error handling

### Message rejection

The default error handler with log the error and reject the message without
requeueing it.

### Retry with exponential backoff

An error handler that supports exponential backoff retries is included. It can
be enabled with:

```ruby
Velveteen::Config.error_handler = Velveteen::ErrorHandlers::ExponentialBackoff
```

## Process model

In short, there isn't one. Velveteen supports running a single worker that
consumes messages from a single queue. Process management is an external
concern left to the application developers.

The approach in mind while developing/extracting Velveteen was to have a single
Procfile entry for each worker, hosted on Heroku, using hobby tier dynos.
Third-party API rate limits were the primary bottleneck and a single worker for
each queue was sufficient to keep up.

## Contributing

Please see [CONTRIBUTING.md](CONTRIBUTING.md).

## License

Velveteen is Copyright © 2020 thoughtbot. It is free software, and may be
redistributed under the terms specified in the [LICENSE] file.

[LICENSE]: LICENSE

About thoughtbot
----------------

![thoughtbot](https://thoughtbot.com/brand_assets/93:44.svg)

Velveteen is maintained and funded by thoughtbot, inc.
The names and logos for thoughtbot are trademarks of thoughtbot, inc.

We love open source software!
See [our other projects][community] or
[hire us][hire] to design, develop, and grow your product.

[community]: https://thoughtbot.com/community?utm_source=github
[hire]: https://thoughtbot.com/hire-us?utm_source=github
