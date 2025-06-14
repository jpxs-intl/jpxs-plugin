---@class ConnectionInterface
---@field connected boolean
---@field connect fun(host: string, port: integer)
---@field connect fun(host: string, path: string)
---@field sendMessage fun(self: ConnectionInterface, message: string)
---@field onMessage fun(self: ConnectionInterface, cb: fun(message: string))
---@field close fun()
