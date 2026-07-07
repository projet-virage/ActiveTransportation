# Agent-Based Transportation Mode Choice Model for Montreal
## Overview

This repository implements a spatially explicit Agent-Based Model (ABM) for simulating transportation mode choice in the Island of Montreal, Canada.

The model combines:

- Agent-Based Modeling (Mesa)
- Geographic Information Systems (GeoPandas)
- Network Analysis (NetworkX + OSMnx)
- Multinomial Logit (MNL) discrete choice modeling

to estimate how individuals choose among four transportation modes:

- Automobile
- Public Transit
- Bicycle (BIXI)
- Walking

The framework is designed to investigate transportation mode choice behaviors of individuals in the Island of Montreal while providing a flexible platform for evaluating transportation policies and infrastructure interventions.

---------------------------------------------------------------------------------------------------

# Model Objectives

The primary objectives of this model are:

- simulate home-work commuting behavior of Montreal residents;
- estimate the transportation mode choice of individuals at the Dissemination Area (DA) level regarding the diverse characteristics of infrastructures;
- consider the influence of travel time, age, income, accessibility to STM and Bixi infrastructure on transportation decisions;
- Investigate the impact of policy intervention scenarios on people's transportation mode choices.
------------------------------------------------------------------------

# Model Workflow

1. Importing spatial data
2. Creating four different networks, one for each transportation mode
3. Assigning nearest nodes in each Network to the Bixi, STM, residential, and workplace as the corresponding representer nodes in each network, thereby enabling shortest-path computations across different transportation systems. 
4. Creating agents at the DA level regarding census data and initializing their attributes 
5. Assigning residential and workplace locations to agents
6. Computing network travel times in all four transportation modes
7. Estimating utilities
8. Computing mode choice probabilities
9. Selecting transportation mode
10. Comparing simulated vs observed mode shares in each DA
11. Optimizing utility coefficients by minimizing the error/differences between models' outputs and census data
12. Running baseline simulations 30 times
13. Running each intervention simulation 30 times and investigating the impact of each intervention by comparing its results with the baseline model's outputs

------------------------------------------------------------------------------------------------
# Agent Generation

Agents are created using census information at the DA level.

For each DA:

- Children (0–14 years) are generated using census counts;
- Adults (15–64 years) are generated using census counts;
- Residential locations are randomly assigned from residential parcels located within the DA;
- Adults receive the DA median household income;
- Children receive an income of zero.

Each agent represents 100 real residents

-------------------------------------------------------------------------------------------------------

### Adults

Adults are randomly assigned to one workplace.

### Children

Children are assigned to a school located within their Dissemination Area whenever possible.

If no school exists inside the DA, a random school from Montreal is assigned.

----------------------------------------------------------------------------------

# Accessibility Analysis

For every agent, shortest-path travel times are computed on all transportation networks.

## Automobile

Home → Workplace

## Walking

Home → Workplace

## Public Transit (STM)

The trip is divided into three components:

Home

↓

Nearest STM Station

↓

Destination STM Station

↓

Workplace

Travel time is the sum of all three segments.

## Bicycle (BIXI)

The cycling trip is divided into three components:

Home

↓

Nearest BIXI Station

↓

Destination BIXI Station

↓

Workplace

Travel time is the sum of these three segments.

-------------------------------------------------------------------

# Utility Functions

Transportation mode choice follows a Multinomial Logit (MNL) model.

Utilities are computed for each available transportation mode.

### Automobile

Utility depends on

- travel time
- income
- alternative-specific constant

### Public Transit

Utility depends on

- travel time
- income
- alternative-specific constant

### Bicycle

Utility depends on

- travel time
- bicycle lane length
- BIXI density
- age
- alternative-specific constant

### Walking

Utility depends on

- travel time
- age

All explanatory variables are normalized using Min-Max scaling before utility calculation.

------------------------------------------------------------------------------------------

# Choice Model

Utilities are converted into probabilities using the softmax formulation

```
P(i) = exp(Ui) / Σ exp(Uj)
```

The transportation mode is then selected stochastically according to these probabilities.

----------------------------------------------------------------------------------------

# Calibration

The model parameters are calibrated using Maximum Likelihood Estimation through the L-BFGS-B optimization algorithm.

The calibration procedure iteratively estimates the utility coefficients that minimize the discrepancy between:

- observed census transportation mode shares
- simulated transportation mode shares

The objective function is the weighted Mean Squared Error (MSE) computed at the DA level.

------------------------------------------------------------------------------------------

# Baseline Simulation

After calibration,

The optimized coefficients are loaded, and the model is executed repeatedly.

Each simulation records:
- automobile users
- transit users
- bicycle users
- walking users
-----------------------------------------------------------------------------------------
