TODO:

* set up Standard
* rate limiting
* error handling, exponential backoff
* message structure validation
* connection failures
* forward rabbit metadata to produced messages
* environments - e.g. debugging tools, dev console output/logging, test helpers
* support for tracing tools? (do those exist?)
* research options to Bunny classes/methods
* what Ruby versions to support?
* set up Travis

Concerns:

* procfile entry per worker might encourage doing too much in the workers
  * include ideas in the readme for how to Do More
