local json    = require 'dkjson'
local utils   = require 'lem.utils'
local streams = require 'lem.streams'
require 'lem.http'

local server = assert(streams.tcp4_listen('*', 21523))

if not config then
	config = {
		channels = { '#labitat' }
	}
end

local format, char, gsub = string.format, string.char, string.gsub
local ipairs, date, tonumber = ipairs, os.date, tonumber

local function log(fmt, ...)
	io.write(format(fmt, ...))
end

utils.spawn(function() assert(server:autospawn(function(is, os)
	local now = date('%Y-%m-%d %H:%M:%S')
	local req, err = is:read('HTTPRequest')
	if not req then
		log('*** %s  HTTP connection error: %s ***\n', now, err)
		is:close()
		os:close()
		return
	end

	local len, body = req.headers['Content-Length'], ''
	if not len then
		log('*** %s  No Content-Length ***\n', now)
		is:close()
		os:close()
		return
	end

	len = tonumber(len)
	if len > 0 then
		local err

		body, err = is:read(len)
		if not body then
			log('*** %s  Error reading body: %s ***\n', now, err)
			is:close()
			os:close()
			return
		end
	end
	is:close()
	os:close()

	body = body:match('payload=([^&]*)')
	if not body then
		log('*** %s  payload not found in body ***\n', now)
		return
	end

	-- URL decode
	body = gsub(body, "+", " ")
	body = gsub(body, "%%(%x%x)", function(h) return char(tonumber(h, 16)) end)
	body = json.decode(body)
	if not body then
		log('*** %s  Error decoding JSON ***\n', now)
		return
	end

	for _, commit in ipairs(body.commits) do
		for _, channel in ipairs(config.channels) do
			local msg = commit.message:match('^([^\r\n]*)')
			send('PRIVMSG %s :%s pushed to %s: %s\r\n',
			     channel, commit.author.name, body.repository.name, msg)
		end
	end
end)) end)

-- vim: ts=2 sw=2 noet:
