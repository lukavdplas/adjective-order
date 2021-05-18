### A Pluto.jl notebook ###
# v0.14.5

using Markdown
using InteractiveUtils

# ╔═╡ 53332b06-b708-11eb-2b74-ed38e37fbd29
begin
	using Pkg
	
	Pkg.activate("../..")
	
	try
		using DataFrames, CSV, Plots
	catch
		Pkg.instantiate()
		using DataFrames, CSV, Plots
	end
	
	theme(:wong, legend = :outertop)
end

# ╔═╡ d4dbf454-b9cd-482c-ae32-2706395dde1c
results = CSV.read("clmm_results.csv", DataFrame)

# ╔═╡ 94c2b7d2-b0e9-486f-b4a7-364947cf1462
scatter([1,2,4],[3,2,1], xerror = [1,.5, 0.3])

# ╔═╡ ef1313cc-4bad-43a9-b44b-fc5b7a75cdd1
vpadding = 0.25

# ╔═╡ 928d2672-6088-491e-bcd7-df036bc96128
function experiment_series!(plot, experiment)
	effect_sizes = let
		colname = "exp" * string(experiment) * "_effect_size"
		values = results[:, colname]
		(collect ∘ skipmissing)(values)
	end
	
	errors = let
		colname = "exp" * string(experiment) * "_std_error"
		values = results[:, colname]
		(collect ∘ skipmissing)(values)
	end
	
	y_values = let
		filtered = filter(1:nrow(results)) do i
			colname = "exp" * string(experiment) * "_effect_size"
			value = results[i, colname]
			!ismissing(value)
		end
		reversed = reverse(filtered)
		
		offset = if experiment == 1
			vpadding
		elseif experiment == 2
			0
		else
			-vpadding
		end
		
		reversed .+ offset
	end
	
	label = "experiment " * string(experiment)
	
	scatter!(plot,
		effect_sizes, y_values,
		xerror = errors,
		seriescolor = experiment,
		label = label
	)
end

# ╔═╡ 7fb31634-be7e-423a-b67c-7d59d3173e1f
ylabels = reverse(strip.(results.factor))

# ╔═╡ 49ebb41b-a005-4a35-b2da-bcd2bbd7aee7
yticks = (1:length(ylabels))

# ╔═╡ 70e1f827-61bb-4208-8127-193067a151ef
let
	p = plot(
		yticks = (yticks, ylabels),
		size = (800, 500),
		yminorgrid = true, minorgridalpha = 0.5, minorticks = 2,
	)
	
	for experiment in 1:3
		experiment_series!(p, experiment)
	end
	
	p
end

# ╔═╡ Cell order:
# ╠═53332b06-b708-11eb-2b74-ed38e37fbd29
# ╠═d4dbf454-b9cd-482c-ae32-2706395dde1c
# ╠═94c2b7d2-b0e9-486f-b4a7-364947cf1462
# ╠═928d2672-6088-491e-bcd7-df036bc96128
# ╠═ef1313cc-4bad-43a9-b44b-fc5b7a75cdd1
# ╠═49ebb41b-a005-4a35-b2da-bcd2bbd7aee7
# ╠═7fb31634-be7e-423a-b67c-7d59d3173e1f
# ╠═70e1f827-61bb-4208-8127-193067a151ef
