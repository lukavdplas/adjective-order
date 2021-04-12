### A Pluto.jl notebook ###
# v0.14.0

using Markdown
using InteractiveUtils

# ╔═╡ 0c33a28a-2419-452c-bb7f-62e0b068418a
let
	using CSV, DataFrames, Plots, Distributions, StatsPlots
	theme(:wong, legend=:outerright)
end

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

# ╔═╡ 820a79b9-b295-43aa-8bd0-cce8d8ba76ba
md"""
## Prior estimation
"""

# ╔═╡ 12202f0b-2410-4042-b776-096d565d00ed
prior_price_tv = let
	sample = filter(stimuli_data) do row
		(row.scenario == "tv") && row.bimodal
		# note: bimodal and unimodal result in the same set of prices
		# select 1 to avoid duplicates
	end
	
	fit(LogNormal, sample.price)
end

# ╔═╡ 4bf237b8-b680-4b5f-aafb-62e9c062fa79
prior_price_couch =  let
	sample = filter(stimuli_data) do row
		(row.scenario == "couch") && row.bimodal
		# note: idem for selecting condition
	end
	
	fit(Normal, sample.price)
end

# ╔═╡ d1d8fa00-f628-4543-a390-956babd9a765
prior_size_tv_unim = let
	sample = filter(stimuli_data) do row
		(row.scenario == "tv") && row.unimodal
	end
	
	fit(Normal, sample.size)
end

# ╔═╡ ce7ae281-dc82-4e3e-a679-ca9afef62985
prior_size_tv_bim = let
	sample = filter(stimuli_data) do row
		(row.scenario == "tv") && row.bimodal
	end
	
	sample_upper = sample[sample.size .> 50, :]
	sample_lower = sample[sample.size .< 50, :]
	
	prior_upper = fit(Normal, sample_upper.size)
	prior_lower = fit(Normal, sample_lower.size)
	
	prior = MixtureModel([prior_upper, prior_lower], [0.5, 0.5])
end

# ╔═╡ 5ff963a7-d31d-4ad5-9eb7-d876ea9db864
prior_size_ch_unim = let
	sample = filter(stimuli_data) do row
		(row.scenario == "couch") && row.unimodal
	end
	
	fit(Normal, sample.size)
end

# ╔═╡ 1ae25cdf-b296-406f-94ab-b5e6577f7e37
prior_size_ch_bim = let
	sample = filter(stimuli_data) do row
		(row.scenario == "couch") && row.bimodal
	end
	
	sample_upper = sample[sample.size .> 70, :]
	sample_lower = sample[sample.size .< 70, :]
	
	prior_upper = fit(Normal, sample_upper.size)
	prior_lower = fit(Normal, sample_lower.size)
	
	prior = MixtureModel([prior_upper, prior_lower], [0.5, 0.5])
end

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
		lw = 3,
		fill = 0, fillalpha = 0.5,
		ylims = (0,1), 
		xlims = (minimum(measures), maximum(measures)),
		label = nothing,
		ylabel = "P(selected | $(scale))",
		xlabel = scale_label(scale);
		kwargs...
	)
end

# ╔═╡ 4d662249-f275-40f2-a5b1-438cd71ccf2d
function plot_prior(prior, scale, scenario; kwargs...)
	measures = stimuli_data[stimuli_data.scenario .== scenario, scale]	
	
	plot(prior,
		color = 2,
		lw = 3,
		fill = 0, fillalpha = 0.5,
		label = nothing;
		xlabel = scale_label(scale),
		ylabel = "P($(scale))",
		xlims = (minimum(measures), maximum(measures)),
		kwargs...
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
		bins = 50,
		color = 2,
		linecolor = 2,
		lw = 3,
		fill = 0, fillalpha = 0.5,
		label = nothing;
		xlabel = scale_label(scale),
		ylabel = "P($(scale))",
		xlims = (minimum(measures), maximum(measures))
	)
end

# ╔═╡ 0ddc10bd-9732-4f3e-af85-d99abb24c868
plot_sample_histogram("expensive", "tv")

# ╔═╡ 8e27b617-b904-4eef-86a3-38560e7bac73
plot(
	plot_selection_results("expensive", "tv"),
	#plot_prior(prior_price_tv, "price", "tv"),
	plot_sample_histogram("expensive", "tv"),
	layout = (2,1)
)

# ╔═╡ 2d164b37-4da8-45ba-836e-510a2c42d05e
let
	plot(
		plot_selection_results("big", "tv", "unimodal", title = "unimodal"),
		plot_selection_results("big", "tv", "bimodal", title = "bimodal"),
		#plot_prior(prior_size_tv_unim, "size", "tv"),
		#plot_prior(prior_size_tv_bim, "size", "tv"),
		plot_sample_histogram("big", "tv", "unimodal"),
		plot_sample_histogram("big", "tv", "bimodal"),
		layout = (2,2))
end

# ╔═╡ aa2655d1-2c8b-443a-9439-e636498f125e
plot(
	plot_selection_results("expensive", "couch"),
	#plot_prior(prior_price_couch, "price", "couch"),
	plot_sample_histogram("expensive", "couch"),
	layout = (2,1)
)

# ╔═╡ afc58be4-6e79-424a-bfb7-0d94ec4e5130
let
	plot(
		plot_selection_results("long", "couch", "unimodal", title = "unimodal"),
		plot_selection_results("long", "couch", "bimodal", title = "bimodal"),
		#plot_prior(prior_size_ch_unim, "size", "couch"),
		#plot_prior(prior_size_ch_bim, "size", "couch"),
		plot_sample_histogram("long", "couch", "unimodal"),
		plot_sample_histogram("long", "couch", "bimodal"),
		layout = (2,2))
end

# ╔═╡ Cell order:
# ╟─f29b7732-246f-4947-bf15-a3ae6d99682e
# ╠═0c33a28a-2419-452c-bb7f-62e0b068418a
# ╠═8358c692-93b8-11eb-20cc-7ff7a8a3ed34
# ╠═14e4583e-e403-43f5-ac84-68650cba71db
# ╠═0e54595b-f569-4201-b355-5ae56f3ddfa8
# ╟─c9718d2e-21e9-4379-8ce7-0c0d6a97ca2f
# ╠═d73c5f6c-b5b5-41b2-8af4-2ec7bab6f747
# ╠═8842788c-177d-418a-9578-3ee5e0466c39
# ╟─820a79b9-b295-43aa-8bd0-cce8d8ba76ba
# ╠═12202f0b-2410-4042-b776-096d565d00ed
# ╠═4bf237b8-b680-4b5f-aafb-62e9c062fa79
# ╠═d1d8fa00-f628-4543-a390-956babd9a765
# ╠═ce7ae281-dc82-4e3e-a679-ca9afef62985
# ╠═5ff963a7-d31d-4ad5-9eb7-d876ea9db864
# ╠═1ae25cdf-b296-406f-94ab-b5e6577f7e37
# ╠═4d662249-f275-40f2-a5b1-438cd71ccf2d
# ╠═17913ee9-5b69-425d-9ab0-fee4a29e4832
# ╠═0ddc10bd-9732-4f3e-af85-d99abb24c868
# ╟─dcef9229-6f95-40f9-b3ac-93aca1ba117c
# ╟─f36af399-85f5-4852-9782-acd32b0a6acb
# ╠═8e27b617-b904-4eef-86a3-38560e7bac73
# ╟─cb65bdec-5b60-401f-9190-94dddefb38f5
# ╠═2d164b37-4da8-45ba-836e-510a2c42d05e
# ╟─38300334-c653-4481-895c-be6aa49c0ddb
# ╠═aa2655d1-2c8b-443a-9439-e636498f125e
# ╟─28b5e4c2-62c0-482d-91bc-14e85c6bc100
# ╠═afc58be4-6e79-424a-bfb7-0d94ec4e5130
# ╟─a3a9b479-cb0b-49e3-a710-0a0b13c1312d
# ╠═9262a9cc-3edc-46e8-b47b-c643467a990f
# ╠═5a7e5a60-29f9-414e-bada-f7787ba61b18
