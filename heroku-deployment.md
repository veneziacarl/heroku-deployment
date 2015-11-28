The following article will cover the steps require to deploy a Sinatra + PG application to Heroku. We have given you a sample application, which you should deploy on your own. Set it up with the following commands:

```no-highlight
# Download the challenge
$ et get heroku-deployment

# Move into the project root directory
$ cd heroku-deployment

# Create the database
$ createdb restaurants

# Add the schema to the database
$ psql restaurants < schema.sql

# Seed the database with data
$ ruby seed.rb

# Install gem dependecies
$ bundle

# Run Sinatra server
$ ruby server.rb
```

Go to `localhost:4567` in your browser to see the sample application.

## Getting Started with Heroku

```no-highlight
# install the heroku toolbelt command line utility if you haven't already
$ brew install heroku-toolbelt

# create a new git repository
$ git init
$ git add .
$ git commit -m initial

# create a new heroku app
$ heroku create your-app-name
```

## `git`

Heroku uses [`git`](https://git-scm.com/) as a means to deploy your application to their servers, as well as manage different versions of your deployed application. This makes it easy to revert back to a known good version of your production application in case your new code doesn't work quite as expected.

When you ran `heroku create your-app-name`, Heroku added a new git remote repository. Run `git remote -v` and take a look at the output.

```no-highlight
$ git remote -v
heroku  git@heroku.com:what-is-for-lunch.git (fetch)
heroku  git@heroku.com:what-is-for-lunch.git (push)
```

We can see that for this particular app, it has a git remote on `heroku.com`. We can use the `git` command line application to `git push` this code to Heroku, where it will run as a **live web application**.

If you were to add a [Github repository]() and run `git remote -v`, the output would change to something similar to this:

```no-highlight
$ git remote -v
heroku  git@heroku.com:what-is-for-lunch.git (fetch)
heroku  git@heroku.com:what-is-for-lunch.git (push)
origin  git@github.com:LaunchAcademy/whats_for_lunch.git (fetch)
origin  git@github.com:LaunchAcademy/whats_for_lunch.git (push)
```

In this case, the app has a two git remotes, one on `github.com`, and another on `heroku.com`. Here we can push this code to GitHub, so that other people can view and collaborate on this project, or we can push the code to Heroku.

## Required Files

Before start pushing code to Heroku, we need to create a few files which will instruct Heroku how to setup and run our application.

### `Gemfile`

The `Gemfile` specifies all of the libraries needed by our application. This file is located in your project's root directory. An example:

```ruby
source "http://rubygems.org"

ruby "2.0.0"

gem "sinatra"
gem "pg"
gem "puma"
```

Here, we have specified the `source` of our gems (or ruby libraries), the version of ruby we are using to develop our application, and the gems necessary for our application to run. Having this information in one place makes it easy for others to grab our code from GitHub and collaboratively build software.

After modifying your `Gemfile`, be sure to `bundle` so that the `Gemfile.lock` is updated and the necessary dependencies are installed.

### `config.ru`

Files that end in `.ru` are `rackup` files. Sinatra is built on [Rack](http://rack.github.io/), which is a very simple web interface. Create a `config.ru` file in your project's root directory with the following contents.

```ruby
require './server'

# disable buffering for Heroku Logplex
$stdout.sync = true

run Sinatra::Application
```

This `config.ru` file will tell Heroku that we are running a Sinatra app.

### `Procfile`

The `Procfile` lets us describe what services will be running. Here, we need to specify how to start our webserver, workers, or other services that our app needs to run. Create a `Procfile` file in your project's root directory with the following contents.

```no-highlight
web: bundle exec puma -C config/puma.rb
```

Here, we are specifying that we want the [Puma](http://puma.io/) webserver to serve our web application. There are other ruby webservers out there, such as Unicorn, and Phusion Passenger. These webservers handle incoming HTTP requests from users and allow multiple concurrent users to access our application.

Let's create the `config/puma.rb` file (i.e. a `puma.rb` file in the `config` folder) with the following content:

```ruby
workers Integer(ENV['WEB_CONCURRENCY'] || 2)
threads_count = Integer(ENV['MAX_THREADS'] || 5)
threads threads_count, threads_count

preload_app!

rackup      DefaultRackup
port        ENV['PORT']     || 3000
environment ENV['RACK_ENV'] || 'development'
```

The configuration for Puma is relying on environment variables to set, or is reverting them to reasonable defaults if they are not.

### `schema.sql`

In order to run our app on a service such as Heroku, we need to be able to recreate the database schema. The schema for this application has been stored in `schema.sql`. You loaded the schema for this application to the "development" database earlier with the `psql restaurants < schema.sql` command.

If you need to recreate the database schema from an existing database, you can do so easily with the following command:

```no-highlight
$ pg_dump -s database_name > schema.sql
```

We will load the schema to our application running on Heroku later in this assignment.

## Databases and Environments

It is good practice to let the environment we are running in dictate the settings to use. For example, if we are in the `development` environment, we are working on our own machine, and we would like to use the local Postgres database that we have created. Update the top of your `server.rb` file, so it looks like this:

```ruby
require "sinatra"
require "pg"

configure :development do
  set :db_config, { dbname: "restaurants" }
end

def db_connection
  begin
    connection = PG.connect(settings.db_config)
    yield(connection)
  ensure
    connection.close
  end
end
```
When our app is in a `production` environment, it is running on a remote server somewhere "in the cloud". In that case, we would like to pull the database settings from the environment. When we ran the `heroku create` command, a number of actions occur, including the initialization of a Postgres database. The location of this database is stored as a URL in an **environment variable**.

Your system stores many settings in the environment. Take a look at your local environment variables with the `printenv` command.

The `heroku config` command will show us the environment variables stored on the server that will host our application:

```no-highlight
$ heroku conifg
=== application Config Vars
DATABASE_URL: postgres://wrwzzupzlpeqbr:dc3h7WnfaX-fRA-ck-QpiXXQSg@ec2-50-19-249-214.compute-1.amazonaws.com:5432/da6e1b6hd34c77
HEROKU_POSTGRESQL_CHARCOAL_URL: postgres://wrnnzupolpeqbr:dc2h7WxfaQ-fRA-ck-QpiXXQSg@ec2-50-19-249-214.compute-1.amazonaws.com:5432/da6e1b6hz34c77
LANG: en_US.UTF-8
RACK_ENV: production
```

We can pull the value for the `DATABASE_URL` from the environment with ruby.

```ruby
database_url = ENV["DATABASE_URL"]
```

The next step is getting it into a format that the `PG::connect` statement will accept. If we lookup the [documentation for this method](http://deveiate.org/code/pg/PG/Connection.html#method-c-new), we see that the `PG.connect` method needs the parts of the `DATABASE_URL` split into its component parts: host, port, dbname, user, and password. Luckily, there is a Ruby core library that takes care of this process for us, specifically the [URI::parse](http://ruby-doc.org/stdlib-2.0.0/libdoc/uri/rdoc/URI.html#method-c-parse) method.

```ruby
database_url = ENV["DATABASE_URL"]
uri = URI.parse(database_url)
```

Now, we can organize this data in a form that the `PG::connect` method will accept. Update the top of your `server.rb` so it looks like this:

```ruby
require "sinatra"
require "pg"

configure :development do
  set :db_config, { dbname: "restaurants" }
end

configure :production do
  uri = URI.parse(ENV["DATABASE_URL"])
  set :db_config, {
    host: uri.host,
    port: uri.port,
    dbname: uri.path.delete('/'),
    user: uri.user,
    password: uri.password
  }
end

def db_connection
  begin
    connection = PG.connect(settings.db_config)
    yield(connection)
  ensure
    connection.close
  end
end
```

## Deploy

Our Sinatra app is primed for deployment on Heroku. However, we still have a few steps to perform:

```no-highlight
# commit our changes
$ git add .
$ git commit -m "app primed for deployment"

# deploy!
$ git push heroku master

# set up the production database schema
$ heroku pg:psql DATABASE_URL < schema.sql

# seed the heroku database
$ heroku run ruby seed.rb
```

## Check it out

`heroku open` will take you to your app's page. If everything went well, you should see your app. If not, don't fret. This is normal.

## Troubleshooting Production Issues

### Reading the logs

It is rare that your first deployment goes smoothly. The first step is to check the logs.

```no-highlight
$ heroku logs -n 100
```

```no-highlight
# ...
2015-07-30T05:54:48.628532+00:00 heroku[web.1]: State changed from starting to up
2015-07-30T05:54:49.530710+00:00 heroku[router]: at=info method=GET path="/robots.txt" host=what-is-for-lunch.herokuapp.com request_id=b81ba60d-cfc0-44f3-b691-e49508ba1e42 fwd="151.80.31.145" dyno=web.1 connect=0ms service=30ms status=404 bytes=234
2015-07-30T05:54:49.528299+00:00 app[web.1]: 151.80.31.145 - - [30/Jul/2015:05:54:49 +0000] "GET /robots.txt HTTP/1.1" 404 18 0.0115
2015-07-30T06:58:31.657420+00:00 heroku[web.1]: Idling
2015-07-30T06:58:31.658152+00:00 heroku[web.1]: State changed from up to down
2015-07-30T06:58:35.314586+00:00 heroku[web.1]: Stopping all processes with SIGTERM
2015-07-30T06:58:36.183641+00:00 app[web.1]: [3] - Gracefully shutting down workers...
2015-07-30T06:58:36.456140+00:00 app[web.1]: [3] === puma shutdown: 2015-07-30 06:58:36 +0000 ===
2015-07-30T06:58:36.456146+00:00 app[web.1]: [3] - Goodbye!
2015-07-30T06:58:37.679962+00:00 heroku[web.1]: Process exited with status 0
```

What can you determine from the logs? Each line contains a timestamp and a message. Look for lines that contains a HTTP request. What is the verb? What is the response code?

### Checking the Database

Log into the remote psql console: `heroku pg:psql`. Is the schema set up correctly? Hint: try the `\d` command.

### `irb` to the Rescue!

If you would like to interact with your production application using `irb`, try the following commands:

```no-highlight
$ heroku run irb
irb(main):001:0> require './server'
```

This will put you into an `irb` session on your production application. You can then make calls to methods and classes you have defined. Definitely a helpful tool for troubleshooting.

### Still Stuck?

If your production app is still not working, and you aren't sure what to try next. Throw in a [Horizon Question](/questions/new), and we will be happy to help.

## Submitting this Assignment

Please include a link to your live application in the README.md file.

## Resources

* [Heroku Dev Center](https://devcenter.heroku.com/)
* [Getting Started with Ruby on Heroku](https://devcenter.heroku.com/articles/getting-started-with-ruby-o)
* [Puma on Heroku](https://devcenter.heroku.com/articles/deploying-rails-applications-with-the-puma-web-server#adding-puma-to-your-application)

