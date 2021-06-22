### A Pluto.jl notebook ###
# v0.14.8

using Markdown
using InteractiveUtils

# ╔═╡ 9e79889a-9baf-11eb-1e2d-59906f90ea82
begin
	#package environment
	
    import Pkg
	root = "../.."
	Pkg.activate(root)
	
	#import model definition
	
	function ingredients(path::String)
		#function copied from https://github.com/fonsp/Pluto.jl/issues/115
		name = Symbol(basename(path))
		m = Module(name)
		Core.eval(m,
			Expr(:toplevel,
				 :(eval(x) = $(Expr(:core, :eval))($name, x)),
				 :(include(x) = $(Expr(:top, :include))($name, x)),
				 :(include(mapexpr::Function, x) =
					$(Expr(:top, :include))(mapexpr, $name, x)),
				 :(include($path))))
		m
	end
	
	priors = ingredients("prior_distributions.jl")
	
	model = ingredients("model_definition.jl")

	# packages for this notebook
	
    try
		using CSV, DataFrames, Distributions, Plots, Statistics
		using Turing, MCMCChains, StatsPlots
	catch
		Pkg.instantiate()
		using CSV, DataFrames, Distributions, Plots, Statistics
		using Turing, MCMCChains, StatsPlots
	end
end

# ╔═╡ bb7f43dc-d45a-4ecb-aa78-d0341fe0c46a
md"""
# Fitting the threshold model

This notebook will fit the threshold model to the semantic judgements. The model itself is defined in `./model_definition.jl`.

I will also use a prior distribution fitted to each sample, which is done in `./prior_distributions.jl`.
"""

# ╔═╡ 8332538e-a06a-415b-8fc1-45e44c5c6a1a
md"""
## Data import

Import the overview of stimuli and the results of the semantic task.
"""

# ╔═╡ 9ebd6e50-cce7-40c8-80b6-5d0785127687
paths = Dict(
	:stimuli_exp2 => root * "/experiment/acceptability_with_semantic/materials/stimuli_data.csv",
	:stimuli_exp3 => root * "/experiment/novel_objects/materials/stimuli_data.csv",
	:results => root * "/modelling/results/results_with_disagreement.csv",
	:export => root * "/modelling/results/semantic_model_chain.jls"
)

# ╔═╡ 56e46a90-adc7-4967-aa50-441dea17d511
stimuli_data = let
	data_exp3 = CSV.read(paths[:stimuli_exp3], DataFrame)
	
	data_exp2 = let
		data = CSV.read(paths[:stimuli_exp2], DataFrame)
		#reorder and rename columns to match exp3
		select!(data, [:index, :size, :price, :bimodal, :unimodal, :scenario])
		rename(data, names(data_exp3))
	end
	
	vcat(data_exp2, data_exp3)
end

# ╔═╡ d8659119-f9f0-4ab9-9e9e-1cf241d425e9
semantic_results = let
	data = CSV.read(paths[:results], DataFrame)
	
	# filter on semantic task
	filter!(data) do row
		row.item_type == "semantic"
	end
	
	# convert responses to bool
	data.response = parse.(Bool, data.response)
	
	#set condition to blank for expensive
	data.condition = map(eachrow(data)) do row
		if row.adj_target == "expensive"
			"none"
		else
			row.condition
		end
	end
	
	data
end

# ╔═╡ 163d5068-c3a6-4b40-aad3-967c1d48cadd
md"""
Use `groupby` and `combine` to get an overview over all the cases that we can iterate over. By "case" I mean particular setup for the semantic task, so we specify the scenario, target adjective, and condition.

The condition is not actually relevant for *"expensive"* (condition affects the size, not the price). It's just easier to treat them as separate than to write an exception. For now, I fit parameters for the entire set of results, so the distinction doesn't matter.
"""

# ╔═╡ 0320e412-2542-465d-9675-77111b98b974
cases_overview = let
	cases = combine(
		groupby(semantic_results,
			[:scenario, :adj_target, :condition]),
		nrow
	)
	
	sorted = let
		by_condition = sort(cases, :condition)
		by_adjective = sort(by_condition, :adj_target, 
			by = adj -> adj == "expensive")
		by_scenario = sort(by_adjective, :scenario)
	end
end

# ╔═╡ 10898ea6-0ebb-4e37-9171-d1bfdb2cc932
md"""
## Stimuli descriptions

Some functions to get information about the stimuli for a case.

First, the scale that should be used based on the target adjective.
"""

# ╔═╡ 650d7384-5fd6-4164-ab52-e1918465fd09
function get_scale(adjective)
	if adjective == "expensive"
		"price"
	else
		"size"
	end
end

# ╔═╡ fee5e072-5b3f-48be-bdcd-3c643102f2de
md"The vector of all sizes/prices in the sample."

# ╔═╡ 07aa30df-a6b3-4394-a6cc-1468e8c84647
function get_stimuli(case)
	items = filter(stimuli_data) do item
		item[case.condition] && item.scenario == case.scenario
	end
	
	items[:, get_scale(case.adj_target)]
end

# ╔═╡ c40d3ed7-8eb1-44c6-8967-b3e4a62bb409
md"""
Definition of the scale points for each case. These are hard coded.

The scale points should allow a decent margin around the observed degrees, so that the probability functions can taper off gradually at the edges.

The resolution of the scale points is based on the sample, but also determines how long fitting will take (lower resolution = faster).
"""

# ╔═╡ 319c4a2c-acdb-46e1-9d1b-69bb3c06661d
begin
	#scales depend on the adjective and scenario (not the condition)
	scales_dict = Dict(
		("tv", "big") => 0:2:100,
		("tv", "expensive") => 0:100:5000,
		("couch", "long") => 0:3:150,
		("couch", "expensive") => 0:30:1500,
		("ball", "big") => 0:0.5:25,
		("ball", "expensive") => 0:0.5:25,
		("spring", "long") => 0:1:40,
		("spring", "expensive") => 0:0.5:25
	)
	
	#convenient retrieval function
	function get_scale_points(case)
		scales_dict[(case.scenario), (case.adj_target)]
	end
end

# ╔═╡ 88534b4b-08a9-42a1-9b02-ed86293a0b9a
md"""
Now we need to specify the prior distributions. The notebook `prior_distributions.jl` specifies these distributions, this is just some code to conveniently retrieve them.
"""

# ╔═╡ 0b9df455-0f9e-489d-a562-486eeaa97cc0
begin
	#scales depend on the adjective and scenario (not the condition)
	priors_dict = Dict(
		("tv", "big", "bimodal") => 		priors.prior_size_tv_bim,
		("tv", "big", "unimodal") => 		priors.prior_size_tv_unim,
		("tv", "expensive", nothing) => 	priors.prior_price_tv,
		("couch", "long", "bimodal") => 	priors.prior_size_couch_bim,
		("couch", "long", "unimodal") => 	priors.prior_size_couch_unim,
		("couch", "expensive", nothing) => 	priors.prior_price_couch,
		("ball", "big", "bimodal") => 		priors.prior_size_ball_bim,
		("ball", "big", "unimodal") => 		priors.prior_size_ball_unim,
		("ball", "expensive", nothing) => 	priors.prior_price_ball,
		("spring", "long", "bimodal") => 	priors.prior_size_spring_bim,
		("spring", "long", "unimodal") => 	priors.prior_size_spring_unim,
		("spring", "expensive", nothing) => priors.prior_price_spring
	)
	
	#convenient retrieval function
	function get_prior(case)
		if case.adj_target == "expensive"
			priors_dict[(case.scenario, case.adj_target, nothing)]
		else
			priors_dict[(case.scenario, case.adj_target, case.condition)]
		end
	end
end

# ╔═╡ ada1c503-8664-4611-bc0a-3c6ce0a41602
md"""
## Semantic task results
"""

# ╔═╡ 284bf321-935c-421e-8183-eeae4e3fae89
md"""
We will fit the model to the data from the semantic task. In particular, we want to know how likely it is that an object is selected as *"big"*, *"long"*, or *"expensive"*, given its degree (size, length, or price, respectively).

Responses are grouped by item, not by degree. This is relevant because there are usually a few items with the same degree. In that case, the model won't be able to distinguish them, but I count them separately so that they weigh as two items in the error calculation.
"""

# ╔═╡ 74231275-a5ad-4b1d-a606-af9344b55f33
function get_results(case)
	# unaggregated results
	raw_results = filter(semantic_results) do row
		all([
				row.scenario == case.scenario,
				row.adj_target == case.adj_target,
				row.condition == case.condition
		])
	end
	
	# group by item
	grouped = groupby(raw_results, :id)
	
	# summarise with degree and ratio of selections
	scale_column = case.adj_target == "expensive" ? :stimulus_price : :stimulus_size
	selection_rate(judgements) = count(judgements) / length(judgements)
	
	combined = combine(grouped, 
		scale_column => first => :degree,
		:response => selection_rate => "ratio_selected",
		:response => count => "n_selected",
		:response => length => "n_total"
	)
	
	sorted = sort(combined, :degree)
end

# ╔═╡ 944137fc-f136-4ad5-bd0a-df8189249b31
let
	case = last(eachrow(cases_overview))
	get_results(case)
end

# ╔═╡ a0cd2088-ff78-4f71-8236-5df0cd85275f
md"""
## Bayesian inference of parameters
"""

# ╔═╡ 90560b95-ecf5-4255-9f40-1dd2a9138eeb
selections = mapreduce(vcat, eachrow(cases_overview)) do case
	results = get_results(case)
	results.n_selected
end

# ╔═╡ 0375e6e3-6880-4ac6-a862-052e9cab09ff
@model function semantic_model(selections; model_type = :vague)
	#prior distribution of parameters
	λ ~ Uniform(1,250)
	c ~ Uniform(-1.0, 1.0)
	
	if model_type == :composite
		α ~ Uniform(0.0, 1.0)
	end
	
	#get predictions based on the parameters
	predictions = mapreduce(vcat, eachrow(cases_overview)) do case
		#set up speaker model for this case
		scale_points = get_scale_points(case)
		prior = get_prior(case)
		results = get_results(case)
		
		speaker = if model_type == :composite
			model.CompositeModel(λ, c, α, scale_points, prior)
		else
			model.VagueModel(λ, c, scale_points, prior)
		end
		
		#predicted probabilities per object
		probs = map(results.degree) do degree
			prediction = model.use_adjective(degree, speaker)
			min(prediction, 1.0)
		end
		
		DataFrame(
			:p => probs, 
			:N => results.n_total
		)
	end

	#evidence (i.e. selection ratios) should be generated from predicted distribution
	for i in 1:length(selections)
		selections[i] ~ Binomial(predictions.N[i], predictions.p[i])
	end
end

# ╔═╡ f08e885e-ae5e-4e27-876e-f56f754cb663
function run_chains(iterations; model_type = :vague)
	model = semantic_model(selections, model_type = model_type)
	sampler = PG(20)

	mapreduce(chainscat, 1:3) do chain
		sample(model, sampler, iterations) 
	end
end

# ╔═╡ 07505fbd-f3c7-4c8a-91b8-666166cd9a47
run_sampling = false

# ╔═╡ 286d06d1-8c2b-4e22-bd90-224187fb4773
#shoud chain be exported? (turn off for testing)
export_chain = true

# ╔═╡ c88b29a3-f0a5-4b5e-8a9d-024bf0a8315c
chains = if run_sampling
	res = run_chains(1000, model_type = :composite)
	
	if export_chain
		write(paths[:export], res)
	end
	
	res
else
	read(paths[:export], Chains)
end

# ╔═╡ d7f1822a-6d69-4e1d-bda1-6f30491f6565
describe(chains)[1]

# ╔═╡ 5ff029f1-4e7f-4f64-9af2-9967c5a2f012
describe(chains)[2]

# ╔═╡ 2dcc7dd2-e810-4697-9e30-8714fb26309d
plot(chains)

# ╔═╡ Cell order:
# ╟─bb7f43dc-d45a-4ecb-aa78-d0341fe0c46a
# ╠═9e79889a-9baf-11eb-1e2d-59906f90ea82
# ╟─8332538e-a06a-415b-8fc1-45e44c5c6a1a
# ╠═9ebd6e50-cce7-40c8-80b6-5d0785127687
# ╠═56e46a90-adc7-4967-aa50-441dea17d511
# ╠═d8659119-f9f0-4ab9-9e9e-1cf241d425e9
# ╟─163d5068-c3a6-4b40-aad3-967c1d48cadd
# ╠═0320e412-2542-465d-9675-77111b98b974
# ╟─10898ea6-0ebb-4e37-9171-d1bfdb2cc932
# ╠═650d7384-5fd6-4164-ab52-e1918465fd09
# ╟─fee5e072-5b3f-48be-bdcd-3c643102f2de
# ╠═07aa30df-a6b3-4394-a6cc-1468e8c84647
# ╟─c40d3ed7-8eb1-44c6-8967-b3e4a62bb409
# ╠═319c4a2c-acdb-46e1-9d1b-69bb3c06661d
# ╟─88534b4b-08a9-42a1-9b02-ed86293a0b9a
# ╠═0b9df455-0f9e-489d-a562-486eeaa97cc0
# ╟─ada1c503-8664-4611-bc0a-3c6ce0a41602
# ╟─284bf321-935c-421e-8183-eeae4e3fae89
# ╠═74231275-a5ad-4b1d-a606-af9344b55f33
# ╠═944137fc-f136-4ad5-bd0a-df8189249b31
# ╟─a0cd2088-ff78-4f71-8236-5df0cd85275f
# ╠═90560b95-ecf5-4255-9f40-1dd2a9138eeb
# ╠═0375e6e3-6880-4ac6-a862-052e9cab09ff
# ╠═f08e885e-ae5e-4e27-876e-f56f754cb663
# ╠═07505fbd-f3c7-4c8a-91b8-666166cd9a47
# ╠═286d06d1-8c2b-4e22-bd90-224187fb4773
# ╠═c88b29a3-f0a5-4b5e-8a9d-024bf0a8315c
# ╠═d7f1822a-6d69-4e1d-bda1-6f30491f6565
# ╠═5ff029f1-4e7f-4f64-9af2-9967c5a2f012
# ╠═2dcc7dd2-e810-4697-9e30-8714fb26309d
