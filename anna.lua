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
local ssl      = require 'lem.ssl'
local ircparse = require 'ircparse'

config = {
	nick = 'Anna',
	description = 'A chatbot..',
	server = 'labitat.dk',
	port = 6697,
	channels = { '#bottest' },
	--channels = { '#labitat' },
}

local context = assert(ssl.newcontext())
local conn = assert(context:connect(config.server, config.port))

local mainloop
do
	local actions = {}

	for _, cmd in ipairs{
			'PING', 'KICK', 'PRIVMSG'} do
		_G[cmd] = function(f)
			local list = actions[cmd]
			if list == nil then
				actions[cmd] = { f }
			else
				list[#list + 1] = f
			end
		end
	end

	local format = string.format
	local queue, first, last = {}, 0, 0

	function send(fmt, ...)
		last = last + 1
		queue[last] = format(fmt, ...)

		if last == 1 and conn:busy() then
			conn:interrupt()
		end
	end

	function mainloop()
		while true do
			while first < last do
				first = first + 1
				assert(conn:write(queue[first]))
				queue[first] = nil
			end

			first, last = 0, 0

			local line, err = conn:read('*l')
			if line then
				io.write(line)

				local msg, err = ircparse(line)
				if not msg then
					print(format('Error parsing %q', line))
				else
					local list = actions[msg.command]
					if list then
						for i = 1, #list do
							list[i](msg)
						end
					end
				end
			elseif err ~= 'interrupted' then
				print(err)
				break
			end
		end
	end
end

for plugin in assert(io.popen('dir -1 plugins')):lines() do
	assert(loadfile('plugins/'..plugin))()
end

send('NICK %s\r\n', config.nick)
send('USER %s 0 * :%s\r\n', config.nick, config.description)
for _, chan in ipairs(config.channels) do
	send('JOIN %s\r\n', chan)
end

utils.spawn(function()
	local stdin = streams.stdin

	while true do
		local line = assert(stdin:read('*l'))
		send('PRIVMSG %s :%s\r\n', config.channels[1], line:sub(1, -2))
	end
end)

mainloop()

-- vim: ts=2 sw=2 noet:
