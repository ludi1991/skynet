local sprotoparser = require "sprotoparser"

local proto = {}

proto.c2s = sprotoparser.parse [[
.package {
	type 0 : integer
	session 1 : integer
}

handshake 1 {
	response {
		msg 0  : string
	}
}

get 2 {
	request {
		what 0 : string
	}
	response {
		result 0 : string
	}
}

set 3 {
	request {
		what 0 : string
		value 1 : string
	}
}

quit 4 {}

getnews 5 {
	response {
        msg 0 : string
    }
}

chat 6 {
	request {
        msg 0 : string 
        name 1 : string
	}
	response {
        result 1 : integer
	}
}

get_player_data 7 {
	request {
        playerid 0: integer
        type 1: string
	}
	response {
        data 0: string
	}
}



get_player_rank 8{
	request {
        playerid 0: integer
    }
    response {
        rank 0: integer
    }
}

login 9 {
    request {
        playerid 0: integer
    }
    response {
        result 0: integer
    }
}


]]

proto.s2c = sprotoparser.parse [[
.package {
	type 0 : integer
	session 1 : integer
}

heartbeat 1 {}

chatting 2 {
	request {
	    name 0 : string
        msg 1 : string
        time 2 : string 
	}
}


]]

return proto
