library(ordinal)

results = read.csv("results_filtered.csv")

test_results = subset(results, item_type == "test")

#all acjectives

m_all <- clmm(response ~ order * condition + (1 | participant), test_results)
summary(m_all)

#scalar adjectives

scalar_results = subset(test_results, adj_secondary_type == "scalar")

m_scalar <- clm(response ~ order * condition, data = scalar_results)
summary(m_scalar)

#absolute adjectives

absolute_results = subset(test_results, adj_secondary_type == "absolute")

m_absolute <- clm(response ~ order * condition, data = absolute_results)
summary(m_absolute)