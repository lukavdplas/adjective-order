# Adjective order

This repository contains my ongoing work for my master thesis at Utrecht University.

### What is this about?

I will include an abstract of my thesis here once I have written one 🙃

Quick explanation: in my thesis I look at people's preferences for the order of adjectives: for example, do you say "big expensive TV" or "expensive big TV"? In particular, I am conducting experiments to see if this preference is influenced by the context.

There is some work suggesting that adjective order preferences are predicted by the subjectivity of each adjective. Subjectivity means that people can disagree about whether the adjective applies to an object, without either of them being wrong. 

In my experiments, participants see a selection of objects of different sizes. The idea is that some distributions will provide a clear division into a "big" and "small" category, providing a more objective sense of what these words mean. This context may influence where someone places an adjective like "big" or "long".

### What is in this repository?

The repository contains data about the experiments I'm conducting, and the code I use for analysis. It's intended as an appendix to my thesis, so it's not self-explanatory.

The [experiments](./experiments) directory has a subdirectory for each experiment.

* [experiments/acceptability](./experiments/acceptability) is the first experiment.
* [experiments/acceptability_with_semantic](./experiments/acceptability) is the second experiment, which adds a semantic judgement task to the procedure.
* [experiments/novel_objects](./experiments/acceptability) is the third experiment. The method is mostly identical to the second experiment, but instead of TVs and couches, the experiment uses fictional objects.

Each experiment folder contains some code to process and inspect the results. There is also a subdirectory "materials" with information on stimuli and questions, and a subdirectory "results" with the results.

The [modelling](./modelling) directoy contains some of the more complicated analysis steps, but it's still kind of a mess.

### How do I view or run the code?

Most of the code is written in Julia using Pluto notebooks. If you want to view the code, you can read the raw code, but I recommend using the [github page](https://lukavdplas.github.io/adjective-order/) of this repository, which contains a static rendered version of each notebook. This is the easiest and quickest way to view the code, complete with output, plots and documentation ✨

If you want to run the code yourself, you will have to install Julia. You can run each notebook as a Julia script, but I recommend installing Pluto. See instructions [here](https://github.com/fonsp/Pluto.jl#lets-do-it).

After installing Pluto, clone the repository and run any of the notebooks in Pluto. Downloading notebooks individually will not work, as they depend on data in the repository, and use the Julia environment specified in [Project.toml](./Project.toml).
