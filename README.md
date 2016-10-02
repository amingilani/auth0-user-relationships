# Auth0 with Rails 5

The existing documentation at Auth0 is overly simplistic and aims to get you up and running really fast. This tutorial gets you up and running really fast, but while observing all of the usual Rails' conventions.

The Auth0 documentation also contains a few typos that break your code, this (hopefully) doesn't

## Setting up an Auth0 powered Rails App

There's already an Auth0 tutorial on making a Ruby on Rails app, but it skips over a few best practices to keep things simple. I'll walk you through a more powerful initial setup.

### Generating a Rails App

If you're working with rails, you already know this, but I like to keep things complete.

```bash
$ rails new auth0_setup --database=postgresql
```

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
rails g controller PublicPages home && \
rails g controller Dashboard show && \
rails g controller auth0 callback failure --skip-template-engine --skip-assets
```

Troubleshoot:
If you get errors, you should probably setup your db with `rails db:setup && rails db:migrate`

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

```ruby
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

### Add the callback link to Auth0

Auth0 only allows callbacks to a whitelist so specify your callback urls at [Application Settings](https://manage.auth0.com/#/applications):

```
https://liveapplication.example.com/auth/auth0/callback
http://localhost:3000/auth/auth0/callback
```

The second one is to let you develop locally.

### Creating a login page

Replace the contents of `app/views/public_pages/home.html.erb`

```html
<div id="root" style="width: 320px; margin: 40px auto; padding: 10px; border-style: dashed; border-width: 1px; box-sizing: border-box;">
    embedded area
</div>
<script src="https://cdn.auth0.com/js/lock/10.2/lock.min.js"></script>
<script>
  var lock = new Auth0Lock(
    <%= Rails.application.secrets.auth0_client_id %>,
    <%= Rails.application.secrets.auth0_domain %>, {
    container: 'root',
    auth: {
      redirectUrl: '',
      responseType: 'code',
      params: {
        scope: 'openid email' // Learn about scopes: https://auth0.com/docs/scopes
      }
    }
  });
  lock.show();
</script>
```

### An auth0 helper

Coming from using Devise for authentication in Rails, I liked the helpers it gave so let's recreate those. Add the following to `app/helpers/auth0_helper.rb`

```ruby
module Auth0Helper
  private

  # Is the user signed in?
  # @return [Boolean]
  def user_signed_in?
    session[:userinfo].present?
  end

  # Set the @current_user or redirect to public page
  def authenticate_user!
    # Redirect to page that has the login here
    if user_signed_in?
      @current_user = session[:userinfo].uid
    else
      redirect_to login_path
    end
  end

  # What's the current_user?
  # @return [Hash]
  def current_user
    @current_user
  end

  # @return the path to the login page
  def login_path
    root_path
  end
end
```

### Add the helper to ApplicationController

Add this line to your `app/controllers/application_controller.rb` access your helpers in all your controllers

```ruby
include Auth0Helper
```

### Showing user info in the dashboard

`app/controllers/dashboard_controller.rb`
```
before_action :authenticate_user!

class DashboardController < ApplicationController
  def show
    @user = current_user
  end
end
```

`app/views/dashboard/show.html.erb`
```
<div>
  <img class="avatar" src="<%= @user[:info][:image] %>"/>
  <h2>Welcome <%= @user[:info][:name] %></h2>
</div>
```

We're done!

### Descriptive Errors

When authentication fails, you want to display the reason for the failure, so add this to your `config/environments/production.rb`

```ruby
OmniAuth.config.on_failure = Proc.new { |env|
  message_key = env['omniauth.error.type']
  error_description = Rack::Utils.escape(env['omniauth.error'].error_message)
  new_path = "#{env['SCRIPT_NAME']}#{OmniAuth.config.path_prefix}/failure?message=#{message_key}&error_description=#{error_description}"
  Rack::Response.new(['302 Moved'], 302, 'Location' => new_path).finish
}
```

### Overflowing Cookies in Development

To make your app work in development:

1. Add this to `/config/initializers/session_store.rb`

   ```
   Rails.application.config.session_store :cache_store
   ```

2. Add this to the end of the config block in `/config/enviroments/development.rb` so that it overrides all other instances:

   ```
   # enforce this rule
   config.cache_store = :memory_store
   ```
