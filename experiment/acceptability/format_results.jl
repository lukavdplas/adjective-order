### A Pluto.jl notebook ###
# v0.14.0

using Markdown
using InteractiveUtils

# ╔═╡ a75d2178-8e27-11eb-383b-9d6053581a5a
begin
	using DataFrames, CSV, Statistics
end

# ╔═╡ 8ea8d699-8c8f-4f3f-9b14-581ccff6f4a5
md"## Import raw results"

# ╔═╡ 696d6c47-ecc6-425d-bee2-3fc12e2322a7
results_raw = CSV.read(
	"results_raw.csv", DataFrame,
	skipto = 4
) ;

# ╔═╡ 46db08e0-49eb-447e-82da-9cf2b9551176
results = let
	real_responses = results_raw[results_raw.DistributionChannel .== "anonymous", :]
	finished = real_responses[real_responses.Finished, :]
end

# ╔═╡ 4fe2de19-0adb-405e-a2d5-9e30b5d6794d
md"## Item data"

# ╔═╡ 2ce3d321-e021-4ed9-bfb8-a7173be76e5c
item_data = let
	#hardcoded values
	data = DataFrame(
		id = [
			"tv_test_1", "tv_test_2", "tv_test_3", "tv_test_4",
			"tv_test_5", "tv_test_6", "tv_test_7", "tv_test_8",
			"ch_test_1", "ch_test_2", "ch_test_3", "ch_test_4",
			"ch_test_5", "ch_test_6", "ch_test_7", "ch_test_8",
			"tv_filler_1", "tv_filler_2", "tv_filler_3", "tv_filler_4",
			"tv_filler_5", "tv_filler_6", "tv_filler_7", "tv_filler_8",
			"tv_filler_9", "tv_filler_10",
			"ch_filler_1", "ch_filler_2", "ch_filler_3", "ch_filler_4",
			"ch_filler_5", "ch_filler_6", "ch_filler_7", "ch_filler_8",
			"ch_filler_9", "ch_filler_10"
		],
		adjectivestring = [
			"big expensive", "expensive big", "refurbished big", "big refurbished",
			"big cheap", "cheap big", "big discounted", "discounted big",
			"long expensive", "expensive long", "leather long", "long leather",
			"cheap long", "long cheap", "discounted long", "long discounted",
			missing, missing, missing, missing,
			missing, missing, missing, missing,
			missing, missing,
			missing, missing, missing, missing,
			missing, missing, missing, missing,
			missing, missing,
		],
		filler_acceptability = [
			missing, missing, missing, missing,
			missing, missing, missing, missing,
			missing, missing, missing, missing,
			missing, missing, missing, missing,
			"questionable", "questionable", "acceptable", "acceptable",
			"acceptable", "unacceptable", "unacceptable", "unacceptable",
			"unacceptable", "acceptable",
			"questionable", "acceptable", "acceptable", "questionable",
			"questionable", "acceptable", "unacceptable", "unacceptable",
			"acceptable", "unacceptable"
		]
	)
	
	#columns derived from other values
	data.item_type = map(data.id) do name
		if occursin("test", name)
			"test"
		else
			"filler"
		end
	end
	
	data.scenario = map(data.id) do id
		if startswith(id, "tv")
			"tv"
		else
			"couch"
		end
	end
	
	data.adj_target = map(data.adjectivestring) do str
		if ismissing(str)
			missing
		elseif occursin("big", str)
			"big"
		else
			"long"
		end
	end
	
	data.adj_secondary = map(data.adjectivestring) do str
		if ismissing(str)
			missing
		elseif occursin("expensive", str)
			"expensive"
		elseif occursin("cheap", str)
			"cheap"
		elseif occursin("discounted", str)
			"discounted"
		elseif occursin("leather", str)
			"leather"
		else
			"refurbished"
		end
	end
	
	data.adj_secondary_type = map(data.adjectivestring) do str
		if ismissing(str)
			missing
		elseif occursin("expensive", str) || occursin("cheap", str)
			"scalar"
		else
			"absolute"
		end
	end
	
	data.order = map(data.adjectivestring) do str
		if ismissing(str)
			missing
		elseif startswith(str, "big") || startswith(str, "long")
			"first"
		else
			"second"
		end
	end
	
	data
end

# ╔═╡ a037c002-3f6c-470a-9b86-400746a13a9d
CSV.write("item_data.csv", item_data)

# ╔═╡ 0e60eeb7-3bef-45c7-91fa-7cbca475923a
md"## Format results"

# ╔═╡ 26286993-52c4-4f47-8aa9-4835636131d1
columns = [ 
		"participant", names(item_data)..., 
		"group", "condition", "response", "time"
	]

# ╔═╡ 51d61b17-4016-4135-ba2a-f0b0cd893999
participants = 1:nrow(results)

# ╔═╡ a6c045e2-2041-4438-8306-8acd49db9409
function empty_df()
	DataFrame(map(name -> name => [], columns))
end

# ╔═╡ 5acc86ef-6ff1-43e7-adf2-54112f9fa79b
md"### Acceptability judgements"

# ╔═╡ f57aa7b5-cc63-48da-aa05-00b223a5fd78
condition_table = DataFrame(
	"group" => [1,2],
	"tv" => ["bimodal", "unimodal"],
	"couch" => ["unimodal", "bimodal"]
)

# ╔═╡ 21492ade-a33d-489e-9113-f13bb4251986
item_results = let
	df = empty_df()
	
	for participant in 1:nrow(results)
		group = results[participant, "Group"]
		
		#acceptability judgements
		for i in 1:nrow(item_data)
			#item and response
			id = item_data[i, "id"]
			item = id * "_1"
			response = results[participant, item]		
			time = results[participant, id * "_time_Last Click"]
			
			#item data
			metadata = map(names(item_data)) do name
				name => item_data[i, name]
			end
			
			#condition (bimodal/unimodal)
			condition = condition_table[group, item_data[i, "scenario"]]

			
			data = Dict(
				"participant" => participant, "group" => group, 
				"condition" => condition, "response" => response,
				"time" => time,
				metadata...
			)
			
			push!(df, data)
		end
		
	end
	
	df
end 

# ╔═╡ e1ae1b84-a276-481b-a36e-60f2586d66e9
md"### Meta questions"

# ╔═╡ d802d624-f0de-4fcb-92b6-8c8f1953d192
meta_items = [
	"intro_prolific_id", "intro_native", "intro_other_langs", "intro_gender"] ;

# ╔═╡ 2b0c6db5-0362-493f-9560-ee65c295c8c1
meta_results = let
	df = empty_df()
	
	for participant in participants
		group = results[participant, "Group"]
		
		#other questions
		for item in meta_items
			response = results[participant, item]
			metadata = map(names(item_data)) do name
				if name == "item_type"
					name => "meta"
				elseif name == "id"
					name => item
				else
					name => missing
				end
			end
			
			data = Dict("participant" => participant, "group" => group,
				"condition" => missing, "response" => response,
				"time" => missing,
				metadata...
			)
			
			push!(df, data)
		end	
	end
	
	df
end

# ╔═╡ 7c2776b7-3667-4301-b8fb-0962eff83fc1
md"### Global time data"

# ╔═╡ 278b857b-579d-450c-b6ed-689081b84aae
time_results = let
	df = empty_df()
	
	for participant in participants
		group = results[participant, "Group"]
		
		time_items = [
			("time_total", "Duration (in seconds)"),
			("time_tv", "tv_scenario_time_Page Submit"),
			("time_couch", "ch_scenario_time_Page Submit")
		]
		
		for (item, colname) in time_items	
			time = results[participant, colname]
		
			data = map(columns) do col
				if col == "participant"
					participant
				elseif col == "group"
					group
				elseif col == "item_type"
					"meta"
				elseif col == "id"
					item
				elseif col == "time"
					time
				elseif col == "condition" && item == "time_tv"
					condition_table[group, "tv"]
				elseif col == "condition" && item == "time_couch"
					condition_table[group, "couch"]
				else
					missing
				end
			end

			push!(df, data)
		end
	end
	
	df
end

# ╔═╡ 68852137-94e2-4759-b90f-0da4443ba24b
md"### All results"

# ╔═╡ 632f6074-cfa1-47e4-a738-86dce66cbfb1
all_results = [item_results ; meta_results ; time_results] ;

# ╔═╡ 022a4a99-8e10-4204-a8af-0388f8c56f05
CSV.write("results.csv", all_results)

# ╔═╡ Cell order:
# ╠═a75d2178-8e27-11eb-383b-9d6053581a5a
# ╟─8ea8d699-8c8f-4f3f-9b14-581ccff6f4a5
# ╠═696d6c47-ecc6-425d-bee2-3fc12e2322a7
# ╠═46db08e0-49eb-447e-82da-9cf2b9551176
# ╟─4fe2de19-0adb-405e-a2d5-9e30b5d6794d
# ╟─2ce3d321-e021-4ed9-bfb8-a7173be76e5c
# ╠═a037c002-3f6c-470a-9b86-400746a13a9d
# ╟─0e60eeb7-3bef-45c7-91fa-7cbca475923a
# ╠═26286993-52c4-4f47-8aa9-4835636131d1
# ╠═51d61b17-4016-4135-ba2a-f0b0cd893999
# ╠═a6c045e2-2041-4438-8306-8acd49db9409
# ╟─5acc86ef-6ff1-43e7-adf2-54112f9fa79b
# ╟─f57aa7b5-cc63-48da-aa05-00b223a5fd78
# ╠═21492ade-a33d-489e-9113-f13bb4251986
# ╟─e1ae1b84-a276-481b-a36e-60f2586d66e9
# ╠═d802d624-f0de-4fcb-92b6-8c8f1953d192
# ╠═2b0c6db5-0362-493f-9560-ee65c295c8c1
# ╟─7c2776b7-3667-4301-b8fb-0962eff83fc1
# ╠═278b857b-579d-450c-b6ed-689081b84aae
# ╟─68852137-94e2-4759-b90f-0da4443ba24b
# ╠═632f6074-cfa1-47e4-a738-86dce66cbfb1
# ╠═022a4a99-8e10-4204-a8af-0388f8c56f05
