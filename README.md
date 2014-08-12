# rails

Highly configurable Rails deploys with common gem dependency management, capistrano and web server setup.

## Overview

The goal of this module is to provide a comprehensive Rails deployment recipe that can cover a wide array of use-cases using high-level options instead of simply exposing all possible configuration details to the caller.


## Optional Dependencies

- Elasticsearch support requires `elasticsearch-elasticsearch (>= 0.3.1)` .

## Usage

Each separate Rails application is encapsulated by `rails::app`.

### Example

```puppet
rails::app {'myapp':
    ruby_version => 'ruby-2.0.0-p0',
    db => 'mysql',
    server_name => [
        "myapp.com",
        "www.myapp.com",
        "${environment}.myapp.com",
    ],
    uses => {
        rmagick => true,
        sidekiq => true,
    },
    shared_dirs => [
        'log',
        'pids',
        'assets',
        'uploads',
        'custom_data'
    ],
}
```

This would set up a deploy directory for capistrano (using [`deversus-capistrano`](https://forge.puppetlabs.com/deversus/capistrano)), a puma web service named "myapp" (using [`deversus-puma`](https://forge.puppetlabs.com/deversus/puma)) and an nginx proxy for the puma service (using [`jfryman-nginx`](https://forge.puppetlabs.com/jfryman/nginx)) with the provided `$server_name` hostnames. Additionally, RVM would be installed (using [`maestrodev-rvm`](https://forge.puppetlabs.com/maestrodev/rvm)) and the `ruby-2.0.0-p0` environment added to it. The binary dependency packages would be installed for rmagick and mysql (e.g. `libmagickwand-dev`, `libmysqlclient-dev` ...), as well as a local redis service for sidekiq . Node.js will also be installed for the default Rails asset compilation. 

### Parameter Reference

#### `app_name` (namevar)

Used for default folder, directory, config file (etc) names throughout.

#### `db`

Name of the database being used - will install any binary dependencies for the client (no servers are installed).

Supported values:

- `mysql` (default)
- `postgresql`

Patches welcome for additional database types.

#### `deploy_using`

Which deployment strategy will be used. Currently, only `capistrano` is supported.


#### `ruby_version`

The ruby binary for RVM. Your system ruby will be used if this is not provided (this is the default).

#### `server_name`

The server names to pass to your server's vhosts. Must be an array of strings.

#### `serve_using`

A server or combination of servers to use to actually serve the app. These will always be automatically configured to work together.

Supported values:

- `nginx/puma` (default)
- `worker-only` for worker queue nodes that don't need to run a web server

Patches welcome for additional server types (`nginx/unicorn`? `apache/passenger`?).

#### `shared_dirs`

A custom set of shared directories of capistrano. See [`deversus-capistrano`](https://forge.puppetlabs.com/deversus/capistrano) for details.

#### `uses`

A hash specifying additional dependencies and common ancillary rails services. Each key should be one of the names documented below, and its value should either be `true` or some additional configuration option required for that name (also documented below).

##### `rmagick => true`

Installs the ImageMagick development packages required to compile the gem.

##### `sidekiq => true`

Installs and launches a local `redis` service.

##### `nokogiri => true`

Installs the XML/XSLT development packages required to compile the gem.

##### `elasticsearch => "$version"`

Installs a local `elasticsearch` service (to use with `tire` et al).

##### `yui => true`

Installs the YUI compressor and its java dependencies.

###### Configuration Options

You must specify which version of `elasticsearch` to install as a string value.
