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

# ╔═╡ 6a822a81-a6ca-474f-a2f5-233843565de9
begin
	using PlutoUI, Plots, Distributions, StatsPlots
	theme(:wong, legend=:outerright)
end

# ╔═╡ 56aa594e-41af-4475-88a3-91cb2f5e8674
html"<button onclick=present()>Present</button>"

# ╔═╡ 2f35c604-99e0-11eb-2bf3-c3cdce2b370e
md"""
# Subjectivity and adjective order
### Luka van der Plas
"""

# ╔═╡ ca738741-eee1-4396-8cae-599712736ab0
md"""
## Contents

* Background
* Research question
* How to investigate this
* My experiment
* Results
* Discussion
"""

# ╔═╡ 42110c43-0dfc-4077-a2e4-d4b6b3a69899
md"""
# Background
What's the deal with adjective order?
"""

# ╔═╡ c224fc59-54b8-4b2b-a3a1-509ee3ff16fd
md"""
## Adjective order

Discuss Dixon
"""

# ╔═╡ 21f437c3-73ee-4641-a6ad-c01cd74a9763
md"""
## A comparison

Simile with rainbow colours
"""

# ╔═╡ 77af885c-f608-42f2-86f6-ebaf3f6d176a
md"""
## Adjective order: the next level ✨

So what is the big factor in adjective order?

It may be **subjectivity**
"""

# ╔═╡ a396084e-0620-4ea2-9b17-9ebff8c9afb4
md"""
## Subjectivity

Explain concept: faultless disagreement
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

What are vague adjectives...
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
			ylabel = "P",
			size = (650, 300)
		)
		
		plot!(p,
			1:slider_value, 
			prior_values[1:slider_value],
			fill = 0, fillalpha = 0.2,
			label = "not big"
		)
		
		plot!(p,
			slider_value:50,
			prior_values[slider_value:50],
			fill = 0, fillalpha = 0.2,
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

There is a trade-off between **informativity** and **usefulness**

There is no single optimal threshold value
"""

# ╔═╡ 0012e487-6e13-4b24-a805-8a815a1aa74b
md"""
## The prior distribution

Explain unimodal/bimodal setup
"""

# ╔═╡ 4aacd22c-c0c0-42f3-be77-48780121f7bf
md"""
# Experiment
"""

# ╔═╡ b862bafe-f46c-4cb6-ade6-9dca5767ef19
md"""
## Semantic judgement example
"""

# ╔═╡ feea4e1a-00cf-4728-9330-d90c0024e8c2
html"""
<style>
table.Container {
	width: 100%;
	border: none;
}
tr.RowContainer {
	height: 200px;
}
tr.RowContainer:hover {
	background-color: white;
}
td.ItemContainer {
	padding: 10px;
}
div.Item { box-sizing: border-box; }
div.Item:hover {
	background-color: #FAF7F1;
}
div.Checkbox {
	width: 10%;
}
div.Stimulus {
	width: 50%;
}
</style>

<table class="Container">
  <tr class="RowContainer">
    <td class="ItemContainer">
		<div class="Item">
			<div class="Checkbox"><input type="checkbox"></div>
			<div class="Stimulus">
				<img src="https://survey.uu.nl/CP/Graphic.php?IM=IM_d0bPhQbgjkIwXRP" style="max-width:90%"><br>
				<b>Size:</b> 22 inches <br>
				<b>Price:</b> $ 990
			</div>
		</div>
	</td>
    <td class="ItemContainer">
		<div class="Item">Smith</div>
	</td>
    <td class="ItemContainer">
		<div class="Item">50</div>
	</td>
  </tr>
  <tr class="RowContainer">
    <td class="ItemContainer">
		<div class="Item">Eve</div>
	</td>
    <td class="ItemContainer">
		<div class="Item">Jackson</div>
	</td>
    <td class="ItemContainer">
		<div class="Item">40</div>
	</td>
  </tr>
</table> 
"""

# ╔═╡ 31e86552-cef8-419c-8edb-7a74b2dba3f2
md"## Acceptability judgement example"

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

# ╔═╡ 5dce214d-5d0d-4134-a69d-aecd4450bb2b
md"""
# Results
"""

# ╔═╡ 3ce26006-1b16-4c1a-8d38-6060b6440196
md"## Helper code"

# ╔═╡ Cell order:
# ╟─56aa594e-41af-4475-88a3-91cb2f5e8674
# ╟─2f35c604-99e0-11eb-2bf3-c3cdce2b370e
# ╟─ca738741-eee1-4396-8cae-599712736ab0
# ╟─42110c43-0dfc-4077-a2e4-d4b6b3a69899
# ╟─c224fc59-54b8-4b2b-a3a1-509ee3ff16fd
# ╟─21f437c3-73ee-4641-a6ad-c01cd74a9763
# ╟─77af885c-f608-42f2-86f6-ebaf3f6d176a
# ╟─a396084e-0620-4ea2-9b17-9ebff8c9afb4
# ╟─934a1574-cff8-45c5-8bd1-cdc45077f1a4
# ╟─f39bf794-2c04-437d-9681-b4fe3f0e49c2
# ╟─9aed9b08-1cd0-4eec-909e-f10cbe779ac0
# ╟─e3db09c7-effc-446e-8868-955d2543805d
# ╟─44d06295-5049-4d53-8c31-90155c6bbb90
# ╟─3e2d47af-a833-489d-a779-a91476e78fbf
# ╟─782d5725-0555-4279-8559-d94b8d198614
# ╟─f60dcca8-6006-45de-aca4-10ec912d8485
# ╟─7a8d48e6-b607-46e1-b0bf-726d0d70de7c
# ╟─0012e487-6e13-4b24-a805-8a815a1aa74b
# ╟─4aacd22c-c0c0-42f3-be77-48780121f7bf
# ╟─b862bafe-f46c-4cb6-ade6-9dca5767ef19
# ╟─feea4e1a-00cf-4728-9330-d90c0024e8c2
# ╟─31e86552-cef8-419c-8edb-7a74b2dba3f2
# ╟─712e70a0-63b4-4a05-932b-65afb441736a
# ╟─5459e3a8-f813-4159-a90e-5e94000ae314
# ╟─5dce214d-5d0d-4134-a69d-aecd4450bb2b
# ╟─3ce26006-1b16-4c1a-8d38-6060b6440196
# ╠═6a822a81-a6ca-474f-a2f5-233843565de9
