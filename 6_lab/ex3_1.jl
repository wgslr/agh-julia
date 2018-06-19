version=1
maxworkers=2 * nprocs()
workers=nprocs()
stripes=1
timefile="times.csv"

using Plots
Plots.gr()

function generate_julia(z; c=2, maxiter=200)
    for i=1:maxiter
        if abs(z) > 2
            return i-1
        end
        z = z^2 + c
    end
    maxiter
end

function calc_julia!(julia_set, xrange, yrange; maxiter=200, height=400, width_start=1, width_end=400)
   for x=width_start:width_end
        for y=1:height
            z = xrange[x] + 1im*yrange[y]
            julia_set[x, y] = generate_julia(z, c=-0.70176-0.3842im, maxiter=maxiter)
        end
    end
    julia_set[width_start:width_end, :]
end


function calc_julia_main(h,w, stripes, workers)
   xmin, xmax = -2,2
   ymin, ymax = -1,1
   xrange = linspace(xmin, xmax, w)
   yrange = linspace(ymin, ymax, h)
   julia_set = Array{Int64}((w, h))

    jobs = []
    prev_end = 0
    togen = stripes
    while(togen > 0)
        local_w = div((w - prev_end), togen)
        start = prev_end + 1
        push!(jobs, (start, start + local_w - 1))
        prev_end = start + local_w - 1
        togen = togen - 1
    end

    tic()
    data = @parallel (vcat) for (s, e) = jobs
        calc_julia!(julia_set, xrange, yrange, height=h, width_start=s, width_end=e)
    end
    secs = toq()

   println("$version,$workers,$stripes,$secs,$h,$w")
   fd = Base.open(timefile, "a")
   write(fd, "$version,$workers,$stripes,$secs,$h,$w\n")
   close(fd)
   

   Plots.heatmap(xrange, yrange, data)
   png("julia")
end


function time_julia(width=4000, height=4000)
    for i in nprocs():nprocs()
        workers = i
        stripes = workers
        while stripes <= width
            println("workers $workers, stripes $stripes")
            calc_julia_main(height, width, stripes, workers)
            stripes = stripes * 2
        end
    end
end
