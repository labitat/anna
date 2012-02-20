local utils   = require 'lem.utils'
local streams = require 'lem.streams'
require 'lem.http'

local format, tonumber = string.format, tonumber

ANSWER(function(msg)
	if not msg:match('[Ss][Tt][Rr]..?[Mm]') then return end

	local iconn, oconn = streams.tcp_connect('space.labitat.dk', 8080)
	if not iconn then return oconn end

	local ok, err = oconn:write('GET /last HTTP/1.1\r\nHost: space.labitat.dk\r\nConnection: close\r\n\r\n')
	if not ok then return err end

	local res, err = iconn:read('HTTPResponse')
	if not res then return err end

	local body, err = res:body()
	if not body then return err end

	local ms = body:match('%[%d+,(%d+)%]')
	if not ms then return 'received unexpected answer from server' end

	return format('%dW', 3600000 / tonumber(ms))
end)

-- vim: ts=2 sw=2 noet:
