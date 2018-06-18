using DifferentialEquations
using DataFrames
using RecursiveArrayTools
using CSV

function solve_lotka(A::Float64, B::Float64, C::Float64, D::Float64, u)
    println("Solving...")
    function equation(du, u, p, t)
        du[1] = A * u[1] - B * u[1] * u[2]
        du[2] = -C * u[2] + D * u[1] * u[2]
    end
    tspan=(0.0, 20.0)
    problem = ODEProblem(equation, u, tspan)
    solve(problem, RK4(), dt=0.01)
end

function write_result(experiment::String, result) 
    filename = "out/$experiment.csv"

    # split results vector
    xy = convert(Array, VectorOfArray(result.u))
    df = DataFrame(t = result.t, x = xy[1, :], y = xy[2, :], exp = experiment)

    CSV.write(filename, df)
    println("Saved results to ", filename)
end

function write_info(experiment::String, params)
    filename = "out/info-$experiment.csv"

    CSV.write(filename,
        DataFrame(exp = experiment, a = params[1], b = params[2], c = params[3],
                  d = params[4], x0 = params[5], y0 = params[6]))
end

function generate_name(A, B, C, D, u)
    "exp-$A-$B-$C-$D-$u"
end

experiment = ARGS[1]
params = map(x -> parse(Float64, x), ARGS[2:7])

result = solve_lotka(params[1:4]..., params[5:6])
write_result(experiment, result)
write_info(experiment, params)