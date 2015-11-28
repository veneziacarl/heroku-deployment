require 'csv'
require 'pg'

if ENV["RACK_ENV"] == "production"
  uri = URI.parse(ENV["DATABASE_URL"])
  DB_CONFIG = {
    host: uri.host,
    port: uri.port,
    dbname: uri.path.delete('/'),
    user: uri.user,
    password: uri.password
  }
else
  DB_CONFIG = { dbname: "restaurants" }
end

def db_connection
  begin
    connection = PG.connect(DB_CONFIG)
    yield(connection)
  ensure
    connection.close
  end
end

db_connection do |conn|
  sql_query = "DELETE FROM restaurants"
  conn.exec(sql_query)
end

CSV.foreach('restaurants.csv', headers: true, col_sep: ";") do |row|
  db_connection do |conn|
    sql_query = "INSERT INTO restaurants(name, address, city, state, zip, description) VALUES ($1, $2, $3, $4, $5, $6)"
    data = row.to_hash.values
    conn.exec_params(sql_query, data)
  end
end

