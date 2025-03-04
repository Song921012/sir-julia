
using MeasureTheory
import Distributions
using Plots
using Random
using BenchmarkTools


@inline function rate_to_proportion(r::Float64,t::Float64)
    1-exp(-r*t)
end;


function sir_markov!(x, state, p)
    (β,c,γ,δt) = p

    @inbounds begin
        state[1] -= x[1]
        state[2] += x[1]
        state[2] -= x[2]
        state[3] += x[2]
    end

    S, I, R = state
    N = S+I+R

    si_prob = rate_to_proportion(β*c*I/N, δt)
    ir_prob = rate_to_proportion(γ, δt)
    si_rv = MeasureTheory.Binomial(S, si_prob)
    ir_rv = MeasureTheory.Binomial(I, ir_prob)
    
    productmeasure([si_rv, ir_rv])
end


tmax = 40.0
tspan = (0.0,tmax);


δt = 0.1
t = 0:δt:tmax;
nsteps = Int(tmax / δt);


u0 = [990,10,0]; # S,I,R


p = [0.05,10.0,0.25,δt]; # β,c,γ,δt


Random.seed!(1234);


state = deepcopy(u0);


mc = Chain(x -> sir_markov!(x, state, p), productmeasure([Dirac(0), Dirac(0)]))
r = rand(mc)
samp = Iterators.take(r, nsteps)
sir_trace = collect(samp)
sir_trace = transpose(hcat(sir_trace...))


sir_out = zeros(Int, nsteps+1, 3)
sir_out[1,:] = u0
for i in 2:nsteps+1
    sir_out[i,:] = sir_out[i-1,:] 
    sir_out[i,1] -= sir_trace[i-1,1]
    sir_out[i,2] += sir_trace[i-1,1]
    sir_out[i,2] -= sir_trace[i-1,2]
    sir_out[i,3] += sir_trace[i-1,2]
end


plot(
    t,
    sir_out,
    label=["S" "I" "R"],
    xlabel="Time",
    ylabel="Number"
)


@benchmark begin
    state = deepcopy(u0);
    mc = Chain(x -> sir_markov!(x, state, p), productmeasure([Dirac(0), Dirac(0)]))
    r = rand(mc)
    Iterators.take(r, nsteps)
end

