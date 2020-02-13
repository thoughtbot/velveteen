TODO:

* forward rabbit metadata to produced messages
* rate limiting
* error handling, exponential backoff
* set up Travis
* environments - e.g. debugging tools, dev console output/logging, test helpers
* support for tracing tools? (do those exist?)
* research options to Bunny classes/methods
* connection failures
* what Ruby versions to support?
* parse date/time into instances of those objects?
* higher level config?
  * message schema directory
  * exchange name
* print warning when worker has no schema
* error messages that are helpful
  * e.g. missing exchange/queue/etc name

Concerns:

* procfile entry per worker might encourage doing too much in the workers
  * include ideas in the readme for how to Do More
