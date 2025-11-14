# **Assignment 5**

This assignment included two major tasks: implementing a full S4 class for Wald-style confidence intervals and creating publication-quality COVID-19 visualizations using plotly and NYTimes data.

**Problem 1 — Wald Confidence Intervals (S4)**
* Built a custom S4 class waldCI with a constructor, validator, show method, accessors, and setters.
* Implemented contains(), overlap(), as.numeric(), and transformCI() with monotonicity checks.
* Created three CI objects and evaluated all required method calls.
* Demonstrated that the validator blocks invalid intervals (negative SE, reversed bounds, infinite values, improper setter usage).

**Problem 3 — COVID-19 Visualization (plotly)**
* Identified national major/minor spikes using smoothed timeseries.
* Compared trajectories of the highest-rate vs lowest-rate states to highlight differences in timing and severity.
* Determined the first five states with substantial COVID activity based on early threshold crossings.
