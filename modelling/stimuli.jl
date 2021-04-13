### A Pluto.jl notebook ###
# v0.14.0

using Markdown
using InteractiveUtils

# ╔═╡ ab04a609-f17b-4360-ba3c-784bc89e192d
begin
    import Pkg
    Pkg.activate(mktempdir())
    Pkg.add([
        Pkg.PackageSpec(name="CSV", version="0.8"),
        Pkg.PackageSpec(name="DataFrames", version="0.22"),
        Pkg.PackageSpec(name="Plots", version="1"),
        Pkg.PackageSpec(name="StatsPlots", version="0.14"),
        Pkg.PackageSpec(name="Turing", version="0.15"),
        Pkg.PackageSpec(name="MCMCChains", version="4"),
    ])
    using CSV, DataFrames, Plots, StatsPlots, Turing, MCMCChains
end

# ╔═╡ 2e35c0c3-e337-4e8d-9dca-8b8a2e0bc962
md"""
## Stimuli data
"""

# ╔═╡ ecbc0b9e-f869-44e5-8bf1-2e828a526e3c
md"## Model definition"

# ╔═╡ 075307aa-7aa7-48d1-9371-661801f1fb49
@model unimodal_model(sample) = begin
	σ ~ InverseGamma(1, 2)
	μ ~ Normal(50, sqrt(σ))
	
	for n in 1:length(sample)
		sample[n] ~ Normal(μ, σ)
	end
end

# ╔═╡ a293cbf7-5b32-479a-9438-b476b8385cb2
md"""
## Fitting
"""

# ╔═╡ a82dc683-687e-445c-8fd9-d21fd79de42d
function plot_prior(prior, scale, scenario; kwargs...)
	measures = stimuli_data[stimuli_data.scenario .== scenario, scale]	
	
	plot(prior,
		color = 2,
		lw = 3,
		fill = 0, fillalpha = 0.5,
		label = nothing;
		xlabel = scale_label(scale),
		ylabel = "P($(scale))",
		xlims = (minimum(measures), maximum(measures)),
		kwargs...
	)
end

# ╔═╡ 530dfabe-68e0-437c-b4b0-b7910c0e2999
iterations = 1000

# ╔═╡ d68f753f-fe25-412d-8b44-57ba4f921a9f
ϵ = 0.05

# ╔═╡ 101627ae-ce66-42b7-9d8d-5e373f7efd05
τ = 10

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

# ╔═╡ e1b24c79-2dcc-4d01-9cb9-40dfbd5777e3
tv_size_unim_model = unimodal_model(get_sample("size", "tv", "unimodal"))

# ╔═╡ 2366d4b3-ce95-4134-a935-ae82a2f747bf
chain = sample(
	tv_size_unim_model, 
	HMC(ϵ, τ), 
	iterations
)

# ╔═╡ 8ca79060-27b0-4910-adc7-0b68d1cab82c
describe(chain)

# ╔═╡ 61b5e56b-3a33-4838-bbc7-7bc5226fafe4
prior_price_tv = let
	sample = filter(data) do row
		(row.scenario == "tv") && row.bimodal
		# note: bimodal and unimodal result in the same set of prices
		# select 1 to avoid duplicates
	end
	
	fit(LogNormal, sample.price)
end

# ╔═╡ 7841ae4a-f9da-4ff1-8f71-ce2290e87a71
prior_price_couch =  let
	sample = filter(data) do row
		(row.scenario == "couch") && row.bimodal
		# note: idem for selecting condition
	end
	
	fit(Normal, sample.price)
end

# ╔═╡ 83fff987-c599-4a2e-866a-b954e822899d
prior_size_tv_unim = let
	sample = filter(data) do row
		(row.scenario == "tv") && row.unimodal
	end
	
	fit(Normal, sample.size)
end

# ╔═╡ 1f9c8c5c-4d6c-44cd-8b95-00bc44dc4b6b
prior_size_tv_bim = let
	sample = filter(data) do row
		(row.scenario == "tv") && row.bimodal
	end
	
	sample_upper = sample[sample.size .> 50, :]
	sample_lower = sample[sample.size .< 50, :]
	
	prior_upper = fit(Normal, sample_upper.size)
	prior_lower = fit(Normal, sample_lower.size)
	
	prior = MixtureModel([prior_upper, prior_lower], [0.5, 0.5])
end

# ╔═╡ 492ea724-782f-4141-ade3-2f5cb11e378e
prior_size_ch_unim = let
	sample = filter(data) do row
		(row.scenario == "couch") && row.unimodal
	end
	
	fit(Normal, sample.size)
end

# ╔═╡ a8a9817c-332c-4b30-a5b6-c1cdc30d20a3
prior_size_ch_bim = let
	sample = filter(data) do row
		(row.scenario == "couch") && row.bimodal
	end
	
	sample_upper = sample[sample.size .> 70, :]
	sample_lower = sample[sample.size .< 70, :]
	
	prior_upper = fit(Normal, sample_upper.size)
	prior_lower = fit(Normal, sample_lower.size)
	
	prior = MixtureModel([prior_upper, prior_lower], [0.5, 0.5])
end

# ╔═╡ Cell order:
# ╟─2e35c0c3-e337-4e8d-9dca-8b8a2e0bc962
# ╠═114cd0b7-8dea-42d4-a19e-36cd4a3c0f6e
# ╠═cb7e8e40-4bf7-4596-8268-b7a0a9abe0a7
# ╟─ecbc0b9e-f869-44e5-8bf1-2e828a526e3c
# ╠═075307aa-7aa7-48d1-9371-661801f1fb49
# ╟─a293cbf7-5b32-479a-9438-b476b8385cb2
# ╠═61b5e56b-3a33-4838-bbc7-7bc5226fafe4
# ╠═7841ae4a-f9da-4ff1-8f71-ce2290e87a71
# ╠═83fff987-c599-4a2e-866a-b954e822899d
# ╠═1f9c8c5c-4d6c-44cd-8b95-00bc44dc4b6b
# ╠═492ea724-782f-4141-ade3-2f5cb11e378e
# ╠═a8a9817c-332c-4b30-a5b6-c1cdc30d20a3
# ╠═a82dc683-687e-445c-8fd9-d21fd79de42d
# ╠═e1b24c79-2dcc-4d01-9cb9-40dfbd5777e3
# ╠═530dfabe-68e0-437c-b4b0-b7910c0e2999
# ╠═d68f753f-fe25-412d-8b44-57ba4f921a9f
# ╠═101627ae-ce66-42b7-9d8d-5e373f7efd05
# ╠═2366d4b3-ce95-4134-a935-ae82a2f747bf
# ╠═8ca79060-27b0-4910-adc7-0b68d1cab82c
# ╠═ab04a609-f17b-4360-ba3c-784bc89e192d
# ╠═2e7b2d1c-9940-11eb-274d-efb0d7118484
