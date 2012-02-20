local json    = require 'dkjson'
local utils   = require 'lem.utils'
local streams = require 'lem.streams'
require 'lem.http'

local server = assert(streams.tcp4_listen('*', 21523))

local format, char, gsub = string.format, string.char, string.gsub
local ipairs, date, tonumber = ipairs, os.date, tonumber

local function log(...)
	print(format('*** %s  %s ***', date('%Y-%m-%d %H:%M:%S'), format(...)))
end

utils.spawn(function() assert(server:autospawn(function(is, os)
	local req, err = is:read('HTTPRequest')
	if not req then
		log('HTTP connection error: %s', err)
		is:close()
		os:close()
		return
	end

	local len, body = tonumber(req.headers['Content-Length']), ''
	if not len or len <= 0 then
		log('No Content-Length')
		is:close()
		os:close()
		return
	end

	body, err = is:read(len)
	is:close()
	os:close()

	if not body then
		log('Error reading body: %s', err)
		return
	end

	body = body:match('payload=([^&]*)')
	if not body then
		log('payload not found in body')
		return
	end

	-- URL decode
	body = gsub(body, "+", " ")
	body = gsub(body, "%%(%x%x)", function(h) return char(tonumber(h, 16)) end)
	body = json.decode(body)
	if not body then
		log('Error decoding JSON')
		return
	end

	local commits = body.commits
	for i = 1, #commits do
		local commit = commits[i]
		local msg = commit.message:match('^([^\r\n]*)')

		say(format('%s pushed to %s: %s',
				commit.author.name, body.repository.name, msg))
	end
end)) end)

-- vim: ts=2 sw=2 noet:
