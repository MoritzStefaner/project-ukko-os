installation:

npm install

bower install

then:

gulp dev


# Tasks

## gulp dev
Launches the dev tasks (copy, includereplace, coffee, sass, bower, connect, watch)

## gulp dist
Launches the dist tasks (copy, includereplace, coffee, sass, bower, uglify, imagemin)

## gulp ftp
Calls _dist_ and uploads the result to an ftp server

## gulp bump(:{major|minor})
Increases the project's version number in package.json and bower.json. Default bump type ('gulp bump') is _patch_ (i.e., 1.0.2 => 1.0.3). Other types are _minor_ (i.e., 1.0.2 => 1.1.2) and _major_ (i.e., 1.0.2 => 2.0.2).

## gulp tag
Commits and uploads the current version to the remote github repository as a tag. Use together with _gulp bump_ to increase version number and upload to repo. Major version bumps are additionally committed as a regular git commit.
