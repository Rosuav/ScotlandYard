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

//Find the nth root of a huge number
//Binary searches for the nearest integer between two guesses.
int nthroot(int n,int root)
{
	int guess1=pow(2,n->size(2)/root),guess2=guess1*2;
	while (1)
	{
		int mid=(guess1+guess2)/2;
		if (mid==guess1)
		{
			//Endgame. We have two final guesses, one unit apart.
			//Pick whichever is closer.
			int comp1=abs(n-pow(guess1,root)),comp2=abs(n-pow(guess2,root));
			return comp1<comp2 ? guess1 : guess2;
		}
		int compare=pow(mid,root);
		//If our guess is too high, bring the top down, else bring the bottom up.
		if (compare>n) guess2=mid; else guess1=mid;
	}
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
	mapping(int:mapping(int:int)) distance=([]); //For subsequent calculations: distance[x][y] is the minimum moves to get from x to y.
	array(int) scores=({0})+allocate(max(@indices(destinations)));
	foreach (SortIterator(destinations);int origin;multiset wavefront)
	{
		multiset seen=(<origin>);
		int dist=0; //Distance from origin to just before wavefront
		int score=0;
		mapping(int:int) dst=distance[origin]=([origin:0]);
		while (sizeof(wavefront))
		{
			dist += 1;
			score += dist * sizeof(wavefront);
			seen |= wavefront;
			multiset nextfront=(<>);
			foreach (wavefront;int loc;)
			{
				nextfront |= destinations[loc];
				dst[loc] = dist;
			}
			nextfront -= seen;
			if (!sizeof(nextfront)) break;
			wavefront = nextfront;
		}
		totscore += score; scores[origin] = score;
		if (dist<=6)
			write("%d: Max dist %d, tot score %d\n",origin,dist,score);
		if (score<650)
			write("%d: Tot score %d, max dist %d\n",origin,score,dist);
		if (dist>9)
			write("%d: Max distance %d to reach%{ %d%}\n",origin,dist,sort((array)wavefront));
	}
	write("Score distribution: %d-%d\n",min(@scores[1..]),max(@scores));
	write("Arithmetic average: %d\n",totscore/sizeof(destinations));
	write("Geometic average: %d\n",nthroot(`*(@scores[1..]),sizeof(destinations)));
	//Now for some random fun. These are the starting tiles. How close together can you be?
	array(int) starts=({34,13,29,91,94,53,26,50,155,141,197,103,174,112,138,132,117,198});
	int closest=200;
	foreach (starts,int origin) foreach (starts,int dest) if (origin<dest)
	{
		if (distance[origin][dest]<3) write("Start locations %d and %d are only %d apart\n",origin,dest,distance[origin][dest]);
	}
	//Truly RANDOM random fun! Distribute five detectives around the board, maximizing distances.
	//This tends to push detectives to the outside of the board. This isn't a huge problem (they
	//can simply start moving to more central locations), but if that's undesirable, start with
	//a negation of the 'scores' array instead.
	array(int) detectives=allocate(5);
	//array(int) detdist=({0})+allocate(max(@indices(distance)),1); //Flat start - promotes edge positions
	array(int) detdist=max(@scores)+1-scores[*]; detdist[0]=0; //Weight toward centrality
	foreach (detectives;int det;)
	{
		//Pick a location, using the detdist array as weights
		int rnd=random(Array.sum(detdist));
		foreach (detdist;int pos;int prob) if ((rnd-=prob)<0) {detectives[det]=pos; break;}
		write("Place detective #%d at %d.\n",det+1,detectives[det]);
		//Multiply each location's weight by the distance from it to the new detective.
		//Effectively, the weight of a location is the product of the distances to each
		//detective. Ergo there is zero probability of a collision (because its distance
		//to the previous one is 0), and far FAR higher chance of getting something a
		//long way from anything than of something close to several others (4*4*4 is way
		//higher than 9*2*1).
		foreach (distance[detectives[det]];int pos;int dist) detdist[pos]*=dist;
	}
}
