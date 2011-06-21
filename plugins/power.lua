local utils   = require 'lem.utils'
local streams = require 'lem.streams'
local format  = string.format

local function get_power(cont)
	local conn, err = streams.tcp_connect('space.labitat.dk', 8080)
	if not conn then return cont(err) end

	local ok, err = conn:write('GET /last HTTP/1.1\r\nHost: space.labitat.dk\r\nConnection: close\r\n\r\n')
	if not ok then return cont(err) end

	local res, err = conn:read('*a')
	if not res then return cont(err) end

	local ms = res:match('\r\n\r\n%[%d+,(%d+)%]')
	if not ms then cont('received unexpected answer from server') end

	return cont(format('%dW', 3600000 / tonumber(ms)))
end

PRIVMSG(function(msg)
	if msg.nick == config.nick then return end
	if not msg[2]:match('[Ss][Tt][Rr]..?[Mm]') then return end

	if msg[1] == config.nick then
		return utils.spawn(get_power, function(reply)
			send('PRIVMSG %s :%s\r\n', msg.nick, reply)
		end)
	end

	if msg[2]:match(format('^%s[:, ]', config.nick)) then
		return utils.spawn(get_power, function(reply)
			send('PRIVMSG %s :%s: %s\r\n', msg[1], msg.nick, reply)
		end)
	end
end)

-- vim: ts=2 sw=2 noet:
