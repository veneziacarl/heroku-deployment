require "sinatra"
require "pg"

def db_connection
  begin
    connection = PG.connect(dbname: "restaurants")
    yield(connection)
  ensure
    connection.close
  end
end

def exec_query(sql, values = [])
  result = nil
  begin
    db_connection do |connection|
      result = connection.exec(sql, values).to_a
    end
  rescue PG::Error => err
    puts "server.rb: error executing SQL statement"
    puts "\tsql: '#{sql}'"
    puts "\tvalues: #{values}"
    puts "\terror: #{err}"
  end
  result
end

helpers do
  # https://www.google.com/maps/search/restaurant_name+city+state
  def gmaps_url(restaurant)
    query = [restaurant["name"], restaurant["city"], restaurant["state"]].join("+")
    "https://www.google.com/maps/search/#{URI.encode(query)}"
  end
end

get "/" do
  redirect to("/restaurants/random")
end

get "/restaurants/random" do
  sql = <<-SQL
    SELECT * FROM restaurants
      ORDER BY RANDOM()
      LIMIT 1;
  SQL
  restaurant = exec_query(sql).first
  erb :"restaurants/show", locals: { restaurant: restaurant }
end

get "/restaurants/new" do
  erb :"restaurants/new"
end

get "/restaurants/:id" do |id|
  sql = "SELECT * FROM restaurants WHERE id = $1;"
  restaurant = exec_query(sql, [id]).first
  erb :"restaurants/show", locals: { restaurant: restaurant }
end

post "/restaurants" do
  sql = <<-SQL
    INSERT INTO restaurants(name, address, city, state, zip, description)
      VALUES($1, $2, $3, $4, $5, $6)
      RETURNING id;
  SQL
  values = [
    params["name"],
    params["address"],
    params["city"],
    params["state"],
    params["zip"],
    params["description"]
  ]
  result = exec_query(sql, values)
  restaurant_id = result.first["id"]

  if restaurant_id
    redirect to("/restaurants/#{restaurant_id}")
  else
    redirect to("/restaurants/random")
  end
end
