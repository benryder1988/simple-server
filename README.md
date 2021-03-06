# Simple Server

[![Build Status](https://resolvetosavelives.semaphoreci.com/badges/simple-server/branches/master.svg)](https://resolvetosavelives.semaphoreci.com/projects/simple-server)
[![Ruby Style Guide](https://img.shields.io/badge/code_style-standard-brightgreen.svg)](https://github.com/testdouble/standard)

This is the backend for the Simple app to help track hypertensive patients across a population.

## Table of Contents

* [Development](#development)
* [Documentation](#documentation)
* [Deployment](#deployment)
* [Contributing](#contributing)

## Development

### Dependencies

Make sure you have the following dependencies installed:

- Ruby 2.5.1
- PostgreSQL 10
- Redis
- Yarn

To install these on MacOS:

```
brew cask install postgres
brew install rbenv ruby-build redis yarn
```

To set up Ruby 2.5.1, see https://gorails.com/setup/osx/10.15-catalina

Open Postgres.app and ensure you have a PostgreSQL 10 server initialized.

### Setup

To set up the Simple server for local development, clone the git repository and
run the setup script included.

```
$ git clone git@github.com:simpledotorg/simple-server.git
$ cd simple-server
$ bin/setup
```

#### Manual Setup

If the included `bin/setup` script fails for some reason, you can also manually
set up the application step by step. You can do so as follows.

First, you need to [install
ruby](https://www.ruby-lang.org/en/documentation/installation). It is
recommended to use [rbenv](https://github.com/rbenv/rbenv) to manage ruby
versions. Note that we currently use Bundler version 1.17.3, so that is also hardcoded below.

```bash
gem install bundler -v 1.17.3
bundle _1.17.3_ install
rake yarn:install
rails db:setup
```

##### Issues with MacOS Catalina and Puma

When running `bin/setup` on MacOS Catalina, you may encounter issues installing the `puma` gem related to compiler upgrades Apple issued.

If you see errors like this:

```
compiling puma_http11.c
puma_http11.c:203:22: error: implicitly declaring library function 'isspace' with type 'int (int)' [-Werror,-Wimplicit-function-declaration]
  while (vlen > 0 && isspace(value[vlen - 1])) vlen--;
                     ^
puma_http11.c:203:22: note: include the header <ctype.h> or explicitly provide a declaration for 'isspace'
1 error generated.
make: *** [puma_http11.o] Error 1
make failed, exit code 2
```

To fix, install `puma` with this command:

```
gem install puma:4.3.5 -- --with-cflags="-Wno-error=implicit-function-declaration"
```

Now re-run `bin/setup` to continue installing everything else.

#### Developing with the Android app

To run [simple-android](https://github.com/simpledotorg/simple-android/) app with the server running locally, you can
use [ngrok](https://ngrok.com).

```bash
brew cask install ngrok
rails server
ngrok http 3000
```

The output of the ngrok command is HTTP and HTTPS URLs that can be used to access your local server. The HTTP URL cannot
be used since HTTP traffic will not be supported by the emulator. Configure the following places with the HTTPS URL.

In the `gradle.properties` file in the `simple-android` repository,
```
qaManifestEndpoint=<HTTPS URL>
```

In the `.env.development.local` (you can create this file if it doesn't exist),
```
SIMPLE_SERVER_HOST=<HTTPS URL>
SIMPLE_SERVER_HOST_PROTOCOL=https
```

#### Workers

We use [sidekiq](https://github.com/mperham/sidekiq) to run async tasks. To run, first make sure that redis (>4) is installed:

```bash
brew install redis

# after installing ensure your redis version is >4
redis-server -v
```

### Testing Email

We use [Mailcatcher](https://mailcatcher.me/) for testing email in development. Please use the
following to set it up on your machine.

_Note: Please don't add Mailcatcher to the `Gemfile`, as it causes conflicts._

```bash
gem install mailcatcher
mailcatcher
```

Now you should be able to see test emails at http://localhost:1080

### Testing Web Views

When testing web views like the progress tab or help screens, you will need to authenticate yourself with specific
request headers. You can run the following command to get a set of request headers for a user that you can attach to
your requests.

```
$ bundle exec rails get_user_credentials
```

The command will output a set of request headers that you can attach to your requests using tools like
[Postman](https://www.postman.com/) or [ModHeader](https://bewisse.com/modheader/).

```
Attach the following request headers to your requests:
Authorization: Bearer 9b54814d4b422ee37dad46e7ebee673c59eed088c264e479880cbe7fb5ac1ce7
X-User-ID: 452b96c2-e0cf-49e7-ab73-c328acd3f1e5
X-Facility-ID: dcda7d9d-48f9-47d2-b1cc-93d90c94386e
```

### Review Apps

#### Testing messages

Messages sent through Twilio are currently fixed to specific countries. To override this setting, go to the [heroku console](https://dashboard.heroku.com/pipelines/30a12deb-f419-4dca-ad4a-6f26bf192e6f) and [add/update](https://devcenter.heroku.com/articles/config-vars#managing-config-vars) the `DEFAULT_COUNTRY` config variable on your review app to your desired country. The supported country codes are listed [here](https://github.com/simpledotorg/simple-server/blob/master/config/initializers/countries.rb).

```
# for US/Canada
DEFAULT_COUNTRY = US

# for UK
DEFAULT_COUNTRY = UK
```

Updating this config will automatically restart the review app and should allow one to receive messages in their appropriate ISD codes.

### Configuration

The app uses a base development configuration using `.env.development`. To add or override any configurations during
local development, create a `.env.development.local` file and add your necessary configurations there. If a
configuration change is applicable to all dev environments, ensure that it is added to `.env.development` and checked
into the codebase.

### Running the application locally

Foreman is used to run the application locally. First, install foreman.

```bash
$ gem install foreman
```

Then, run the following command to start the Rails and Sidekiq together.

```bash
$ foreman start -f Procfile.dev
```

**Note:** Foreman will also execute the `whenever` gem in trial mode. This will validate that the `whenever`
configuration is valid, but will not actually schedule any cron jobs.

Alternatively, you can start these services locally _without_ foreman by using the following commands individually.

* Rails: `bundle exec rails server` or `bundle exec puma`
* Sidekiq: `bundle exec sidekiq`

### Running the tests

```bash
RAILS_ENV=test bundle exec rspec
```

### Code

We use the [standard](https://github.com/testdouble/standard#how-do-i-run-standard-in-my-editor) gem as our default formatter and linter. To enable it directly in your editor, follow [this](https://github.com/testdouble/standard#how-do-i-run-standard-in-my-editor).

To check all the offenses throughout the codebase:

```bash
bundle exec rails standard
```
**Note**: The codebase is currently undergoing a slow linting process and hence most files that have offenses have been ignored under a `.standard_todo.yml`. As we fix these files, remove them from the `yml` file so that they can be picked up by `standard` again for future offenses. Refer to [usage](https://github.com/testdouble/standard#usage) on how to generate todo files.


### Generating seed data

To generate seed data, execute the following command from the project root

```bash
$ foreman start -f Procfile.dev
$ bundle exec rails db:seed db:seed_users_data
```
**Note**: This **requires** server and sidekiq to be running.

To purge the generated patient data, run

```bash
bundle exec rails db:purge_users_data
```

**Note**: This only removes data created by `db:seed_users_data`, it keeps the seed data created by `db:seed`.

### Creating an admin user

Run the following command from the project root to create a new dashboard admin:
```bash
bundle exec rails 'create_admin_user[<name>,<email>,<password>]'
```

### View Sandbox data in your local environment

1. Follow the steps in the "How to add an SSH key..." section [here](https://github.com/simpledotorg/deployment) to add your SSH key to the deployment repo
2. Ask someone from the Simple team to add you as an admin to Sandbox
3. Create a password for your Sandbox account and use that to log into the Sandbox dashboard on https://api-sandbox.simple.org
4. Run `ssh deploy@ec2-13-235-33-14.ap-south-1.compute.amazonaws.com` to verify that your SSH access from step 1 was completed successfully.
5. Run `bundle exec cap sandbox db:pull` to sync Sandbox data with your local machine.
6. Use your Sandbox email and password to log into your local environment (http://localhost:3000).

### Profiling

We use the [vegeta](https://github.com/tsenart/vegeta) utility to run performance benchmarks. The suite and additional instructions are [here](./profiling/README.md).

## Documentation

### API

API Documentation can be accessed at `/api-docs` on local server and hosted at https://api.simple.org/api-docs

To regenerate the Swagger API documentation, run the following command.

```
$ bundle exec rake rswag:specs:swaggerize
```

### ADRs

Architecture decisions are captured in ADR format and are available in `/doc/arch`

### ERD (Entity-Relationship Diagram)

These are not actively committed into the repository. But can be generated by running `bundle exec erd`


## Deployment

Simple Server is deployed to several environments using a mixture of tools.

* Ansible: Server management and configuration is done using Ansible. See the [deployment repository](https://github.com/simpledotorg/deployment/tree/master/ansible)
  for more information.
* Capistrano: Application code is deployed to servers for a specific country and environment using Capistrano.
* SemaphoreCI: Continuous deployment

To make a deployment, run the release script.

```
bin/release
```

This will create a git release tag and automatically trigger a deployment to all non-production environments through
Semaphore.

Once complete, trigger a manual deployment to production environments through the
[Semaphore CI dashboard](https://resolvetosavelives.semaphoreci.com/projects/simple-server).

> Make sure you add your SSH keys as single sign-on so that `cap` doesn't get confused when there's more than 1 instance
> to deal with. You can do this simply by running `ssh-add -K ~/.ssh/id_rsa`.

### Deployment to a specific environment

* We use Capistrano [multi-config](https://github.com/railsware/capistrano-multiconfig) to do multi-country deploys.
* All `cap` commands are namespaced with the country name. For eg: `bundle exec india:sandbox deploy`.
* The available country names are listed under `config/deploy`. The subsequent envs, under the country directory, like
  `config/deploy/india/sandbox.rb`

Simple Server can be deployed to a specific environment of a specific country with the following command.

```bash
bundle exec cap <country_name>:<enviroment> deploy
# eg: bundle exec cap india:staging deploy
# or, bundle exec cap bangladesh:production deploy
```

Rake tasks can be run on the deployed server using Capistrano as well. For example,

```bash
bundle exec cap india:staging deploy:rake task=db:seed
```

### Deployment Resources

* [Deployment instructions for Simple Server](doc/deployment.md)
* [Deployment repository](https://github.com/simpledotorg/deployment)

## Contributing

The contribution guidelines can be found [here](doc/contributing.md).
