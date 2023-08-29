## Info

This repository contains Helm charts maintained by Scaleout Systems AB. The repo index is hosted by GitHub pages.

**Note:** The main branch is now the new default branch. For getting the latest version of these charts  please clone the main branch and not the master.


## Getting started
To be able to deploy Helm charts from this repository you first need to add this repository as a source of charts.

```bash
$ helm repo add scaleout https://scaleoutsystems.github.io/charts/scaleout/stackn
```

Deploy a chart
```bash
$ helm install stackn scaleout/stackn -f <path_to_values.yaml>
```

### Local configs
If you want local configurations place them in a directory named configs/ as the .gitignore will ignore that foldername and contents.

## License
APACHE 2.0
