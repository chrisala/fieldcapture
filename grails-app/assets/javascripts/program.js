//= require tab-init.js

//= require mapWithFeatures.js
//= require sites
//= require document
//= require reporting

/**
 * Knockout view model for program pages.
 * @param props JSON/javascript representation of the program.
 * @param options an object specifying the following options:
 * validationContainerSelector, programDeleteUrl, returnToUrl, programEditUrl, programViewUrl
 * @constructor
 */
ProgramViewModel = function (props, options) {
    var self = $.extend(this, new Documents(options));

    var defaults = {
        validationContainerSelector: '.validationEngineContainer'
    };
    var config = _.extend({}, defaults, options);

    self.programId = props.programId;
    self.name = ko.observable(props.name);
    self.description = ko.observable(props.description).extend({markdown: true});
    self.url = ko.observable(props.url);
    self.newsAndEvents = ko.observable(props.newsAndEvents).extend({markdown: true});

    self.projects = props.projects;

    self.deleteProgram = function () {
        if (window.confirm("Delete this program?  Are you sure?")) {
            $.post(config.programDeleteUrl).complete(function () {
                    window.location = config.returnToUrl;
                }
            );
        }
    };

    self.editDescription = function () {
        editWithMarkdown('Edit organisation description', self.description);
    };

    self.editOrganisation = function () {
        window.location = config.programEditUrl;
    };

    self.transients = self.transients || {};

    self.toJS = function (includeDocuments) {
        var ignore = self.ignore.concat(['projects', 'reports']);
        var js = ko.mapping.toJS(self, {include: ['documents'], ignore: ignore});
        if (includeDocuments) {
            js.documents = ko.toJS(self.documents);
            js.links = ko.mapping.toJS(self.links());
        }
        return js;
    };

    self.modelAsJSON = function (includeDocuments) {
        var orgJs = self.toJS(includeDocuments);
        return JSON.stringify(orgJs);
    };

    self.save = function () {
        if ($(config.validationContainerSelector).validationEngine('validate')) {
            self.saveWithErrorDetection(
                function (data) {
                    var programId = self.programId ? self.programId : data.programId;

                    var url;
                    if (config.returnToUrl) {
                        url = config.returnToUrl;
                        url += (config.returnToUrl.indexOf('?') > 0) ? '&' : '?';
                        url += 'programId=' + programId;
                    }
                    else {
                        url = config.programViewUrl + '/' + programId;
                    }
                    window.location.href = url;
                },
                function (data) {
                    bootbox.alert('<span class="label label-important">Error</span><p>' + data.detail + '</p>');
                });
        }
    };

    if (props.documents !== undefined && props.documents.length > 0) {
        $.each(['logo', 'banner', 'mainImage'], function (i, role) {
            var document = self.findDocumentByRole(props.documents, role);
            if (document) {
                self.documents.push(document);
            }
        });
    }

    // links
    if (props.links) {
        $.each(props.links, function (i, link) {
            self.addLink(link.role, link.url);
        });
    }

    autoSaveModel(self, config.programSaveUrl,
        {
            blockUIOnSave: true,
            blockUISaveMessage: 'Saving programme....',
            serializeModel: function () {
                return self.modelAsJSON(true);
            }
        });



    return self;
};

var ProgramPageViewModel = function(props, options) {
    var self = this;
    _.extend(self, new ProgramViewModel(props, options));

    var config = props.config || {};

    self.config = ko.observable(vkbeautify.json(config));

    /**
     * Returns the currently configured activity report configuration.
     * Side effect: it is created if it doesn't exist.
     */
    var getActivityReportConfig = function() {
        var activityReportConfig;
        if (!config.projectReports) {
            config.projectReports = [];
        }
        activityReportConfig = _.find(config.projectReports, function(report) {
            return report.type == 'Activity';
        });
        if (!activityReportConfig) {
            activityReportConfig = {type:'Activity'};
            config.projectReports.push(activityReportConfig);
        }

        return activityReportConfig;
    };
    var getProgramReportConfig = function() {
        if (!config.programReports || config.programReports.length == 0) {
            config.programReports = [{type:'Administrative', category:'Core Services'}];
        }
        return config.programReports[0];
    };

    var activityReportConfig = getActivityReportConfig();
    var programReportConfig = getProgramReportConfig();

    self.coreServicesOptions = [
        {label:'Monthly', firstMilestoneDate:'2018-07-31T14:00:00Z', period:1},
        {label:"Quarterly - Group A (First period ends September 30)", firstMilestoneDate:'2018-09-30T14:00:00Z', period:3},
        {label:"Quarterly - Group B (First period ends August 31)", firstMilestoneDate:'2018-08-31T14:00:00Z', period:3},
        {label:"Half-yearly", firstMilestoneDate:'2019-01-31T13:00:00Z', period:6}];

    var currentOption = _.find(self.coreServicesOptions, function(option) {
        return option.firstMilestoneDate == programReportConfig.firstMilestoneDate;
    });
    self.coreServicesPeriod = ko.observable(currentOption ? currentOption.label : null);


    self.activityReportingOptions = [
        {label:"Quarterly - Group C (First period ends September 30)", firstMilestoneDate:'2018-09-30T14:00:00Z', period:3},
        {label:"Quarterly - Group D (First period ends October 31)", firstMilestoneDate:'2018-10-31T13:00:00Z', period:3},
        {label:"Half-yearly", firstMilestoneDate:'2019-02-28T13:00:00Z', period:6}];

    currentOption = _.find(self.activityReportingOptions, function(option) {
        return option.firstMilestoneDate == activityReportConfig.firstMilestoneDate;
    });
    self.activityReportingPeriod = ko.observable(currentOption ? currentOption.label : null);

    self.saveReportingConfiguration = function() {

        if ($(options.reportingConfigSelector).validationEngine('validate')) {
            var selectedCoreServicesPeriod = _.find(self.coreServicesOptions, function(option) {
                return option.label == self.coreServicesPeriod();
            });
            programReportConfig.firstMilestoneDate = selectedCoreServicesPeriod.firstMilestoneDate;
            programReportConfig.period = selectedCoreServicesPeriod.period;

            var selectedActivityReportingPeriod = _.find(self.activityReportingOptions, function(option) {
                return option.label == self.activityReportingPeriod();
            });
            activityReportConfig.firstMilestoneDate = selectedActivityReportingPeriod.firstMilestoneDate;
            activityReportConfig.period = selectedActivityReportingPeriod.period;

            self.saveConfig(config, function() {
                self.regenerateReports();
            });
        }
    };

    self.saveConfig = function(config, successCallback) {
        var json = {config: config};
        $.ajax({
            url: options.programSaveUrl,
            type: 'POST',
            data: JSON.stringify(json),
            dataType:'json',
            contentType: 'application/json'
        }).done(function (data) {
            bootbox.alert("Program configuration saved");
            if (_.isFunction(successCallback)) {
                successCallback(data);
            }
        }).fail(function() {
            bootbox.alert("Save failed");
        });
    };

    self.regenerateReports = function() {
        $.ajax({
            url: options.regenerateProgramReportsUrl,
            type: 'POST',
            dataType:'json',
            contentType: 'application/json'
        }).fail(function() {
            bootbox.alert("Failed to regenerate program reports");
        });
    };

    self.saveProgramConfiguration = function() {

        try {
            config = JSON.parse(self.config());
        }
        catch (e) {
            bootbox.alert("Invalid JSON");
            return;
        }
        self.saveConfig(config);

    };

    var tabs = {
        'about': {
            initialiser: function () {}
        },
        'projects': {
            initialiser: function() {
                $.fn.dataTable.moment( 'dd-MM-yyyy' );
                $('#projectList').DataTable();
            }
        },
        'sites': {
            initialiser: function () {
                generateMap(['programId:'+self.programId], false, {includeLegend:false});
            }
        },
        'admin': {
            initialiser: function () {
                populatePermissionsTable();
                $(options.reportingConfigSelector).validationEngine();
            }
        }
    };

    initialiseTabs(tabs, {tabSelector:'#program-tabs.nav a', tabStorageKey:'selected-program-tab'});
};