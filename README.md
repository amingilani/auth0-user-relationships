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

### Generate a User Model

Generate a User model with an indexed string called `auth0_uid`

```
rails g model user auth0_uid:string:index
```
