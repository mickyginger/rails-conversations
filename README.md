# Creating an internal messaging system in Rails 5: a walkthrough

> **Note:** This app was lifted almost line by line from [an excellent article by Dana Muller](https://medium.com/@danamulder/tutorial-create-a-simple-messaging-system-on-rails-d9b94b0fbca1#.bheztdsw0). I've made a few changes to her solution, but I highly recommend reading the article.

> **Note:** This guide assumes you've already implemented a user authentication system. I'm using Devise here, but a custom BCrypt system would work equally well.

## Overview

![inbox](https://raw.githubusercontent.com/mickyginger/rails-conversations/master/screen-shot-1.png)

![messges](https://raw.githubusercontent.com/mickyginger/rails-conversations/master/screen-shot-2.png)

The system requires 3 models: `User`, `Message` and `Conversation`. The conversation is simply a container for messages. It is essentially a relationship between two users. The system we are going to create will effectivly mimic a phone text message system, where the user clicks on the name of a contact and all of the messages between those two people will be displayed there.

## Setup

We will not be using `scaffold` at all throughout this walkthrough, since we only need a few, very specific views.

## Conversation model

The conversation model and respective database table is quite unusual, so we're going to build it piecemeal, starting with a custom migration:

`rails g migration CreateConversations`

This will give you the following migration: 
```ruby
class CreateConversations < ActiveRecord::Migration[5.0]
  def change
    create_table :conversations do |t|
    end
  end
end
```
Update it as follows:

```ruby
class CreateConversations < ActiveRecord::Migration[5.0]
  def change
    create_table :conversations do |t|
      t.integer :sender_id
      t.integer :receiver_id
      
      t.timestamps
    end
  end
end
```

Then run the migration with `rake db:migrate`

Since the sender_id *and* the receiver_id will both be user ids, we need to construct a very specific model. First we'll manually create the model file:

`touch app/models/conversation.rb`

Then flesh out the model: 

```ruby
class Conversation < ApplicationRecord
  belongs_to :sender, class_name: "User", foreign_key: "sender_id"
  belongs_to :receiver, class_name: "User", foreign_key: "receiver_id"
end
```

Here, we've indicated that the `sender_id` and `receiver_id` are both ids from the user table. So when we do `conversation.sender` or `conversation.receiver`, ActiveRecord will attempt to find a user with those ids.

But wait, there's more...

A conversation will have many messages, so we can add that relationship to the model now as well:

```ruby
class Conversation < ApplicationRecord
  belongs_to :sender, class_name: "User", foreign_key: "sender_id"
  belongs_to :receiver, class_name: "User", foreign_key: "receiver_id"
  has_many :messages, dependent: :destroy
end
```

We're also going to add a validation as well. We want to make sure that only one conversation is created between two users, regardless of who is the `receiver` and who is the `sender`.

If Sarah starts a conversation with Bradley, Sarah is the `sender` and Bradley the `receiver`. If Bradley wants to send Sarah a message, he should use the same conversation that has already been set up between those two users, even though he is now the `sender`.

```ruby
class Conversation < ApplicationRecord
  belongs_to :sender, class_name: "User", foreign_key: "sender_id"
  belongs_to :receiver, class_name: "User", foreign_key: "receiver_id"
  has_many :messages, dependent: :destroy
  
  validates_uniqueness_of :sender_id, scope: :receiver_id
end
```

The `scope` option limits the uniqueness check.

> **Note:** more info on ActiveRecord validations can be found in the [official docs](http://guides.rubyonrails.org/active_record_validations.html)

Finally, we need to add a class method `between` which will allow us to find the conversation between to users, regardless of who is the `sender` and who is the `receiver`. To create a class method with ActiveRecord, we use the `scope` method, like so:

```ruby
class Conversation < ApplicationRecord
  belongs_to :sender, class_name: "User", foreign_key: "sender_id"
  belongs_to :receiver, class_name: "User", foreign_key: "receiver_id"
  has_many :messages, dependent: :destroy

  validates_uniqueness_of :sender_id, scope: :receiver_id

  scope :between, -> (sender_id,receiver_id) do
    where("(conversations.sender_id = ? AND conversations.receiver_id = ?) OR (conversations.receiver_id = ? AND conversations.sender_id = ?)", sender_id, receiver_id, sender_id, receiver_id)
  end
end
```

Here we have created some custom SQL. `Conversation.between` will take two arguments, both user ids, and try to find a conversation that has either one as sender OR receiver. We be using this later.

## Message model

This will be a lot simpler! We can generate the model directly like so:

`rails g model Message body:text conversation:references user:references read:boolean`

Before running the migration that is created, we need to set `read` to be `false` by default. Amend the migration like so:

```ruby
class CreateMessages < ActiveRecord::Migration[5.0]
  def change
    create_table :messages do |t|
      t.text :body
      t.references :conversation, foreign_key: true
      t.references :user, foreign_key: true
      t.boolean :read, default: false

      t.timestamps
    end
  end
end
```

Then `rake db:migrate`

We're just going to add a validation to the message model to ensure all of the fields are filled in:

```ruby
class Message < ApplicationRecord
  belongs_to :conversation
  belongs_to :user

  validates_presence_of :body, :conversation_id, :user_id
end
```

While we're here, we can add some formatting to the timestamp, so we can display the time of the message in a more human readable way:

```ruby
class Message < ApplicationRecord
  belongs_to :conversation
  belongs_to :user

  validates_presence_of :body, :conversation_id, :user_id

  private
    def message_time
      created_at.strftime("%d/%m/%y at %l:%M %p")
    end
end
```

Done and done.

## Routes

The routing for this system is actually very straightforward. We want a `conversations` index page, which will display all the conversations a user has. We also want a `conversations_messages` index page that will display all the messages for that conversation.

We can do that very simply like so:

```ruby
# config/routes.rb
  devise_for :users

  resources :conversations, only: [:index, :create] do
    resources :messages, only: [:index, :create]
  end
```

You can see how that has affected your app's routes by typing `rails routes` in the terminal.

## Conversations controller

The conversations controller will basically handle showing all convesations, and creating new conversations when needed. It will only need `index` and `create` methods.

Lets make this now:

`rails g controller conversations index`

This will create the controller and an `index.html.erb` file in `app/views/conversations/`

Let's flesh out the controller:

```ruby
class ConversationsController < ApplicationController
  before_action :authenticate_user!
  
  def index
    @conversations = Conversation.where("sender_id = ? OR receiver_id = ?", current_user.id, current_user.id)
    @users = User.where.not(id: current_user.id)
  end
end
```

For the index, we will display a list of all the conversations that the current user has on the go, and a list of the users that are signed up to the app.

Notice that I have added the `authenticate_user!` method as a `before_action`. The user **must** be logged in to view their messages!

Let's now add the `create` method. First we will check if a conversation already exists between the two users. If it does we will redirect the user to that conversation's messages index page. If not, we will create the conversation and then redirect the user.

```ruby
class ConversationsController < ApplicationController
  before_action :authenticate_user!
  
  def index
    @users = User.where.not(id: current_user.id)
    @conversations = Conversation.where("sender_id = ? OR receiver_id = ?", current_user.id, current_user.id)
  end

  def create
    if Conversation.between(params[:sender_id], params[:receiver_id]).present?
      @conversation = Conversation.between(params[:sender_id], params[:receiver_id]).first
    else
      @conversation = Conversation.create!(conversation_params)
    end

    redirect_to conversation_messages_path(@conversation)
  end

  private
    def conversation_params
      params.permit(:sender_id, :receiver_id)
    end
end
```
This is where the `between` method we created in the model comes in to play.

### The view

There's only one view we need to create here. Here's a skeleton view which you can amend and style to your liking:

```erb
<h1>Inbox</h1>
<ul>
  <% @conversations.each do |conversation| %>
    <% recipient = conversation.sender_id == current_user.id ? conversation.receiver : conversation.sender %>
    <li><%= link_to recipient.username, conversation_messages_path(conversation) %></li>
  <% end %>
</ul>


<h2>Users</h2>
<ul>
  <% @users.each do |user| %>
    <li><%= link_to user.username, conversations_path(sender_id: current_user.id, receiver_id: user.id), method: :post %></li>
  <% end %>
</ul>
```

## Messages controller

As before we can generate the controller like so:

`rails g controller messages index`

Here's the completed controller. Take a look, then I'll talk you through it:

```ruby
class MessagesController < ApplicationController
  before_action :authenticate_user!
  
  before_action do
    @conversation = Conversation.find(params[:conversation_id])
  end

  def index
    @messages = @conversation.messages

    @messages.where("user_id != ? AND read = ?", current_user.id, false).update_all(read: true)

    @message = @conversation.messages.new
  end

  def create
    @message = @conversation.messages.new(message_params)
  @message.user = current_user

    if @message.save
      redirect_to conversation_messages_path(@conversation)
    end
  end

  private
    def message_params
      params.require(:message).permit(:body, :user_id)
    end
end
```

We start by ensuring the user is logged in. Since we are always going to need the current conversation regardless of what we are doing, we can use the `before_action` hook to pull that from the database.

In the `index` method, we can pull out all of the messges from the conversation. Since all the messages will be on the page, we can assume the user has read all the unread messages that were sent to her, so we update the `read` attribute of any messages sent by the other user to be `true`. After that, we create a new message, ready for the user to add the content.

The `create` method is standard, we save the message and redirect to the same page, so the user can see their new message has been added to the conversation.

### The view

Again, a skeleton view for your consideration:

```erb
<ul>
  <% @messages.each do |message| %>
    <% if message.body %>
      <li>
        <h4><%= message.user.username %></h4>
        <p><%= message.body %></p>
      </li>
    <% end %>
  <% end %>
</ul>

<%= form_for [@conversation, @message] do |f| %>
  <div class="field">
    <%= f.text_area :body, placeholder: "Your message" %>
  </div>

  <%= f.submit "Send" %>
<% end %>
```

The only thing here that's unusual is the `form_for` tag. We're passing two models. This will mean that the form points to the correct url, eg: `/conversaions/1/messges/`

## Cleaning up our views

The ideal goal with the MVC design pattern is to have the model take care of all the data, and as much logic as possible, leaving our views and controllers as clean as possible. We can remove the `reciever` variable from the conversations index page and move the logic into the model:

```ruby
# app/models/conversation.rb
class Conversation < ApplicationRecord
  belongs_to :sender, class_name: "User", foreign_key: "sender_id"
  belongs_to :receiver, class_name: "User", foreign_key: "receiver_id"
  has_many :messages, dependent: :destroy

  validates_uniqueness_of :sender_id, scope: :receiver_id

  scope :between, -> (sender_id, receiver_id) do
    where("(conversations.sender_id = ? AND conversations.receiver_id = ?) OR (conversations.receiver_id = ? AND conversations.sender_id = ?)", sender_id, receiver_id, sender_id, receiver_id)
  end

  def recipient(current_user)
    self.sender_id == current_user.id ? self.receiver : self.sender
  end

end
```

We've created a new method `recipient`, which will return the other user (ie not the `current_user`) from the conversation. Unfortunately we have to pass `current_user` into the method since `current_user` is not available in the model by design.

> **Note:** Some more info about that from (StackOverflow)[http://stackoverflow.com/questions/2513383/access-current-user-in-model]

Now we can use it in our view

```erb
<h1>Inbox</h1>

<ul>
  <% @conversations.each do |conversation| %>
    <li>
      <%= link_to conversation.recipient(current_user).username, conversation_messages_path(conversation) %>
    </li>
  <% end %>
</ul>

...

```

Ah, that's much nicer

## Unread message count

Finally, lets display the number of unread messages in a conversation. Again, not **all** the unread messages, just the unread messages that were posted by the other user. Let's make a new method in the model to handle that:

```ruby
class Conversation < ApplicationRecord
  belongs_to :sender, class_name: "User", foreign_key: "sender_id"
  belongs_to :receiver, class_name: "User", foreign_key: "receiver_id"
  has_many :messages, dependent: :destroy

  validates_uniqueness_of :sender_id, scope: :receiver_id

  scope :between, -> (sender_id, receiver_id) do
    where("(conversations.sender_id = ? AND conversations.receiver_id = ?) OR (conversations.receiver_id = ? AND conversations.sender_id = ?)", sender_id, receiver_id, sender_id, receiver_id)
  end

  def recipient(current_user)
    self.sender_id == current_user.id ? self.receiver : self.sender
  end

  def unread_message_count(current_user)
    self.messages.where("user_id != ? AND read = ?", current_user.id, false).count
  end

end
```

Great, let's update the view

```erb
<h1>Inbox</h1>

<ul>
  <% @conversations.each do |conversation| %>
    <li>
      <%= link_to conversation.recipient(current_user).username, conversation_messages_path(conversation) %>
      <% if !conversation.unread_message_count(current_user).zero? %>
        (<%= conversation.unread_message_count(current_user) %>)
      <% end %>
    </li>
  <% end %>
</ul>
```

If there are unread messages (ie, the `unread_message_count` is not 0), then we can display them on the screen.

> **Note:** if you're using bootstrap (a list group with badges)[http://getbootstrap.com/components/#list-group-badges] might be useful here.

## Real-time Rails

> **Note:** this section was heavily influenced by [another great article, this time by Sophie DeBenedetto](https://blog.heroku.com/real_time_rails_implementing_websockets_in_rails_5_with_action_cable) for Heroku

Adding websocket functionality is simple with rails 5, thanks to ActionCable but does require a bit of setup

First we need to mount the websocket server in the routes file:

```ruby
Rails.application.routes.draw do
  mount ActionCable.server => '/cable'

  devise_for :users
  root 'conversations#index'

  resources :conversations, only: [:index, :create] do
    resources :messages, only: [:index, :create]
  end
end
```

Next we need to create a client-side websocket request handler. First we need to create a js file in the `channels` folder

```bash
touch app/assets/javascripts/channels/messages.js
```

Then actually create the request handler:

```javascript
// app/assets/javascripts/channels/messages.js

//= require cable
//= require_self
//= require_tree .

this.App = {};

App.cable = ActionCable.createConsumer(); 
```

This file is so far just creating a connection with the webserver. We'll update it sortly to actually do something when a message is sent.

> **Note:** The websocket URI is `/cable` by default. If we want to set it to something else we can do so in a config file, like so: `config.action_cable.url = "ws://localhost:3000/something-else"`

We also need to include an `<%= action_cable_meta_tag %>` in `app/views/layouts/application.html.erb`.

### The channel

OK, next we need to create a channel. This will handle all the requests for a specific resource. Rails has a generator for this:

```bash
rails g channel messages
```

This will create a new file `app/channels/messages_channel.rb`. We simply need to update the `subscribed` method therein:

```ruby
class MessagesChannel < ApplicationCable::Channel
  def subscribed
    stream_from "messages"
  end

  def unsubscribed
    # Any cleanup needed when channel is unsubscribed
  end
end
```

### Broadcasting an event

When a user adds a message to a conversation, we are going to broadcast the conversation id. If any users are currently displaying that conversation, we will reload the page.

So firstly we need to update our messages controller to broadcast when a message is created:

```ruby
# app/controllers/messages_controller.rb
class MessagesController < ApplicationController

  ...

  def create
    @message = @conversation.messages.new(message_params)
    @message.user = current_user

    if @message.save
      ActionCable.server.broadcast "messages", { conversation_id: @conversation.id }
      redirect_to conversation_messages_path(@conversation)
    end
  end

  ...
  
end

```

So we're simply broadcasting the `conversation_id` of the message that was created along the `messages` channel.

### "Reloading" the page

Finally we need to receive that broadcast, and if the user is displaying that message, reaload the page.

We're going to do that in the javascript file we created earlier:

```javascript
// app/assets/javascripts/channels/messages.js

//= require cable
//= require_self
//= require_tree .

this.App = {};

App.cable = ActionCable.createConsumer();

App.messages = App.cable.subscriptions.create('MessagesChannel', {
  received: function(data){
    if(!!location.pathname.match("conversations/" + data.conversation_id) || !!$('[data-conversation-id='+ data.conversation_id + ']').length) {
      Turbolinks.visit(location);
    }
  }
});
```
The data we sent down the channel is picked up by the `received` method of our subscription. We can access it from the `data` object passed into the method. So `data.conversation_id` should be the id of the conversation that was just added to.

We first check to see if we are on the messages page for that conversation, buy checking the url (eg: `/conversations/1`). If not, we check if the conversation is visible on the conversations index page by checking for a data attribute to see if we can find the updated conversation id there. Either way, if the user can see the conversation on their screen, we update the view using the `Turbolinks.visit` method.

> **Note:** for more information about turbolinks [consult the documentation](https://github.com/turbolinks/turbolinks)

### Adding the data-attribute to the conversations index page

Finally we need to update the conversations index page to include those all important data-attributes on the conversations that we're listing there:

```erb
<h1>Inbox</h1>

<ul>
  <% @conversations.each do |conversation| %>
    <li data-conversation-id="<%= conversation.id %>">
      <%= link_to conversation.recipient(current_user).username, conversation_messages_path(conversation) %>
    </li>
  <% end %>
</ul>
```

Great! Now regardless of which page the user is on, if a message is added to a conversation, the user will know about it immediately.