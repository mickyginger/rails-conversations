//= require cable
//= require_self
//= require_tree .

this.App = {};

App.cable = ActionCable.createConsumer();

App.messages = App.cable.subscriptions.create('MessagesChannel', {  
  received: function(data) {
    
    if(!!location.pathname.match("conversations/" + data.conversation_id) || !!$('li[data-conversation-id='+ data.conversation_id + ']').length) {
      Turbolinks.visit(location);
    }
  }
});