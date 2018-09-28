// Karma configuration
// Generated on Thu May 21 2015 09:01:47 GMT+1000 (AEST)

module.exports = function (config) {

    var sourcePreprocessors = ['coverage'];
    function isDebug(argument) {
        return argument === '--debug';
    }
    if (process.argv.some(isDebug)) {
        sourcePreprocessors = [];
    }
    config.set({

        // base path that will be used to resolve all patterns (eg. files, exclude)
        basePath: '',

        plugins: [
            'karma-jquery',
            'karma-chrome-launcher',
            'karma-jasmine',
            'karma-jasmine-jquery',
            'karma-coverage',
            'karma-firefox-launcher',
            'karma-phantomjs-launcher'
        ],


        // frameworks to use
        // available frameworks: https://npmjs.org/browse/keyword/karma-adapter
        frameworks: [
            'jquery-3.3.1',
            'jasmine-jquery',
            'jasmine'],


        // list of files / patterns to load in the browser
        files: [
            'test/js/util/*.js',
            'grails-app/assets/vendor/knockout/3.4.0/knockout-3.4.0.js',
            'grails-app/assets/vendor/knockout/3.4.0/knockout.mapping-latest.js',
            'grails-app/assets/vendor/underscorejs/1.8.3/underscore.js',
            'grails-app/assets/vendor/wmd/showdown.js',
            'grails-app/assets/vendor/wmd/wmd.js',
            'grails-app/assets/vendor/datatables/1.10.16/js/jquery.dataTables.js',
            'grails-app/assets/vendor/jquery-ui/jquery-ui-1.9.2.custom.js',
            'grails-app/assets/vendor/fileupload-9.0.0/jquery.fileupload.js',
            'grails-app/assets/vendor/momentjs/moment.min.js',
            'grails-app/assets/javascripts/*.js',
            'test/js/spec/**/*.js'
        ],


        // list of files to exclude
        exclude: [],


        // preprocess matching files before serving them to the browser
        // available preprocessors: https://npmjs.org/browse/keyword/karma-preprocessor
        preprocessors: {
            'grails-app/assets/javascripts/*.js':sourcePreprocessors
        },


        // test results reporter to use
        // possible values: 'dots', 'progress'
        // available reporters: https://npmjs.org/browse/keyword/karma-reporter
        reporters: ['progress', 'coverage'],

        coverageReporter: {
            'dir':'./target',
            'type':"text",
            check: {
                global: {
                    lines: 10
                }
            }
        },

        // web server port
        port: 9876,


        // enable / disable colors in the output (reporters and logs)
        colors: true,


        // level of logging
        // possible values: config.LOG_DISABLE || config.LOG_ERROR || config.LOG_WARN || config.LOG_INFO || config.LOG_DEBUG
        logLevel: config.LOG_INFO,


        // enable / disable watching file and executing tests whenever any file changes
        autoWatch: true,


        // start these browsers
        // available browser launchers: https://npmjs.org/browse/keyword/karma-launcher
        browsers: ['Chrome','Firefox','PhantomJS'],


        // Continuous Integration mode
        // if true, Karma captures browsers, runs the tests and exits
        singleRun: true
    });
};