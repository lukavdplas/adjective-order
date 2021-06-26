### A Pluto.jl notebook ###
# v0.14.8

using Markdown
using InteractiveUtils

# ╔═╡ 8b8a92c6-d032-11eb-0137-afbbf72b726d
begin
	using Pkg
	root = "../.."
	Pkg.activate(root)
	
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
	
	try
		using DataFrames, CSV, Plots, Statistics
	catch
		Pkg.instantiate()
		using DataFrames, CSV, Plots, Statistics
	end
	
	theme(:wong, legend = :outerright)
end

# ╔═╡ aaa9134a-c7b8-486a-b7f8-62f9450c4fd2
paths = Dict(
	:all_results => root * "/modelling/results/results_with_disagreement.csv",
	:export => root * "/modelling/results/relative_judgements.csv",
	:figures => root * "/figures/"
)

# ╔═╡ 44b4cf10-7b86-4e13-95ec-2ab825f7b2a3
all_results = CSV.read(paths[:all_results], DataFrame)

# ╔═╡ cbeb0915-0f02-44f1-a3e7-a147a9fd2992
md"""
## Disagreement potential
"""

# ╔═╡ 6a370a3a-3680-45eb-91bf-1f0105fb76bb
md"""
**Long, big, expensive:** The measured disagreement values.

**Cheap:** Use a missing value.

**Absolute adjective:** Set to `0`


"""

# ╔═╡ c548a0b4-7a06-4c8c-81b3-0210c8922315
function disagreement_potential(adjective, item)
	if adjective ∈ ["long", "big"]
		item.disagreement_on_adj_target
	elseif adjective == "expensive"
		item.disagreement_on_adj_secondary
	elseif adjective == "cheap"
		missing
	else
		0.0
	end
end

# ╔═╡ 5ab54f01-ea3d-40df-bceb-a953d2b9144f
relative_judgements = let
	#acceptability judgements
	acceptability_results = filter(row -> row.item_type == "test", all_results)
	acceptability_results.response = parse.(Int, acceptability_results.response)
	
	#group by NP (adj1, adj2, noun)
	groups = groupby(acceptability_results, [:adj_target, :adj_secondary, :scenario])
	
	mapreduce(vcat, collect(groups)) do NP_data
		#collect relative rating per participant
		per_participant = groupby(NP_data, :participant)
		
		mapreduce(vcat, collect(per_participant)) do participant_data
			#ratings for first and second order
			first_rating = let
				row = (first ∘ filter)(row -> row.order == "first", participant_data)
				row.response
			end
			
			second_rating = let
				row = (first ∘ filter)(row -> row.order == "second", participant_data)
				row.response
			end
			
			#metadata that should be kept
			datarow = participant_data[1:1, [
					:experiment, :participant, :condition,
					:scenario, :adj_target, :adj_secondary,
					:adj_secondary_type, :confidence_on_semantic
				]]
			
			#add difference and mean to data
			diff = first_rating - second_rating
			mean_rating = mean([first_rating, second_rating])
			
			insertcols!(datarow, 3, 
				:preference_for_first_order => [diff],
				:mean_acceptability => [mean_rating]
			)
			
			#calculate disagreement difference
			row = participant_data[1,:]
			dis_target = disagreement_potential(row.adj_target, row)
			dis_secondary = disagreement_potential(row.adj_secondary, row)
			predicted_preference = dis_target - dis_secondary
			
			insertcols!(datarow, 5, 
				:relative_subjectivity => [predicted_preference],
			)
		end
	end
end

# ╔═╡ f1d76242-e88d-4144-a206-912ee6f27c19
CSV.write(paths[:export], relative_judgements)

# ╔═╡ ec5983f3-078a-4b7c-a001-ca5aded6659f
md"""
## Plots
"""

# ╔═╡ 49abd597-ef9a-4be6-8862-010c7e301437
preference_scale = -5:5

# ╔═╡ adcfea9e-4a77-4046-a12a-3ba652aefbbc
histogram(
	relative_judgements.preference_for_first_order,
	bins = preference_scale,
	label = nothing,
	xlabel = "preference for target adjective first",
	ylabel = "N"
)

# ╔═╡ a68bbb19-5b2b-4eaa-8107-3baad14a7450
pal2 = let
	colours = [
		PlotThemes.wong_palette[5],
		PlotThemes.wong_palette[2],
		"#eeeeee",
		PlotThemes.wong_palette[1],
		PlotThemes.wong_palette[6]
	]
	
	palette(colours, preference_scale, rev = true)
end

# ╔═╡ 60eb98a2-c0e9-4002-bddf-914c70235e34
pal = let
	colours = [
		"#006D60",
		PlotThemes.wong_palette[3],
		"#eeeeee",
		PlotThemes.wong_palette[7],
		"#9E3264",
	]
	
	palette(colours, preference_scale, rev = true)
end

# ╔═╡ 4cbb255c-f33c-4c5a-93ea-50c5f80fb786
function plot_preference(x_col, x_scale, data; seriestype = :bar, orientation = :vertical, kwargs...)
	p = plot(
		ylabel = "ratio of responses",
		legendtitle = "preference for \n target first",
		legendtitlefontsize = 8,
	)
	
	map(reverse(preference_scale)) do preference
		preference_data = filter(data) do row
			row.preference_for_first_order <= preference
		end
		
		y_values = map(x_scale) do x
			n = count(x1 -> x1 === x, preference_data[!, x_col])
			total = count(x1 -> x1 === x, data[!, x_col])
			
			n / total
		end
		
		plot!(p, x_scale, y_values, 
			label = preference,
			seriestype = seriestype,
			color = :black,
			fill = 0,
			fillcolor = pal[preference + 6];
			orientation = orientation,
		)
	end
	
	plot!(p; kwargs...)
end

# ╔═╡ a732fdce-9182-4b64-a1e0-4b8b1b27a7bb
let
	mean_values = 1.0:0.5:5.0
	plot_preference(:mean_acceptability, mean_values, relative_judgements,
		xticks = mean_values, xlabel = "mean acceptability"
	)
end

# ╔═╡ 06e8e659-314b-4d06-8f78-9e2c08c9ff1b
plot_preference(:adj_secondary_type, ["absolute", "scalar"], relative_judgements,
	xlabel = "secondary adjective type",
	plotype = :bar
)

# ╔═╡ 223480da-0988-436a-a37e-213dee964454
plot_preference(:condition, ["bimodal", "unimodal"], relative_judgements,
	xlabel = "condition",
	plotype = :bar
)

# ╔═╡ 0d166931-3e23-441b-b985-f6e91a85eb7f
let
	sorted = sort(relative_judgements, [:experiment])
	grouped = groupby(sorted, [:adj_target, :experiment])
	
	subplots = map(collect(grouped)) do data
		experiment = first(data.experiment)
		adjective = first(data.adj_target)
		title = "$(adjective), experiment $(experiment)"
		
		plot_preference(:condition, ["bimodal", "unimodal"], data,
			xlabel = "condition",
			plotype = :bar,
			legend = :none,
			title = title,
			titlefontsize = 12,
		)
	end
	
	plot(subplots..., layout = (3,2), size = (600, 700))
end

# ╔═╡ 61010c9e-63d7-4999-80ca-7f2eb35fde32
md"""
### Relative subjectivity
"""

# ╔═╡ b181392f-027c-4817-b52e-af37174af9cb
subjectivity_scores = (sort ∘ unique)(filter(!ismissing, relative_judgements.relative_subjectivity))

# ╔═╡ a45af2ed-3f57-4176-a807-6db2b29eafcd
preference_by_subjectivity = let
	rounded_subjectivity = let
		data = copy(relative_judgements)
		data.relative_subjectivity = round.(data.relative_subjectivity, digits = 2)
		data
	end
	
	rounded_subjectivity_scores = let
		rounded = round.(subjectivity_scores, digits = 2)
		unique(rounded)
	end
	
	plot_preference(:relative_subjectivity, rounded_subjectivity_scores, rounded_subjectivity,
		xlabel = "relative subjectivity of target",
		seriestype = :line
	)
end

# ╔═╡ cc008e68-6456-4193-ada7-7897162ea111
if "figures" ∈ readdir(root)
	savefig(preference_by_subjectivity, 
		paths[:figures] * "preference_by_subjectivity.pdf")
	md"Figure saved!"
end

# ╔═╡ 7da08416-d548-4c2c-829a-fde81eda7723
let
	preferences = map(subjectivity_scores) do score
		data = filter(row -> row.relative_subjectivity === score, relative_judgements)
		data.preference_for_first_order
	end
	
	means = mean.(preferences)
	errors = std.(preferences)

	p = scatter(subjectivity_scores, means, 
		yerror = errors,
		color = 3,
		marker = :circle, linecolor = :black,
		xlabel = "relative subjectivity of target",
		ylabel = "preference for target first",
		legend = :none
	)
	
	vline!(p, [0], linecolor = :black, linestyle = :dash)
	hline!(p, [0], linecolor = :black, linestyle = :dash)
end

# ╔═╡ 0cebbb6d-3016-4e52-9fa9-3a74a326ae3b
preference_by_adj_pair = let
	data_with_adj_pair = let
		data = copy(relative_judgements)
		data.adj_pair = map(eachrow(data)) do row
			"$(row.adj_target) * $(row.adj_secondary)"
		end
		data
	end
	
	adj_pairs = let
		pairs = unique(data_with_adj_pair.adj_pair)
		mean_preference(pair) = let
			pairdata = filter(row -> row.adj_pair == pair, data_with_adj_pair)
			mean(pairdata.preference_for_first_order)
		end
		reverse(sort(pairs, by = mean_preference))
	end
	
	plot_preference(:adj_pair, adj_pairs, data_with_adj_pair,
		xlabel = "ratio of response",
		seriestype = :bar,
		orientation = :horizontal,
		ylabel = "adjectives"
	)
end

# ╔═╡ 79e16b94-b17a-4bd1-b20c-efb631713531
if "figures" ∈ readdir(root)
	savefig(preference_by_adj_pair, 
		paths[:figures] * "preference_by_adjective_pair.pdf")
	md"Figure saved!"
end

# ╔═╡ Cell order:
# ╠═8b8a92c6-d032-11eb-0137-afbbf72b726d
# ╠═aaa9134a-c7b8-486a-b7f8-62f9450c4fd2
# ╠═44b4cf10-7b86-4e13-95ec-2ab825f7b2a3
# ╟─cbeb0915-0f02-44f1-a3e7-a147a9fd2992
# ╟─6a370a3a-3680-45eb-91bf-1f0105fb76bb
# ╠═c548a0b4-7a06-4c8c-81b3-0210c8922315
# ╠═5ab54f01-ea3d-40df-bceb-a953d2b9144f
# ╠═f1d76242-e88d-4144-a206-912ee6f27c19
# ╟─ec5983f3-078a-4b7c-a001-ca5aded6659f
# ╠═49abd597-ef9a-4be6-8862-010c7e301437
# ╠═adcfea9e-4a77-4046-a12a-3ba652aefbbc
# ╠═a68bbb19-5b2b-4eaa-8107-3baad14a7450
# ╠═60eb98a2-c0e9-4002-bddf-914c70235e34
# ╠═4cbb255c-f33c-4c5a-93ea-50c5f80fb786
# ╟─a732fdce-9182-4b64-a1e0-4b8b1b27a7bb
# ╟─06e8e659-314b-4d06-8f78-9e2c08c9ff1b
# ╟─223480da-0988-436a-a37e-213dee964454
# ╟─0d166931-3e23-441b-b985-f6e91a85eb7f
# ╟─61010c9e-63d7-4999-80ca-7f2eb35fde32
# ╠═b181392f-027c-4817-b52e-af37174af9cb
# ╠═a45af2ed-3f57-4176-a807-6db2b29eafcd
# ╠═cc008e68-6456-4193-ada7-7897162ea111
# ╠═7da08416-d548-4c2c-829a-fde81eda7723
# ╠═0cebbb6d-3016-4e52-9fa9-3a74a326ae3b
# ╠═79e16b94-b17a-4bd1-b20c-efb631713531
