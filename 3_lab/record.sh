#!/usr/bin/fish
printf "%s\n%s %s\n\n" (git log --format=%s HEAD -n 1) (git rev-parse --short HEAD) (julia --compile=all -O3 graphs.jl | tail -n 1)
