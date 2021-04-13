library(ordinal)

results = read.csv("results/results_filtered.csv")

test_results = subset(results, item_type == "test")

#all adjectives

m_all <- clmm(response ~ order * condition * adj_target  + (1 | participant), test_results)
summary(m_all)

#scalar adjectives

scalar_results = subset(test_results, adj_secondary_type == "scalar")

m_scalar <- clmm(response ~ order * condition  + (1 | participant), data = scalar_results)
summary(m_scalar)

#absolute adjectives

absolute_results = subset(test_results, adj_secondary_type == "absolute")

m_absolute <- clmm(response ~ order * condition  + (1 | participant), data = absolute_results)
summary(m_absolute)

# -------------------------------------

# take two experiments together

aj_results = read.csv("../acceptability/results/results_filtered.csv")
aj_results$participant = sapply(aj_results$participant, function(x){100 + x})
aj_results$stimulus_size = sapply(aj_results$id, function(x){NULL})
aj_results$stimulus_price = sapply(aj_results$id, function(x){NULL})
aj_test_results = subset(aj_results, item_type == "test")

combined_results = rbind(test_results, aj_test_results)

#all adjectives
m_comb_all = clmm(response ~ order * condition + (1 | participant), combined_results)
summary(m_comb_all)


#scalar adjectives
scalar_combined_results = subset(combined_results, adj_secondary_type == "scalar")
m_comb_scalar <- clm(response ~ order * condition  + (1 | participant), data = scalar_combined_results)
summary(m_comb_scalar)

#absolute adjectives

absolute_combined_results = subset(combined_results, adj_secondary_type == "absolute")
m_comb_absolute <- clm(response ~ order * condition  + (1 | participant), data = absolute_combined_results)
summary(m_comb_absolute)