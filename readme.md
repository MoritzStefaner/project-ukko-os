![Projekt Ukko image](http://project-ukko.net/assets/ukko-teaser-fb.png)

# Project Ukko: Open Source version of UI code

This is the Open Source version of the Project Ukko web application (http://project-ukko.net).

## Code credits

All original code (c) by Moritz Stefaner and Dominikus Baur, 2015-2016
Please do not redistribute or reuse without keeping all copyright notices, references to the github repository and the project website intact.

## License

Apache 2.0, see https://github.com/MoritzStefaner/project-ukko-os/blob/master/LICENSE

## Project credits

Project Ukko is a Future Everything and BSC project for EUPORIAS.
Data visualisation by Moritz Stefaner.
Project Ukko director Drew Hemment.

Scientific coordination: Melanie Davis, Isadora Jiménez, Paco Doblas-Reyes, Carlo Buontempo
RESILIENCE seasonal predictions: Veronica Torralba, Nube González-Reviriego, Paco Doblas-Reyes
Based on ECMWF seasonal predictions by RESILIENCE.
Visual identity design: Stefanie Posavec
UI development support: Dominikus Baur
Project management: Tom Rowlands
Wind power capacity data was generously provided by thewindpower.net.

EUPORIAS is a project funded by the EU 7th Framework Programme (GA 308291) and led by the Met Office.

# Installation

```
cd www
npm install
bower install
```

# Tasks
```
gulp dev
```
Launches the dev tasks (copy, includereplace, coffee, sass, bower, connect, watch)

```
gulp dist
```
Launches the dist tasks (copy, includereplace, coffee, sass, bower, uglify, imagemin)

```
gulp ftp
```
Calls _dist_ and uploads the result to an ftp server

```
gulp bump(:{major|minor})
```
Increases the project's version number in package.json and bower.json. Default bump type ('gulp bump') is _patch_ (i.e., 1.0.2 => 1.0.3). Other types are _minor_ (i.e., 1.0.2 => 1.1.2) and _major_ (i.e., 1.0.2 => 2.0.2).

```
gulp tag
```
Commits and uploads the current version to the remote github repository as a tag. Use together with _gulp bump_ to increase version number and upload to repo. Major version bumps are additionally committed as a regular git commit.
