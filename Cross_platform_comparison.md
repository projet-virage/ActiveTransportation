# Cross platform implementation comparison

In order to compare the three ABM platforms (NetLogo, mesa and repast4py), we want to assert that the three scripts implement the same model. 

- The mesa model has been developed by Navid in Collab, it's a pure ABM approach with the calibration being done within the same ABM than the simlation steps. The most complete model (`SocialInteractionGraph_MostEfficientVersion.ipynb`) comprises socio-demo / environmental / social variables.
- The NetLogo model (`NetLogo\TransportModeChoice.nlogox`) has been developed by Claude, based on Navid's reference model `SocialInteractionGraph_MostEfficientVersion.ipynb`
- The repast4py model is stored in a separate repo and replicates the same approahc as `SocialInteractionGraph_MostEfficientVersion.ipynb`. Yet, some differences are expected with the reference model and need to be assessed.

## Mesa vs. repast4py

*Review date: 2026-11-12. Files reviewed:*

| Platform | Main code | Data preparation / calibration |
|---|---|---|
| Mesa | [SocialInteractionGraph_MostEfficientVersion.ipynb](SocialInteractionGraph_MostEfficientVersion.ipynb) (commit `9713e0d`) | Inside the same notebook (population, routing, social network, Optuna calibration) |
| repast4py | `\\wsl.localhost\Ubuntu\home\benoit\abm_ta\abm_ta_soc.py` (branch `wsl_main`) | [GeneratePop.ipynb](../VIRAGE_proto_ActiveTransportation_repast/GeneratePop.ipynb) (population, workplaces, linkage) and [ComputeUtilityFunctions.ipynb](../VIRAGE_proto_ActiveTransportation_repast/ComputeUtilityFunctions.ipynb) (routing, environmental variables, social network, PyTorch calibration), branch `main` (`fd9eb73`) |

*`GeneratePopRepast.ipynb` (July 2026) is an older version of `GeneratePop.ipynb` and was not used. The shared specification is in [Common_playground.md](../VIRAGE_proto_ActiveTransportation_repast/Common_playground.md).*

### Summary

The two models share the overall design (census-based agents at the DA level, 4 OSMnx networks with the same `trv_time` weight, nearest protected bike lane, 1 km local density, a static Gower-based social network, MNL with a bike-only peer effect). **They differ, however, in almost every step that produces the results**: how the population and workplaces are generated, how transit time is computed, the utility specification and how it is standardized, the calibration method, the choice rule (argmax vs. random draw), and the simulation scenario. As they stand, differences in outputs between the two platforms cannot be attributed to the platform itself.

The differences most likely to change the results, in order:

1. **Choice rule**: Mesa uses a deterministic argmax of the utilities. repast draws a mode at random from the MNL probabilities. Under argmax, minority modes are underpredicted: Mesa bike share is 0.3% simulated vs. 1.3% observed.
2. **Utility specification and standardization**: 33 vs. 21 parameters. Mesa adds age × time and income × time interactions and standardizes the 4 travel times with one pooled mean/std; repast standardizes each mode's time separately.
3. **Calibration**: Mesa runs Optuna (30 trials) on simulated argmax choices with a 20/80 local/global MSE. repast fits expected probabilities by gradient descent on a zone-level multinomial NLL.
4. **Scenario**: Mesa relocates 30% of agents (home and job) once, then runs 5 steps. repast moves 1.16% of agents' homes and changes 1.5% of jobs at every tick, over 50 ticks.
5. **Population inputs**: different census variables, residential layers, workplace sources and commute-distance rules.

### Side-by-side comparison

#### Software architecture

| | Mesa | repast4py |
|---|---|---|
| Execution | Single process, notebook | MPI (`mpirun -n N`); agents spread across ranks with ghost synchronization |
| Agents | `PersonAgent(mesa.Agent)` in a Python list; Mesa scheduler not used (`Schedule` imported, unused) | `Commuter(core.Agent)` in a `SharedContext`, social network loaded as a `SharedDirectedNetwork` projection (`network.read_network`) |
| Pipeline | Everything in one model object: population, routing, social network, calibration, scenario | Preparation and calibration done offline in 2 notebooks; the ABM only loads files (`agents*.shp`, `workplaces_*.shp`, `agent2workplace*_soc.csv`, `socnet*.csv`, `UCsoc_mode_choice_model*.pt`) |
| Scheduling | Manual loop: `model_step()` called 5 times | `schedule_repeating_event(1, 1, step)`, stops at `stop_at` (50) |
| Outputs | Counts and transition matrix before/after relocation | Mode counts per tick (`ReducingDataSet`, summed across ranks) + agent logs every 10 ticks |
| Random seeds | `random` and `np.random` seeded with 42 | `repast4py.random.init(123)`, **but** `sample_agent_modes` uses `np.random.default_rng()` with no seed, so mode draws cannot be reproduced |

#### Synthetic population

| | Mesa | repast4py |
|---|---|---|
| Study area | `DA_MTL_MTM.shp` (Montréal island DAs) | `AOI_DA_data.shp` filtered on CD = Montréal |
| Scaling | 1 agent = 50 persons (`n_rep=50`): **12,340 agents** | 1 agent = 100 persons (`factor=100`): **13,438 agents** |
| Number of agents per DA | Commuters by mode: Σ round(Car, Transit, Bike, Walk / n_rep). "Other" modes excluded | 15–64 population: round((M15–64 + F15–64) / factor) |
| Gender | Male count = round(male share × n), from `Gender.csv`; 1 = male | Drawn with the DA's joint age × sex distribution (5-year groups); 1 = male (the ABM docstring says the reverse, which is wrong) |
| Age | Uniform 15–64, independent of the DA | Drawn from the DA's 5-year age groups (15–64), plus uniform jitter of 0–4 |
| Income | 13 classes from `Census_data.csv` (incl. "without income"; apparently individual total income); value in $ drawn from a truncated normal inside the class | 19 classes of **household** income; value = class lower bound in k$ (0, 5, 10 … 200), no spread within the class |
| Home location | Random residential polygon intersecting the DA (`Residential_MTM.shp`); location = polygon centroid (can fall outside the DA) | Random point inside residential land (CMM 2020) ∩ DA |
| Workplace source | `workplaces.shp` (one point per workplace; origin not documented in the notebook) | REQ businesses geocoded by postal code (DMTI), one point per job (~1.6M) |
| Linking agents to workplaces | Commute class from DA shares: <30 min → 4 km, 30–45 → 8 km, 45–60 → 13 km, >60 → 18 km (the <15 and 15–30 groups are merged). Workplace drawn uniformly **within a disc** of that radius around home. **Not exclusive** (several agents can share a workplace) | 5 classes: <15 → 0–4 km, 15–30 → 4–8, 30–45 → 8–13, 45–60 → 13–18, >60 → >18 km. Workplace drawn **within a ring** measured from the DA polygon, without replacement (**exclusive**); falls back to the nearest ring if the ring is full |

The radius mapping is shifted between the two models: a "15–30 min" commuter gets 0–4 km in Mesa and 4–8 km in repast. Mesa's disc also allows any distance from 0 up to the radius, so Mesa commutes are shorter on average.

#### Network and travel times

| | Mesa | repast4py |
|---|---|---|
| Networks | `Nodes.shp` + `Edges_{car,walk,bike,transit}.shp` | `nodes.shp` + `edges_{car,walk,bike,transit_walk}.shp` |
| Snapping to the network | Nearest node of the **walk** network, reused for all modes | Nearest node among `snap_nodes.shp` (nodes meant to be reachable by every mode) |
| Car / walk / bike | Shortest `trv_time` path home → work | Same |
| Transit | **3 legs**: walk home → station nearest the home node (Euclidean KDTree), then station → station on the transit network, then walk station → work | **One** shortest path on the combined transit + walk network (best station pair and possible all-walk trips are found implicitly) |
| No path found | Mode unavailable (U = −∞) | Calibration: NaN replaced by 3 × 99th percentile. ABM, after a move: mean + 3σ. ABM, initial values: NaN left as is (see "Issues found") |

#### Environmental variables

| | Mesa | repast4py |
|---|---|---|
| Local population density | Agents within 1 km × n_rep / π km² (per km², ego included); recomputed for **all** agents after relocation | Same rule in pers./ha; recomputed **only for agents who moved**, not for their old and new neighbours |
| Distance to bike lane | Nearest feature of `VQ_bikelanes.shp` from the home centroid | Same layer (`sjoin_nearest`); recomputed after a move |

#### Social network

| | Mesa | repast4py |
|---|---|---|
| Candidates | Agents within 1 km of ego's home **(home–home)** or within 1 km of ego's work **(work–work)** | Any pair with one location of each agent within 1 km: home–home, work–work **and home–work** |
| Similarity | Gower distance (age, income, gender), `gower` package | Gower distance with the same formula, computed manually on candidate pairs only |
| Tie selection | N ~ U{5..10}; pool = the 2N most similar candidates; **N drawn at random from the pool** | N ~ U{5..10}; **the N most similar** candidates (no random draw) |
| Size | 1 agent of 12,340 has no peers | 3 to 10 ties per agent (mean 7.4) when fewer than N candidates exist |
| Dynamics | Static, directed | Static, directed (repast network projection) |

Both models use a 1 km radius. [Common_playground.md](../VIRAGE_proto_ActiveTransportation_repast/Common_playground.md) still says 5 km.

#### Utility function

| | Mesa | repast4py |
|---|---|---|
| Reference mode | Walk (ASC_walk = 0) | Walk (ASC and all individual-specific coefficients = 0) |
| Terms per mode | time, age, gender, income, pop. density, **age × time**, **income × time**. Walk also has its own age, gender, income and density coefficients | time (own mode only); gender, age, income and density relative to walk |
| Bike only | distance to bike lane, γ × peer bike share | distance to bike lane, β × peer bike share |
| Number of parameters | 33 | 21 |
| Standardization | z-scores over all agents. **The 4 times share one pooled mean/std**, so differences in time between modes enter the utility. Gender (0/1) and peer share are **not** standardized | z-scores using the training zones' statistics, **separately for each mode's time**, so only within-mode deviations matter and the differences between modes go into the ASCs. Gender and peer share **are** standardized |
| Statistics after relocation | Recomputed (`prepare_static_calibration_data`), so **every** agent's standardized values change | Fixed (stored in the `.pt` file) |

In Mesa, all four utilities, including walk (the reference), have their own age, gender, income and density coefficients. In an MNL only differences between modes are identified, so these coefficients cannot be identified or interpreted individually.

#### Calibration

| | Mesa | repast4py |
|---|---|---|
| Where | Inside the ABM, on the full simulation | Offline, PyTorch, on a vectorized MNL (no ABM) |
| Optimizer | Optuna TPE, **30 trials**, bounded search with sign priors (e.g. time < 0, γ > 0) | Adam, 2,000 steps, StepLR, L2 penalty on demographic and time coefficients |
| Quantity fitted | Counts of **simulated argmax choices** after 5 steps (step 1 without peers, steps 2–5 with) | **Expected probabilities** summed per DA |
| Loss | 0.2 × population-weighted mean of per-DA share MSE + 0.8 × global share MSE | Zone-level multinomial NLL weighted by census counts (MAE only used for diagnostics, unlike what Common_playground.md says) |
| Targets | round(census count / n_rep) per mode and DA | Census commuter counts per mode and DA |
| Validation | None (fit on all DAs) | 80/20 split by DA; checkpoint with the best validation loss is kept |
| Peer share used | Produced by the model itself during the 5 steps | One random draw of modes from the **environmental** model, applied to the social network, then held fixed |
| Global fit reported | Shares (car, transit, bike, walk): 0.656 / 0.288 / 0.003 / 0.053 vs. observed 0.639 / 0.282 / 0.013 / 0.066 | Reported in the notebook as validation MAE per mode (not reproduced here) |

The [README](README.md) in this repo still says L-BFGS-B / maximum likelihood. The code uses Optuna.

#### Choice rule and update scheme

| | Mesa | repast4py |
|---|---|---|
| Choice | **`argmax(probabilities)`**, so deterministic (the README says "stochastically") | Random categorical draw from the MNL probabilities, every tick |
| Initial modes | None: step 1 computes all utilities with peer share = 0 | Modes saved by the calibration notebook (one draw from the social model) |
| Peer share update | **Synchronous**: every agent chooses, then all peer shares are updated | **Sequential**: each agent recomputes its ratio from its neighbours' current modes just before choosing. Neighbours that already acted this tick give their new mode; ghosts on other ranks give the mode from the last synchronization |
| Utilities recomputed | Step 1: all 4. Later steps: bike only (the others do not change) | All 4 every tick |

#### Simulation scenario

| | Mesa | repast4py |
|---|---|---|
| Time | 5 steps before + 5 steps after one relocation event | 50 ticks |
| Home moves | One event: 30% of agents get a new residential polygon drawn **uniformly over all of Montréal** | Each tick: 1.16% of agents; DA drawn ∝ DA population (multinomial), random point in its residential area |
| Job changes | The same 30% get a new workplace within their original commute radius of the **new** home | Each tick: 1.5% of agents (independent of movers) draw a random workplace; the change is **accepted only if car time is shorter** |
| Updates after a move | Times of relocated agents, density of all agents, standardization statistics (all agents). **`DA_ID` is not updated** | Times of movers and switchers, bike lane distance and density of movers; `dauid` updated |

### Issues found in each implementation

These are not cross-platform differences, but they affect the comparison and should be fixed or documented before running the comparison.

**Mesa**

- **Argmax choice.** An MNL without its random error term amounts to "always choose the most likely mode", which explains the very low bike share (30–34 agents vs. 161 observed). It also means that 5 steps with deterministic choices add little beyond the peer feedback.
- **Re-standardization after relocation.** `prepare_static_calibration_data()` recomputes the means and standard deviations after relocation. Combined with recomputed densities, this shifts the utilities of agents who did not move: 5.74% of non-relocated agents changed mode, even though choices are deterministic.
- **`DA_ID` is not updated** for relocated agents, so DA-level outputs after relocation are wrong.
- **Identification**: walk-specific individual coefficients (β24–β29) plus 33 parameters fitted with only 30 Optuna trials. The coefficients are probably far from an optimum and cannot be interpreted.
- Possible crash if no workplace lies within the commute radius (`workplace_node_network = None` is then passed to the router). It did not happen in this run.
- The [README](README.md) is out of date (children agents, BIXI stations, L-BFGS-B).

**repast4py**

- **Initial NaN travel times.** About 35 of 13,438 agents (batch data, factor 100) have NaN times in `agent2workplace*_soc.csv`: the penalty applied during calibration is not saved to the CSV. In `_chose_mode`, NaN probabilities make `(u < cum_probs).argmax()` return index 0, so these agents always choose **walk** until they move or change job.
- **Inconsistent penalty for missing paths**: 3 × 99th percentile in calibration vs. mean + 3σ in the ABM.
- **Unseeded mode draws** (`rng=None` in `sample_agent_modes`).
- **Density update only for movers**: agents near a mover's old or new home keep stale densities.
- **Calibrated peer coefficient**: it is fitted on peer shares from a single draw of the environmental model, not on a share that has converged under the social model.
- The ABM loads the column `ratio_bike`, which is the **DA-level census** bike share, not `ratio_bike_sn`. It is overwritten before the first choice, so the only effect is on the logged value at tick 1.
- The default dataset in `~/abm_ta/data` (`ts=20260914T163951`) predates the social-network ratios (no `ratio_bike_sn` column). The batch data (`data/batch_data`) is up to date.
- The docstring says gender is male = 0. The data uses male = 1.

### Suggestions for a fair comparison

The comparison paper is about platforms, so the two implementations should be identical up to platform-specific mechanics. A practical way to get there:

1. **Share the inputs.** Feed both models the same synthetic population, workplaces, agent ↔ workplace links, social network and MNL coefficients (e.g. the repast notebook outputs, which are already saved to files). This removes most of the differences listed under "Synthetic population" to "Social network" at once.
2. **Agree on one utility specification**, with the same standardization statistics stored with the coefficients. The main choices: interaction terms or not, pooled or per-mode time standardization, walk as a proper reference.
3. **Use random draws from the MNL probabilities** in both models, with seeded generators, and compare distributions over replications rather than single runs.
4. **Agree on one update scheme for peer shares**: synchronous (Mesa) or sequential (repast). Synchronous is easier to reproduce across platforms and with MPI.
5. **Agree on one scenario**: rates, number of ticks, how the new home is drawn (uniform vs. population-weighted), and the job change rule (accept only if shorter or not).
6. **Use one transit routing** (combined transit + walk graph vs. 3 legs) and one rule for missing paths.
7. Keep the calibration outside the ABM for the platform comparison (or calibrate once and reuse the coefficients), so that runtime comparisons measure simulation only.

