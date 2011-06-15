local utils   = require 'lem.utils'
local streams = require 'lem.streams'
local format  = string.format

local function get_power(cont)
	local conn = assert(streams.tcp_connect('space.labitat.dk', 8080))

	assert(conn:write('GET /last HTTP/1.1\r\nHost: space.labitat.dk\r\nConnection: close\r\n\r\n'))

	local res = assert(conn:read('*a'))
	--print(res)

	local ms = res:match('\r\n\r\n%[%d+,(%d+)%]')
	return cont(3600000 / tonumber(ms))
end

PRIVMSG(function(msg)
	if msg.nick == config.nick then return end
	if not msg[2]:match('[Ss][Tt][Rr]..?[Mm]') then return end

	if msg[1] == config.nick then
		return utils.spawn(get_power, function(watt)
			send('PRIVMSG %s :%dW\r\n', msg.nick, watt)
		end)
	end

	if msg[2]:match(format('^%s[:, ]', config.nick)) then
		return utils.spawn(get_power, function(watt)
			send('PRIVMSG %s :%s: %dW\r\n', msg[1], msg.nick, watt)
		end)
	end
end)

-- vim: ts=2 sw=2 noet:
