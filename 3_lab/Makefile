
record:
	git stash; fish -c 'printf "%s\n%s %s\n" (git log --format=%s HEAD -n 1) (git rev-parse --short HEAD) (julia --compile=all -O3 graphs.jl) >> times.txt;'; git stash pop

test:
	julia --compile=all -O3 graphs.jl
