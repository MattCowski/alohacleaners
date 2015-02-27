var gulp      = require('gulp');
var gutil     = require('gulp-util');
var connect   = require('gulp-connect');
var gulpif    = require('gulp-if');
var coffee    = require('gulp-coffee');
var concat    = require('gulp-concat');
var tplCache  = require('gulp-angular-templatecache');
var jade      = require('gulp-jade');
var less      = require('gulp-less');
var dist = './public';
var protractor = require("gulp-protractor").protractor;
// var webdriver_standalone = require("gulp-protractor").webdriver_standalone;


gulp.task('appJS', function() {
  // concatenate compiled .coffee files and js files
  // into build/app.js
  gulp.src(['!./app/**/*_test.js','!./app/**/*_e2e.js','./app/**/*.js','!./app/**/*_test.coffee','!./app/**/*_e2e.coffee','./app/**/*.coffee'])
    .pipe(gulpif(/[.]coffee$/, coffee({bare: true}).on('error', gutil.log)))
    .pipe(concat('app.js'))
    .pipe(gulp.dest(dist))
});

gulp.task('e2e_testJS', function() {
  // gulp.task('webdriver_standalone', webdriver_standalone);
  gulp.src(["./app/**/*_e2e.coffee"])
    .pipe(
      gulpif(/[.]coffee$/,
        coffee({bare: true})
        .on('error', gutil.log)
      )
    )
    .pipe(gulp.dest(dist))

  // gulp.src(["./app/**/*e2e_test.js"])
      .pipe(protractor({
          configFile: "protractor.config.js",
          args: ['--baseUrl', 'http://localhost:9001']
      })) 
      .on('error', gutil.log)
});


gulp.task('testJS', function() {
  // Compile JS test files. Not compiled.
  gulp.src([
      './app/**/*_test.js',
      './app/**/*_test.coffee',
      // '!./app/**/*e2e_test.js',
      // '!./app/**/*e2e_test.coffee',
    ])
    .pipe(
      gulpif(/[.]coffee$/,
        coffee({bare: true})
        .on('error', gutil.log)
      )
    )
    .pipe(gulp.dest(dist))
});

gulp.task('templates', function() {
  // combine compiled Jade and html template files into 
  // build/template.js
  gulp.src(['!./app/index.jade', '!./app.index.html',
      './app/**/*.html', './app/**/*.jade'])
      .pipe(gulpif(/[.]jade$/, jade().on('error', gutil.log)))
      .pipe(tplCache('templates.js',{standalone:true}))
      .pipe(gulp.dest(dist))
});

gulp.task('appCSS', function() {
  // concatenate compiled Less and CSS
  // into build/app.css
  gulp
    .src([
      './app/**/*.less',
      './app/**/*.css'
    ])
    .pipe(
      gulpif(/[.]less$/,
        less({
          paths: [
            './bower_components/bootstrap/less'
          ]
        })
        .on('error', gutil.log))
    )
    .pipe(
      concat('app.css')
    )
    .pipe(
      gulp.dest(dist)
    )
});

gulp.task('libJS', function() {
  // concatenate vendor JS into build/lib.js
  gulp.src([
    './bower_components/lodash/dist/lodash.js',
    './bower_components/jquery/dist/jquery.js',
    './bower_components/bootstrap/dist/js/bootstrap.js',
    './bower_components/ng-file-upload/angular-file-upload-shim.js',
    './bower_components/angular/angular.js',
    './bower_components/angular-mocks/angular-mocks.js',
    './bower_components/ng-file-upload/angular-file-upload.js',
    './bower_components/angular-cookies/angular-cookies.js',
    './bower_components/angular-animate/angular-animate.js',
    './bower_components/angular-sanitize/angular-sanitize.js',
    './bower_components/angular-route/angular-route.js',
    './bower_components/angularfire/dist/angularfire.min.js',
    './bower_components/firebase/firebase.js',
    './bower_components/firebase-util/firebase-util.js',
    './bower_components/firebase-simple-login/firebase-simple-login.js',
    './bower_components/ng-token-auth/dist/ng-token-auth.js',
    
    './bower_components/jquery-ui/ui/jquery-ui.js',
    './bower_components/angular-ui-calendar/src/calendar.js',
    './bower_components/fullcalendar/fullcalendar.js',
    './bower_components/fullcalendar/gcal.js',
    './bower_components/angular-motion/dist/angular-motion.js',
    './bower_components/angular-strap/dist/angular-strap.js',
    './bower_components/angular-strap/dist/angular-strap.tpl.js',
    './bower_components/angular-bootstrap/ui-bootstrap-tpls.js',
    './bower_components/angular-ui-utils/ui-utils.js',
    './bower_components/angulartics/src/angulartics.js',
    './bower_components/angulartics/src/angulartics-ga.js',
    './bower_components/angulartics/src/angulartics-scroll.js',
    './bower_components/angular-video-background/dist/vidBg.js',
    ]).pipe(concat('lib.js'))
      .pipe(gulp.dest(dist));
});

gulp.task('libCSS',
  function() {
  // concatenate vendor css into build/lib.css
  gulp.src(['!./bower_components/**/*.min.css',
      './bower_components/**/*.css'])
      .pipe(concat('lib.css'))
      .pipe(gulp.dest(dist));
});

gulp.task('index', function() {
  gulp.src(['./app/index.jade', './app/index.html'])
    .pipe(gulpif(/[.]jade$/, jade().on('error', gutil.log)))
    .pipe(gulp.dest(dist));
});

gulp.task('watch',function() {

  // reload connect server on built file change
  gulp.watch([
      dist+'/**/*.html',        
      dist+'/**/*.js',
      dist+'/**/*.css'        
  ], function(event) {
      return gulp.src(event.path)
          .pipe(connect.reload());
  });

  // watch files to build
  gulp.watch(['./app/**/*.coffee', '!./app/**/*_test.coffee', '!./app/**/*_e2e.coffee', './app/**/*.js', '!./app/**/*_test.js', '!./app/**/*_e2e.js'], ['appJS']);
  gulp.watch(['./app/**/*_test.coffee', './app/**/*_test.js'], ['testJS']);
  gulp.watch(['./app/**/*_e2e.coffee', './app/**/*_e2e.js'], ['e2e_testJS']);
  gulp.watch(['!./app/index.jade', '!./app/index.html', './app/**/*.jade', './app/**/*.html'], ['templates']);
  gulp.watch(['./app/**/*.less', './app/**/*.css'], ['appCSS']);
  gulp.watch(['./app/index.jade', './app/index.html'], ['index']);
});

// gulp.task('server', function() {
//   return connect.server({
//     root: ['generated'],
//     port: 8000,
//     livereload: {
//       port: 1337
//     },
//     middleware: function(connect, o) {
//       return [
//         (function() {
//           var options, proxy, url;
//           url = require('url');
//           proxy = require('proxy-middleware');
//           // options = url.parse('http://localhost:9000/api/');
//           options = url.parse('http://twoweekapp.herokuapp.com/api/');
//           options.route = '/api';
//           return proxy(options);
//         })()
//       ];
//     }
//   });
// });


gulp.task('connect', connect.server({
  root: [dist],
  port: 9001,
  livereload: true,
  middleware: function(connect, o) {
      return [
        (function() {
          var options, proxy, url;
          url = require('url');
          // var angularServer = 'http://664dd095.ngrok.com';
          proxy = require('proxy-middleware');
          // options = url.parse(angularServer);
          options = url.parse('http://localhost:9001/api/');
          // options = url.parse('http://twoweekapp.herokuapp.com/api/');
          options.route = '/api';
          return proxy(options);
        })()
      ];
    }
}
));

gulp.task('default', ['connect', 'appJS', 'testJS', 'templates', 'appCSS', 'index', 'libJS', 'libCSS', 'watch']);