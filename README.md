# Adjective order

This repository contains my work for my master thesis at Utrecht University.

✨ [go to the the github page of this repository](https://lukavdplas.github.io/adjective-order/) ✨

### What is this about?

_Abstract of my thesis:_

This study investigates the order of English adjective clusters (e.g. _big expensive TV_ vs. _expensive big TV_). Previous research has established that the subjectivity of the adjective is a good predictor for its preferred position, and provided a theoretical motivation for this preference, but has not directly tested a causal link.

This study approaches the relationship between the subjectivity and order of adjectives from an empirical perspective, by setting up an experiment that manipulates the subjectivity of adjectives by presenting different contexts. I then investigate whether this context has an effect on adjective order preference.

Three experiments are conducted, which take a similar approach. The experiments focus on scalar adjectives and present participants with different types of prior distributions, to achieve different levels of uncertainty about the interpretation of the adjective. The effect of this manipulation on subjectivity is verified in a semantic judgement task, by considering inter-subject disagreement and participants' self-reported confidence.

Within this context, adjective order preference is investigated using an acceptability judgement task. This task presents sentences containing adjective clusters, allowing a comparison between the acceptability of different orders.

The results indicate that the context can effectively influence the subjectivity of the adjective. However, there is no evidence that this affects preferences for adjective order. The results show some expected order preferences, but no significant effect of context.

These results suggest that adjective order preference is not sensitive to subtle contextual variation. Further research may reveal whether adjective order is completely independent of context, or whether the distinctions in this experiment are too subtle to detect.

### What is in this repository?

The repository contains data about the experiments I'm conducting, and the code I use for analysis. It's intended as an appendix to my thesis, so it's not self-explanatory.

The [experiment](./experiment) directory has a subdirectory for each experiment.

* [experiment/acceptability](./experiment/acceptability) is the first experiment.
* [experiment/acceptability_with_semantic](./experiment/acceptability) is the second experiment, which adds a semantic judgement task to the procedure.
* [experiment/novel_objects](./experiment/acceptability) is the third experiment. The method is mostly identical to the second experiment, but instead of TVs and couches, the experiment uses fictional objects.

Each experiment folder contains some code to process and inspect the results. There is also a subdirectory "materials" with information on stimuli and questions, and a subdirectory "results" with the results.

The [modelling](./modelling) directory contains code used for analysis. It contains the code used to calculate disagreement potential, and the following subdirectories:

* [modelling/linear_model](./modelling/linear_model) mainly contains the statistical models to investigate significant factors on acceptability judgements.
* [modelling/order_model](./modelling/order_model) contains the model of adjective order preference.
* [modelling/threshold_model](./modelling/threshold_model) contains the semantic model.
* [modelling/results](./modelling/results) contains various output files.

### How do I view or run the code?

Most of the code is written in Julia using Pluto notebooks. If you want to view the code, you can read the raw code, but I recommend using the [github page](https://lukavdplas.github.io/adjective-order/) of this repository, which contains a static rendered version of each notebook. This is the easiest and quickest way to view the code, complete with output, plots and documentation ✨

If you want to run the code yourself, you will have to install Julia. You can run each notebook as a Julia script, but I recommend installing Pluto. See instructions [here](https://github.com/fonsp/Pluto.jl#lets-do-it).

After installing Pluto, clone the repository and run any of the notebooks in Pluto. Downloading notebooks individually will not work, as they depend on data in the repository, and use the Julia environment specified in [Project.toml](./Project.toml).
