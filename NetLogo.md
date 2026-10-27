# Porting Python/Mesa ABM to NetLogo

In order to compare the three platforms (Mesa, repast4py and NetLogo), we want to port the Mesa ABM version to NetLogo. To save time, we use Claude to do most of theporting.

Navid suggested to use the last (and most complete) notebook, which is `SocialInteractionGraph_MostEfficientVersion.ipynb`. It encompasses the 3 dimensions we decided to include in the MNL function: SES, environment and social network. Some minor adaptations were required to run locally on VOLVIC: migrating to panadas 3.x and path to data sources.

