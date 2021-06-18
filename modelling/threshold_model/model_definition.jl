### A Pluto.jl notebook ###
# v0.14.8

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

# ╔═╡ 1265bf24-ccef-11eb-0db6-c1355b5726fd
begin
    import Pkg
	root = "../.."
    Pkg.activate(root)

    try
		using Distributions, Plots, StatsPlots, PlutoUI
	catch
		Pkg.instantiate()
		using Distributions, Plots, StatsPlots, PlutoUI
	end
	
	theme(:wong, legend = :outertop)
end

# ╔═╡ 2e056874-bfc8-42d6-9412-229cee3fea9c
md"""
# Model definition

This notebook defines the model I will use for the semantics of vague adjectives.

The functions defined here are imported in `fitting.jl` to fit the model to the experiment results.
"""

# ╔═╡ 0c383b94-3d51-41e1-9d48-0f27b8d3ebf1
md"""
## Example distribution

To illustrate the model and check that everything works, I use an example of a scale and prior distribution.
"""

# ╔═╡ 7dec4e35-7cf6-45ff-aae6-4fe53d093881
example_scale_points = 1:100

# ╔═╡ 320b3280-072a-4cca-9011-cb94799a9c60
example_prior = Normal(50, 5)

# ╔═╡ 746c9a8f-900c-42bc-9326-8e4f06cf075d
function plot_example_prior()
	plot(example_scale_points, example_prior,
		label = "prior",
		fill = 0, fillalpha = 0.5,
		xlabel = "degree", ylabel = "P",
	)
end

# ╔═╡ 7ad46ea1-fb79-4fa6-9f0f-8dd529313275
plot_example_prior()

# ╔═╡ 5ae0c8ad-efa4-47d5-af77-3c40e4808ba0
function probability_values(scale_points, prior)
	density_values = let
		prior_density(degree) = pdf(prior, degree) * step(scale_points)
		total_p_mass = sum(prior_density, scale_points)

		prior_density.(scale_points) ./ total_p_mass
	end
			
	cumulative_values = map(1:length(scale_points)) do i
		sum(k -> density_values[k], 1:i)
	end
	
	Dict(
		map(0:length(scale_points)) do i
			if i == 0
				first(scale_points) - step(scale_points) =>
					Dict(:density => 0.0, :cumulative => 0.0)
			else
				scale_points[i] => 
					Dict(:density => density_values[i], 
						:cumulative => cumulative_values[i]
					)
			end
		end
	)
end

# ╔═╡ 93e5caed-f31d-4ff7-a905-90ba32ffd7b3
example_prob_values = probability_values(example_scale_points, example_prior)

# ╔═╡ 8d281fc6-2a73-4dc0-ad57-493393608615
function example_density(degree)
	example_prob_values[degree][:density]
end

# ╔═╡ 6e825f28-448b-416c-be5d-1d5032aba90e
function example_cumulative(degree)
	example_prob_values[degree][:cumulative]
end

# ╔═╡ 2ce9ee34-d870-4e3e-ad79-2f25374a68f3
md"""
## Literal listener

The literal listener model estimates the probability that the degree (i.e. price/size) of an object is equal to $x$ given a message like *"It's an expensive couch"*.

The distribution of couch prices defines the prior belief that the price could be $x$, i.e. $P(x)$

The adjective *"expensive"* is interpreted to indicate that $x$ is above a threshold $\theta$. So we estimate the posterior belief

$P(x | x > \theta)$

$\geq$

This is calculated as follows

$L_0(x | x > \theta) = \cases{
	\frac{P(x)}{\int_\theta^{max} P(x)} & if \(x \geq θ\) \\ 
	0 &if \(x < θ\)
}$

"""

# ╔═╡ c04d4d1a-7e07-40a4-b4b3-d6eb893c03f2
function literal_listener(x, θ, scale_points, densityf, cumulativef)	
	if x >= θ
		step_size = step(scale_points)
		
		denominator = if θ > first(scale_points)
			(1 - cumulativef(θ - step_size))
		else
			1.0
		end
		
		fraction = densityf(x) / denominator

		if fraction < Inf 
			fraction
		else
			#fix for when the denominator is zero and the fraction becomes Inf
			step_size / (last(scale_points) - (θ - step_size))
		end
	else
		0
	end
end

# ╔═╡ c682ae23-87f6-4ac5-961a-f5999642b446
md"""
Plot for the literal listener model. The plot takes the threshold $\theta$ as a parameter.
"""

# ╔═╡ 596c1cda-f3bc-46ee-bb45-cd469ed89c50
function plot_example_literal_listener(θ)
	p = plot_example_prior()
	
	plot!(p,
		example_scale_points,
		x -> literal_listener(x, θ, 
			example_scale_points, example_density, example_cumulative),
		fill = 0, fillalpha = 0.5,
		label = "literal listener"
	)
end

# ╔═╡ 78254550-795a-47fa-bbb0-598ec245d981
@bind ll_example_θ Slider(example_scale_points, default = 50)

# ╔═╡ e36d6390-3e61-4053-809c-7451df1f64e8
md"""
Threshold: $(ll_example_θ)
"""

# ╔═╡ eda0b3cc-9b01-4a71-8ecd-99ab3e4e963e
plot_example_literal_listener(ll_example_θ)

# ╔═╡ b8822897-2e8c-4a59-b886-1931aa43c7f6
sum(example_scale_points) do x
	literal_listener(x, ll_example_θ, example_scale_points, example_density, example_cumulative)
end

# ╔═╡ dee3660c-6a02-4d79-80fe-514f0befb5df
md"""
## Expected success

Based on the literal listener model, we can calculate the communicate effeciency a threshold $\theta$. 

We estimate the *expected succes* of our communication if we use $\theta$ as our threshold. When we describe an object of size/price $x$, the success of the action is determined by the posterior belief $P(x | \text{message})$ that the listener will hold based on the message.

Here, assume we describe an object of price/size $x$ as follows:

* If $x > \theta$, we won't use the vague adjective, so the listener will use their prior belief $P(x)$
* If $x \geq \theta$, we will describe it using the vague adjective. The listener then updates their belief according to the literal listener model to estimate $L_0(x | x > \theta)$a

The *expected success* takes the success for each point $x$ in the scale, multiplied by the prior probability that $x$ will occur.

$\sum P(x) * \text{success}(x)$

So

$ES(\theta) = \sum_{x < \theta} P(x) \times P(x) \; +$
$\sum_{x \geq \theta} P(x) \times L_0(x | \theta)$
"""

# ╔═╡ 25f1631a-8f7b-48b5-8f40-b68e6a8791c3
function expected_success(θ, scale_points, densityf, cumulativef)
	sum(scale_points) do x
		if x < θ
			densityf(x) * densityf(x)
		else
			densityf(x) * literal_listener(x, θ, scale_points, densityf, cumulativef)
		end
	end
end

# ╔═╡ d12c6005-dfd2-4292-aa41-6bc454cd50c6
md"""
Plot of the expected success for every threshold value $\theta$
"""

# ╔═╡ 3fec1bcc-78d9-459f-a786-543d0dac1a29
let
	p = plot_example_prior()
	
	es(θ) = expected_success(
		θ, 
		example_scale_points, 
		example_density, 
		example_cumulative)
	
	plot!(p,
		example_scale_points,
		es,
		label = "expected success"
	)
end

# ╔═╡ 28aa86cd-7a3e-44b8-9ff1-f7a6036af994
md"""
## Utility

The utility of a threshold is based on the expected success. Parameters are threshold $\theta$ and a coverage parameter $c$

This is calculated as follows:

$U(\theta, c) = ES(\theta) + c \times \Big( \sum_{x = \theta}^{max} P(x) \Big)$
"""

# ╔═╡ d5083551-83fd-4ba2-b21a-9cb278b3a04b
function utility(θ, coverage, scale_points, densityf, cumulativef)
	term1 = expected_success(θ, scale_points, densityf, cumulativef)
	
	term2 = sum(filter(x -> x >= θ, scale_points)) do x
		densityf(x)
	end
	
	term1 + coverage * term2
end

# ╔═╡ 31f5132c-4941-4573-baf2-7b3888a85659
md"To plot the utility, we need to provide  value for the coverage parameter."

# ╔═╡ c40fe4e7-2f37-4343-9478-07e57d3281fa
function plot_example_utility(coverage)
	p = plot_example_prior()
	
	ut(θ) = utility(
		θ, 
		coverage,
		example_scale_points, 
		example_density, 
		example_cumulative)
	
	plot!(p,
		example_scale_points,
		ut,
		label = "utility"
	)
end

# ╔═╡ 8a997b70-599d-42b4-813b-44a9cd4f0984
@bind ut_example_coverage Slider(-0.25:0.01:0.25, default = -0.01)

# ╔═╡ 2573056a-55e7-414c-a6c2-475ee7a586f6
md"Coverage: $(ut_example_coverage)"

# ╔═╡ 59a261ea-cd08-477c-91f7-36f5f4530e88
plot_example_utility(ut_example_coverage)

# ╔═╡ 28d156b6-cbaf-455b-8353-0139848d0496
md"""
## Threshold probability

The probability that one would use a threshold $\theta$ is based on hyperparameters $c$ and $\lambda$ and calculated as follows

$P(\theta | \lambda, c) = \frac{e^{\lambda \cdot U(\theta, c)}}{\sum_t e^{\lambda \cdot U(t, c)}}$
"""

# ╔═╡ 8c1f9f28-a365-4046-b456-699b937879cd
function probability_threshold(θ, λ, coverage, scale_points, densityf, cumulativef)
	exp_utility(x) = exp(
		Float64(λ * utility(x, coverage, scale_points, densityf, cumulativef))
		# convert to float to prevent type error in some cases
	)
	
	numerator = exp_utility(θ)
	denominator =  sum(exp_utility, scale_points)
	
	if denominator < Inf
		numerator / denominator
	else
		1
	end
end

# ╔═╡ 5a768cab-200c-410d-afec-d4011aa6fd6a
md"The plot requires two parameters, $\lambda$ and coverage."

# ╔═╡ 6815087e-f369-4770-8b9a-9f2830d625cf
function plot_example_threshold_probability(λ, coverage)
	p = plot_example_prior()
	
	tp(θ) = probability_threshold(
		θ, 
		λ,
		coverage,
		example_scale_points, 
		example_density, 
		example_cumulative)
	
	plot!(p,
		example_scale_points,
		tp,
		fill = 0, fillalpha = 0.5,
		label = "threshold probability"
	)
end

# ╔═╡ 7e16cb53-ccd6-4b7c-a67a-6efcffadc271
@bind tp_example_λ Slider(1:5:100, default = 50)

# ╔═╡ 6f857b1c-f222-4e85-b799-b969b3916835
md"λ : $(tp_example_λ)"

# ╔═╡ 27af3bf1-de32-427a-9f7b-ead828573eca
@bind tp_example_coverage Slider(-0.25:0.01:0.25, default = -0.01)

# ╔═╡ 4ba5e51d-2e24-4564-a639-eab2a0383fb6
md"Coverage parameter: $(tp_example_coverage)"

# ╔═╡ 66ac83c0-af7d-4496-98c7-faa26eced85f
plot_example_threshold_probability(tp_example_λ, tp_example_coverage)

# ╔═╡ 0e40e06b-c4f9-41f8-bfd9-5868f787c10f
md"""
## Adjective use

Based on the distribution of thresholds, we can now calculate the probability that a speaker would use the adjective for a degree $x$.

The speaker will use the adjective for an object with degree $x$ if they are using a threshold value $\theta$ such that $x \geq \theta$. We use the threshold probability function to estimate how likely such thresholds are.

$S_1(x, \lambda, c) = \sum_{\theta \leq x} P(\theta | \lambda, c)$
"""

# ╔═╡ 0520663b-fc07-45a6-8746-0aa90764bb0b
function use_adjective(degree, λ::Number, coverage::Number, 
		scale_points::AbstractArray, 
		densityf::Function, cumulativef::Function)
	sum(filter(θ -> θ <= degree, scale_points)) do θ
		probability_threshold(θ, λ, coverage, scale_points, densityf, cumulativef)
	end
end

# ╔═╡ fb982d85-d207-4237-a6a3-6b2344d71f7c
md"""
For the sake of efficiency, an alternative method of the function takes an array of precalculated threshold probabilities.
"""

# ╔═╡ 9785d1ed-4540-4f8a-afbd-421cf1c3906e
function use_adjective(degree, θ_probabilities::AbstractArray,
		scale_points::AbstractArray)

	sum(filter(i -> scale_points[i] <= degree, 1:length(scale_points))) do i
		θ_probabilities[i]
		end
end

# ╔═╡ 877bfa0e-71eb-4dfd-954d-879538d57537
md"The plot will use precalculated threshold probabilities."

# ╔═╡ 4dcc331c-745c-4ba1-9ce4-a114800af089
@bind ua_example_λ Slider(1:5:100, default = 50)

# ╔═╡ 8ee9987c-9c52-4e95-8ceb-5c992976007f
md"λ : $(ua_example_λ)"

# ╔═╡ 31caa034-ace3-4ffe-9b07-8742d90982ab
@bind ua_example_coverage Slider(-0.25:0.01:0.25, default = 0.0)

# ╔═╡ 3ae4e681-2d85-42a0-a12e-3db3ab98696d
md"Coverage parameter: $(ua_example_coverage)"

# ╔═╡ c76f04f9-5927-41f5-9f41-7110913a0bf7
ua_example_θ_probabilities = map(example_scale_points) do θ
	probability_threshold(θ, ua_example_λ, ua_example_coverage, 
		example_scale_points, example_density, example_cumulative)
end

# ╔═╡ b42c1d06-2d0e-404b-b697-ea7c0343e4c2
md"""
For convenience, the following struct wraps some parameters for the model. The constructor conducts some preperation steps:
* Get a density and cumulative function from a `Distribution`
* Generate threshold probabilities
"""

# ╔═╡ ebfc50fa-c164-49e5-b467-75db3fa6f12a
struct VagueModel
	λ
	coverage
	scale_points
	probabilities
	densityf
	cumulativef
	θ_probabilities
	
	#constructor
	VagueModel(λ, coverage, scale_points, prior) = let
		probabilities = probability_values(scale_points, prior)
		
		function densityf(degree)
			probabilities[degree][:density]
		end
		
		function cumulativef(degree)
			probabilities[degree][:cumulative]
		end
		
		θ_probabilities = map(scale_points) do θ
			probability_threshold(θ, λ, coverage,
				scale_points, densityf, cumulativef)
		end
		
		new(λ, coverage, scale_points, probabilities, 
			densityf, cumulativef, θ_probabilities)
	end
end

# ╔═╡ b4a9031d-1e8e-42e8-8d86-a8352a5d05e2
md"""
We can now make a new method of the `use_adjective` function that takes a `VagueModel` struct.
"""

# ╔═╡ fbc35f8a-46e2-4c76-92c2-333b9d8a7e48
function use_adjective(degree, model::VagueModel)
	use_adjective(degree, model.θ_probabilities, model.scale_points)
end

# ╔═╡ 27a9f319-6e7a-4547-a35c-4556e2555b26
function plot_example_use_adjective(θ_probabilities)
	ua(d) = use_adjective(
		d, 
		θ_probabilities,
		example_scale_points)
	
	plot(
		example_scale_points,
		ua,
		ylabel = "P",
		xlabel = "degree",
		label = "use adjective | degree",
	)
end

# ╔═╡ d3dbf582-cb9b-4bc5-83c9-28a2c88269b8
let
	p = plot_example_use_adjective(ua_example_θ_probabilities)
end

# ╔═╡ 9b8deef0-42d4-4885-9564-57b4ac22e253
md"""
## Alternative interpretation for bimodal cases
"""

# ╔═╡ e4de916a-0eed-4815-b117-aaa907f75dd7
function group_level_use_adjective(degree, prior::MixtureModel)
	n_components = length(prior.components)
	
	component_mean(i) = mean(prior.components[i])
	
	sum(1:n_components) do i
		component = prior.components[i]
		weight = probs(prior)[i]
		
		prob = pdf(component, degree)  * weight / pdf(prior, degree)
		highest = mean(component) > mean(prior)
		
		prob * highest
	end
end

# ╔═╡ 62a3dda6-0ff8-4edb-9907-735659a7b2a9
example_bimodal = MixtureModel([Normal(30, 5), Normal(70, 5)])

# ╔═╡ 59f6abde-4c06-44e1-8528-e7306047bfa2
let
	p_prior = plot(example_scale_points,
		x -> pdf(example_bimodal, x),
		label = :none,
		title = "prior"
	)
	
	p_speaker = plot(
		example_scale_points,
		x -> group_level_use_adjective(x, example_bimodal),
		label = "group-level speaker"
	)
	
	vague_model = VagueModel(300.0, 0.01, example_scale_points, example_bimodal)
	
	plot!(p_speaker,
		example_scale_points,
		x -> use_adjective(x, vague_model),
		label = "original speaker"
	)
	
	plot(p_speaker, p_prior, layout = (2,1))
end

# ╔═╡ Cell order:
# ╟─2e056874-bfc8-42d6-9412-229cee3fea9c
# ╠═1265bf24-ccef-11eb-0db6-c1355b5726fd
# ╟─0c383b94-3d51-41e1-9d48-0f27b8d3ebf1
# ╠═7dec4e35-7cf6-45ff-aae6-4fe53d093881
# ╠═320b3280-072a-4cca-9011-cb94799a9c60
# ╠═746c9a8f-900c-42bc-9326-8e4f06cf075d
# ╠═7ad46ea1-fb79-4fa6-9f0f-8dd529313275
# ╠═5ae0c8ad-efa4-47d5-af77-3c40e4808ba0
# ╠═93e5caed-f31d-4ff7-a905-90ba32ffd7b3
# ╠═8d281fc6-2a73-4dc0-ad57-493393608615
# ╠═6e825f28-448b-416c-be5d-1d5032aba90e
# ╟─2ce9ee34-d870-4e3e-ad79-2f25374a68f3
# ╠═c04d4d1a-7e07-40a4-b4b3-d6eb893c03f2
# ╟─c682ae23-87f6-4ac5-961a-f5999642b446
# ╠═596c1cda-f3bc-46ee-bb45-cd469ed89c50
# ╟─e36d6390-3e61-4053-809c-7451df1f64e8
# ╟─78254550-795a-47fa-bbb0-598ec245d981
# ╟─eda0b3cc-9b01-4a71-8ecd-99ab3e4e963e
# ╠═b8822897-2e8c-4a59-b886-1931aa43c7f6
# ╟─dee3660c-6a02-4d79-80fe-514f0befb5df
# ╠═25f1631a-8f7b-48b5-8f40-b68e6a8791c3
# ╟─d12c6005-dfd2-4292-aa41-6bc454cd50c6
# ╟─3fec1bcc-78d9-459f-a786-543d0dac1a29
# ╟─28aa86cd-7a3e-44b8-9ff1-f7a6036af994
# ╠═d5083551-83fd-4ba2-b21a-9cb278b3a04b
# ╟─31f5132c-4941-4573-baf2-7b3888a85659
# ╠═c40fe4e7-2f37-4343-9478-07e57d3281fa
# ╟─2573056a-55e7-414c-a6c2-475ee7a586f6
# ╟─8a997b70-599d-42b4-813b-44a9cd4f0984
# ╟─59a261ea-cd08-477c-91f7-36f5f4530e88
# ╟─28d156b6-cbaf-455b-8353-0139848d0496
# ╠═8c1f9f28-a365-4046-b456-699b937879cd
# ╟─5a768cab-200c-410d-afec-d4011aa6fd6a
# ╠═6815087e-f369-4770-8b9a-9f2830d625cf
# ╟─6f857b1c-f222-4e85-b799-b969b3916835
# ╟─7e16cb53-ccd6-4b7c-a67a-6efcffadc271
# ╟─4ba5e51d-2e24-4564-a639-eab2a0383fb6
# ╟─27af3bf1-de32-427a-9f7b-ead828573eca
# ╠═66ac83c0-af7d-4496-98c7-faa26eced85f
# ╟─0e40e06b-c4f9-41f8-bfd9-5868f787c10f
# ╠═0520663b-fc07-45a6-8746-0aa90764bb0b
# ╟─fb982d85-d207-4237-a6a3-6b2344d71f7c
# ╠═9785d1ed-4540-4f8a-afbd-421cf1c3906e
# ╟─877bfa0e-71eb-4dfd-954d-879538d57537
# ╠═27a9f319-6e7a-4547-a35c-4556e2555b26
# ╟─8ee9987c-9c52-4e95-8ceb-5c992976007f
# ╟─4dcc331c-745c-4ba1-9ce4-a114800af089
# ╟─3ae4e681-2d85-42a0-a12e-3db3ab98696d
# ╟─31caa034-ace3-4ffe-9b07-8742d90982ab
# ╠═c76f04f9-5927-41f5-9f41-7110913a0bf7
# ╟─d3dbf582-cb9b-4bc5-83c9-28a2c88269b8
# ╟─b42c1d06-2d0e-404b-b697-ea7c0343e4c2
# ╠═ebfc50fa-c164-49e5-b467-75db3fa6f12a
# ╟─b4a9031d-1e8e-42e8-8d86-a8352a5d05e2
# ╠═fbc35f8a-46e2-4c76-92c2-333b9d8a7e48
# ╟─9b8deef0-42d4-4885-9564-57b4ac22e253
# ╠═e4de916a-0eed-4815-b117-aaa907f75dd7
# ╠═62a3dda6-0ff8-4edb-9907-735659a7b2a9
# ╠═59f6abde-4c06-44e1-8528-e7306047bfa2
