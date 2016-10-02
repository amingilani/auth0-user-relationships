# Auth0 with Rails 5

This tutorial was for a problem I ran into, and fixed for myself.

> As an application, I should be able to create database
> relationships between my users and other tables but I can't
> because I don't have a users table in my database

There were no tutorials that addressed this particular problem, so I made my own.

## How it works

If I could have a conversation with Past Me, it would go something like this:

*How do I create a relationships with my User model, if I don't actually have a User model*  
Well, make one, dummy!  
*But the whole point of Auth0 is so that I don't have to manage users myself!*  
Yes, you don't. But having a User model in your database doesn't mean you're managing Users, or storing information about them -- infact, you don't have to store any information about your users at all, except a unique ID to reference them from Auth0  
*But then how do I display things like user names and profile information?*  
Auth0 has an API your server can call upon.  
*Ohhhh, I see where this is headed.*
You can fetch and show user information on the fly. It'll always be up to date, and you'll never have to write to your database.
*Ahhh, but what if Auth0's server fails?*  
Then you have bigger problems than fetching user information: your users won't be able to login in the first place. Besides, that's a risk you accepted when chose Auth0's convenience over setting up your own authentication service, **and** if you're a hobby dev or small team, do you think your uptime will be better than Authy's?  
*Nevermind, let's get to the tutorial already*  
Good boy.

## Setting up an Auth0 powered Rails App

There's already an Auth0 tutorial on making a Ruby on Rails app, but it skips over a few best practices to keep things simple. I'll walk you through a more powerful initial setup.

### Generating a Rails App

If you're working with rails, you already know this, but I like to keep things complete.

[![asciicast](https://asciinema.org/a/48351.png)](https://asciinema.org/a/48351)

### Setting up Gems

We're going to be storing secrets in environment variables, so for dev purposes, we need an extra gem. Add the following to your `Gemfile`:

```ruby
# Standard Auth0 requirements
gem 'omniauth', '~> 1.3.1'
gem 'omniauth-auth0', '~> 1.4.1'
# Secrets should never be stored in code
gem 'dotenv-rails', require: 'dotenv/rails-now', group: [:development, :test]
```

### Gitignore secrets

Add the following to your `.gitignore` and commit this now:

```bash
# Ignore the environment variables
.env
```

### Setup your environment variables

When in development or testing, we want to load secrets from outside version control, so create a `.env` file with the following content:

```
AUTH0_CLIENT_ID= #INSERT YOUR SECRET HERE
AUTH0_MANAGEMENT_JWT= #INSERT YOUR SECRET HERE
AUTH0_DOMAIN= #INSERT YOUR SECRET HERE
```

### Add to your app secrets

Instead of fetching the secrets directly in your code, fetch them once in the secrets file, where they should be and refer them via this file throughout your code. Make the following changes to your `config/secrets.yml`

```yaml
# Add this to the top of the file
default: &default
  auth0_client_id: <%= ENV['AUTH0_CLIENT_ID'] %>
  auth0_client_secret: <%= ENV['AUTH0_CLIENT_SECRET'] %>
  auth0_management_jwt: <%= ENV['AUTH0_MANAGEMENT_JWT'] %>
  auth0_domain: <%= ENV['AUTH0_DOMAIN'] %>

# Make the rest of your groups inherit from default
development:
  <<: *default
  ...

test:
  <<: *default
  ...

# Do not keep production secrets in the repository,
# instead read values from the environment.
production:
  <<: *default
  ...

```

### Create an initializer

Create `config/initializers/auth0.rb` to configure OmniAuth.

```ruby
# Configure the middleware
Rails.application.config.middleware.use OmniAuth::Builder do
  provider(
    :auth0,
    Rails.application.secrets.auth0_client_id,
    Rails.application.secrets.auth0_client_secret,
    Rails.application.secrets.auth0_domain,
    callback_path: '/auth/auth0/callback'
  )
end
```

### Generating Controllers

We want two pages for our simplistic app, a publicly accessible contoller home page, and a privately accessible dashboard, as well as a controller without pages for an authentication api:

```bash
$ rails g controller PublicPages home && \
> rails g controller Dashboard show && \
> rails g controller auth0 callback failure --skip-template-engine --skip-assets
```

### Fixing routes

We want to route all the get requests to our controllers and actions

```ruby
# home page
root 'public_pages#home'

# Dashboard
get 'dashboard' => 'dashboard#show'

# Auth0 routes for authentication
get '/auth/auth0/callback' => 'auth0#callback'
get '/auth/failure'        => 'auth0#failure'
```

### Setup the Auth0 Controller

Replace the file in `/app/controllers/auth0_controller.rb` with

```
class Auth0Controller < ApplicationController
  def callback
    # This stores all the user information that came from Auth0
    # and the IdP
    session[:userinfo] = request.env['omniauth.auth']

    # Redirect to the URL you want after successful auth
    redirect_to '/dashboard'
  end

  def failure
    # show a failure page or redirect to an error page
    @error_msg = request.params['message']
  end
end
```

### Creating a login page

Replace the contents of `app/views/public_pages/home.html.erb`
```
```
