# A Spatially Explicit Agent-Based Model of Commuting Mode Choice in the Island of Montréal

## Overview

This repository contains the implementation of a spatially explicit transportation agent-based model (ABM) developed to investigate commuting mode choices across the Island of Montreal, Canada. The model examines how individual socioeconomic characteristics, built-environment conditions, and social interactions shape commuting decisions, and how changes in residential and workplace locations may influence travel behaviour and the overall distribution of transportation modes.

The modeling framework follows a progressive, three-configuration approach. It begins by examining commuting choices based on individual socioeconomic characteristics, then introduces built-environment attributes, and finally incorporates social interactions to explore their additional influence on cycling decisions. This stepwise structure makes it possible to assess how the inclusion of different behavioral and contextual factors affects the model's ability to reproduce observed commuting patterns.

Commuters are represented as heterogeneous agents with distinct demographic and socioeconomic characteristics. Each agent makes a commuting mode choice among four alternatives:

- **Auto**
- **Public transit**
- **Cycling**
- **Walking**

Mode choices are simulated using a multinomial logit (MNL) framework. The utility of each available transportation alternative is calculated using relevant individual, travel-related, and contextual characteristics. The model also incorporates spatially explicit residential and workplace locations, multimodal transportation networks, and population characteristics to represent geographic differences in commuting conditions and transportation accessibility.

In the final configuration, social interactions are introduced through agent-level peer networks constructed using geographic proximity and socioeconomic similarity. Peer behavior influences the utility of cycling, while the utilities of auto, public transit, and walking remain unaffected by the social-interaction term.

Following calibration, the model is used to investigate how residential and workplace relocation can affect commuting decisions. Three relocation scenarios are considered, in which 10%, 20%, and 30% of the agent population experience changes in their residential and workplace locations. These experiments allow us to examine how changes in location may influence individual mode choices and aggregate commuting patterns.

---

## Research Objectives

The model was developed to address the following objectives:

1. **Examine the role of socioeconomic characteristics:** Understand how individual demographic and socioeconomic attributes, together with travel time, contribute to commuting mode choices.
2. **Assess the influence of the built environment:** Investigate how population density, transit-stop density, and proximity to cycling infrastructure influence the attractiveness of different commuting modes.
3. **Explore social influences on cycling:** Evaluate whether the cycling behavior of geographically and socioeconomically similar peers is associated with an agent's own cycling decision.
4. **Represent spatial variations in commuting conditions:** Integrate residential and workplace locations with multimodal transportation networks to account for differences in travel times and transportation accessibility across the study area.
5. **Investigate the implications of residential and workplace relocation:** Assess how changes in agents' locations affect commuting conditions, mode choices, and the overall distribution of transportation modes.

---

## Study Area

The study focuses on the Island of Montreal, Quebec, Canada. The spatial modeling framework represents the study area using Dissemination Areas (DAs), which provide a geographically detailed basis for representing population characteristics and comparing simulated commuting patterns with observed data.

Residential and workplace locations are spatially represented within the study area. These locations are connected through multimodal transportation networks, allowing the model to estimate commuting conditions for auto, public transit, cycling, and walking.

The DA-level spatial structure also provides the basis for examining geographic differences in commuting behavior and evaluating model performance against observed commuting patterns.

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

The utility of each transportation alternative is calculated as a linear combination of its relevant explanatory variables and alternative-specific constants, where applicable.

For an agent \(i\), the utility of alternative \(m\) can be expressed generally as:

\[
U_{im}=V_{im}+\varepsilon_{im}
\]

where:

- \(U_{im}\) is the total utility of transportation alternative \(m\) for agent \(i\).
- \(V_{im}\) is the systematic component of utility.
- \(\varepsilon_{im}\) is the unobserved component of utility.

The probability of choosing an available transportation alternative is calculated using the multinomial logit formulation:

\[
P_{im}=
\frac{\exp(V_{im})}
{\sum_{j\in C_i}\exp(V_{ij})}
\]

where \(C_i\) represents the set of transportation alternatives available to agent \(i\).

The model uses walking as the reference alternative, meaning that no alternative-specific constant is included in the walking utility function.

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

The systematic utility functions are specified as follows.

**Auto:**

\[
\begin{aligned}
V_{auto} =\;& ASC_{auto}
+\beta_1 Time_{auto}
+\beta_2 Age
+\beta_3 Gender\\
&+\beta_4 Education_{HighSchool}
+\beta_5 Education_{BelowBachelor}\\
&+\beta_6 Education_{BachelorAndAbove}
\end{aligned}
\]

**Public transit:**

\[
\begin{aligned}
V_{transit} =\;& ASC_{transit}
+\beta_7 Time_{transit}
+\beta_8 Age
+\beta_9 Gender\\
&+\beta_{10} Education_{HighSchool}
+\beta_{11} Education_{BelowBachelor}\\
&+\beta_{12} Education_{BachelorAndAbove}
\end{aligned}
\]

**Cycling:**

\[
\begin{aligned}
V_{bike} =\;& ASC_{bike}
+\beta_{13} Time_{bike}
+\beta_{14} Age
+\beta_{15} Gender\\
&+\beta_{16} Education_{HighSchool}
+\beta_{17} Education_{BelowBachelor}\\
&+\beta_{18} Education_{BachelorAndAbove}
\end{aligned}
\]

**Walking:**

\[
\begin{aligned}
V_{walk} =\;&
\beta_{19} Time_{walk}
+\beta_{20} Age
+\beta_{21} Gender\\
&+\beta_{22} Education_{HighSchool}
+\beta_{23} Education_{BelowBachelor}\\
&+\beta_{24} Education_{BachelorAndAbove}
\end{aligned}
\]

Here, \(ASC\) represents the alternative-specific constant, and the \(\beta\) coefficients represent the estimated contributions of the explanatory variables to each alternative's systematic utility.

The utilities are calculated only when the corresponding transportation mode is available to the agent.

### Configuration 2: Socioeconomic characteristics and built-environment attributes

The second configuration extends the initial model by incorporating built-environment characteristics alongside travel time and individual socioeconomic variables.

This stage examines whether the surrounding urban environment provides additional explanatory power for commuting decisions beyond individual characteristics alone.

The additional built-environment variables are:

- **Population density:** Represents the population concentration around the agent's residential context.
- **Transit-stop density:** Represents the availability or concentration of public transit stops.
- **Proximity to bicycle lanes:** Represents the agent's proximity to cycling infrastructure.

The built-environment variables are incorporated into the utilities of the relevant transportation alternatives as follows.

**Auto:**

\[
\begin{aligned}
V_{auto} =\;& ASC_{auto}
+\beta_1 Time_{auto}
+\beta_2 Age
+\beta_3 Gender\\
&+\beta_4 Education_{HighSchool}
+\beta_5 Education_{BelowBachelor}\\
&+\beta_6 Education_{BachelorAndAbove}
+\beta_7 PopulationDensity
\end{aligned}
\]

**Public transit:**

\[
\begin{aligned}
V_{transit} =\;& ASC_{transit}
+\beta_8 Time_{transit}
+\beta_9 Age
+\beta_{10} Gender\\
&+\beta_{11} Education_{HighSchool}
+\beta_{12} Education_{BelowBachelor}\\
&+\beta_{13} Education_{BachelorAndAbove}
+\beta_{14} PopulationDensity\\
&+\beta_{15} TransitStopDensity
\end{aligned}
\]

**Cycling:**

\[
\begin{aligned}
V_{bike} =\;& ASC_{bike}
+\beta_{16} Time_{bike}
+\beta_{17} Age
+\beta_{18} Gender\\
&+\beta_{19} Education_{HighSchool}
+\beta_{20} Education_{BelowBachelor}\\
&+\beta_{21} Education_{BachelorAndAbove}
+\beta_{22} PopulationDensity\\
&+\beta_{23} TransitStopDensity
+\beta_{24} ProximityBikeLanes
\end{aligned}
\]

**Walking:**

\[
\begin{aligned}
V_{walk} =\;&
\beta_{25} Time_{walk}
+\beta_{26} Age
+\beta_{27} Gender\\
&+\beta_{28} Education_{HighSchool}
+\beta_{29} Education_{BelowBachelor}\\
&+\beta_{30} Education_{BachelorAndAbove}
+\beta_{31} PopulationDensity
\end{aligned}
\]

This configuration makes it possible to examine how different aspects of the built environment contribute to the attractiveness of commuting alternatives. In particular, population density is included in the utilities of all four modes, transit-stop density is included in the transit and cycling utilities, and proximity to bicycle lanes is included specifically in the cycling utility.

### Configuration 3: Socioeconomic characteristics, built environment, and social interactions

The third configuration builds on the second by incorporating social interactions into the cycling utility function.

The social component is designed to capture the potential influence of peer behavior on an individual's decision to cycle. For this purpose, agents are connected through peer networks established using geographic proximity and socioeconomic similarity.

The model calculates a peer cycling share for each agent, representing the proportion of relevant peers who choose cycling. This measure is then incorporated into the cycling utility through an additional coefficient, \(\gamma_{bike}\).

The utility functions for auto, public transit, and walking remain identical to those in Configuration 2. Social interactions are introduced exclusively into the cycling utility:

**Auto:**

\[
\begin{aligned}
V_{auto} =\;& ASC_{auto}
+\beta_1 Time_{auto}
+\beta_2 Age
+\beta_3 Gender\\
&+\beta_4 Education_{HighSchool}
+\beta_5 Education_{BelowBachelor}\\
&+\beta_6 Education_{BachelorAndAbove}
+\beta_7 PopulationDensity
\end{aligned}
\]

**Public transit:**

\[
\begin{aligned}
V_{transit} =\;& ASC_{transit}
+\beta_8 Time_{transit}
+\beta_9 Age
+\beta_{10} Gender\\
&+\beta_{11} Education_{HighSchool}
+\beta_{12} Education_{BelowBachelor}\\
&+\beta_{13} Education_{BachelorAndAbove}
+\beta_{14} PopulationDensity\\
&+\beta_{15} TransitStopDensity
\end{aligned}
\]

**Cycling:**

\[
\begin{aligned}
V_{bike} =\;& ASC_{bike}
+\beta_{16} Time_{bike}
+\beta_{17} Age
+\beta_{18} Gender\\
&+\beta_{19} Education_{HighSchool}
+\beta_{20} Education_{BelowBachelor}\\
&+\beta_{21} Education_{BachelorAndAbove}
+\beta_{22} PopulationDensity\\
&+\beta_{23} TransitStopDensity
+\beta_{24} ProximityBikeLanes\\
&+\gamma_{bike} PeerBikeShare
\end{aligned}
\]

**Walking:**

\[
\begin{aligned}
V_{walk} =\;&
\beta_{25} Time_{walk}
+\beta_{26} Age
+\beta_{27} Gender\\
&+\beta_{28} Education_{HighSchool}
+\beta_{29} Education_{BelowBachelor}\\
&+\beta_{30} Education_{BachelorAndAbove}
+\beta_{31} PopulationDensity
\end{aligned}
\]

The coefficient \(\gamma_{bike}\) captures the contribution of peer cycling behavior to the systematic utility of cycling. A positive value indicates that a higher cycling share among an agent's peers increases the modeled attractiveness of cycling, whereas a negative value indicates the opposite relationship.

Importantly, the peer-behavior variable is included only in the cycling utility. It does not directly modify the utilities of auto, public transit, or walking.

---

## Social Interaction and Peer-Network Construction

Social interactions are represented through agent-level peer networks. Rather than assuming that all commuters influence one another, the model identifies relevant peers using geographic proximity and socioeconomic similarity.

For each agent, the model identifies a set of peers and calculates the proportion of those peers who currently choose cycling.

The peer cycling share can be expressed as:

\[
PeerBikeShare_i =
\frac{\sum_{j\in N_i} I(Mode_j=Bike)}
{|N_i|}
\]

where:

- \(N_i\) is the set of peers associated with agent \(i\).
- \(I(Mode_j=Bike)\) equals 1 if peer \(j\) chooses cycling and 0 otherwise.
- \(|N_i|\) is the total number of peers in the network.

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

---

## Repository Structure

The following is a suggested organization for the repository. The actual directory names should be adjusted to match the implementation.

```text
transportation-abm-montreal/
│
├── README.md
│
├── data/
│   ├── README.md
│   └── [spatial and demographic input data]
│
├── notebooks/
│   ├── [exploratory data analysis]
│   ├── [model calibration]
│   └── [simulation results]
│
├── src/
│   ├── [agent implementation]
│   ├── [transportation model]
│   ├── [utility functions]
│   ├── [network and travel-time calculations]
│   ├── [social interaction functions]
│   └── [relocation scenarios]
│
├── calibration/
│   ├── [socioeconomic configuration]
│   ├── [built-environment configuration]
│   └── [social-interaction configuration]
│
├── results/
│   ├── [calibration results]
│   ├── [baseline simulation]
│   └── [relocation scenarios]
│
└── requirements.txt
```

---

## Software and Libraries

The model is implemented in Python and uses geospatial, network-analysis, agent-based modeling, and optimization libraries.

The main technologies used in the modeling workflow include:

- **Python:** Main programming language.
- **Mesa:** Agent-based modeling framework.
- **GeoPandas:** Spatial data processing and analysis.
- **OSMnx:** Retrieval and analysis of transportation-network data.
- **NetworkX:** Network representation and analysis.
- **NumPy:** Numerical calculations and array operations.
- **Pandas:** Data management and analysis.
- **Optuna:** Hyperparameter optimization and model calibration.
- **Matplotlib:** Visualization of model outputs and simulation results.

The exact package versions and installation instructions should be provided in the repository's `requirements.txt` file to support reproducibility.

### Installation

Clone the repository:

```bash
git clone https://github.com/YOUR-USERNAME/transportation-abm-montreal.git
```

Move into the project directory:

```bash
cd transportation-abm-montreal
```

Create and activate a Python virtual environment:

```bash
python -m venv .venv
```

On Windows:

```bash
.venv\Scripts\activate
```

On macOS or Linux:

```bash
source .venv/bin/activate
```

Install the required packages:

```bash
pip install -r requirements.txt
```

---

## Running the Model

The general modeling workflow consists of the following stages:

**Step 1 – Prepare the input data**

Load and prepare the demographic, socioeconomic, built-environment, residential, workplace, and transportation-network data required by the model.

**Step 2 – Initialize the agents and spatial environment**

Initialize the model, create the commuter agents, assign their characteristics and locations, and connect them to the relevant transportation networks.

**Step 3 – Calculate travel times and mode availability**

Estimate the travel times associated with each commuting alternative and determine which alternatives are available to each agent.

**Step 4 – Calibrate the three configurations**

Run the calibration procedure separately for the socioeconomic, built-environment, and social-interaction configurations.

**Step 5 – Run the baseline simulation**

Use the calibrated model to establish the baseline distribution of commuting mode choices.

**Step 6 – Run the relocation experiments**

Execute the three relocation scenarios, affecting 10%, 20%, and 30% of the agent population, respectively.

**Step 7 – Analyze and compare the results**

Compare the relocation scenarios with the baseline in terms of commuting-mode shares, individual mode transitions, and the responses of relocated and non-relocated agents.

The exact execution commands depend on the entry-point scripts and configuration files included in the repository.

---

## Reproducibility

Reproducibility is an important consideration when conducting agent-based simulation experiments.

The model uses random processes during agent initialization, mode-choice simulation, and relocation. Random seeds should therefore be specified and documented to support reproducible experiments.

For comparisons between the baseline and relocation scenarios, independent model instances should be initialized using consistent initial conditions wherever appropriate. This helps ensure that differences between scenarios are associated with the modeled relocation changes rather than unintended differences in initialization.

Where stochastic mode choices are involved, repeated simulation runs can also be used to assess the stability of the results.

The repository should document the random seeds, calibration settings, model parameters, and relevant software versions used to produce the reported results.

---

## Limitations and Considerations

The model provides a spatially explicit behavioral framework for investigating commuting mode choices, but several considerations are important when interpreting its results.

- **Behavioral representation:** Mode choices are represented using an MNL framework. As a result, the model's behavioral assumptions and estimated utility functions influence the simulated decisions.
- **Social interactions:** Social influence is represented through peer cycling shares and is introduced only in the cycling utility. The framework does not directly incorporate social effects into auto, public transit, or walking utilities.
- **Spatial representation:** Commuting conditions depend on the quality and spatial resolution of the input data, including transportation networks, demographic information, and built-environment attributes.
- **Relocation scenarios:** The three relocation levels represent predefined experimental scenarios. They should be interpreted as model-based simulations rather than forecasts of actual future residential or workplace movements.
- **Calibration:** Agreement with observed commuting patterns does not necessarily mean that every individual agent's behavior is reproduced correctly. Both aggregate mode shares and spatial patterns are important when evaluating model performance.

---

## Intended Applications

The framework can support research into the relationship between urban form, transportation accessibility, social interactions, and commuting behavior.

Potential applications include:

- Evaluating the behavioral implications of residential and workplace relocation.
- Examining how changes in urban density and transportation infrastructure may influence commuting mode choices.
- Investigating the potential role of peer behavior in cycling decisions.
- Exploring spatial differences in commuting accessibility across urban neighborhoods.
- Comparing commuting patterns under alternative urban and transportation conditions.

---

## Citation

If you use this model or build upon its methodology, please cite the associated research publication when it becomes available.

**Publication details:** To be added.

---

## Data Availability

Input datasets used by the model may be subject to licensing, privacy, or access restrictions. Data files are therefore not necessarily distributed with the source code.

Where possible, the repository should provide descriptions of the required datasets, their original sources, spatial and temporal coverage, and instructions for obtaining or preparing them.

---

## Acknowledgements

This research was conducted as part of work on spatially explicit agent-based modeling, transportation behavior, and urban mobility in the Island of Montréal, Canada.

The model brings together geospatial analysis, transportation-network modeling, discrete-choice theory, and complex systems approaches to investigate the factors shaping commuting decisions.
