### A Pluto.jl notebook ###
# v0.14.5

using Markdown
using InteractiveUtils

# ╔═╡ 14d59268-9967-11eb-3a11-b388759a33c4
begin
    import Pkg
    Pkg.activate("..")

    try
		using CSV, DataFrames, Statistics, Plots
	catch
		Pkg.instantiate()
		using CSV, DataFrames, Statistics, Plots
	end
	
	theme(:wong, legend = :outerright)
end

# ╔═╡ 0629eb23-887f-45e1-8296-015fae7fba62
md"""
## Import packages and results
"""

# ╔═╡ df716478-9bd3-4896-b0ff-8afe398e590c
results_exp2 = let
	all_data = CSV.read(
		"../experiment/acceptability_with_semantic/results/results_filtered.csv",
		DataFrame
	)
	
	filter(row -> row.item_type == "semantic", all_data)
end

# ╔═╡ fe482323-1aee-4711-b6bf-cab1eafda5c4
results_exp3 = let
	all_data = CSV.read(
		"../experiment/novel_objects/results/results_filtered.csv",
		DataFrame
	)
	
	filter(row -> row.item_type == "semantic", all_data)
end

# ╔═╡ 3b37b492-f870-4fac-939f-70aec7ffd233
md"""
## Disgreement ratio 

Define `agree_ratio` to calculate the agreement ratio in an array of `true`/`false` responses.

Let $s$ be the array of responsses. For any two participants $i$ and $j$, the probablity that $s_i = s_j$ is equal to

$P((s_i = true \land s_j = true) \lor (s_i = false \land s_j = false))$

which is equivalent to

$P(s_i = true) \cdot P(s_j = true) + P(s_i = false) \cdot P(s_j = false)$

So we can calculate the agreement ratio from $p_{pos}$ (the probability of a positive response) and $p_{neg}$ (the probability of a negative response) as

$p_{agree} = p_{pos} \times p_{pos} + p_{neg} \times p_{neg}$
"""

# ╔═╡ 27baafa7-e81f-43d5-b853-7b7eb6cf7fa6
function agree_ratio(responses::AbstractArray)
	positives = count(responses)
	negatives = count(.!(responses))
	
	p_pos = positives / length(responses)
	p_neg = negatives / length(responses)
	
	p_pos * p_pos + p_neg * p_neg
end

# ╔═╡ bde1f837-e6ea-4dab-bb6f-4d4fbed5e741
md"""
Then 

$p_{disagree} = 1 - p_{agree}$
"""

# ╔═╡ 92743f65-b271-4fa3-b8b1-ec1de5048b43
function disagree_ratio(responses::AbstractArray)
	responses = parse.(Bool, responses)
	1 - agree_ratio(responses)
end

# ╔═╡ 2c9a5bae-14bb-4fa9-8651-38d24b523599
md"""
## Calculate for each stimuli set

We can calculate the disagreement ratio  for each item (i.e. a single TV or couch).
"""

# ╔═╡ 8d2dea08-cd8d-42d5-aaf0-e0f59a58fa33
function all_disagree_ratios(ids, responses)
	disagreement(responses) = disagree_ratio(responses)
	
	data = DataFrame("id" => ids, "response" => responses)
	
	disagreement_per_item = combine(
		groupby(data, :id), 
		:response => disagreement,
	)
	
	disagreement_per_item.response_disagreement
end

# ╔═╡ 9549e4d1-aa8f-4283-a1a4-fc4c3318f66c
md"""
Then take the mean to get the disgreement ratio across a set of items.
"""

# ╔═╡ 0aa37a35-92dd-4ca4-abed-3ddb17a88353
md"""
I group the results by the target adjective, the scenario and the condition. These three factors determine the set of stimuli. 

The disgreement ratio for each set:
"""

# ╔═╡ e0d2ddfc-dc8e-4457-a5c6-b876cdbaa0e8
function format_results(data)
	scale(adjective) = adjective == "expensive" ? "price" : "size"
	df = combine(
		groupby(data, [:adj_target, :scenario, :condition]),
		:adj_target => scale ∘ first => "scale",
		[:id, :response] => mean ∘ all_disagree_ratios => "mean_disagreement",
	)
end

# ╔═╡ da18f457-a761-4550-a990-f6bf87227062
disagreement_results_exp2 = format_results(results_exp2)

# ╔═╡ 981cedcd-6360-4ca5-badf-013e0949a61f
disagreement_results_exp3 = format_results(results_exp3)

# ╔═╡ 4386d4a2-00fb-43b1-939e-1d10554ea0f0
md"""
## Plot mean disagreement
"""

# ╔═╡ d4cfb160-9f8c-417a-ac27-7e437573727d
function plot_disagreement(data)
	p = plot(
		xlabel = "condition",
		xlims = (0.4,1.6),
		ylims = (0.0, 0.35),
		yticks = 0.0:0.05:0.35,
		ylabel = "disagreement ratio"
	)
	
	get_colour(scenario) = (scenario == "tv") || (scenario == "ball") ? 1 : 2
	get_linestyle(adjective) = adjective == "expensive" ? :dash : :solid
	get_markershape(adjective) = adjective == "expensive" ? :utriangle : :circle
	
	for group in groupby(data, [:scenario, :adj_target])
		adjective = first(group.adj_target)
		scenario = first(group.scenario)
		phrase = adjective * " * " * scenario
		plot!(p,
			group.condition,
			group.mean_disagreement,
			label = phrase,
			color = get_colour(scenario),
			linestyle = get_linestyle(adjective),
			markershape = get_markershape(adjective)
		)
	end
	
	p
end

# ╔═╡ 376dfa4f-deb9-41b3-870b-03c360dd514f
plot_disagreement(disagreement_results_exp2)

# ╔═╡ 90092303-1644-44bb-801f-0b974d791297
plot_disagreement(disagreement_results_exp3)

# ╔═╡ 9a7fed2e-3049-4f0d-8fc5-12fd4fd853af
md"""
## Disagreement per item
"""

# ╔═╡ 72ef58d5-32a3-49b7-8dcd-acbbd387099b
function disagreement_per_item(data)
	scale(adjective) = adjective == "expensive" ? "price" : "size"
	df = combine(
		groupby(data, [:id]),
		:scenario => first => :scenario,
		:adj_target => first => :adj_target,
		:condition => first => :condition,
		:adj_target => scale ∘ first => :scale,
		[:response] => disagree_ratio => :disagreement,
	)
end

# ╔═╡ bc16306d-e77e-401e-9902-5741d3ae43d5
item_disagreement_exp2 = disagreement_per_item(results_exp2)

# ╔═╡ 087f96fa-f0e8-4053-b191-a38b16848518
item_disagreement_exp3 = disagreement_per_item(results_exp3)

# ╔═╡ c525c29a-8aff-497e-b8a3-50ea03073c5d
md"### Export plots"

# ╔═╡ c03f946c-4933-47b7-9c67-8a708deae41c
plot_path = "../figures/"

# ╔═╡ 413acb58-81de-49bb-a00b-70b60a850dd9
savefig(
	plot_disagreement(disagreement_results_exp2),
	plot_path * "disagreement_results_exp2.pdf"
)

# ╔═╡ 7b53bca9-ac63-47af-8457-d5f42b6b2b79
savefig(
	plot_disagreement(disagreement_results_exp3),
	plot_path * "disagreement_results_exp3.pdf"
)

# ╔═╡ 294da086-eddb-4268-a53a-3c20eaedcbfd
md"### Export data"

# ╔═╡ bc0f4263-b1f4-46c9-9506-2c5db0dfadef
CSV.write("results/disagreement_exp2.csv", disagreement_results_exp2)

# ╔═╡ 72508777-18f5-4dc8-b441-8e21ef154550
CSV.write("results/disagreement_exp3.csv", disagreement_results_exp3)

# ╔═╡ Cell order:
# ╟─0629eb23-887f-45e1-8296-015fae7fba62
# ╠═14d59268-9967-11eb-3a11-b388759a33c4
# ╠═df716478-9bd3-4896-b0ff-8afe398e590c
# ╠═fe482323-1aee-4711-b6bf-cab1eafda5c4
# ╟─3b37b492-f870-4fac-939f-70aec7ffd233
# ╠═27baafa7-e81f-43d5-b853-7b7eb6cf7fa6
# ╟─bde1f837-e6ea-4dab-bb6f-4d4fbed5e741
# ╠═92743f65-b271-4fa3-b8b1-ec1de5048b43
# ╟─2c9a5bae-14bb-4fa9-8651-38d24b523599
# ╠═8d2dea08-cd8d-42d5-aaf0-e0f59a58fa33
# ╟─9549e4d1-aa8f-4283-a1a4-fc4c3318f66c
# ╟─0aa37a35-92dd-4ca4-abed-3ddb17a88353
# ╠═e0d2ddfc-dc8e-4457-a5c6-b876cdbaa0e8
# ╠═da18f457-a761-4550-a990-f6bf87227062
# ╠═981cedcd-6360-4ca5-badf-013e0949a61f
# ╟─4386d4a2-00fb-43b1-939e-1d10554ea0f0
# ╠═d4cfb160-9f8c-417a-ac27-7e437573727d
# ╠═376dfa4f-deb9-41b3-870b-03c360dd514f
# ╠═90092303-1644-44bb-801f-0b974d791297
# ╟─9a7fed2e-3049-4f0d-8fc5-12fd4fd853af
# ╠═72ef58d5-32a3-49b7-8dcd-acbbd387099b
# ╠═bc16306d-e77e-401e-9902-5741d3ae43d5
# ╠═087f96fa-f0e8-4053-b191-a38b16848518
# ╟─c525c29a-8aff-497e-b8a3-50ea03073c5d
# ╠═c03f946c-4933-47b7-9c67-8a708deae41c
# ╠═413acb58-81de-49bb-a00b-70b60a850dd9
# ╠═7b53bca9-ac63-47af-8457-d5f42b6b2b79
# ╟─294da086-eddb-4268-a53a-3c20eaedcbfd
# ╠═bc0f4263-b1f4-46c9-9506-2c5db0dfadef
# ╠═72508777-18f5-4dc8-b441-8e21ef154550
