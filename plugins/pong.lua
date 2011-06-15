PING(function(msg)
	send('PONG :%s\r\n', msg[1])
end)

-- vim: ts=2 sw=2 noet:
