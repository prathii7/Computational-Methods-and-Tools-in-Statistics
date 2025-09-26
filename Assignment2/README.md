### Assignment 2

In this assignment I worked on three problems.


Problem 1: Modified Random Walk
- Implemented three versions of a random walk in R.  
- Demonstrated identical results using pre-generated random inputs.  
- Benchmarked with microbenchmark.  
- Estimated probability of ending at 0 using Monte Carlo simulation.

Problem 2: Mean of Mixture of Distributions
- Simulated daily car counts with Poisson and Normal distributions.  
- Implemented without loops using matrices.  
- Estimated average cars/day across 100000 simulated days (~264).


Problem 3: Linear Regression (YouTube Superbowl Ads)
- Imported and de-identified YouTube Superbowl ads data.  
- Explored and log-transformed engagement variables.  
- Fitted linear regression models with ad features + year.  
- Found that year was significantly associated with engagement.  
- Reproduced OLS coefficients manually using matrix algebra and matched lm().
