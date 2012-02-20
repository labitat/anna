ANSWER(function(msg)
	if msg:match('[Hh][Ee][Jj]') then
		return 'Hej'
	elseif msg:match('[Hh][Ee][Ll][Ll][Oo]') then
		return 'Hello'
	end
end)

-- vim: ts=2 sw=2 noet:
