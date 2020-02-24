TODO:

* move this todo list into proper place - trello, gh issues/projects, etc
* differentiate rate limit queues (e.g. add `_tokens` or something to the name)
* don't introduce metadata as a term? stick with rabbit's term of headers?
* use logger for all output
* environments - e.g. debugging tools, dev console output/logging, test helpers
* integration tests that actually hit Rabbit
* set up Travis
* improve config architecture
  * avoid all memoization by creating a config instance and storing it
    somewhere?
* validate metadata with its own schema?
  * could maybe see this as the application developer tests that a worker
    produces messages with expected metadata, then can assume velveteen will
    pass those on, and not worry about a schema
  * use private method(s) on the worker to define the message schema, instead of
    json file(s)?
* workers specify which error handler to use
* exponential backoff
  * worker can customize delay
  * do we need to include the `count` field in the x-death entries when
    determining retry count?
  * configuring the dlx queue in the handler means it's not created until the
    first error. is that okay?
  * find a better solution for working around the Bunny cache holding onto
    expired queues
* better interrupt handling?
  * sometimes ctr+c (sending SIGINT) causes Bunny to dump a backtrace. is there
    something we should be doing to gracefully halt Bunny?
* support for tracing tools? (do those exist?)
* research options to Bunny classes/methods
* connection failures
* what Ruby versions to support?
* parse date/time into instances of those objects?
* print warning when worker has no schema
* error messages that are helpful
  * e.g. missing exchange/queue/etc name
* put rate limit config into a single file, so worker and producer can share it
* consider documenting the example files
* raise exception in development when publishing an invalid message for a worker
  that velveteen knows about?
* validate the message before instantiating the worker? benefit could be that
  it's an explicit step than can be more easily moved around, and it could
  happen at the class level, without needing to hold onto an instance(?)
* don't symbolize keys when parsing JSON? the bunny `headers` are strings and
  it's probably a good idea to be consistent with that
* support timeouts?

Concerns:

* procfile entry per worker might encourage doing too much in the workers
  * include ideas in the readme for how to Do More
