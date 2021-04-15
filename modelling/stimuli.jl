### A Pluto.jl notebook ###
# v0.14.1

using Markdown
using InteractiveUtils

# ╔═╡ ab04a609-f17b-4360-ba3c-784bc89e192d
begin
    import Pkg
    Pkg.activate(mktempdir())
    Pkg.add([
        Pkg.PackageSpec(name="CSV", version="0.8"),
        Pkg.PackageSpec(name="DataFrames", version="0.22"),
        Pkg.PackageSpec(name="Distributions", version="0.24"),
    ])
    using CSV, DataFrames, Distributions
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
## Using Distributions

The easiest approach to go from the sample to a distribution is to use the `fit()` function from `Distributions`.

One disadvantage is that this does not give information about how certain we can be about the optimal fit.
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
The `MixtureModel` can be used to represent a bimodal distribution, but `fit` can't be used on mixed models (not weird, this is more complex).


As a quick solution, I divide the sample into the upper and lower cluster, and fit each cluster separately. I then combine the two in a mixture model. This somewhat overestimates the distance between the two means.
"""

# ╔═╡ 1f9c8c5c-4d6c-44cd-8b95-00bc44dc4b6b
prior_size_tv_bim = let
	sample =  get_sample("size", "tv", "bimodal")
	
	sample_upper = filter(x -> x >= 50, sample)
	sample_lower = filter(x -> x < 50, sample)
	
	prior_upper = fit(Normal, sample_upper)
	prior_lower = fit(Normal, sample_lower)
	
	prior = MixtureModel([prior_upper, prior_lower], [0.5, 0.5])
end

# ╔═╡ a8a9817c-332c-4b30-a5b6-c1cdc30d20a3
prior_size_ch_bim = let
	sample = get_sample("size", "couch", "bimodal")
	
	sample_upper = filter(x -> x >= 70, sample)
	sample_lower = filter(x -> x < 70, sample)
	
	prior_upper = fit(Normal, sample_upper)
	prior_lower = fit(Normal, sample_lower)
	
	prior = MixtureModel([prior_upper, prior_lower], [0.5, 0.5])
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
