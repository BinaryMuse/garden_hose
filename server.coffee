http = require 'http'
fs = require 'fs'
toml = require 'toml'
express = require 'express'
sio = require 'socket.io'
providers = require './providers'

# Configuration
if !process.env.NODE_ENV?
  console.warn "*********************************************************"
  console.warn "WARNING: Starting in fake mode since no NODE_ENV was set."
  console.warn "*********************************************************\n"
  process.env.NODE_ENV = 'fake'

config = fs.readFileSync('./config/config.toml')
config = toml.parse(config)
config = config[process.env.NODE_ENV]
console.log(config)

app = express()
server = http.createServer(app)
io = sio.listen(server)

provider = new providers[config.type](config.config)
provider.on 'activity', (item) ->
  io.sockets.emit 'activity', item

app.configure ->
  app.set 'port', process.env.PORT || 3000
  app.use express.favicon()
  app.use express.logger()
  app.use express.static("#{__dirname}/public")

app.get '/', (req, res) ->
  res.sendfile "#{__dirname}/public/index.htm"

server.listen app.get('port'), ->
  console.log "Server listening on #{app.get('port')}"
