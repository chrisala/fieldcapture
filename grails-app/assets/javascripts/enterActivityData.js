//= require forms-manifest.js
//= require_self

function validateDateField(dateField) {
    var date = stringToDate($(dateField).val());

    if (!isValidDate(date)) {
        return "Date must be in the format dd-MM-YYYY";
    };
}

/* Master controller for page. This handles saving each model as required. */
var Master = function (activityId, config) {
    var self = this;
    this.subscribers = [];

    var defaults = {
        validationContainerSelector:'#validation-container',
        timeoutMessageSelector:'#timeoutMessage',
        activityNavSelector:'#activity-nav',
        savedNavMessageSelector:'#saved-nav-message-holder',
        activityUpdateUrl:fcConfig.activityUpdateUrl
    };
    var options = _.extend({}, defaults, config);

    // client models register their name and methods to participate in saving
    self.register = function (modelInstanceName, getMethod, isDirtyMethod, resetMethod, saveCallback) {
        this.subscribers.push({
            model: modelInstanceName,
            get: getMethod,
            isDirty: isDirtyMethod,
            reset: resetMethod,
            saveCallback: saveCallback
        });
        if (ko.isObservable(isDirtyMethod)) {
            isDirtyMethod.subscribe(function() {
                self.dirtyCheck();
            });
        }
    };

    self.dirtyCheck = function() {
        self.dirtyFlag.isDirty(self.isDirty());
    };

    /**
     *  Takes into account changes to the photo point photo's as the default knockout dependency
     *  detection misses edits to some of the fields.
     */
    self.dirtyFlag = {
        isDirty: ko.observable(false),
        reset: function() {
            $.each(self.subscribers, function(i, obj) {
                obj.reset();
            });
        }
    };

    // master isDirty flag for the whole page - can control button enabling
    self.isDirty  = function () {
        var dirty = false;
        $.each(this.subscribers, function(i, obj) {
            dirty = dirty || obj.isDirty();
        });
        return dirty;
    };

    self.activityData = function() {
        var activityData = undefined;
        $.each(self.subscribers, function(i, obj) {
            if (obj.model == 'activityModel') {
                activityData = obj.get();
                return false;
            }
        });
        return activityData;
    };

    self.validate = function() {
        var valid = $(options.validationContainerSelector).validationEngine('validate');
        if (valid) {

            // Check that forms with multiple optional sections have at least one of those sections completed.
            var optionalCount = 0;
            var notCompletedCount = 0;
            var warnings = [];
            $.each(self.subscribers, function(i, obj) {
                if (obj.model !== 'activityModel') {
                    if (obj.model.transients.optional) {
                        optionalCount++;
                        if (obj.model.outputNotCompleted()) {
                            notCompletedCount++;
                        }
                    }
                    warnings = warnings.concat(obj.model.checkWarnings());
                }
            });
            if (optionalCount > 1 && notCompletedCount == optionalCount) {
                valid = false;
                bootbox.alert("<p>To 'Save changes', the mandatory fields of at least one section of this form must be completed.</p>"+
                    "<p>If all sections are 'Not applicable' please contact your grant manager to discuss alternate form options</p>");
            }
            else if (warnings.length > 0) {
                bootbox.alert("<p>You have active warnings on this form.  Please check that the values entered are correct.</p>");
            }

        }

        return valid;
    };

    self.modelAsJS = function() {
        var activityData, outputs = [];
        $.each(this.subscribers, function(i, obj) {
            if (obj.isDirty()) {
                if (obj.model === 'activityModel') {
                    activityData = obj.get();
                }
                else {
                    outputs.push(obj.get());
                }
            }
        });

        if (activityData === undefined && outputs.length == 0) {
            return undefined;
        }
        if (!activityData) {
            activityData = {};
        }
        activityData.outputs = outputs;

        return activityData;

    };
    self.modelAsJSON = function() {
        var jsData = this.modelAsJS();

        return jsData ? JSON.stringify(jsData) : undefined;
    };

    self.displayErrors = function(errors) {
        var errorText =
            "<span class='label label-important'>Important</span><h4>There was an error while trying to save your changes.</h4>";

        $.each(errors, function (i, error) {
            errorText += "<p>Saving <b>" +  (error.name === 'activity' ? 'the activity context' : error.name) +
                "</b> threw the following error:<br><blockquote>" + error.error + "</blockquote></p>";
        });
        errorText += "<p>Any other changes should have been saved.</p>";
        bootbox.alert(errorText);
    };

    /**
     * Makes an ajax call to save any sections that have been modified. This includes the activity
     * itself and each output.
     *
     * Modified outputs are injected as a list into the activity object. If there is nothing to save
     * in the activity itself, then the root is an object that is empty except for the outputs list.
     *
     * NOTE that the model for each section must register itself to be included in this save.
     *
     * Validates the entire page before saving.
     */
    self.save = function () {

        var valid = self.validate();

        var jsData = self.modelAsJS();

        if (jsData === undefined) {
            alert("Nothing to save.");
            return;
        }

        // We can't allow an activity that failed validation to be marked as finished.
        if (!valid) {
            if (!jsData.progress || jsData.progress === 'finished') {
                jsData.progress = 'started';
                jsData.activityId = jsData.activityId || self.activityData().activityId;
            }
        }

        // Don't allow another save to be initiated.
        blockUIWithMessage("Saving activity data...");

        var toSave = JSON.stringify(jsData);
        var activityStorageKey = 'activity-'+options.activityId;
        amplify.store(activityStorageKey, toSave);
        $.ajax({
            url: options.activityUpdateUrl,
            type: 'POST',
            data: toSave,
            contentType: 'application/json',
            success: function (data) {
                var errorText = "";
                if (data.error || data.errors) {
                    self.displayErrors(data.errors || [data.error]);
                } else {
                    self.cancelAutosave();
                    self.dirtyFlag.reset();
                    blockUIWithMessage("Activity data saved.");
                    self.performSaveCallbacks(data);
                }
                amplify.store(activityStorageKey, null);
            },
            error: function (jqXHR, status, error) {

                // This is to detect a redirect to CAS response due to session timeout, which is not
                // 100% reliable using ajax (e.g. no network will give the same response).
                if (jqXHR.readyState == 0) {

                    bootbox.alert($(options.timeoutMessageSelector).html());
                }
                else {
                    self.displayErrors(['An unhandled error occurred: ' + error]);
                }

            },
            complete: function () {
                $.unblockUI();

                if (!valid) {
                    var message = 'Your changes have been saved and you can remain in this activity form, or you can exit this page without losing data. Please note that you cannot mark this activitiy as finished until all mandatory fields have been completed though.';
                    bootbox.alert(message, function() {
                        self.validate();
                    });
                }
                else {
                    showAlert("Your data has been saved.  Please select one of the the navigation options below to continue.", "alert-info", 'saved-nav-message-holder');
                    $("html, body").animate({
                        scrollTop: $(options.savedNavMessageSelector).offset().top + 'px'
                    });
                    var $nav = $(options.activityNavSelector);

                    var oldBorder = $nav.css('border');
                    $nav.css('border', '2px solid black');
                    setTimeout(function() {
                        $nav.css('border', oldBorder);
                    }, 5000);
                }
            }
        });


    };

    self.performSaveCallbacks = function(saveResponse) {
        if (saveResponse) {
            $.each(this.subscribers, function(i, obj) {
                if (obj.saveCallback) {
                    obj.saveCallback(saveResponse);
                }
            });
        }
    };

    autoSaveModel(self, null, {preventNavigationIfDirty:true});
};


function ActivityHeaderViewModel (act, site, project, metaModel, themes, config) {
    var self = this;

    var defaults = {
        projectViewUrl:fcConfig.projectViewUrl,
        siteViewUrl:fcConfig.siteViewUrl,
        featureServiceUrl:fcConfig.featureServiceUrl,
        wmsServerUrl:fcConfig.wmsServerUrl
    };
    var options = _.extend({}, defaults, config);

    var mapInitialised = false;
    self.activityId = act.activityId;
    self.description = ko.observable(act.description);
    self.notes = ko.observable(act.notes);
    self.startDate = ko.observable(act.startDate).extend({simpleDate: false});
    self.endDate = ko.observable(act.endDate || act.plannedEndDate).extend({simpleDate: false});
    self.plannedStartDate = ko.observable(act.plannedStartDate).extend({simpleDate: false});
    self.plannedEndDate = ko.observable(act.plannedEndDate).extend({simpleDate: false});
    self.projectStage = ko.observable(act.projectStage || "");
    self.progress = ko.observable(act.progress);
    self.mainTheme = ko.observable(act.mainTheme);
    self.type = ko.observable(act.type);
    self.projectId = act.projectId;
    self.transients = {};
    self.transients.site = ko.observable(site);
    self.transients.project = project;
    self.transients.outputs = [];
    self.transients.metaModel = metaModel || {};
    self.transients.activityProgressValues = ['planned','started','finished'];
    self.transients.themes = $.map(themes, function (obj, i) { return obj.name });
    self.transients.markedAsFinished = ko.observable(act.progress === 'finished');
    self.transients.markedAsFinished.subscribe(function (finished) {
        self.progress(finished ? 'finished' : 'started');
    });

    self.confirmSiteChange = function() {

        if (metaModel.supportsSites && metaModel.supportsPhotoPoints && self.transients.photoPointModel().dirtyFlag.isDirty()) {
            return window.confirm(
                "This activity has photos attached to photo points.\n  Changing the site will delete these photos.\n  This cannot be undone.  Are you sure?"
            );
        }
        return true;
    };
    self.siteId = ko.vetoableObservable(act.siteId, self.confirmSiteChange);

    self.siteId.subscribe(function(siteId) {

        var matchingSite = $.grep(self.transients.project.sites, function(site) { return siteId == site.siteId})[0];

        if (mapInitialised) {
            alaMap.clearFeatures();
            if (matchingSite) {
                alaMap.replaceAllFeatures([matchingSite.extent.geometry]);
            }
            self.transients.site(matchingSite);
            if (metaModel.supportsPhotoPoints) {
                self.updatePhotoPointModel(matchingSite);
            }
        }
    });
    self.goToProject = function () {
        if (self.projectId) {
            document.location.href = options.projectViewUrl + self.projectId;
        }
    };
    self.goToSite = function () {
        if (self.siteId()) {
            document.location.href = options.siteViewUrl + self.siteId();
        }
    };

    if (metaModel.supportsPhotoPoints) {
        self.transients.photoPointModel = ko.observable(new PhotoPointViewModel(site, activity));
        self.updatePhotoPointModel = function(site) {
            self.transients.photoPointModel(new PhotoPointViewModel(site, activity));
        };
    }

    self.modelForSaving = function (valid) {
        // get model as a plain javascript object
        var jsData = ko.mapping.toJS(self, {'ignore':['transients', 'dirtyFlag']});
        if (metaModel.supportsPhotoPoints) {
            jsData.photoPoints = self.transients.photoPointModel().modelForSaving();
        }
        // If we leave the site or theme undefined, it will be ignored during JSON serialisation and hence
        // will not overwrite the current value on the server.
        var possiblyUndefinedProperties = ['siteId', 'mainTheme'];

        $.each(possiblyUndefinedProperties, function(i, propertyName) {
            if (jsData[propertyName] === undefined) {
                jsData[propertyName] = '';
            }
        });
        return jsData;
    };
    self.modelAsJSON = function () {
        return JSON.stringify(self.modelForSaving());
    };

    self.selfDirtyFlag = ko.dirtyFlag(self, false);

    // make sure progress moves to started if we save any data (unless already finished)
    // (do this here so the model becomes dirty)
    self.progress(self.transients.markedAsFinished() ? 'finished' : 'started');

    self.initialiseMap = function(mapFeatures) {
        if (metaModel.type !== 'Report' && metaModel.supportsSites) {
            if (!mapFeatures) {
                mapFeatures = {zoomToBounds: true, zoomLimit: 15, highlightOnHover: true, features: []};
            }
            init_map_with_features({
                    mapContainer: "smallMap",
                    zoomToBounds:true,
                    zoomLimit:16,
                    featureService: options.featureServiceUrl,
                    wmsServer: options.wmsServerUrl
                },
                mapFeatures
            );
            mapInitialised = true;
        }
    };

    self.updateIdsAfterSave = function(saveResult) {
        if (metaModel.supportsPhotoPoints) {
            self.transients.photoPointModel().updatePhotoPointDocumentIds(saveResult.photoPoints);

        }
    };

    /**
     *  Takes into account changes to the photo point photo's as the default knockout dependency
     *  detection misses edits to some of the fields.
     */
    self.dirtyFlag = {
        isDirty: ko.computed(function() {
            var dirty = self.selfDirtyFlag.isDirty();
            if (!dirty && metaModel.supportsPhotoPoints) {
                dirty = self.transients.photoPointModel().dirtyFlag.isDirty();
            }
            return dirty;
        }),
        reset: function() {
            self.selfDirtyFlag.reset();
            if (metaModel.supportsPhotoPoints) {
                self.transients.photoPointModel().dirtyFlag.reset();
            }
        }
    };
};

initialiseOutputViewModel = function(outputViewModelName, dataModel, elementId, activity, output, master, config) {
    var viewModelInstance = outputViewModelName + 'Instance';

    var context = {
        project:fcConfig.project,
        activity:activity,
        documents:activity.documents,
        site:activity.site
    };
    ecodata.forms[viewModelInstance] = new ecodata.forms[outputViewModelName](output, dataModel, context, config);
    ecodata.forms[viewModelInstance].loadData(output.data);

    // dirtyFlag must be defined after data is loaded
    ecodata.forms[viewModelInstance].dirtyFlag = ko.simpleDirtyFlag(ecodata.forms[viewModelInstance], false);

    ko.applyBindings(ecodata.forms[viewModelInstance], document.getElementById(elementId));

    // this resets the baseline for detecting changes to the model
    // - shouldn't be required if everything behaves itself but acts as a backup for
    //   any binding side-effects
    // - note that it is not foolproof as applying the bindings happens asynchronously and there
    //   is no easy way to detect its completion
    ecodata.forms[viewModelInstance].dirtyFlag.reset();

    // register with the master controller so this model can participate in the save cycle
    master.register(ecodata.forms[viewModelInstance], ecodata.forms[viewModelInstance].modelForSaving,
        ecodata.forms[viewModelInstance].dirtyFlag.isDirty, ecodata.forms[viewModelInstance].dirtyFlag.reset);

    // Check for locally saved data for this output - this will happen in the event of a session timeout
    // for example.
    var savedData = amplify.store('activity-' + activity.activityId);
    var savedOutput = null;
    if (savedData) {
        var outputData = $.parseJSON(savedData);
        if (outputData.outputs) {
            $.each(outputData.outputs, function (i, tmpOutput) {
                if (tmpOutput.name === output.name) {
                    if (tmpOutput.data) {
                        savedOutput = tmpOutput.data;
                    }
                }
            });
        }
    }
    if (savedOutput) {
        ecodata.forms[viewModelInstance].loadData(savedOutput);
    }
};