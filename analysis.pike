class SortIterator(mixed base, int|void valueorder)
{
	array(mixed) i, v;
	int pos = 0, top;
	void create()
	{
		i = indices(base); v = values(base); top = sizeof(base);
		if (valueorder) sort(v, i); else sort(i, v);
	}

	bool first() {pos = 0; return top > 0;}
	int next() {return ++pos < top;}
	mixed index() {return pos < top ? i[pos] : UNDEFINED;}
	mixed value() {return pos < top ? v[pos] : UNDEFINED;}
	int _sizeof() {return top;}
	bool `!() {return pos >= top;}
	this_program `+(int steps)
	{
		this_program clone = this_program(([]));
		clone->i = i; clone->v = v; clone->top = top;
		//Can push pos past top - I don't care. Cannot push pos below zero though.
		clone->pos = pos + max(steps, -pos);
	}
	this_program `-(int steps) {return this + (-steps);}
	this_program `+=(int steps) {pos += max(steps, -pos); return this;}
}

int main()
{
	//Step 1: Parse the data file
	array stuff=array_sscanf((String.trim_all_whites(Stdio.read_file("connections.txt"))/"\n")[*],"%d%{ %[rbt0-9]%}");
	//Step 2: Basic sanity checks
	mapping(int:multiset(int)) destinations=([]);
	foreach (stuff;int i;[int idx,array conn])
	{
		if (idx!=i+1) exit(1,"Error in %d - s/be idx %d\n",idx,i+1);
		multiset dests=destinations[idx]=(<>);
		foreach (conn,[string c])
		{
			int dest=(int)c[1..];
			if (dest==idx) exit(1,"Loopback in %d\n",idx);
			if (!has_value(stuff[dest-1][1]*({ }),sprintf("%c%d",c[0],idx))) write("Non-returning connection from %d to %s\n",idx,c);
			dests[dest]=1;
		}
		//Note that sizeof(conn) and sizeof(dests) may not match, due to multi-modal connections
		//to the same destination (usually bus and taxi). This may be of some interest.
	}
	//Step 3: Analysis!
	int totscore=0;
	foreach (SortIterator(destinations);int origin;multiset wavefront)
	{
		multiset seen=(<origin>);
		int dist=0; //Distance from origin to just before wavefront
		int score=0;
		while (sizeof(wavefront))
		{
			dist += 1;
			score += dist * sizeof(wavefront);
			seen |= wavefront;
			multiset nextfront=(<>);
			foreach (wavefront;int loc;) nextfront |= destinations[loc];
			nextfront -= seen;
			if (!sizeof(nextfront)) break;
			wavefront = nextfront;
		}
		totscore += score;
		if (dist<=6)
			write("%d: Max dist %d, tot score %d\n",origin,dist,score);
		if (score<650)
			write("%d: Tot score %d, max dist %d\n",origin,score,dist);
		if (dist>9)
			write("%d: Max distance %d to reach%{ %d%}\n",origin,dist,sort((array)wavefront));
	}
	write("Average score: %d\n",totscore/sizeof(destinations));
}
