### A Pluto.jl notebook ###
# v0.14.5

using Markdown
using InteractiveUtils

# ╔═╡ e8edf6b8-c218-11eb-1fc4-7984a8fbd724
begin
    import Pkg
    Pkg.activate("..")

    try
		using CSV, DataFrames, Plots
	catch
		Pkg.instantiate()
		using CSV, DataFrames, Plots
	end
	
	theme(:wong, legend = :outerright)
end

# ╔═╡ 9d1ee5a2-ca6e-45cf-a849-745ed345d36e
all_results = CSV.read(
	"../results/results_with_disagreement.csv",
	DataFrame
)

# ╔═╡ 3f081b80-7325-4c11-907d-e2e6aa1a1b5f
md"""
## Plot acceptability by confidence

Acceptability rating on sentences based on the confidence rating for the semantic task on the same adjective.
"""

# ╔═╡ 36611088-145a-45d8-afe3-fd206c80c9ae
function plot_acceptability_by_confidence(data; kwargs...)
	#select data
	plotdata = filter(data) do row
		row.item_type == "test"
	end
	
	#convert responses to Int
	plotdata.response = parse.(Int, plotdata.response)
	
	scale = 1:5
	confidence_ratings = intersect(scale, plotdata.confidence_on_semantic)
	
	get_quantile(acceptability, confidence) = let
		filtered_confidence = filter(
			row -> row.confidence_on_semantic == confidence,
			plotdata)
		filtered_acceptability = filter(
			row -> row.response <= acceptability,
			filtered_confidence)
		nrow(filtered_acceptability) / nrow(filtered_confidence)
	end
	
	p = plot(
		xlabel = "confidence rating on semantic task",
		ylabel = "fraction of responses",
		legendtitle = "acc. rating",
		xticks = confidence_ratings
	)
	
	pal = let
		c1 = PlotThemes.wong_palette[3]
		palette(cgrad([:white, c1], 5, categorical = true))
	end
	
	for acceptability in reverse(scale)
		quantiles = map(confidence_ratings) do confidence
			get_quantile(acceptability, confidence)
		end
		
		plot!(p,
			confidence_ratings,
			quantiles,
			palette = pal,
			color = :black,
			fill = 0,
			fillcolor = acceptability,
			label = acceptability
			)
		
		#bar!(p,
		#	confidence_ratings,
		#	quantiles,
		#	palette = pal,
		#	fillcolor = acceptability,
		#	label = acceptability
		#	)
	end
	
	plot!(p; kwargs...)
	
	p
end

# ╔═╡ 064c1e7e-99bc-476f-a173-f14da6359d92
function plot_acceptability_by_confidence_per_order(data)
	p_first = let
		subdata = filter(row -> row.order === "first", data)
		plot_acceptability_by_confidence(subdata, title = "target first")
	end
	
	p_second = let
		subdata = filter(row -> row.order === "second", data)
		plot_acceptability_by_confidence(subdata, title = "target second")
	end
	
	plot(p_first, p_second, layout = (2,1), size = (600, 800))
end

# ╔═╡ 922c24fe-d2bb-429d-b743-54cf1eaa7ee5
let
	exp23_data = filter(row -> row.experiment ∈ [2,3], all_results)
	plot_acceptability_by_confidence_per_order(exp23_data)
end

# ╔═╡ 4c1298da-211f-4a30-911c-3fd650988e75
let
	exp2_data = filter(row -> row.experiment == 2, all_results)
	plot_acceptability_by_confidence_per_order(exp2_data)
end

# ╔═╡ 67c3eedd-8875-4391-92f2-31fc34d8631c
let
	exp3_data = filter(row -> row.experiment == 3, all_results)
	plot_acceptability_by_confidence_per_order(exp3_data)
end

# ╔═╡ 35e7c5d9-48c7-466e-8f0a-2dd8c503dbe3
md"""
## Plot acceptability by disagreement
"""

# ╔═╡ be5cb371-7a42-433a-a081-8500a923b9c6
names(all_results)

# ╔═╡ dac69432-ff26-4c6f-9eff-72ba69844dec
function plot_acceptability_by_disagreement(data; kwargs...)
	#select data
	plotdata = filter(data) do row
		row.item_type == "test"
	end
	
	#convert responses to Int
	plotdata.response = parse.(Int, plotdata.response)
	
	scale = 1:5
	disagreements = (sort ∘ unique)(plotdata.disagreement_on_adj_target)
	
	get_quantile(acceptability, disagreement) = let
		filtered_disagreement = filter(
			row -> row.disagreement_on_adj_target === disagreement,
			plotdata)
		filtered_acceptability = filter(
			row -> row.response <= acceptability,
			filtered_disagreement)
		nrow(filtered_acceptability) / nrow(filtered_disagreement)
	end
	
	p = plot(
		xlabel = "disagreement ratio on target adjective",
		ylabel = "fraction of responses",
		legendtitle = "acc. rating",
	)
	
	pal = let
		c1 = PlotThemes.wong_palette[3]
		palette(cgrad([:white, c1], 5, categorical = true))
	end
	
	for acceptability in reverse(scale)
		quantiles = map(disagreements) do disagreement
			get_quantile(acceptability, disagreement)
		end
		
		plot!(p,
			disagreements,
			quantiles,
			palette = pal,
			color = :black,
			fill = 0,
			fillcolor = acceptability,
			label = acceptability
			)
	end
	
	plot!(p; kwargs...)
	
	p
end

# ╔═╡ 5a1573f8-a1d6-423b-93b5-86298b149199
function plot_acceptability_by_disagreement_per_order(data)
	p_first = let
		subdata = filter(row -> row.order === "first", data)
		plot_acceptability_by_disagreement(subdata, title = "target first")
	end
	
	p_second = let
		subdata = filter(row -> row.order === "second", data)
		plot_acceptability_by_disagreement(subdata, title = "target second")
	end
	
	plot(p_first, p_second, layout = (2,1), size = (600, 800))
end

# ╔═╡ 7e52e878-aad2-4595-a71b-f5f671add02f
md"### Both experiments"

# ╔═╡ d748e507-1113-41b9-9d4b-395924b25cc4
let
	exp23_data = filter(row -> row.experiment ∈ [2,3], all_results)
	plot_acceptability_by_disagreement_per_order(exp23_data)
end

# ╔═╡ bbd14ae1-7d2d-40d1-969c-3174d9d02937
md"### Experiment 2"

# ╔═╡ 3205445c-95b9-4239-8c3b-ece01cbdbcd0
let
	exp23_data = filter(row -> row.experiment == 2, all_results)
	plot_acceptability_by_disagreement_per_order(exp23_data)
end

# ╔═╡ bab31615-3372-4d31-820a-5eb5fde315bd
md"### Experiment 3"

# ╔═╡ 0ae9257e-34bc-4d4d-8f64-565cd4a9c2a1
let
	exp23_data = filter(row -> row.experiment == 3, all_results)
	plot_acceptability_by_disagreement_per_order(exp23_data)
end

# ╔═╡ Cell order:
# ╠═e8edf6b8-c218-11eb-1fc4-7984a8fbd724
# ╠═9d1ee5a2-ca6e-45cf-a849-745ed345d36e
# ╟─3f081b80-7325-4c11-907d-e2e6aa1a1b5f
# ╠═36611088-145a-45d8-afe3-fd206c80c9ae
# ╠═064c1e7e-99bc-476f-a173-f14da6359d92
# ╟─922c24fe-d2bb-429d-b743-54cf1eaa7ee5
# ╠═4c1298da-211f-4a30-911c-3fd650988e75
# ╠═67c3eedd-8875-4391-92f2-31fc34d8631c
# ╟─35e7c5d9-48c7-466e-8f0a-2dd8c503dbe3
# ╠═be5cb371-7a42-433a-a081-8500a923b9c6
# ╠═dac69432-ff26-4c6f-9eff-72ba69844dec
# ╠═5a1573f8-a1d6-423b-93b5-86298b149199
# ╟─7e52e878-aad2-4595-a71b-f5f671add02f
# ╠═d748e507-1113-41b9-9d4b-395924b25cc4
# ╟─bbd14ae1-7d2d-40d1-969c-3174d9d02937
# ╠═3205445c-95b9-4239-8c3b-ece01cbdbcd0
# ╟─bab31615-3372-4d31-820a-5eb5fde315bd
# ╠═0ae9257e-34bc-4d4d-8f64-565cd4a9c2a1
