### A Pluto.jl notebook ###
# v0.14.0

using Markdown
using InteractiveUtils

# ╔═╡ 14d59268-9967-11eb-3a11-b388759a33c4
begin
	using CSV, DataFrames, Statistics
end

# ╔═╡ 27baafa7-e81f-43d5-b853-7b7eb6cf7fa6
function agree_ratio(responses::AbstractArray)
	positives = count(responses)
	negatives = count(.!(responses))
	
	p_pos = positives / length(responses)
	p_neg = negatives / length(responses)
	
	p_pos * p_pos + p_neg * p_neg
end

# ╔═╡ 92743f65-b271-4fa3-b8b1-ec1de5048b43
function disagree_ratio(responses::AbstractArray)
	1 - agree_ratio(responses)
end

# ╔═╡ 8d2dea08-cd8d-42d5-aaf0-e0f59a58fa33
function all_disagree_ratios(data::AbstractDataFrame)
	disagreement(responses) = disagree_ratio(parse.(Bool, responses))
	
	scale = first(data.adj_target) == "expensive" ? :stimulus_price : :stimulus_size
		
	
	disagreement_per_item = combine(
		groupby(data, :id), 
		scale => first,
		:response => disagreement,
	)
end

# ╔═╡ f1561300-451e-4f92-b33f-6da167a1295d
function mean_disagree_ratio(data::AbstractDataFrame)
	all_ratios = all_disagree_ratios(data)
	mean(all_ratios.response_disagreement)
end

# ╔═╡ df716478-9bd3-4896-b0ff-8afe398e590c
results = CSV.read(
	"../experiment/acceptability_with_semantic/results_filtered.csv",
	DataFrame
) ;

# ╔═╡ 0e201bf2-af91-41e5-9bbe-81eddeac1ee9
sem_data = filter(row -> row.item_type == "semantic", results)

# ╔═╡ da18f457-a761-4550-a990-f6bf87227062
let
	df = combine(
		mean_disagree_ratio,
		groupby(sem_data, [:adj_target, :scenario, :condition])
	)
	rename(df, :x1 => :disagreement_ratio)
end

# ╔═╡ 2aff82b1-1089-4eb9-b941-6daa76d9c235
function select_data(data; adjective = nothing, scenario = nothing)
	filter(data) do row
		all([
				isnothing(adjective) || (row.adj_target == adjective),
				isnothing(scenario) || (row.scenario == scenario)
			])
	end
end

# ╔═╡ Cell order:
# ╠═14d59268-9967-11eb-3a11-b388759a33c4
# ╠═27baafa7-e81f-43d5-b853-7b7eb6cf7fa6
# ╠═92743f65-b271-4fa3-b8b1-ec1de5048b43
# ╠═8d2dea08-cd8d-42d5-aaf0-e0f59a58fa33
# ╠═f1561300-451e-4f92-b33f-6da167a1295d
# ╠═da18f457-a761-4550-a990-f6bf87227062
# ╠═df716478-9bd3-4896-b0ff-8afe398e590c
# ╠═0e201bf2-af91-41e5-9bbe-81eddeac1ee9
# ╠═2aff82b1-1089-4eb9-b941-6daa76d9c235
