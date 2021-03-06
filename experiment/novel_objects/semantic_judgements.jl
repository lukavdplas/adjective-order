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

# ╔═╡ 734de216-874c-47e4-ab20-871aca0ee6e4
md"""
## Filter data

Function for filterting data further. This is needed when I calculate the threshold value for each participant.

Only include the data for a participant/adjective/scenario combination if the participant's responses were monotonous. That is, if they selected an item as "big", they must also have selected all larger items as well.

My definition is loose on items of equal size because that makes the calculation easier. This is also not as important.
"""

# ╔═╡ cbb00ae3-7727-4caf-89be-adcb1af27c35
function is_monotonic(sequence::Array{Bool})
	if all(sequence) || !any(sequence)
		true
	else
		!(sequence[1]) && is_monotonic(sequence[2:end])
	end
end

# ╔═╡ c9718d2e-21e9-4379-8ce7-0c0d6a97ca2f
md"""
## Selection probabilities
"""

# ╔═╡ 21bd0056-f2f3-4a25-9919-2a30a59a73bc
function get_bounds(adjective, scenario)
	if adjective == "big"
		return (0, 20)
	elseif adjective == "long"
		return (0, 40)
	else #so adjective == "expensive" must be true
		return (0, 22)
	end
end

# ╔═╡ 820a79b9-b295-43aa-8bd0-cce8d8ba76ba
md"""
## Stimuli descriptives & histogram
"""

# ╔═╡ c6b20706-0115-4602-98ee-d7e22e986fec
function all_descriptives(scenario)
	data = filter(row -> row.scenario == scenario, stimuli_data)
	
	sizes_unimodal = data[data.unimodal, :size]
	prices = data[data.unimodal, :price]
	sizes_bimodal = data[data.bimodal, :size]
	threshold = scenario == "ball" ? 10 : 20
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
	
	data_per_cat = DataFrame(
		value = [prices ; sizes_unimodal ; sizes_bimodal ;
			sizes_bimodal_low ; sizes_bimodal_high],
		category = [
			repeat(["prices"], length(prices));
			repeat(["sizes_unimodal"], length(sizes_unimodal));
			repeat(["sizes_bimodal"], length(sizes_bimodal));
			repeat(["sizes_bimodal_low"], length(sizes_bimodal_low));
			repeat(["sizes_bimodal_high"], length(sizes_bimodal_high))
		]
	)
	
	combine(groupby(data_per_cat, :category),
		:value => mean,
		:value => std,
	)
end

# ╔═╡ 93c41a8a-d25c-4efa-b860-adcee8cc9c89
all_descriptives("ball")

# ╔═╡ a6abf963-0ca0-4089-b36b-67869a1b363b
all_descriptives("spring")

# ╔═╡ dcef9229-6f95-40f9-b3ac-93aca1ba117c
md"""
## Plots
"""

# ╔═╡ f36af399-85f5-4852-9782-acd32b0a6acb
md"**Selection of 'expensive' for balls**"

# ╔═╡ cb65bdec-5b60-401f-9190-94dddefb38f5
md"**Selection of 'big' for balls**"

# ╔═╡ 38300334-c653-4481-895c-be6aa49c0ddb
md"**Selection of 'expensive' for springs**"

# ╔═╡ 28b5e4c2-62c0-482d-91bc-14e85c6bc100
md"**Selection of 'long' for springs**"

# ╔═╡ 4913f741-6f04-4bf8-8844-cc0a42a6d08b
md"""
### Export plots
"""

# ╔═╡ e4a7961e-5f32-4e6c-be46-264520ccd421
md"**Histograms**"

# ╔═╡ b551c9be-6a03-4a09-8e88-cf620f47e36b
md"**Selection probabilities**"

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

# ╔═╡ cc3b7a32-f0c5-4a0a-a708-e0b382f7e90a
function include_data(data)	
	adjective = first(data.adj_target)
	scale_column = "stimulus_" * get_scale(adjective)
	sorted_data = sort(data, scale_column)
	responses = let
		values = sorted_data.response
		bool_array = collect(values .== "true")
	end
	is_monotonic(responses)
end

# ╔═╡ 38232c1a-6f47-443c-8cdf-c281fe89dbf5
filtered_results = let
	filtered = filter(
		include_data,
		groupby(semantic_results, [:participant, :adj_target, :scenario])
	)
	
	combine(filtered, names(filtered), keepkeys = true)
end

# ╔═╡ 5a7e5a60-29f9-414e-bada-f7787ba61b18
scale_label(scale) = scale == "size" ? "size (cm)" : "price (\$)"

# ╔═╡ e4189dd6-725e-4153-a6ca-5af9391d57c9
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
		conditioncol = isnothing(condition) ? "bimodal" : condition
		all([
			row.scenario == scenario,
			(row[conditioncol] == true),
			])
	end
	
	measures = data[:, scale]
	
	nbins = if (adjective == "long") && (scenario == "spring")
		maximum(get_bounds(adjective, scenario)) + 1
	else
		maximum(get_bounds(adjective, scenario)) * 2 + 1
	end
	
	max_count = maximum(unique(measures)) do size
		count(item -> item == size, measures)
	end
	
	histogram(measures,
		bins = nbins,
		color = 2,
		fill = 0, fillcolor = get_colour(condition),
		label = nothing;
		xlabel = scale_label(scale),
		ylabel = "N($(scale))",
		yticks = 1:max_count,
		xlims = get_bounds(adjective, scenario)
	)
end

# ╔═╡ 8e27b617-b904-4eef-86a3-38560e7bac73
plot(
	plot_selection_results("expensive", "ball"),
	plot_sample_histogram("expensive", "ball"),
	layout = (2,1)
)

# ╔═╡ 2d164b37-4da8-45ba-836e-510a2c42d05e
let
	plot(
		plot_selection_results("big", "ball", "unimodal", title = "unimodal"),
		plot_selection_results("big", "ball", "bimodal", title = "bimodal"),
		plot_sample_histogram("big", "ball", "unimodal"),
		plot_sample_histogram("big", "ball", "bimodal"),
		layout = (2,2))
end

# ╔═╡ aa2655d1-2c8b-443a-9439-e636498f125e
plot(
	plot_selection_results("expensive", "spring"),
	plot_sample_histogram("expensive", "spring"),
	layout = (2,1)
)

# ╔═╡ afc58be4-6e79-424a-bfb7-0d94ec4e5130
let
	plot(
		plot_selection_results("long", "spring", "unimodal", title = "unimodal"),
		plot_selection_results("long", "spring", "bimodal", title = "bimodal"),
		plot_sample_histogram("long", "spring", "unimodal"),
		plot_sample_histogram("long", "spring", "bimodal"),
		layout =  (2,2)
	)
end

# ╔═╡ 8d7f53ad-2f6c-494c-a3a8-f71afd9a625b
if "figures" ∈ readdir(root)
	for scenario in ["ball", "spring"]
		#long/big
		adj_target = scenario == "ball" ? "big" : "long"
		for condition in ["bimodal", "unimodal"]
			p = plot_sample_histogram(adj_target, scenario, condition)
			scale = get_scale(adj_target)
			path = root * "/figures/stimuli_histogram_$(scenario)_$(scale)_$(condition).pdf"
			savefig(p, path)
		end
		
		#expensive
		adjective = "expensive"
		p = plot_sample_histogram(adjective, scenario)
		scale = get_scale(adjective)
		path = root * "/figures/stimuli_histogram_$(scenario)_$(scale).pdf"
		savefig(p, path)
	end
	
	md"Histograms saved!"
else
	md"No figures folder"
end

# ╔═╡ d0a2d22f-92f7-411f-89bf-ad8fb8892bc8
if "figures" ∈ readdir(root)
	for scenario in ["ball", "spring"]
		#big/long
		adjective = scenario == "ball" ? "big" : "long"
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
# ╟─734de216-874c-47e4-ab20-871aca0ee6e4
# ╠═cbb00ae3-7727-4caf-89be-adcb1af27c35
# ╠═cc3b7a32-f0c5-4a0a-a708-e0b382f7e90a
# ╠═38232c1a-6f47-443c-8cdf-c281fe89dbf5
# ╟─c9718d2e-21e9-4379-8ce7-0c0d6a97ca2f
# ╠═21bd0056-f2f3-4a25-9919-2a30a59a73bc
# ╠═8842788c-177d-418a-9578-3ee5e0466c39
# ╟─820a79b9-b295-43aa-8bd0-cce8d8ba76ba
# ╠═c6b20706-0115-4602-98ee-d7e22e986fec
# ╠═93c41a8a-d25c-4efa-b860-adcee8cc9c89
# ╠═a6abf963-0ca0-4089-b36b-67869a1b363b
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
# ╟─4913f741-6f04-4bf8-8844-cc0a42a6d08b
# ╟─e4a7961e-5f32-4e6c-be46-264520ccd421
# ╠═8d7f53ad-2f6c-494c-a3a8-f71afd9a625b
# ╟─b551c9be-6a03-4a09-8e88-cf620f47e36b
# ╠═d0a2d22f-92f7-411f-89bf-ad8fb8892bc8
# ╟─a3a9b479-cb0b-49e3-a710-0a0b13c1312d
# ╠═9262a9cc-3edc-46e8-b47b-c643467a990f
# ╠═5a7e5a60-29f9-414e-bada-f7787ba61b18
# ╠═e4189dd6-725e-4153-a6ca-5af9391d57c9
