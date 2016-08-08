["users", "conversations", "messages"].each do |table_name|
  ActiveRecord::Base.connection.execute("TRUNCATE #{table_name} RESTART IDENTITY CASCADE")
end

User.create([
  {
    username: "mickyginger",
    email: "mike.hayden@ga.co",
    password: "password",
    password_confirmation: "password",
    image: File.open(Rails.root.join 'db/images/mike.png')
  },{
    username: "julesjam",
    email: "jules@ga.co",
    password: "password",
    password_confirmation: "password",
    image: File.open(Rails.root.join 'db/images/jules.jpg')
  },{
    username: "jasonlai",
    email: "jason@ga.co",
    password: "password",
    password_confirmation: "password",
    image: File.open(Rails.root.join 'db/images/jason.jpg')
  },{
    username: "steadyx",
    email: "ed@ga.co",
    password: "password",
    password_confirmation: "password",
    image: File.open(Rails.root.join 'db/images/ed.jpg')
  },{
    username: "willcook",
    email: "will@ga.co",
    password: "password",
    password_confirmation: "password",
    image: File.open(Rails.root.join 'db/images/will.jpg')
  },{
    username: "toni155",
    email: "toni@ga.co",
    password: "password",
    password_confirmation: "password",
    image: File.open(Rails.root.join 'db/images/toni.jpg')
  },{
    username: "chetanbarot",
    email: "chetan@ga.co",
    password: "password",
    password_confirmation: "password",
    image: File.open(Rails.root.join 'db/images/chetan.png')
  }
])