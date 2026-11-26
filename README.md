# A Spatially Explicit Agent-Based Model of Commuting Mode Choice in the Island of Montréal

## Overview

This repository contains the implementation of a spatially explicit transportation agent-based model (ABM) developed to investigate commuting mode choices across the Island of Montreal, Canada. The model examines how individual socioeconomic characteristics, built-environment conditions, and social interactions shape commuting decisions, as well as how changes in residential and workplace locations may influence travel behavior and the overall distribution of transportation modes.

The modeling framework follows a progressive, three-configuration approach. It begins by examining commuting choices based on individual socioeconomic characteristics, then incorporates built-environment attributes, and finally introduces social interactions to explore their additional influence on cycling decisions. This stepwise structure makes it possible to assess how the inclusion of different behavioral and contextual factors affects the model's ability to reproduce observed commuting patterns.

Commuters are represented as heterogeneous agents with distinct demographic and socioeconomic characteristics. Each agent makes a commuting mode choice among four alternatives, namely, auto, public transit, bike, and walking. Mode choices are simulated using a multinomial logit (MNL) framework. The utility of each available transportation alternative is calculated using relevant individual, travel-related, and contextual characteristics. The model also incorporates spatially explicit residential and workplace locations, multimodal transportation networks, and population characteristics to represent geographic differences in commuting conditions and transportation accessibility. In the final configuration, social interactions are introduced through agent-level peer networks constructed using geographic proximity and socioeconomic similarity. Peer behavior influences the utility of cycling, while the utilities of auto, public transit, and walking remain unaffected by the social-interaction term.

Following calibration, the model is used to investigate how residential and workplace relocation can affect commuting decisions. Three relocation scenarios are considered, in which 10%, 20%, and 30% of the agent population experience changes in their residential and workplace locations. These experiments allow us to examine how changes in location, travel times, accessibility, and social interactions may influence individual mode choices and aggregate commuting patterns.

Partially based on the following paper:

>[Aziz, H. A., Park, B. H., Morton, A., Stewart, R. N., Hilliard, M., & Maness, M. (2018). A high resolution agent-based model to support walk-bicycle infrastructure investment decisions: A case study with New York City. Transportation research part C: emerging technologies, 86, 280-299.](https://doi.org/10.1016/j.trc.2017.11.008)



---

## Research Objectives

The model was developed to address the following objectives:

1. **Examine the role of socioeconomic characteristics:** Understand how individual demographic and socioeconomic attributes, together with travel time, contribute to commuting mode choices.
2. **Assess the influence of the built environment:** Investigate how population density, transit-stop density, and proximity to cycling infrastructure influence the attractiveness of different commuting modes.
3. **Explore social influences on cycling:** Evaluate whether the cycling behavior of geographically and socioeconomically similar peers is associated with an agent's own cycling decision.
4. **Investigate the implications of residential and workplace relocation:** Assess how changes in agents' locations affect commuting conditions, individual mode choices, and the overall distribution of transportation modes.

---

## Study Area

The study focuses on the Island of Montreal, Quebec, Canada. The spatial modeling framework represents the study area using Dissemination Areas (DAs), which provide a geographically detailed basis for representing population characteristics and comparing simulated commuting patterns with observed data.

---

## Modeling Framework

### Agent representation

Each commuter is represented as an individual agent with a distinct set of demographic and socioeconomic characteristics. Agents are assigned residential and workplace locations and are associated with the relevant spatial and transportation-network information.

The main components of an agent include:

- Residential location.
- Workplace location.
- Age.
- Gender.
- Educational attainment.
- Travel time by transportation mode.
- Availability of the four commuting alternatives.
- Relevant built-environment attributes associated with the residential context.
- Peer-network information in the social-interaction configuration.

Agents make their commuting decisions through an MNL choice framework. The available alternatives are determined by the corresponding mode-availability conditions, and unavailable alternatives are excluded from the choice process.

### Multinomial logit mode-choice framework

The utility of each transportation alternative is calculated as a function of its relevant explanatory variables and, where applicable, an alternative-specific constant.

The MNL framework converts the systematic utility values of available alternatives into choice probabilities. The probability of choosing a particular mode increases as its utility becomes more attractive relative to the other available alternatives.

The model uses walking as the reference alternative, meaning that no alternative-specific constant is included in the walking utility function.

The utility functions for each model configuration are presented below in the same Python-style structure used in the model implementation.

---

## Three Model Configurations

The model is developed and calibrated through three progressively expanded configurations. Each configuration retains the explanatory variables from the preceding stage while introducing additional factors.

### Configuration 1: Socioeconomic characteristics

The first configuration examines commuting mode choices using travel time and individual socioeconomic characteristics. It provides the initial behavioral representation of commuting decisions before introducing additional built-environment and social-interaction effects.

The explanatory variables include:

- Travel time for auto, public transit, cycling, and walking.
- Age.
- Gender.
- Educational attainment, represented by three education variables:
  - High school.
  - Below bachelor's degree.
  - Bachelor's degree and above.

The utility functions for the four transportation alternatives are implemented as follows.

**Auto utility**

```python
if self.auto_available == True:
    self.U_auto = (
        ASC_auto
        + β1 * self.time_auto_st
        + β2 * self.age_st
        + β3 * self.gender
        + β4 * self.Education_HighSchool
        + β5 * self.Education_BelowBachelor
        + β6 * self.Education_Bachelor_and_above
    )
else:
    self.U_auto = -np.inf
```

**Public transit utility**

```python
if self.transit_available == True:
    self.U_transit = (
        ASC_transit
        + β7 * self.time_transit_st
        + β8 * self.age_st
        + β9 * self.gender
        + β10 * self.Education_HighSchool
        + β11 * self.Education_BelowBachelor
        + β12 * self.Education_Bachelor_and_above
    )
else:
    self.U_transit = -np.inf
```

**Cycling utility**

```python
if self.bike_available == True:
    self.U_bike = (
        ASC_bike
        + β13 * self.time_bike_st
        + β14 * self.age_st
        + β15 * self.gender
        + β16 * self.Education_HighSchool
        + β17 * self.Education_BelowBachelor
        + β18 * self.Education_Bachelor_and_above
    )
else:
    self.U_bike = -np.inf
```

**Walking utility** - _Reference mode_

```python
if self.walk_available == True:
    self.U_walk = (
        β19 * self.time_walk_st
     )
else:
    self.U_walk = -np.inf
```

In this configuration, travel time and socioeconomic characteristics are used to explain differences in the attractiveness of the four commuting alternatives. Alternative-specific constants are included for auto, public transit, and cycling, while walking serves as the reference alternative.

### Configuration 2: Socioeconomic characteristics and built-environment attributes

The second configuration extends the initial model by incorporating built-environment characteristics alongside travel time and individual socioeconomic variables.

This stage examines whether the surrounding urban environment provides additional explanatory power for commuting decisions beyond individual characteristics alone.

The additional built-environment variables are:

- **Population density:** Represents the population concentration around the agent's residential context.
- **Transit-stop density:** Represents the availability or concentration of public transit stops.
- **Proximity to bicycle lanes:** Represents the agent's proximity to cycling infrastructure.

The built-environment variables are incorporated into the utilities of the relevant transportation alternatives as follows.

**Auto utility**

```python
if self.auto_available == True:
    self.U_auto = (
        ASC_auto
        + β1 * self.time_auto_st
        + β2 * self.age_st
        + β3 * self.gender
        + β4 * self.Education_HighSchool
        + β5 * self.Education_BelowBachelor
        + β6 * self.Education_Bachelor_and_above
        + β7 * self.population_density_st
    )
else:
    self.U_auto = -np.inf
```

**Public transit utility**

```python
if self.transit_available == True:
    self.U_transit = (
        ASC_transit
        + β8 * self.time_transit_st
        + β9 * self.age_st
        + β10 * self.gender
        + β11 * self.Education_HighSchool
        + β12 * self.Education_BelowBachelor
        + β13 * self.Education_Bachelor_and_above
        + β14 * self.population_density_st
        + β15 * self.transit_stop_density_st
    )
else:
    self.U_transit = -np.inf
```

**Cycling utility**

```python
if self.bike_available == True:
    self.U_bike = (
        ASC_bike
        + β16 * self.time_bike_st
        + β17 * self.age_st
        + β18 * self.gender
        + β19 * self.Education_HighSchool
        + β20 * self.Education_BelowBachelor
        + β21 * self.Education_Bachelor_and_above
        + β22 * self.population_density_st
        + β23 * self.transit_stop_density_st
        + β24 * self.prx_bikelanes
    )
else:
    self.U_bike = -np.inf
```

**Walking utility** - _Reference mode_

```python
if self.walk_available == True:
    self.U_walk = (
        β25 * self.time_walk_st
    )
else:
    self.U_walk = -np.inf
```

This configuration makes it possible to examine how different aspects of the built environment contribute to the attractiveness of commuting alternatives. Population density is included in the utilities of all four modes, transit-stop density is included in the transit and cycling utilities, and proximity to bicycle lanes is included specifically in the cycling utility.

### Configuration 3: Socioeconomic characteristics, built environment, and social interactions

The third configuration builds on the second by incorporating social interactions into the cycling utility.

The social component is designed to capture the potential influence of peer behavior on an individual's decision to cycle. For this purpose, agents are connected through peer networks established using geographic proximity and socioeconomic similarity.

The model calculates a peer cycling share for each agent, representing the proportion of relevant peers who choose cycling. This measure is then incorporated into the cycling utility through an additional coefficient, `γ_bike`.

The utilities for auto, public transit, and walking remain identical to those in Configuration 2. Social interactions are introduced exclusively into the cycling utility.

**Auto utility**

```python
if self.auto_available == True:
    self.U_auto = (
        ASC_auto
        + β1 * self.time_auto_st
        + β2 * self.age_st
        + β3 * self.gender
        + β4 * self.Education_HighSchool
        + β5 * self.Education_BelowBachelor
        + β6 * self.Education_Bachelor_and_above
        + β7 * self.population_density_st
    )
else:
    self.U_auto = -np.inf
```

**Public transit utility**

```python
if self.transit_available == True:
    self.U_transit = (
        ASC_transit
        + β8 * self.time_transit_st
        + β9 * self.age_st
        + β10 * self.gender
        + β11 * self.Education_HighSchool
        + β12 * self.Education_BelowBachelor
        + β13 * self.Education_Bachelor_and_above
        + β14 * self.population_density_st
        + β15 * self.transit_stop_density_st
    )
else:
    self.U_transit = -np.inf
```

**Cycling utility**

```python
if self.bike_available == True:
    self.U_bike = (
        ASC_bike
        + β16 * self.time_bike_st
        + β17 * self.age_st
        + β18 * self.gender
        + β19 * self.Education_HighSchool
        + β20 * self.Education_BelowBachelor
        + β21 * self.Education_Bachelor_and_above
        + β22 * self.population_density_st
        + β23 * self.transit_stop_density_st
        + β24 * self.prx_bikelanes
        + γ_bike * self.peer_bike_share
    )
else:
    self.U_bike = -np.inf
```

**Walking utility** - _Reference mode_

```python
if self.walk_available == True:
    self.U_walk = (
        β25 * self.time_walk_st
    )
else:
    self.U_walk = -np.inf
```

The coefficient `γ_bike` captures the contribution of peer cycling behavior to the systematic utility of cycling. A positive value indicates that a higher cycling share among an agent's peers increases the modeled attractiveness of cycling, whereas a negative value indicates the opposite relationship.

Importantly, the peer-behavior variable is included only in the cycling utility. It does not directly modify the utilities of auto, public transit, or walking.

---

## Social Interaction and Peer-Network Construction

Social interactions are represented through agent-level peer networks. Rather than assuming that all commuters influence one another, the model identifies relevant peers using geographic proximity and socioeconomic similarity.

For each agent, the model identifies a set of peers and calculates the proportion of those peers who currently choose cycling.

The peer cycling share is calculated as the number of cycling peers divided by the total number of identified peers:

```python
if not agent.peer_indices:
    agent.peer_bike_share = 0.0
else:
    bike_count = sum(
        agents[j].mode_choice == "bike"
        for j in agent.peer_indices
    )

    agent.peer_bike_share = bike_count / len(agent.peer_indices)
```

The resulting peer cycling share is incorporated into the cycling utility in Configuration 3.

If an agent has no identified peers, the peer cycling share is assigned a value of zero. This ensures that the cycling utility can still be calculated without requiring every agent to have an established peer network.

This approach allows the model to examine how cycling behavior within geographically and socioeconomically similar groups may contribute to individual commuting decisions.

---

## Spatial Representation and Transportation Networks

The model incorporates spatially explicit residential and workplace locations to represent the geographic context of commuting decisions.

The spatial framework combines population characteristics, agent locations, and multimodal transportation networks. These components are used to estimate travel times and represent differences in accessibility across the Island of Montréal.

The transportation alternatives considered in the model are:

- **Auto:** Travel conditions are represented through the relevant road-network information.
- **Public transit:** Travel time accounts for walking access to transit, the transit journey, and walking from the transit stop to the destination.
- **Cycling:** Travel conditions are represented through the cycling network and associated travel-time information.
- **Walking:** Travel time is estimated using the pedestrian network.

The model also incorporates contextual information such as population density, transit-stop density, and proximity to bicycle lanes. These variables provide additional information about the built environment surrounding agents' residential locations.

By linking agents to spatially explicit locations and transportation networks, the framework can account for differences in commuting conditions rather than treating all agents as if they experienced the same transportation environment.

---

## Model Calibration

The model is calibrated against observed commuting mode shares at the Dissemination Area (DA) level.

Calibration is conducted separately for the three model configurations:

1. **Socioeconomic configuration:** Travel time and individual socioeconomic characteristics.
2. **Built-environment configuration:** Travel time, socioeconomic characteristics, and built-environment attributes.
3. **Social-interaction configuration:** All variables included in the built-environment configuration, with the additional peer cycling share variable in the cycling utility.

This progressive calibration strategy provides a consistent basis for comparing the three configurations. By introducing additional explanatory variables at each stage, the model can be evaluated in terms of how its ability to reproduce observed commuting patterns changes as behavioral and contextual complexity increases.

The calibration process estimates the utility coefficients and alternative-specific constants for the relevant configurations. The resulting parameter sets are used to simulate commuting choices and compare predicted mode distributions with observed commuting patterns.

Model performance is assessed by examining the agreement between simulated and observed mode shares at the DA level. This allows the analysis to consider both the overall distribution of commuting modes and their spatial variation across the study area.

---

## Residential and Workplace Relocation Experiments

Following calibration, simulation experiments are conducted to investigate how changes in residential and workplace locations influence commuting behavior.

Three relocation scenarios are considered:

| Scenario | Share of agents affected |
|---|---:|
| Scenario 1 | 10% |
| Scenario 2 | 20% |
| Scenario 3 | 30% |

In each scenario, the selected proportion of agents experiences changes to their residential and workplace locations. These changes modify the spatial context in which commuting decisions are made.

Following relocation, the model updates the relevant spatial and transportation-related information, including:

- Agents' residential and workplace locations.
- Connections to the transportation networks.
- Travel times for the available commuting modes.
- Relevant local population-density information.
- Transit-stop-density information.
- Peer-network and peer-cycling information, where applicable.

The updated conditions are then used to reassess agents' commuting mode choices.

The relocation experiments are designed to examine several related questions:

- How does residential and workplace relocation change commuting travel times?
- How do changes in travel conditions influence individual mode choices?
- Do changes in residential contexts affect access to cycling infrastructure and public transit?
- How do changes in agents' locations influence their peer networks and exposure to cycling behavior?
- How does the proportion of relocated agents affect the overall distribution of commuting modes?

By comparing the three relocation scenarios with the baseline simulation, the model provides a way to investigate how the scale of residential and workplace relocation may influence commuting patterns across the study area.

---

## Baseline and Scenario Comparisons

The baseline simulation provides the reference against which the relocation experiments are evaluated.

The 10%, 20%, and 30% relocation scenarios are run as separate experiments so that the consequences of each relocation level can be examined independently.

The comparison focuses on:

- Final commuting-mode counts.
- Final commuting-mode shares.
- Changes in individual commuting choices.
- Transitions between transportation alternatives.
- Differences between relocated and non-relocated agents.
- Changes in the overall distribution of commuting modes.

Transition matrices can be used to identify movements between alternatives. For example, they can show how many agents switch from auto to public transit, cycling, or walking after relocation.

Separating relocated and non-relocated agents also makes it possible to examine whether changes in commuting behavior are concentrated among agents whose locations change or whether the resulting spatial and social effects extend to other agents.


This research was conducted as part of work on spatially explicit agent-based modeling, transportation behavior, and urban mobility in the Island of Montréal, Canada.

The model brings together geospatial analysis, transportation-network modeling, discrete-choice theory, and complex systems approaches to investigate the factors shaping commuting decisions.
