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
results = CSV.read("results_filtered.csv", DataFrame) ;

# ╔═╡ 14e4583e-e403-43f5-ac84-68650cba71db
stimuli_data = CSV.read("stimuli_data.csv", DataFrame)

# ╔═╡ 0e54595b-f569-4201-b355-5ae56f3ddfa8
semantic_results = results[results.item_type .== "semantic", :]

# ╔═╡ c9718d2e-21e9-4379-8ce7-0c0d6a97ca2f
md"""
## Selection probabilities
"""

# ╔═╡ 820a79b9-b295-43aa-8bd0-cce8d8ba76ba
md"""
## Prior estimation
"""

# ╔═╡ 12202f0b-2410-4042-b776-096d565d00ed
prior_price_TV = let
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

# ╔═╡ d73c5f6c-b5b5-41b2-8af4-2ec7bab6f747
function selection_probability(stimulus_id::String, data::DataFrame)
	stimulus_data = data[data.id .== stimulus_id, :]
	
	responses = parse.(Bool, stimulus_data.response)
	
	count(responses) / length(responses)
end

# ╔═╡ dc2684a6-b29b-4ee8-a138-745aa34ac666
function measure(stimulus_id::String, scale::String)
	words = split(stimulus_id, '_')
	short_id = join(words[3:4], "_")
		
	first(stimuli_data[stimuli_data.index .== short_id, scale])
end

# ╔═╡ 647f7087-9313-43ec-aa98-eb1b9c138802
function plot_selection_probabilities(data::DataFrame, scale::String; kwargs...)
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
		ylabel = "P(selected | size)",
		xlabel = scale; 
		kwargs...
	)
end

# ╔═╡ c2d76d84-33a6-4e34-a874-a01644e232fd
plot_size_tv_unim_results = let
	big_results = filter(semantic_results) do row
		(row.adj_target == "big") & (row.condition .== "unimodal")
	end
	
	plot_selection_probabilities(big_results, "size", 
		xlabel = "size (inches)"
	)
end ;

# ╔═╡ ea454f4c-4269-4be1-9117-c8a92e4abf3b
plot_size_tv_bim_results = let
	big_results = filter(semantic_results) do row
		(row.adj_target == "big") & (row.condition .== "bimodal")
	end
	
	plot_selection_probabilities(big_results, "size", 
		xlabel = "size (inches)"
	)
end ;

# ╔═╡ 40b7d49e-0af5-4191-b52f-4e0e5b1b8643
plot_size_ch_bim_results = let
	big_results = filter(semantic_results) do row
		(row.adj_target == "long") & (row.condition .== "bimodal")
	end
	
	plot_selection_probabilities(big_results, "size", 
		xlabel = "size (inches)"
	)
end ;

# ╔═╡ 6d4df08a-0bd3-4607-b40a-48985a81e091
plot_size_ch_unim_results = let
	big_results = filter(semantic_results) do row
		(row.adj_target == "long") & (row.condition .== "unimodal")
	end
	
	plot_selection_probabilities(big_results, "size", 
		xlabel = "size (inches)"
	)
end ;

# ╔═╡ 0570de20-39c1-45f8-b93f-93bd5142c07c
plot_price_tv_results = let
	exp_tv_results = filter(semantic_results) do row
		(row.adj_target == "expensive") && (row.scenario == "tv") 
	end
	
	plot_selection_probabilities(exp_tv_results, "price",
		xlabel = "price (\$)"
	)
end ;

# ╔═╡ c2ca7f4c-24c9-48b9-9a22-f1ea358f6891
plot_price_ch_results = let
	exp_tv_results = filter(semantic_results) do row
		(row.adj_target == "expensive") && (row.scenario == "couch")
	end
	
	plot_selection_probabilities(exp_tv_results, "price",
		xlabel = "price (\$)"
	)
end ;

# ╔═╡ d57014f7-ddca-4f32-8505-c3f1847b72da
function plot_prior(prior; kwargs...)
	plot(prior,
		color = 2,
		lw = 3,
		fill = 0, fillalpha = 0.5,
		label = nothing;
		kwargs...
	)
end

# ╔═╡ 50ef232b-6b90-45f8-a84b-da83f4592ddd
plot_price_tv_prior = let
	prices = stimuli_data[stimuli_data.scenario .== "tv", "price"]
	
	plot_prior(prior_price_TV,
		xlims = (minimum(prices), maximum(prices)),
		xlabel = "price (\$)",
		ylabel = "P(price)"
	)
end ;

# ╔═╡ 8e27b617-b904-4eef-86a3-38560e7bac73
plot(
	plot_price_tv_results,
	plot_price_tv_prior,
	layout = (2,1)
)

# ╔═╡ 457f66a7-844f-4da5-a284-09bb1856b62e
plot_price_ch_prior = let
	prices = stimuli_data[stimuli_data.scenario .== "couch", "price"]
	
	plot_prior(prior_price_couch,
		xlims = (minimum(prices), maximum(prices)),
		xlabel = "price (\$)",
		ylabel = "P(price)"
	)
end ;

# ╔═╡ aa2655d1-2c8b-443a-9439-e636498f125e
plot(
	plot_price_ch_results,
	plot_price_ch_prior,
	layout = (2,1)
)

# ╔═╡ 0d80b339-28dd-4340-85e5-c511bc9228fe
plot_size_tv_unim_prior = let
	sizes = stimuli_data[stimuli_data.scenario .== "tv", "size"]
	
	plot_prior(prior_size_tv_unim,
		xlims = (minimum(sizes), maximum(sizes)),
		xlabel = "size (inches)",
		ylabel = "P(price)"
	)
end ;

# ╔═╡ addd245c-949e-41b6-b7cd-3b0016607459
plot_size_tv_bim_prior = let
	sizes = stimuli_data[stimuli_data.scenario .== "tv", "size"]
	
	plot_prior(prior_size_tv_bim,
		xlims = (minimum(sizes), maximum(sizes)),
		xlabel = "size (inches)",
		ylabel = "P(price)"
	)
end ;

# ╔═╡ 2d164b37-4da8-45ba-836e-510a2c42d05e
let
	plot(
		plot(plot_size_tv_unim_results, title = "unimodal"),
		plot(plot_size_tv_bim_results, title = "bimodal"),
		plot_size_tv_unim_prior,
		plot_size_tv_bim_prior,
		layout = (2,2))
end

# ╔═╡ 94088dc0-85fc-434b-8054-5f8302a05fa9
plot_size_ch_unim_prior = let
	sizes = stimuli_data[stimuli_data.scenario .== "couch", "size"]
	
	plot_prior(prior_size_ch_unim,
		xlims = (minimum(sizes), maximum(sizes)),
		xlabel = "size (inches)",
		ylabel = "P(price)"
	)
end ;

# ╔═╡ 0bb37438-1344-4100-92bb-8b1903cffcb7
plot_size_ch_bim_prior = let
	sizes = stimuli_data[stimuli_data.scenario .== "couch", "size"]
	
	plot_prior(prior_size_ch_bim,
		xlims = (minimum(sizes), maximum(sizes)),
		xlabel = "size (inches)",
		ylabel = "P(price)"
	)
end ;

# ╔═╡ afc58be4-6e79-424a-bfb7-0d94ec4e5130
let
	plot(
		plot(plot_size_ch_unim_results, title = "unimodal"),
		plot(plot_size_ch_bim_results, title = "bimodal"),
		plot_size_ch_unim_prior,
		plot_size_ch_bim_prior,
		layout = (2,2))
end

# ╔═╡ Cell order:
# ╟─f29b7732-246f-4947-bf15-a3ae6d99682e
# ╠═0c33a28a-2419-452c-bb7f-62e0b068418a
# ╠═8358c692-93b8-11eb-20cc-7ff7a8a3ed34
# ╠═14e4583e-e403-43f5-ac84-68650cba71db
# ╠═0e54595b-f569-4201-b355-5ae56f3ddfa8
# ╟─c9718d2e-21e9-4379-8ce7-0c0d6a97ca2f
# ╠═c2d76d84-33a6-4e34-a874-a01644e232fd
# ╠═ea454f4c-4269-4be1-9117-c8a92e4abf3b
# ╠═40b7d49e-0af5-4191-b52f-4e0e5b1b8643
# ╠═6d4df08a-0bd3-4607-b40a-48985a81e091
# ╠═0570de20-39c1-45f8-b93f-93bd5142c07c
# ╠═c2ca7f4c-24c9-48b9-9a22-f1ea358f6891
# ╟─820a79b9-b295-43aa-8bd0-cce8d8ba76ba
# ╠═12202f0b-2410-4042-b776-096d565d00ed
# ╠═4bf237b8-b680-4b5f-aafb-62e9c062fa79
# ╠═d1d8fa00-f628-4543-a390-956babd9a765
# ╠═ce7ae281-dc82-4e3e-a679-ca9afef62985
# ╠═5ff963a7-d31d-4ad5-9eb7-d876ea9db864
# ╠═1ae25cdf-b296-406f-94ab-b5e6577f7e37
# ╠═50ef232b-6b90-45f8-a84b-da83f4592ddd
# ╠═457f66a7-844f-4da5-a284-09bb1856b62e
# ╠═0d80b339-28dd-4340-85e5-c511bc9228fe
# ╠═addd245c-949e-41b6-b7cd-3b0016607459
# ╠═94088dc0-85fc-434b-8054-5f8302a05fa9
# ╠═0bb37438-1344-4100-92bb-8b1903cffcb7
# ╟─dcef9229-6f95-40f9-b3ac-93aca1ba117c
# ╟─f36af399-85f5-4852-9782-acd32b0a6acb
# ╟─8e27b617-b904-4eef-86a3-38560e7bac73
# ╟─cb65bdec-5b60-401f-9190-94dddefb38f5
# ╟─2d164b37-4da8-45ba-836e-510a2c42d05e
# ╟─38300334-c653-4481-895c-be6aa49c0ddb
# ╟─aa2655d1-2c8b-443a-9439-e636498f125e
# ╟─28b5e4c2-62c0-482d-91bc-14e85c6bc100
# ╟─afc58be4-6e79-424a-bfb7-0d94ec4e5130
# ╟─a3a9b479-cb0b-49e3-a710-0a0b13c1312d
# ╠═d73c5f6c-b5b5-41b2-8af4-2ec7bab6f747
# ╠═dc2684a6-b29b-4ee8-a138-745aa34ac666
# ╠═647f7087-9313-43ec-aa98-eb1b9c138802
# ╠═d57014f7-ddca-4f32-8505-c3f1847b72da
