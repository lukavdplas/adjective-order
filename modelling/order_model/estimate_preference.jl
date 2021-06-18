### A Pluto.jl notebook ###
# v0.14.8

using Markdown
using InteractiveUtils

# ╔═╡ 8b8a92c6-d032-11eb-0137-afbbf72b726d
begin
	using Pkg
	root = "../.."
	Pkg.activate(root)
	
	function ingredients(path::String)
		#function copied from https://github.com/fonsp/Pluto.jl/issues/115
		name = Symbol(basename(path))
		m = Module(name)
		Core.eval(m,
			Expr(:toplevel,
				 :(eval(x) = $(Expr(:core, :eval))($name, x)),
				 :(include(x) = $(Expr(:top, :include))($name, x)),
				 :(include(mapexpr::Function, x) =
					$(Expr(:top, :include))(mapexpr, $name, x)),
				 :(include($path))))
		m
	end
	
	try
		using DataFrames, CSV, Plots
	catch
		Pkg.instantiate()
		using DataFrames, CSV, Plots
	end
	
	theme(:wong, legend = :outerright)
end

# ╔═╡ aaa9134a-c7b8-486a-b7f8-62f9450c4fd2
paths = Dict(
	:all_results => root * "/modelling/results/results_with_disagreement.csv"
)

# ╔═╡ 44b4cf10-7b86-4e13-95ec-2ab825f7b2a3
all_results = CSV.read(paths[:all_results], DataFrame)

# ╔═╡ cbeb0915-0f02-44f1-a3e7-a147a9fd2992
md"""
## Disagreement potential
"""

# ╔═╡ 6a370a3a-3680-45eb-91bf-1f0105fb76bb
md"""
### Long, big, expensive

These values are already in the dataframe.
"""

# ╔═╡ 1dd20c82-601a-4cf4-92f7-1951105daaad
md"""
### Cheap
"""

# ╔═╡ 94dc57ea-a02f-4565-bb15-82d1dcd2fa81
function disagreement_cheap(item)
	missing
end

# ╔═╡ b92005b4-39d6-46ab-b8cd-8be8db1138e3
md"""
### Absolute adjectives

For the sake of simplicity, I assume that there is no noise in the interpretation of absolute adjectives, so people will always agree on them.
"""

# ╔═╡ f8e66190-5492-4262-aaf9-d34de4bc0570
absolute_noise = 0.0

# ╔═╡ 3df0ae93-2008-4166-b2c5-80313663f111
md"""
### Complete function
"""

# ╔═╡ c548a0b4-7a06-4c8c-81b3-0210c8922315
function disagreement_potential(adjective, item)
	if adjective ∈ ["long", "big"]
		item.disagreement_on_adj_target
	elseif adjective == "expensive"
		item.disagreement_on_adj_secondary
	elseif adjective == "cheap"
		disagreement_cheap(item)
	else
		absolute_noise
	end
end

# ╔═╡ e91667cd-8b8b-4073-8573-4f0ebf121c24
function order_evaluation(item)
	if !ismissing(item.adjectivestring)	
		adjectives = split(item.adjectivestring)

		first_subjectivity = disagreement_potential(adjectives[1], item)
		second_subjectivity = disagreement_potential(adjectives[2], item)
		
		first_subjectivity - second_subjectivity
	else
		missing
	end
end

# ╔═╡ 5ab54f01-ea3d-40df-bceb-a953d2b9144f
scores = map(eachrow(all_results)) do row
	order_evaluation(row)
end

# ╔═╡ da5f8e34-c4b5-4db5-9c42-abd8a8c69eb6
plotdata = let
	data = DataFrame(
		:score => scores,
		:response => all_results.response
	)
	
	filter!(data) do row
		!ismissing(row.score)
	end
	
	data.response = parse.(Int, data.response)
	
	data
end

# ╔═╡ 381ab291-f431-49e1-9638-66f74ec2ab07
let
	p = plot(
		xlabel = "order score",
		ylabel = "acceptability rating"
	)
	
	pal = let
		c1 = PlotThemes.wong_palette[5]
		palette(cgrad([:white, c1], 5, categorical = true))
	end
	
	scores = sort(unique(plotdata.score))
	
	for rating in reverse(1:5)
		rating_data = filter(row -> row.response <= rating, plotdata)
		
		counts = map(scores) do score
			n = count(s -> s == score, rating_data.score)
			total = count(s -> s == score, plotdata.score) 
			n / total
		end
		
		plot!(p,
			scores, counts,
			color = :black,
			fill = 0, fillcolor = rating,
			palette = pal,
			label = rating
		)
	end
	
	p
	
end

# ╔═╡ Cell order:
# ╠═8b8a92c6-d032-11eb-0137-afbbf72b726d
# ╠═aaa9134a-c7b8-486a-b7f8-62f9450c4fd2
# ╠═44b4cf10-7b86-4e13-95ec-2ab825f7b2a3
# ╟─cbeb0915-0f02-44f1-a3e7-a147a9fd2992
# ╟─6a370a3a-3680-45eb-91bf-1f0105fb76bb
# ╟─1dd20c82-601a-4cf4-92f7-1951105daaad
# ╠═94dc57ea-a02f-4565-bb15-82d1dcd2fa81
# ╟─b92005b4-39d6-46ab-b8cd-8be8db1138e3
# ╠═f8e66190-5492-4262-aaf9-d34de4bc0570
# ╟─3df0ae93-2008-4166-b2c5-80313663f111
# ╠═c548a0b4-7a06-4c8c-81b3-0210c8922315
# ╠═e91667cd-8b8b-4073-8573-4f0ebf121c24
# ╠═5ab54f01-ea3d-40df-bceb-a953d2b9144f
# ╠═da5f8e34-c4b5-4db5-9c42-abd8a8c69eb6
# ╠═381ab291-f431-49e1-9638-66f74ec2ab07
