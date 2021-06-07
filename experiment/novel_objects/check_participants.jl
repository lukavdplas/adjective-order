### A Pluto.jl notebook ###
# v0.14.7

using Markdown
using InteractiveUtils

# ╔═╡ 254b6cda-8c9c-11eb-1c41-353023a58eea
begin	
    import Pkg
    Pkg.activate("../..")
	
	try
    	using DataFrames, CSV, Statistics, Plots
	catch
		Pkg.instantiate()
		using DataFrames, CSV, Statistics, Plots
	end

	theme(:wong, legend=:outerright) #plot theme
end

# ╔═╡ d03b1c2f-eba4-41ec-ae2b-5c89152a9212
md"""
# Check participant-level data

Collect some information at participant-level (like demographics) and filter participants.
"""

# ╔═╡ 2a989224-fc5e-4220-a0e6-9d38ff7eba0b
md"""
## Demographics

### Native speakers

Are all participants native speakers?"""

# ╔═╡ 32712abf-66a0-41b3-bcbc-5de9e81baf5e
md"Oh no! Let's see how many are non-native."

# ╔═╡ 5f75473f-4b24-4e34-8d67-549353d8469b
md"We'll use `is_native` to filter participants later."

# ╔═╡ 5624a07b-8ae8-4985-b720-8accec48bd1b
md"""
### Other languages

"Besides English, how many other languages do you speak fluently?"
"""

# ╔═╡ 4e58b1a9-e516-43c3-a12d-a03bf826b63d
md"""
### Gender
"""

# ╔═╡ 1ee0a1a6-4723-4e7c-80d8-717da6664749
md"""
## Duration
"""

# ╔═╡ e234d0db-84e2-400d-b840-467d61432891
md"""
## Filler responses
"""

# ╔═╡ 25d7774c-fafb-4c99-8a72-81829f2e8030
function filler_correct_count(data; absolute = true)
	
	is_positive(response) = response ∈ ["4", "5"]
	is_negative(response) = response ∈ ["1", "2"]
	
	true_positives = filter(data) do row
		(row.filler_acceptability == "acceptable") && is_positive(row.response)
	end
	
	true_negatives = filter(data) do row
		(row.filler_acceptability == "unacceptable") && is_negative(row.response)
	end
	
	total = filter(data) do row
		(row.filler_acceptability == "acceptable") || (row.filler_acceptability == "unacceptable")
	end
	
	if absolute
		nrow(true_negatives) + nrow(true_positives)
	else
		(nrow(true_negatives) + nrow(true_positives)) / nrow(total)
	end
end

# ╔═╡ 6d3d96e0-79f3-436c-9e16-824a88e38fa0
filler_threshold = 0.7

# ╔═╡ 357879b1-371c-4aa7-bfec-d4b853a109cc
md"""
## Acceptability judgements
"""

# ╔═╡ 5bc8041c-a195-4c67-b83e-2f2fdfe8059a
md"""
## Semantic judgements
"""

# ╔═╡ 760480fc-6334-4273-be1b-af7882d21636
function average_precision(responses, values)
	precision(responses, targets) = count(targets .& responses) / count(responses)
	recall(responses, targets) = count(targets .& responses) / count(targets)
	
	thresholds = (reverse ∘ sort)(values)
	
	precisions = map(thresholds) do threshold
		targets = values .>= threshold
		precision(responses, targets)
	end

	recalls = map(thresholds) do threshold
		targets = values .>= threshold
		recall(responses, targets)
	end
	append!(recalls, [0.0])
	
	sum(1:length(thresholds)) do k			
		precisions[k] * (recalls[k] - recalls[k + 1])
	end
	
end

# ╔═╡ 8f5a4372-fbd6-4aef-a337-6579e0c1e47f
function score_consistency(data::AbstractDataFrame)
	filtered = filter(row -> row.item_type == "semantic", data)
	
	adjective = first(data.adj_target)
	values_col = adjective == "expensive" ? "stimulus_price" : "stimulus_size"
	
	responses = parse.(Bool, filtered.response)
	values = filtered[:, values_col]
	
	average_precision(responses, values)
end

# ╔═╡ 96e88f14-0332-4b2f-9ab3-c312679817ab
consistency_threshold = 0.8

# ╔═╡ 77ae2222-3b71-439e-80a4-b8b7f957332a
md"""## Filtered results
Filter participants and export filtered results.
"""

# ╔═╡ 49f49cf2-b8b2-44cb-9195-2c2752979257
md"## Import"

# ╔═╡ 047ecfd6-37ca-4a1c-91a7-2638faaa2bb6
results = CSV.read(
	"results/results.csv", DataFrame,
)

# ╔═╡ 0da400bc-5eb1-442b-a172-90596050cf2b
function is_native(participant)
	selection = filter(results) do row
		row.participant == participant && row.id == "intro_native"
	end
	
	response = first(selection.response)
	response == "Yes"
end

# ╔═╡ fa7ba658-27ac-47a8-bbff-243515bd2c53
function format_counts(data, item; name = missing)
	item_data = filter(data) do row
		row.id == item && is_native(row.participant)
	end
	grouped = groupby(item_data, :response)
	table = combine(grouped, nrow)
	rename(table,
		:response => name,
		:nrow => "N"
	)
end

# ╔═╡ f00afc92-e90c-4879-aa88-9d934a8eef5d
format_counts(results, "intro_native", name = "native")

# ╔═╡ ecb597d1-427d-4a70-85c0-ac6ec588a60c
format_counts(results, "intro_other_langs", name = "other languages")

# ╔═╡ f407b39a-c0b0-48d5-b429-6a9a976aaa33
format_counts(results, "intro_gender", name = "gender")

# ╔═╡ 181dc0ec-bc78-4fed-8288-d25fae5ebc62
durations = results[results.id .== "time_total", :time] ./ 60

# ╔═╡ 57f4fe1a-aaab-410c-bbb7-967bf7f4c50b
histogram(
	durations, label = nothing,
	bins = range(
		0, 
		stop = (ceil ∘ maximum)(durations), 
		length = (Integer ∘ ceil ∘ maximum)(durations)),
	xlabel = "total time (minutes)"
)

# ╔═╡ 61c9430d-723a-494e-b5d1-26bb7e42bb00
let
	m = round(median(durations), digits = 1)
	md"The median duration is **$m minutes**."
end

# ╔═╡ 2a205bc0-702b-44ee-aaab-a3dd39f64a9b
participants = let
	ids = unique(results.participant)
	filter(is_native, ids)
end

# ╔═╡ 7bf19152-9f92-420f-9057-a954499179f3
all(is_native.(participants))

# ╔═╡ 0e5b5a94-e6b1-42d6-bdee-31a2ddfad218
filler_results = filter(row -> row.item_type .== "filler", results)

# ╔═╡ a43af605-3923-4102-bcb9-777c25c6d52c
participant_filler_scores = let
	grouped = groupby(filler_results, :participant)
	df = combine(grouped) do participant_data
		filler_correct_count(participant_data, absolute = false)
	end
	
	df.x1
end

# ╔═╡ eedc17bf-9518-4450-b2f5-352a68ada5ff
histogram(participant_filler_scores,
	bins = range(0.0, 1.05, length = 13),
	label = nothing,
	xlabel = "ratio of fillers correct", ylabel = "# participants"
)

# ╔═╡ 9574b8c2-db78-496c-87ef-32ed7dd833c2
function all_responses(participant)
	p_data = filter(row -> row.participant .== participant, results)
	item_data = filter(p_data) do row
		(row.item_type == "filler") || (row.item_type .== "test")
	end
	
	responses = parse.(Float64, item_data.response)
end

# ╔═╡ f00eaadb-d8bd-40cb-85d3-a1cb3043657e
mean_response = mean ∘ all_responses

# ╔═╡ 8de065c8-1ce4-484b-b008-fcf7db27a73c
histogram(
	mean_response.(participants),
	bins = range(1.0, 5.2, step = 0.2),
	xlabel = "mean response", 
	ylabel = "# participants",
	label = nothing
)

# ╔═╡ ed8aedd6-943f-44bd-9c81-5c002f8a5eb9
sd_response = std ∘ all_responses

# ╔═╡ a30ab7e1-1ab1-4cfa-b05d-07becdc1b619
histogram(
	sd_response.(participants),
	bins = range(0.0, 2.5, step = 0.1),
	xlabel = "standard deviation response", 
	ylabel = "# participants",
	label = nothing
)

# ╔═╡ 7f60742f-eb48-4a91-abb0-1940bc289107
semantic_results = filter(row -> row.item_type == "semantic", results) ;

# ╔═╡ ad88b5e2-1108-421c-b44d-951bd04fcd19
consistency_scores = let
	grouped = groupby(semantic_results, [:participant, :adj_target, :scenario])
	combined = combine(score_consistency, grouped)
	rename(combined, :x1 => :AP)
end

# ╔═╡ a0642a75-e450-442f-8d1a-d0bfdd94aede
histogram(
	consistency_scores.AP,
	legend = nothing,
	xlabel = "average precision of semantic classifications",
	ylabel = "# observations",
)

# ╔═╡ 51514237-96a1-4478-bdc6-96f683a0a79f
function semantic_consistency_score(participant)
	scores = filter(consistency_scores) do row
		row.participant == participant
	end
	
	mean(scores.AP)
end

# ╔═╡ 1936ac3b-861b-437e-bdc6-5dd4d94f48ce
function include_participant(participant)
	filler_score(participant) = let
		pdata = filter(row -> row.participant == participant, filler_results)
		score = filler_correct_count(pdata, absolute = false)
	end
	
	all([
			is_native(participant),
			semantic_consistency_score(participant) >= consistency_threshold,
			filler_score(participant) >= filler_threshold,
			sd_response(participant) >= 1
		])
end

# ╔═╡ 66ac1377-aa46-4c10-85fe-63daeb68ab07
let
	total = length(participants)
	included = count(include_participant, participants)
	md"Participants excluded: $(total - included) out of $(total)"
end

# ╔═╡ 86338e1a-46e3-428b-8bf5-0610e435a9a6
filter(!include_participant, participants)

# ╔═╡ f3498682-38f2-484b-8ab2-29b2efc864ae
function semantic_judgements(participant, adjective, scenario)
	res = filter(results) do row
		all([(row.participant == participant),
				(row.item_type == "semantic"),
				(row.scenario == scenario),
				(row.adj_target == adjective)
				])
	end	
	
	values_col = adjective == "expensive" ? "stimulus_price" : "stimulus_size"

	sorted = sort(res, values_col)
	
	responses = parse.(Bool, sorted.response)
	values = sorted[:, values_col]
	
	responses, values
end

# ╔═╡ 9cb8cc07-5159-4212-8339-0192b08a4b4e
filtered_results = filter(results) do row
	include_participant(row["participant"])
end

# ╔═╡ 06fe2b77-b932-46c7-a712-5dfe670c710a
CSV.write("results/results_filtered.csv", filtered_results)

# ╔═╡ Cell order:
# ╟─d03b1c2f-eba4-41ec-ae2b-5c89152a9212
# ╟─2a989224-fc5e-4220-a0e6-9d38ff7eba0b
# ╠═7bf19152-9f92-420f-9057-a954499179f3
# ╠═0da400bc-5eb1-442b-a172-90596050cf2b
# ╟─32712abf-66a0-41b3-bcbc-5de9e81baf5e
# ╠═f00afc92-e90c-4879-aa88-9d934a8eef5d
# ╟─5f75473f-4b24-4e34-8d67-549353d8469b
# ╟─5624a07b-8ae8-4985-b720-8accec48bd1b
# ╠═ecb597d1-427d-4a70-85c0-ac6ec588a60c
# ╟─4e58b1a9-e516-43c3-a12d-a03bf826b63d
# ╠═f407b39a-c0b0-48d5-b429-6a9a976aaa33
# ╠═fa7ba658-27ac-47a8-bbff-243515bd2c53
# ╟─1ee0a1a6-4723-4e7c-80d8-717da6664749
# ╠═181dc0ec-bc78-4fed-8288-d25fae5ebc62
# ╟─57f4fe1a-aaab-410c-bbb7-967bf7f4c50b
# ╟─61c9430d-723a-494e-b5d1-26bb7e42bb00
# ╟─e234d0db-84e2-400d-b840-467d61432891
# ╠═2a205bc0-702b-44ee-aaab-a3dd39f64a9b
# ╠═0e5b5a94-e6b1-42d6-bdee-31a2ddfad218
# ╠═25d7774c-fafb-4c99-8a72-81829f2e8030
# ╠═a43af605-3923-4102-bcb9-777c25c6d52c
# ╟─eedc17bf-9518-4450-b2f5-352a68ada5ff
# ╠═6d3d96e0-79f3-436c-9e16-824a88e38fa0
# ╟─357879b1-371c-4aa7-bfec-d4b853a109cc
# ╠═9574b8c2-db78-496c-87ef-32ed7dd833c2
# ╠═f00eaadb-d8bd-40cb-85d3-a1cb3043657e
# ╠═ed8aedd6-943f-44bd-9c81-5c002f8a5eb9
# ╟─8de065c8-1ce4-484b-b008-fcf7db27a73c
# ╟─a30ab7e1-1ab1-4cfa-b05d-07becdc1b619
# ╟─5bc8041c-a195-4c67-b83e-2f2fdfe8059a
# ╠═7f60742f-eb48-4a91-abb0-1940bc289107
# ╠═f3498682-38f2-484b-8ab2-29b2efc864ae
# ╠═760480fc-6334-4273-be1b-af7882d21636
# ╠═8f5a4372-fbd6-4aef-a337-6579e0c1e47f
# ╠═ad88b5e2-1108-421c-b44d-951bd04fcd19
# ╠═a0642a75-e450-442f-8d1a-d0bfdd94aede
# ╠═51514237-96a1-4478-bdc6-96f683a0a79f
# ╠═96e88f14-0332-4b2f-9ab3-c312679817ab
# ╟─77ae2222-3b71-439e-80a4-b8b7f957332a
# ╠═1936ac3b-861b-437e-bdc6-5dd4d94f48ce
# ╟─66ac1377-aa46-4c10-85fe-63daeb68ab07
# ╠═86338e1a-46e3-428b-8bf5-0610e435a9a6
# ╠═9cb8cc07-5159-4212-8339-0192b08a4b4e
# ╠═06fe2b77-b932-46c7-a712-5dfe670c710a
# ╟─49f49cf2-b8b2-44cb-9195-2c2752979257
# ╠═254b6cda-8c9c-11eb-1c41-353023a58eea
# ╠═047ecfd6-37ca-4a1c-91a7-2638faaa2bb6
