### A Pluto.jl notebook ###
# v0.14.0

using Markdown
using InteractiveUtils

# This Pluto notebook uses @bind for interactivity. When running this notebook outside of Pluto, the following 'mock version' of @bind gives bound variables a default value (instead of an error).
macro bind(def, element)
    quote
        local el = $(esc(element))
        global $(esc(def)) = Core.applicable(Base.get, el) ? Base.get(el) : missing
        el
    end
end

# ╔═╡ 9e79889a-9baf-11eb-1e2d-59906f90ea82
begin
    import Pkg
    Pkg.activate(mktempdir())
    Pkg.add([
        Pkg.PackageSpec(name="CSV", version="0.8"),
        Pkg.PackageSpec(name="DataFrames", version="0.22"),
        Pkg.PackageSpec(name="Distributions", version="0.24"),
        Pkg.PackageSpec(name="Plots", version="1"),
        Pkg.PackageSpec(name="PlotThemes", version="2"),
        Pkg.PackageSpec(name="StatsPlots", version="0.14"),
        Pkg.PackageSpec(name="PlutoUI", version="0.7"),
    ])
    using CSV, DataFrames, Distributions, Plots, PlotThemes, StatsPlots, PlutoUI

	theme(:wong, legend = :outerright)
end

# ╔═╡ 2337edd6-894c-442d-bdf3-d1b9775dce4b
md"""
Goal: model of semantic judgements. For now, I focus on "expensive", which has no distinction in conditions.
"""

# ╔═╡ 8332538e-a06a-415b-8fc1-45e44c5c6a1a
md"""
## Data import
"""

# ╔═╡ 9ebd6e50-cce7-40c8-80b6-5d0785127687
paths = Dict(
	"stimuli" => "../experiment/acceptability_with_semantic/materials/stimuli_data.csv"
)

# ╔═╡ 56e46a90-adc7-4967-aa50-441dea17d511
stimuli_data = CSV.read(paths["stimuli"], DataFrame)

# ╔═╡ 10898ea6-0ebb-4e37-9171-d1bfdb2cc932
md"""
## Prior distribution
"""

# ╔═╡ 27c93d40-e837-41d8-87b0-c8f03f66825f
tv_prices = let
	sample = filter(stimuli_data) do row
		(row.scenario == "tv") && row.bimodal
		#filter on one condition to prevent duplicates
		#set of prices is the same for both conditions
	end
	
	sample.price
end

# ╔═╡ fe1ed26e-42bf-4178-89e4-bef0f4e0c240
couch_prices = let
	sample = filter(stimuli_data) do row
		(row.scenario == "couch") && row.bimodal
		#filter on one condition to prevent duplicates
		#set of prices is the same for both conditions
	end
	
	sample.price
end

# ╔═╡ 252f4a66-37e7-4ffa-9429-a407af3a9345
couch_price_scale_points = 0:25:1500

# ╔═╡ 4387731e-0866-425c-aee7-a83b7ca729d5
fitted_prior_couch_price = fit(Normal, couch_prices)

# ╔═╡ fcd71c2c-e685-449d-bf0d-563d28b4a5b9
couch_price_prior_values = let
	scale = [couch_price_scale_points ;
		couch_price_scale_points.stop + couch_price_scale_points.step ]
	densities = pdf.(fitted_prior_couch_price, scale)
	densities / sum(densities)
end

# ╔═╡ 460e3cdb-e248-4c2b-a921-8cab93dadd6d
function couch_price_density(x)
	Δ = (x - couch_price_scale_points.start)
	i = 1 + (Int ∘ floor)(Δ / couch_price_scale_points.step)
	
	couch_price_prior_values[i]
end

# ╔═╡ 60b27cb6-6aa1-4a92-a4be-42ecd805ef79
couch_price_cumulative_values = map(1:length(couch_price_prior_values)) do i
	sum(couch_price_prior_values[1:i])
end

# ╔═╡ 1a71c080-a430-4028-b738-8ca7183f6369
function couch_price_cumulative(x)
	Δ = (x - couch_price_scale_points.start)
	i = 1 + (Int ∘ floor)(Δ / couch_price_scale_points.step)
	
	couch_price_cumulative_values[i]
end

# ╔═╡ f93afb34-6e01-49bc-843a-0eac76bf8b13
function plot_couch_prior()
	plot(
		couch_price_scale_points,
		couch_price_density,
		fill = 0, fillalpha = 0.5,
		label = "prior probability",
		ylabel = "P",
		xlabel = "price (\$)",
	)
end

# ╔═╡ 44d33712-d590-423b-b75c-a281dcb27ae9
let	
	p1 = histogram(
		couch_prices, 
		normalize = true,
		bins = couch_price_scale_points,
		legend = :none,
		ylabel = "N",
		xlabel = "price (\$)",
		title = "Couch prices in sample"
	)
	
	p2 = plot_couch_prior()
	plot!(p2, title = "Estimated distribution of couch prices", legend = :none)
	
	plot(p1, p2, layout = (2,1))
end

# ╔═╡ ad926740-e511-4bf7-a76f-eb1ed1f33e4b
md"""
## Model

### Literal listener
"""

# ╔═╡ 564a20ee-5f1a-42ee-8177-6184989bea76
function literal_listener(x, θ, densityf, cumulativef)	
	if x >= θ
		densityf(x) / (1 - cumulativef(θ))
	else
		0
	end
end

# ╔═╡ 83bbf10c-c616-4982-a3dc-9f8773aadbe5
function plot_literal_listener(θ)
	p = plot_couch_prior()
	
	plot!(p,
		couch_price_scale_points,
		x -> literal_listener(x, θ, couch_price_density, couch_price_cumulative),
		fill = 0, fillalpha = 0.5,
	)
end

# ╔═╡ b7ecc372-66d2-437a-b832-304df70dfab5
@bind ll_example_θ Slider(couch_price_scale_points)

# ╔═╡ de2bdadc-0ab9-4cc4-9d1a-2aa040ab4c7a
md"""
Threshold: $(ll_example_θ)
"""

# ╔═╡ 1cd0b656-580d-4daf-9ce7-8b8c3e37dfde
plot_literal_listener(ll_example_θ)

# ╔═╡ b8806ceb-8cf3-406c-b167-92613f7f2488
md"""
### Expected success
"""

# ╔═╡ c3c0ac35-3992-4c3c-9794-96967941fcf7
function expected_success(θ, scale_points, densityf, cumulativef)
	term_1 = if θ > minimum(scale_points)
		sum(filter(x -> x < θ, scale_points)) do x
			densityf(x) * densityf(x)
		end
	else
		0
	end
	
	term_2 = sum(filter(x -> x >= θ, scale_points)) do x
		densityf(x) * literal_listener(x, θ, densityf, cumulativef)
	end
	
	#term_1 + 
	term_2
end

# ╔═╡ 217e6552-74ca-4ade-ae21-e215bf68ca90
let
	p = plot_couch_prior()
	
	es(θ) = expected_success(
		θ, 
		couch_price_scale_points, 
		couch_price_density, 
		couch_price_cumulative)
	
	plot!(p,
		couch_price_scale_points,
		es,
		fill = 0, fillalpha = 0.5,
		label = "expected success"
	)
end

# ╔═╡ 4a6d5189-a731-45c4-8e38-3b5099756f18
md"""
### Utility
"""

# ╔═╡ a246c8c9-808c-44e6-94a9-ac077c546baa
function utility(θ, coverage, scale_points, densityf, cumulativef)
	term1 = expected_success(θ, scale_points, densityf, cumulativef)
	
	term2 = sum(filter(x -> x >= θ, scale_points)) do x
		densityf(x)
	end
	
	term1 + coverage * term2
end

# ╔═╡ e4c4689c-53f2-4874-a8eb-fe31d1da50a5
@bind ut_example_coverage Slider(0:0.01:0.25)

# ╔═╡ 281d7b77-6fb0-4733-88c9-0c49c10b8109
md"Coverage parameter : $(ut_example_coverage)"

# ╔═╡ 4051fec8-8a0c-4412-84aa-ad1f8d3491ee
function plot_utility(coverage)
	p = plot_couch_prior()
	
	ut(θ) = utility(
		θ, 
		coverage,
		couch_price_scale_points, 
		couch_price_density, 
		couch_price_cumulative)
	
	plot!(p,
		couch_price_scale_points,
		ut,
		fill = 0, fillalpha = 0.5,
		label = "utility"
	)
end

# ╔═╡ a53d05c5-b1c5-4ab7-a29a-ef88361c5203
plot_utility(ut_example_coverage)

# ╔═╡ 5ec1487c-fb7e-4c09-b80c-f92b2a3f37e4
md"""
### Threshold probability
"""

# ╔═╡ 0b5dbba1-8509-495d-9da1-051c71b116fb
function probability_threshold(θ, λ, coverage, scale_points, densityf, cumulativef)
	exp_utility(x) = exp(
		λ * utility(x, coverage, scale_points, densityf, cumulativef)
	)
	
	exp_utility(θ) / sum(exp_utility, scale_points)
end

# ╔═╡ 51179458-39d3-4652-939d-6f15954056e3
@bind tp_example_λ Slider(0:5:100)

# ╔═╡ 1fae8bee-9cca-404f-8fe8-0752b4c64e6f
md"λ : $(tp_example_λ)"

# ╔═╡ 34398d43-b2bd-428f-a9f8-fab579ccb99f
@bind tp_example_coverage Slider(0:0.01:0.25)

# ╔═╡ da453bd1-70f1-47a2-b32d-eee7af514e43
md"Coverage parameter: $(tp_example_coverage)"

# ╔═╡ 33090a3c-ce88-40aa-b3ee-ba6eb2b6b593
function plot_threshold_probability(λ, coverage)
	p = plot_couch_prior()
	
	tp(θ) = probability_threshold(
		θ, 
		λ,
		coverage,
		couch_price_scale_points, 
		couch_price_density, 
		couch_price_cumulative)
	
	plot!(p,
		couch_price_scale_points,
		tp,
		fill = 0, fillalpha = 0.5,
		label = "threshold probability"
	)
end

# ╔═╡ ab797a07-254e-40f8-b7b9-c7fe31d5d4ba
plot_threshold_probability(tp_example_λ, tp_example_coverage)

# ╔═╡ 0a0715d3-8f0b-4e26-b54d-8aa3cdc6ced6
md"""
### Adjective use
"""

# ╔═╡ 7e6becae-5be3-4069-b2f6-139f4b02cf92
function use_adjective(degree, λ::Number, coverage::Number, 
		scale_points::AbstractArray, 
		densityf::Function, cumulativef::Function)
	sum(filter(θ -> θ <= degree, scale_points)) do θ
		probability_threshold(θ, λ, coverage, scale_points, densityf, cumulativef)
	end
end

# ╔═╡ 4f454802-5399-43dd-928e-89506a78da28
function use_adjective(degree, θ_probabilities::AbstractArray,
		scale_points::AbstractArray)

	sum(filter(i -> scale_points[i] <= degree, 1:length(scale_points))) do i
		θ_probabilities[i]
		end
end

# ╔═╡ 899f2e2a-ab04-412f-97b2-90269cc14cf6
@bind ua_example_λ Slider(0:5:100)

# ╔═╡ b522ae78-c917-47ca-83c9-ff43771b0603
md"λ : $(ua_example_λ)"

# ╔═╡ d2d4c6d6-d440-4442-979d-76c9a0e76b00
@bind ua_example_coverage Slider(0:0.01:0.25)

# ╔═╡ 5318b14a-e95b-4324-85bd-8a8094351cad
md"Coverage parameter: $(ua_example_coverage)"

# ╔═╡ edd92128-c71e-40da-b325-32425c9d1cf0
ua_example_θ_probabilities = map(couch_price_scale_points) do θ
	probability_threshold(θ, ua_example_λ, ua_example_coverage, 
		couch_price_scale_points, couch_price_density, couch_price_cumulative)
end

# ╔═╡ 55869021-3709-412a-a216-92c035a90f6a
function plot_use_adjective(λ, coverage)
	ua(d) = use_adjective(
		d, 
		ua_example_θ_probabilities,
		couch_price_scale_points)
	
	plot(couch_price_scale_points,
		ua,
		fill = 0, fillalpha = 0.5,
		label = "P(use adjective)"
	)
end

# ╔═╡ 96112ecc-8f1f-4bb1-b6c5-a67cfa8a00a9
plot_use_adjective(ua_example_λ, ua_example_coverage)

# ╔═╡ Cell order:
# ╟─2337edd6-894c-442d-bdf3-d1b9775dce4b
# ╟─8332538e-a06a-415b-8fc1-45e44c5c6a1a
# ╠═9e79889a-9baf-11eb-1e2d-59906f90ea82
# ╠═9ebd6e50-cce7-40c8-80b6-5d0785127687
# ╠═56e46a90-adc7-4967-aa50-441dea17d511
# ╟─10898ea6-0ebb-4e37-9171-d1bfdb2cc932
# ╠═27c93d40-e837-41d8-87b0-c8f03f66825f
# ╠═fe1ed26e-42bf-4178-89e4-bef0f4e0c240
# ╠═252f4a66-37e7-4ffa-9429-a407af3a9345
# ╠═4387731e-0866-425c-aee7-a83b7ca729d5
# ╠═fcd71c2c-e685-449d-bf0d-563d28b4a5b9
# ╠═460e3cdb-e248-4c2b-a921-8cab93dadd6d
# ╠═60b27cb6-6aa1-4a92-a4be-42ecd805ef79
# ╠═1a71c080-a430-4028-b738-8ca7183f6369
# ╠═44d33712-d590-423b-b75c-a281dcb27ae9
# ╠═f93afb34-6e01-49bc-843a-0eac76bf8b13
# ╟─ad926740-e511-4bf7-a76f-eb1ed1f33e4b
# ╠═564a20ee-5f1a-42ee-8177-6184989bea76
# ╠═83bbf10c-c616-4982-a3dc-9f8773aadbe5
# ╟─de2bdadc-0ab9-4cc4-9d1a-2aa040ab4c7a
# ╠═b7ecc372-66d2-437a-b832-304df70dfab5
# ╠═1cd0b656-580d-4daf-9ce7-8b8c3e37dfde
# ╟─b8806ceb-8cf3-406c-b167-92613f7f2488
# ╠═c3c0ac35-3992-4c3c-9794-96967941fcf7
# ╠═217e6552-74ca-4ade-ae21-e215bf68ca90
# ╟─4a6d5189-a731-45c4-8e38-3b5099756f18
# ╠═a246c8c9-808c-44e6-94a9-ac077c546baa
# ╟─281d7b77-6fb0-4733-88c9-0c49c10b8109
# ╠═e4c4689c-53f2-4874-a8eb-fe31d1da50a5
# ╠═a53d05c5-b1c5-4ab7-a29a-ef88361c5203
# ╠═4051fec8-8a0c-4412-84aa-ad1f8d3491ee
# ╟─5ec1487c-fb7e-4c09-b80c-f92b2a3f37e4
# ╠═0b5dbba1-8509-495d-9da1-051c71b116fb
# ╟─1fae8bee-9cca-404f-8fe8-0752b4c64e6f
# ╟─51179458-39d3-4652-939d-6f15954056e3
# ╟─da453bd1-70f1-47a2-b32d-eee7af514e43
# ╟─34398d43-b2bd-428f-a9f8-fab579ccb99f
# ╠═ab797a07-254e-40f8-b7b9-c7fe31d5d4ba
# ╠═33090a3c-ce88-40aa-b3ee-ba6eb2b6b593
# ╟─0a0715d3-8f0b-4e26-b54d-8aa3cdc6ced6
# ╠═7e6becae-5be3-4069-b2f6-139f4b02cf92
# ╠═4f454802-5399-43dd-928e-89506a78da28
# ╟─b522ae78-c917-47ca-83c9-ff43771b0603
# ╟─899f2e2a-ab04-412f-97b2-90269cc14cf6
# ╟─5318b14a-e95b-4324-85bd-8a8094351cad
# ╟─d2d4c6d6-d440-4442-979d-76c9a0e76b00
# ╠═96112ecc-8f1f-4bb1-b6c5-a67cfa8a00a9
# ╠═edd92128-c71e-40da-b325-32425c9d1cf0
# ╠═55869021-3709-412a-a216-92c035a90f6a
