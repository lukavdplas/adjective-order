### A Pluto.jl notebook ###
# v0.15.1

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

# ╔═╡ 6a822a81-a6ca-474f-a2f5-233843565de9
begin
	using Pkg
	root = ".."
	Pkg.activate(root)
	
	try
		using PlutoUI, Plots, Distributions, StatsPlots, HypertextLiteral
	catch
		Pkg.instantiate()
		using PlutoUI, Plots, Distributions, StatsPlots, HypertextLiteral
	end

	theme(:wong, legend=:outerright)
end

# ╔═╡ 56aa594e-41af-4475-88a3-91cb2f5e8674
html"<button onclick=present()>Present</button>"

# ╔═╡ 2f35c604-99e0-11eb-2bf3-c3cdce2b370e
md"""
# The effect of subjectivity on adjective order
### Luka van der Plas
"""

# ╔═╡ ca738741-eee1-4396-8cae-599712736ab0
md"""
## Contents

* Background
* Research question
* How to investigate this
* Experiments
* Results
* Discussion
* Conclusion
"""

# ╔═╡ 42110c43-0dfc-4077-a2e4-d4b6b3a69899
md"""
# Background
"""

# ╔═╡ c224fc59-54b8-4b2b-a3a1-509ee3ff16fd
md"""
## Adjective order
"""

# ╔═╡ 9b4fbf82-44a9-4d1e-9edd-9a09a633e48f
md"""
Do you say...
* *big plastic bag* or *plastic big bag*?
* *big heavy bag* or *heavy big bag*?

Intuitions about adjective order are difficult to describe

Semantic grouping (Dixon, 1982):

$\langle \textit{value}, \textit{dimension}, \textit{physical property}, \textit{speed}, \textit{human propensity}, \textit{age}, \textit{colour} \rangle$
"""

# ╔═╡ 77af885c-f608-42f2-86f6-ebaf3f6d176a
md"""
## Adjective order: the next level ✨

Is there an underlying factor to adjective order?

It may be **subjectivity**
"""

# ╔═╡ a396084e-0620-4ea2-9b17-9ebff8c9afb4
md"""
## Subjectivity

Subjectivity: **potential for disagreement**

Caused by:
* personal taste (*beautiful*)
* vagueness (*big*)
* ...
"""

# ╔═╡ 8ddcc42c-d8d1-4d78-a2e6-7ec006d0e2e4
md"## Why subjectivity?"

# ╔═╡ 89612292-abab-4ecf-b670-898e630c6b4c
md"""
Subjectivity is a problem for **reference resolution**

Compare:

$[\textit{big} \, [\textit{plastic} \; \textit{bag}]]$

vs.

$[\textit{plastic} \, [\textit{big} \; \textit{bag}]]$

More efficient to first combine the adjective that is more objective (Scontras et al.,  2019)
"""

# ╔═╡ 0d7dce07-de21-4dbf-918d-7329bd7fae0f
md"## Current research"

# ╔═╡ 7490a3d8-b4a8-4bc3-8f31-db877fd4b1a0
md"""
Subjectivity and order are measured separately (e.g. Scontras et al., 2017)

 $\rightarrow$ no causal link

 $\rightarrow$ treated as static
"""

# ╔═╡ 934a1574-cff8-45c5-8bd1-cdc45077f1a4
md"""
# Research question

**Is adjective order preference influenced by subjectivity?**

And more specifically:

**Is this sensitive to context?**
"""

# ╔═╡ f39bf794-2c04-437d-9681-b4fe3f0e49c2
md"""
# How to investigate this

An experiment where I:

1. Manipulate subjectivity

2. Measure the effect on order preference

To explain how, we need some theory...
"""

# ╔═╡ 9aed9b08-1cd0-4eec-909e-f10cbe779ac0
md"""
## Vague adjectives

Vagueness: **gradient interpretation**

Scalar adjectives (*big*, *long*, *expensive*): suitable for modelling
"""

# ╔═╡ e3db09c7-effc-446e-8868-955d2543805d
md"""
## How big is "big"?
"""

# ╔═╡ 44d06295-5049-4d53-8c31-90155c6bbb90
@bind size_vline Slider(2:49, default = 25)

# ╔═╡ f60dcca8-6006-45de-aca4-10ec912d8485
begin
	x_values = 1:50
	prior_values = let
		prior = Normal(25, 5.5)
		pdf.(prior, x_values)
	end
	
	function make_threshold_plot(slider_value)
		p = plot(
			xlabel = "size",
			ylabel = "density",
			size = (500, 250),
			legend = :right,
		)
		
		plot!(p,
			1:slider_value, 
			prior_values[1:slider_value],
			color = :black, fillcolor = 7,
			fill = 0, 
			label = "not big"
		)
		
		plot!(p,
			slider_value:50,
			prior_values[slider_value:50],
			color = :black, fillcolor = 3,
			fill = 0,
			label = "big"
		)

		plot!(p, [slider_value], 
			seriestype = :vline, 
			label = nothing,
			color = :black,
		)
	end
	
	function calculate_threshold_percentage(slider_value)
		ratio = sum(prior_values[slider_value:end]) / sum(prior_values)
		percentage = round(ratio * 100, digits=1)
	end
end ;

# ╔═╡ 3e2d47af-a833-489d-a779-a91476e78fbf
make_threshold_plot(size_vline)

# ╔═╡ 782d5725-0555-4279-8559-d94b8d198614
let
	percentage = calculate_threshold_percentage(size_vline)
	md"""
	**$(percentage)%** of all things are "big"
	"""
end

# ╔═╡ 7a8d48e6-b607-46e1-b0bf-726d0d70de7c
md"""
## Threshold values

There is a trade-off between **informativity** and **coverage**

There is no single optimal threshold value
"""

# ╔═╡ 13980aa6-75fd-4c31-a391-6e940abe22ab
function make_gradable_plot(bimodality)
	prior = MixtureModel([
			Normal(25 - (bimodality * 12), 5.5 - (bimodality * 2.5)),
			Normal(25 + (bimodality * 12), 5.5 - (bimodality * 2.5)),
			])
	
	prior_values = pdf.(prior, x_values)
	
	p = plot(
		xlabel = "size",
		ylabel = "density",
		size = (600, 280),
		legend = :none,
		colorbar = :none,
	)
	

	z_values = map(x_values) do x
		1 / (1 + exp(-0.5*(x-27)))
	end
	grad = cgrad([PlotThemes.wong_palette[7], PlotThemes.wong_palette[3]])
	
	plot!(p,
		x_values,
		prior_values,
		color = :black,
		fill = 0,
		fill_z = z_values,
		fillcolor = grad,
	)
	
	p
end ;

# ╔═╡ f9a34cd2-fab0-4d65-b18e-63a1f4ddc621
make_gradable_plot(0.0)

# ╔═╡ 0012e487-6e13-4b24-a805-8a815a1aa74b
md"""
## The prior distribution
"""

# ╔═╡ 421b73e5-2ec2-4cd1-87f1-d347bc11c18b
@bind plot_bimodality_index Slider(0.2 :0.05: 1.0, default = 0.2)

# ╔═╡ 212160ed-47fd-40e5-b42c-e4a4d449194e
make_gradable_plot(plot_bimodality_index)

# ╔═╡ 4aacd22c-c0c0-42f3-be77-48780121f7bf
md"""
# Experiments
"""

# ╔═╡ a2567683-1b7a-41a0-970f-8b7fccc085ea
md"""
## Design
"""

# ╔═╡ fcbf9525-abed-4343-a641-039000cc9b01
md"3 experiments"

# ╔═╡ 331f2e9c-e94e-47a6-8213-d5e22ada4e48
md"""
**Conditions**

* Unimodal distribution
* Bimodal distribution
"""

# ╔═╡ 56c97bea-8779-4a81-b5eb-e69f020cb23f
md"""
**Target adjectives**

* *big*
* *long*
"""

# ╔═╡ 72644945-b5e6-4c43-9c23-bd4a49166a43
md"## Design"

# ╔═╡ a66c5e1e-e9e0-4cf1-bafa-8e72a49af8c9
md"""
**Scenarios**
"""

# ╔═╡ 40078ef0-7ad8-4959-a7ad-2667efdb9e8b
md"""
## Participants
"""

# ╔═╡ 5641fd17-a25e-4762-85b0-7c398be42eda
md"Recruitment through Prolific"

# ╔═╡ f4804a28-f27e-44b7-84ac-186455eace95
md"## Procedure"

# ╔═╡ 017acb94-2675-4225-b34f-ee87ae241dcb
md"""
Online survey

Per scenario:
"""

# ╔═╡ bc65e167-8238-4b00-8999-754ee4fc5a2b
md"""
## Scenario introduction
"""

# ╔═╡ fac04ee7-2280-47cd-a00b-582ca37c84ab
md"""
14 objects per scenario

One version for each condition

Objects vary in
* **size** (*big*) or **length** (*long*)
* **price** (*expensive*, *cheap*)
"""

# ╔═╡ 28ace618-9f7b-4f43-91e9-57af1c4da443
md"""
## Scenario introduction
"""

# ╔═╡ dbeb2823-479f-4d63-881f-5d5f6b194e2d
md"""
## Scenario introduction
"""

# ╔═╡ 1e3a799c-0aec-4fe5-a15a-ee077d0be747
md"## Scenario introduction"

# ╔═╡ aec667ad-d4cf-4686-a531-75defa6fe9ed
md"## Scenario introduction"

# ╔═╡ b862bafe-f46c-4cb6-ade6-9dca5767ef19
md"""
## Semantic judgement task
"""

# ╔═╡ 8c874d10-3d9b-4a6d-8833-41b63bf27a4e
md"## Semantic judgement task"

# ╔═╡ 7c57df4a-3c99-437c-a25a-d520f5a38a1d
html"""
<style>
table.Likert {
	border: none;
}
</style>

How confident did you feel about your selection?

<table class="Likert">
<tr>
	<td>Very doubtful</td>
	<td><input type="radio"></td>
	<td><input type="radio"></td>
	<td><input type="radio"></td>
	<td><input type="radio"></td>
	<td><input type="radio"></td>
	<td>Very confident</td>
</tr>
</table>
"""

# ╔═╡ 31e86552-cef8-419c-8edb-7a74b2dba3f2
md"## Acceptability judgement task"

# ╔═╡ 712e70a0-63b4-4a05-932b-65afb441736a
html"""
<style>
table.Likert {
	border: none;
}
</style>

<b>I saw a big expensive TV over there</b>

<table class="Likert">
<tr>
	<td>Definitely sounds bad</td>
	<td><input type="radio"></td>
	<td><input type="radio"></td>
	<td><input type="radio"></td>
	<td><input type="radio"></td>
	<td><input type="radio"></td>
	<td>Definitely sounds good</td>
</tr>
</table>
"""

# ╔═╡ 5459e3a8-f813-4159-a90e-5e94000ae314
html"""
<style>
table.Likert {
	border: none;
}
</style>

<b>I saw an expensive big TV over there</b>

<table class="Likert">
<tr>
	<td>Definitely sounds bad</td>
	<td><input type="radio"></td>
	<td><input type="radio"></td>
	<td><input type="radio"></td>
	<td><input type="radio"></td>
	<td><input type="radio"></td>
	<td>Definitely sounds good</td>
</tr>
</table>
"""

# ╔═╡ fc215efc-ced0-4114-9291-8ae2ba3663ba
md"## Acceptability judgement task"

# ╔═╡ c6112f98-fd00-412d-b5aa-a55326a318b8
md"""
Sentences to test adjective order:

* *I saw a big expensive TV over there.*
* *I saw an expensive big TV over there.*

Target (*big*/*long*) is combined with
* 2 scalar adjectives (*expensive*, *cheap*)
* 2 absolute adjectives (*leather*, *refurbished*, *striped*...)

 $\rightarrow$ 8 sentences per scenario

In addition: 10 fillers per scenario
"""

# ╔═╡ 696635e9-cb83-4900-9046-c427d6c30b9d
md"""# Results: semantic task"""

# ╔═╡ 1b6490d5-a0bb-4ea1-ac2f-2571d2392ac8
md"## Confidence ratings"

# ╔═╡ 84315bb3-c780-42e3-a1af-8b21ab4e31c1
md"## Potential for disagreement"

# ╔═╡ ae4f30f4-cf46-4a38-af04-a06fcdddd23d
md"""
Subjectivity is described as the *potential for disagreement*

If we would match up two random participants, how likely is it that they disagree on their judgement for an object?

$p_{\textit{disagree}} = 1 - (p_{\textit{both true}} +p_{\textit{both false}})$
$= 1 - ({p_{\textit{true}}}^2 + {p_{\textit{false}}}^2)$

More mixed responses mean higher subjectivity!
"""

# ╔═╡ baad54b7-b944-4289-8ca5-72852c06020b
md"## Potential for disagreement"

# ╔═╡ ecdd00f4-4dae-407d-8072-ae9f3da1a4a3
md"## Semantic model"

# ╔═╡ 9711a1e4-094a-4674-a6c1-d512a3e161dd
md"""
A model of interpretation

Original model: Goodman & Frank (2016)

Two adaptations:
* Mixing in group-level thinking
* Ignoring condition
"""

# ╔═╡ 84fde6a3-a9af-44f0-943c-f80a9712a274
md"""
## Semantic model: original model
"""

# ╔═╡ 5dd898a8-e8d1-4846-8d52-d212a436d3d6
md"## Semantic model: composite model"

# ╔═╡ 45b72705-7ed3-4ace-aa62-0cd447d0fd53
md"""Issues:
* *Practical*: no parameter for between-group distinction
* *Conceptual*: thinks on level of items, not groups

Solution:

Mix this item-level model with a group-level model

For each object...
* Determine what cluster it belongs to
* Determine if that *cluster* is big/long/etc
"""

# ╔═╡ efbcc42b-4238-4e31-a6ee-fb98749a3fbc
md"## Semantic model: composite model"

# ╔═╡ 92392332-1321-41fd-88bd-9c6daf33daac
md"## Semantic model: condition-blind model"

# ╔═╡ 98581c36-eac9-487c-9127-0604fed057ce
md"""
Do people notice the bimodal/unimodal distinction?

The condition-blind model always believes in the same normal distribution, regardless of condition
"""

# ╔═╡ c5c9b6ac-df6b-4b83-adce-115cc0ef3b5e
md"## Semantic model: condition-blind model"

# ╔═╡ df8aa262-f3a8-4cfe-af8e-8aa8bd877c9d
md"## Semantic model: comparison"

# ╔═╡ 717e2b1a-effd-49fa-af32-414c9ec0acc5
md"""
Paramaters estimated with MCMC sampling

Evaluated on posterior probability of data

Performance: *condition-blind > composite > original*
"""

# ╔═╡ 34cab4b3-7b3d-45e1-9040-503ecd6e1c16
md"## Semantic model: comparison"

# ╔═╡ 97647cf0-ec8e-4e0e-b481-24683b2fd99a
md"""
Condition-blind model shows best performance, but has conceptual issues

May indicate that participants do not base judgements on stimuli
"""

# ╔═╡ 5dce214d-5d0d-4134-a69d-aecd4450bb2b
md"""
# Results: acceptability judgements
"""

# ╔═╡ 56ffe1c0-ef3b-4ecb-9ff3-acf91199a02d
md"## Effect of condition"

# ╔═╡ 2b37275e-645e-467b-8376-14960f3e7dfa
md"## Disagreement potential and confidence"

# ╔═╡ f5721070-6141-4abe-b231-484ce50ce8d8
PlutoUI.LocalResource("./figures/order_pref_by_disagreement_and_confidence.svg")

# ╔═╡ c979f17f-5437-4c7c-af1c-b351bee84f84
md"## Effect of scalar vs. absolute adjectives"

# ╔═╡ 2f0e278b-3cba-41ae-b4f9-f57aea48c45b
md"""## Correlation with corpus data"""

# ╔═╡ 0766fd85-0bbc-40fd-bf9d-218e11dbfde4
md"""
We can compare the order preferences to frequency data

Data: Google Ngrams corpus (Michel et al., 2011)

For each pair of adjectives, calculate a *relative frequency score*

$\textit{relative frequency} = \frac{f_{\textit{target first}} - f_{\textit{target second}}}{f_{\textit{target first}} + f_{\textit{target second}}}$

"""

# ╔═╡ 4fb74102-0074-41e5-a679-8562c7867aeb
md"## Correlation with corpus data"

# ╔═╡ 260592ea-a83b-4e32-a4e7-3e73923b0ff8
PlutoUI.LocalResource("./figures/order_pref_by_corpus_freq.svg")

# ╔═╡ 3ddb3ba9-941c-4f4e-b063-9e1663de321a
md"## Summary of findings"

# ╔═╡ bfca19f2-fc18-41f6-bc0c-8d34e3bce647
md"""
Bimodal distribution resulted in...
* Lower disagreement
* Higher confidence
So it seems to affect subjectivity!

However, **the distribution had no effect on adjective order**
"""

# ╔═╡ 68d94e24-e474-45d5-9ced-4469ef2500f0
md"## Summary of findings"

# ╔═╡ 470a481d-9312-4936-8de2-24cba35bfced
md"""
Significant predictors of adjective order:
* Scalar vs. absolute adjectives
* Corpus frequencies

These match expectations, but they are static
"""

# ╔═╡ 53adebc5-520b-4847-ba45-15061d5053b5
md"""
# Discussion
"""

# ╔═╡ ebfadab6-1ad5-4fa6-bc70-fdc405e50b89
md"## Reflection"

# ╔═╡ 8699f9f8-557c-4cbb-99ce-2392f0175bc3
md"""
Context or prior expectations?
* No effect of novel objects
* Good performance of condition-blind model
"""

# ╔═╡ 1a91e8f1-ff36-48af-b3b2-2bfa13dfa3f9
md"Acceptability judgments: task ambiguity"

# ╔═╡ ff1f6e6a-581b-4ef6-b129-c14851da87da
md"## Implications"

# ╔═╡ c63ca361-d69a-4b95-9015-338ab834c80a
md"""
Why did subjectivity not affect order?

💡 Subjectivity is *not the true underlying factor*

💡 The experiment is *too fine-grained*
"""

# ╔═╡ f3264078-b62c-432c-b5a6-a18b630ea847
md"""
# Conclusion
"""

# ╔═╡ 9385aaed-a6cd-4c99-8dd3-6f5305c1a03c
md"""
Context affects how much interpretation varies


No effect on adjective order

Static factors can predict order preference according to expectations
"""

# ╔═╡ 3ce26006-1b16-4c1a-8d38-6060b6440196
md"## Helper code"

# ╔═╡ 984abf1c-e5f4-4766-a914-cabe411cf87b
stackrows(x) = permutedims(hcat(x...),(2,1))

# ╔═╡ 590d567c-0aed-4c96-a309-d659e0142b68
flex(x::Union{AbstractVector,Base.Generator}; kwargs...) = flex(x...; kwargs...)

# ╔═╡ ba999f79-f020-4dd5-a3bc-9fe230b6936f
begin
	Base.@kwdef struct Div
		contents
		style=Dict()
	end
	
	Div(x) = Div(contents=x)
	
	function Base.show(io::IO, m::MIME"text/html", d::Div)
		h = @htl("""
			<div style=$(d.style)>
			$(d.contents)
			</div>
			""")
		show(io, m, h)
	end
end

# ╔═╡ ba95f5ac-f775-4bc8-8c32-9f7cd836a422
function stimulus_div(img_url, size, price; scale = "Size", kwargs...)
	Div(
		HTML("""<p><img src="$(img_url)" style="max-height:5em"></p>
			<p style="margin-block-end: 0px"><b>$(scale):</b> $(size) </p>
			<p style="margin-block-end: 0px"><b>Price:</b> \$ $(price) </p>"""),
		Dict((String(k) => string(v) for (k,v) in kwargs)...)
	)
end ;

# ╔═╡ c48df4d0-cd39-4c30-97b4-b40bfc37cd3a
function flex(args...; kwargs...)
	Div(;
		contents=collect(args),
		style=Dict("display" => "flex", ("flex-" * String(k) => string(v) for (k,v) in kwargs)...)
		)
end

# ╔═╡ 21a75a77-30af-4ce9-b208-988b0cbe8091
function stimulus_with_checkbox(img_url, size, price)
	Div(flex(
			Div(html"""<input type="checkbox">""",
				Dict("width" => "10%", "padding-top" => "5em")),
			
			stimulus_div(img_url, size, price)
			)
	)
end; 

# ╔═╡ 148b9f67-6355-4cf1-a2b0-7d34b9d7407d
flex(
	Div(md"""
		High confidence overall
		
		Higher confidence in bimodal condition $\;$ ($p = .003$)
		""",
		Dict("width" => "100%")),
	
	PlutoUI.LocalResource("./figures/confidence_aggregated.svg")
)

# ╔═╡ fc13ba32-064c-4df3-aeb5-8facdd8c879f
flex(
	Div(md"""
		Lower disagreement in bimodal condition...
		
		... with exception of *big* in exp 3
		""",
		Dict("width" => "100%")),
	
	PlutoUI.LocalResource("./figures/disagreement_combined.svg")
)

# ╔═╡ 7f58bc9e-cd36-4ab1-8885-2884e2e4d2b9
flex(Div(md"""
		 $\lambda$: $(@bind example_λ Slider(0:20:200, default=100))
		""",
		Dict("width" => "50%")),
	Div(md"""
	 $c$: $(@bind example_c Slider(-0.05:0.01:0.05, default = -0.01))
	""")
)

# ╔═╡ 569bc894-cdac-4b19-9cfe-6da8cfb8a0a2
flex(Div(md"""
		 $\lambda$: $(@bind example_λ_cp Slider(0:20:200, default=100))
		""",
		Dict("width" => "33%")),
	
	Div(md"""
	 	$c$: $(@bind example_c_cp Slider(-0.05:0.01:0.05, default = -0.01))
		""",
		Dict("width" => "33%")),
	
	Div(md"""
		 $\alpha$: $(@bind example_α_cp Slider(0.0:0.1:1.0, default = 0.5))
		""")
)

# ╔═╡ 5a8005ea-b6fb-4bdf-ac95-30edadb109bc
flex(Div(md"""
		 $\lambda$: $(@bind example_λ_cb Slider(0:20:200, default=100))
		""",
		Dict("width" => "50%")),
	Div(md"""
	 $c$: $(@bind example_c_cb Slider(-0.05:0.01:0.05, default = -0.01))
	""")
)

# ╔═╡ 6bc1af68-0732-41a1-8568-94a760c2049b
flex(
	Div(md"""
		Similar ratings between conditions.
		
		No interaction between order and condition ($p = .411$)
		""",
		Dict("width" => "100%")),
	
	PlutoUI.LocalResource("./figures/order_pref_by_condition.svg")
)

# ╔═╡ 1a816ccf-13c4-4787-96e3-f68919d93d33
flex(
	Div(md"""
		Stronger preference for *target first* when combined with an absolute adjective
		
		Significant interaction between order and adjective type ($p < .001$)
		""",
		Dict("width" => "100%")),
	
	PlutoUI.LocalResource("./figures/order_pref_by_secondary_type.svg")
)

# ╔═╡ ba7fe41a-7a6b-4261-a21b-7d719c6c38ad
function grid(items::AbstractMatrix; fill_width::Bool=true)
	Div(
		contents=Div.(vec(permutedims(items, [2,1]))), 
		style=Dict(
			"display" => fill_width ? "grid" : "inline-grid", 
			"grid-template-columns" => "repeat($(size(items,2)), auto)",
			"column-gap" => "1em",
		),
	)
end

# ╔═╡ 731dddb0-25be-459b-a995-da9383683c56
grid([
		md"" md"**Experiment 1**" md"**Experiment 2**" md"**Experiment 3**" ;
		md"*big...*" md"*TV*" md"*TV*" md"*hoppler*" ;
		md"*long...*" md"*couch*" md"*couch*" md"*trand*" ;
	])

# ╔═╡ 2052703e-bd23-46e4-a564-470736633b44
grid([
		md"" md"**Experiment 1**" md"**Experiment 2**" md"**Experiment 3**" ;
		md"Participants" md"30" md"31" md"30" ;
	])

# ╔═╡ 44d1958b-6dcf-43a9-98f5-fd3f039aba49
grid([
		md"" md"**Experiment 1**" md"**Experiment 2**" md"**Experiment 3**" ;
		md"Scenario introduction" md"✔️" md"✔️" md"✔️" ;
		md"Semantic task" md"" md"✔️" md"✔️" ;
		md"Acceptability judgements" md"✔️" md"✔️" md"✔️" ;
	])

# ╔═╡ 0081a2a4-b130-45e7-9ff6-595d28deaeea
grid([ 
		stimulus_div("https://raw.githubusercontent.com/lukavdplas/adjective-order/main/experiment/acceptability_with_semantic/materials/images/tv_01.jpg",
			"22 inches",
			"990";
			margin = "0em 1em 0em 8em"
			) stimulus_div("https://raw.githubusercontent.com/lukavdplas/adjective-order/main/experiment/acceptability_with_semantic/materials/images/tv_02.jpg",
			"84 inches",
			"275";
			margin = "0em 1em 0em 1em") ;
		stimulus_div("https://raw.githubusercontent.com/lukavdplas/adjective-order/main/experiment/acceptability_with_semantic/materials/images/tv_03.jpg",
			"70 inches",
			"885";
			margin = "1em 1em 0em 8em"
			) stimulus_div("https://raw.githubusercontent.com/lukavdplas/adjective-order/main/experiment/acceptability_with_semantic/materials/images/tv_04.jpg",
			"34 inches",
			"800"; margin = "1em 8em 0em 1em") ;
	],
)

# ╔═╡ d4186ee3-7306-4e85-98c1-441c1e5cf7c4
grid([ 
		stimulus_div("https://raw.githubusercontent.com/lukavdplas/adjective-order/main/experiment/acceptability_with_semantic/materials/images/ch_01.jpg",
			"""3'7" """,
			"360";
			scale = "Length"
			) stimulus_div("https://raw.githubusercontent.com/lukavdplas/adjective-order/main/experiment/acceptability_with_semantic/materials/images/ch_02.jpg",
			"""6'7" """,
			"965";
			scale = "Length") ;
		stimulus_div("https://raw.githubusercontent.com/lukavdplas/adjective-order/main/experiment/acceptability_with_semantic/materials/images/ch_03.jpg",
			"""5'3" """,
			"290";
			scale = "Length",
			margin = "1em 0em 0em 0em"
			) stimulus_div("https://raw.githubusercontent.com/lukavdplas/adjective-order/main/experiment/acceptability_with_semantic/materials/images/ch_04.jpg",
			"""9'6" """,
			scale = "Length",
			"600"; margin = "1em 0em 0em 0em") ;
	],
)

# ╔═╡ 48fae675-2262-45ae-a200-cbeca8343e66
grid([ 
		stimulus_div("https://raw.githubusercontent.com/lukavdplas/adjective-order/main/experiment/novel_objects/materials/images/bl_01.jpg",
			"18 cm",
			"9.50";
			margin = "0em 1em 0em 8em"
			) stimulus_div("https://raw.githubusercontent.com/lukavdplas/adjective-order/main/experiment/novel_objects/materials/images/bl_02.jpg",
			"14 cm",
			"10.00";
			margin = "0em 1em 0em 1em") ;
		stimulus_div("https://raw.githubusercontent.com/lukavdplas/adjective-order/main/experiment/novel_objects/materials/images/bl_03.jpg",
			"2.5 cm",
			"15.00";
			margin = "1em 1em 0em 8em"
			) stimulus_div("https://raw.githubusercontent.com/lukavdplas/adjective-order/main/experiment/novel_objects/materials/images/bl_04.jpg",
			"5 cm",
			"19.00"; margin = "1em 8em 0em 1em") ;
	],
)

# ╔═╡ 98c04373-d648-41de-97c3-7dafcfdf3661
grid([ 
		stimulus_div("https://raw.githubusercontent.com/lukavdplas/adjective-order/main/experiment/novel_objects/materials/images/sp_01.jpg",
			"8 cm",
			"9.50";
			scale = "Length"
			) stimulus_div("https://raw.githubusercontent.com/lukavdplas/adjective-order/main/experiment/novel_objects/materials/images/sp_02.jpg",
			"33 cm",
			"8.00";
			scale = "Length") ;
		stimulus_div("https://raw.githubusercontent.com/lukavdplas/adjective-order/main/experiment/novel_objects/materials/images/sp_03.jpg",
			"13 cm",
			"8.00";
			scale = "Length",
			margin = "1em 0em 0em 0em"
			) stimulus_div("https://raw.githubusercontent.com/lukavdplas/adjective-order/main/experiment/novel_objects/materials/images/sp_04.jpg",
			"30 cm",
			"11.00"; 
			scale = "Length", margin = "1em 0em 0em 0em") ;
	],
)

# ╔═╡ 29b295fa-740e-4f33-ace7-50abb932ba0b
grid([stimulus_with_checkbox(
			"https://raw.githubusercontent.com/lukavdplas/adjective-order/main/experiment/acceptability_with_semantic/materials/images/tv_01.jpg",
			"22 inches",
			"990"
			) stimulus_with_checkbox(
			"https://raw.githubusercontent.com/lukavdplas/adjective-order/main/experiment/acceptability_with_semantic/materials/images/tv_02.jpg",
			"84 inches",
			"275") ;
		stimulus_with_checkbox(
			"https://raw.githubusercontent.com/lukavdplas/adjective-order/main/experiment/acceptability_with_semantic/materials/images/tv_03.jpg",
			"70 inches",
			"885"
			) stimulus_with_checkbox(
			"https://raw.githubusercontent.com/lukavdplas/adjective-order/main/experiment/acceptability_with_semantic/materials/images/tv_04.jpg",
			"34 inches",
			"800")
		])

# ╔═╡ 3cb66e59-9101-4bf0-8ecb-8e9d4c794c33
function ingredients(path::String)
	# this is from the Julia source code (evalfile in base/loading.jl)
	# but with the modification that it returns the module instead of the last object
	name = Symbol(basename(path))
	m = Module(name)
	Core.eval(m,
        Expr(:toplevel,
             :(eval(x) = $(Expr(:core, :eval))($name, x)),
             :(include(x) = $(Expr(:top, :include))($name, x)),
             :(include(mapexpr::Function, x) = $(Expr(:top, :include))(mapexpr, $name, x)),
             :(include($path))))
	m
end

# ╔═╡ f5e8b788-c02b-4c63-9549-a80387bb5f5f
model = ingredients(root * "/modelling/threshold_model/model_definition.jl");

# ╔═╡ cf402fa6-21c8-4f4b-b24e-f07ec5435ab7
function plot_bimodal_model(λ, c)
	scale = model.example_scale_points
	prior = model.example_bimodal
	speaker = model.VagueModel(λ, c, scale, prior)
	
	p_prior = plot(scale,
		x -> pdf(prior, x),
		legend = :none,
		title = "prior probability",
		ylabel = "P(degree)", xlabel = "degree",
		fill = 0,
		color = :black, fillcolor = 1
	)
	
	p_threshold = plot(scale,
		speaker.θ_probabilities,
		legend = :none,
		title = "threshold probability",
		ylabel = "P_θ(degree)", xlabel = "degree",
		fill = 0,
		color = :black, fillcolor = 1
	)
	
	p_speaker = plot(scale,
		x -> model.use_adjective(x, speaker),
		legend = :none,
		title = "speaker",
		ylabel = "S(degree)", xlabel = "degree",
		lw = 2,
	)
	
	p = plot(p_speaker, p_threshold, p_prior, 
		layout = Plots.grid(3,1, heights = [0.4, 0.4, 0.2]), 
		size = (300, 600))
end;

# ╔═╡ fdb01fa2-b8a7-47e7-9834-3a60fc9481c1
function plot_unimodal_model(λ, c)
	scale = model.example_scale_points
	prior = Normal(50,10)
	speaker = model.VagueModel(λ, c, scale, prior)
	
	p_prior = plot(scale,
		x -> pdf(prior, x),
		legend = :none,
		title = "prior probability",
		ylabel = "P(degree)", xlabel = "degree",
		fill = 0,
		color = :black, fillcolor = 2
	)
	
	p_threshold = plot(scale,
		speaker.θ_probabilities,
		legend = :none,
		title = "threshold probability",
		ylabel = "P_θ(degree)", xlabel = "degree",
		fill = 0,
		color = :black, fillcolor = 2
	)
	
	p_speaker = plot(scale,
		x -> model.use_adjective(x, speaker),
		legend = :none,
		title = "speaker",
		ylabel = "S(degree)", xlabel = "degree",
		lw = 2, color = 2
	)
	
	p = plot(p_speaker, p_threshold, p_prior, 
		layout = Plots.grid(3,1, heights = [0.4, 0.4, 0.2]), 
		size = (300, 600))
end;

# ╔═╡ aeace4bb-2fed-414c-bdbb-697dc42f0938
function plot_model(λ, c)
	p_bimodal = plot_bimodal_model(λ, c)
	p_unimodal = plot_unimodal_model(λ, c)
	
	plot(p_unimodal, p_bimodal, layout = (1,2), size = (500, 320), 
		titlefontsize = 10, guidefontsize = 8, tickfontsize = 6)
end;

# ╔═╡ 5a6be561-3d5e-4eb0-aff5-cbe75150e494
plot_model(example_λ, example_c)

# ╔═╡ d5d257ef-f2d9-4354-999d-17445cfd740e
function plot_bimodal_model_composite(λ, c, α)
	scale = model.example_scale_points
	prior = model.example_bimodal
	speaker = model.CompositeModel(λ, c, α, scale, prior)
	
	p_prior = plot(scale,
		x -> pdf(prior, x),
		legend = :none,
		title = "prior probability",
		ylabel = "P(degree)", xlabel = "degree",
		fill = 0,
		color = :black, fillcolor = 1
	)
	
	θ_probs = map(scale) do x
		if x > first(scale)
			prev_x = x - step(model.example_scale_points)
			model.use_adjective(x, speaker) - model.use_adjective(prev_x, speaker)
		else
			model.use_adjective(x, speaker)
		end
	end
	
	p_threshold = plot(scale,
		θ_probs,
		legend = :none,
		title = "threshold probability",
		ylabel = "P_θ(degree)", xlabel = "degree",
		fill = 0,
		color = :black, fillcolor = 1
	)
	
	p_speaker = plot(scale,
		x -> model.use_adjective(x, speaker),
		legend = :none,
		title = "speaker",
		ylabel = "S(degree)", xlabel = "degree",
		lw = 2,
	)
	
	p = plot(p_speaker, p_threshold, p_prior, 
		layout = Plots.grid(3,1, heights = [0.4, 0.4, 0.2]), 
		size = (300, 600))
end;

# ╔═╡ f064ff09-40c9-4d3a-9e21-c2c3361cad17
function plot_composite_model(λ, c, α)
	p_bimodal = plot_bimodal_model_composite(λ, c, α)
	p_unimodal = plot_unimodal_model(λ, c)
	
	plot(p_unimodal, p_bimodal, layout = (1,2), size = (500, 320), 
		titlefontsize = 10, guidefontsize = 8, tickfontsize = 6)
end;

# ╔═╡ 0e27f658-968e-4652-96d4-8cfd3bb3c138
plot_composite_model(example_λ_cp, example_c_cp, example_α_cp)

# ╔═╡ b2f3d10c-66be-4ce8-b0bb-3a5e74474b64
function plot_bimodal_model_conditionblind(λ, c)
	scale = model.example_scale_points
	prior = model.example_bimodal
	prior_unim = Normal(50,10)
	speaker = model.VagueModel(λ, c, scale, prior_unim)
	
	p_prior = plot(scale,
		x -> pdf(prior, x),
		legend = :none,
		title = "prior probability",
		ylabel = "P(degree)", xlabel = "degree",
		fill = 0,
		color = :black, fillcolor = 1
	)
	
	p_threshold = plot(scale,
		speaker.θ_probabilities,
		legend = :none,
		title = "threshold probability",
		ylabel = "P_θ(degree)", xlabel = "degree",
		fill = 0,
		color = :black, fillcolor = 1
	)
	
	p_speaker = plot(scale,
		x -> model.use_adjective(x, speaker),
		legend = :none,
		title = "speaker",
		ylabel = "S(degree)", xlabel = "degree",
		lw = 2,
	)
	
	p = plot(p_speaker, p_threshold, p_prior, 
		layout = Plots.grid(3,1, heights = [0.4, 0.4, 0.2]), 
		size = (300, 600))
end;

# ╔═╡ 237e136c-182c-4183-85b0-e95acb7776e6
function plot_model_conditionblind(λ, c)
	p_bimodal = plot_bimodal_model_conditionblind(λ, c)
	p_unimodal = plot_unimodal_model(λ, c)
	
	plot(p_unimodal, p_bimodal, layout = (1,2), size = (500, 320), 
		titlefontsize = 10, guidefontsize = 8, tickfontsize = 6)
end;

# ╔═╡ 9de156fc-bcab-462f-b563-fae5058a00ef
plot_model_conditionblind(example_λ_cb, example_c_cb)

# ╔═╡ Cell order:
# ╟─56aa594e-41af-4475-88a3-91cb2f5e8674
# ╟─2f35c604-99e0-11eb-2bf3-c3cdce2b370e
# ╟─ca738741-eee1-4396-8cae-599712736ab0
# ╟─42110c43-0dfc-4077-a2e4-d4b6b3a69899
# ╟─c224fc59-54b8-4b2b-a3a1-509ee3ff16fd
# ╟─9b4fbf82-44a9-4d1e-9edd-9a09a633e48f
# ╟─77af885c-f608-42f2-86f6-ebaf3f6d176a
# ╟─a396084e-0620-4ea2-9b17-9ebff8c9afb4
# ╟─8ddcc42c-d8d1-4d78-a2e6-7ec006d0e2e4
# ╟─89612292-abab-4ecf-b670-898e630c6b4c
# ╟─0d7dce07-de21-4dbf-918d-7329bd7fae0f
# ╟─7490a3d8-b4a8-4bc3-8f31-db877fd4b1a0
# ╟─934a1574-cff8-45c5-8bd1-cdc45077f1a4
# ╟─f39bf794-2c04-437d-9681-b4fe3f0e49c2
# ╟─9aed9b08-1cd0-4eec-909e-f10cbe779ac0
# ╟─e3db09c7-effc-446e-8868-955d2543805d
# ╟─44d06295-5049-4d53-8c31-90155c6bbb90
# ╟─3e2d47af-a833-489d-a779-a91476e78fbf
# ╟─782d5725-0555-4279-8559-d94b8d198614
# ╟─f60dcca8-6006-45de-aca4-10ec912d8485
# ╟─7a8d48e6-b607-46e1-b0bf-726d0d70de7c
# ╟─f9a34cd2-fab0-4d65-b18e-63a1f4ddc621
# ╟─13980aa6-75fd-4c31-a391-6e940abe22ab
# ╟─0012e487-6e13-4b24-a805-8a815a1aa74b
# ╟─421b73e5-2ec2-4cd1-87f1-d347bc11c18b
# ╟─212160ed-47fd-40e5-b42c-e4a4d449194e
# ╟─4aacd22c-c0c0-42f3-be77-48780121f7bf
# ╟─a2567683-1b7a-41a0-970f-8b7fccc085ea
# ╟─fcbf9525-abed-4343-a641-039000cc9b01
# ╟─331f2e9c-e94e-47a6-8213-d5e22ada4e48
# ╟─56c97bea-8779-4a81-b5eb-e69f020cb23f
# ╟─72644945-b5e6-4c43-9c23-bd4a49166a43
# ╟─a66c5e1e-e9e0-4cf1-bafa-8e72a49af8c9
# ╟─731dddb0-25be-459b-a995-da9383683c56
# ╟─40078ef0-7ad8-4959-a7ad-2667efdb9e8b
# ╟─5641fd17-a25e-4762-85b0-7c398be42eda
# ╟─2052703e-bd23-46e4-a564-470736633b44
# ╟─f4804a28-f27e-44b7-84ac-186455eace95
# ╟─017acb94-2675-4225-b34f-ee87ae241dcb
# ╟─44d1958b-6dcf-43a9-98f5-fd3f039aba49
# ╟─bc65e167-8238-4b00-8999-754ee4fc5a2b
# ╟─fac04ee7-2280-47cd-a00b-582ca37c84ab
# ╟─28ace618-9f7b-4f43-91e9-57af1c4da443
# ╟─0081a2a4-b130-45e7-9ff6-595d28deaeea
# ╟─ba95f5ac-f775-4bc8-8c32-9f7cd836a422
# ╟─dbeb2823-479f-4d63-881f-5d5f6b194e2d
# ╟─d4186ee3-7306-4e85-98c1-441c1e5cf7c4
# ╟─1e3a799c-0aec-4fe5-a15a-ee077d0be747
# ╟─48fae675-2262-45ae-a200-cbeca8343e66
# ╟─aec667ad-d4cf-4686-a531-75defa6fe9ed
# ╟─98c04373-d648-41de-97c3-7dafcfdf3661
# ╟─b862bafe-f46c-4cb6-ade6-9dca5767ef19
# ╟─29b295fa-740e-4f33-ace7-50abb932ba0b
# ╟─21a75a77-30af-4ce9-b208-988b0cbe8091
# ╟─8c874d10-3d9b-4a6d-8833-41b63bf27a4e
# ╟─7c57df4a-3c99-437c-a25a-d520f5a38a1d
# ╟─31e86552-cef8-419c-8edb-7a74b2dba3f2
# ╟─712e70a0-63b4-4a05-932b-65afb441736a
# ╟─5459e3a8-f813-4159-a90e-5e94000ae314
# ╟─fc215efc-ced0-4114-9291-8ae2ba3663ba
# ╟─c6112f98-fd00-412d-b5aa-a55326a318b8
# ╟─696635e9-cb83-4900-9046-c427d6c30b9d
# ╟─1b6490d5-a0bb-4ea1-ac2f-2571d2392ac8
# ╟─148b9f67-6355-4cf1-a2b0-7d34b9d7407d
# ╟─84315bb3-c780-42e3-a1af-8b21ab4e31c1
# ╟─ae4f30f4-cf46-4a38-af04-a06fcdddd23d
# ╟─baad54b7-b944-4289-8ca5-72852c06020b
# ╟─fc13ba32-064c-4df3-aeb5-8facdd8c879f
# ╟─ecdd00f4-4dae-407d-8072-ae9f3da1a4a3
# ╟─9711a1e4-094a-4674-a6c1-d512a3e161dd
# ╟─84fde6a3-a9af-44f0-943c-f80a9712a274
# ╟─7f58bc9e-cd36-4ab1-8885-2884e2e4d2b9
# ╟─5a6be561-3d5e-4eb0-aff5-cbe75150e494
# ╟─f5e8b788-c02b-4c63-9549-a80387bb5f5f
# ╟─cf402fa6-21c8-4f4b-b24e-f07ec5435ab7
# ╟─fdb01fa2-b8a7-47e7-9834-3a60fc9481c1
# ╟─aeace4bb-2fed-414c-bdbb-697dc42f0938
# ╟─5dd898a8-e8d1-4846-8d52-d212a436d3d6
# ╟─45b72705-7ed3-4ace-aa62-0cd447d0fd53
# ╟─efbcc42b-4238-4e31-a6ee-fb98749a3fbc
# ╟─569bc894-cdac-4b19-9cfe-6da8cfb8a0a2
# ╟─0e27f658-968e-4652-96d4-8cfd3bb3c138
# ╟─d5d257ef-f2d9-4354-999d-17445cfd740e
# ╟─f064ff09-40c9-4d3a-9e21-c2c3361cad17
# ╟─92392332-1321-41fd-88bd-9c6daf33daac
# ╟─98581c36-eac9-487c-9127-0604fed057ce
# ╟─c5c9b6ac-df6b-4b83-adce-115cc0ef3b5e
# ╟─5a8005ea-b6fb-4bdf-ac95-30edadb109bc
# ╟─9de156fc-bcab-462f-b563-fae5058a00ef
# ╟─b2f3d10c-66be-4ce8-b0bb-3a5e74474b64
# ╟─237e136c-182c-4183-85b0-e95acb7776e6
# ╟─df8aa262-f3a8-4cfe-af8e-8aa8bd877c9d
# ╟─717e2b1a-effd-49fa-af32-414c9ec0acc5
# ╟─34cab4b3-7b3d-45e1-9040-503ecd6e1c16
# ╟─97647cf0-ec8e-4e0e-b481-24683b2fd99a
# ╟─5dce214d-5d0d-4134-a69d-aecd4450bb2b
# ╟─56ffe1c0-ef3b-4ecb-9ff3-acf91199a02d
# ╟─6bc1af68-0732-41a1-8568-94a760c2049b
# ╟─2b37275e-645e-467b-8376-14960f3e7dfa
# ╟─f5721070-6141-4abe-b231-484ce50ce8d8
# ╟─c979f17f-5437-4c7c-af1c-b351bee84f84
# ╟─1a816ccf-13c4-4787-96e3-f68919d93d33
# ╟─2f0e278b-3cba-41ae-b4f9-f57aea48c45b
# ╟─0766fd85-0bbc-40fd-bf9d-218e11dbfde4
# ╟─4fb74102-0074-41e5-a679-8562c7867aeb
# ╟─260592ea-a83b-4e32-a4e7-3e73923b0ff8
# ╟─3ddb3ba9-941c-4f4e-b063-9e1663de321a
# ╟─bfca19f2-fc18-41f6-bc0c-8d34e3bce647
# ╟─68d94e24-e474-45d5-9ced-4469ef2500f0
# ╟─470a481d-9312-4936-8de2-24cba35bfced
# ╟─53adebc5-520b-4847-ba45-15061d5053b5
# ╟─ebfadab6-1ad5-4fa6-bc70-fdc405e50b89
# ╟─8699f9f8-557c-4cbb-99ce-2392f0175bc3
# ╟─1a91e8f1-ff36-48af-b3b2-2bfa13dfa3f9
# ╟─ff1f6e6a-581b-4ef6-b129-c14851da87da
# ╟─c63ca361-d69a-4b95-9015-338ab834c80a
# ╟─f3264078-b62c-432c-b5a6-a18b630ea847
# ╟─9385aaed-a6cd-4c99-8dd3-6f5305c1a03c
# ╟─3ce26006-1b16-4c1a-8d38-6060b6440196
# ╠═6a822a81-a6ca-474f-a2f5-233843565de9
# ╠═984abf1c-e5f4-4766-a914-cabe411cf87b
# ╠═c48df4d0-cd39-4c30-97b4-b40bfc37cd3a
# ╠═590d567c-0aed-4c96-a309-d659e0142b68
# ╠═ba999f79-f020-4dd5-a3bc-9fe230b6936f
# ╠═ba7fe41a-7a6b-4261-a21b-7d719c6c38ad
# ╠═3cb66e59-9101-4bf0-8ecb-8e9d4c794c33
