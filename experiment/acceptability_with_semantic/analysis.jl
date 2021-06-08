### A Pluto.jl notebook ###
# v0.14.7

using Markdown
using InteractiveUtils

# ╔═╡ 53c045a8-7032-11eb-1e32-979e2d2b7846
begin
    import Pkg
	root = "../.."
    Pkg.activate(root)

    try
		using DataFrames, CSV, Statistics, Plots
	catch
		Pkg.instantiate()
		using DataFrames, CSV, Statistics, Plots
	end

	theme(:wong, legend=:outerright) #plot theme
end

# ╔═╡ 75ed3aeb-ca7c-4db8-82e9-7fdd7b394b97
md"""
## Import
"""

# ╔═╡ fb243fdd-76ce-4ea2-b38c-d3450e9b01b1
all_results =  CSV.read(
	"results/results_filtered.csv", DataFrame,
)

# ╔═╡ 95263e12-80b6-4eeb-b36e-157e67a51850
md"""
## Confidence on semantic task
"""

# ╔═╡ 7b942347-7e3c-413a-a800-59ca7f82d137
confidence_results = let
	df = all_results[all_results.item_type .== "confidence", :]
	df.response = parse.(Int64, df.response)
	df
end

# ╔═╡ 7ade9d08-b89d-477c-8ede-c3cdbf1d4cd3
md"""
## Acceptability judgements

### Formatting
"""

# ╔═╡ 9d94d22d-6ebf-4f26-a8ed-321ebb81c972
item_results = let
	df = all_results[
		(all_results.item_type .== "test") .| (all_results.item_type .== "filler"), 
		:]
	
	df.response = parse.(Int64, df.response)
	
	df
end ;

# ╔═╡ f38b95f7-b8c5-4b14-b305-d0f5b4639d2c
md"""
### Distribution of responses 

**All responses**
"""

# ╔═╡ adbb424d-cab8-4457-9862-063d96b32f28
md"""
**Only test items**
"""

# ╔═╡ 1d618621-118b-4bd6-b7ca-a017fbb3cb63
test_results = item_results[item_results.item_type .== "test", :] ;

# ╔═╡ e5383671-e932-43f6-92fa-3e446b56b687
md"**Filler items**"

# ╔═╡ 8f63f0e9-dbcc-414e-90e0-ed815383d113
filler_results = item_results[item_results.item_type .== "filler", :] ;

# ╔═╡ 771607e6-dbbc-4883-9bad-cdd68e0d99a7
md"""
### Response time
"""

# ╔═╡ f8b4c2f0-3ed9-4225-a40d-62008ec51754
let
	times = min.(item_results.time, 20)
	
	histogram(
		times,
		bins = 41,
		label = nothing
	)
end

# ╔═╡ 860e9c66-4268-4d09-b7ce-d3b8eca84537
md"""
### Order preference


**All test data**

Compare the acceptability of *target first* ("big expensive") and *target second* ("expensive big"). 

Also compare between the bimodal condition (where the target adjective is expected to be less subjective) and the unimodal condition.
"""

# ╔═╡ 6083e4df-0a27-476f-83d8-7e9c6b21d351
md"""
**Scalar-scalar combinations**

Only compare "long expensive", "big expensive", "long cheap", "big cheap"
"""

# ╔═╡ 57d977cc-d93f-42d6-bacb-c6f06c0b4c68
scalar_data = test_results[test_results.adj_secondary_type .== "scalar", :] ;

# ╔═╡ 6dd07dbb-bd31-46c1-a5d0-f561c4ef1f87
md"""
**Absolute vs scalar combinations**

"""

# ╔═╡ 586961f3-127b-424d-8599-9cb765054850
md"**Results per adjective combination**"

# ╔═╡ d02c1bd3-8cd8-47f4-804c-c08effaac0df
md"""
## Order preference * confidence
"""

# ╔═╡ d4d8acb4-df67-4cc1-9daf-0fc0a46b5e06
condition_confidence_results = combine(
	groupby(test_results, [:order, :condition, :confidence_on_semantic]),
	:response => mean,
	:participant => length ∘ unique => "N_participants"
)

# ╔═╡ 043d1865-7a2d-4c3d-86de-e123eecfdf5f
let
	p = plot(xticks = 1:5, xlims = (1, 5),
		xlabel = "confidence rating",
		ylabel = "mean acceptability rating"
	)
	
	for order in ["first", "second"]
		for condition in ["bimodal", "unimodal"]
			data = filter(condition_confidence_results) do row
				row.order == order && row.condition == condition
			end
			
			color = condition == "bimodal" ? 1 : 2
			style = order == "first" ? :dash : :solid
			label = condition * " + " * order
			
			plot!(p, data.confidence_on_semantic, data.response_mean,
				lw = 3, color = color, linestyle = style,
				label = label,
			)
		end
	end
	
	p
end

# ╔═╡ 8075f032-15b1-43bb-8c17-86b6478386be
md"""
## Export figures
"""

# ╔═╡ 0c3d68e6-b42c-426a-81d7-30f55cba0c58
figures_path = root * "/figures/"

# ╔═╡ b6c28ed9-db7b-4247-9280-b779d84a6b94
figures_folder_exists = isdir(figures_path)

# ╔═╡ 215219a4-47a6-4c5f-b1e0-0c8c270ff3f3
md"""
## General functions
"""

# ╔═╡ 2e9afc98-7e13-45e5-ba23-d0daa4d8afb2
scale = 1:5

# ╔═╡ da8ba469-1a81-48f9-bdd8-2ae9c732ac73
function get_colour(condition)
	if condition == "bimodal"
		1
	elseif condition == "unimodal"
		2
	else
		3
	end
end

# ╔═╡ 73e91bc5-72d4-4750-bfee-60556f561d71
function get_palette(condition)
	main_colour = PlotThemes.wong_palette[get_colour(condition)]
	palette(cgrad([:white, main_colour], 5, categorical = true))
end

# ╔═╡ 24554dad-393c-4993-adea-506a61d25651
confidence_plot = let
	percentile(adjective, condition,rating) = let
		subdata = filter(confidence_results) do row
			row.condition == condition && row.adj_target == adjective
		end
		responses = subdata.response
		count(r -> r <= rating, responses) / length(responses)
	end
	
	xticklabels =  [
		"bimodal\nbig", "unimodal\nbig", 
		"bimodal\nlong", "unimodal\nlong",
		"bimodal\nexpensive", "unimodal\nexpensive"]
	
	p = plot(
		xlabel = "condition + adjective",
		ylabel = "fraction of responses",
		legendtitle = "rating",
		xticks = ([1,2,4,5,7,8], xticklabels),
		xtickfontsize = 6, legendtitlefontsize = 10,
	)
	
	adjectives = ["big", "long", "expensive"]
	conditions = ["bimodal", "unimodal"]
	
	for condition in conditions
		for rating in reverse(scale)
			bar_positions = [1,4,7] .+ (condition == "unimodal")
			percentiles = map(adj -> percentile(adj, condition, rating), adjectives)

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
	
	p
end

# ╔═╡ 94b81f46-fbfb-4ac6-9492-db7beaf61895
if figures_folder_exists
	savefig(confidence_plot, figures_path * "confidence_ratings_exp2.pdf")
end

# ╔═╡ 80bab411-8b70-43ac-bccd-8e6e531a5155
function plot_acceptability_by_confidence(data; condition = nothing, kwargs...)
	percentile(confidence, acceptability) = let
		subdata = filter(data) do row
			row.confidence_on_semantic == confidence
		end
		responses = subdata.response
		count(r -> r <= acceptability, responses) / length(responses)
	end
	
	p = plot(
		xlabel = "confidence on semantic task",
		ylabel = "fraction of responses",
		legendtitle = "acceptability",
		xticks = scale
	)

	for rating in reverse(scale)
		percentiles = map(c -> percentile(c, rating), scale)

		bar!(p,
			scale, 
			percentiles,
			palette = get_palette(condition),
			fillcolor = rating,
			label = rating,
		)
	end
	
	plot!(p; kwargs...)
	
	p
end

# ╔═╡ 69c502a7-07f7-428e-a69e-f67326cf0be6
plot_acceptability_by_confidence(test_results)

# ╔═╡ fd8a4e5a-9533-4a93-8da8-62278cc32076
let
	first_data = filter(row -> row.order == "first", test_results)
	p1 = plot_acceptability_by_confidence(first_data, title = "target first")

	second_data = filter(row -> row.order == "second", test_results)
	p2 = plot_acceptability_by_confidence(second_data, title = "target second")

	plot(p1, p2, layout = (2,1))
end

# ╔═╡ 43e082be-6457-4125-ab46-4c50d7a38bc2
function plot_response_counts(responses; kwargs...)
	counts = map(scale) do score
		count(responses .== score)
	end
	
	p = bar(scale, counts, 
		label = nothing, xlabel = "response", ylabel = "frequency";
		kwargs...
	)	
	return p
end

# ╔═╡ 934eccc1-e6e0-4183-b6bf-ff150f9acdf4
plot_response_counts(item_results.response)

# ╔═╡ f6acabc7-4c3d-4173-a6e4-e2ba65c3e3dd
plot_response_counts(test_results[:, "response"])

# ╔═╡ 5b05f3d8-c9d7-4a75-a7ac-32e34199cc88
let
	response_counts(responses) = map(scale) do score
		count(responses .== score)
	end
	
	responses(acceptability) = filler_results[
		filler_results.filler_acceptability .== acceptability,
		"response"]
	
	ymax = maximum(["acceptable", "unacceptable", "questionable"]) do acceptability
		counts = (response_counts ∘ responses)(acceptability)
		max = maximum(counts)
		max + (10 - mod(max, 10))
	end
	
	p_acceptable = plot_response_counts(
		responses("acceptable"),
		title = "acceptable",
		ylims = (0, ymax)
	)
	
	p_unacceptable = plot_response_counts(
		responses("unacceptable"),
		title = "unacceptable",
		ylims = (0, ymax)
	)
	
	p_questionable = plot_response_counts(
		responses("questionable"),
		title = "questionable",
		ylims = (0, ymax)
	)
	
	plot(p_acceptable, p_unacceptable, p_questionable, 
		layout = (1,3),
		size = (600, 300)
	)
end

# ╔═╡ 7968aaf4-c8a3-4163-bf7a-0d8935c27229
function aggregate_responses(data)
	positions =  ["first", "second"]
	order_data = map(positions) do position
		data[data.order .== position, :]
	end
	
	bimodal_means = map(order_data) do data
		condition_data = data[data.condition .== "bimodal", :]
		mean(condition_data.response)
	end
	
	unimodal_means = map(order_data) do data
		condition_data = data[data.condition .== "unimodal", :]
		mean(condition_data.response)
	end
	
	DataFrame(
		target_position = ["first", "second"],
		mean_judgement_bimodal = bimodal_means,
		mean_judgement_unimodal = unimodal_means,
	)
end

# ╔═╡ f6c3b498-ad94-4b0d-9e0d-07a4e8ca4f49
function plot_aggregated_responses(data)
	aggregated_responses = aggregate_responses(data)
	
	p = plot(
		xlabel = "position target adjective",
		ylabel = "mean acceptability",
		ylims = (3,5)
	)
	plot!(p, 
		aggregated_responses.target_position,
		aggregated_responses.mean_judgement_bimodal,
		label = "bimodal",
		lw = 3
	)
	plot!(p, 
		aggregated_responses.target_position,
		aggregated_responses.mean_judgement_unimodal,
		label = "unimodal",
		lw = 3
	)
end

# ╔═╡ 38a7e895-aba0-4988-9ae9-b50571808a22
plot_aggregated_responses(test_results)

# ╔═╡ a602dc1f-5acb-4abb-a9b0-6937709e99c8
plot_aggregated_responses(scalar_data)

# ╔═╡ 602ac2a3-7b37-4ce2-ac02-2c44cadb7ea1
function plot_stacked_bar(data; kwargs...)	
	percentile(order, condition, rating) = let
		subdata = filter(data) do row
			row.condition == condition && row.order == order
		end
		responses = subdata.response
		count(r -> r <= rating, responses) / length(responses)
	end
	
	xticklabels =  ["bimodal\ntarget first", "unimodal\ntarget first", 
		"bimodal\ntarget second", "unimodal\ntarget second"]
	
	p = plot(
		xlabel = "condition + order",
		ylabel = "fraction of responses",
		legendtitle = "rating",
		xticks = ([1,2,4,5], xticklabels),
		xtickfontsize = 7
	)
	
	orders = ["first", "second"]
	conditions = ["bimodal", "unimodal"]
	
	for condition in conditions

		for rating in reverse(scale)
			bar_positions = [1,4] .+ (condition == "unimodal")
			percentiles = map(o -> percentile(o, condition, rating), orders)

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
	
	plot!(p; kwargs...)
	
	p
end

# ╔═╡ 89d741fd-04a3-4aa2-9105-ef7da99a8f29
plot_stacked_bar(test_results)

# ╔═╡ 2e8c9de6-e28b-4625-8bcc-94709528f466
plot_stacked_bar(scalar_data)

# ╔═╡ f99af668-ddae-414f-ad51-17c58f2d4b84
let
	combinations = (sort ∘ unique ∘ zip)(test_results.adj_target, test_results.adj_secondary)
	
	plots = map(combinations) do (target, secondary)
		data = filter(test_results) do row
			row.adj_target == target && row.adj_secondary == secondary
		end
		
		plot_stacked_bar(data, 
			title = "$(target) + $(secondary)",
			legend = :none, xtickfontsize = :5, guidefontsize = 8)
	end
	
	plot(plots..., layout = (4,2), size = (600, 700))
end

# ╔═╡ 82445e02-482b-4e67-8e5d-28c648e0aa2c
if figures_folder_exists
	savefig(plot_stacked_bar(test_results),
		figures_path * "acceptability_results_exp2.pdf"
	)
end

# ╔═╡ b8ba1ee7-9be6-4e5b-b6c9-0437e5d717ed
function plot_scalar_vs_absolute(data)
	percentile(order, secondary_type, rating) = let
		subdata = filter(data) do row
			row.adj_secondary_type == secondary_type && row.order == order
		end
		responses = subdata.response
		count(r -> r <= rating, responses) / length(responses)
	end
	
	xticklabels =  ["scalar\ntarget first", "absolute\ntarget first", 
		"scalar\ntarget second", "absolute\ntarget second"]
	
	p = plot(
		xlabel = "type of secondary adjective + order",
		ylabel = "fraction of responses",
		legendtitle = "rating",
		xticks = ([1,2,4,5], xticklabels),
		xtickfontsize = 7
	)
	
	orders = ["first", "second"]
	secondary_types = ["scalar", "absolute"]
	
	get_colour(secondary_type) = secondary_type == "scalar" ? 3 : 7
	get_palette(secondary_type) = let
		main_colour = PlotThemes.wong_palette[get_colour(secondary_type)]
		palette(cgrad([:white, main_colour], 5, categorical = true))
	end
	
	for secondary_type in secondary_types
		for rating in reverse(scale)
			bar_positions = [1,4] .+ (secondary_type == "absolute")
			percentiles = map(o -> percentile(o, secondary_type, rating), orders)

			bar!(p,
				bar_positions, 
				percentiles,
				palette = get_palette(secondary_type),
				fillcolor = rating,
				bar_width = 0.7,
				label = rating,
			)
		end
	end
	
	p
end

# ╔═╡ b2a7f59c-fe1a-4419-a2c9-9b6d57e0d029
plot_scalar_vs_absolute(test_results)

# ╔═╡ 5d87cd27-79af-46ba-9564-c9884a3b290d
if figures_folder_exists
	savefig(plot_scalar_vs_absolute(test_results),
		figures_path * "acceptability_scalar_vs_absolute_exp2.pdf"
	)
end

# ╔═╡ Cell order:
# ╟─75ed3aeb-ca7c-4db8-82e9-7fdd7b394b97
# ╠═53c045a8-7032-11eb-1e32-979e2d2b7846
# ╠═fb243fdd-76ce-4ea2-b38c-d3450e9b01b1
# ╟─95263e12-80b6-4eeb-b36e-157e67a51850
# ╠═7b942347-7e3c-413a-a800-59ca7f82d137
# ╠═24554dad-393c-4993-adea-506a61d25651
# ╟─7ade9d08-b89d-477c-8ede-c3cdbf1d4cd3
# ╠═9d94d22d-6ebf-4f26-a8ed-321ebb81c972
# ╟─f38b95f7-b8c5-4b14-b305-d0f5b4639d2c
# ╠═934eccc1-e6e0-4183-b6bf-ff150f9acdf4
# ╟─adbb424d-cab8-4457-9862-063d96b32f28
# ╠═1d618621-118b-4bd6-b7ca-a017fbb3cb63
# ╟─f6acabc7-4c3d-4173-a6e4-e2ba65c3e3dd
# ╟─e5383671-e932-43f6-92fa-3e446b56b687
# ╠═8f63f0e9-dbcc-414e-90e0-ed815383d113
# ╠═5b05f3d8-c9d7-4a75-a7ac-32e34199cc88
# ╟─771607e6-dbbc-4883-9bad-cdd68e0d99a7
# ╠═f8b4c2f0-3ed9-4225-a40d-62008ec51754
# ╟─860e9c66-4268-4d09-b7ce-d3b8eca84537
# ╠═89d741fd-04a3-4aa2-9105-ef7da99a8f29
# ╟─38a7e895-aba0-4988-9ae9-b50571808a22
# ╟─6083e4df-0a27-476f-83d8-7e9c6b21d351
# ╠═57d977cc-d93f-42d6-bacb-c6f06c0b4c68
# ╠═2e8c9de6-e28b-4625-8bcc-94709528f466
# ╟─a602dc1f-5acb-4abb-a9b0-6937709e99c8
# ╟─6dd07dbb-bd31-46c1-a5d0-f561c4ef1f87
# ╟─b2a7f59c-fe1a-4419-a2c9-9b6d57e0d029
# ╟─586961f3-127b-424d-8599-9cb765054850
# ╟─f99af668-ddae-414f-ad51-17c58f2d4b84
# ╟─d02c1bd3-8cd8-47f4-804c-c08effaac0df
# ╠═d4d8acb4-df67-4cc1-9daf-0fc0a46b5e06
# ╠═69c502a7-07f7-428e-a69e-f67326cf0be6
# ╠═fd8a4e5a-9533-4a93-8da8-62278cc32076
# ╠═043d1865-7a2d-4c3d-86de-e123eecfdf5f
# ╠═80bab411-8b70-43ac-bccd-8e6e531a5155
# ╟─8075f032-15b1-43bb-8c17-86b6478386be
# ╠═0c3d68e6-b42c-426a-81d7-30f55cba0c58
# ╠═b6c28ed9-db7b-4247-9280-b779d84a6b94
# ╠═94b81f46-fbfb-4ac6-9492-db7beaf61895
# ╠═82445e02-482b-4e67-8e5d-28c648e0aa2c
# ╠═5d87cd27-79af-46ba-9564-c9884a3b290d
# ╟─215219a4-47a6-4c5f-b1e0-0c8c270ff3f3
# ╠═2e9afc98-7e13-45e5-ba23-d0daa4d8afb2
# ╠═da8ba469-1a81-48f9-bdd8-2ae9c732ac73
# ╠═73e91bc5-72d4-4750-bfee-60556f561d71
# ╠═43e082be-6457-4125-ab46-4c50d7a38bc2
# ╠═7968aaf4-c8a3-4163-bf7a-0d8935c27229
# ╠═f6c3b498-ad94-4b0d-9e0d-07a4e8ca4f49
# ╠═602ac2a3-7b37-4ce2-ac02-2c44cadb7ea1
# ╠═b8ba1ee7-9be6-4e5b-b6c9-0437e5d717ed
