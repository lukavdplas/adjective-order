### A Pluto.jl notebook ###
# v0.14.5

using Markdown
using InteractiveUtils

# ╔═╡ 14d59268-9967-11eb-3a11-b388759a33c4
begin
    import Pkg
    Pkg.activate("..")

    try
		using CSV, DataFrames, Statistics, Plots, HypothesisTests
	catch
		Pkg.instantiate()
		using CSV, DataFrames, Statistics, Plots, HypothesisTests
	end
	
	theme(:wong, legend = :outerright)
end

# ╔═╡ 0629eb23-887f-45e1-8296-015fae7fba62
md"""
## Import packages and results
"""

# ╔═╡ 96785983-8cb6-4129-90a8-5593f302f642
all_results_exp2 = CSV.read(
	"../experiment/acceptability_with_semantic/results/results_filtered.csv",
	DataFrame
) ;

# ╔═╡ df716478-9bd3-4896-b0ff-8afe398e590c
results_exp2 = filter(row -> row.item_type == "semantic", all_results_exp2)

# ╔═╡ 86ea9f21-27b0-4bab-b66c-1f42e84406d8
all_results_exp3 = CSV.read(
	"../experiment/novel_objects/results/results_filtered.csv",
	DataFrame
) ;

# ╔═╡ fe482323-1aee-4711-b6bf-cab1eafda5c4
results_exp3 = filter(row -> row.item_type == "semantic", all_results_exp3)

# ╔═╡ 3b37b492-f870-4fac-939f-70aec7ffd233
md"""
## Disgreement ratio 

Define `agree_ratio` to calculate the agreement ratio in an array of `true`/`false` responses.

Let $s$ be the array of responsses. For any two participants $i$ and $j$, the probablity that $s_i = s_j$ is equal to

$P((s_i = true \land s_j = true) \lor (s_i = false \land s_j = false))$

which is equivalent to

$P(s_i = true) \cdot P(s_j = true) + P(s_i = false) \cdot P(s_j = false)$

So we can calculate the agreement ratio from $p_{pos}$ (the probability of a positive response) and $p_{neg}$ (the probability of a negative response) as

$p_{agree} = {p_{pos}}^2 + {p_{neg}}^2$
"""

# ╔═╡ 27baafa7-e81f-43d5-b853-7b7eb6cf7fa6
function agree_ratio(responses::AbstractArray)
	positives = count(responses)
	negatives = count(.!(responses))
	
	p_pos = positives / length(responses)
	p_neg = negatives / length(responses)
	
	p_pos^2 + p_neg^2
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
	
	sorted_data = sort(data, :condition)
	for group in groupby(sorted_data, [:scenario, :adj_target])
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
		groupby(data, [:id, :condition]),
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

# ╔═╡ 94b5be02-b21e-470e-9f79-e35652cc502c
md"""
### Test significance
Test if the condition has a significant effect on disagreement.

Each item in the sample (i.e. a single TV, couch, etc.) is considered a single datapoint, so we can compare the data between conditions.

The disagreement rates are not normally distributed:
"""

# ╔═╡ 8e7e2b92-ff0a-49e5-b467-c051b4cf61ac
let
	results = [item_disagreement_exp2, item_disagreement_exp3]
	subplots = map(enumerate(results)) do (i, data)
		histogram(data.disagreement, 
			bins = 10, 
			legend = :none, 
			title = "experiment $(i + 1)",
			xlabel = "disagreement", ylabel = "N")
	end
	
	plot(subplots..., layout = (1,2))
end

# ╔═╡ 54a41360-49a8-455a-a745-b55d50bb3a7a
md"""
So I use the Mann-Whitney U test to test the effect of condition on disagreement. Unlike a t-test, this does not assume a normal distribution.
"""

# ╔═╡ a377771c-cc71-473e-b302-565a3437e6b6
function test_condition_on_disagreement(data, adjectives)
	data_subset = filter(data) do row
		row.adj_target ∈ adjectives
	end
	
	bimodal_items = filter(row -> row.condition == "bimodal", data_subset)
	unimodal_items = filter(row -> row.condition == "unimodal", data_subset)
	
	MannWhitneyUTest(unimodal_items.disagreement, bimodal_items.disagreement)
end

# ╔═╡ 71863277-9237-4807-be1d-9ee5064e6dda
md"""
**Experiment 2**

Results for "big" and "long" in experiment 2:
"""

# ╔═╡ 2194484a-eac0-49d3-9ba2-5fd94a2d265d
let
	res = test_condition_on_disagreement(item_disagreement_exp2, ["long"])
	res, pvalue(res, tail = :right)
end

# ╔═╡ 5a20c3bb-1e0b-460d-bb76-6e16d5bc21bc
let
	res = test_condition_on_disagreement(item_disagreement_exp2, ["big"])
	res, pvalue(res, tail = :right)
end

# ╔═╡ 7aa29154-4f62-4219-ad22-5c7adc0011a2
let
	res = test_condition_on_disagreement(item_disagreement_exp2, ["big", "long"])
	res, pvalue(res, tail = :right)
end

# ╔═╡ 771c844e-f335-4a3e-bdbe-6dd782eb6552
md"""Test for "expensive" (with two-sided p-value)"""

# ╔═╡ 212b6244-53ad-450f-b201-b2f0ff010dcd
let
	res = test_condition_on_disagreement(item_disagreement_exp2, ["expensive"])
	res, pvalue(res, tail = :both)
end

# ╔═╡ 932e5f1d-a69f-47bb-b170-65c8b2b01464
md"""
**Experiment 3**

Again testing "big" and "long":
"""

# ╔═╡ 10de0330-8ea4-4071-876b-1a767f2adc01
let
	res = test_condition_on_disagreement(item_disagreement_exp3, ["long"])
	res, pvalue(res, tail = :right)
end

# ╔═╡ c2828053-d8b5-4d13-8873-6a7a74dfef05
let
	res = test_condition_on_disagreement(item_disagreement_exp3, ["big"])
	res, pvalue(res, tail = :right)
end

# ╔═╡ b7203af3-5712-4df6-bbef-830696f9d702
let
	res = test_condition_on_disagreement(item_disagreement_exp3, ["big", "long"])
	res, pvalue(res, tail = :right)
end

# ╔═╡ f7361ccc-c648-499b-93e5-a92f59b97d32
md"""
## Disagreement and confidence

Plot the relationship between the disagreement ratio and confidence ratings

The statistics for this are done in an ordinal model in R.

Extract confidence data:
"""

# ╔═╡ 262544b4-9ed2-4eec-9998-5b1049046f08
begin
	is_confidence_item(row) = row.item_type == "confidence"
	confidence_results_exp2 = filter(is_confidence_item, all_results_exp2)
	confidence_results_exp3 = filter(is_confidence_item, all_results_exp3)
end ;

# ╔═╡ e21ffb39-ebc7-4da6-93ac-67411448e43e
md"Define a plot function"

# ╔═╡ 1d27ec93-5509-4dff-af1a-2eb7e183412a
function plot_confidence_disagreement(results)
	#get all adjective+condition cases that actually appear in the data
	cases = let
		groups = groupby(results, [:adj_target, :condition])
		all_combinations = [
			(first(data.adj_target), first(data.condition)) for data in groups
		]
		filter(all_combinations) do (adjective, condition)
			!ismissing(adjective) && !ismissing(condition)
		end
	end
	
	#disagreement for an adjective+condition case
	disagreement(case) = let
		adjective, condition = case
		data = filter(results) do row
			all([row.adj_target == adjective,
				row.condition == condition,
				row.item_type == "semantic"])
		end
		mean(disagreement_per_item(data).disagreement)
	end
	
	#total observations for a case
	total_observations(case) = let
		adjective, condition = case
		data = filter(results) do row
			all([row.adj_target == adjective,
				row.condition == condition,
				row.item_type == "confidence"])
		end
		nrow(data)
	end
	
	#sort cases by disagreement ratio for the plot
	sorted_cases = sort(cases, by = disagreement)
	disagreements = disagreement.(sorted_cases)
	
	p = plot(
		xlabel = "disagreement ratio",
		ylabel = "fraction of responses",
		legendtitle = "rating",
	)
	
	pal = let
		c1 = PlotThemes.wong_palette[3]
		palette(cgrad([:white, c1], 5, categorical = true))
	end
	
	for rating in 5:-1:1
		data = filter(results) do row
			row.item_type == "confidence" && parse(Int, row.response) <= rating
		end

		counts = map(sorted_cases) do (adjective, condition)
			subdata = filter(data) do row
				row.adj_target == adjective && row.condition == condition
			end
			nrow(subdata) / total_observations((adjective, condition))
		end
		
		plot!(p,
			disagreements, 
			counts,
			label = rating,
			linecolor = :black,
			fill = 0,
			palette = pal,
			fillcolor = rating,
		)
	end
	
	p
end

# ╔═╡ 14201d40-f60b-447b-b317-6e08c463f4fd
plot_confidence_disagreement(all_results_exp2)

# ╔═╡ 212d8e6d-afee-44fe-a633-35e2423dfa44
plot_confidence_disagreement(all_results_exp3)

# ╔═╡ c525c29a-8aff-497e-b8a3-50ea03073c5d
md"### Export plots"

# ╔═╡ 2274e8b9-ef94-402b-a17d-5dcf6bd471ea
root = ".."

# ╔═╡ 2b93bb69-d6b4-43e4-80cb-9e8904b74dff
function export_figure(plot, name)
	if "figures" ∈ readdir(root)
		plot_path = root * "/figures/"
		savefig(
			plot_disagreement(disagreement_results_exp2),
			plot_path * "disagreement_results_exp2.pdf"
		)
		md"Figure saved! ✨"
	else
		md"No `figures` folder 😪"
	end
end

# ╔═╡ 413acb58-81de-49bb-a00b-70b60a850dd9
export_figure(
	plot_disagreement(disagreement_results_exp2),
	"disagreement_results_exp2.pdf"
)

# ╔═╡ 7b53bca9-ac63-47af-8457-d5f42b6b2b79
export_figure(
	plot_disagreement(disagreement_results_exp3),
	"disagreement_results_exp3.pdf"
)

# ╔═╡ de9692b1-8ceb-4a37-86b0-1c94c228b9fb
export_figure(
	plot_confidence_disagreement(all_results_exp2),
	"confidence_disagreement_results_exp2.pdf"
)

# ╔═╡ fe4773f1-4637-4557-a75b-dca60b0e3fc9
export_figure(
	plot_confidence_disagreement(all_results_exp3),
	"confidence_disagreement_results_exp3.pdf"
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
# ╠═96785983-8cb6-4129-90a8-5593f302f642
# ╠═df716478-9bd3-4896-b0ff-8afe398e590c
# ╠═86ea9f21-27b0-4bab-b66c-1f42e84406d8
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
# ╟─94b5be02-b21e-470e-9f79-e35652cc502c
# ╟─8e7e2b92-ff0a-49e5-b467-c051b4cf61ac
# ╟─54a41360-49a8-455a-a745-b55d50bb3a7a
# ╠═a377771c-cc71-473e-b302-565a3437e6b6
# ╟─71863277-9237-4807-be1d-9ee5064e6dda
# ╠═2194484a-eac0-49d3-9ba2-5fd94a2d265d
# ╠═5a20c3bb-1e0b-460d-bb76-6e16d5bc21bc
# ╠═7aa29154-4f62-4219-ad22-5c7adc0011a2
# ╟─771c844e-f335-4a3e-bdbe-6dd782eb6552
# ╠═212b6244-53ad-450f-b201-b2f0ff010dcd
# ╟─932e5f1d-a69f-47bb-b170-65c8b2b01464
# ╠═10de0330-8ea4-4071-876b-1a767f2adc01
# ╠═c2828053-d8b5-4d13-8873-6a7a74dfef05
# ╠═b7203af3-5712-4df6-bbef-830696f9d702
# ╟─f7361ccc-c648-499b-93e5-a92f59b97d32
# ╠═262544b4-9ed2-4eec-9998-5b1049046f08
# ╟─e21ffb39-ebc7-4da6-93ac-67411448e43e
# ╠═1d27ec93-5509-4dff-af1a-2eb7e183412a
# ╠═14201d40-f60b-447b-b317-6e08c463f4fd
# ╠═212d8e6d-afee-44fe-a633-35e2423dfa44
# ╟─c525c29a-8aff-497e-b8a3-50ea03073c5d
# ╠═2274e8b9-ef94-402b-a17d-5dcf6bd471ea
# ╠═2b93bb69-d6b4-43e4-80cb-9e8904b74dff
# ╠═413acb58-81de-49bb-a00b-70b60a850dd9
# ╠═7b53bca9-ac63-47af-8457-d5f42b6b2b79
# ╠═de9692b1-8ceb-4a37-86b0-1c94c228b9fb
# ╠═fe4773f1-4637-4557-a75b-dca60b0e3fc9
# ╟─294da086-eddb-4268-a53a-3c20eaedcbfd
# ╠═bc0f4263-b1f4-46c9-9506-2c5db0dfadef
# ╠═72508777-18f5-4dc8-b441-8e21ef154550
