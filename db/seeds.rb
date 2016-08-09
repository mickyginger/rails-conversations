["users", "conversations", "messages"].each do |table_name|
  ActiveRecord::Base.connection.execute("TRUNCATE #{table_name} RESTART IDENTITY CASCADE")
end

User.create([
  {
    username: "mickyginger",
    email: "mike.hayden@ga.co",
    password: "password",
    password_confirmation: "password",
    image: File.open(Rails.root.join 'db/images/mike.png'),
    name: "Mike Hayden"
  },{
    username: "julesjam",
    email: "jules@ga.co",
    password: "password",
    password_confirmation: "password",
    image: File.open(Rails.root.join 'db/images/jules.jpg'),
    name: "Jules Wyatt"
  },{
    username: "jasonlai",
    email: "jason@ga.co",
    password: "password",
    password_confirmation: "password",
    image: File.open(Rails.root.join 'db/images/jason.jpg'),
    name: "Jason Lai"
  },{
    username: "steadyx",
    email: "ed@ga.co",
    password: "password",
    password_confirmation: "password",
    image: File.open(Rails.root.join 'db/images/ed.jpg'),
    name: "Edward Kemp"
  },{
    username: "willcook",
    email: "will@ga.co",
    password: "password",
    password_confirmation: "password",
    image: File.open(Rails.root.join 'db/images/will.jpg'),
    name: "Will Cook"
  },{
    username: "toni155",
    email: "toni@ga.co",
    password: "password",
    password_confirmation: "password",
    image: File.open(Rails.root.join 'db/images/toni.jpg'),
    name: "Antonio Rossi"
  },{
    username: "chetanbarot",
    email: "chetan@ga.co",
    password: "password",
    password_confirmation: "password",
    image: File.open(Rails.root.join 'db/images/chetan.png'),
    name: "Chetan Barot"
  }
])