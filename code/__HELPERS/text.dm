/*
 * Holds procs designed to help with filtering text
 * Contains groups:
 *			SQL sanitization
 *			Text sanitization
 *			Text searches
 *			Text modification
 *			Misc
 */


/*
 * Text sanitization
 */

//Simply removes < and > and limits the length of the message
/proc/strip_html_simple(var/t,var/limit=MAX_MESSAGE_LEN)
	var/list/strip_chars = list("<",">")
	t = copytext(t,1,limit)
	for(var/char in strip_chars)
		var/index = findtext(t, char)
		while(index)
			t = copytext(t, 1, index) + copytext(t, index+1)
			index = findtext(t, char)
	return t

//Removes a few problematic characters
/proc/sanitize_simple(var/t, var/list/repl_chars = list("\n"=" ","\t"=" ","�"=" "))
	for(var/char in repl_chars)
		t = replacetext(t, char, repl_chars[char])
	return t

/proc/readd_quotes(var/t)
	var/list/repl_chars = list("&#34;" = "\"", "&#39;" = "'")
	for(var/char in repl_chars)
		t = replacetext(t, char, repl_chars[char])
	return t

//Runs byond's sanitization proc along-side sanitize_simple
/proc/sanitize(var/t,var/list/repl_chars = list("\n"=" ","\t"=" ","�"=" "))
	var/msg = html_encode(sanitize_simple(t, repl_chars))
	return readd_quotes(msg)

//Runs sanitize and strip_html_simple
//I believe strip_html_simple() is required to run first to prevent '<' from displaying as '&lt;' after sanitize() calls byond's html_encode()
/proc/strip_html(var/t,var/limit=MAX_MESSAGE_LEN)
	return copytext((sanitize(strip_html_simple(t))),1,limit)

//Runs byond's sanitization proc along-side strip_html_simple
//I believe strip_html_simple() is required to run first to prevent '<' from displaying as '&lt;' that html_encode() would cause
/proc/adminscrub(var/t,var/limit=MAX_MESSAGE_LEN)
	return copytext((html_encode(strip_html_simple(t))),1,limit)


//Returns null if there is any bad text in the string
/proc/reject_bad_text(var/text, var/max_length=512)
	if(length(text) > max_length)	return			//message too long
	var/non_whitespace = 0
	for(var/i=1, i<=length(text), i++)
		switch(text2ascii(text,i))
			if(62,60,92,47)	return			//rejects the text if it contains these bad characters: <, >, \ or /
			if(0 to 31)		return			//more weird stuff
			if(32)			continue		//whitespace
			else			non_whitespace = 1
	if(non_whitespace)		return text		//only accepts the text if it has some non-spaces

// Used to get a sanitized input.
/proc/stripped_input(var/mob/user, var/message = "", var/title = "", var/default = "", var/max_length=MAX_MESSAGE_LEN)
	var/name = input(user, message, title, default) as text|null
	return html_encode(trim(name, max_length))

// Used to get a properly sanitized multiline input, of max_length
/proc/stripped_multiline_input(var/mob/user, var/message = "", var/title = "", var/default = "", var/max_length=MAX_MESSAGE_LEN)
	var/name = input(user, message, title, default) as message|null
	return html_encode(trim(name, max_length))

//Filters out undesirable characters from names
/proc/reject_bad_name(var/t_in, var/allow_numbers = 0, var/max_length = MAX_NAME_LEN, var/allow_signs = TRUE)
	if(!t_in || length(t_in) > max_length)
		return //Rejects the input if it is null or if it is longer then the max length allowed

	var/number_of_alphanumeric	= 0
	var/last_char_group			= 0
	var/t_out = ""

	for(var/i=1, i<=length(t_in), i++)
		var/ascii_char = text2ascii(t_in,i)
		switch(ascii_char)
			// A  .. Z
			if(65 to 90)			//Uppercase Letters
				t_out += ascii2text(ascii_char)
				number_of_alphanumeric++
				last_char_group = 4

			// a  .. z
			if(97 to 122)			//Lowercase Letters
				if(last_char_group<2)
					t_out += ascii2text(ascii_char-32)	//Force uppercase first character
				else
					t_out += ascii2text(ascii_char)
				number_of_alphanumeric++
				last_char_group = 4

			// 0  .. 9
			if(48 to 57)			//Numbers
				if(!last_char_group || !allow_numbers) //suppress at start of string
					continue
				t_out += ascii2text(ascii_char)
				number_of_alphanumeric++
				last_char_group = 3

			// '  -  .
			if(39,45,46)			//Common name punctuation
				if(!last_char_group || !allow_signs)
					continue
				t_out += ascii2text(ascii_char)
				last_char_group = 2

			// ~  |  @  :  #  $  %  &  *  +
			if(126,124,64,58,35,36,37,38,42,43)			//Other symbols that we'll allow (mainly for AI)
				if(!last_char_group || !allow_numbers || !allow_signs) //suppress at start of string
					continue
				t_out += ascii2text(ascii_char)
				last_char_group = 2

			//Space
			if(32)
				if(last_char_group <= 1)
					continue	//suppress double-spaces and spaces at start of string
				t_out += ascii2text(ascii_char)
				last_char_group = 1
			else
				return

	if(number_of_alphanumeric < 2)
		return		//protects against tiny names like "A" and also names like "' ' ' ' ' ' ' '"

	if(last_char_group == 1)
		t_out = copytext(t_out,1,length(t_out))	//removes the last character (in this case a space)

	for(var/bad_name in list("space","floor","wall","r-wall","monkey","unknown","inactive ai"))	//prevents these common metagamey names
		if(cmptext(t_out,bad_name))
			return	//(not case sensitive)

	return t_out

/*
 * Text searches
 */

//Adds 'u' number of zeros ahead of the text 't'
/proc/add_zero(t, u)
	while (length(t) < u)
		t = "0[t]"
	return t

//Adds 'u' number of spaces ahead of the text 't'
/proc/add_lspace(t, u)
	while(length(t) < u)
		t = " [t]"
	return t

//Adds 'u' number of spaces behind the text 't'
/proc/add_tspace(t, u)
	while(length(t) < u)
		t = "[t] "
	return t

//Returns a string with reserved characters and spaces before the first letter removed
/proc/trim_left(text)
	for (var/i in 1 to length(text))
		if (text2ascii(text, i) > 32)
			return copytext(text, i)
	return ""

//Returns a string with reserved characters and spaces after the last letter removed
/proc/trim_right(text)
	for (var/i in length(text) to 1 step -1)
		if (text2ascii(text, i) > 32)
			return copytext(text, 1, i + 1)

	return ""

//Returns a string with reserved characters and spaces before the first word and after the last word removed.
/proc/trim(text)
	return trim_left(trim_right(text))

//Returns a string with the first element of the string capitalized.
/proc/capitalize(var/t as text)
	return r_capitalize(t)

/proc/r_lowertext(text)
	var/t = ""
	for(var/i = 1, i <= length(text), i++)
		var/a = text2ascii(text, i)
		if (a == 1105 || a == 1025)
			t += ascii2text(1105)
			continue
		if (a < 1040 || a > 1071)
			t += ascii2text(a)
			continue
		t += ascii2text(a + 32)
	return lowertext(t)

/proc/r_uppertext(text)
	var/t = ""
	for(var/i = 1, i <= length(text), i++)
		var/a = text2ascii(text, i)
		if (a == 1105 || a == 1025)
			t += ascii2text(1025)
			continue
		if (a < 1072 || a > 1105)
			t += ascii2text(a)
			continue
		t += ascii2text(a - 32)
	return uppertext(t)

/proc/r_capitalize(t as text)
	var/first = ascii2text(text2ascii(t))
	return r_uppertext(first) + copytext(t, length(first) + 1)

/proc/stringpercent(var/text,character = "*")
//This proc returns the number of chars of the string that is the character
//This is used for detective work to determine fingerprint completion.
	if(!text || !character)
		return 0
	var/count = 0
	for(var/i = 1, i <= length(text), i++)
		var/a = copytext(text,i,i+1)
		if(a == character)
			count++
	return count

/proc/reverse_text(var/text = "")
	var/new_text = ""
	for(var/i = length(text); i > 0; i--)
		new_text += copytext(text, i, i+1)
	return new_text

//Used in preferences' SetFlavorText and human's set_flavor verb
//Previews a string of len or less length
proc/TextPreview(var/string,var/len=40)
	if(length(string) <= len)
		if(!length(string))
			return "\[...\]"
		else
			return string
	else
		return "[copytext(string, 1, 37)]..."

proc/strip_improper(input_text)
	return replacetext(replacetext(input_text, "\proper", ""), "\improper", "")

// Used to remove the string shortcuts for a clean transfer
/proc/sanitize_filename(t)
	return sanitize_simple(t, list("\n"="", "\t"="", "/"="", "\\"="", "?"="", "%"="", "*"="", ":"="", "|"="", "\""="", "<"="", ">"=""))

/proc/deep_string_equals(var/A, var/B)
	if(length(A) != length(B))
		return FALSE
	for(var/i = 1 to length(A))
		if (text2ascii(A, i) != text2ascii(B, i))
			return FALSE
	return TRUE

//Used for applying byonds text macros to strings that are loaded at runtime
/proc/apply_text_macros(string)
	var/next_backslash = findtext(string, "\\")
	if(!next_backslash)
		return string

	var/leng = length(string)

	var/next_space = findtext(string, " ", next_backslash + 1)
	if(!next_space)
		next_space = leng - next_backslash

	if(!next_space)	//trailing bs
		return string

	var/base = next_backslash == 1 ? "" : copytext(string, 1, next_backslash)
	var/macro = lowertext(copytext(string, next_backslash + 1, next_space))
	var/rest = next_backslash > leng ? "" : copytext(string, next_space + 1)

	//See http://www.byond.com/docs/ref/info.html#/DM/text/macros
	switch(macro)
		//prefixes/agnostic
		if("the")
			rest = text("\the []", rest)
		if("a")
			rest = text("\a []", rest)
		if("an")
			rest = text("\an []", rest)
		if("proper")
			rest = text("\proper []", rest)
		if("improper")
			rest = text("\improper []", rest)
		if("roman")
			rest = text("\roman []", rest)
		//postfixes
		if("th")
			base = text("[]\th", rest)
		if("s")
			base = text("[]\s", rest)
		if("he")
			base = text("[]\he", rest)
		if("she")
			base = text("[]\she", rest)
		if("his")
			base = text("[]\his", rest)
		if("himself")
			base = text("[]\himself", rest)
		if("herself")
			base = text("[]\herself", rest)
		if("hers")
			base = text("[]\hers", rest)

	. = base
	if(rest)
		. += .(rest)
// Returns the location of the atom as a string in the following format:
// "Area Name (X, Y, Z)"
// Mainly used for logging
/proc/get_location_in_text(atom/A)
	var/message
	if(!A.loc)
		message = "Invalid location"
	else
		message = "[get_area(A)] ([A.x], [A.y], [A.z])"
	return message

//Adds 'char' ahead of 'text' until there are 'count' characters total
/proc/add_leading(text, count, char = " ")
	var/charcount = count - length_char(text)
	var/list/chars_to_add[max(charcount + 1, 0)]
	return jointext(chars_to_add, char) + text

/proc/utf_goon(t)
	t = replacetextEx(t, "", "&#1040;")
	t = replacetextEx(t, "", "&#1041;")
	t = replacetextEx(t, "", "&#1042;")
	t = replacetextEx(t, "", "&#1043;")
	t = replacetextEx(t, "", "&#1044;")
	t = replacetextEx(t, "", "&#1045;")
	t = replacetextEx(t, "", "&#1025;")
	t = replacetextEx(t, "", "&#1046;")
	t = replacetextEx(t, "", "&#1047;")
	t = replacetextEx(t, "", "&#1048;")
	t = replacetextEx(t, "", "&#1049;")
	t = replacetextEx(t, "", "&#1050;")
	t = replacetextEx(t, "", "&#1051;")
	t = replacetextEx(t, "", "&#1052;")
	t = replacetextEx(t, "", "&#1053;")
	t = replacetextEx(t, "", "&#1054;")
	t = replacetextEx(t, "", "&#1055;")
	t = replacetextEx(t, "", "&#1056;")
	t = replacetextEx(t, "", "&#1057;")
	t = replacetextEx(t, "", "&#1058;")
	t = replacetextEx(t, "", "&#1059;")
	t = replacetextEx(t, "", "&#1060;")
	t = replacetextEx(t, "", "&#1061;")
	t = replacetextEx(t, "", "&#1062;")
	t = replacetextEx(t, "", "&#1063;")
	t = replacetextEx(t, "", "&#1064;")
	t = replacetextEx(t, "", "&#1065;")
	t = replacetextEx(t, "", "&#1066;")
	t = replacetextEx(t, "", "&#1067;")
	t = replacetextEx(t, "", "&#1068;")
	t = replacetextEx(t, "", "&#1069;")
	t = replacetextEx(t, "", "&#1070;")
	t = replacetextEx(t, "", "&#1071;")
	t = replacetextEx(t, "", "&#1072;")
	t = replacetextEx(t, "", "&#1073;")
	t = replacetextEx(t, "", "&#1074;")
	t = replacetextEx(t, "", "&#1075;")
	t = replacetextEx(t, "", "&#1076;")
	t = replacetextEx(t, "", "&#1077;")
	t = replacetextEx(t, "", "&#1105;")
	t = replacetextEx(t, "", "&#1078;")
	t = replacetextEx(t, "", "&#1079;")
	t = replacetextEx(t, "", "&#1080;")
	t = replacetextEx(t, "", "&#1081;")
	t = replacetextEx(t, "", "&#1082;")
	t = replacetextEx(t, "", "&#1083;")
	t = replacetextEx(t, "", "&#1084;")
	t = replacetextEx(t, "", "&#1085;")
	t = replacetextEx(t, "", "&#1086;")
	t = replacetextEx(t, "", "&#1087;")
	t = replacetextEx(t, "", "&#1088;")
	t = replacetextEx(t, "", "&#1089;")
	t = replacetextEx(t, "", "&#1090;")
	t = replacetextEx(t, "", "&#1091;")
	t = replacetextEx(t, "", "&#1092;")
	t = replacetextEx(t, "", "&#1093;")
	t = replacetextEx(t, "", "&#1094;")
	t = replacetextEx(t, "", "&#1095;")
	t = replacetextEx(t, "", "&#1096;")
	t = replacetextEx(t, "", "&#1097;")
	t = replacetextEx(t, "", "&#1098;")
	t = replacetextEx(t, "", "&#1099;")
	t = replacetextEx(t, "", "&#1100;")
	t = replacetextEx(t, "", "&#1101;")
	t = replacetextEx(t, "", "&#1102;")
	t = replacetextEx(t, "", "&#1103;")

	t = replacetextEx(t, "&#255;", "&#1103;")

	return t
