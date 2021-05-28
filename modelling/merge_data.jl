### A Pluto.jl notebook ###
# v0.14.5

using Markdown
using InteractiveUtils

# ╔═╡ 549e9d6c-bf8d-11eb-27c2-d3b585c3ec61
begin
	using Pkg
	Pkg.activate("..")
	
	try
		using DataFrames, CSV
	catch
		Pkg.instantiate()
		using DataFrames, CSV
	end
end

# ╔═╡ cd110580-543a-4e75-a74b-a978327edeb2
md"""
## Merge experiment data
Import results from the three experiments and join them into one dataframe
"""

# ╔═╡ d293e45a-9617-43d4-9d77-9176fc6fbb4e
function import_results(exp)
	experiment_name = let
		names = ["acceptability", "acceptability_with_semantic", "novel_objects"]
		name = names[exp]
	end
	
	path = ("../experiment/$(experiment_name)/results/results_filtered.csv")
	CSV.read(path, DataFrame)
end

# ╔═╡ 5eaf956f-6ea8-43f4-86ac-ab7fbf7a36bc
function format_results(data, exp)
	#change participants to 101, 102, etc, so they remain unique
	data.participant = data.participant .+ (100 * exp)
	
	#add experiment column
	insertcols!(data, 1, :experiment => repeat([exp], nrow(data)))
	
	#add columns missing for exp 1
	if exp == 1
		missing_col() = repeat([missing], nrow(data))
		data.stimulus_size = missing_col()
		data.stimulus_price = missing_col()
		data.confidence_on_semantic = missing_col()
	end
	
	data
end

# ╔═╡ a33e8227-ccc2-4a92-a067-43bc5e69220e
results_per_experiment = let
	#import and format results for each experiment
	results = map(1:3) do exp
		results = import_results(exp)
		format_results(results, exp)
	end
	
	#make sure that column orders match
	map(results) do df
		df[!, names(results[3])]
	end
end

# ╔═╡ 37c06185-9965-4df2-8d9a-0c5bc1c25c11
all_results = [
	results_per_experiment[1] ; results_per_experiment[2] ; results_per_experiment[3]
]

# ╔═╡ b60818cb-58b6-4f7d-b180-0d0522e9126e
md"""
## Add disagreement ratios
Add the disagreement ratio on the semantic judgement task, so it can be used to predict acceptability.
"""

# ╔═╡ 43971206-87d5-439f-bc2e-c0afa7fa1e68
function import_disagreement(exp)
	if exp == 1
		return missing
	end
	
	path = "results/disagreement_exp$(exp).csv"
	CSV.read(path, DataFrame)
end

# ╔═╡ 49af426b-5d2b-457f-ac4e-5bc2c2a4593a
disagremeent_results = map(import_disagreement, 1:3)

# ╔═╡ b3182bff-29b5-429a-a7f1-38ec487a8e59
function get_disagreement(exp, adjective, scenario, condition)
	data = disagremeent_results[exp]
	if ismissing(data)
		return missing
	end
	
	filtered = filter(data) do row
		all([row.adj_target == adjective, row.scenario == scenario, 
				row.condition == condition])
	end
	
	first(filtered.mean_disagreement)
end

# ╔═╡ 4d6145e0-dd09-46f1-b6af-e9e718a45d4e
results_with_disagreement = let
	disagreement_target = map(eachrow(all_results)) do row
		if !ismissing(row.adj_target)
			get_disagreement(
				row.experiment, row.adj_target, row.scenario, row.condition
			)
		else
			missing
		end
	end
	
	disagreement_secondary = map(eachrow(all_results)) do row
		if row.adj_secondary === "expensive"
			get_disagreement(
				row.experiment, "expensive", row.scenario, row.condition
			)
		else
			missing
		end
	end
	
	results = copy(all_results)
	results.disagreement_on_adj_target = disagreement_target
	results.disagreement_on_adj_secondary = disagreement_secondary
	results
end

# ╔═╡ 70babcdc-b7a0-43d5-999e-ab74934de8c9
CSV.write("results/results_with_disagreement.csv", results_with_disagreement)

# ╔═╡ Cell order:
# ╠═549e9d6c-bf8d-11eb-27c2-d3b585c3ec61
# ╟─cd110580-543a-4e75-a74b-a978327edeb2
# ╠═d293e45a-9617-43d4-9d77-9176fc6fbb4e
# ╠═5eaf956f-6ea8-43f4-86ac-ab7fbf7a36bc
# ╠═a33e8227-ccc2-4a92-a067-43bc5e69220e
# ╠═37c06185-9965-4df2-8d9a-0c5bc1c25c11
# ╟─b60818cb-58b6-4f7d-b180-0d0522e9126e
# ╠═43971206-87d5-439f-bc2e-c0afa7fa1e68
# ╠═49af426b-5d2b-457f-ac4e-5bc2c2a4593a
# ╠═b3182bff-29b5-429a-a7f1-38ec487a8e59
# ╠═4d6145e0-dd09-46f1-b6af-e9e718a45d4e
# ╠═70babcdc-b7a0-43d5-999e-ab74934de8c9
