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
		using CSV, DataFrames, Distributions, Plots, Statistics, Optim
		using Turing, MCMCChains, StatsPlots
	catch
		Pkg.instantiate()
		using CSV, DataFrames, Distributions, Plots, Statistics, Optim
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
	:export => root * "/modelling/results/semantic_model_chain.jls",
	:figures => root * "/figures/"
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
		if case.condition == "none"
			item.scenario == case.scenario
		else
			item[case.condition] && item.scenario == case.scenario
		end
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

# ╔═╡ 054a8859-dff2-4588-8ac6-5f45c884a6d5
describe(chains)[2]

# ╔═╡ 38bc06e2-91f7-42df-b051-e0702df27969
let
	p1 = meanplot(chains)
	p2 = density(chains)
	
	plot(p1, p2, layout = (1,2), size = (650, 600))
end

# ╔═╡ 1882081e-e66b-40a1-995a-a1234265217f
function plot_parameter(parameter; kwargs...)
	data = chains[parameter]
	vector = reshape(data, length(data))
	
	xlims_dict = Dict(
		:λ => (0, 250),
		:c => (-0.2, 0.05),
		:α => (0.0, 1.0)
	)
	
	p = density(vector,
		xlims = xlims_dict[parameter],
		color = :black,
		fill = 0, fillcolor = 3, fillalpha = 0.75,
		xlabel = "value",
		ylabel = "density",
		legend = :none,
	)
	
	plot!(p; kwargs...)
	
	p
end

# ╔═╡ 3a3af14d-99b5-45c3-9ffb-5d90bc0de7c2
let
	parameters = [:λ, :c, :α]
	
	subplots = map(parameters) do parameter
		plot_parameter(parameter, title = parameter)
	end
	
	plot(subplots..., layout = (3,1), size = (400, 600))
end

# ╔═╡ f7c0074e-af88-421d-aa05-2ca1cb254ddc
if "figures" ∈ readdir(root)
	for parameter in [:λ, :c, :α]
		p = plot_parameter(parameter)
		
		ascii_strings = Dict(:λ => "lambda", :c => "c", :α => "alpha")
		filename = "posterior_distribution_$(ascii_strings[parameter]).pdf"
		
		savefig(p, paths[:figures] * filename)
	end
	
	md"Figures saved!"
end

# ╔═╡ 40028cea-72cb-45b1-b12e-1950bab1e046
md"""
## Plot predictions vs. data
"""

# ╔═╡ dd797a0b-47c2-4d2c-ac83-b877e9cb32dc
function get_interval(parameter)
	data = quantile(chains, q = [0.025, 0.975])
	parameter_data= DataFrame(data[parameter])
	
	lower, upper = parameter_data[1, "2.5%"], parameter_data[1, "97.5%"]
end

# ╔═╡ 67b82a4a-31ad-410d-9f93-1defacb70ae9
begin
	λ_interval = get_interval(:λ)
	c_interval = get_interval(:c)
	α_interval = get_interval(:α)
end ;

# ╔═╡ 6ce1d407-b9b7-4799-8357-7a8b8917e55d
md"""
## Model comparisons
"""

# ╔═╡ 5d8f8f9f-b4e5-4d13-8025-04024881efab
md"""
Compare the likelihood of the results for the composite and vague model, given the *best fit* values for each of the parameters. (Optimal parameter values are calculated in `fitting.jl`.)
"""

# ╔═╡ c8e3bce8-8381-4e76-98cf-444c11310221
function data_likelihood_vague(parameters; transform = true)
	λ, c = parameters
	
	if transform
		-1 * logprob"selections = selections | model = semantic_model(nothing), λ = λ, c = c"
	else
		prob"selections = selections | model = semantic_model(nothing), λ = λ, c = c"
	end
end

# ╔═╡ 96de5fcc-7fc5-4171-ab26-62b685dcd007
@model function semantic_model_composite(selections)
	#prior distribution of parameters
	λ ~ Uniform(1,250)
	c ~ Uniform(-1.0, 1.0)
	α ~ Uniform(0.0, 1.0)

	#get predictions based on the parameters
	predictions = mapreduce(vcat, eachrow(cases_overview)) do case
		#set up speaker model for this case
		scale_points = get_scale_points(case)
		prior = get_prior(case)
		results = get_results(case)
		
		speaker = model.CompositeModel(λ, c, α, scale_points, prior)
		
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

# ╔═╡ c1e5467e-d76a-4ffc-b53a-48f811da5a8a
function data_likelihood_composite(parameters; transform = true)
	λ, c, α = parameters
	
	if transform
		-1 * logprob"selections = selections | model = semantic_model_composite(nothing), λ = λ, c = c, α = α"
	else
		prob"selections = selections | model = semantic_model_composite(nothing), λ = λ, c = c, α = α"
	end
end

# ╔═╡ 21b66fad-52b3-410d-8512-3d6a26d171f1
opt_vague_result = let
	initial_values = [100.0, 0.0]
	result = optimize(data_likelihood_vague, initial_values)
end

# ╔═╡ ab0939c7-f16f-4c2a-961f-a3568b8e31d5
opt_vague_parameters = Optim.minimizer(opt_vague_result)

# ╔═╡ e5b65621-df27-4df4-beed-811475a5a17c
opt_composite_result = let
	initial_values = [100.0, 0.0, 0.0]
	result = optimize(data_likelihood_composite, initial_values)
end

# ╔═╡ 3af2c374-84be-4aa4-b36f-4cb03e9dc9b7
opt_composite_parameters = Optim.minimizer(opt_composite_result)

# ╔═╡ 67755e76-51a9-4356-9667-c11703fec270
function predictions(case)
	scale_points = get_scale_points(case)
	prior = get_prior(case)
	
	#prediction with mean values of parameters
	
	mode_speaker = model.CompositeModel(opt_composite_parameters..., scale_points, prior)
	
	mode_probs = map(scale_points) do d
		model.use_adjective(d, mode_speaker)
	end
	
	# 95% confidence interval
	
	confidence_interval_95 = let
		parameter_bounds = [(λ, c, α)
			for λ in get_interval(:λ) 
			for c in get_interval(:c)
			for α in get_interval(:α)]
		
		bounds_data = mapreduce(hcat, parameter_bounds) do (λ, c, α)
			speaker = model.CompositeModel(λ, c, α, scale_points, prior)
			probabilities = map(scale_points) do d
				model.use_adjective(d, speaker)
			end
		end
		
		n_items, n_configurations = size(bounds_data)
		
		lower_bounds = map(1:n_items) do i
			mode_probs[i] - minimum(bounds_data[i, :]) 
		end
		
		upper_bounds = map(1:n_items) do i
			maximum(bounds_data[i, :]) - mode_probs[i]
		end
		
		lower_bounds, upper_bounds
	end
	
	mode_probs, confidence_interval_95
end

# ╔═╡ bc0e77d6-4b11-44a4-a909-77d15e411ac9
function plot_case_comparison(case; kwargs...)
	pal = let
		themecolours = PlotThemes.wong_palette
		
		colours = if case.condition == "bimodal"
			[ themecolours[6], themecolours[1], "#eeeeee"]
		elseif case.condition == "unimodal"
			[ themecolours[5], themecolours[2], "#eeeeee"]
		else
			[ "#006D60", themecolours[3], "#eeeeee"]
		end
	end
	
	p = plot(
		ylabel = "P($(case.adj_target) | degree)",
		xlabel = "degree",
	)
	
	#get predicted selection probabilities
	
	scale_points = get_scale_points(case)
	results = get_results(case)
	
	mean_predictions, confidence_interval = predictions(case)
	
	plot!(p,
		scale_points,
		mean_predictions,
		ribbon = confidence_interval,
		#fillalpha = 0.75, fillcolor = pal[1],
		fillalpha = 0.75, fillcolor = pal[2],
		label = "predicted",
		#color = pal[2], lw = 2,
		color = :black
	)
	
	scatter!(p,
		results.degree,
		results.ratio_selected,
		label = "observed",
		color = :black,
		markersize = 2.5,
	)
	
	plot!(p; kwargs...)
end

# ╔═╡ a1565fa6-08d1-411c-8779-3d7c6d83f7af
comparison_plot = let
	scenario_index(scenario) = let
		scenario_order = ["tv", "couch", "ball", "spring"]
		findfirst(isequal(scenario), scenario_order)
	end
	
	sorted_cases = sort(cases_overview, :scenario, by = scenario_index)
	
	plots = map(eachrow(sorted_cases)) do case
		name = if case.condition == "none"
			"$(case.adj_target) $(case.scenario)"
		else
			"$(case.adj_target) $(case.scenario) ($(case.condition))"
		end
		
		plot_case_comparison(case,
			title = name, legend = nothing,
			titlefontsize = 12,
			guidefontsize = 9,
		)
	end
	
	subplots = plot(plots..., layout = (4,3), size = (1000, 900))
	
	legendplot = plot_case_comparison(
		last(cases_overview),
		xlims = (-10, -5),
		grid = false,
		showaxis = false,
		ticks = nothing,
		legend = :top,
		size = (1000, 100),
		guide = ""
	)
	
	plot(subplots, legendplot, layout = grid(2,1, heights = [0.9,0.1]), 
		size = (1000, 1000)
	)
end

# ╔═╡ 002fb827-a54c-41c4-86e5-18dbee13d96d
if "figures" ∈ readdir(root)
	savefig(comparison_plot, paths[:figures] * "semantic_model_comparison.pdf")
	md"Figure saved!"
end

# ╔═╡ 96e84c2d-ca35-4ac6-982f-c6c558c4c7bc
md"""
Bayes factor of model $M_1$ compared to $M_2$ given data $D$

$K = \frac{P(D | M_1)}{P(D | M_2)}$

"""

# ╔═╡ 17d4753a-731a-47e6-8a64-82e7d6524ddb
p_data_vague_model = data_likelihood_vague(
	opt_vague_parameters, transform = false
)

# ╔═╡ 78740a3d-c57f-4e11-bd1d-2efb3e0d7380
p_data_composite_model = data_likelihood_composite(
	opt_composite_parameters, transform = false
)

# ╔═╡ 2a2f32f5-f5f1-4573-8bac-e0b4b8b6f48c
bayes_factor_composite = p_data_composite_model / p_data_vague_model

# ╔═╡ b518dcd5-7209-4787-abc5-a4a44ff28ff3
md"""
### Different speaker functions between conditions
"""

# ╔═╡ c0557729-a137-40b8-92c3-b780061da36b
cases_overview

# ╔═╡ d0d06901-2854-4d2c-b54f-4c98905a5f60
@model function semantic_model_noconditions(selections)
	#prior distribution of parameters
	λ ~ Uniform(1,250)
	c ~ Uniform(-1.0, 1.0)

	
	#get predictions based on the parameters
	predictions = mapreduce(vcat, eachrow(cases_overview)) do case
		#set up speaker model for this case
		scale_points = get_scale_points(case)
		
		prior = let
			if case.condition == "bimodal"
				unimodal_case = first(filter(cases_overview) do othercase
					all([	othercase.scenario == case.scenario,
							othercase.adj_target == case.adj_target,
							othercase.condition == "unimodal"])
					end)
				
				get_prior(unimodal_case)
			else
				get_prior(case)
			end
			
		end
		
		results = get_results(case)
		
		speaker = model.VagueModel(λ, c, scale_points, prior)
		
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

# ╔═╡ 61cb05a7-2f61-4b87-a013-6e3c111f0a5d
function data_likelihood_noconditions(parameters; transform = true)
	λ, c = parameters
	
	if transform
		-1 * logprob"selections = selections | model = semantic_model_noconditions(nothing), λ = λ, c = c"
	else
		prob"selections = selections | model = semantic_model_noconditions(nothing), λ = λ, c = c"
	end
end

# ╔═╡ 3e4058b0-de07-46ea-9100-060f6747acee
opt_noconditions_result = let
	initial_values = [100.0, 0.0]
	result = optimize(data_likelihood_noconditions, initial_values)
end

# ╔═╡ 79852e31-6ad1-46f4-a4bd-2cde29aaf1b2
opt_noconditions_parameters = Optim.minimizer(opt_noconditions_result)

# ╔═╡ 49242c29-a25f-4bc3-8540-2956b7cc118a
p_data_noconditions = data_likelihood_noconditions(
	opt_noconditions_parameters, transform = false
)

# ╔═╡ 3a01a930-6e9d-41c4-a0aa-bb9e1d186876
md"""
This version does get a better fit compared to both models.
"""

# ╔═╡ 2efa6ad0-faa3-497c-bc5e-40a49bb05866
p_data_noconditions / p_data_vague_model

# ╔═╡ 03c183ae-83e6-4801-b471-4f64f4155d48
p_data_noconditions / p_data_composite_model

# ╔═╡ 26606497-b1df-4272-becd-58e0e273cf35
md"""
So far, we looked at the model's ability to predict the selection ratios (the *y*-values on the plot). We did not look at how well the model predicted the degrees of the objects in the sample (the *x*-values).

The vague and composite model use the same prior distribution, so there is no point in comparing them. But for the "no conditions" model, we mess with the prior distribution, so that's worth considering. It is a bit unfair to manipulate the prior distribution until you get the best fit on the *y*-axis, without including that you get a worse fit on the *x*-axis.

We can calculate the probability of the object sample. These probabilities get very small, so we take the log.
"""

# ╔═╡ cb94e825-4738-49e9-b45c-a29e86b555eb
logp_sample = sum(eachrow(cases_overview)) do case
	scale_points = get_scale_points(case)
	prior = get_prior(case)
	stimuli = get_stimuli(case)
	
	probabilities = pdf.(prior, stimuli)
	
	prob = prod(probabilities)
	log(10, prob)
end

# ╔═╡ b1ff8c47-92ba-41d6-a268-7821b6a7e879
logp_sample_noconditions = sum(eachrow(cases_overview)) do case
	scale_points = get_scale_points(case)
	
	prior = if case.condition == "bimodal"
		unimodal_case = let
			first(filter(cases_overview) do othercase
				all([	othercase.scenario == case.scenario,
						othercase.adj_target == case.adj_target,
						othercase.condition == "unimodal"])
				end)
		end
		get_prior(unimodal_case)
	else
		get_prior(case)
	end

	stimuli = get_stimuli(case)
	
	probabilities = pdf.(prior, stimuli)
	prob = prod(probabilities)
	log(10, prob)
end

# ╔═╡ 63c11e41-5028-4b04-934c-0a74887e1459
md"""
The "no conditions" fit is a lot worse in predicting the sample. Here is the bayes factor on the "true" prior distribution over the version where we treat everything as unimodal.
"""

# ╔═╡ 32dc6b96-077b-4291-85c0-ead273f5dc7a
10^(logp_sample - logp_sample_noconditions)

# ╔═╡ 5a65e0f4-c4ee-40df-a3d7-f31e80767fd3
md"""
When we include the likelihood of the sample, the "no conditions" model becomes a lot less likely.

Improvement of vague model over no conditions model:
"""

# ╔═╡ 6098fb5c-ec91-49af-9897-1836583493be
let
	noconditions = log(10, p_data_noconditions) + logp_sample_noconditions
	vague = log(10, p_data_vague_model) + logp_sample
	
	10^(vague - noconditions)
end

# ╔═╡ 2222c017-21d1-45ba-a5cc-c3a5f44b2721
md"""
Improvement of composite model over no conditions model:
"""

# ╔═╡ 00a392d1-fa65-4ab5-863f-d4badd203f8e
let
	noconditions = log(10, p_data_noconditions) + logp_sample_noconditions
	composite = log(10, p_data_composite_model) + logp_sample
	
	10^(composite - noconditions)
end

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
# ╠═054a8859-dff2-4588-8ac6-5f45c884a6d5
# ╠═38bc06e2-91f7-42df-b051-e0702df27969
# ╠═1882081e-e66b-40a1-995a-a1234265217f
# ╠═3a3af14d-99b5-45c3-9ffb-5d90bc0de7c2
# ╠═f7c0074e-af88-421d-aa05-2ca1cb254ddc
# ╟─40028cea-72cb-45b1-b12e-1950bab1e046
# ╠═dd797a0b-47c2-4d2c-ac83-b877e9cb32dc
# ╠═67b82a4a-31ad-410d-9f93-1defacb70ae9
# ╠═67755e76-51a9-4356-9667-c11703fec270
# ╠═bc0e77d6-4b11-44a4-a909-77d15e411ac9
# ╠═a1565fa6-08d1-411c-8779-3d7c6d83f7af
# ╠═002fb827-a54c-41c4-86e5-18dbee13d96d
# ╟─6ce1d407-b9b7-4799-8357-7a8b8917e55d
# ╟─5d8f8f9f-b4e5-4d13-8025-04024881efab
# ╠═c8e3bce8-8381-4e76-98cf-444c11310221
# ╠═96de5fcc-7fc5-4171-ab26-62b685dcd007
# ╠═c1e5467e-d76a-4ffc-b53a-48f811da5a8a
# ╠═21b66fad-52b3-410d-8512-3d6a26d171f1
# ╠═ab0939c7-f16f-4c2a-961f-a3568b8e31d5
# ╠═e5b65621-df27-4df4-beed-811475a5a17c
# ╠═3af2c374-84be-4aa4-b36f-4cb03e9dc9b7
# ╟─96e84c2d-ca35-4ac6-982f-c6c558c4c7bc
# ╠═17d4753a-731a-47e6-8a64-82e7d6524ddb
# ╠═78740a3d-c57f-4e11-bd1d-2efb3e0d7380
# ╠═2a2f32f5-f5f1-4573-8bac-e0b4b8b6f48c
# ╟─b518dcd5-7209-4787-abc5-a4a44ff28ff3
# ╠═c0557729-a137-40b8-92c3-b780061da36b
# ╠═d0d06901-2854-4d2c-b54f-4c98905a5f60
# ╠═61cb05a7-2f61-4b87-a013-6e3c111f0a5d
# ╠═3e4058b0-de07-46ea-9100-060f6747acee
# ╠═79852e31-6ad1-46f4-a4bd-2cde29aaf1b2
# ╠═49242c29-a25f-4bc3-8540-2956b7cc118a
# ╟─3a01a930-6e9d-41c4-a0aa-bb9e1d186876
# ╠═2efa6ad0-faa3-497c-bc5e-40a49bb05866
# ╠═03c183ae-83e6-4801-b471-4f64f4155d48
# ╟─26606497-b1df-4272-becd-58e0e273cf35
# ╠═cb94e825-4738-49e9-b45c-a29e86b555eb
# ╠═b1ff8c47-92ba-41d6-a268-7821b6a7e879
# ╟─63c11e41-5028-4b04-934c-0a74887e1459
# ╠═32dc6b96-077b-4291-85c0-ead273f5dc7a
# ╟─5a65e0f4-c4ee-40df-a3d7-f31e80767fd3
# ╠═6098fb5c-ec91-49af-9897-1836583493be
# ╟─2222c017-21d1-45ba-a5cc-c3a5f44b2721
# ╠═00a392d1-fa65-4ab5-863f-d4badd203f8e
