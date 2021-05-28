### A Pluto.jl notebook ###
# v0.14.3

using Markdown
using InteractiveUtils

# This Pluto notebook uses @bind for interactivity. When running this notebook outside of Pluto, the following 'mock version' of @bind gives bound variables a default value (instead of an error).
macro bind(def, element)
    quote
        local el = $(esc(element))
        global $(esc(def)) = Core.applicable(Base.get, el) ? Base.get(el) : missing
        el
    end
end

# ╔═╡ 9e79889a-9baf-11eb-1e2d-59906f90ea82
begin
    import Pkg
    Pkg.activate("..")

    try
		using CSV, DataFrames, Distributions, Plots, StatsPlots, PlutoUI, Optim
	catch
		Pkg.instantiate()
		using CSV, DataFrames, Distributions, Plots, StatsPlots, PlutoUI, Optim
	end
end

# ╔═╡ 2337edd6-894c-442d-bdf3-d1b9775dce4b
md"""
Goal: model of semantic judgements. For now, I focus on "expensive couch".
"""

# ╔═╡ 8332538e-a06a-415b-8fc1-45e44c5c6a1a
md"""
## Data import
"""

# ╔═╡ 9ebd6e50-cce7-40c8-80b6-5d0785127687
paths = Dict(
	"stimuli" => "../experiment/acceptability_with_semantic/materials/stimuli_data.csv",
	"results" => "../experiment/acceptability_with_semantic/results/results_filtered.csv"
)

# ╔═╡ 56e46a90-adc7-4967-aa50-441dea17d511
stimuli_data = CSV.read(paths["stimuli"], DataFrame)

# ╔═╡ 10898ea6-0ebb-4e37-9171-d1bfdb2cc932
md"""
## Prior distribution
"""

# ╔═╡ fe1ed26e-42bf-4178-89e4-bef0f4e0c240
couch_prices = let
	sample = filter(stimuli_data) do row
		(row.scenario == "couch") && row.bimodal
		#filter on one condition to prevent duplicates
		#set of prices is the same for both conditions
	end
	
	sample.price
end

# ╔═╡ 252f4a66-37e7-4ffa-9429-a407af3a9345
couch_price_scale_points = 0:50:1500

# ╔═╡ 4387731e-0866-425c-aee7-a83b7ca729d5
fitted_prior_couch_price = fit(Normal, couch_prices)

# ╔═╡ fcd71c2c-e685-449d-bf0d-563d28b4a5b9
couch_price_prior_values = let
	scale = [couch_price_scale_points ;
		couch_price_scale_points.stop + couch_price_scale_points.step ]
	densities = pdf.(fitted_prior_couch_price, scale)
	densities / sum(densities)
end

# ╔═╡ 460e3cdb-e248-4c2b-a921-8cab93dadd6d
function couch_price_density(x)
	Δ = (x - couch_price_scale_points.start)
	i = 1 + (Int ∘ floor)(Δ / couch_price_scale_points.step)
	
	couch_price_prior_values[i]
end

# ╔═╡ 60b27cb6-6aa1-4a92-a4be-42ecd805ef79
couch_price_cumulative_values = map(1:length(couch_price_prior_values)) do i
	sum(couch_price_prior_values[1:i])
end

# ╔═╡ 1a71c080-a430-4028-b738-8ca7183f6369
function couch_price_cumulative(x)
	Δ = (x - couch_price_scale_points.start)
	i = 1 + (Int ∘ floor)(Δ / couch_price_scale_points.step)
	
	couch_price_cumulative_values[i]
end

# ╔═╡ f93afb34-6e01-49bc-843a-0eac76bf8b13
function plot_couch_prior()
	plot(
		couch_price_scale_points,
		couch_price_density,
		fill = 0, fillalpha = 0.5,
		label = "prior probability",
		ylabel = "P",
		xlabel = "price (\$)",
	)
end

# ╔═╡ 44d33712-d590-423b-b75c-a281dcb27ae9
let	
	p1 = histogram(
		couch_prices, 
		normalize = true,
		bins = couch_price_scale_points,
		legend = :none,
		ylabel = "N",
		xlabel = "price (\$)",
		title = "Couch prices in sample"
	)
	
	p2 = plot_couch_prior()
	plot!(p2, title = "Estimated distribution of couch prices", legend = :none)
	
	plot(p1, p2, layout = (2,1))
end

# ╔═╡ ad926740-e511-4bf7-a76f-eb1ed1f33e4b
md"""
## Model

### Literal listener
"""

# ╔═╡ 3296d398-5e9b-4afb-a0c7-e8fc7d980548
md"""
The literal listener model estimates the probability that the degree (i.e. price/size) of an object is equal to $x$ given a message like *"It's an expensive couch"*.

The distribution of couch prices defines the prior belief that the price could be $x$, i.e. $P(x)$

The adjective *"expensive"* is interpreted to indicate that $x$ is above a threshold $\theta$. So we estimate the posterior belief

$P(x | x > \theta)$

$\geq$

This is calculated as follows

$L_0(x | x > \theta) = \cases{
	\frac{P(x)}{\int_\theta^{max} P(x)} & if \(x \geq θ\) \\ 
	0 &if \(x < θ\)
}$

"""

# ╔═╡ 564a20ee-5f1a-42ee-8177-6184989bea76
function literal_listener(x, θ, densityf, cumulativef)	
	if x >= θ
		densityf(x) / (1 - cumulativef(θ))
	else
		0
	end
end

# ╔═╡ 770e7e10-ceff-4bb7-93f5-b13ba722a7ce
md"""
Plot for the literal listener model. The plot takes the threshold $\theta$ as a parameter.
"""

# ╔═╡ 83bbf10c-c616-4982-a3dc-9f8773aadbe5
function plot_literal_listener(θ)
	p = plot_couch_prior()
	
	plot!(p,
		couch_price_scale_points,
		x -> literal_listener(x, θ, couch_price_density, couch_price_cumulative),
		fill = 0, fillalpha = 0.5,
		label = "literal listener"
	)
end

# ╔═╡ b7ecc372-66d2-437a-b832-304df70dfab5
@bind ll_example_θ Slider(couch_price_scale_points)

# ╔═╡ de2bdadc-0ab9-4cc4-9d1a-2aa040ab4c7a
md"""
Threshold: $(ll_example_θ)
"""

# ╔═╡ 1cd0b656-580d-4daf-9ce7-8b8c3e37dfde
plot_literal_listener(ll_example_θ)

# ╔═╡ b8806ceb-8cf3-406c-b167-92613f7f2488
md"""
### Expected success
"""

# ╔═╡ f3b0e6f6-2e2b-423c-a89d-0dfec3facf07
md"""
Based on the literal listener model, we can calculate the communicate effeciency a threshold $\theta$. 

We estimate the *expected succes* of our communication if we use $\theta$ as our threshold. When we describe an object of size/price $x$, the success of the action is determined by the posterior belief $P(x | \text{message})$ that the listener will hold based on the message.

Here, assume we describe an object of price/size $x$ as follows:

* If $x > \theta$, we won't use the vague adjective, so the listener will use their prior belief $P(x)$
* If $x \geq \theta$, we will describe it using the vague adjective. The listener then updates their belief according to the literal listener model to estimate $L_0(x | x > \theta)$

The *expected success* takes the success for each point $x$ in the scale, multiplied by the prior probability that $x$ will occur.

$\sum P(x) * \text{success}(x)$

So

$ES(\theta) = \sum_{x < \theta} P(x) \times P(x) \; +$
$\sum_{x \geq \theta} P(x) \times L_0(x | x \geq \theta)$
"""

# ╔═╡ c3c0ac35-3992-4c3c-9794-96967941fcf7
function expected_success(θ, scale_points, densityf, cumulativef)
	term_1 = if θ > minimum(scale_points)
		sum(filter(x -> x < θ, scale_points)) do x
			densityf(x) * densityf(x)
		end
	else
		0
	end
	
	term_2 = sum(filter(x -> x >= θ, scale_points)) do x
		densityf(x) * literal_listener(x, θ, densityf, cumulativef)
	end
	
	term_1 + term_2
end

# ╔═╡ 3e412b0d-b835-4e29-9155-c24b5b5d9546
md"""
Plot of the expected success for every threshold value $\theta$
"""

# ╔═╡ 217e6552-74ca-4ade-ae21-e215bf68ca90
let
	p = plot_couch_prior()
	
	es(θ) = expected_success(
		θ, 
		couch_price_scale_points, 
		couch_price_density, 
		couch_price_cumulative)
	
	plot!(p,
		couch_price_scale_points,
		es,
		label = "expected success"
	)
end

# ╔═╡ 4a6d5189-a731-45c4-8e38-3b5099756f18
md"""
### Utility
"""

# ╔═╡ 1a2cbb22-a5b1-4f3c-8238-d59436f9d1a0
md"""
The utility of a threshold is based on the expected success. Parameters are threshold $\theta$ and a coverage parameter $c$

This is calculated as follows:

$U(\theta, c) = ES(\theta) + c \times \Big( \sum_{x = \theta}^{max} P(x) \Big)$
"""

# ╔═╡ a246c8c9-808c-44e6-94a9-ac077c546baa
function utility(θ, coverage, scale_points, densityf, cumulativef)
	term1 = expected_success(θ, scale_points, densityf, cumulativef)
	
	term2 = sum(filter(x -> x >= θ, scale_points)) do x
		densityf(x)
	end
	
	term1 + coverage * term2
end

# ╔═╡ e4c4689c-53f2-4874-a8eb-fe31d1da50a5
@bind ut_example_coverage Slider(-0.25:0.01:0.25, default = 0.0)

# ╔═╡ 281d7b77-6fb0-4733-88c9-0c49c10b8109
md"Coverage parameter : $(ut_example_coverage)"

# ╔═╡ 4051fec8-8a0c-4412-84aa-ad1f8d3491ee
function plot_utility(coverage)
	p = plot_couch_prior()
	
	ut(θ) = utility(
		θ, 
		coverage,
		couch_price_scale_points, 
		couch_price_density, 
		couch_price_cumulative)
	
	plot!(p,
		couch_price_scale_points,
		ut,
		label = "utility"
	)
end

# ╔═╡ a53d05c5-b1c5-4ab7-a29a-ef88361c5203
plot_utility(ut_example_coverage)

# ╔═╡ 5ec1487c-fb7e-4c09-b80c-f92b2a3f37e4
md"""
### Threshold probability
"""

# ╔═╡ 1bcb2a30-bbe8-4225-8566-347706555828
md"""
The probability that one would use a threshold $\theta$ is based on hyperparameters $c$ and $\lambda$ and calculated as follows

$P(\theta | \lambda, c) = \frac{e^{\lambda \cdot U(\theta, c)}}{\sum_t e^{\lambda \cdot U(t, c)}}$
"""

# ╔═╡ 0b5dbba1-8509-495d-9da1-051c71b116fb
function probability_threshold(θ, λ, coverage, scale_points, densityf, cumulativef)
	exp_utility(x) = exp(
		λ * utility(x, coverage, scale_points, densityf, cumulativef)
	)
	
	exp_utility(θ) / sum(exp_utility, scale_points)
end

# ╔═╡ 51179458-39d3-4652-939d-6f15954056e3
@bind tp_example_λ Slider(1:5:100, default = 50)

# ╔═╡ 1fae8bee-9cca-404f-8fe8-0752b4c64e6f
md"λ : $(tp_example_λ)"

# ╔═╡ 34398d43-b2bd-428f-a9f8-fab579ccb99f
@bind tp_example_coverage Slider(-0.25:0.01:0.25, default = 0.0)

# ╔═╡ da453bd1-70f1-47a2-b32d-eee7af514e43
md"Coverage parameter: $(tp_example_coverage)"

# ╔═╡ 33090a3c-ce88-40aa-b3ee-ba6eb2b6b593
function plot_threshold_probability(λ, coverage)
	p = plot_couch_prior()
	
	tp(θ) = probability_threshold(
		θ, 
		λ,
		coverage,
		couch_price_scale_points, 
		couch_price_density, 
		couch_price_cumulative)
	
	plot!(p,
		couch_price_scale_points,
		tp,
		fill = 0, fillalpha = 0.5,
		label = "threshold probability"
	)
end

# ╔═╡ ab797a07-254e-40f8-b7b9-c7fe31d5d4ba
plot_threshold_probability(tp_example_λ, tp_example_coverage)

# ╔═╡ 0a0715d3-8f0b-4e26-b54d-8aa3cdc6ced6
md"""
### Adjective use
"""

# ╔═╡ 01cbddcb-641c-4251-81bb-83637caff93e
md"""
Based on the distribution of thresholds, we can now calculate the probability that a speaker would use the adjective for a degree $x$.

In particular, the speaker will use the adjective if they are using a threshold value $\theta$ such that $x \geq \theta$. We use the threshold probability function to estimate how likely such thresholds are.

$S_1(x, \lambda, c) = \sum_{\theta \leq x} P(\theta | \lambda, c)$
"""

# ╔═╡ 7e6becae-5be3-4069-b2f6-139f4b02cf92
function use_adjective(degree, λ::Number, coverage::Number, 
		scale_points::AbstractArray, 
		densityf::Function, cumulativef::Function)
	sum(filter(θ -> θ <= degree, scale_points)) do θ
		probability_threshold(θ, λ, coverage, scale_points, densityf, cumulativef)
	end
end

# ╔═╡ a97115d7-f572-4d58-8c9a-a073b17b7b12
md"""
For the sake of efficiency, an alternative implementation of the function takes an array of precalculated threshold probabilities.
"""

# ╔═╡ 4f454802-5399-43dd-928e-89506a78da28
function use_adjective(degree, θ_probabilities::AbstractArray,
		scale_points::AbstractArray)

	sum(filter(i -> scale_points[i] <= degree, 1:length(scale_points))) do i
		θ_probabilities[i]
		end
end

# ╔═╡ 899f2e2a-ab04-412f-97b2-90269cc14cf6
@bind ua_example_λ Slider(1:5:100, default = 50)

# ╔═╡ b522ae78-c917-47ca-83c9-ff43771b0603
md"λ : $(ua_example_λ)"

# ╔═╡ d2d4c6d6-d440-4442-979d-76c9a0e76b00
@bind ua_example_coverage Slider(-0.25:0.01:0.25, default = 0.0)

# ╔═╡ 5318b14a-e95b-4324-85bd-8a8094351cad
md"Coverage parameter: $(ua_example_coverage)"

# ╔═╡ edd92128-c71e-40da-b325-32425c9d1cf0
ua_example_θ_probabilities = map(couch_price_scale_points) do θ
	probability_threshold(θ, ua_example_λ, ua_example_coverage, 
		couch_price_scale_points, couch_price_density, couch_price_cumulative)
end

# ╔═╡ 55869021-3709-412a-a216-92c035a90f6a
function plot_use_adjective(θ_probabilities)
	ua(d) = use_adjective(
		d, 
		θ_probabilities,
		couch_price_scale_points)
	
	plot(couch_price_scale_points,
		ua,
		ylabel = "P(use adjective)",
		xlabel = "Price (\$)",
		label = "model prediction",
	)
end

# ╔═╡ 96112ecc-8f1f-4bb1-b6c5-a67cfa8a00a9
let
	p = plot_use_adjective(ua_example_θ_probabilities)
end

# ╔═╡ ada1c503-8664-4611-bc0a-3c6ce0a41602
md"""
## Fitting parameters
"""

# ╔═╡ 284bf321-935c-421e-8183-eeae4e3fae89
md"""
Now we can look at the probability that each stimulus was selected for the target adjective in the experiment and fit the model to these data.

We start by importing the results from the experiment.
"""

# ╔═╡ ccb9bbd4-4c2e-474f-8937-b0eb8c235814
semantic_results = let
	all_results = CSV.read(paths["results"], DataFrame)
	
	semresults = filter(all_results) do row
		row.item_type == "semantic"
	end
	
	semresults.response = parse.(Bool, semresults.response)
	
	semresults
end ;

# ╔═╡ 91116ccc-25d6-47e5-8624-63a215cec588
couch_price_results = let
	results = filter(semantic_results) do row
		row.scenario == "couch" && row.adj_target == "expensive" && row.condition == "bimodal" 
	end
	
	grouped = groupby(results, :stimulus_price)
	
	acceptance_rate(judgements) = count(judgements) / length(judgements)
	
	combine(grouped, :response => acceptance_rate => "ratio_accepted")
end

# ╔═╡ 2500f256-3d54-4eae-a5df-60267afb2b59
md"""
For values of the parameters $\lambda$ and $c$, we calculate how far off the model is from the real data.

I use the mean square error (MSE) to score the predictions.
"""

# ╔═╡ 9b096d21-8aa9-42fd-81a5-593942a7a468
function estimate_error(parameters)
	λ, coverage = parameters
	
	θ_probabilities = map(couch_price_scale_points) do θ
		probability_threshold(θ, λ, coverage, 
			couch_price_scale_points, couch_price_density, couch_price_cumulative)
	end
	
	p_predicted = map(couch_price_results.stimulus_price) do price
		use_adjective(price, θ_probabilities, couch_price_scale_points)
	end
	
	p_observed = couch_price_results.ratio_accepted
	
	mse = sum((p_predicted .- p_observed) .^2)
end

# ╔═╡ 2226afd3-aa95-4b9e-9d5b-8addf7b69854
md"""
I use the `Optim` package to find optimal values of $\lambda$ and $c$
"""

# ╔═╡ 705af09d-7f4f-496c-ac89-29fd461bae4f
opt_result = let
	initial_values = [50.0, 0.0]
	
	optimize(estimate_error,
		initial_values
	)
end

# ╔═╡ 0bc81ff1-b5e5-4fff-af12-19c41c750dcd
optimal_λ, optimal_coverage = Optim.minimizer(opt_result)

# ╔═╡ 00a3912f-7b63-4338-ac25-a44cca17e2db
md"""
The best-fitting model compared to the experiment data:
"""

# ╔═╡ 4ba598ff-32ce-4467-9fcb-db3b0c4b3ae2
let
	θ_probabilities =	map(couch_price_scale_points) do θ
		probability_threshold(θ, optimal_λ, optimal_coverage, 
			couch_price_scale_points, couch_price_density, couch_price_cumulative)
	end

	p = plot_use_adjective(θ_probabilities)
	
	scatter!(p,
		couch_price_results.stimulus_price,
		couch_price_results.ratio_accepted,
		label = "observed acceptance rates",
		legend = :outertop,
		)
end

# ╔═╡ Cell order:
# ╟─2337edd6-894c-442d-bdf3-d1b9775dce4b
# ╟─8332538e-a06a-415b-8fc1-45e44c5c6a1a
# ╠═9e79889a-9baf-11eb-1e2d-59906f90ea82
# ╠═9ebd6e50-cce7-40c8-80b6-5d0785127687
# ╠═56e46a90-adc7-4967-aa50-441dea17d511
# ╟─10898ea6-0ebb-4e37-9171-d1bfdb2cc932
# ╠═fe1ed26e-42bf-4178-89e4-bef0f4e0c240
# ╠═252f4a66-37e7-4ffa-9429-a407af3a9345
# ╠═4387731e-0866-425c-aee7-a83b7ca729d5
# ╠═fcd71c2c-e685-449d-bf0d-563d28b4a5b9
# ╠═460e3cdb-e248-4c2b-a921-8cab93dadd6d
# ╠═60b27cb6-6aa1-4a92-a4be-42ecd805ef79
# ╠═1a71c080-a430-4028-b738-8ca7183f6369
# ╠═44d33712-d590-423b-b75c-a281dcb27ae9
# ╠═f93afb34-6e01-49bc-843a-0eac76bf8b13
# ╟─ad926740-e511-4bf7-a76f-eb1ed1f33e4b
# ╟─3296d398-5e9b-4afb-a0c7-e8fc7d980548
# ╠═564a20ee-5f1a-42ee-8177-6184989bea76
# ╟─770e7e10-ceff-4bb7-93f5-b13ba722a7ce
# ╠═83bbf10c-c616-4982-a3dc-9f8773aadbe5
# ╟─de2bdadc-0ab9-4cc4-9d1a-2aa040ab4c7a
# ╟─b7ecc372-66d2-437a-b832-304df70dfab5
# ╠═1cd0b656-580d-4daf-9ce7-8b8c3e37dfde
# ╟─b8806ceb-8cf3-406c-b167-92613f7f2488
# ╟─f3b0e6f6-2e2b-423c-a89d-0dfec3facf07
# ╠═c3c0ac35-3992-4c3c-9794-96967941fcf7
# ╟─3e412b0d-b835-4e29-9155-c24b5b5d9546
# ╠═217e6552-74ca-4ade-ae21-e215bf68ca90
# ╟─4a6d5189-a731-45c4-8e38-3b5099756f18
# ╟─1a2cbb22-a5b1-4f3c-8238-d59436f9d1a0
# ╠═a246c8c9-808c-44e6-94a9-ac077c546baa
# ╟─281d7b77-6fb0-4733-88c9-0c49c10b8109
# ╠═e4c4689c-53f2-4874-a8eb-fe31d1da50a5
# ╠═a53d05c5-b1c5-4ab7-a29a-ef88361c5203
# ╠═4051fec8-8a0c-4412-84aa-ad1f8d3491ee
# ╟─5ec1487c-fb7e-4c09-b80c-f92b2a3f37e4
# ╟─1bcb2a30-bbe8-4225-8566-347706555828
# ╠═0b5dbba1-8509-495d-9da1-051c71b116fb
# ╟─1fae8bee-9cca-404f-8fe8-0752b4c64e6f
# ╟─51179458-39d3-4652-939d-6f15954056e3
# ╟─da453bd1-70f1-47a2-b32d-eee7af514e43
# ╟─34398d43-b2bd-428f-a9f8-fab579ccb99f
# ╠═ab797a07-254e-40f8-b7b9-c7fe31d5d4ba
# ╠═33090a3c-ce88-40aa-b3ee-ba6eb2b6b593
# ╟─0a0715d3-8f0b-4e26-b54d-8aa3cdc6ced6
# ╟─01cbddcb-641c-4251-81bb-83637caff93e
# ╠═7e6becae-5be3-4069-b2f6-139f4b02cf92
# ╟─a97115d7-f572-4d58-8c9a-a073b17b7b12
# ╠═4f454802-5399-43dd-928e-89506a78da28
# ╟─b522ae78-c917-47ca-83c9-ff43771b0603
# ╟─899f2e2a-ab04-412f-97b2-90269cc14cf6
# ╟─5318b14a-e95b-4324-85bd-8a8094351cad
# ╟─d2d4c6d6-d440-4442-979d-76c9a0e76b00
# ╠═96112ecc-8f1f-4bb1-b6c5-a67cfa8a00a9
# ╠═edd92128-c71e-40da-b325-32425c9d1cf0
# ╠═55869021-3709-412a-a216-92c035a90f6a
# ╟─ada1c503-8664-4611-bc0a-3c6ce0a41602
# ╟─284bf321-935c-421e-8183-eeae4e3fae89
# ╠═ccb9bbd4-4c2e-474f-8937-b0eb8c235814
# ╠═91116ccc-25d6-47e5-8624-63a215cec588
# ╟─2500f256-3d54-4eae-a5df-60267afb2b59
# ╠═9b096d21-8aa9-42fd-81a5-593942a7a468
# ╟─2226afd3-aa95-4b9e-9d5b-8addf7b69854
# ╠═705af09d-7f4f-496c-ac89-29fd461bae4f
# ╠═0bc81ff1-b5e5-4fff-af12-19c41c750dcd
# ╟─00a3912f-7b63-4338-ac25-a44cca17e2db
# ╠═4ba598ff-32ce-4467-9fcb-db3b0c4b3ae2
