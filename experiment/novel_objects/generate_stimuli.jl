### A Pluto.jl notebook ###
# v0.14.3

using Markdown
using InteractiveUtils

# ╔═╡ ba3c7e38-a67d-11eb-2fa6-77506c821a76
begin
    import Pkg
    Pkg.activate(mktempdir())
    Pkg.add([
        Pkg.PackageSpec(name="DataFrames", version="1"),
        Pkg.PackageSpec(name="CSV", version="0.8"),
        Pkg.PackageSpec(name="Plots", version="1"),
    ])
    using DataFrames, CSV, Plots, Random
end

# ╔═╡ 9d37c29e-4a35-4438-a560-19175be343e0
md"""
I use some randomisation in the creation of stimuli to create an arbitrary map between the sizes and prices. However, I don't want to shuffle the stimuli data every time I run the code.

The function below initialises a random number generator with a given seed, which will ensure that all these functions are deterministic.
"""

# ╔═╡ c6ec0556-4d5a-4634-b2e0-2f1bf1548290
function rng(x = 1234)
	MersenneTwister(x)
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
spring_prices_overlap = rand(rng(), spring_prices, length(spring_sizes_overlap))

# ╔═╡ d878180e-719e-45cf-8908-207d752f6c07
md"""
For the three subgroups, generate the rows for a dataframe.
"""

# ╔═╡ f7090a06-d114-486c-807d-7e3c2971b571
spring_data_overlap = let	
	sizes = shuffle(rng(1), spring_sizes_overlap)
	prices = shuffle(rng(2), spring_prices_overlap)
	
	ids = map(1:length(sizes)) do i
		 "sp_" * string(i)
	end
	
	bimodal = repeat([true], length(sizes))
	unimodal = repeat([true], length(sizes))
	
	DataFrame(
		"id" => ids,
		"size" => sizes,
		"price" => prices,
		"bimodal" => bimodal,
		"unimodal" => unimodal
	)
end

# ╔═╡ 2cd306d9-5afe-4995-9450-335ca3460ad5
md"""
## Balls
### Measures
"""

# ╔═╡ b4a170e1-1073-4e02-9bea-82189895be6f
ball_sizes_unimodal = [ 10, 11, 16, 5, 8.5,  12.5, 9, 7, 18, 2.5, 10.5, 12, 14, 10]

# ╔═╡ 904604ab-169f-4f2c-b3ac-b39baa3e04f8
histogram(ball_sizes_unimodal, bins = 0:0.5:20, legend = :none)

# ╔═╡ 8822e9e7-cd70-47f3-a3ea-8e199c88d000
ball_sizes_bimodal = [
	16, 5, 18, 2.5, 14, #overlap
	4, 3, 17, 15.5, 3.5, 4, 16.5, 3.5, 16.5 #new values
]

# ╔═╡ 57a09bf9-8c34-42cd-95c4-b52528cf661a
histogram(ball_sizes_bimodal, bins = 0:0.5:20, legend = :none)

# ╔═╡ 155df767-4765-4df1-bfb6-dd6db2799675
ball_prices = [ 10, 12, 4, 19, 8, 14, 11.5, 9.5, 6.5, 1.5, 17, 15, 7.5, 9]

# ╔═╡ a16741c0-d458-4096-99d9-faac6f6a007d
histogram(ball_prices, bins = 0:0.5:20, legend = :none)

# ╔═╡ 04dd2cd8-2315-4882-81d0-3567aa85d84d
md"""
### Generate table
"""

# ╔═╡ 2dc4302b-6b09-467f-988a-db75a45bbd37
ball_sizes_overlap = intersect(ball_sizes_unimodal, ball_sizes_bimodal)

# ╔═╡ 4852b506-2e95-413e-97b8-3981d3c3df4e
ball_prices_overlap = rand(rng(710), ball_prices, length(ball_sizes_overlap))

# ╔═╡ 9ff92ac2-37fc-4f6d-bd76-ff20c0328e8c
md"""
For the three subgroups, generate the rows for a dataframe.
"""

# ╔═╡ 13398123-ac2a-4262-aec1-bac99f9ac374
ball_data_overlap = let	
	sizes = shuffle(rng(8), ball_sizes_overlap)
	prices = shuffle(rng(9), ball_prices_overlap)
	
	ids = map(1:length(sizes)) do i
		 "bl_" * string(i)
	end
	
	bimodal = repeat([true], length(sizes))
	unimodal = repeat([true], length(sizes))
	
	DataFrame(
		"id" => ids,
		"size" => sizes,
		"price" => prices,
		"bimodal" => bimodal,
		"unimodal" => unimodal
	)
end

# ╔═╡ 4d622a9b-ca7f-4bb1-9e67-833fc1950a23
md"""
## Export data
"""

# ╔═╡ 89e14279-07d1-459e-8060-74cee5ab5cfd
md"""
## Helper functions
"""

# ╔═╡ 3e8f840d-0a23-4c02-9c57-9688dfdad474
function subtract(items, overlap_items)
	filter(items) do item
		!( item ∈ overlap_items)
	end
end

# ╔═╡ 924f2986-8427-4581-a376-64b4ba565fcc
spring_data_bimodal = let
	sizes = let
		values = subtract(spring_sizes_bimodal, spring_sizes_overlap)
		shuffle(rng(3), values)
	end
	
	prices =let
		values = subtract(spring_prices, spring_prices_overlap)
		shuffle(rng(4), values)
	end
	
	ids = map(1:length(sizes)) do i
		index = nrow(spring_data_overlap) + i
		"sp_" * string(index)
	end
	
	bimodal = repeat([true], length(sizes))
	unimodal = repeat([false], length(sizes))
	
	DataFrame(
		"id" => ids,
		"size" => sizes,
		"price" => prices,
		"bimodal" => bimodal,
		"unimodal" => unimodal
	)
end

# ╔═╡ a9cdb8ed-17a1-4df0-9dea-5fae64c0515c
spring_data_unimodal = let
	sizes = let
		values = subtract(spring_sizes_unimodal, spring_sizes_overlap)
		shuffle(rng(5), values)
	end
	
	prices = let
		values = subtract(spring_prices, spring_prices_overlap)
		shuffle(rng(6), values)
	end
	
	ids = map(1:length(sizes)) do i
		index = nrow(spring_data_overlap) + nrow(spring_data_bimodal) + i
		"sp_" * string(index)
	end
	
	bimodal = repeat([false], length(sizes))
	unimodal = repeat([true], length(sizes))
	
	DataFrame(
		"id" => ids,
		"size" => sizes,
		"price" => prices,
		"bimodal" => bimodal,
		"unimodal" => unimodal
	)
end

# ╔═╡ 525eb273-07fe-4c9a-b9a2-98b20ace0571
spring_data = vcat(spring_data_overlap, spring_data_bimodal, spring_data_unimodal)

# ╔═╡ 1d21ec9f-e165-4544-87b1-1ba9f32805e1
ball_data_bimodal = let
	sizes = let
		values = subtract(ball_sizes_bimodal, ball_sizes_overlap)
		shuffle(rng(12), values)
	end
	
	prices = let
		values = subtract(ball_prices, ball_prices_overlap)
		shuffle(rng(13), values)
	end
	
	
	ids = map(1:length(sizes)) do i
		index = nrow(ball_data_overlap) + i
		"bl_" * string(index)
	end
	
	bimodal = repeat([true], length(sizes))
	unimodal = repeat([false], length(sizes))
	
	DataFrame(
		"id" => ids,
		"size" => sizes,
		"price" => prices,
		"bimodal" => bimodal,
		"unimodal" => unimodal
	)
end

# ╔═╡ e4473623-ba99-41ca-b790-959bd46451e8
ball_data_unimodal = let
	sizes = let
		values = subtract(ball_sizes_unimodal, ball_sizes_overlap)
		shuffle(rng(15), values)
	end
	
	prices = let
		values = subtract(ball_prices, ball_prices_overlap)
		shuffle(rng(16), values)
	end
	
	
	ids = map(1:length(sizes)) do i
		index = nrow(ball_data_overlap) + nrow(ball_data_bimodal) + i
		"bl_" * string(index)
	end
	
	bimodal = repeat([false], length(sizes))
	unimodal = repeat([true], length(sizes))
	
	DataFrame(
		"id" => ids,
		"size" => sizes,
		"price" => prices,
		"bimodal" => bimodal,
		"unimodal" => unimodal
	)
end

# ╔═╡ c8448cc0-57bb-4624-9a5c-390a5783f01d
ball_data = vcat(ball_data_overlap, ball_data_bimodal, ball_data_unimodal)

# ╔═╡ b1dc7fbb-8eb8-49c6-9a52-09aead876ab8
all_data = vcat(spring_data, ball_data)

# ╔═╡ a1a969e6-36a4-4882-a214-986240693f32
CSV.write("./materials/stimuli_data.csv", all_data)

# ╔═╡ Cell order:
# ╠═ba3c7e38-a67d-11eb-2fa6-77506c821a76
# ╟─9d37c29e-4a35-4438-a560-19175be343e0
# ╠═c6ec0556-4d5a-4634-b2e0-2f1bf1548290
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
# ╟─d878180e-719e-45cf-8908-207d752f6c07
# ╠═f7090a06-d114-486c-807d-7e3c2971b571
# ╠═924f2986-8427-4581-a376-64b4ba565fcc
# ╠═a9cdb8ed-17a1-4df0-9dea-5fae64c0515c
# ╠═525eb273-07fe-4c9a-b9a2-98b20ace0571
# ╟─2cd306d9-5afe-4995-9450-335ca3460ad5
# ╠═b4a170e1-1073-4e02-9bea-82189895be6f
# ╠═904604ab-169f-4f2c-b3ac-b39baa3e04f8
# ╠═8822e9e7-cd70-47f3-a3ea-8e199c88d000
# ╠═57a09bf9-8c34-42cd-95c4-b52528cf661a
# ╠═155df767-4765-4df1-bfb6-dd6db2799675
# ╠═a16741c0-d458-4096-99d9-faac6f6a007d
# ╟─04dd2cd8-2315-4882-81d0-3567aa85d84d
# ╠═2dc4302b-6b09-467f-988a-db75a45bbd37
# ╠═4852b506-2e95-413e-97b8-3981d3c3df4e
# ╟─9ff92ac2-37fc-4f6d-bd76-ff20c0328e8c
# ╠═13398123-ac2a-4262-aec1-bac99f9ac374
# ╠═1d21ec9f-e165-4544-87b1-1ba9f32805e1
# ╠═e4473623-ba99-41ca-b790-959bd46451e8
# ╠═c8448cc0-57bb-4624-9a5c-390a5783f01d
# ╟─4d622a9b-ca7f-4bb1-9e67-833fc1950a23
# ╠═b1dc7fbb-8eb8-49c6-9a52-09aead876ab8
# ╠═a1a969e6-36a4-4882-a214-986240693f32
# ╟─89e14279-07d1-459e-8060-74cee5ab5cfd
# ╠═3e8f840d-0a23-4c02-9c57-9688dfdad474
