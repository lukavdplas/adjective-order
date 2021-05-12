### A Pluto.jl notebook ###
# v0.14.3

using Markdown
using InteractiveUtils

# ╔═╡ a75d2178-8e27-11eb-383b-9d6053581a5a
begin
    import Pkg
    Pkg.activate("../..")
	Pkg.instantiate()

    using CSV, DataFrames
end

# ╔═╡ 21c40f3f-f93f-403d-8d10-63d273e4d163
md"""
# Format results

This script takes the raw output from the survey and converts it to a neat format for analysis.

The raw output is not public (because it is not anonymous), and the script obviously does not work without it. The rendered web page will give some errors.
"""

# ╔═╡ 8ea8d699-8c8f-4f3f-9b14-581ccff6f4a5
md"## Import raw results"

# ╔═╡ 696d6c47-ecc6-425d-bee2-3fc12e2322a7
results_raw = CSV.read(
	"results/results_raw.csv", DataFrame,
	skipto = 4
) ;

# ╔═╡ 46db08e0-49eb-447e-82da-9cf2b9551176
results = filter(results_raw) do row
	row.DistributionChannel == "anonymous" && row.Finished == "True"
	#exclude previews and unfinished responses
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
CSV.write("materials/item_data.csv", item_data)

# ╔═╡ 0e60eeb7-3bef-45c7-91fa-7cbca475923a
md"## Format results"

# ╔═╡ 26286993-52c4-4f47-8aa9-4835636131d1
columns = [ 
		"participant", "id", "response", "time", 
	"group", "condition", names(item_data)[2:end]...,
	"stimulus_size", "stimulus_price", "confidence_on_semantic",
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

# ╔═╡ 4000e200-f3b9-4d09-af10-48b8b4ad5a97
md"""
### Semantic judgements
"""

# ╔═╡ ef76ed48-c7d2-42a4-b9f9-6fa3bc718114
semantic_items = let
	ids = [
		"tv_sj_big_bim", "tv_sj_big_unim", 
		"tv_sj_exp_bim", "tv_sj_exp_unim",
		"ch_sj_long_bim", "ch_sj_long_unim",
		"ch_sj_exp_bim", "ch_sj_exp_unim",
	]
	
	parts(id) = split(id, "_")
	
	scenarios = map(ids) do id
		parts(id)[1] == "tv" ? "tv" : "couch"
	end
	
	adjectives = map(ids) do id
		parts(id)[3] == "exp" ? "expensive" : parts(id)[3]
	end
	
	conditions = map(ids) do id
		parts(id)[4] == "bim" ? "bimodal" : "unimodal"
	end
	
	DataFrame(
		"id" => ids,
		"scenario" => scenarios,
		"adjective" => adjectives,
		"condition" => conditions
	)
end

# ╔═╡ 69044955-6953-4517-984a-a3032ad72185
stimuli_data = CSV.read("materials/stimuli_data.csv", DataFrame)

# ╔═╡ 43129d45-0772-467b-ada9-4c7337423973
function parse_answer(answer, scenario)	
	raw_items = split(answer, ",")
	
	clean_items = map(raw_items) do item
		words = split(strip(item), r"\s+")
		size = words[2]
		price = words[end]
		
		(size, price)
	end
	
	parse_size(item) = let
		sizestring = item[1]
		if scenario == "tv"
			parse(Int64, sizestring)
		else
			stripped = strip(sizestring, ['\"'])
			splitted = split(stripped, r"'")
			feet, inches = parse.(Int64, splitted)
			total_inches = inches + 12 * feet
		end
	end
	
	parse_price(item) = parse(Int64, item[2])
	
	map(clean_items) do item
		Dict("size" => parse_size(item), "price" => parse_price(item))
	end
end

# ╔═╡ 5c40473f-5e91-4190-ad8a-5de254284041
function collect_semantic_judgements(response, scenario, condition, adjective)
	if ismissing(response)
		return missing
	end
	
	selection = parse_answer(response, scenario)
	stimuli = filter(stimuli_data) do row
		(row.scenario == scenario) && row[condition]
	end
	
	map(eachrow(stimuli)) do row
		size = row["size"]
		price = row["price"]
		ismatch(item) = (item["size"] == size) && (item["price"] == price)
		
		id = "sj_" * adjective * "_" * row["index"]
		selected = any(ismatch.(selection))
		
		Dict(
			"id" => id,
			"stimulus_size" => size,
			"stimulus_price" => price,
			"response" => selected,
		)
	end
end

# ╔═╡ bac8883b-919f-4026-bea0-9e2e95b9fc9d
semantic_results = let
	df = empty_df()
	
	for participant in 1:nrow(results)
		group = results[participant, "Group"]
		
		for item in eachrow(semantic_items)
			scenario = item["scenario"]
			condition = condition_table[group, scenario]
			adjective = item["adjective"]
			colname = item["id"]
			response = results[participant, colname]
			
			if !ismissing(response)
				judgements = collect_semantic_judgements(
					response, scenario, condition, adjective)
			
				for judgement in judgements
					
					data = Dict(
						"participant" => participant,
						"group" => group,
						"condition" => condition,
						"scenario" => scenario,
						"adj_target" => adjective,
						"item_type" => "semantic",
						judgement...
					)
					
					for col in columns
						if !(col in keys(data))
							data[col] = missing
						end
					end
					
					push!(df, data)
				end
			end
		end
	end
	
	df
end

# ╔═╡ 23ca8de5-06ee-4b90-ab0a-d25d68142da7
md"""
### Confidence questions
"""

# ╔═╡ 9967b13c-4541-4b2e-b566-f4aefca41c9d
confidence_items = DataFrame(
	"id" => ["tv_sj_big_con", "tv_sj_exp_con", "ch_sj_long_con", "ch_sj_exp_con"],
	"scenario" => ["tv", "tv", "couch", "couch"],
	"adjective" => ["big", "expensive", "long", "expensive"]
)

# ╔═╡ 4dba5fc9-d218-461b-9e29-1405b6f9aa58
confidence_results = let
	df = empty_df()
	
	for participant in 1:nrow(results)
		group = results[participant, "Group"]
		
		for item in eachrow(confidence_items)
			condition = condition_table[group, item["scenario"]]
			adjective = item["adjective"]
			colname = item["id"] * "_1"
			response = Int(results[participant, colname])
			
			data = Dict(
				"item_type" => "confidence",
				"id" => item["id"],
				"participant" => participant,
				"response" => response,
				"group" => group,
				"condition" => condition,
				"scenario" => item["scenario"],
				"adj_target" => adjective
			)
			
			for col in columns
				if !(col in keys(data))
					data[col] = missing
				end
			end
			
			push!(df, data)
		end
	end
	
	df
end

# ╔═╡ 787693d9-4111-45f6-b14f-21603783ade3
function confidence_rating(participant, scenario)
	adjective = scenario == "tv" ? "big" : "long"
	
	data = filter(confidence_results) do row
		(row.participant == participant) && (row.scenario == scenario) && (row.adj_target == adjective)
	end
	
	response = first(data.response)
end

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
			response = Int(results[participant, item])	
			time = results[participant, id * "_time_Last Click"]
			
			#item data
			metadata = map(names(item_data)) do name
				name => item_data[i, name]
			end
			
			#condition (bimodal/unimodal)
			scenario = item_data[i, "scenario"]
			condition = condition_table[group, scenario]
			
			#confidence on semantic task
			confidence = confidence_rating(participant, scenario)

			
			data = Dict(
				"participant" => participant, "group" => group, 
				"condition" => condition, "response" => response,
				"time" => time,
				"confidence_on_semantic" => confidence,
				metadata...
			)
			
			for col in columns
				if !(col in keys(data))
					data[col] = missing
				end
			end
			
			push!(df, data)
		end
		
	end
	
	df
end 

# ╔═╡ e1ae1b84-a276-481b-a36e-60f2586d66e9
md"### Meta questions"

# ╔═╡ d802d624-f0de-4fcb-92b6-8c8f1953d192
meta_items = [
	"intro_native", "intro_other_langs", "intro_gender"] ;

# ╔═╡ 2b0c6db5-0362-493f-9560-ee65c295c8c1
meta_results = let
	df = empty_df()
	
	for participant in participants
		group = results[participant, "Group"]
		
		#other questions
		for item in meta_items
			response = results[participant, item]
			
			data = Dict("participant" => participant, "group" => group,
				"response" => response,
				"item_type" => "meta",
				"id" => item,
			)
			
			for col in columns
				if !(col in keys(data))
					data[col] = missing
				end
			end
			
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
			
			condition = if item == "time_tv"
				condition_table[group, "tv"]
			elseif item == "time_couch"
				condition_table[group, "couch"]
			else
				missing
			end
			
			data = Dict(
				"participant" => participant,
				"item_type" => "meta",
				"id" => item,
				"time" => time,
				"group" => group,
				"condition" => condition
			)
			
			for col in columns
				if !(col in keys(data))
					data[col] = missing
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
all_results = [
	item_results ; 
	semantic_results ; 
	confidence_results ; 
	meta_results ; 
	time_results] ;

# ╔═╡ 022a4a99-8e10-4204-a8af-0388f8c56f05
CSV.write("results/results.csv", all_results)

# ╔═╡ Cell order:
# ╟─21c40f3f-f93f-403d-8d10-63d273e4d163
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
# ╟─4000e200-f3b9-4d09-af10-48b8b4ad5a97
# ╟─ef76ed48-c7d2-42a4-b9f9-6fa3bc718114
# ╠═69044955-6953-4517-984a-a3032ad72185
# ╠═43129d45-0772-467b-ada9-4c7337423973
# ╠═5c40473f-5e91-4190-ad8a-5de254284041
# ╠═bac8883b-919f-4026-bea0-9e2e95b9fc9d
# ╟─23ca8de5-06ee-4b90-ab0a-d25d68142da7
# ╠═9967b13c-4541-4b2e-b566-f4aefca41c9d
# ╠═4dba5fc9-d218-461b-9e29-1405b6f9aa58
# ╠═787693d9-4111-45f6-b14f-21603783ade3
# ╟─e1ae1b84-a276-481b-a36e-60f2586d66e9
# ╠═d802d624-f0de-4fcb-92b6-8c8f1953d192
# ╠═2b0c6db5-0362-493f-9560-ee65c295c8c1
# ╟─7c2776b7-3667-4301-b8fb-0962eff83fc1
# ╠═278b857b-579d-450c-b6ed-689081b84aae
# ╟─68852137-94e2-4759-b90f-0da4443ba24b
# ╠═632f6074-cfa1-47e4-a738-86dce66cbfb1
# ╠═022a4a99-8e10-4204-a8af-0388f8c56f05
