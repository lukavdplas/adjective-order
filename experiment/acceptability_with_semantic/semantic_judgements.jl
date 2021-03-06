### A Pluto.jl notebook ###
# v0.14.7

using Markdown
using InteractiveUtils

# ╔═╡ 0c33a28a-2419-452c-bb7f-62e0b068418a
begin
    import Pkg
	root = "../.."
    Pkg.activate(root)

    try
		using CSV, DataFrames, Plots, Statistics
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
function selection_probability(stimulus_id::String, data)
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

# ╔═╡ c4289d3a-7548-4ae1-9c1e-c2415126093b
md"**Histograms**"

# ╔═╡ af597df9-dce9-4b35-b16a-d1457ca9608c
md"**Semantic results**"

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

# ╔═╡ 5a7e5a60-29f9-414e-bada-f7787ba61b18
scale_label(scale) = scale == "size" ? "size (inches)" : "price (\$)"

# ╔═╡ 9b784865-8b1b-44ce-828b-4454e5543100
function get_colour(condition)
	if condition == "bimodal"
		1
	elseif condition == "unimodal"
		2
	else
		3
	end
end

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
	
	bounds = get_bounds(adjective, scenario)

	plot(
		[measures; bounds[2]], 
		[probabilities; probabilities[end]],
		linetype = :steppost,
		fill = 0, 
		linecolor = :black, fillcolor = get_colour(condition),
		ylims = (0,1), 
		xlims = bounds,
		label = nothing,
		ylabel = "P(selected | $(scale))",
		xlabel = scale_label(scale);
		kwargs...
	)
end

# ╔═╡ 17913ee9-5b69-425d-9ab0-fee4a29e4832
function plot_sample_histogram(adjective, scenario, condition = nothing; kwargs...)
	scale = get_scale(adjective)
	
	data = filter(stimuli_data) do row
		if !isnothing(condition)
			row.scenario == scenario && (row[condition] == true)
		else
			row.scenario == scenario && row["bimodal"] == true
		end
	end
	
	measures = data[:, scale]
	
	histogram(measures,
		bins = 25,
		color = 2,
		fill = 0, fillcolor = get_colour(condition),
		label = nothing;
		xlabel = scale_label(scale),
		ylabel = "N($(scale))",
		xlims = get_bounds(adjective, scenario)
	)
end

# ╔═╡ 8e27b617-b904-4eef-86a3-38560e7bac73
plot(
	plot_selection_results("expensive", "tv"),
	plot_sample_histogram("expensive", "tv"),
	layout = (2,1)
)

# ╔═╡ 2d164b37-4da8-45ba-836e-510a2c42d05e
let
	plot(
		plot_selection_results("big", "tv", "unimodal", title = "unimodal"),
		plot_selection_results("big", "tv", "bimodal", title = "bimodal"),
		plot_sample_histogram("big", "tv", "unimodal"),
		plot_sample_histogram("big", "tv", "bimodal"),
		layout = (2,2))
end

# ╔═╡ aa2655d1-2c8b-443a-9439-e636498f125e
plot(
	plot_selection_results("expensive", "couch"),
	plot_sample_histogram("expensive", "couch"),
	layout = (2,1)
)

# ╔═╡ afc58be4-6e79-424a-bfb7-0d94ec4e5130
let
	plot(
		plot_selection_results("long", "couch", "unimodal", title = "unimodal"),
		plot_selection_results("long", "couch", "bimodal", title = "bimodal"),
		plot_sample_histogram("long", "couch", "unimodal"),
		plot_sample_histogram("long", "couch", "bimodal"),
		layout = (2,2))
end

# ╔═╡ a10dd3a6-0f95-4bc0-8807-47bfadb52535
if "figures" ∈ readdir(root)
	for scenario in ["tv", "couch"]
		adj_target = scenario == "ball" ? "big" : "long"
		for adjective in [adj_target, "expensive"]
			for condition in ["bimodal", "unimodal"]
				p = plot_sample_histogram(adjective, scenario, condition)
				scale = get_scale(adjective)
				path = root * "/figures/stimuli_histogram_$(scenario)_$(scale)_$(condition).pdf"
				savefig(p, path)
			end
		end
		
		adjective = "expensive"
		if scenario == "couch"
			for condition in ["bimodal", "unimodal"]
				p = plot_sample_histogram(adjective, scenario, condition)
				scale = get_scale(adjective)
				path = root * "/figures/stimuli_histogram_$(scenario)_$(scale)_$(condition).pdf"
				savefig(p, path)
			end
		else
			p = plot_sample_histogram(adjective, scenario)
			scale = get_scale(adjective)
			path = root * "/figures/stimuli_histogram_$(scenario)_$(scale).pdf"
			savefig(p, path)
		end
	end
	
	md"Histograms saved!"
else
	md"No figures folder"
end

# ╔═╡ 2be094ea-930f-4ff5-9279-3a800e0ea457
if "figures" ∈ readdir(root)
	for scenario in ["tv", "couch"]
		#big/long
		adjective = scenario == "tv" ? "big" : "long"
		for condition in ["bimodal", "unimodal"]
			p = plot(
				plot_selection_results(adjective, scenario, condition),
				plot_sample_histogram(adjective, scenario, condition),
				layout = grid(2,1, heights=[0.75, 0.25]),
				size = (400, 400)
			)
			scale = get_scale(adjective)
			path = root * "/figures/semantic_results_$(scenario)_$(scale)_$(condition).pdf"
			savefig(p, path)
		end
		
		#expensive
		adjective = "expensive"
		p = plot(
			plot_selection_results(adjective, scenario),
			plot_sample_histogram(adjective, scenario),
			layout = grid(2,1, heights=[0.75, 0.25]),
			size = (400, 400)
		)
		scale = get_scale(adjective)
		path = root * "/figures/semantic_results_$(scenario)_$(scale).pdf"
		savefig(p, path)			
	end

	md"Semantic results saved!"
else
	md"No figures folder"
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
# ╟─c4289d3a-7548-4ae1-9c1e-c2415126093b
# ╠═a10dd3a6-0f95-4bc0-8807-47bfadb52535
# ╟─af597df9-dce9-4b35-b16a-d1457ca9608c
# ╠═2be094ea-930f-4ff5-9279-3a800e0ea457
# ╟─a3a9b479-cb0b-49e3-a710-0a0b13c1312d
# ╠═9262a9cc-3edc-46e8-b47b-c643467a990f
# ╠═5a7e5a60-29f9-414e-bada-f7787ba61b18
# ╠═9b784865-8b1b-44ce-828b-4454e5543100
