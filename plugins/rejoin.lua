KICK(function(msg)
	for _, chan in ipairs(config.channels) do
		if msg[1] == chan and msg[2] == config.nick then
			send('JOIN %s\r\n', chan)
			break
		end
	end
end)

-- vim: ts=2 sw=2 noet:
