#!/usr/bin/env lem
--
-- This file is part of anna.
-- Copyright 2011 Emil Renner Berthing
--
-- anna is free software: you can redistribute it and/or
-- modify it under the terms of the GNU General Public License as
-- published by the Free Software Foundation, either version 3 of
-- the License, or (at your option) any later version.
--
-- anna is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with anna.  If not, see <http://www.gnu.org/licenses/>.
--

local utils    = require 'lem.utils'
local streams  = require 'lem.streams'
local queue    = require 'lem.streams.queue'
local ssl      = require 'lem.ssl'
local ircparse = require 'ircparse'

config = {
	nick = 'Anna',
	description = 'A chatbot..',
	server = 'labitat.dk',
	port = 6697,
	channels = { '#bottest' },
	--channels = { '#labitat', '#bottest' },
}

local context = assert(ssl.newcontext())

do
	local iconn, oconn = assert(context:connect(config.server, config.port))
	local actions = {}

	for _, cmd in ipairs{'PING', 'KICK', 'PRIVMSG'} do
		_ENV[cmd] = function(f)
			local list = actions[cmd]
			if list == nil then
				actions[cmd] = { f }
			else
				list[#list + 1] = f
			end
		end
	end

	local format = string.format

	oconn = queue.wrap(oconn)

	function send(...)
		return oconn:write(format(...))
	end

	utils.spawn(function()
		while true do
			local line, err = iconn:read('*l')
			if not line then
				print(err)
				break
			end

			print(line)

			local msg, err = ircparse(line)
			if not msg then
				print(format("Error parsing '%s'", line))
			else
				local list = actions[msg.command]
				if list then
					for i = 1, #list do
						list[i](msg)
					end
				end
			end
		end
	end)
end

for plugin in assert(io.popen('dir -1 plugins')):lines() do
	io.write('Loading ', plugin, '...')
	io.flush()
	assert(loadfile('plugins/'..plugin))()
	print('done')
end

send('NICK %s\r\n', config.nick)
send('USER %s 0 * :%s\r\n', config.nick, config.description)
utils.sleeper():sleep(2)
for _, chan in ipairs(config.channels) do
	print(("Trying to join %s"):format(chan))
	send('JOIN %s\r\n', chan)
end

local stdin = streams.stdin

while true do
	local line = assert(stdin:read('*l'))
	send('PRIVMSG %s :%s\r\n', config.channels[1], line)
end

-- vim: ts=2 sw=2 noet:
