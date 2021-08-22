### A Pluto.jl notebook ###
# v0.15.1

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
	:figures => root * "/figures/",
	:presentation_figures => root * "/presentation/figures/"
)

# ╔═╡ 97033e82-8d7a-4202-b8e5-08d741b90394
presentation_maxsize = (650, 320)

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

# ╔═╡ cd58b3fd-a128-4256-b0db-5e8e2352c25e
names(all_results)

# ╔═╡ 76c2ed8b-a354-4c70-819a-410f968d85d0
md"""### Corpus data

Frequency data from google ngrams (frequencies in year 2019)
"""

# ╔═╡ 6cac4352-df93-4090-bb6a-d03bff6d6be1
corpus_data = DataFrame(
	:adj_target => vcat(repeat(["big"], 6), repeat(["long"], 6)),
	:adj_secondary => [
		"expensive", "cheap", "discounted", 
		"refurbished", "striped", "plastic", 
		"expensive", "cheap", "discounted", 
		"metal", "leather", "plastic"],
	:freq_target_first => [
		0.0000008678, 0.0000000935, 0.0000000000,
		0.0000000000, 0.0000003639, 0.0000046894, 
		0.0000002050, 0.0000000746, 0.0000001048,
		0.0000090045, 0.0000063455, 0.0000020865],
	:freq_target_second => [
		0.0000001391, 0.0000000438, 0.0000000030,
		0.0000000000, 0.0000000491, 0.0000000253,
		0.0000007459, 0.0000002318, 0.0000000745,
		0.0000001710, 0.0000001425, 0.0000000539],
)

# ╔═╡ bda742af-8a77-4dd5-8def-3066ef3bbbdc
function corpus_preference_score(row)
	f_first = row.freq_target_first
	f_second = row.freq_target_second
	
	if (f_first + f_second) < 1e-8
		missing
	elseif row.adj_target == "long" && row.adj_secondary == "discounted"
		missing
	else
		(f_first - f_second) / (f_first + f_second)
	end
end

# ╔═╡ 5ab54f01-ea3d-40df-bceb-a953d2b9144f
relative_judgements = let
	#acceptability judgements
	acceptability_results = filter(row -> row.item_type == "test", all_results)
	acceptability_results.response = parse.(Int, acceptability_results.response)
	
	#group by NP (adj1, adj2, noun)
	groups = groupby(acceptability_results, [:adj_target, :adj_secondary, :scenario])
	
	data = mapreduce(vcat, collect(groups)) do NP_data
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
					:adj_secondary_type, :confidence_on_semantic,
					:disagreement_on_adj_target, :disagreement_on_adj_secondary
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
	
	corpus_scores = map(eachrow(data)) do row
		adj_target = row.adj_target
		adj_secondary = row.adj_secondary
		
		match = first(filter(corpus_data) do row
				row.adj_target == adj_target && row.adj_secondary == adj_secondary
			end)
		
		corpus_preference = corpus_preference_score(match)
	end
	
	data.corpus_preference = corpus_scores
	
	data
end

# ╔═╡ f1d76242-e88d-4144-a206-912ee6f27c19
CSV.write(paths[:export], relative_judgements)

# ╔═╡ aa0d3b17-73fd-4c77-8b75-69e4992c5301
md"A pretty table:"

# ╔═╡ 492c1c5f-ea19-4699-ad35-fb64757ed553
let
	data = copy(corpus_data)
	
	#convert frequencies from percent to ppb
	data.freq_target_first = data.freq_target_first * 1e9 / 1e2
	data.freq_target_second = data.freq_target_second * 1e9 / 1e2
	
	#preference scores
	scores = corpus_preference_score.(eachrow(data))
	data.preference_score = scores
	
	sort(data, [:adj_target, :adj_secondary])
end

# ╔═╡ ec5983f3-078a-4b7c-a001-ca5aded6659f
md"""
## Plots
"""

# ╔═╡ 49abd597-ef9a-4be6-8862-010c7e301437
preference_scale = -4:4

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
	
	#palette(colours, preference_scale, rev = true)
	
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
			fillcolor = pal[preference + 5];
			orientation = orientation,
		)
	end
	
	plot!(p; kwargs...)
end

# ╔═╡ 67ecf720-a4bd-41e8-adbe-230b34024fd0
md"### By mean acceptability"

# ╔═╡ a732fdce-9182-4b64-a1e0-4b8b1b27a7bb
let
	mean_values = 1.0:0.5:4.0
	plot_preference(:mean_acceptability, mean_values, relative_judgements,
		xticks = mean_values, xlabel = "mean acceptability"
	)
end

# ╔═╡ 3c64c464-8a4d-411a-9c75-f9c670716003
md"### By type of secondary adjective"

# ╔═╡ 06e8e659-314b-4d06-8f78-9e2c08c9ff1b
secondary_type_plot = plot_preference(:adj_secondary_type, ["absolute", "scalar"], relative_judgements,
	xlabel = "secondary adjective type",
	plotype = :bar
)

# ╔═╡ 912a7297-1a09-40d0-9ea6-53996c43e0e1
let
	p = plot(secondary_type_plot; size = (400, presentation_maxsize[2]))
	
	savefig(p,
		paths[:presentation_figures] * "order_pref_by_secondary_type.svg"
	)
end

# ╔═╡ 96eadf44-7d94-46c5-a8ef-6724c927e48d
md"### By condition"

# ╔═╡ 223480da-0988-436a-a37e-213dee964454
condition_plot = plot_preference(:condition, ["bimodal", "unimodal"], relative_judgements,
	xlabel = "condition",
	plotype = :bar
)

# ╔═╡ d865e175-6765-4bd5-a4e7-3f7d9d641737
let
	p = plot(condition_plot; size = (400, presentation_maxsize[2]))
	
	savefig(p,
		paths[:presentation_figures] * "order_pref_by_condition.svg"
	)
end

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
### By relative subjectivity
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

# ╔═╡ 0245a16b-6da2-45b1-9671-476604065695
let
	p = plot(preference_by_subjectivity;
		size = (presentation_maxsize[1], 290), aspect_ratio = 0.13)
	
	savefig(p, 
		root * "/presentation/figures/order_pref_by_subjectivity.svg"
	)
end

# ╔═╡ cc008e68-6456-4193-ada7-7897162ea111
if "figures" ∈ readdir(root)
	savefig(preference_by_subjectivity, 
		paths[:figures] * "preference_by_subjectivity.pdf")
	md"Figure saved!"
end

# ╔═╡ ec22046e-d17e-4bf5-9424-62e53276a951
md"### By adjective pair"

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
		xlabel = "ratio of responses",
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

# ╔═╡ d5859881-16a5-4ac9-92ae-e42ab8a0007d
let
	p = plot(preference_by_adj_pair;
		size = (presentation_maxsize[1], 290), aspect_ratio = 0.04)
	
	savefig(p,
		paths[:presentation_figures] * "order_pref_by_adjective_pair.svg")
end

# ╔═╡ 39ccdc36-7c19-407c-a1ed-be0d424405f3
md"### By relative frequency in corpus"

# ╔═╡ 65ba0667-cc6d-4d27-9a01-aaf45d9d4b10
corpus_plot = let
	data = copy(relative_judgements)
	data.corpus_preference = round.(data.corpus_preference, digits = 1)
	
	corpus_preference_scores = let
		scores = map(corpus_preference_score, eachrow(corpus_data))
		rounded_scores = round.(scores, digits = 1)
		(sort ∘ unique)(rounded_scores)
		end
	
	plot_preference(:corpus_preference, corpus_preference_scores, data,
		seriestype = :line,
		xlabel = "relative frequency of target first"
)
end

# ╔═╡ c14c94e7-5a62-42ea-8ca9-6fc41c67539b
if "figures" ∈ readdir(root)
	savefig(corpus_plot, 
		paths[:figures] * "preference_by_corpus_freq.pdf")
	md"Figure saved!"
end

# ╔═╡ a3a10afb-1872-413d-b1a1-255a5a4536f6
let
	x_values = filter(!ismissing, relative_judgements.corpus_preference)
	x_values = round.(x_values, digits = 1)
	
	ratio = 1 / (maximum(x_values) - minimum(x_values))
	
	p = plot(corpus_plot;
		size = (presentation_maxsize[1], 290), aspect_ratio = ratio)
	
	savefig(p,
		paths[:presentation_figures] * "order_pref_by_corpus_freq.svg")
end

# ╔═╡ 2eb3da98-f276-4d84-bfc9-6281699d92b9
md"### By condidence rating on target"

# ╔═╡ ffb3d5ec-b1d1-4d46-91b3-613bef41cd70
confidence_plot() = plot_preference(:confidence_on_semantic, 2:5,
	relative_judgements,
	xlabel = "confidence on semantic task",
	seriestype = :bar
)

# ╔═╡ 103e6f38-a325-4e8a-a680-05af49fa7aed
confidence_plot()

# ╔═╡ 0db341c7-234f-4e36-9a67-e24e421629d3
let
	p = plot(confidence_plot(), size = (500, presentation_maxsize[2]))
	
	savefig(p,
		paths[:presentation_figures] * "order_pref_by_confidence.svg")
end

# ╔═╡ b92be1b9-556f-4381-bbdf-c141d2e0003d
md"### By disagreement on target"

# ╔═╡ 1c55f8bf-3258-41b6-854b-0d3ae76d67a5
target_disagreement_values = let
	values = filter(!ismissing, relative_judgements.disagreement_on_adj_target)
	(sort ∘ unique)(values)
end

# ╔═╡ 7f35d271-2d38-49b7-932e-4efed601c01e
disagreement_plot() = let
	digits = 2
	
	data = copy(relative_judgements)
	data.disagreement_on_adj_target = round.(data.disagreement_on_adj_target, 
		digits = digits)
	
	values = round.(target_disagreement_values, digits = digits)
	
	plot_preference(:disagreement_on_adj_target, values,
		data,
		xlabel = "disagreement on target adjective",
		seriestype = :line
	)
end

# ╔═╡ fddb64e3-1105-4bb2-8203-45f0ecf838f0
disagreement_plot()

# ╔═╡ 75a4a84d-4693-4056-a4cc-489fc0bd4c84
let
	p = plot(disagreement_plot(), size = presentation_maxsize, aspect_ratio = 0.06)
	
	savefig(p,
		paths[:presentation_figures] * "order_pref_by_disagreement.svg")
end

# ╔═╡ ff838e65-dc60-4340-b56c-845c43c112d9
let
	p1 = plot(disagreement_plot(), 
		legend = nothing, guidefontsize = 10)
	
	p2 = plot(confidence_plot(), 
		legend = nothing, guidefontsize = 10)
	
	p = plot(p1, p2, layout = (1,2), size = (600, 300))
	
	savefig(p,
		paths[:presentation_figures] * "order_pref_by_disagreement_and_confidence.svg"
	)
end

# ╔═╡ Cell order:
# ╠═8b8a92c6-d032-11eb-0137-afbbf72b726d
# ╠═aaa9134a-c7b8-486a-b7f8-62f9450c4fd2
# ╠═97033e82-8d7a-4202-b8e5-08d741b90394
# ╠═44b4cf10-7b86-4e13-95ec-2ab825f7b2a3
# ╟─cbeb0915-0f02-44f1-a3e7-a147a9fd2992
# ╟─6a370a3a-3680-45eb-91bf-1f0105fb76bb
# ╠═c548a0b4-7a06-4c8c-81b3-0210c8922315
# ╠═cd58b3fd-a128-4256-b0db-5e8e2352c25e
# ╠═5ab54f01-ea3d-40df-bceb-a953d2b9144f
# ╠═f1d76242-e88d-4144-a206-912ee6f27c19
# ╟─76c2ed8b-a354-4c70-819a-410f968d85d0
# ╠═6cac4352-df93-4090-bb6a-d03bff6d6be1
# ╠═bda742af-8a77-4dd5-8def-3066ef3bbbdc
# ╟─aa0d3b17-73fd-4c77-8b75-69e4992c5301
# ╠═492c1c5f-ea19-4699-ad35-fb64757ed553
# ╟─ec5983f3-078a-4b7c-a001-ca5aded6659f
# ╠═49abd597-ef9a-4be6-8862-010c7e301437
# ╠═adcfea9e-4a77-4046-a12a-3ba652aefbbc
# ╠═a68bbb19-5b2b-4eaa-8107-3baad14a7450
# ╠═60eb98a2-c0e9-4002-bddf-914c70235e34
# ╠═4cbb255c-f33c-4c5a-93ea-50c5f80fb786
# ╟─67ecf720-a4bd-41e8-adbe-230b34024fd0
# ╟─a732fdce-9182-4b64-a1e0-4b8b1b27a7bb
# ╟─3c64c464-8a4d-411a-9c75-f9c670716003
# ╠═06e8e659-314b-4d06-8f78-9e2c08c9ff1b
# ╠═912a7297-1a09-40d0-9ea6-53996c43e0e1
# ╟─96eadf44-7d94-46c5-a8ef-6724c927e48d
# ╟─223480da-0988-436a-a37e-213dee964454
# ╠═d865e175-6765-4bd5-a4e7-3f7d9d641737
# ╟─0d166931-3e23-441b-b985-f6e91a85eb7f
# ╟─61010c9e-63d7-4999-80ca-7f2eb35fde32
# ╠═b181392f-027c-4817-b52e-af37174af9cb
# ╠═a45af2ed-3f57-4176-a807-6db2b29eafcd
# ╠═0245a16b-6da2-45b1-9671-476604065695
# ╠═cc008e68-6456-4193-ada7-7897162ea111
# ╟─ec22046e-d17e-4bf5-9424-62e53276a951
# ╠═0cebbb6d-3016-4e52-9fa9-3a74a326ae3b
# ╠═79e16b94-b17a-4bd1-b20c-efb631713531
# ╠═d5859881-16a5-4ac9-92ae-e42ab8a0007d
# ╟─39ccdc36-7c19-407c-a1ed-be0d424405f3
# ╠═65ba0667-cc6d-4d27-9a01-aaf45d9d4b10
# ╠═c14c94e7-5a62-42ea-8ca9-6fc41c67539b
# ╠═a3a10afb-1872-413d-b1a1-255a5a4536f6
# ╟─2eb3da98-f276-4d84-bfc9-6281699d92b9
# ╠═103e6f38-a325-4e8a-a680-05af49fa7aed
# ╠═ffb3d5ec-b1d1-4d46-91b3-613bef41cd70
# ╠═0db341c7-234f-4e36-9a67-e24e421629d3
# ╟─b92be1b9-556f-4381-bbdf-c141d2e0003d
# ╠═1c55f8bf-3258-41b6-854b-0d3ae76d67a5
# ╠═fddb64e3-1105-4bb2-8203-45f0ecf838f0
# ╠═7f35d271-2d38-49b7-932e-4efed601c01e
# ╠═75a4a84d-4693-4056-a4cc-489fc0bd4c84
# ╠═ff838e65-dc60-4340-b56c-845c43c112d9
