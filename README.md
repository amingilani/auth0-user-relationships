# Relationships with Users when using Auth0

This tutorial was for a problem I ran into, and fixed for myself. Here's a nice user story explaining the problem:

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

## Building the App

Here's what we need to do:

1. Create a `User` model containing nothing more than a user's UUID
2. Extend `User` to load user data from Auth0's API to an instance variable upon initialize
3. Extend `User` with a method that allows you to access the user data
4. Extend the `Auth0Helper` to save and return the `User` to our `current_user` helper

### Add the Auth0 Gem

Add the following line to your `Gemfile` and run `bundle`:
```ruby
# Auth0's API
gem 'auth0'
```

### Generate an Management API token

Auth0 uses JWTs as API tokens. To be able to read your User's from the Management API:

1. Visit the Auth0 [Management API](https://auth0.com/docs/api/management/v2)'s [get_users](https://auth0.com/docs/api/management/v2#!/Users/get_users) endpoint
2. Check the `read:users` and `read:user_idp_tokens` scopes, and copy the token in the top left corner.

![Generating the get users](http://g.recordit.co/OpGpEozmsv.gif)

### Add the token to your environment variables

Add the following line to your `.env` file

```bash
AUTH0_MANAGEMENT_JWT= # Add your token here
```

### Add the token to your secrets

Extend the `defaults` block in `config/secrets.yml`

```yaml
default: &default
  auth0_client_id: <%= ENV['AUTH0_CLIENT_ID'] %>
  auth0_client_secret: <%= ENV['AUTH0_CLIENT_SECRET'] %>
  auth0_management_jwt: <%= ENV['AUTH0_MANAGEMENT_JWT'] %>
  auth0_domain: <%= ENV['AUTH0_DOMAIN'] %>
```

### Generate a User Model

Generate a User model with an indexed string column called `auth0_uid`

```bash
rails g model user auth0_uid:string:index && \
rails db:migrate
```

### Add a method to load user data

We want a method to run in `initialize` and to load the user information into an instance variable

```ruby
class User < ApplicationRecord
  after_initialize :set_instance_variables

  ...

  private

  def set_instance_variables
    @user ||= auth0_api.user auth0_id
  end

  def auth0_api
    Auth0Client.new(
      client_id: Rails.application.secrets.auth0_client_id,
      token: Rails.application.secrets.auth0_management_jwt,
      domain: Rails.application.secrets.auth0_domain,
      api_version: 2
    )
  end
end
```

Now, create a method to access the user info

```ruby
class User < ApplicationRecord

  ...

  def info(key = nil)
    key.nil? ? @user : @user[key.to_s]
  end

  private

  ...

end

```

### Update the helper to load User

Update the helper to set `@current_user` with a `User` instance:

```
def authenticate_user!
  # Redirect to page that has the login here
  if user_signed_in?
    @current_user = User.find_or_create_by(
      auth0_id: session[:userinfo].uid
    )
  else
    redirect_to root_path
  end
end
```

### Update the view

Update the dashboard view at `app/views/dashboard/show.html.erb`

```
<h2>Welcome <%= @user.info :name %></h2>
```

### Read the Docs

You'll find the entire schema at for the Auth0 API response in the docs for the [User](https://auth0.com/docs/api/management/v2#!/Users/get_users) resource


## Next steps

With a `User` model in your database, you can now go ahead and add as many `belongs_to` or `has_many` relationships you want in your database. Your user's info will always be up to date, and you still don't have to handle authentication yourself.
