<%@ page import="grails.converters.JSON; org.codehaus.groovy.grails.web.json.JSONArray" contentType="text/html;charset=UTF-8" %>
<!DOCTYPE html>
<html xmlns="http://www.w3.org/1999/html">
<head>
    <g:if test="${printView}">
        <meta name="layout" content="nrmPrint"/>
        <title>Print | ${activity.type} | Field Capture</title>
    </g:if>
    <g:else>
        <meta name="layout" content="${grailsApplication.config.layout.skin?:'main'}"/>
        <title>Edit | ${activity.type} | Field Capture</title>
    </g:else>

    <script type="text/javascript" src="${grailsApplication.config.google.maps.url}"></script>
    <script type="text/javascript" src="//cdnjs.cloudflare.com/ajax/libs/jstimezonedetect/1.0.4/jstz.min.js"></script>
    <r:script disposition="head">
    var fcConfig = {
        serverUrl: "${grailsApplication.config.grails.serverURL}",
        activityUpdateUrl: "${createLink(controller: 'activity', action: 'ajaxUpdate')}",
        activityDeleteUrl: "${createLink(controller: 'activity', action: 'ajaxDelete')}",
        projectViewUrl: "${createLink(controller: 'project', action: 'index')}/",
        siteViewUrl: "${createLink(controller: 'site', action: 'index')}/",
        bieUrl: "${grailsApplication.config.bie.baseURL}",
        speciesProfileUrl: "${createLink(controller: 'proxy', action: 'speciesProfile')}",
        documentUpdateUrl: "${g.createLink(controller:"document", action:"documentUpdate")}",
        documentDeleteUrl: "${g.createLink(controller:"document", action:"deleteDocument")}",
        imageUploadUrl: "${createLink(controller: 'image', action: 'upload')}",
        imageLocation:"${resource(dir:'/images')}"
        },
        here = document.location.href;
    </r:script>
    <r:require modules="knockout,jqueryValidationEngine,datepicker,jQueryFileUploadUI,activity,mapWithFeatures,attachDocuments,species,amplify,imageViewer"/>
</head>
<body>
<div class="${containerType} validationEngineContainer" id="validation-container">
<div id="koActivityMainBlock">
    <g:if test="${!printView}">
        <ul class="breadcrumb">
            <li><g:link controller="home">Home</g:link> <span class="divider">/</span></li>
            <li><a data-bind="click:goToProject" class="clickable">Project</a> <span class="divider">/</span></li>
            <li class="active">
                <span data-bind="text:type"></span>
            </li>
        </ul>
    </g:if>

    <div data-bind="template: {name:headerTemplate, afterRender:initialiseMap}">

    </div>

    <g:if env="development" test="${!printView}">
        <div class="expandable-debug">
            <hr />
            <h3>Debug</h3>
            <div>
                <h4>KO model</h4>
                <pre data-bind="text:ko.toJSON($root.modelForSaving(),null,2)"></pre>
                <h4>Activity</h4>
                <pre>${activity?.encodeAsHTML()}</pre>
                <h4>Site</h4>
                <pre>${site?.encodeAsHTML()}</pre>
                <h4>Sites</h4>
                <pre>${(sites as JSON).toString()}</pre>
                <h4>Project</h4>
                <pre>${project?.encodeAsHTML()}</pre>
                <h4>Activity model</h4>
                <pre>${metaModel}</pre>
                <h4>Output models</h4>
                <pre>${outputModels?.encodeAsHTML()}</pre>
                <h4>Themes</h4>
                <pre>${themes.toString()}</pre>
                <h4>Map features</h4>
                <pre>${mapFeatures.toString()}</pre>
            </div>
        </div>
    </g:if>
</div>

<script type="text/html" id="activityHeader">

    <div class="row-fluid title-block well well-small input-block-level">
        <div class="span12 title-attribute">
            <h1><span data-bind="click:goToProject" class="clickable">${project?.name?.encodeAsHTML() ?: 'no project defined!!'}</span></h1>
            <g:if test="${metaModel.supportsSites}">
            <div class="row-fluid">
                <div class="span1">
                    Site:
                </div>
                <div class="span8">
                    <fc:select data-bind='options:transients.project.sites,optionsText:"name",optionsValue:"siteId",value:siteId,optionsCaption:"Choose a site..."' printable="${printView}"/>
                    Leave blank if this activity is not associated with a specific site.
                </div>
            </div>
            </g:if>
            <h3 data-bind="css:{modified:dirtyFlag.isDirty},attr:{title:'Has been modified'}">Activity: <span data-bind="text:type"></span></h3>
            <h4><span>${project.associatedProgram?.encodeAsHTML()}</span> <span>${project.associatedSubProgram?.encodeAsHTML()}</span></h4>
        </div>
    </div>


    <div class="row-fluid">
        <div class="span9">
            <!-- Common activity fields -->

            <div class="row-fluid space-after">
                <div class="span6">
                    <label for="theme">Major theme</label>
                    <select id="theme" data-bind="value:mainTheme, options:transients.themes, optionsCaption:'Choose..'" class="input-xlarge">
                    </select>
                </div>
                <div class="span6">
                    <label class="for-readonly">Description</label>
                    <span class="readonly-text" data-bind="text:description"></span>
                </div>
            </div>

            <div class="row-fluid space-after">
                <div class="span6">
                    <label class="for-readonly inline">Project stage</label>
                    <span class="readonly-text" data-bind="text:projectStage"></span>
                </div>
                <div class="span6">
                    <label class="for-readonly inline">Activity progress</label>
                    <button type="button" class="btn btn-small"
                            data-bind="css: {'btn-warning':progress()=='planned','btn-success':progress()=='started','btn-info':progress()=='finished','btn-danger':progress()=='deferred','btn-inverse':progress()=='cancelled'}"
                            style="line-height:16px;cursor:default;color:white">
                        <span data-bind="text: progress"></span>
                    </button>
                </div>
            </div>

            <div class="row-fluid space-after">
                <div class="span6">
                    <label class="for-readonly inline">Planned start date</label>
                    <span class="readonly-text" data-bind="text:plannedStartDate.formattedDate"></span>
                </div>
                <div class="span6">
                    <label class="for-readonly inline">Planned end date</label>
                    <span class="readonly-text" data-bind="text:plannedEndDate.formattedDate"></span>
                </div>
            </div>

            <div class="row-fluid">
                <div class="span6 required">
                    <label for="startDate"><b>Actual start date</b>
                        <fc:iconHelp title="Start date" printable="${printView}">Date the activity was started.</fc:iconHelp>
                    </label>
                    <g:if test="${printView}">
                        <div class="row-fluid">
                            <fc:datePicker targetField="startDate.date" name="startDate" data-validation-engine="validate[required,funcCall[validateDateField]]" printable="${printView}"/>
                        </div>
                    </g:if>
                    <g:else>
                        <div class="input-append">
                            <fc:datePicker targetField="startDate.date" name="startDate" data-validation-engine="validate[required,funcCall[validateDateField]]" printable="${printView}"/>
                        </div>
                    </g:else>
                </div>
                <div class="span6 required">
                    <label for="endDate"><b>Actual end date</b>
                        <fc:iconHelp title="End date" printable="${printView}">Date the activity finished.</fc:iconHelp>
                    </label>
                    <g:if test="${printView}">
                        <div class="row-fluid">
                            <fc:datePicker targetField="endDate.date" name="endDate" data-validation-engine="validate[future[startDate]]" printable="${printView}" />
                        </div>
                    </g:if>
                    <g:else>
                        <div class="input-append">
                            <fc:datePicker targetField="endDate.date" name="endDate" data-validation-engine="validate[future[startDate]]" printable="${printView}" />
                        </div>
                    </g:else>
                </div>
            </div>


        </div>

        <div class="span3">
            <div id="smallMap" style="width:100%"></div>
        </div>

    </div>
</script>
<script type="text/html" id="reportHeader">
<div class="row-fluid title-block well well-small input-block-level">
    <div class="span12 title-attribute">
        <h1><span data-bind="click:goToProject" class="clickable">${project?.name?.encodeAsHTML() ?: 'no project defined!!'}</span></h1>
        <h3 data-bind="css:{modified:dirtyFlag.isDirty},attr:{title:'Has been modified'}">Activity: <span data-bind="text:type"></span></h3>
        <h4><span>${project.associatedProgram?.encodeAsHTML()}</span> <span>${project.associatedSubProgram?.encodeAsHTML()}</span></h4>
        <h4>Report period from <span data-bind="text:plannedStartDate.formattedDate"></span> to <span data-bind="text:plannedEndDate.formattedDate"></span> </h4>
    </div>
</div>

</script>
<!-- ko stopBinding: true -->
<g:each in="${metaModel?.outputs}" var="outputName">
    <g:if test="${outputName != 'Photo Points'}">
    <g:set var="blockId" value="${fc.toSingleWord([name: outputName])}"/>
    <g:set var="model" value="${outputModels[outputName]}"/>
    <g:set var="output" value="${activity.outputs.find {it.name == outputName}}"/>
    <g:if test="${!output}">
        <g:set var="output" value="[name: outputName]"/>
    </g:if>
    <md:modelStyles model="${model}" edit="true"/>
    <div class="output-block" id="ko${blockId}">
        <h3 data-bind="css:{modified:dirtyFlag.isDirty},attr:{title:'Has been modified'}">${outputName}</h3>
        <div data-bind="if:transients.optional || outputNotCompleted()">
            <label class="checkbox" ><input type="checkbox" data-bind="checked:outputNotCompleted"> <span data-bind="text:transients.questionText"></span> </label>
        </div>
        <div id="${blockId}-content" data-bind="visible:!outputNotCompleted()">
            <!-- add the dynamic components -->
            <md:modelView model="${model}" site="${site}" edit="true" output="${output.name}" printable="${printView}" />
        </div>
        <g:render template="/output/outputJSModel" plugin="fieldcapture-plugin" model="${[viewModelInstance:blockId+'ViewModel', edit:true, activityId:activity.activityId, model:model, outputName:output.name]}"></g:render>

        <r:script>
        $(function(){

            var viewModelName = "${blockId}ViewModel",
                viewModelInstance = viewModelName + "Instance";

            var output = <fc:modelAsJavascript model="${output}"/>;
            var config = ${fc.modelAsJavascript(model:metaModel.outputConfig?.find{it.outputName == outputName}, default:'{}')};

            window[viewModelInstance] = new window[viewModelName](output, site, config);
            window[viewModelInstance].loadData(output.data || {}, activity.documents);

            // dirtyFlag must be defined after data is loaded
            window[viewModelInstance].dirtyFlag = ko.simpleDirtyFlag(window[viewModelInstance], false);

            ko.applyBindings(window[viewModelInstance], document.getElementById("ko${blockId}"));

            // this resets the baseline for detecting changes to the model
            // - shouldn't be required if everything behaves itself but acts as a backup for
            //   any binding side-effects
            // - note that it is not foolproof as applying the bindings happens asynchronously and there
            //   is no easy way to detect its completion
            window[viewModelInstance].dirtyFlag.reset();

            // register with the master controller so this model can participate in the save cycle
            master.register(window[viewModelInstance], window[viewModelInstance].modelForSaving,
                    window[viewModelInstance].dirtyFlag.isDirty, window[viewModelInstance].dirtyFlag.reset);

            // Check for locally saved data for this output - this will happen in the event of a session timeout
            // for example.
            var savedData = amplify.store('activity-${activity.activityId}');
            var savedOutput = null;
            if (savedData) {
                var outputData = $.parseJSON(savedData);
                if (outputData.outputs) {
                    $.each(outputData.outputs, function(i, tmpOutput) {
                        if (tmpOutput.name === '${output.name}') {
                            if (tmpOutput.data) {
                                savedOutput = tmpOutput.data;
                            }
                        }
                    });
                }
            }
            if (savedOutput) {
                window[viewModelInstance].loadData(savedOutput);
            }
        });

        </r:script>
    </div>
        </g:if>
</g:each>
<!-- /ko -->

    <g:if test="${metaModel.supportsPhotoPoints}">
    <div class="output-block" data-bind="with:transients.photoPointModel">
        <h3>Photo Points</h3>

         <g:render template="/site/photoPoints" plugin="fieldcapture-plugin"></g:render>

    </div>
    </g:if>
<g:if test="${!printView}">
    <div class="form-actions">
        <button type="button" id="save" class="btn btn-primary">Save changes</button>
        <button type="button" id="cancel" class="btn">Cancel</button>
        <label class="checkbox inline">
            <input data-bind="checked:transients.markedAsFinished" type="checkbox"> Mark this activity as finished.
        </label>
    </div>
</g:if>

</div>

<g:render template="/shared/timeoutMessage" plugin="fieldcapture-plugin" model="${[url:createLink(action:'enterData', id:activity.activityId, params: [returnTo:returnTo])]}"/>

<g:render template="/shared/imagerViewerModal" model="[readOnly:false]"></g:render>
<g:render template="/shared/documentTemplate" plugin="fieldcapture-plugin"></g:render>
<g:render template="/shared/imagerViewerModal"></g:render>

%{--The modal view containing the contents for a modal dialog used to attach a document--}%
<g:render template="/shared/attachDocument" plugin="fieldcapture-plugin"/>

<r:script>

    var returnTo = "${returnTo}";
    function validateDateField(dateField) {
        var date = stringToDate($(dateField).val());

        if (!isValidDate(date)) {
            return "Date must be in the format dd-MM-YYYY";
        };
    }

    /* Master controller for page. This handles saving each model as required. */
    var Master = function () {
        var self = this;
        this.subscribers = [];

        // client models register their name and methods to participate in saving
        self.register = function (modelInstanceName, getMethod, isDirtyMethod, resetMethod) {
            this.subscribers.push({
                model: modelInstanceName,
                get: getMethod,
                isDirty: isDirtyMethod,
                reset: resetMethod
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
        this.isDirty  = function () {
            var dirty = false;
            $.each(this.subscribers, function(i, obj) {
                dirty = dirty || obj.isDirty();
            });
            return dirty;
        };

        this.activityData = function() {
            var activityData = undefined;
            $.each(self.subscribers, function(i, obj) {
                if (obj.model == 'activityModel') {
                    activityData = obj.get();
                    return false;
                }
            });
            return activityData;
        };

        this.validate = function() {
            var valid = $('#validation-container').validationEngine('validate');
            if (valid) {
                // Check that forms with multiple optional sections have at least one of those sections completed.
                var optionalCount = 0;
                var notCompletedCount = 0;
                $.each(self.subscribers, function(i, obj) {
                    if (obj.model !== 'activityModel') {
                        if (obj.model.transients.optional) {
                            optionalCount++;
                            if (obj.model.outputNotCompleted()) {
                                notCompletedCount++;
                            }
                        }
                    }
                });
                if (optionalCount > 1 && notCompletedCount == optionalCount) {
                   valid = false;
                   bootbox.alert("<p>To 'Save changes', the mandatory fields of at least one section of this form must be completed.</p>"+
                        "<p>If all sections are 'Not applicable' please contact your grant manager to discuss alternate form options</p>");
                }
            }

            return valid;
        };

        this.modelAsJS = function() {
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

        }
        this.modelAsJSON = function() {
            var jsData = this.modelAsJS();

            return jsData ? JSON.stringify(jsData) : undefined;
        }

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
        this.save = function () {

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
            amplify.store('activity-${activity.activityId}', toSave);
            var unblock = true;
            $.ajax({
                url: "${createLink(action: 'ajaxUpdate', id: activity.activityId)}",
                type: 'POST',
                data: toSave,
                contentType: 'application/json',
                success: function (data) {
                    var errorText = "";
                    if (data.errors) {
                        errorText = "<span class='label label-important'>Important</span><h4>There was an error while trying to save your changes.</h4>";
                        $.each(data.errors, function (i, error) {
                            errorText += "<p>Saving <b>" +
(error.name === 'activity' ? 'the activity context' : error.name) +
"</b> threw the following error:<br><blockquote>" + error.error + "</blockquote></p>";
                        });
                        errorText += "<p>Any other changes should have been saved.</p>";
                        bootbox.alert(errorText);
                    } else {
                        self.cancelAutosave();
                        self.dirtyFlag.reset();
                        blockUIWithMessage("Activity data saved.")

                        if (valid) {
                            unblock = false; // We will be transitioning off this page.
                            self.saved();
                        }


                    }
                    amplify.store('activity-${activity.activityId}', null);
                },
                error: function (jqXHR, status, error) {

                    // This is to detect a redirect to CAS response due to session timeout, which is not
                    // 100% reliable using ajax (e.g. no network will give the same response).
                    if (jqXHR.readyState == 0) {

                        bootbox.alert($('#timeoutMessage').html());
                    }
                    else {
                        alert('An unhandled error occurred: ' + error);
                    }

                },
                complete: function () {
                    if (unblock) {
                        $.unblockUI();
                    }
                    if (!valid) {
                        var message = 'Your changes have been saved and you can remain in this activity form, or you can exit this page without losing data. Please note that you cannot mark this activitiy as finished until all mandatory fields have been completed though.';
                        bootbox.alert(message, function() {
                            self.validate();
                        });
                    }
                }
            });


        };
        this.saved = function () {
            document.location.href = returnTo;
        };
        autoSaveModel(self, null, {preventNavigationIfDirty:true});
    };

    var master = new Master();

    var activity = JSON.parse('${(activity as JSON).toString().encodeAsJavaScript()}');

    $(function(){

        $('#validation-container').validationEngine('attach', {scroll: true});

        $('.helphover').popover({animation: true, trigger:'hover'});

        $('#save').click(function () {
            master.save();
        });

        $('#cancel').click(function () {
            document.location.href = returnTo;
        });

        $('#reset').click(function () {
            master.reset();
        });

        function ViewModel (act, site, project, metaModel) {
            var self = this;
            var mapInitialised = false;
            self.activityId = act.activityId;
            self.description = ko.observable(act.description);
            self.notes = ko.observable(act.notes);
            self.startDate = ko.observable(act.startDate).extend({simpleDate: false});
            self.endDate = ko.observable(act.endDate || act.plannedEndDate).extend({simpleDate: false});
            self.plannedStartDate = ko.observable(act.plannedStartDate).extend({simpleDate: false});
            self.plannedEndDate = ko.observable(act.plannedEndDate).extend({simpleDate: false});
            self.eventPurpose = ko.observable(act.eventPurpose);
            self.fieldNotes = ko.observable(act.fieldNotes);
            self.associatedProgram = ko.observable(act.associatedProgram);
            self.associatedSubProgram = ko.observable(act.associatedSubProgram);
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
            self.transients.themes = $.map(${themes}, function (obj, i) { return obj.name });
            self.transients.markedAsFinished = ko.observable(act.progress === 'finished');
            self.transients.markedAsFinished.subscribe(function (finished) {
                self.progress(finished ? 'finished' : 'started');
            });
            self.headerTemplate = function(something) {
                if (metaModel.type === 'Report') {
                    return 'reportHeader';
                }
                return 'activityHeader';
            };

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
                    document.location.href = fcConfig.projectViewUrl + self.projectId;
                }
            };
            self.goToSite = function () {
                if (self.siteId()) {
                    document.location.href = fcConfig.siteViewUrl + self.siteId();
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

            self.save = function (callback, key) {
            };
            self.removeActivity = function () {
                bootbox.confirm("Delete this entire activity? Are you sure?", function(result) {
                    if (result) {
                        document.location.href = "${createLink(action:'delete',id:activity.activityId,
        params:[returnTo:grailsApplication.config.grails.serverURL + '/' + returnTo])}";
                    }
                });
            };
            self.notImplemented = function () {
                alert("Not implemented yet.")
            };

            self.selfDirtyFlag = ko.dirtyFlag(self, false);

            // make sure progress moves to started if we save any data (unless already finished)
            // (do this here so the model becomes dirty)
            self.progress(self.transients.markedAsFinished() ? 'finished' : 'started');

            self.initialiseMap = function() {
                if (metaModel.supportsSites) {
                    var mapFeatures = $.parseJSON('${mapFeatures?.encodeAsJavaScript()}');
                    if (!mapFeatures) {
                        mapFeatures = {zoomToBounds: true, zoomLimit: 15, highlightOnHover: true, features: []};
                    }
                    init_map_with_features({
                            mapContainer: "smallMap",
                            zoomToBounds:true,
                            zoomLimit:16,
                            featureService: "${createLink(controller: 'proxy', action: 'feature')}",
                            wmsServer: "${grailsApplication.config.spatial.geoserverUrl}"
                        },
                        mapFeatures
                    );
                    mapInitialised = true;
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

        var site = JSON.parse('${(site as JSON).toString().encodeAsJavaScript()}');
        var metaModel = ${metaModel};
        var viewModel = new ViewModel(
            activity,
            site,
            ${project ? "JSON.parse('${project.toString().encodeAsJavaScript()}')": 'null'},
            metaModel);

        ko.applyBindings(viewModel);
        // We need to reset the dirty flag after binding but doing so can miss a transition from planned -> started
        // as the "mark activity as finished" will have already updated the progress to started.
        if (activity.progress == viewModel.progress()) {
            viewModel.dirtyFlag.reset();
        }

    <g:if test="${params.progress}">
        var newProgress = '${params.progress}';
            viewModel.transients.markedAsFinished(newProgress == 'finished');
    </g:if>

        master.register('activityModel', viewModel.modelForSaving, viewModel.dirtyFlag.isDirty, viewModel.dirtyFlag.reset);
    });
</r:script>
</body>
</html>