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

    <script type="text/javascript" src="//cdnjs.cloudflare.com/ajax/libs/jstimezonedetect/1.0.4/jstz.min.js"></script>
    <r:script disposition="head">
    var fcConfig = {
        serverUrl: "${grailsApplication.config.grails.serverURL}",
        activityUpdateUrl: "${createLink(controller: 'activity', action: 'ajaxUpdate')}",
        activityDeleteUrl: "${createLink(controller: 'activity', action: 'ajaxDelete')}",
        projectViewUrl: "${createLink(controller: 'project', action: 'index')}/",
        siteViewUrl: "${createLink(controller: 'site', action: 'index')}/"
        },
        here = document.location.href;
    </r:script>
    <r:require modules="knockout,jqueryValidationEngine,datepicker,jQueryImageUpload"/>
</head>
<body>
<div class="container-fluid validationEngineContainer" id="validation-container">
  <div id="koActivityMainBlock">
      <g:if test="${!printView}">
          <ul class="breadcrumb">
                <li><g:link controller="home">Home</g:link> <span class="divider">/</span></li>
                <li>Activities<span class="divider">/</span></li>
                <li class="active">
                    <span data-bind="text:type"></span>
                    <span data-bind="text:startDate.formattedDate"></span>/<span data-bind="text:endDate.formattedDate"></span>
                </li>
          </ul>
      </g:if>

        <div class="row-fluid title-block well well-small input-block-level">
            <div class="span12 title-attribute">
                <h1><span data-bind="click:goToProject" class="clickable">${project?.name ?: 'no project defined!!'}</span></h1>
                <g:if test="${site}">
                    <h2><span data-bind="click:goToSite" class="clickable">Site: ${site.name}</span></h2>
                </g:if>
                <g:else>
                    <select data-bind="options:transients.sites,optionsText:'name',optionsValue:'siteId',value:siteId,optionsCaption:'Choose a site...'"></select>
                </g:else>
                <h3>Activity: <span data-bind="text:type"></span></h3>
            </div>
        </div>

        <div class="row-fluid">
            <div class="span6">
                <fc:textArea data-bind="value: description" id="description" label="Description" class="span12" rows="3" />
            </div>
            <div class="span6">
                <fc:textArea data-bind="value: notes" id="notes" label="Notes" class="span12" rows="3" />
            </div>
        </div>

        <div class="row-fluid">
            <div class="span4 control-group">
                <label for="startDate">Start date
                <fc:iconHelp title="Start date">Date the activity was started.</fc:iconHelp>
                </label>
                <div class="input-append">
                    <fc:datePicker targetField="startDate.date" name="startDate" data-validation-engine="validate[required]" printable="${printView}"/>
                </div>
            </div>
            <div class="span4">
                <label for="endDate">End date
                <fc:iconHelp title="End date">Date the activity finished.</fc:iconHelp>
                </label>
                <div class="input-append">
                    <fc:datePicker targetField="endDate.date" name="endDate" data-validation-engine="validate[future[startDate]]" printable="${printView}" />
                </div>
            </div>
            <div class="span4">
                <label for="censusMethod">Method</label>
                <input data-bind="value: censusMethod" id="censusMethod" type="text" class="span12"/>
            </div>
        </div>

        <g:if test="${!printView}">
            <div class="well well-small">
                <h4>Old-style edit pages (while we transition to one-page editing)</h4>
                <ul class="unstyled">
                    <g:each in="${metaModel?.outputs}" var="output">
                        <g:set var="data" value="${activity.outputs.find({it.name == output})}"/>
                        <li class="row-fluid">
                            <span class="span4">${output}</span>
                            <g:if test="${data}">
                                <span class="span4"><a type="button" class="btn"
                                 href="${createLink(controller: 'output', action:'edit', id: data.outputId)}">Edit data</a></span>
                            </g:if>
                            <g:else>
                                <span class="span4"><a type="button" class="btn"
                                 href="${createLink(controller: 'output', action:'create')}?activityId=${activity.activityId}&outputName=${output}">Add data</a></span>
                            </g:else>
                        </li>
                    </g:each>
                </ul>
            %{--<ul class="unstyled" data-bind="foreach:transients.metaModel.outputs">
                <li class="row-fluid">
                    <span class="span4" data-bind="text:$data"></span>
                    <span class="span4"><a data-bind="editOutput:$data">Add data</a></span>
                </li>
            </ul>--}%
            </div>

          <div class="expandable-debug">
              <hr />
              <h3>Debug</h3>
              <div>
                  <h4>KO model</h4>
                  <pre data-bind="text:ko.toJSON($root,null,2)"></pre>
                  <h4>Activity</h4>
                  <pre>${activity}</pre>
                  <h4>Site</h4>
                  <pre>${site}</pre>
                  <h4>Sites</h4>
                  <pre>${(sites as JSON).toString()}</pre>
                  <h4>Project</h4>
                  <pre>${project}</pre>
                  <h4>Activity model</h4>
                  <pre>${metaModel}</pre>
                  <h4>Output models</h4>
                  <pre>${outputModels}</pre>
              </div>
          </div>
        </g:if>
    </div>

    <g:each in="${metaModel?.outputs}" var="outputName">
        <g:set var="blockId" value="${fc.toSingleWord([name: outputName])}"/>
        <g:set var="model" value="${outputModels[outputName]}"/>
        <g:set var="output" value="${activity.outputs.find {it.name == outputName}}"/>
        <g:if test="${!output}">
            <g:set var="output" value="[activityId: activity.activityId, name: outputName]"/>
        </g:if>
        <div class="output-block" id="ko${blockId}">
            <h3>${outputName}</h3>
            <!-- add the dynamic components -->
            <md:modelView model="${model}" site="${site}" edit="true"/>
    <r:script>
        $(function(){

            var viewModelName = "${blockId}ViewModel",
                viewModelInstance = viewModelName + "Instance",
                output = {name: 'test', assessmentDate: '', collector: ''};

            // load dynamic models - usually objects in a list
            <md:jsModelObjects model="${model}" site="${site}" speciesLists="${speciesLists}" edit="true" viewModelInstance="${blockId}ViewModelInstance"/>

            this[viewModelName] = function () {
                var self = this;
                self.name = "${output.name}";
                self.assessmentDate = ko.observable("${output.assessmentDate}").extend({simpleDate: false});
                self.collector = ko.observable("${output.collector}")/*.extend({ required: true })*/;
                self.activityId = ko.observable("${activity.activityId}");
                self.activityType = ko.observable("${activity.type}");
                self.deleteAll = function () {
                    document.location.href = "${createLink(action:'delete',id:output.outputId,
                        params:[returnTo:grailsApplication.config.grails.serverURL + '/' + returnTo])}";
                };
                self.data = {};
                self.transients = {};
                self.transients.dummy = ko.observable();
                self.transients.activityStartDate = ko.observable("${activity.startDate}").extend({simpleDate: false});
                self.transients.activityEndDate = ko.observable("${activity.endDate}").extend({simpleDate: false});

                // add declarations for dynamic data
                <md:jsViewModel model="${model}" edit="true" viewModelInstance="${blockId}ViewModelInstance"/>

                // this will be called from the save method to remove transient properties
                self.removeBeforeSave = function (jsData) {
                    // add code to remove any transients added by the dynamic tags
                    <md:jsRemoveBeforeSave model="${model}"/>
                    delete jsData.activityType;
                    delete jsData.transients;
                    return jsData;
                };
                self.save = function () {
                    if ($('#form').validationEngine('validate')) {
                        var jsData = ko.toJS(self);
                        // get rid of any transient observables
                        jsData = self.removeBeforeSave(jsData);
                        var json = JSON.stringify(jsData);
                        $.ajax({
                            url: '${createLink(action: "ajaxUpdate", id: "${output.outputId}")}',
                            type: 'POST',
                            data: json,
                            contentType: 'application/json',
                            success: function (data) {
                                if (data.error) {
                                    alert(data.detail + ' \n' + data.error);
                                } else {
                                    document.location.href = returnTo;
                                }
                            },
                            error: function (data) {
                                var status = data.status
                                alert('An unhandled error occurred: ' + data.status);
                            }
                        });
                    }
                };
                self.notImplemented = function () {
                    alert("Not implemented yet.")
                };
                self.loadData = function (data) {
                    // load dynamic data
                    <md:jsLoadModel model="${model}"/>

                    // if there is no data in tables then add an empty row for the user to add data
                    if (typeof self.addRow === 'function' && self.rowCount() === 0) {
                        self.addRow();
                    }
                    self.transients.dummy.notifySubscribers();
                    };
                };

                window[viewModelInstance] = new this[viewModelName]();
                window[viewModelInstance].loadData(${output.data ?: '{}'});

            ko.applyBindings(window[viewModelInstance], document.getElementById("ko${blockId}"));

        });

            </r:script>
        </div>
    </g:each>

    <div class="form-actions">
        <button type="button" id="save" class="btn btn-primary">Save changes</button>
        <button type="button" id="cancel" class="btn">Cancel</button>
    </div>

</div>

<!-- templates -->

<r:script>

    var returnTo = "${returnTo}";

    $(function(){

        $('#validation-container').validationEngine('attach', {scroll: false});

        $('.helphover').popover({animation: true, trigger:'hover'});

        $('#save').click(function () {
            viewModel.save();
        });

        $('#cancel').click(function () {
            document.location.href = returnTo;
        });

        $('.edit-btn').click(function () {
            var data = ${activity.outputs},
                outputName = $(this).parent().previous().html(),
                outputId;
            // search for corresponding outputs in the activity data
            $.each(data, function (i,output) { // iterate output data in the activity to
                                               // find any matching the meta-model name
                if (output.name === outputName) {
                    outputId = output.outputId;
                }
            });
            if (outputId) {
                // build edit link
                document.location.href = fcConfig.serverUrl + "/output/edit/" + outputId +
                    "?returnTo=" + here;
            } else {
                // build create link
                document.location.href = fcConfig.serverUrl + "/output/create?activityId=${activity.activityId}" +
                    '&outputName=' + encodeURIComponent(outputName) +
                    "&returnTo=" + here;
            }

        });

        ko.bindingHandlers.editOutput = {
            init: function(element, valueAccessor, allBindingsAccessor, viewModel, bindingContext) {
                var outputName = ko.utils.unwrapObservable(valueAccessor()),
                    activity = bindingContext.$root,
                    outputId;

                // search for corresponding outputs in the activity data
                $.each(activity.outputs, function (i,output) { // iterate output data in the activity to
                                                                  // find any matching the meta-model name
                    if (output.name === outputName) {
                        outputId = output.outputId;
                    }
                });
                if (outputId) {
                    // build edit link
                    $(element).html('Edit data');
                    $(element).attr('href', fcConfig.serverUrl + "/output/edit/" + outputId +
                        "?returnTo=" + here);
                } else {
                    // build create link
                    $(element).attr('href', fcConfig.serverUrl + '/output/create?activityId=' + activity.activityId +
                        '&outputName=' + encodeURIComponent(outputName) +
                        "&returnTo=" + here);
                }
            }
        };

        function ViewModel (act, site, project, metaModel) {
            var self = this;
            self.activityId = act.activityId;
            self.description = ko.observable(act.description);
            self.notes = ko.observable(act.notes);
            self.startDate = ko.observable(act.startDate).extend({simpleDate: false});
            self.endDate = ko.observable(act.endDate).extend({simpleDate: false});
            self.censusMethod = ko.observable(act.censusMethod);
            self.methodAccuracy = ko.observable(act.methodAccuracy);
            self.collector = ko.observable(act.collector);
            self.fieldNotes = ko.observable(act.fieldNotes);
            self.type = ko.observable(act.type);
            self.siteId = ko.observable(act.siteId);
            self.projectId = act.projectId;
            self.outputs = act.outputs;
            self.transients = {};
            self.transients.site = site;
            self.transients.project = project;
            self.transients.metaModel = metaModel || {};
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
            self.save = function () {
                if ($('#validation-container').validationEngine('validate')) {
                    var jsData = ko.toJS(self);
                    delete jsData.transients;
                    var json = JSON.stringify(jsData);
                    $.ajax({
                        url: "${createLink(action: 'ajaxUpdate', id: activity.activityId)}",
                        type: 'POST',
                        data: json,
                        contentType: 'application/json',
                        success: function (data) {
                            if (data.error) {
                                alert(data.detail + ' \n' + data.error);
                            } else {
                                document.location.href = returnTo;
                            }
                        },
                        error: function (data) {
                            var status = data.status;
                            alert('An unhandled error occurred: ' + data.status);
                        }
                    });
                }
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
        }

        var viewModel = new ViewModel(
            ${(activity as JSON).toString()},
            ${site ?: 'null'},
            ${project ?: 'null'},
            ${metaModel ?: 'null'});
        ko.applyBindings(viewModel,document.getElementById('koActivityMainBlock'));

    });

</r:script>
</body>
</html>