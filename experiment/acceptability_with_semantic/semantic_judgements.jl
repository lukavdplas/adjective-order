### A Pluto.jl notebook ###
# v0.14.5

using Markdown
using InteractiveUtils

# ╔═╡ 0c33a28a-2419-452c-bb7f-62e0b068418a
begin
    import Pkg
    Pkg.activate("../..")

    try
		
	catch
		Pkg.instantiate()
		using CSV, DataFrames, Plots, Statistics
	end

	theme(:wong, legend=:outerright)
end

# ╔═╡ ace7cca0-a2c2-40f2-a6c4-29f88bfc6e58
md"""
# Semantic judgements

Results on the semantic judgement task
"""

# ╔═╡ f29b7732-246f-4947-bf15-a3ae6d99682e
md"""
## Import
"""

# ╔═╡ 8358c692-93b8-11eb-20cc-7ff7a8a3ed34
results = CSV.read("results/results_filtered.csv", DataFrame) ;

# ╔═╡ 14e4583e-e403-43f5-ac84-68650cba71db
stimuli_data = CSV.read("materials/stimuli_data.csv", DataFrame)

# ╔═╡ 0e54595b-f569-4201-b355-5ae56f3ddfa8
semantic_results = results[results.item_type .== "semantic", :]

# ╔═╡ c9718d2e-21e9-4379-8ce7-0c0d6a97ca2f
md"""
## Selection probabilities
"""

# ╔═╡ d73c5f6c-b5b5-41b2-8af4-2ec7bab6f747
function selection_probability(stimulus_id::String, data::DataFrame)
	stimulus_data = data[data.id .== stimulus_id, :]
	
	responses = parse.(Bool, stimulus_data.response)
	
	count(responses) / length(responses)
end

# ╔═╡ 21bd0056-f2f3-4a25-9919-2a30a59a73bc
function get_bounds(adjective, scenario)
	if adjective == "big"
		return (0, 100)
	elseif adjective == "long"
		return (0, 150)
	elseif scenario == "tv" #so adjective == "expensive" must be true
		return (0, 5000)
	else
		return (0, 1500)
	end
end

# ╔═╡ 5fb90c52-f4eb-40be-81b7-2f86019f2e9c
md"""
## Threshold estimation

Estimate the location of the threshold for each participant. 

In the example of *"big"*, I base the threshold value for a participant on the lowest measure in the sample that they classified as *"big"*. The threshold is the midpoint between that value and the next one below it.
"""

# ╔═╡ 57070425-5937-466e-b540-2ead9d2a6199
function estimate_threshold(responses, measures)
	responses = parse.(Bool, responses)
	judgements = (collect ∘ zip)(responses, measures)
	
	selected = filter(judgements) do (response, measure)
		response
	end
	
	lowest_selected = minimum(selected) do (response, measure)
		measure
	end
	
	under_threshold = filter(judgements) do (response, measure)
		measure < lowest_selected
	end
	
	highest_under_threshold = maximum(under_threshold) do (response, measure)
		measure
	end
	
	threshold = mean([lowest_selected, highest_under_threshold])
end

# ╔═╡ 820a79b9-b295-43aa-8bd0-cce8d8ba76ba
md"""
## Stimuli descriptives & histogram
"""

# ╔═╡ d37b5466-1322-4c80-a824-20ff555588c8
function all_descriptives(scenario)
	data = filter(row -> row.scenario == scenario, stimuli_data)
	
	sizes_unimodal = data[data.unimodal, :size]
	prices_unimodal = data[data.unimodal, :price]
	sizes_bimodal = data[data.bimodal, :size]
	threshold = scenario == "tv" ? 50 : 80
	sizes_bimodal_low = let
		items = filter(data) do row
			row.bimodal && (row.size < threshold)
		end
		items.size
	end
	sizes_bimodal_high = let
		items = filter(data) do row
			row.bimodal && (row.size > threshold)
		end
		items.size
	end
	prices_bimodal = data[data.bimodal, :price]
	
	data_per_cat = DataFrame(
		value = [prices_unimodal ; prices_bimodal ; 
			sizes_unimodal ; sizes_bimodal ;
			sizes_bimodal_low ; sizes_bimodal_high],
		category = [
			repeat(["prices_unimodal"], length(prices_unimodal));
			repeat(["prices_bimodal"], length(prices_bimodal));
			repeat(["sizes_unimodal"], length(sizes_unimodal));
			repeat(["sizes_bimodal"], length(sizes_bimodal));
			repeat(["sizes_bimodal_low"], length(sizes_bimodal_low));
			repeat(["sizes_bimodal_high"], length(sizes_bimodal_high))
		]
	)
	
	combine(groupby(data_per_cat, :category),
		:value => mean,
		:value => std,
		:value => median
	)
end

# ╔═╡ e8bd45b7-e8bd-4b48-bb67-3dab6e9dc8c3
all_descriptives("tv")

# ╔═╡ 4f12bc36-da4f-49bf-87d0-46d4ff500431
all_descriptives("couch")

# ╔═╡ dcef9229-6f95-40f9-b3ac-93aca1ba117c
md"""
## Plots
"""

# ╔═╡ f36af399-85f5-4852-9782-acd32b0a6acb
md"**Selection of 'expensive' for TVs**"

# ╔═╡ cb65bdec-5b60-401f-9190-94dddefb38f5
md"**Selection of 'big' for TVs**"

# ╔═╡ 38300334-c653-4481-895c-be6aa49c0ddb
md"**Selection of 'expensive' for couches**"

# ╔═╡ 28b5e4c2-62c0-482d-91bc-14e85c6bc100
md"**Selection of 'long' for couches**"

# ╔═╡ fc676ddd-da2c-4ced-a757-c98e33f8fad3
md"## Export plots"

# ╔═╡ a3a9b479-cb0b-49e3-a710-0a0b13c1312d
md"""
## General functions
"""

# ╔═╡ 9262a9cc-3edc-46e8-b47b-c643467a990f
function get_scale(adjective)
	if adjective == "expensive"
		"price"
	else
		"size"
	end
end

# ╔═╡ 653a596d-ada1-4901-a999-70f827a4766f
function threshold(adjectives, responses, sizes, prices)
	scale = (get_scale ∘ first)(adjectives)
	
	measures = scale == "price" ? prices : sizes
	
	estimate_threshold(responses, measures)
end

# ╔═╡ 4d9f6cf7-9c45-44b5-a7fa-90f5b49004fc
threshold_results = combine(
	groupby(semantic_results, [:adj_target, :scenario, :condition, :participant]),
	[:adj_target, :response, :stimulus_size, :stimulus_price] => threshold => "threshold"
)

# ╔═╡ 5a7e5a60-29f9-414e-bada-f7787ba61b18
scale_label(scale) = scale == "size" ? "size (inches)" : "price (\$)"

# ╔═╡ 8842788c-177d-418a-9578-3ee5e0466c39
function plot_selection_results(adjective, scenario, condition = nothing; kwargs...)
	scale = get_scale(adjective)
	
	data = filter(semantic_results) do row
		all([
			row.adj_target == adjective,
			row.scenario == scenario,
			isnothing(condition) || (row.condition == condition),
			])
	end
	
	colname = "stimulus_" * scale
	
	measures = (sort ∘ unique)(data[:, colname ])
	
	probabilities = map(measures) do value
		items =  filter(data) do row
			row[colname] == value
		end
		responses = parse.(Bool, items.response)
		count(responses) / length(responses)
	end
	
	plot(measures, probabilities,
		fill = 0, linecolor = :black,
		ylims = (0,1), 
		xlims = get_bounds(adjective, scenario),
		label = nothing,
		ylabel = "P(selected | $(scale))",
		xlabel = scale_label(scale);
		kwargs...
	)
end

# ╔═╡ 83e46121-1ced-4dd2-b733-3d9966fec148
function plot_thresholds(adjective, scenario, condition = nothing)
	scale = get_scale(adjective)
	
	subdata = filter(threshold_results) do row
		all([
				row.adj_target == adjective, 
				row.scenario == scenario,
				isnothing(condition) || (row.condition == condition)
				])
	end
	
	thresholds = subdata.threshold
	
	measures = let
		data = filter(stimuli_data) do row
			all([
				row.scenario == scenario,
				isnothing(condition) || (row[condition])
				])
		end

		measures = data[:, scale]
		(sort ∘ unique)(measures)
	end
	
	histogram(thresholds,
		bins = measures,
		#normalize = true,
		fill = 0,
		xlims = get_bounds(adjective, scenario),
		label = nothing,
		ylabel = "N(threshold | $(scale))",
		xlabel = scale_label(scale)
	)
end

# ╔═╡ 17913ee9-5b69-425d-9ab0-fee4a29e4832
function plot_sample_histogram(adjective, scenario, condition = "bimodal"; kwargs...)
	scale = get_scale(adjective)
	
	data = filter(stimuli_data) do row
		all([
			row.scenario == scenario,
			(row[condition] == true),
			])
	end
	
	measures = data[:, scale]
	
	histogram(measures,
		bins = 25,
		color = 2,
		fill = 0,
		label = nothing;
		xlabel = scale_label(scale),
		ylabel = "N($(scale))",
		xlims = get_bounds(adjective, scenario)
	)
end

# ╔═╡ 8e27b617-b904-4eef-86a3-38560e7bac73
plot(
	#plot_selection_results("expensive", "tv"),
	plot_thresholds("expensive", "tv"),
	plot_sample_histogram("expensive", "tv"),
	layout = (2,1)
)

# ╔═╡ 2d164b37-4da8-45ba-836e-510a2c42d05e
let
	plot(
		#plot_selection_results("big", "tv", "unimodal", title = "unimodal"),
		#plot_selection_results("big", "tv", "bimodal", title = "bimodal"),
		plot_thresholds("big", "tv", "unimodal"),
		plot_thresholds("big", "tv", "bimodal"),
		plot_sample_histogram("big", "tv", "unimodal"),
		plot_sample_histogram("big", "tv", "bimodal"),
		layout = (2,2))
end

# ╔═╡ aa2655d1-2c8b-443a-9439-e636498f125e
plot(
	#plot_selection_results("expensive", "couch"),
	plot_thresholds("expensive", "couch"),
	plot_sample_histogram("expensive", "couch"),
	layout = (2,1)
)

# ╔═╡ afc58be4-6e79-424a-bfb7-0d94ec4e5130
let
	plot(
		#plot_selection_results("long", "couch", "unimodal", title = "unimodal"),
		#plot_selection_results("long", "couch", "bimodal", title = "bimodal"),
		plot_thresholds("long", "couch", "unimodal"),
		plot_thresholds("long", "couch", "bimodal"),
		plot_sample_histogram("long", "couch", "unimodal"),
		plot_sample_histogram("long", "couch", "bimodal"),
		layout = (2,2))
end

# ╔═╡ a10dd3a6-0f95-4bc0-8807-47bfadb52535
for scenario in ["tv", "couch"]
	adj_target = scenario == "tv" ? "big" : "long"
	for adjective in [adj_target, "expensive"]
		for condition in ["bimodal", "unimodal"]
			p = plot_sample_histogram(adjective, scenario, condition)
			scale = get_scale(adjective)
			path = "../../figures/stimuli_histogram_$(scenario)_$(scale)_$(condition).pdf"
			savefig(p, path)
		end
	end
end

# ╔═╡ Cell order:
# ╟─ace7cca0-a2c2-40f2-a6c4-29f88bfc6e58
# ╟─f29b7732-246f-4947-bf15-a3ae6d99682e
# ╠═0c33a28a-2419-452c-bb7f-62e0b068418a
# ╠═8358c692-93b8-11eb-20cc-7ff7a8a3ed34
# ╠═14e4583e-e403-43f5-ac84-68650cba71db
# ╠═0e54595b-f569-4201-b355-5ae56f3ddfa8
# ╟─c9718d2e-21e9-4379-8ce7-0c0d6a97ca2f
# ╠═d73c5f6c-b5b5-41b2-8af4-2ec7bab6f747
# ╠═21bd0056-f2f3-4a25-9919-2a30a59a73bc
# ╠═8842788c-177d-418a-9578-3ee5e0466c39
# ╟─5fb90c52-f4eb-40be-81b7-2f86019f2e9c
# ╠═57070425-5937-466e-b540-2ead9d2a6199
# ╠═653a596d-ada1-4901-a999-70f827a4766f
# ╠═4d9f6cf7-9c45-44b5-a7fa-90f5b49004fc
# ╠═83e46121-1ced-4dd2-b733-3d9966fec148
# ╟─820a79b9-b295-43aa-8bd0-cce8d8ba76ba
# ╠═d37b5466-1322-4c80-a824-20ff555588c8
# ╠═e8bd45b7-e8bd-4b48-bb67-3dab6e9dc8c3
# ╠═4f12bc36-da4f-49bf-87d0-46d4ff500431
# ╠═17913ee9-5b69-425d-9ab0-fee4a29e4832
# ╟─dcef9229-6f95-40f9-b3ac-93aca1ba117c
# ╟─f36af399-85f5-4852-9782-acd32b0a6acb
# ╠═8e27b617-b904-4eef-86a3-38560e7bac73
# ╟─cb65bdec-5b60-401f-9190-94dddefb38f5
# ╠═2d164b37-4da8-45ba-836e-510a2c42d05e
# ╟─38300334-c653-4481-895c-be6aa49c0ddb
# ╠═aa2655d1-2c8b-443a-9439-e636498f125e
# ╟─28b5e4c2-62c0-482d-91bc-14e85c6bc100
# ╠═afc58be4-6e79-424a-bfb7-0d94ec4e5130
# ╟─fc676ddd-da2c-4ced-a757-c98e33f8fad3
# ╠═a10dd3a6-0f95-4bc0-8807-47bfadb52535
# ╟─a3a9b479-cb0b-49e3-a710-0a0b13c1312d
# ╠═9262a9cc-3edc-46e8-b47b-c643467a990f
# ╠═5a7e5a60-29f9-414e-bada-f7787ba61b18
