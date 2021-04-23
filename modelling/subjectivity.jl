### A Pluto.jl notebook ###
# v0.14.2

using Markdown
using InteractiveUtils

# ╔═╡ 14d59268-9967-11eb-3a11-b388759a33c4
begin
    import Pkg
    Pkg.activate(mktempdir())
    Pkg.add([
        Pkg.PackageSpec(name="CSV", version="0.8"),
        Pkg.PackageSpec(name="DataFrames", version="0.22"),
    ])
    using CSV, DataFrames, Statistics
end

# ╔═╡ 0629eb23-887f-45e1-8296-015fae7fba62
md"""
## Import packages and results
"""

# ╔═╡ df716478-9bd3-4896-b0ff-8afe398e590c
results = let
	all_data = CSV.read(
		"../experiment/acceptability_with_semantic/results/results_filtered.csv",
		DataFrame
	)
	
	filter(row -> row.item_type == "semantic", all_data)
end

# ╔═╡ 3b37b492-f870-4fac-939f-70aec7ffd233
md"""
## Disgreement ratio 

Define `agree_ratio` to calculate the agreement ratio in an array of `true`/`false` responses.

Let $R$ be the array of responsses. For any two participants $i$ and $j$, the probablity that $R_i = R_j$ is equal to

$P((R_i = true \land R_j = true) \lor (R_i = false \land R_j = false))$

which is equivalent to

$P(R_i = true) \times P(R_j = true) + P(R_i = false) \times P(R_j = false)$

So we can calculate the agreement ratio from $P_{pos}$ (the probability of a positive response) and $P_{neg}$ (the probability of a negative response) as

$P_{agree} = P_{pos} \times P_{pos} + P_{neg} \times P_{neg}$
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

$P_{disagree} = 1 - P_{agree}$
"""

# ╔═╡ 92743f65-b271-4fa3-b8b1-ec1de5048b43
function disagree_ratio(responses::AbstractArray)
	1 - agree_ratio(responses)
end

# ╔═╡ 2c9a5bae-14bb-4fa9-8651-38d24b523599
md"""
## Calculate for each stimuli set

We can calculate the disagreement ratio  for each item (i.e. a single TV or couch).
"""

# ╔═╡ 8d2dea08-cd8d-42d5-aaf0-e0f59a58fa33
function all_disagree_ratios(data::AbstractDataFrame)
	disagreement(responses) = disagree_ratio(parse.(Bool, responses))
	
	disagreement_per_item = combine(
		groupby(data, :id), 
		:response => disagreement,
	)
end

# ╔═╡ 9549e4d1-aa8f-4283-a1a4-fc4c3318f66c
md"""
Then take the mean to get the disgreement ratio across a set of items.
"""

# ╔═╡ f1561300-451e-4f92-b33f-6da167a1295d
function mean_disagree_ratio(data::AbstractDataFrame)
	all_ratios = all_disagree_ratios(data)
	mean(all_ratios.response_disagreement)
end

# ╔═╡ 0aa37a35-92dd-4ca4-abed-3ddb17a88353
md"""
I group the results by the target adjective, the scenario and the condition. These three factors determine the set of stimuli. 

The disgreement ratio for each set:
"""

# ╔═╡ da18f457-a761-4550-a990-f6bf87227062
let
	df = combine(
		mean_disagree_ratio,
		groupby(results, [:adj_target, :scenario, :condition])
	)
	rename(df, :x1 => :disagreement_ratio)
end

# ╔═╡ Cell order:
# ╟─0629eb23-887f-45e1-8296-015fae7fba62
# ╠═14d59268-9967-11eb-3a11-b388759a33c4
# ╠═df716478-9bd3-4896-b0ff-8afe398e590c
# ╟─3b37b492-f870-4fac-939f-70aec7ffd233
# ╠═27baafa7-e81f-43d5-b853-7b7eb6cf7fa6
# ╟─bde1f837-e6ea-4dab-bb6f-4d4fbed5e741
# ╠═92743f65-b271-4fa3-b8b1-ec1de5048b43
# ╟─2c9a5bae-14bb-4fa9-8651-38d24b523599
# ╠═8d2dea08-cd8d-42d5-aaf0-e0f59a58fa33
# ╟─9549e4d1-aa8f-4283-a1a4-fc4c3318f66c
# ╠═f1561300-451e-4f92-b33f-6da167a1295d
# ╟─0aa37a35-92dd-4ca4-abed-3ddb17a88353
# ╠═da18f457-a761-4550-a990-f6bf87227062
