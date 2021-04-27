### A Pluto.jl notebook ###
# v0.14.3

using Markdown
using InteractiveUtils

# ╔═╡ ba3c7e38-a67d-11eb-2fa6-77506c821a76
begin
	using DataFrames, CSV, Plots, Random
	Random.seed!(1234)
end

# ╔═╡ 9deb32c7-06f7-46fb-8b34-f49c8addab28
md"""
## Springs
### Measures
"""

# ╔═╡ b5f48cab-967e-4f05-8294-1d71534b66a3
spring_sizes_unimodal = [ 8, 20, 16, 33, 24, 26, 19, 30, 21, 18, 22, 21, 13, 20 ]

# ╔═╡ f3ff9880-5ea3-482e-9a1b-5be7b2f9b2dc
histogram(spring_sizes_unimodal, bins = 0:40, legend = :none)

# ╔═╡ 62cf4310-5fb4-4af2-809b-fe5a4b8e2c9a
spring_sizes_bimodal = [ 8, 9, 11, 30, 32, 33, 28, 13, 9, 32, 10, 11, 31, 31 ]

# ╔═╡ fc50c73b-b69a-45fe-b02e-d128d8d61520
histogram(spring_sizes_bimodal, bins = 0:40, legend = :none)

# ╔═╡ 156eca92-b1ec-4125-9932-ea46995fa3f6
spring_prices = [
	10.0, 5.0, 8.5, 11.0, 13.5, 12.5, 9.5, 6.5, 8.0, 14, 18, 3.0, 16.5, 11
]

# ╔═╡ b60e33bc-921a-4b39-a4a3-e42c311abf05
histogram(spring_prices, bins = 0:0.5:20, legend = :none)

# ╔═╡ e89ccecf-7c75-46af-affd-d6e668a4816b
md"""
### Generate table

First, establish the overlap between the two sets of sizes, and assign a subset of the prices to the overlap group.
"""

# ╔═╡ a0c67783-86b9-4a7c-ae63-ebae7b941317
spring_sizes_overlap = intersect(spring_sizes_unimodal, spring_sizes_bimodal)

# ╔═╡ a99b6c1a-588e-4628-878b-c3c2e59285a8
spring_prices_overlap = rand(spring_prices, length(spring_sizes_overlap))

# ╔═╡ b7088fa8-1326-44cb-81d2-67145c18cee6
md"""
Total number of stimuli, counting overlap items only once.
"""

# ╔═╡ 364eaf2e-2e98-4c83-bd2d-714cbf1563e7
total_springs = length(spring_sizes_unimodal) + length(spring_sizes_bimodal) - length(spring_sizes_overlap)

# ╔═╡ d878180e-719e-45cf-8908-207d752f6c07
md"""
For the three subgroups, generate the rows for a dataframe.
"""

# ╔═╡ e9389687-e2fd-43de-9a20-05dd67ebd75e
function random_matches(sizes, prices)
	shuffled_sizes =  shuffle(sizes)
	shuffled_prices = shuffle(prices)
	
	DataFrame("size" => shuffled_sizes, "price" => shuffled_prices)
end

# ╔═╡ 3e8f840d-0a23-4c02-9c57-9688dfdad474
function subtract(items, overlap)
	filter(items) do item
		!( item ∈ overlap)
	end
end

# ╔═╡ f7090a06-d114-486c-807d-7e3c2971b571
spring_data_overlap = let
	items = random_matches(spring_sizes_overlap, spring_prices_overlap)
	
	ids = map(1:nrow(items)) do i
		 "sp_" * string(i)
	end
	
	bimodal = repeat([true], nrow(items))
	unimodal = repeat([true], nrow(items))
	
	DataFrame(
		"id" => ids,
		"size" => items.size,
		"price" => items.price,
		"bimodal" => bimodal,
		"unimodal" => unimodal
	)
end

# ╔═╡ 924f2986-8427-4581-a376-64b4ba565fcc
spring_data_bimodal = let
	sizes = subtract(spring_sizes_bimodal, spring_sizes_overlap)
	prices = subtract(spring_prices, spring_prices_overlap)
	
	items = random_matches(sizes, prices)
	
	ids = map(1:nrow(items)) do i
		index = nrow(spring_data_overlap) + i
		"sp_" * string(index)
	end
	
	bimodal = repeat([true], nrow(items))
	unimodal = repeat([false], nrow(items))
	
	DataFrame(
		"id" => ids,
		"size" => items.size,
		"price" => items.price,
		"bimodal" => bimodal,
		"unimodal" => unimodal
	)
end

# ╔═╡ a9cdb8ed-17a1-4df0-9dea-5fae64c0515c
spring_data_unimodal = let
	sizes = subtract(spring_sizes_unimodal, spring_sizes_overlap)
	prices = subtract(spring_prices, spring_prices_overlap)
	
	items = random_matches(sizes, prices)
	
	ids = map(1:nrow(items)) do i
		index = nrow(spring_data_overlap) + nrow(spring_data_bimodal) + i
		"sp_" * string(index)
	end
	
	bimodal = repeat([false], nrow(items))
	unimodal = repeat([true], nrow(items))
	
	DataFrame(
		"id" => ids,
		"size" => items.size,
		"price" => items.price,
		"bimodal" => bimodal,
		"unimodal" => unimodal
	)
end

# ╔═╡ 525eb273-07fe-4c9a-b9a2-98b20ace0571
spring_data = vcat(spring_data_overlap, spring_data_bimodal, spring_data_unimodal)

# ╔═╡ a1a969e6-36a4-4882-a214-986240693f32
CSV.write("./materials/stimuli_data.csv", spring_data)

# ╔═╡ Cell order:
# ╠═ba3c7e38-a67d-11eb-2fa6-77506c821a76
# ╟─9deb32c7-06f7-46fb-8b34-f49c8addab28
# ╠═b5f48cab-967e-4f05-8294-1d71534b66a3
# ╠═f3ff9880-5ea3-482e-9a1b-5be7b2f9b2dc
# ╠═62cf4310-5fb4-4af2-809b-fe5a4b8e2c9a
# ╠═fc50c73b-b69a-45fe-b02e-d128d8d61520
# ╠═156eca92-b1ec-4125-9932-ea46995fa3f6
# ╠═b60e33bc-921a-4b39-a4a3-e42c311abf05
# ╟─e89ccecf-7c75-46af-affd-d6e668a4816b
# ╠═a0c67783-86b9-4a7c-ae63-ebae7b941317
# ╠═a99b6c1a-588e-4628-878b-c3c2e59285a8
# ╟─b7088fa8-1326-44cb-81d2-67145c18cee6
# ╠═364eaf2e-2e98-4c83-bd2d-714cbf1563e7
# ╟─d878180e-719e-45cf-8908-207d752f6c07
# ╠═e9389687-e2fd-43de-9a20-05dd67ebd75e
# ╠═3e8f840d-0a23-4c02-9c57-9688dfdad474
# ╠═f7090a06-d114-486c-807d-7e3c2971b571
# ╠═924f2986-8427-4581-a376-64b4ba565fcc
# ╠═a9cdb8ed-17a1-4df0-9dea-5fae64c0515c
# ╠═525eb273-07fe-4c9a-b9a2-98b20ace0571
# ╠═a1a969e6-36a4-4882-a214-986240693f32
