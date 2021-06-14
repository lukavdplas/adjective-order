### A Pluto.jl notebook ###
# v0.14.8

using Markdown
using InteractiveUtils

# ╔═╡ ab04a609-f17b-4360-ba3c-784bc89e192d
begin
    import Pkg
	root = "../.."
    Pkg.activate(root)

    try
		using CSV, DataFrames, Distributions
	catch
		Pkg.instantiate()
		using CSV, DataFrames, Distributions
	end
end

# ╔═╡ 2e35c0c3-e337-4e8d-9dca-8b8a2e0bc962
md"""
## Stimuli data
"""

# ╔═╡ 76604e42-47e4-4948-993e-a23a16dd8e6f
paths = Dict(
	:stimuli_exp2 => root * "/experiment/acceptability_with_semantic/materials/stimuli_data.csv",
	:stimuli_exp3 => root * "/experiment/novel_objects/materials/stimuli_data.csv"
)

# ╔═╡ 114cd0b7-8dea-42d4-a19e-36cd4a3c0f6e
data = let
	data_exp3 = CSV.read(paths[:stimuli_exp3], DataFrame)
	
	data_exp2 = let
		data = CSV.read(paths[:stimuli_exp2], DataFrame)
		#reorder and rename columns to match exp3
		select!(data, [:index, :size, :price, :bimodal, :unimodal, :scenario])
		rename(data, names(data_exp3))
	end
	
	vcat(data_exp2, data_exp3)
end

# ╔═╡ cb7e8e40-4bf7-4596-8268-b7a0a9abe0a7
function get_sample(scale, scenario, condition = nothing)
	subset = filter(data) do row
		if row.scenario == scenario
			if condition == "bimodal"
				row.bimodal
			elseif condition == "unimodal"
				row.unimodal
			else
				true
			end
		else
			false
		end
	end
	
	subset[:, scale]
end

# ╔═╡ a293cbf7-5b32-479a-9438-b476b8385cb2
md"""
## Unimodal samples

Here we can use the `fit()` function from `Distributions`.
"""

# ╔═╡ 61b5e56b-3a33-4838-bbc7-7bc5226fafe4
prior_price_tv = fit(LogNormal, get_sample("price", "tv", "unimodal"))

# ╔═╡ 7841ae4a-f9da-4ff1-8f71-ce2290e87a71
prior_price_couch = fit(Normal,  get_sample("price", "couch", "unimodal"))

# ╔═╡ 83fff987-c599-4a2e-866a-b954e822899d
prior_size_tv_unim = fit(Normal,  get_sample("size", "tv", "unimodal"))

# ╔═╡ 492ea724-782f-4141-ade3-2f5cb11e378e
prior_size_couch_unim = fit(Normal,  get_sample("size", "couch", "unimodal"))

# ╔═╡ d6cdd16d-70ba-49fd-a06d-d2b6b9a37d39
prior_price_ball = fit(Normal, get_sample("price", "ball", "unimodal"))

# ╔═╡ 84914ff2-5248-48d2-a153-04a8309812e8
prior_size_ball_unim = fit(Normal, get_sample("size", "ball", "unimodal"))

# ╔═╡ 128079b4-b7a7-4b81-b741-b4e725012a5b
prior_price_spring = fit(Normal, get_sample("price", "spring", "unimodal"))

# ╔═╡ 0c7b0624-e289-4f6e-a03c-3d32b84e6acd
prior_size_spring_unim = fit(Normal, get_sample("size", "spring", "unimodal"))

# ╔═╡ 19aa3fe8-7ae5-4be2-8e28-5540a42dc760
md"""
## Bimodal samples

The `MixtureModel` from Distributions can be used to represent a bimodal distribution, but `fit` can't be used on mixed models.

I use the `GaussianMixtures` package to estimate this distributions, but the package does not work with Pluto, so this is done in a separate script with the following code:

```julia
using GaussianMixtures

function get_parameters(scale, scenario, condition)
	sample = Float64.(get_sample(scale, scenario, condition))
	model = GMM(2, sample)

	parameters = Dict(
		:w => model.w,
		:μ => model.μ,
		:σ => sqrt.(model.Σ)
	)
end

params_size_tv_bim = get_parameters("size", "tv", "bimodal")

params_size_couch_bim = get_parameters("size", "couch", "bimodal")

params_size_ball_bim = get_parameters("size", "ball", "bimodal")

params_size_spring_bim = get_parameters("size", "spring", "bimodal")
```

The code below just states the optimal parameter values, so I can use them elsewhere.
"""

# ╔═╡ 1f9c8c5c-4d6c-44cd-8b95-00bc44dc4b6b
prior_size_tv_bim = let
	weights = [0.5, 0.5]
	μs = [33.1429, 75.1429]
	σs = [5.84144, 4.35656]
	
	MixtureModel(
		[Normal(μs[1], σs[1]), Normal(μs[2], σs[2])], 
		weights)
end

# ╔═╡ a8a9817c-332c-4b30-a5b6-c1cdc30d20a3
prior_size_couch_bim = let
	weights = [0.5, 0.5]
	μs = [105.0, 54.4286]
	σs = [5.68205, 6.56521]
	
	MixtureModel(
		[Normal(μs[1], σs[1]), Normal(μs[2], σs[2])], 
		weights)
end

# ╔═╡ cd01e091-56ee-4bff-9eaf-e90bcafe39c5
prior_size_ball_bim = let
	weights = [0.5, 0.5]
	μs = [3.64286, 16.2143]
	σs = [0.742307, 1.16058]
	
	MixtureModel(
		[Normal(μs[1], σs[1]), Normal(μs[2], σs[2])], 
		weights)
end

# ╔═╡ 19721076-694d-44ad-a343-22cf967aa1da
prior_size_spring_bim = let
	weights = [0.5, 0.5]
	μs = [31.0, 10.1429]
	σs = [1.51186, 1.55183]
	
	MixtureModel(
		[Normal(μs[1], σs[1]), Normal(μs[2], σs[2])], 
		weights)
end

# ╔═╡ Cell order:
# ╟─2e35c0c3-e337-4e8d-9dca-8b8a2e0bc962
# ╠═ab04a609-f17b-4360-ba3c-784bc89e192d
# ╠═76604e42-47e4-4948-993e-a23a16dd8e6f
# ╠═114cd0b7-8dea-42d4-a19e-36cd4a3c0f6e
# ╠═cb7e8e40-4bf7-4596-8268-b7a0a9abe0a7
# ╟─a293cbf7-5b32-479a-9438-b476b8385cb2
# ╠═61b5e56b-3a33-4838-bbc7-7bc5226fafe4
# ╠═7841ae4a-f9da-4ff1-8f71-ce2290e87a71
# ╠═83fff987-c599-4a2e-866a-b954e822899d
# ╠═492ea724-782f-4141-ade3-2f5cb11e378e
# ╠═d6cdd16d-70ba-49fd-a06d-d2b6b9a37d39
# ╠═84914ff2-5248-48d2-a153-04a8309812e8
# ╠═128079b4-b7a7-4b81-b741-b4e725012a5b
# ╠═0c7b0624-e289-4f6e-a03c-3d32b84e6acd
# ╟─19aa3fe8-7ae5-4be2-8e28-5540a42dc760
# ╠═1f9c8c5c-4d6c-44cd-8b95-00bc44dc4b6b
# ╠═a8a9817c-332c-4b30-a5b6-c1cdc30d20a3
# ╠═cd01e091-56ee-4bff-9eaf-e90bcafe39c5
# ╠═19721076-694d-44ad-a343-22cf967aa1da
