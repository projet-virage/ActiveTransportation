# NetLogo port of `SocialInteractionGraph_MostEfficientVersion.ipynb`: choices and decisions

This document records how the Mesa/Python model was ported to NetLogo 7.0.4, which options were considered at each step, what was decided, and how each decision affects comparability with the Python version. It accompanies the Mesa / repast4py / NetLogo platform comparison (see `../NetLogo.md`).

## 1. Scope and guiding principles

* **Reference**: `SocialInteractionGraph_MostEfficientVersion.ipynb` with `n_rep = 50` (cells 6–23): data preparation, network construction, the `TransportModel` / `PersonAgent` classes, calibration (cells 20–21) and the relocation experiment (cell 23). The network plots of cell 12 are replaced by the NetLogo view (DA outlines and agents coloured by mode).
* **Fidelity first.** The port reproduces what the Python code *does*, including behaviour that differs from the README or looks accidental, whenever it changes results (rounding, Gower distance, argmax choice, etc.). Section 4 lists these items.
* **Pure NetLogo.** Everything runs in NetLogo code with bundled extensions only: `gis` (shapefiles), `array` (networks and shortest-path search), `csv` (census, outputs), `table` (look-ups, caches). No `py` extension, and in the end no `nw` either (section 3.2). The only step outside NetLogo is a one-off PowerShell export of workplace coordinates (section 3.5).
* **No data copy.** The model reads `../data/Transportation_UrbanHealth/` (the `data-dir` input). Derived or generated files go to `NetLogo/derived/` and `NetLogo/output/` (both git-ignored).
* **Not bit-identical.** NetLogo and Python use different random number generators, so individual runs differ. The aim is the same *distribution* of outcomes. Steps that do not involve randomness are reproduced exactly (e.g. the number of agents per DA).

## 2. Files

| File | Content | Python counterpart |
|---|---|---|
| `TransportModeChoice.nlogox` | Interface, globals, breeds, `setup`, Info tab, BehaviorSpace experiments | — |
| `tmc-data.nls` | World and coordinate system, networks, STM stops, bike lanes, workplaces, census, residential parcels | cells 6, 7, 10, `TransportModel.__init__` |
| `tmc-population.nls` | Agent creation, activation, population density, social network | `create_agents`, `assign_nodes`, `assign_local_population_density`, `initialize_social_network` |
| `tmc-travel.nls` | Shortest-path travel times with caches | `_batch_shortest`, `compute_all_travel_times` |
| `tmc-choice.nls` | Standardisation, utilities, model step, mode shares | `prepare_static_calibration_data`, `compute_mode_choice`, `model_step`, `fast_peer_share` |
| `tmc-calibration.nls` | Objective function, parameter search, coefficient files | `calibration_error`, Optuna study (cells 20–21) |
| `tmc-relocation.nls` | Relocation experiment | cell 23 |
| `prep_workplaces.ps1` | One-off export of the workplace point coordinates | — |
| `betas_HighComplexity.csv` | The 33 coefficients of `Betas_HighComplexity.npy` (decoded from the `.npy` without Python) | `np.load(...)` |

**File format.** NetLogo 7 uses the XML `.nlogox` format. The code is split into `.nls` include files (opened as tabs in the NetLogo editor) so that each file mirrors a part of the Python model and stays readable. *Alternative considered:* a single `.nlogox`; it would be easier to share but would make one 1,000+ line code tab.

## 3. Decisions, topic by topic

### 3.1 World, projection and spatial units

* **Options:** (a) world = island envelope; (b) world = network envelope; patch size 100 m / 200 m / 500 m; NetLogo units in metres.
* **Decision:** world = envelope of the network nodes (the networks extend well beyond the island and every node must be a turtle inside the world) plus a 500 m margin, with **200 m patches** (about 650 × 475 patches). The GIS transformation is set explicitly with `gis:set-transformation`, so MTM-8 metres ↔ NetLogo coordinates is an exact linear map (`x->mtm`, `mtm->x`, …).
* **Rationale:** patches only serve as a spatial index. Turtles sit at exact (floating-point) positions, and all distances come from those exact positions, so distances are exact Euclidean distances in metres, as in Python (projected MTM-8 coordinates). 200 m keeps the patch count moderate while making radius searches cheap.
* **Impact:** none on results.

### 3.2 Networks

* **Options:** (a) node turtles + one directed link breed per mode, with shortest paths from the `nw` extension (the natural NetLogo design, and the one initially planned); (b) node turtles + adjacency arrays (`array` extension) with a shortest-path search written in NetLogo; (c) precomputing travel times in Python (rejected: not pure NetLogo).
* **What we measured:** in NetLogo 7.0.4, creating a link costs time proportional to the number of links that already exist, whatever the breed, the creation order or the endpoints (100,000 links: 75 s; the next 100,000: 374 s; same in a bare model without extensions). The four networks have 1,077,477 edges in total, which extrapolates to hours of setup. Reading the shapefiles is fast (≈ 3 s each); creating the links is the bottleneck.
* **Decision:** (b). All 94,931 nodes are turtles shared by the four networks (as in `osmnx.graph_from_gdfs`, every graph contains every node), and a node's index is its `who` number. Each network is stored as two arrays indexed by node (forward and backward adjacency), whose items are flat lists `[neighbour travel-time neighbour travel-time …]`. Building all four takes ≈ 21 s. Only the `u`, `v`, `trv_time` attributes are used; edge geometries are not needed. The `nw` extension is therefore not used.
* **Parallel edges and self-loops** (`MultiDiGraph` keys) are stored as they are: the search uses the cheapest parallel edge automatically, exactly like networkx on a multigraph, and self-loops never improve a path.
* **Impact:** none on travel times.

### 3.3 Shortest paths and caching

* **Algorithm:** `osmnx.routing.shortest_path` calls `networkx.shortest_path` once per pair, i.e. networkx's **bidirectional Dijkstra**. The port implements the same algorithm in NetLogo (`network-distance` in `tmc-travel.nls`): two binary heaps stored in arrays, the standard stopping rule (stop when the sum of the two heap minima reaches the best complete path), and search-state arrays stamped with a query id so that nothing is reset between queries. Checked against a plain one-directional Dijkstra: identical results.
* **Caching:** same structure as `_batch_shortest`: per network, collect the missing (origin, destination) pairs, compute each once, and keep them in a cache table for the whole session (the caches also survive `setup-population` and relocation).
* **Transit** follows the Python logic exactly: walk (home node → home STM node), then transit (home STM node → work STM node) only for agents whose first leg exists, then walk (work STM node → workplace node) only for those whose second leg exists. Transit is available only if all three legs exist.
* **Unreachable destination**: the search reports `false`, the port's equivalent of `NaN`; the mode becomes unavailable (utility −∞). The bidirectional search stops as soon as one side runs out of nodes, so unreachable pairs are cheap.
* **Impact:** none on results. Performance: see section 5.

### 3.4 Nearest-node and nearest-neighbour searches (KDTree, `osmnx.nearest_nodes`)

* **Options:** (a) brute force `min-one-of`; (b) growing `in-radius` search on the patch grid; (c) rasterised approximations.
* **Decision:** (b), exact. `nearest-in` searches discs of growing radius around the point; once the best candidate is closer than the radius minus the patch-centre offset, it is provably the nearest one. Used for: network node of each residential parcel / workplace / STM stop, and the STM stop nearest to a network node (`closest_candidate_node`).
* **Lazy evaluation:** Python computes the network node of all 64,425 parcels; the port only computes it for parcels that actually host an agent (same values, less work).
* **Impact:** none (ties between equidistant nodes are broken at random instead of by index).

### 3.5 Workplaces

`workplaces.shp` contains 1,303,891 points, but its `.dbf` weighs 705 MB (company names, descriptions, postal codes) that the model never uses. NetLogo's GIS extension loads all attributes into memory.

* **Options:** (a) load the shapefile directly with `gis` (pure NetLogo, but several GB of heap and minutes of loading); (b) one-off export of the coordinates to a slim text file; (c) use `Workplaces_MTM.shp` (9,982 land-use polygons) instead, which would change the model.
* **Decision (user's choice):** (b). `prep_workplaces.ps1` reads the point geometry directly from the `.shp` binary (no Python, no GDAL, `.dbf` never opened) and writes `derived/workplaces_xy.txt` (`x y` in MTM-8 metres, one line per workplace, file order preserved). Run it once; it takes about 6 minutes.
* **Workplace assignment:** Python picks uniformly among the workplaces within `commute_distance` of home (`KDTree.query_ball_point` + `random.choice`). The port uses **rejection sampling** over the full list: draw a random workplace, accept it if it lies within the radius. This gives exactly the same distribution with no spatial index (an exhaustive scan backs it up if 200,000 draws all fail).
* **Impact:** none.

### 3.6 Census data and DAs (cell 7)

Reproduced step by step with the `csv` extension: drop the first data row (Montreal CMA total, `iloc[1:]`), rename columns, drop `COL14`, `dropna`, income bracket shares (with `income_no_total = 1 − Σ others`), merging `<15 min` into `15–30 min` and commute shares, gender share `Male / (Male + Female)`, and the *right* join with the DA polygons (census order kept; DAs without a polygon are kept but get no agents).

Divisions by zero (which would give `NaN` in pandas) give 0. In Python, those DAs either never get agents or would make the notebook crash, so this does not change results.

### 3.7 Residential parcels and DA membership

* **Options:** (a) parcel centroid in DA (raster or point-in-polygon); (b) polygon intersection, as in Python.
* **Decision:** (b): `residential.intersects(da.geometry)` is reproduced with `gis:intersects?` (JTS, the same geometry engine family as shapely), after a spatial prefilter on centroid distances. A parcel straddling two DAs belongs to both, as in Python. Agents live at the parcel centroid (`gis:centroid-of`, the same centroid as shapely).
* **Impact:** none.

### 3.8 Agent creation (`create_agents`)

* **Rounding:** Python's `round()` rounds **half to even** (`round(0.5) = 0`, `round(1.5) = 2`), while NetLogo's `round` rounds half up. With census counts that are multiples of 5 and `n_rep = 50`, halves are very frequent (e.g. 25 people → 0.5 agent), so the port implements `py-round`. With NetLogo's `round` the island would get noticeably more agents than Python's 12,340.
* **Truncated normal income:** `scipy.stats.truncnorm` is replaced by rejection sampling from `random-normal` within [low, high] (same distribution), followed by `py-round`.
* **Categories:** commute-radius classes (4, 8, 13, 18 km) and income brackets are allocated with the same `floor`/remainder rule and shuffled; Python's `zip` truncation is mimicked.
* **Side effect worth knowing (present in the Python model too):** with `n_rep = 50`, a DA has about 4 agents on average (12,340 agents over ~3,180 DAs), so `floor(share × n_adults)` is 0 for most of the 12 income brackets and most of the commute classes. The remainder classes absorb almost everyone: most agents end up "without income" (mean income ≈ $3,600) and with the 4 km commute radius. The port reproduces this faithfully; it may deserve attention in the original model (e.g. largest-remainder allocation or sampling the brackets).
* **Only adults** are created: the README mentions children and schools, but this notebook does not create them.

### 3.9 Agent activation (`assign_nodes`)

Agents are activated in random order (`ask persons`), as `random.sample(agent_list)`:

* network node of the home parcel;
* **distance to the nearest bike lane:** exact point-to-polyline distance. Bike-lane polylines are split into segments, each segment is indexed on the patches it crosses, and the nearest segment is found by a growing search with a proven stopping rule. *Alternative rejected:* rasterising bike lanes to patches (error up to ±200 m, which would shift `proximity_to_bikelane`);
* workplace (section 3.5) and its network node; a hidden `workspot` turtle marks the workplace (it serves as spatial index for the social network);
* home and work STM nodes (`closest_candidate_node`).

### 3.10 Population density

`count persons in-radius 1 km × n_rep / π`, with the agent itself included and `≤ r`, like `KDTree.query_ball_point`.

### 3.11 Social network (`initialize_social_network`)

* Candidates: agents living within `interaction-radius` of the agent's home **or** working within `interaction-radius` of its workplace, minus itself.
* `target_n = randint(min_peers, max_peers)`, capped by the number of candidates; peers = `target_n` agents drawn at random from the `2 × target_n` most similar candidates.
* **Gower distance reproduced exactly.** The `gower` package rescales numerical features by their range over the rows it receives (the agent plus its candidates), not over the whole population; the min-max normalisation done before in the notebook therefore cancels out. The port computes `(|Δage|/range_age + [gender differs] + |Δincome|/range_income) / 3` with local ranges (a feature with zero range contributes 0, as in `gower`).
* Ties in the similarity ranking are broken by agent order (`np.argpartition` breaks them arbitrarily).

### 3.12 Standardisation and utilities

* Z-scores use the **population** standard deviation (`numpy.std`, ddof = 0). NetLogo's `standard-deviation` is the sample one (ddof = 1), so the port computes it explicitly.
* The four travel times share **one** mean and standard deviation, pooled over all finite values of the four modes (as in the notebook); income, age, density and bike-lane proximity have their own.
* The 33 coefficients keep the Python order (`b1…b29`, `gamma_bike`, `ASC_auto`, `ASC_transit`, `ASC_bike`); walking is the reference alternative (no ASC).
* On the first step after a reset all four utilities are computed; on the following steps (social interaction on) only the bicycle utility is recomputed with the peer bike share of the previous step, exactly as in `compute_mode_choice`.

### 3.13 Mode choice: argmax, not random draw

* The README says the mode is drawn according to the logit probabilities, but the code takes `np.argmax(probs)`, i.e. the mode with the highest utility. **The port follows the code** (deterministic argmax; ties go to the first mode in auto/transit/bike/walk order).
* Python falls back to a random mode when `Σ exp(U)` is 0 or infinite. The port reproduces this with the float64 limits (all available utilities < −745.13, or one > 709.78), and when no mode is available.
* Unavailable modes are stored as `false` instead of −∞ (NetLogo has no infinities).

### 3.14 Calibration

* **Objective** (`calibration_error`): ported line by line. Observed counts use `py-round(count / n_rep)`; DA error = mean squared share difference weighted by the observed agents of the DA; objective = 0.2 × local + 0.8 × global share error. `evaluate-betas` writes `output/DA_calibration_results.csv` (same columns as the Python file).
* **Search options:** (a) Optuna's TPE sampler (Python only); (b) BehaviorSearch (bundled with NetLogo 7.0.4) — but each evaluation would rebuild the population and recompute ~60,000 shortest paths, whereas in Python the model is built once and only the five choice steps are rerun per trial; (c) a search procedure inside the model, reusing the built population like Python does.
* **Decision (user's choice):** (c). `calibrate` runs `n-trials` trials (default 30, as in the notebook) within the same bounds as the Optuna study. The first `n-startup` trials (default 10, Optuna's own number of random start-up trials for TPE) are uniform random draws; the following ones are Gaussian perturbations of the best point so far (σ = 10 % of each range, clipped to the bounds). The history goes to `output/calibration_history.csv`, then the notebook's 5-step convergence check is printed, the final objective is computed with results saved, and the coefficients go to `output/betas_HighComplexity.csv`.
* **Impact:** the search *strategy* differs from TPE, so the calibrated coefficients will differ; the objective function is identical. With 30 trials neither method is expected to converge; to compare *models* rather than optimisers, run both with the same coefficient file (`betas_HighComplexity.csv`, decoded from the Python `.npy`).

### 3.15 Relocation experiment (cell 23)

Ported as `run-relocation-experiment`: baseline simulation; `int(0.30 × n)` agents (slider `relocation-fraction`) get a new random parcel (different from the old one, anywhere on the island), a new workplace with the same commute radius, new bike-lane distance and STM nodes; densities are recomputed for everyone, travel times for the relocated agents (caches reused), statistics are recomputed, and the simulation runs again. Outputs: comparison table, change in shares (pp), transition matrix, change rates of relocated / non-relocated agents, two plots, and `output/relocation_*.csv`. As in Python, the DA of relocated agents and the social network are **not** updated. The population is modified afterwards: run `setup-population` before another experiment.

## 4. Python behaviours reproduced on purpose

| Behaviour in the notebook | Kept? | Note |
|---|---|---|
| `round()` = half to even | yes | `py-round`; drives agent counts and observed counts |
| Mode = argmax of probabilities (README says random draw) | yes | section 3.13 |
| Random mode when `Σ exp(U)` is 0 or ∞ | yes | float64 limits |
| Gower ranges computed on (agent + candidates) only | yes | section 3.11 |
| Single pooled mean/std for the four travel times | yes | section 3.12 |
| Relocated agents keep their DA and peers | yes | section 3.15 |
| `floor` allocation of income / commute classes (most agents without income, 4 km radius) | yes | section 3.8 |
| Unused code (`agents_interactions_effect`, first `compute_mode_shares` overridden by the second, `prx_bikelanes` vs `prx_bikelanes_st` naming) | not ported | no effect on results |
| `self.population` clip, plots of the networks, `tqdm` progress bars | not ported | no effect on results |

## 5. Performance and memory

Measured headless on the VOLVIC server (Windows Server 2022, 24 logical CPUs, 96 GB RAM; NetLogo runs single-threaded), full population (`n_rep = 50`, 12,340 agents):

| Stage | NetLogo 7.0.4 | Python notebook |
|---|---|---|
| Nodes + 4 networks (adjacency arrays) | 24 s | — |
| STM stops, bike lanes, workplaces, census, parcels, parcel → DA matching | 36 s | — |
| Agents, density, activation (homes, bike lanes, workplaces, STM nodes) | 15 s | — |
| Car / walk / STM / bike travel times | 180 / 236 / 156 / 253 s (825 s) | 114 / 152 / 95 / 154 s (515 s) |
| Social network | 32 s | — |
| One calibration trial (5 steps) | ≈ 0.6–0.8 s | ≈ 3.3 s |
| Relocation of 3,702 agents (activation + travel times) | ≈ 4.5 min | — |
| **Total `setup`** | **≈ 15.5 min** | — |

* The shortest-path step dominates. The NetLogo search is ≈ 1.6 × slower than networkx, which is acceptable for a one-off step; the caches make a second `setup-population` in the same session much faster (only new pairs are computed).
* Choice steps are faster than in Python, so calibration trials are cheap.
* Memory: the networks, 1.3 M workplace coordinates and ~180,000 turtles fit in a few GB; NetLogo's default heap (50 % of RAM) is more than enough.
* `prep_workplaces.ps1` takes ≈ 6 min, once.
* Possible further speed-ups, not implemented to keep the code simple: A* with a Euclidean lower bound (effective on the walk and bike networks, where speed is nearly constant), or caching the travel times of a population to a file.

## 6. How to run

**Once:** create the slim workplace file (≈ 6 min):

```powershell
cd NetLogo
powershell -ExecutionPolicy Bypass -File prep_workplaces.ps1
```

**GUI:** open `TransportModeChoice.nlogox` in NetLogo 7.0.4, then `setup-data` → `setup-population` → `load-betas` → `run-simulation` / `evaluate-betas`, or `calibrate`, or `relocation`. `max-das` > 0 restricts the population to the first DAs for quick tests (the full networks are still loaded). `seed` fixes the random seed (0 = random).

**Headless** (BehaviorSpace experiments defined in the model: `smoke`, `full-baseline`, `calibrate-and-relocate`). The `netlogo-headless.bat` shipped with NetLogo 7.0.4 fails when the install path contains spaces; calling Java directly works:

```powershell
$nl = 'D:\Program Files\NetLogo 7.0.4'
& "$nl\runtime\bin\java.exe" -XX:MaxRAMPercentage=50 "-Dnetlogo.extensions.dir=$nl\extensions" `
  -classpath "$nl\app\netlogo-7.0.4.jar" org.nlogo.headless.Main `
  --model NetLogo\TransportModeChoice.nlogox --experiment full-baseline --table -
```

Beware: in headless BehaviorSpace runs, a runtime error stops the run silently (the metrics are simply reported at that point). When testing changes, wrap the commands in `carefully [ ... ] [ print error-message ]`.

## 7. Verification

Runs of 2026-10-27, headless, full population, seed 42, compared with the outputs saved in the Python notebook (`n_rep = 50`):

| Check | NetLogo | Python | Comment |
|---|---|---|---|
| Agents created | 12,340 | 12,340 | deterministic given banker's rounding: exact match |
| Agents without peers | 1 | 1 | |
| Observed totals (auto, transit, bike, walk) | 7888, 3477, 161, 814 | 7888, 3477, 161, 814 | exact match |
| DAs in `DA_calibration_results.csv` / identical observed counts | 3,175 / 3,175 | 3,175 | exact match, DA by DA |
| Simulated totals with the Python coefficients | 8050, 3583, 38, 669 | 8094, 3557, 34, 655 | same coefficients (`betas_HighComplexity.csv`), different random draws |
| Final objective with the Python coefficients | 0.00953 | 0.00931 | mean DA error 0.059 vs 0.057 |
| Calibration, 30 trials | best 0.0126 | best 0.0093 (TPE) | different optimiser, same objective (section 3.14) |
| Mode changes after convergence (steps 2–5) | 0.2–0.25 % | — | choices are stable after 5 steps |
| Relocation: agents moved | 3,702 | 3,702 | |
| Relocation: agents changing mode (all / relocated / others) | 12.13 % / 28.1 % / 5.3 % | 12.12 % / 27.0 % / 5.7 % | |
| Relocation: baseline counts | 8048, 3585, 36, 671 | 8094, 3552, 30, 664 | |

Shortest-path engine: bidirectional results equal a plain one-directional Dijkstra on 20 random pairs. The `smoke` BehaviorSpace experiment (40 DAs, ≈ 3 min) is the quickest end-to-end check after a change.

Not verified by me: rendering of the Interface tab in the NetLogo GUI (all runs were headless).
