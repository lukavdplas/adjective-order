using CSV, DataFrames

stimuli_path = "./experiment/acceptability_with_semantic/materials/stimuli_data.csv"
data = CSV.read(stimuli_path, DataFrame)

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

using GaussianMixtures

parameters(model) = Dict(
	:w => model.w,
	:μ => model.μ,
	:σ => sqrt.(model.Σ)
	)

gmm_size_tv_bim = let
   sample = get_sample("size", "tv", "bimodal")
   GMM(2, Float64.(sample))
end

params_size_tv_bim = parameters(gmm_size_tv_bim)

gmm_size_ch_bim = let
    sample = get_sample("size", "couch", "bimodal")
    GMM(2, Float64.(sample))
 end

 params_size_ch_bim = parameters(gmm_size_ch_bim)