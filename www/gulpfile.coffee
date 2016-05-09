gulp = require 'gulp'
coffee = require 'gulp-coffee'
concat = require 'gulp-concat'
notify = require 'gulp-notify'
sourcemaps = require 'gulp-sourcemaps'
bower = require 'main-bower-files'
sass = require 'gulp-sass'
fileinclude = require 'gulp-file-include'
replace = require 'gulp-replace-task'
connect = require 'gulp-connect'
del = require 'del'
uglify = require 'gulp-uglify'
# imagemin = require 'gulp-imagemin'
sequence = require 'run-sequence'
sftp = require 'gulp-sftp'
bump = require 'gulp-bump'
git = require 'gulp-git'
Bust = require 'gulp-bust'

bust = new Bust()

pkg = require './package.json'

banner = """
-- #{pkg.name} --
authors: #{pkg.authors}
version: #{pkg.version}
date: #{new Date()}

Project Ukko
https://github.com/MoritzStefaner/project-ukko-os
Licensed under Apache 2.0
(c) by Moritz Stefaner and Dominikus Baur, 2015-2016

"""

configDev =
	"mode": "dev"	# dev|dist
	"target": "dev"	# dev|dist
	"bowerDir": "bower_components"
	"variables":
		"SITE_NAME": "Project Ukko (v#{pkg.version})"
		"GA_ID": "_"
		"GA_URL": "_"
		"FB_APP_ID": "_"
		"BANNER": banner
		"VERSION": pkg.version

configDist =
	"mode": "dist"	# dev|dist
	"target": "dist"	# dev|dist
	"bowerDir": "bower_components"
	"variables":
		"SITE_NAME": "Project Ukko — visualizing seasonal wind predictions"
		"GA_ID": "_"
		"GA_URL": "_"
		"FB_APP_ID": "_"
		"BANNER": banner
		"VERSION": pkg.version

config = configDev

onError = (err) -> notify().write err


gulp.task 'sftp-deploy', ['minify'], ->
	gulp.src config.target + '/**/*!(.sass-cache)*'
	.pipe sftp
		host: 'starling.columba.uberspace.de'
		port: 22
		authKey: 'key1'
		remotePath: "/var/www/virtual/starling/html/euporias/#{pkg.version}"

	gulp.src config.target + '/.htaccess'
	.pipe sftp
		host: 'starling.columba.uberspace.de'
		port: 22
		authKey: 'key1'
		remotePath: "/var/www/virtual/starling/html/euporias"

gulp.task 'sftp-deploy-public', ['minify'], ->
	gulp.src config.target + '/**/*!(.sass-cache|.htaccess)*'
	.pipe sftp
		host: 'projectukko.default.ukko.uk0.bigv.io'
		port: 22
		authKey: 'key2'
		remotePath: "/srv/project-ukko.net/public/htdocs"

gulp.task 'bower', ->
	gulp.src bower()
	.pipe connect.reload()
	.pipe concat "libs.js"
	.pipe gulp.dest config.target + '/js'

gulp.task 'coffee', ->
	gulp.src ['src/coffee/main.coffee', 'src/coffee/**/!(main)*.coffee']
	.pipe concat "main.js"
	.pipe connect.reload()
	.pipe sourcemaps.init()
	.pipe coffee bare:false
	.on "error", notify.onError "Error: <%= error.message %>"
	.pipe sourcemaps.write()
	.pipe gulp.dest config.target + '/js'
	#.pipe notify "coffee's ready!"


gulp.task 'sass', ->
	sassStyle = "nested"
	sassStyle = "compressed" if config.mode == "dist"

	gulp.src('src/sass/**/*.sass')
	.pipe(sass
		outputStyle: sassStyle
		options:
			includePaths: []
	)
	.on "error", notify.onError "Error: <%= error.message %>"
	.pipe connect.reload()
	.pipe gulp.dest config.target + '/css'


gulp.task 'copy', ->
	gulp.src ["src/assets/**/*.!(psd)", "src/assets/**/*"]
	.pipe gulp.dest config.target + '/assets'

	gulp.src "src/js/**/*"
	.pipe gulp.dest config.target + '/js'

	gulp.src "src/data/**/*"
	.pipe gulp.dest config.target + '/data'

	gulp.src "./"
	.pipe connect.reload()

gulp.task 'includereplace', ->
	gulp.src ["src/**/!(_)*.html", "src/.htaccess"]
	.pipe fileinclude
		prefix: '@@'
		basepath: '@file'
	.pipe replace
		patterns: [ json: config.variables ]
	.pipe connect.reload()
	.pipe gulp.dest config.target + '/'

gulp.task 'uglify', ['initial-build'], ->
	gulp.src config.target + '/js/**/*.js'
	.pipe uglify()
	.on "error", notify.onError "Error: <%= error.message %>"
	.pipe gulp.dest config.target + '/js'

# gulp.task 'imagemin', ['initial-build'], ->
# 	gulp.src config.target + '/assets/**/*.{png,jpg,gif}'
# 	.pipe imagemin()
# 	.on "error", notify.onError "Error: <%= error.message %>"
# 	.pipe gulp.dest config.target + '/assets'


gulp.task 'clean', (cb) ->
	del [ config.target ], cb

gulp.task 'initial-build', ['clean'], (cb) ->
	sequence(['copy', 'includereplace', 'coffee', 'sass', 'bower'], cb)

gulp.task 'connect', ['initial-build'], ->
	connect.server
		root: config.target + '/'
		port: 8000
		livereload: true

gulp.task 'watch', ['connect'], ->
	gulp.watch 'bower_components/**', ['bower']
	gulp.watch 'src/coffee/**', ['coffee']
	gulp.watch 'src/sass/**', ['sass']
	gulp.watch 'src/assets/**', ['copy']
	gulp.watch 'src/js/**/*', ['copy']
	gulp.watch 'src/data/**', ['copy']
	gulp.watch 'src/**/*.html', ['includereplace']

gulp.task 'minify', ['uglify']


# main tasks:
gulp.task 'dev', ->
	config = configDev
	sequence 'watch'

gulp.task 'dist', ->
	config = configDist
	sequence 'minify'

gulp.task 'ftp', ->
	config = configDist
	sequence 'sftp-deploy'

gulp.task 'deploy', ->
	config = configDist
	sequence 'sftp-deploy-public'

gulp.task 'bump', () ->
	gulp.src ['./package.json', './bower.json']
	.pipe bump()
	.pipe gulp.dest('./')

gulp.task 'bump:major', () ->
	gulp.src ['./package.json', './bower.json']
	.pipe bump
		type: 'major'
	.pipe gulp.dest('./')

gulp.task 'bump:minor', () ->
	gulp.src ['./package.json', './bower.json']
	.pipe bump
		type: 'minor'
	.pipe gulp.dest('./')


gulp.task 'tag', () ->
	pkg = require './package.json'
	v = 'v' + pkg.version
	message = 'Release ' + v

	git.commit message
	git.tag v, message
	git.push 'origin', 'master', {args: '--tags'}
