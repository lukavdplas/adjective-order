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
		using CSV, DataFrames, Distributions, Plots, PlutoUI, Statistics, Optim
	catch
		Pkg.instantiate()
		using CSV, DataFrames, Distributions, Plots, PlutoUI, Statistics, Optim
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
	:results => root * "/modelling/results/results_with_disagreement.csv"
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

# ╔═╡ 7584a0da-c1ef-46c2-a29f-14be4a607f97
md"""
Now we need one more thing.

The semantic requires a cumulative and density function for the prior distribution. The functions `pdf` and `cdf` do exactly that, but it's more convenient to write them as unary functions.

For the density, we also need to make a small change: since we use discrete probabilities and the step sizes are not equal to 1, we need to rescale the density.
"""

# ╔═╡ 2da5f80d-cc6a-476d-93e8-e9aca99f2634
function get_cumulative(case)
	prior = get_prior(case)
	cumulative(x) = cdf(prior, x)
end

# ╔═╡ 3183d56d-2fc9-413c-87ed-80d8ebe48b2c
function get_density(case)
	prior = get_prior(case)
	scale_points = get_scale_points(case)
	
	step_size = scale_points.step
	
	density(x) = pdf(prior, x) * step_size
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
		:response => selection_rate => "ratio_selected"
	)
	
	sorted = sort(combined, :degree)
end

# ╔═╡ 944137fc-f136-4ad5-bd0a-df8189249b31
let
	case = last(eachrow(cases_overview))
	get_results(case)
end

# ╔═╡ b4ac858b-df06-4946-b3e2-5eb9d3541962
md"""
## Fitting

The model depends on two parameters, $\lambda$ and $c$. For a configuration of these parameters, we want to calculate how far off the model is from the real data.
 

For each case, we estimate the `use_adjective` probability function based on the prior distribution, and then compare it to the selection probabilities. I use the mean square error (MSE) compare the predictions to the observed values.
"""

# ╔═╡ 088db32d-cdfc-4105-aaaa-1cc51b812c72
function MSE_per_case(parameters, case)
	λ, coverage = parameters
	
	scale_points = get_scale_points(case)
	density = get_density(case)
	cumulative = get_cumulative(case)
	results = get_results(case)
	
	θ_probabilities = map(scale_points) do θ
		model.probability_threshold(θ, λ, coverage,
			scale_points, density, cumulative)
	end
		
	p_predicted = map(results.degree) do d
		model.use_adjective(d, θ_probabilities, scale_points)
	end
	
	p_observed = results.ratio_selected
	
	squared_errors = (p_predicted .- p_observed).^2
	mean(squared_errors)
end

# ╔═╡ 12f9a8ef-f2f9-4e14-aab1-a7f89c1bcd10
function MSE(parameters)
	errors = map(eachrow(cases_overview)) do case
		MSE_per_case(parameters, case)
	end
	
	mean(errors)
end

# ╔═╡ 2226afd3-aa95-4b9e-9d5b-8addf7b69854
md"""
Now we can find the values of λ and $c$ that minimise the error.
"""

# ╔═╡ 43e46e4e-9c9f-452b-91e1-38921ff65881
initial_values = [50.0, 0.0]

# ╔═╡ 705af09d-7f4f-496c-ac89-29fd461bae4f
opt_result = let
	optimize(MSE,
		initial_values
	)
end

# ╔═╡ 0bc81ff1-b5e5-4fff-af12-19c41c750dcd
optimal_λ, optimal_coverage = Optim.minimizer(opt_result)

# ╔═╡ 057d3937-0da3-42b6-b051-6c1c477740b9
let
	λ = round(optimal_λ, digits = 1)
	c = round(optimal_coverage, digits = 3)
	mse = round(Optim.minimum(opt_result), digits= 3)
	
	md"""
	Optimal parameters are $\lambda$ = $λ 
	
	and $c$ = $c
	
	Mean square error: $(mse)
	"""
end

# ╔═╡ 00a3912f-7b63-4338-ac25-a44cca17e2db
md"""
Plot the predictions and observations together:
"""

# ╔═╡ f5c6b055-2b00-4297-9dde-5a58f78630a4
function plot_case_comparsion(case, λ, coverage; kwargs...)
	p = plot(
		ylabel = "P",
		xlabel = "degree",
	)
	
	#get predicted selection probabilities
	
	scale_points = get_scale_points(case)
	density = get_density(case)
	cumulative = get_cumulative(case)
	results = get_results(case)
	
	θ_probabilities = map(scale_points) do θ
		model.probability_threshold(θ, λ, coverage,
			scale_points, density, cumulative)
	end
	
	p_predicted = map(scale_points) do d
		model.use_adjective(d, θ_probabilities, scale_points)
	end
	
	plot!(p,
		scale_points,
		p_predicted,
		label = "predicted"
	)
	
	scatter!(p,
		results.degree,
		results.ratio_selected,
		label = "observed"
	)
	
	plot!(p; kwargs...)
end

# ╔═╡ 43300428-161a-4ec1-9dc4-e3159ee675ba
let
	plots = map(eachrow(cases_overview)) do case
		name = join([case.adj_target, case.scenario, case.condition], ", ")
		plot_case_comparsion(case, optimal_λ, optimal_coverage,
			title = name, legend = nothing,
			titlefontsize = 12
		)
	end
	
	p = plot(plots..., layout = (4,3), size = (1000, 800))
end

# ╔═╡ e9e955b5-f663-446e-a756-74043c0955a7
md"""
### Fit parameters per case

Try fitting the parameters for each case instead of estimating them globally.
"""

# ╔═╡ f99f0abf-cbc7-483b-9507-e3221988f872
opt_results_per_case = map(eachrow(cases_overview)) do case
	case_MSE(parameters) = MSE_per_case(parameters, case)
	
	opt_result = let
		optimize(case_MSE,
			initial_values
		)
	end
end

# ╔═╡ 7ebd8837-2d2f-49fe-a15b-faf4fa67258e
result_summaries = map(opt_results_per_case) do res
	opt_λ, opt_c = Optim.minimizer(res)
	mse = Optim.minimum(res)
	
	summary = Dict(:λ => opt_λ, :coverage => opt_c, :MSE => mse)
end

# ╔═╡ 1c147ed6-51d8-4f8b-915b-489de896a597
let
	subplots = map([:λ, :coverage, :MSE]) do variable
		values = map(res -> res[variable], result_summaries)
		
		histogram(values, bins = 20, legend = :none, title = variable)
	end
	
	plot(subplots..., layout = (3,1))
end

# ╔═╡ 2f265b25-937e-4b9d-bf6e-75fa42197813
let
	cases_results = zip(eachrow(cases_overview), result_summaries)
	
	plots = map(cases_results) do (case, result)	
		λ = result[:λ]
		coverage = result[:coverage]
		
		name = join([case.adj_target, case.scenario, case.condition], ", ")
		plot_case_comparsion(case, λ, coverage,
			title = name, legend = nothing,
			titlefontsize = 12
		)
	end
	
	p = plot(plots..., layout = (4,3), size = (1000, 800))
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
# ╟─7584a0da-c1ef-46c2-a29f-14be4a607f97
# ╠═2da5f80d-cc6a-476d-93e8-e9aca99f2634
# ╠═3183d56d-2fc9-413c-87ed-80d8ebe48b2c
# ╟─ada1c503-8664-4611-bc0a-3c6ce0a41602
# ╟─284bf321-935c-421e-8183-eeae4e3fae89
# ╠═74231275-a5ad-4b1d-a606-af9344b55f33
# ╠═944137fc-f136-4ad5-bd0a-df8189249b31
# ╟─b4ac858b-df06-4946-b3e2-5eb9d3541962
# ╠═088db32d-cdfc-4105-aaaa-1cc51b812c72
# ╠═12f9a8ef-f2f9-4e14-aab1-a7f89c1bcd10
# ╟─2226afd3-aa95-4b9e-9d5b-8addf7b69854
# ╠═43e46e4e-9c9f-452b-91e1-38921ff65881
# ╠═705af09d-7f4f-496c-ac89-29fd461bae4f
# ╠═0bc81ff1-b5e5-4fff-af12-19c41c750dcd
# ╟─057d3937-0da3-42b6-b051-6c1c477740b9
# ╟─00a3912f-7b63-4338-ac25-a44cca17e2db
# ╠═f5c6b055-2b00-4297-9dde-5a58f78630a4
# ╠═43300428-161a-4ec1-9dc4-e3159ee675ba
# ╟─e9e955b5-f663-446e-a756-74043c0955a7
# ╠═f99f0abf-cbc7-483b-9507-e3221988f872
# ╠═7ebd8837-2d2f-49fe-a15b-faf4fa67258e
# ╠═1c147ed6-51d8-4f8b-915b-489de896a597
# ╠═2f265b25-937e-4b9d-bf6e-75fa42197813
