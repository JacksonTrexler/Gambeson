extends Behaviour

# Spike: a heavy, deliberate blow. The foe adds the AP it left unspent as its side's last turn ended
# (Unit.unspent) to its Defense against it; landing, it deals + rank damage.


func guard(c: Cast) -> int:
	return floori(c.target.unspent) if c.foe else 0


func bonus(c: Cast) -> int:
	return c.rank if c.foe else 0


func describe(rank: int) -> String:
	return "The foe adds the AP it left unspent last turn to its Defense against it. A hit deals {r:%d} more damage" % rank
