
record:
	fish -c 'printf "%s %s\n" (git rev-parse --short HEAD) (julia graphs.jl) >> times.txt;'
