### A Pluto.jl notebook ###
# v0.14.3

using Markdown
using InteractiveUtils

# ╔═╡ 254b6cda-8c9c-11eb-1c41-353023a58eea
begin
    import Pkg
    Pkg.activate("../..")
	Pkg.instantiate()

    using DataFrames, CSV, Statistics, Plots, PlotThemes
	theme(:wong, legend=:outerright)
end

# ╔═╡ 9884af41-9aeb-40a9-8167-093682d6e25a
md"""
# Participant filtering

Inspect some general information about participants and filter participants who did not provide suitable data.
"""

# ╔═╡ 2a989224-fc5e-4220-a0e6-9d38ff7eba0b
md"""
## Demographics

### Native speakers

Any non-native participants?"""

# ╔═╡ 5624a07b-8ae8-4985-b720-8accec48bd1b
md"""
### Other languages

"Besides English, how many other languages do you speak fluently?"
"""

# ╔═╡ 4e58b1a9-e516-43c3-a12d-a03bf826b63d
md"""
### Gender
"""

# ╔═╡ fa7ba658-27ac-47a8-bbff-243515bd2c53
function format_counts(data, item; name = missing)
	item_data = filter(row -> row.id == item, data)
	grouped = groupby(item_data, :response)
	table = combine(grouped, nrow)
	rename(table,
		:response => name,
		:nrow => "N"
	)
end

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
	
	true_positives = data[
		(data.filler_acceptability .== "acceptable") .& is_positive.(data.response),
		:]
	
	true_negatives = data[
		(data.filler_acceptability .== "unacceptable") .& is_negative.(data.response),
		:]
	
	total = data[
		(data.filler_acceptability .== "acceptable") .| (data.filler_acceptability .== "unacceptable"),
		:]
	
	if absolute
		nrow(true_negatives) + nrow(true_positives)
	else
		(nrow(true_negatives) + nrow(true_positives)) / nrow(total)
	end
end

# ╔═╡ 6d3d96e0-79f3-436c-9e16-824a88e38fa0
filler_threshold = 0.75

# ╔═╡ 357879b1-371c-4aa7-bfec-d4b853a109cc
md"""
## Responses
"""

# ╔═╡ 49f49cf2-b8b2-44cb-9195-2c2752979257
md"""## Import
Import packages and data
"""

# ╔═╡ 047ecfd6-37ca-4a1c-91a7-2638faaa2bb6
results = CSV.read(
	"results/results.csv", DataFrame,
)

# ╔═╡ 7bf19152-9f92-420f-9057-a954499179f3
any(results[results.id .== "intro_native", "response"] .!= "Yes")

# ╔═╡ ecb597d1-427d-4a70-85c0-ac6ec588a60c
format_counts(results, "intro_other_langs", name = "other languages")

# ╔═╡ f407b39a-c0b0-48d5-b429-6a9a976aaa33
format_counts(results, "intro_gender", name = "gender")

# ╔═╡ 181dc0ec-bc78-4fed-8288-d25fae5ebc62
durations = results[results.id .== "time_total", "time"] ./ 60

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
participants = unique(results.participant) ;

# ╔═╡ 0e5b5a94-e6b1-42d6-bdee-31a2ddfad218
filler_results = results[results.item_type .== "filler", :] ;

# ╔═╡ 4bb6b8a2-fa0b-4323-8461-a969a44fb51c
function filler_score(participant)
	p_results = filler_results[filler_results.participant .== participant, :]
	filler_correct_count(p_results, absolute = false)
end

# ╔═╡ a43af605-3923-4102-bcb9-777c25c6d52c
participant_filler_scores = filler_score.(participants)

# ╔═╡ eedc17bf-9518-4450-b2f5-352a68ada5ff
histogram(participant_filler_scores,
	bins = range(0.0, 1.05, length = 21),
	label = nothing,
	xlabel = "ratio of fillers correct", ylabel = "# participants"
)

# ╔═╡ 9574b8c2-db78-496c-87ef-32ed7dd833c2
function all_responses(participant)
	p_data = results[results.participant .== participant, :]
	item_data = p_data[
		(p_data.item_type .== "filler") .| (p_data.item_type .== "test"), 
		:]
	responses = parse.(Int64, item_data.response)
end

# ╔═╡ f00eaadb-d8bd-40cb-85d3-a1cb3043657e
mean_response = mean ∘ all_responses

# ╔═╡ 8de065c8-1ce4-484b-b008-fcf7db27a73c
histogram(
	mean_response.(participants),
	bins = range(1.0, 5.2, step = 0.2),
	xlabel = "mean response", 
	ylabel = "# participants",
	legend = :none
)

# ╔═╡ ed8aedd6-943f-44bd-9c81-5c002f8a5eb9
sd_response = std ∘ all_responses

# ╔═╡ a30ab7e1-1ab1-4cfa-b05d-07becdc1b619
histogram(
	sd_response.(participants),
	bins = range(0.0, 2.5, step = 0.1),
	xlabel = "standard deviation response", 
	ylabel = "# participants",
	legend = :none
)

# ╔═╡ 77ae2222-3b71-439e-80a4-b8b7f957332a
md"""## Filtered results

Filter participants and save filtered results
"""

# ╔═╡ 1936ac3b-861b-437e-bdc6-5dd4d94f48ce
function include_participant(participant)
	filler_score(participant) >= filler_threshold
end

# ╔═╡ 9cb8cc07-5159-4212-8339-0192b08a4b4e
filtered_results = filter(results) do row
	include_participant(row["participant"])
end

# ╔═╡ 06fe2b77-b932-46c7-a712-5dfe670c710a
CSV.write("results/results_filtered.csv", filtered_results)

# ╔═╡ Cell order:
# ╟─9884af41-9aeb-40a9-8167-093682d6e25a
# ╟─2a989224-fc5e-4220-a0e6-9d38ff7eba0b
# ╠═7bf19152-9f92-420f-9057-a954499179f3
# ╟─5624a07b-8ae8-4985-b720-8accec48bd1b
# ╠═ecb597d1-427d-4a70-85c0-ac6ec588a60c
# ╟─4e58b1a9-e516-43c3-a12d-a03bf826b63d
# ╠═f407b39a-c0b0-48d5-b429-6a9a976aaa33
# ╠═fa7ba658-27ac-47a8-bbff-243515bd2c53
# ╟─1ee0a1a6-4723-4e7c-80d8-717da6664749
# ╠═181dc0ec-bc78-4fed-8288-d25fae5ebc62
# ╠═57f4fe1a-aaab-410c-bbb7-967bf7f4c50b
# ╟─61c9430d-723a-494e-b5d1-26bb7e42bb00
# ╟─e234d0db-84e2-400d-b840-467d61432891
# ╠═2a205bc0-702b-44ee-aaab-a3dd39f64a9b
# ╠═0e5b5a94-e6b1-42d6-bdee-31a2ddfad218
# ╠═25d7774c-fafb-4c99-8a72-81829f2e8030
# ╠═4bb6b8a2-fa0b-4323-8461-a969a44fb51c
# ╠═a43af605-3923-4102-bcb9-777c25c6d52c
# ╟─eedc17bf-9518-4450-b2f5-352a68ada5ff
# ╠═6d3d96e0-79f3-436c-9e16-824a88e38fa0
# ╟─357879b1-371c-4aa7-bfec-d4b853a109cc
# ╠═9574b8c2-db78-496c-87ef-32ed7dd833c2
# ╠═f00eaadb-d8bd-40cb-85d3-a1cb3043657e
# ╠═ed8aedd6-943f-44bd-9c81-5c002f8a5eb9
# ╠═8de065c8-1ce4-484b-b008-fcf7db27a73c
# ╠═a30ab7e1-1ab1-4cfa-b05d-07becdc1b619
# ╟─49f49cf2-b8b2-44cb-9195-2c2752979257
# ╠═254b6cda-8c9c-11eb-1c41-353023a58eea
# ╠═047ecfd6-37ca-4a1c-91a7-2638faaa2bb6
# ╟─77ae2222-3b71-439e-80a4-b8b7f957332a
# ╠═1936ac3b-861b-437e-bdc6-5dd4d94f48ce
# ╠═9cb8cc07-5159-4212-8339-0192b08a4b4e
# ╠═06fe2b77-b932-46c7-a712-5dfe670c710a
