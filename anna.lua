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
local bqueue   = require 'bqueue'

config = {
	nick = 'Anna',
	description = 'A chatbot..',
	server = 'labitat.dk',
	port = 6697,
	channels = { '#bottest' },
	--channels = { '#labitat', '#bottest' },
}

local context = assert(ssl.newcontext())

local send
do
	local format = string.format
	local match, mme = string.match, format('^%s[:, ]([^\r\n]+)', config.nick)
	local is, os = assert(context:connect(config.server, config.port))
	os = queue.wrap(os)

	function send(...)
		return os:write(format(...))
	end

	do
		local channels = config.channels
		function say(...)
			local msg = format(...)
			for i = 1, #channels do
				os:write(format('PRIVMSG %s :%s\r\n', channels[i], msg))
			end
		end
	end

	local plugins, n = {}, 0
	function ANSWER(handler)
		local queue = bqueue.new()
		n = n + 1
		plugins[n] = queue
		utils.spawn(function(queue)
			while true do
				local msg = queue:get()
				local reply = handler(msg[1])
				if reply then
					local nick, chan = msg[2], msg[3]
					if chan then
						send('PRIVMSG %s :%s: %s\r\n', chan, nick, reply)
					else
						send('PRIVMSG %s :%s\r\n', nick, reply)
					end
				end
			end
		end, queue)
	end

	local function notify_listeners(msg)
		for i = 1, n do
			 plugins[i]:put(msg)
		end
	end

	local actions = {
		PING = function(msg)
			send('PONG :%s\r\n', msg[1])
		end,
		KICK = function(msg)
			send('JOIN %s\r\n', msg[1])
		end,
		PRIVMSG = function(msg)
			local nick = msg.nick
			if not nick or nick == config.nick then return end
			if msg[1] == config.nick then
				return notify_listeners{ msg[2], nick }
			end

			local str = match(msg[2], mme)
			if str then
				return notify_listeners{ str, nick, msg[1] }
			end
		end,
	}

	utils.spawn(function()
		while true do
			local line, err = is:read('*l')
			if not line then
				print(err)
				break
			end

			local msg, err = ircparse(line)
			if not msg then
				print(format("Error parsing '%s': %s", line, err))
			else
				print(line)
				local handler = actions[msg.command]
				if handler then
					handler(msg)
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

say('Hello!')

local stdin = streams.stdin
while true do
	local line = assert(stdin:read('*l'))
	send('PRIVMSG %s :%s\r\n', config.channels[1], line)
end

-- vim: ts=2 sw=2 noet:
