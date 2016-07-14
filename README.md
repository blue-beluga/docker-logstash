# [<img src=".bluebeluga.png" height="100" width="200" style="border-radius: 50%;"/>](https://github.com/blue-beluga/docker-logstash) bluebeluga/logstash

Alpine Linux image with Logstash HTTP listener.

### Plugins

By default, this image includes a selection of common Logstash codec, filter,
and output plugins.  If you need additional plugins, edit `./Gemfile`.


## Available Tags

* `latest`: Currently Logstash 2.3.2


## Tests

Tests are run as part of the `Makefile` build process. To execute them run the following command:

    make test

## Deployment

To push the Docker image to Quay, run the following command:

    make release
