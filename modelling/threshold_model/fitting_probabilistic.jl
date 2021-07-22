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
	:figures => root * "/figures/",
	:export_composite => root * "/modelling/results/semantic_model_chain_composite.jls",
	:export_vague => root * "/modelling/results/semantic_model_chain_vague.jls",
	:export_conditionblind => root * "/modelling/results/semantic_model_chain_conditionblind.jls",
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

# ╔═╡ f08e885e-ae5e-4e27-876e-f56f754cb663
function run_chains(model_function, iterations)
	model = model_function(selections)
	sampler = PG(20)

	mapreduce(chainscat, 1:3) do chain
		sample(model, sampler, iterations) 
	end
end

# ╔═╡ 7f9e07df-dc39-4673-a88e-5c45097b682a
iterations = 1000

# ╔═╡ 2b70fd89-07c4-46b5-b5b8-3679336d786d
run_sampling = false

# ╔═╡ 286d06d1-8c2b-4e22-bd90-224187fb4773
#shoud chain be exported? (turn off for testing)
export_chain_results = true

# ╔═╡ ce453229-e629-4277-8804-d49ed97e6070
function get_chain_result(model_function, export_symbol)
	 if run_sampling
		res = run_chains(model_function, iterations)

		if export_chain_results
			write(paths[export_symbol], res)
		end

		res
	else
		read(paths[export_symbol], Chains)
	end
end

# ╔═╡ 2bf858aa-24b0-48f6-b442-ec860bbb949b
md"### Composite model"

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

# ╔═╡ c88b29a3-f0a5-4b5e-8a9d-024bf0a8315c
chains_composite = get_chain_result(semantic_model_composite, :export_composite)

# ╔═╡ d7f1822a-6d69-4e1d-bda1-6f30491f6565
describe(chains_composite)[1]

# ╔═╡ 054a8859-dff2-4588-8ac6-5f45c884a6d5
describe(chains_composite)[2]

# ╔═╡ 46c9adcd-9109-4539-b2fa-c0ca30a632f4
function plot_sampling(chain)
	p1 = meanplot(chain)
	p2 = density(chain)
	
	plot(p1, p2, layout = (1,2), size = (650, 600))
end

# ╔═╡ 38bc06e2-91f7-42df-b051-e0702df27969
plot_sampling(chains_composite)

# ╔═╡ 1882081e-e66b-40a1-995a-a1234265217f
function plot_parameter(chains, parameter; kwargs...)
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
		fill = 0, fillcolor = 3,
		xlabel = "value",
		ylabel = "density",
		legend = :none,
	)
	
	plot!(p; kwargs...)
	
	p
end

# ╔═╡ 2132a38d-c542-4948-997c-0f64065d7b5c
function plot_all_parameters(chain, parameters)
	n = length(parameters)
	
	subplots = map(parameters) do parameter
		plot_parameter(chain, parameter, title = parameter)
	end
	
	plot(subplots..., layout = (n, 1), size = (400, n * 200))
end

# ╔═╡ 3a3af14d-99b5-45c3-9ffb-5d90bc0de7c2
plot_all_parameters(chains_composite, [:λ, :c, :α])	

# ╔═╡ f7c0074e-af88-421d-aa05-2ca1cb254ddc
if "figures" ∈ readdir(root)
	for parameter in [:λ, :c, :α]
		p = plot_parameter(chains_composite, parameter)
		
		ascii_strings = Dict(:λ => "lambda", :c => "c", :α => "alpha")
		filename = "posterior_distribution_$(ascii_strings[parameter]).pdf"
		
		savefig(p, paths[:figures] * filename)
	end
	
	md"Figures saved!"
end

# ╔═╡ 61d2e82e-0bbf-468b-a57c-31ffe989ff22
md"""
### Vague model
"""

# ╔═╡ 0375e6e3-6880-4ac6-a862-052e9cab09ff
@model function semantic_model_vague(selections)
	#prior distribution of parameters
	λ ~ Uniform(1,250)
	c ~ Uniform(-1.0, 1.0)
	
	#get predictions based on the parameters
	predictions = mapreduce(vcat, eachrow(cases_overview)) do case
		#set up speaker model for this case
		scale_points = get_scale_points(case)
		prior = get_prior(case)
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

# ╔═╡ 37dfb41e-e323-4065-9081-1f5dbb6eb7c9
chains_vague = get_chain_result(semantic_model_vague, :export_vague)

# ╔═╡ 536ca01c-8f1c-4044-9ce3-7a79644bd585
describe(chains_vague)[1]

# ╔═╡ f6c85c5b-7e1e-48d8-8e4e-cb783d5878b7
describe(chains_vague)[2]

# ╔═╡ 33f61e3d-24b2-4e78-b149-75fb96d2cb4b
plot_sampling(chains_vague)

# ╔═╡ d022e51e-1eae-4797-8f99-f89ba66d45b6
plot_all_parameters(chains_vague, [:λ, :c])

# ╔═╡ 503660b8-28c1-4aa3-99fe-fdfc2002eeb0
md"""
### Condition-blind model
"""

# ╔═╡ c0213787-dd06-4e05-bf60-534b7b7794b1
function get_condition_blind_prior(case)
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

# ╔═╡ d0d06901-2854-4d2c-b54f-4c98905a5f60
@model function semantic_model_noconditions(selections)
	#prior distribution of parameters
	λ ~ Uniform(1,250)
	c ~ Uniform(-1.0, 1.0)

	
	#get predictions based on the parameters
	predictions = mapreduce(vcat, eachrow(cases_overview)) do case
		#set up speaker model for this case
		scale_points = get_scale_points(case)
		
		prior = get_condition_blind_prior(case)
		
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

# ╔═╡ 96e20e62-6fc3-48a3-8969-826995ba21e6
chains_noconditions = get_chain_result(semantic_model_noconditions, :export_conditionblind)

# ╔═╡ b5ea6e8b-b1de-4ed4-8533-8571a5cf2062
describe(chains_noconditions)[1]

# ╔═╡ 767fb62f-58bc-4339-8307-d7ed98172327
describe(chains_noconditions)[2]

# ╔═╡ ac267ba5-1d2f-4652-bbb4-ce756a767d75
plot_sampling(chains_noconditions)

# ╔═╡ 0be598ee-5a98-4a8a-9f16-370f62289369
plot_all_parameters(chains_noconditions, [:λ, :c])

# ╔═╡ 40028cea-72cb-45b1-b12e-1950bab1e046
md"""
## Plot predictions vs. data
"""

# ╔═╡ dd797a0b-47c2-4d2c-ac83-b877e9cb32dc
function get_interval(chains, parameter)
	data = quantile(chains, q = [0.025, 0.975])
	parameter_data= DataFrame(data[parameter])
	
	lower, upper = parameter_data[1, "2.5%"], parameter_data[1, "97.5%"]
end

# ╔═╡ 67755e76-51a9-4356-9667-c11703fec270
function predictions(case, speaker_model, chain; condition_blind = false)
	scale_points = get_scale_points(case)
	
	prior = if condition_blind
		get_condition_blind_prior(case)
	else
		get_prior(case)
	end
	
	#prediction with mean values of parameters
	
	median_parameters = if speaker_model == model.CompositeModel
		[
			median(chain[:λ]), 
			median(chain[:c]), 
			median(chain[:α])]
	else
		[
			median(chain[:λ]), 
			median(chain[:c])]	
	end
	
	median_speaker = speaker_model(median_parameters..., scale_points, prior)
	
	median_probs = map(scale_points) do d
		model.use_adjective(d, median_speaker)
	end
	
	# 95% confidence interval
	
	confidence_interval_95 = let
		parameter_bounds = if speaker_model == model.CompositeModel
			[(λ, c, α)
				for λ in get_interval(chain, :λ) 
				for c in get_interval(chain, :c)
				for α in get_interval(chain, :α)]
		else
			[(λ, c)
				for λ in get_interval(chain, :λ) 
				for c in get_interval(chain, :c)]
		end
		
		bounds_data = mapreduce(hcat, parameter_bounds) do parameters
			speaker = speaker_model(parameters..., scale_points, prior)
			probabilities = map(scale_points) do d
				model.use_adjective(d, speaker)
			end
		end
		
		n_items, n_configurations = size(bounds_data)
		
		lower_bounds = map(1:n_items) do i
			median_probs[i] - minimum(bounds_data[i, :]) 
		end
		
		upper_bounds = map(1:n_items) do i
			maximum(bounds_data[i, :]) - median_probs[i]
		end
		
		lower_bounds, upper_bounds
	end
	
	median_probs, confidence_interval_95
end

# ╔═╡ d1440025-dd2d-42dc-8f57-2a69db7bc58c


# ╔═╡ bc0e77d6-4b11-44a4-a909-77d15e411ac9
function plot_case_comparison(case, speaker_model, chain; condition_blind = false,
		kwargs...)
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
	
	mean_predictions, confidence_interval = predictions(case, speaker_model, chain, 
		condition_blind = condition_blind,)
	
	plot!(p,
		scale_points,
		mean_predictions,
		ribbon = confidence_interval,
		fillalpha = 0.75, fillcolor = pal[2],
		label = "predicted",
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

# ╔═╡ 3eb07cce-4e1d-4cf1-b4b6-5665c66204ac
function make_comparison_plot(speaker_model, chain; condition_blind = false)
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
		
		plot_case_comparison(case, speaker_model, chain,
			condition_blind = condition_blind,
			title = name, legend = nothing,
			titlefontsize = 12,
			guidefontsize = 9,
		)
	end
	
	subplots = plot(plots..., layout = (4,3), size = (1000, 900))
	
	legendplot = plot_case_comparison(
		last(cases_overview), speaker_model, chain, 
		condition_blind = condition_blind,
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

# ╔═╡ a1565fa6-08d1-411c-8779-3d7c6d83f7af
comparison_plot_composite = make_comparison_plot(model.CompositeModel, chains_composite)

# ╔═╡ c6b1be4b-0471-49c4-91ad-cb5e0a084a95
comparison_plot_vague = make_comparison_plot(model.VagueModel, chains_vague)

# ╔═╡ 5632c70f-6dc1-412a-8564-562557244d41
comparison_plot_conditionblind = make_comparison_plot(model.VagueModel, chains_noconditions, condition_blind = true)

# ╔═╡ 002fb827-a54c-41c4-86e5-18dbee13d96d
if "figures" ∈ readdir(root)
	savefig(comparison_plot_composite, 
		paths[:figures] * "semantic_model_comparison_composite.pdf")
	
	savefig(comparison_plot_vague, 
		paths[:figures] * "semantic_model_comparison_vague.pdf")
	
	savefig(comparison_plot_conditionblind, 
		paths[:figures] * "semantic_model_comparison_conditionblind.pdf")
	
	md"Figures saved!"
end

# ╔═╡ 6ce1d407-b9b7-4799-8357-7a8b8917e55d
md"""
## Model comparisons
"""

# ╔═╡ 5d8f8f9f-b4e5-4d13-8025-04024881efab
md"""
Compare the likelihood of the results for the composite and vague model, given the *best fit* values for each of the parameters. (Optimal parameter values are calculated in `fitting.jl`.)
"""

# ╔═╡ 723ab12f-2f66-45fe-934d-6fa6d4e9f16d
function data_posterior(chain)
	logevidence = chain[:logevidence]
	vector = reshape(logevidence, length(logevidence))
	
	probabilities = exp.(vector)
	
	mean(probabilities)
end

# ╔═╡ e4a9cc67-c321-4d46-b705-d3196ce3603e
P_evidence_composite = data_posterior(chains_composite)

# ╔═╡ 8302111d-be6e-4b6e-af0a-f66bdb270476
P_evidence_vague = data_posterior(chains_vague)

# ╔═╡ 6b4b5b36-fa48-4828-834d-935cbb277c38
P_evidence_conditionblind = data_posterior(chains_noconditions)

# ╔═╡ 96e84c2d-ca35-4ac6-982f-c6c558c4c7bc
md"""
Bayes factor of model $M_1$ compared to $M_2$ given data $D$

$K = \frac{P(D | M_1)}{P(D | M_2)}$

"""

# ╔═╡ b9c72945-1a9f-4ebc-a6c0-1c73469c44cf
P_evidence_conditionblind / P_evidence_composite

# ╔═╡ ca9e7644-615c-4ba1-9e4b-7b1d021124af
P_evidence_composite / P_evidence_vague

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
# ╠═f08e885e-ae5e-4e27-876e-f56f754cb663
# ╠═ce453229-e629-4277-8804-d49ed97e6070
# ╠═7f9e07df-dc39-4673-a88e-5c45097b682a
# ╠═2b70fd89-07c4-46b5-b5b8-3679336d786d
# ╠═286d06d1-8c2b-4e22-bd90-224187fb4773
# ╟─2bf858aa-24b0-48f6-b442-ec860bbb949b
# ╠═96de5fcc-7fc5-4171-ab26-62b685dcd007
# ╠═c88b29a3-f0a5-4b5e-8a9d-024bf0a8315c
# ╠═d7f1822a-6d69-4e1d-bda1-6f30491f6565
# ╠═054a8859-dff2-4588-8ac6-5f45c884a6d5
# ╠═46c9adcd-9109-4539-b2fa-c0ca30a632f4
# ╠═38bc06e2-91f7-42df-b051-e0702df27969
# ╠═1882081e-e66b-40a1-995a-a1234265217f
# ╠═2132a38d-c542-4948-997c-0f64065d7b5c
# ╠═3a3af14d-99b5-45c3-9ffb-5d90bc0de7c2
# ╠═f7c0074e-af88-421d-aa05-2ca1cb254ddc
# ╟─61d2e82e-0bbf-468b-a57c-31ffe989ff22
# ╠═0375e6e3-6880-4ac6-a862-052e9cab09ff
# ╠═37dfb41e-e323-4065-9081-1f5dbb6eb7c9
# ╠═536ca01c-8f1c-4044-9ce3-7a79644bd585
# ╠═f6c85c5b-7e1e-48d8-8e4e-cb783d5878b7
# ╠═33f61e3d-24b2-4e78-b149-75fb96d2cb4b
# ╠═d022e51e-1eae-4797-8f99-f89ba66d45b6
# ╟─503660b8-28c1-4aa3-99fe-fdfc2002eeb0
# ╠═c0213787-dd06-4e05-bf60-534b7b7794b1
# ╠═d0d06901-2854-4d2c-b54f-4c98905a5f60
# ╠═96e20e62-6fc3-48a3-8969-826995ba21e6
# ╠═b5ea6e8b-b1de-4ed4-8533-8571a5cf2062
# ╠═767fb62f-58bc-4339-8307-d7ed98172327
# ╠═ac267ba5-1d2f-4652-bbb4-ce756a767d75
# ╠═0be598ee-5a98-4a8a-9f16-370f62289369
# ╟─40028cea-72cb-45b1-b12e-1950bab1e046
# ╠═dd797a0b-47c2-4d2c-ac83-b877e9cb32dc
# ╠═67755e76-51a9-4356-9667-c11703fec270
# ╠═d1440025-dd2d-42dc-8f57-2a69db7bc58c
# ╠═bc0e77d6-4b11-44a4-a909-77d15e411ac9
# ╠═3eb07cce-4e1d-4cf1-b4b6-5665c66204ac
# ╠═a1565fa6-08d1-411c-8779-3d7c6d83f7af
# ╠═c6b1be4b-0471-49c4-91ad-cb5e0a084a95
# ╠═5632c70f-6dc1-412a-8564-562557244d41
# ╠═002fb827-a54c-41c4-86e5-18dbee13d96d
# ╟─6ce1d407-b9b7-4799-8357-7a8b8917e55d
# ╟─5d8f8f9f-b4e5-4d13-8025-04024881efab
# ╠═723ab12f-2f66-45fe-934d-6fa6d4e9f16d
# ╠═e4a9cc67-c321-4d46-b705-d3196ce3603e
# ╠═8302111d-be6e-4b6e-af0a-f66bdb270476
# ╠═6b4b5b36-fa48-4828-834d-935cbb277c38
# ╟─96e84c2d-ca35-4ac6-982f-c6c558c4c7bc
# ╠═b9c72945-1a9f-4ebc-a6c0-1c73469c44cf
# ╠═ca9e7644-615c-4ba1-9e4b-7b1d021124af
