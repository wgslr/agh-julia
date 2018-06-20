version=2
maxworkers=length(workers())
# workers=nprocs()
stripes=1
timefile="times.csv"

allworkers = workers


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

function be_worker(jobs_chnl, results_chnl, julia_set, xrange, yrange, h)
    println("worker function spawned")
    while true
        (s, e) =  take!(jobs_chnl)
        put!(results_chnl, calc_julia!(julia_set, xrange, yrange, height=h, width_start=s, width_end=e))
    end
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

    lens = map(bounds -> bounds[2] - bounds[1] + 1, jobs)
    avgwidth = sum(lens)/length(lens)
    println("Average stripe has $avgwidth columns")

    tic()

    const jobs_chnl = RemoteChannel(() -> Channel{Tuple}(10000), 1)
    const results_chnl = RemoteChannel(() -> Channel{Array{Int64}}(10000), 1)


    foreach(worker -> remote_do(be_worker, worker, jobs_chnl, results_chnl, julia_set, xrange, yrange, h), allworkers()[1:workers])
    foreach(j -> put!(jobs_chnl, j), jobs)
    close(jobs_chnl)

    data = Array{Int64}((0,h))

    for _ in 1:stripes
        data = vcat(data, take!(results_chnl))
    end

    # data = pmap(job -> begin
    #     (s, e) = job
    #     calc_julia!(julia_set, xrange, yrange, height=h, width_start=s, width_end=e)
    # end, jobs)
    # data=reduce(vcat, Array{Int64}((0,h)), data)

    secs = toq()

   println("$version,$workers,$stripes,$secs,$h,$w")
   fd = Base.open(timefile, "a")
#    write(fd, "$version,$workers,$stripes,$secs,$h,$w\n")
   close(fd)
   

   println("Generating heatmap")
   Plots.heatmap(xrange, yrange, data)
   println("Writing png")
   png("julia")
end


function time_julia(width=4000, height=4000)
    for i in 1:maxworkers
        workers = i
        stripes = workers
        while stripes <= width
            println("workers $workers, stripes $stripes")
            calc_julia_main(height, width, stripes, workers)
            stripes = stripes * 2
        end
        println("workers $workers, stripes $width")
        calc_julia_main(height, width, width, workers)
    end
end
