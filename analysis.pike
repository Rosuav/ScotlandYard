int main()
{
	//Step 1: Parse the data file
	array stuff=array_sscanf((String.trim_all_whites(Stdio.read_file("connections.txt"))/"\n")[*],"%d%{ %[rbt0-9]%}");
	//Step 2: Basic sanity checks
	foreach (stuff;int i;[int idx,array conn])
	{
		if (idx!=i+1) exit(1,"Error in %d - s/be idx %d\n",idx,i+1);
		foreach (conn,[string c])
		{
			int dest=(int)c[1..];
			if (dest==idx) exit(1,"Loopback in %d\n",idx);
			if (!has_value(stuff[dest-1][1]*({ }),sprintf("%c%d",c[0],idx))) write("Non-returning connection from %d to %s\n",idx,c);
		}
	}
	write("%O\n",stuff);
}
