# Estimate prior distribution for bimodal samples using GaussianMixtures

# Import data (this is all identical to stimuli.jl)

import Pkg
root = "."
Pkg.activate(root)

using CSV, DataFrames

paths = Dict(
	:stimuli_exp2 => root * "/experiment/acceptability_with_semantic/materials/stimuli_data.csv",
	:stimuli_exp3 => root * "/experiment/novel_objects/materials/stimuli_data.csv"
)

data = let
	data_exp3 = CSV.read(paths[:stimuli_exp3], DataFrame)
	
	data_exp2 = let
		data = CSV.read(paths[:stimuli_exp2], DataFrame)
		#reorder and rename columns to match exp3
		select!(data, [:index, :size, :price, :bimodal, :unimodal, :scenario])
		rename(data, names(data_exp3))
	end
	
	vcat(data_exp2, data_exp3)
end

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

# Import GaussianMixtures and estimate data

using GaussianMixtures

function get_parameters(scale, scenario, condition)
	sample = Float64.(get_sample(scale, scenario, condition))
	model = GMM(2, sample)

	parameters = Dict(
		:w => model.w,
		:μ => model.μ,
		:σ => sqrt.(model.Σ)
	)
end

params_size_tv_bim = get_parameters("size", "tv", "bimodal")

params_size_couch_bim = get_parameters("size", "couch", "bimodal")

params_size_ball_bim = get_parameters("size", "ball", "bimodal")

params_size_spring_bim = get_parameters("size", "spring", "bimodal")