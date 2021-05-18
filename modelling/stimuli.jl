### A Pluto.jl notebook ###
# v0.14.2

using Markdown
using InteractiveUtils

# ╔═╡ ab04a609-f17b-4360-ba3c-784bc89e192d
begin
    import Pkg
    Pkg.activate(".")

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

# ╔═╡ 2e7b2d1c-9940-11eb-274d-efb0d7118484
stimuli_path = "../experiment/acceptability_with_semantic/materials/stimuli_data.csv"

# ╔═╡ 114cd0b7-8dea-42d4-a19e-36cd4a3c0f6e
data = CSV.read(stimuli_path, DataFrame)

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

The easiest approach to go from the sample to a distribution is to use the `fit()` function from `Distributions`.
"""

# ╔═╡ 61b5e56b-3a33-4838-bbc7-7bc5226fafe4
prior_price_tv = fit(LogNormal, get_sample("price", "tv", "unimodal"))

# ╔═╡ 7841ae4a-f9da-4ff1-8f71-ce2290e87a71
prior_price_couch = fit(Normal,  get_sample("price", "couch", "unimodal"))

# ╔═╡ 83fff987-c599-4a2e-866a-b954e822899d
prior_size_tv_unim = fit(Normal,  get_sample("size", "tv", "unimodal"))

# ╔═╡ 492ea724-782f-4141-ade3-2f5cb11e378e
prior_size_ch_unim = fit(Normal,  get_sample("size", "couch", "unimodal"))

# ╔═╡ 19aa3fe8-7ae5-4be2-8e28-5540a42dc760
md"""
## Bimodal samples

The `MixtureModel` can be used to represent a bimodal distribution, but `fit` can't be used on mixed models (not weird, this is more complex).

I use the `GaussianMixtures` package to estimate this distributions, but the package does not work with Pluto, so this is done in a separate script with the following code:

```julia
using GaussianMixtures

parameters(model) = Dict(
	:w => model.w,
	:μ => model.μ,
	:σ => sqrt.(model.Σ)
	)

gmm_size_tv_bim = let
   sample = get_sample("size", "tv", "bimodal")
   GMM(2, Float64.(sample))
end

params_size_tv_bim = parameters(gmm_size_tv_bim)

gmm_size_ch_bim = let
    sample = get_sample("size", "couch", "bimodal")
    GMM(2, Float64.(sample))
 end

 params_size_ch_bim = parameters(gmm_size_ch_bim)
```
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
prior_size_ch_bim = let
	weights = [0.5, 0.5]
	μs = [105.0, 54.4286]
	σs = [5.68205, 6.56521]
	
	MixtureModel(
		[Normal(μs[1], σs[1]), Normal(μs[2], σs[2])], 
		weights)
end

# ╔═╡ 84499c1a-7089-4b4f-84d7-75179e14a160
md"""
## Packages
"""

# ╔═╡ Cell order:
# ╟─2e35c0c3-e337-4e8d-9dca-8b8a2e0bc962
# ╠═2e7b2d1c-9940-11eb-274d-efb0d7118484
# ╠═114cd0b7-8dea-42d4-a19e-36cd4a3c0f6e
# ╠═cb7e8e40-4bf7-4596-8268-b7a0a9abe0a7
# ╟─a293cbf7-5b32-479a-9438-b476b8385cb2
# ╠═61b5e56b-3a33-4838-bbc7-7bc5226fafe4
# ╠═7841ae4a-f9da-4ff1-8f71-ce2290e87a71
# ╠═83fff987-c599-4a2e-866a-b954e822899d
# ╠═492ea724-782f-4141-ade3-2f5cb11e378e
# ╟─19aa3fe8-7ae5-4be2-8e28-5540a42dc760
# ╠═1f9c8c5c-4d6c-44cd-8b95-00bc44dc4b6b
# ╠═a8a9817c-332c-4b30-a5b6-c1cdc30d20a3
# ╟─84499c1a-7089-4b4f-84d7-75179e14a160
# ╠═ab04a609-f17b-4360-ba3c-784bc89e192d
