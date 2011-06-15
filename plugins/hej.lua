PRIVMSG(function(msg)
	if msg.nick == config.nick then return end

	if msg[1] == config.nick then
		return send('PRIVMSG %s :Hej %s\r\n', msg.nick, msg.nick)
	end

	if msg[2]:match('^[Hh][Ee][Jj] [Aa][Nn][Nn][Aa]$') or
	   msg[2]:match('^[Hh][Ee][Jj] [Aa][Nn][Nn][Aa][ %.,]') then
		send('PRIVMSG %s :Hej %s\r\n', msg[1], msg.nick)
	end
end)

-- vim: ts=2 sw=2 noet:
