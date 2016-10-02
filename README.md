# Creating Sane Web Apps with Rails and Auth0

This tutorial was for a problem I ran into, and fixed for myself. There were no tutorials that addressed this particular problem, so I made my own. If I could have a conversation with Past Me, it would go something like this:

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

## Creating a Rails App

Do you seriously need instructions for this?

`rails new `
