### A Pluto.jl notebook ###
# v0.15.1

using Markdown
using InteractiveUtils

# ╔═╡ 9a18fe10-00e6-11ec-0b78-f75e5fd3fbe2
begin
	using Pkg
	root = ".."
	Pkg.activate(root)
	
	try
		using DataFrames, CSV, Plots, Statistics, StatsPlots, Distributions
	catch
		Pkg.instantiate()
		using DataFrames, CSV, Plots, Statistics, StatsPlots, Distributions
	end

	theme(:wong, legend=:outerright)
end

# ╔═╡ da6256f6-85a5-4c78-adcb-b56f4a1e79b9
paths = Dict(
	:all_results => root * "/modelling/results/results_with_disagreement.csv",
	:presentation_figures => root * "/presentation/figures/"
)

# ╔═╡ d01aba57-cd22-44a2-88ac-b7fccadaddb0
all_results = CSV.read(paths[:all_results], DataFrame)

# ╔═╡ 25b432b0-d01f-45dd-bda1-ccfddc6c6c57
md"""
## Confidence
"""

# ╔═╡ 905475a9-dfd7-4817-a5a7-a3e34a54a883
confidence_results = let
	df = all_results[all_results.item_type .== "confidence", :]
	df.response = parse.(Int64, df.response)
	df
end

# ╔═╡ e86f90cd-f63c-48f9-aca3-2e5fbd1685df
md"## Semantic model"

# ╔═╡ bdc215d6-6c6d-45eb-8f85-a2a9f7de462d
function ingredients(path::String)
	# this is from the Julia source code (evalfile in base/loading.jl)
	# but with the modification that it returns the module instead of the last object
	name = Symbol(basename(path))
	m = Module(name)
	Core.eval(m,
        Expr(:toplevel,
             :(eval(x) = $(Expr(:core, :eval))($name, x)),
             :(include(x) = $(Expr(:top, :include))($name, x)),
             :(include(mapexpr::Function, x) = $(Expr(:top, :include))(mapexpr, $name, x)),
             :(include($path))))
	m
end

# ╔═╡ 010ce797-84b9-4919-84c2-508217a5433f
md"## Helper code" 

# ╔═╡ caa9023f-40f9-4ed0-9c35-2d68ba05be33
scale = 1:5

# ╔═╡ 91b52a42-6b98-40a3-a06b-1cc55d16c0e0
function get_palette(condition)
	gradient = if condition == "bimodal"
		cgrad([
				"#eeeeee",
				PlotThemes.wong_palette[1],
				PlotThemes.wong_palette[6]
				],scale = :log)
	elseif condition == "unimodal"
		cgrad([
				"#eeeeee",
				PlotThemes.wong_palette[2],
				PlotThemes.wong_palette[5]
				], scale = :log)
	else
		cgrad([
				"#eeeeee",
				PlotThemes.wong_palette[3],
				"#006D60"
				], scale = :log)
	end
	
	palette(map(index -> gradient[index], 0.0:0.25:1.0))
end

# ╔═╡ 4a809f3d-f6a7-45d6-91fb-fba9551c0440
confidence_plot = let
	percentile(adjective, condition,rating) = let
		if condition ∈ ["bimodal", "unimodal"]
			subdata = filter(confidence_results) do row
				row.condition == condition && row.adj_target ∈ ["big", "long"]
			end
		else
			subdata = filter(confidence_results) do row
				row.adj_target == adjective
			end
		end
		responses = subdata.response
		count(r -> r <= rating, responses) / length(responses)
	end
	
	xticklabels =  [
		"big/long\nbimodal", "big/long\nunimodal", "expensive"]
	
	p = plot(
		xlabel = "adjective + condition",
		ylabel = "fraction of responses",
		legendtitle = "rating",
		xticks = ([1,2,3.5], xticklabels),
		xtickfontsize = 8, legendtitlefontsize = 10,
	)

	conditions = ["bimodal", "unimodal"]
	
	#target adjectives separated by condition
	for condition in conditions
		for rating in reverse(scale)
		
		
			bar_positions = [1 + (condition == "unimodal")]
			percentiles = [percentile("target", condition, rating)]

			bar!(p,
				bar_positions, 
				percentiles,
				palette = get_palette(condition),
				fillcolor = rating,
				bar_width = 0.7,
				label = rating,
			)
		end
	end
	
	#expensive (not separated by condition)
	for rating in reverse(scale)
		bar_position = 3.5
		bar_height = percentile("expensive", nothing, rating)
		bar!(p,
			[bar_position], [bar_height],
			palette = get_palette(nothing),
			fillcolor = rating,
			bar_width = 0.7,
			label = rating,
		)
	end
	
	
	
	p
end

# ╔═╡ b85457ba-17d7-4f18-923c-0e710d19e60e
let
	p = plot(confidence_plot, size = (400,320))
	
	savefig(p, 
		paths[:presentation_figures] * "confidence_aggregated.svg")
	
	md"Figure saved!"
end

# ╔═╡ Cell order:
# ╠═9a18fe10-00e6-11ec-0b78-f75e5fd3fbe2
# ╠═da6256f6-85a5-4c78-adcb-b56f4a1e79b9
# ╠═d01aba57-cd22-44a2-88ac-b7fccadaddb0
# ╟─25b432b0-d01f-45dd-bda1-ccfddc6c6c57
# ╠═905475a9-dfd7-4817-a5a7-a3e34a54a883
# ╟─4a809f3d-f6a7-45d6-91fb-fba9551c0440
# ╠═b85457ba-17d7-4f18-923c-0e710d19e60e
# ╟─e86f90cd-f63c-48f9-aca3-2e5fbd1685df
# ╠═bdc215d6-6c6d-45eb-8f85-a2a9f7de462d
# ╟─010ce797-84b9-4919-84c2-508217a5433f
# ╠═caa9023f-40f9-4ed0-9c35-2d68ba05be33
# ╠═91b52a42-6b98-40a3-a06b-1cc55d16c0e0
