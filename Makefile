
record:
	git stash; fish -c 'printf "%s %s\n" (git rev-parse --short HEAD) (julia --compile=all -O3 graphs.jl) >> times.txt;'; git stash pop
