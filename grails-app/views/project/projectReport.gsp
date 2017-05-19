<%@ page import="au.org.ala.fieldcapture.ActivityService; au.org.ala.fieldcapture.DateUtils" contentType="text/html;charset=UTF-8" %>
<!DOCTYPE html>
<html>
<head>
    <meta name="layout" content="${(grailsApplication.config.layout.skin?:'main')+'Print'}"/>
    <title>Project Summary | Project | MERIT</title>
    <script type="text/javascript" src="//www.google.com/jsapi"></script>
    <r:script disposition="head">
    var fcConfig = {
        serverUrl: "${grailsApplication.config.grails.serverURL}",
        siteViewUrl: "${createLink(controller: 'site', action: 'index')}",
        activityViewUrl: "${createLink(controller: 'activity', action: 'index')}",
        spatialBaseUrl: "${grailsApplication.config.spatial.baseUrl}",
        spatialWmsCacheUrl: "${grailsApplication.config.spatial.wms.cache.url}",
        spatialWmsUrl: "${grailsApplication.config.spatial.wms.url}",
        organisationLinkBaseUrl: "${createLink(controller:'organisation', action:'index')}",
        imageLocation:"${resource(dir:'/images')}",
        excelOutputTemplateUrl:"${createLink(controller: 'activity', action:'excelOutputTemplate')}",
        speciesProfileUrl: "${createLink(controller: 'species', action: 'speciesProfile')}",
        bieUrl: "${grailsApplication.config.bie.baseURL}",
        returnTo: "${createLink(controller: 'project', action: 'index', id: project.projectId)}"
    },
        here = window.location.href;

    </r:script>
    <style type="text/css">
        .title { font-weight: bold;}
        .activity-title {
            border-top: 4px solid black;
            background-color: #d9edf7;
            border-bottom: 1px solid;
            padding-bottom: 10px;
            margin-bottom: 10px;
        }
        .output-block > h3 {
            font-size:large;
        }
    .output-section.stage-title {
        padding:10px;
        border-top: 4px solid black;
    }
        tr, .chart, .chart-plus-title {
            page-break-inside: avoid;
        }

    </style>

    <r:require modules="knockout, activity, jqueryValidationEngine, merit_projects, pretty_text_diff,jQueryFileDownload,species"/>
</head>
<body>
<div class="container">


    <h1>Project Summary</h1>
    <g:if test="${params.fromStage == params.toStage}">
        <h3>${params.toStage}</h3>
    </g:if>
    <g:else>
        <h3>${params.fromStage} to ${params.toStage}</h3>
    </g:else>
    <h3></h3>

    <div class="overview">
        <div class="row-fluid">
            <div class="span3 title">Project Name</div>
            <div class="span9">${project.name}</div>
        </div>
        <div class="row-fluid">
            <div class="span3 title">Recipient</div>
            <div class="span9">${project.organisationName}</div>
        </div>
        <g:if test="${project.serviceProviderName}">
            <div class="row-fluid">
                <div class="span3 title">Service Provider</div>
                <div class="span9">${project.serviceProviderName}</div>
            </div>
        </g:if>
        <div class="row-fluid">
            <div class="span3 title">Funded by</div>
            <div class="span9">${project.associatedProgram} ${project.associatedSubProgram?:''}</div>
        </div>
        <div class="row-fluid">
            <div class="span3 title">Funding</div>
            <g:set var="funding" value="${(project.custom?.details?.budget?.overallTotal?:project.funding)}"/>
            <div class="span9">
                <g:if test="${funding}">
                    <g:formatNumber type="currency" number="${funding}"/>
                </g:if>
            </div>
        </div>
        <div class="row-fluid">
            <div class="span3 title">Project start</div>
            <div class="span9"><g:formatDate format="dd MMM yyyy" date="${au.org.ala.fieldcapture.DateUtils.parse(project.plannedStartDate).toDate()}"/></div>
        </div>
        <div class="row-fluid">
            <div class="span3 title">Project finish</div>
            <div class="span9"><g:formatDate format="dd MMM yyyy" date="${au.org.ala.fieldcapture.DateUtils.parse(project.plannedEndDate).toDate()}"/></div>
        </div>
        <div class="row-fluid">
            <div class="span3 title">Grant ID</div>
            <div class="span9">${project.grantId}</div>
        </div>
        <g:if test="${project.externalId}">
            <div class="row-fluid">
                <div class="span3 title">External ID</div>
                <div class="span9">${project.externalId}</div>
            </div>
        </g:if>


        <div class="row-fluid" id="report-status">
            <div class="span3 title">Current report status</div>
            <div class="span9" data-bind="text:currentStatus"></div>
        </div>

        <div class="row-fluid">
            <div class="span3 title">Summary generated</div>
            <div class="span9"><g:formatDate format="yyyy-MM-dd HH:mm:ss" date="${new Date()}"/></div>
        </div>
        <div class="row-fluid generated-by">
            <div class="span3 title">Summary generated by</div>
            <div class="span9"><fc:currentUserDisplayName></fc:currentUserDisplayName></div>
        </div>
        <div class="row-fluid">
            <div class="span3 title">Position / role:</div>
            <div class="span9">${role}</div>
        </div>
    </div>

    <h3>Project Overview</h3>
    <p>${project.description}</p>

    <g:if test="${images && ('Images' in content)}">
    <h3>Main project images</h3>

        <g:each in="${images}" var="image">
            <img src="${image.thumbnailUrl?:image.url}"/>
        </g:each>
    </g:if>

    <g:if test="${'Blog' in content && blog}">
        <g:if test="${blog.find{it.type == 'News and Events'}}">
            <h3>News & events</h3>
            <div class="blog-section">
                <g:render template="/shared/blog" model="${[blog:blog, type:'News and Events']}"/>
            </div>
        </g:if>

        <g:if test="${blog.find{it.type == 'Project Stories'}}">
            <div class="row-fluid">
                <h3>Project stories</h3>
                <div class="blog-section">
                    <g:render template="/shared/blog" model="${[blog:blog, type:'Project Stories']}"/>
                </div>
            </div>
        </g:if>
    </g:if>

    <g:if test="${'Activity status summary' in content}">
    <h3>Activity status summary</h3>

    <table class="table table-striped">
        <thead>
            <tr>
                <g:each in="${['', 'Planned', 'Started', 'Finished', 'Deferred', 'Cancelled']}" var="progress">
                    <th>${progress}</th>
                </g:each>
            </tr>
        </thead>
        <tbody>
            <g:each in="${orderedStageNames}" var="stage">
                <tr>
                    <th>${stage}</th>
                    <g:each in="${['Planned', 'Started', 'Finished', 'Deferred', 'Cancelled']}" var="progress">
                        <td>${activityCountByStage[stage][progress.toLowerCase()]?:0}</td>
                    </g:each>
                </tr>
            </g:each>

        </tbody>
    </table>
    </g:if>


    <g:if test="${outcomes && ('Project outcomes' in content)}">
    <h3>Project outcomes</h3>
    <table class="table table-striped">
        <thead>
        <tr>
            <th>Outcomes</th>
            <th>Assets Addressed</th>
        </tr>
        </thead>
        <tbody>
        <g:each in="${outcomes}" var="outcome">
            <tr>
                <td>${outcome.description}</td>
                <td>
                    <ul>
                    <g:each in="${outcome.assets}" var="asset">
                        <li>${asset}</li>
                    </g:each>
                    </ul>
                </td>
            </tr>
        </g:each>

        </tbody>
    </table>
    </g:if>

    <g:if test="${metrics.targets  && ('Progress against output targets' in content)}">
        <h3>Progress against output targets</h3>
        <p>Note this is the current project progress, not the progress made during the selected stage(s).</p>
        <div class="row-fluid dashboard">
            <div class="span4">
                <g:set var="count" value="${metrics.targets.size()}"/>
                <g:each in="${metrics.targets?.entrySet()}" var="metric" status="i">
                %{--This is to stack the output metrics in three columns, the ceil biases uneven amounts to the left--}%
                    <g:if test="${i == Math.ceil(count/3) || i == Math.ceil(count/3*2)}">
                        </div>
                        <div class="span4">
                    </g:if>
                    <div class="well">
                        <h3>${metric.key}</h3>
                        <g:each in="${metric.value}" var="score">
                            <fc:renderScore score="${score}" printable="${printable}"></fc:renderScore>
                        </g:each>
                    </div>
                </g:each>
            </div>
        </div>
    </g:if>
    <g:if test="${metrics.other  && ('Progress of outputs without targets' in content)}">
        <h3>Progress of outputs without targets</h3>
        <p>Note this is the current project progress, not the progress made during the selected stage(s).</p>
        <div class="outputs-without-targets dashboard">
            <g:each in="${metrics.other?.entrySet()}" var="metric" status="i">

                <div class="row-fluid well well-small">
                    <h3>${metric.key}</h3>
                    <g:each in="${metric.value}" var="score">
                                <fc:renderScore score="${score}" printable="${printable}"></fc:renderScore>


                    </g:each>
                </div><!-- /.well -->

            </g:each>
        </div>
    </g:if>

    <g:each in="${outputModels}" var="outputModel">
        <g:render template="/output/outputJSModel" plugin="fieldcapture-plugin"
                  model="${[model:outputModel.value, outputName:outputModel.key, edit:false, speciesLists:[], printable:printable]}"></g:render>
    </g:each>

    <g:if test="${latestStageReport && ('Stage report' in content)}">

        <h3>Stage report</h3>
        (${DateUtils.isoToDisplayFormat(latestStageReport.plannedStartDate)} - ${DateUtils.isoToDisplayFormat(latestStageReport.plannedEndDate)})
        <g:each in="${stageReportModel.outputs}" var="outputName">
            <g:render template="/output/readOnlyOutput"
                  model="${[divId:'latest-stage-report-'+outputName,
                            activity:latestStageReport,
                            outputModel:outputModels[outputName],
                            outputName:outputName,
                            activityModel:stageReportModel,
                            printable:printable]}"
                  plugin="fieldcapture-plugin"></g:render>
        </g:each>

    </g:if>

    <g:if test="${risksComparison.baseline?.rows && ('Project risks' in content)}">
    <h3>Project risks</h3>
    <p>Note this is the risk information as it appeared at the end of the selected stage(s).</p>
    <table class="table table-striped">
        <thead>
        <tr>
            <th>Type of threat / risk</th>
            <th>Description</th>
            <th>Likelihood</th>
            <th>Consequence</th>
            <th>Risk rating</th>
            <th>Current control / <br/>Contingency strategy</th>
            <th>Residual risk</th>
        </tr>
        </thead>
        <tbody>
        <g:each in="${risksComparison.baseline?.rows}" var="risk">
            <tr>
                <td>${risk.threat}</td>
                <td>${risk.description}</td>
                <td>${risk.likelihood}</td>
                <td>${risk.consequence}</td>
                <td>${risk.riskRating}</td>
                <td>${risk.currentControl}</td>
                <td>${risk.residualRisk}</td>
            </tr>
        </g:each>

        </tbody>
    </table>
    </g:if>

    <g:if test="${(risksComparison.baseline?.rows || risksComparison.comparison?.rows) && ('Project risks changes' in content)}">
        <h3>Project risks changes</h3>
        <g:if test="${risksComparison.comparison}">
            Comparing edit made on ${au.org.ala.fieldcapture.DateUtils.displayFormatWithTime(risksComparison.comparisonDate)}
            to edit made on ${au.org.ala.fieldcapture.DateUtils.displayFormatWithTime(risksComparison.baselineDate)}
        </g:if>
        <g:elseif test="${risksComparison.baseline}">
            Risks and threats first entered during the period of this report, last edited at: ${au.org.ala.fieldcapture.DateUtils.displayFormatWithTime(risksComparison.baselineDate)}
        </g:elseif>

        <table class="table table-striped risks-comparison">
            <thead>
            <tr>
                <th>Type of threat / risk</th>
                <th>Description</th>
                <th>Likelihood</th>
                <th>Consequence</th>
                <th>Risk rating</th>
                <th>Current control / <br/>Contingency strategy</th>
                <th>Residual risk</th>
            </tr>
            </thead>
            <tbody>
            <g:set var="max" value="${Math.max(risksComparison.baseline.rows.size(), risksComparison.comparison?.rows?.size()?:0)}"/>
            <g:each in="${(0..<max)}" var="i">
                <tr>
                    <td><fc:renderComparison changed="${risksComparison.baseline?.rows ?: []}" i="${i}" original="${risksComparison.comparison?.rows ?: []}" property="threat"/> </td>
                    <td><fc:renderComparison changed="${risksComparison.baseline?.rows ?: []}" i="${i}" original="${risksComparison.comparison?.rows ?: []}" property="description"/></td>
                    <td><fc:renderComparison changed="${risksComparison.baseline?.rows ?: []}" i="${i}" original="${risksComparison.comparison?.rows ?: []}" property="likelihood"/></td>
                    <td><fc:renderComparison changed="${risksComparison.baseline?.rows ?: []}" i="${i}" original="${risksComparison.comparison?.rows ?: []}" property="consequence"/></td>
                    <td><fc:renderComparison changed="${risksComparison.baseline?.rows ?: []}" i="${i}" original="${risksComparison.comparison?.rows ?: []}" property="riskRating"/></td>
                    <td><fc:renderComparison changed="${risksComparison.baseline?.rows ?: []}" i="${i}" original="${risksComparison.comparison?.rows ?: []}" property="currentControl"/></td>
                    <td><fc:renderComparison changed="${risksComparison.baseline?.rows ?: []}" i="${i}" original="${risksComparison.comparison?.rows ?: []}" property="residualRisk"/></td>
                </tr>
            </g:each>

            </tbody>
        </table>
    </g:if>


    <g:if test="${activitiesByStage && ('Progress against activities' in content)}">
        <h3>Progress against activities</h3>

        <g:each in="${orderedStageNames}" var="stage">
            <g:if test="${activitiesByStage[stage]}">
            <div class="output-section stage-title">
                <h3>${stage}</h3>
            </div>
            <g:each in="${activitiesByStage[stage]}" var="activity">
                <div class="activity-title">
                <h3>${activity.description ?: activity.type}</h3>
                </div>
                <div class="activity-header">
                    <div class="row-fluid">
                        <div class="span3 title">Activity type</div>
                        <div class="span9">${activity.type}</div>
                    </div>
                    <div class="row-fluid">
                        <div class="span3 title">Status</div>
                        <div class="span9">${activity.progress}</div>
                    </div>
                    <div class="row-fluid">
                        <div class="span3 title">Major theme</div>
                        <div class="span9">${activity.mainTheme}</div>
                    </div>
                    <div class="row-fluid">
                        <div class="span3 title">Start date</div>
                        <div class="span9">${DateUtils.isoToDisplayFormat(activity.startDate ?: activity.plannedStartDate)}</div>
                    </div>
                    <div class="row-fluid">
                        <div class="span3 title">End date</div>
                        <div class="span9">${DateUtils.isoToDisplayFormat(activity.endDate ?: activity.plannedEndDate)}</div>
                    </div>
                    <g:if test="${activity.reason}">
                        <div class="row-fluid">
                            <div class="span3 title">Reason</div>
                            <div class="span9">${activity.reason}</div>
                        </div>
                    </g:if>

                </div>
                <g:if test="${activity.progress == 'started' || activity.progress == 'finished'}">
                    <g:set var="activityModel" value="${activityModels.find{it.name == activity.type}}"/>
                    <g:each in="${activityModel.outputs}" var="outputName">
                        <g:if test="${outputName != 'Photo Points'}">
                            <g:render template="/output/readOnlyOutput"
                                      model="${[activity:activity,
                                                outputModel:outputModels[outputName],
                                                outputName:outputName,
                                                activityModel:activityModel]}"
                                      plugin="fieldcapture-plugin"></g:render>
                        </g:if>

                    </g:each>
                    <g:if test="${activityModel.supportsPhotoPoints}">
                        <div id="photopoints-${activity.activityId}" class="output-block">
                            <h3>Photo Points</h3>

                            <g:render template="/site/photoPoints" plugin="fieldcapture-plugin" model="${[readOnly:true]}"></g:render>

                        </div>
                        <r:script>
                            $(function() {
                                var activity = <fc:modelAsJavascript model="${activity}"></fc:modelAsJavascript>;
                                ko.applyBindings(new PhotoPointViewModel(activity.site, activity, {}), document.getElementById('photopoints-${activity.activityId}'));
                            });
                        </r:script>
                    </g:if>
                </g:if>
                <g:if test="${activity.progress == 'deferred' || activity.progress == 'cancelled'}">
                </g:if>

            </g:each>
            </g:if>
        </g:each>
    </g:if>

    <g:if test="${project.documents  && ('Supporting documents' in content)}">
        <h3>Supporting documents</h3>
        <table class="table table-striped">
            <thead>
            <tr>
                <th>Name</th>
                <th>Type</th>
                <th>Stage</th>
            </tr>
            </thead>
            <tbody>
            <g:each in="${project.documents}" var="document">
                <tr>
                    <td>${document.name?:document.filename}</td>
                    <td><fc:documentType document="${document}"/></td>
                    <td>${document.stage ? "Stage "+document.stage : ''}</td>
                </tr>
            </g:each>

            </tbody>
        </table>
    </g:if>
    <g:render template="/shared/documentTemplate" plugin="fieldcapture-plugin"/>

</div>
<r:script>
    $(function() {

        var reports = <fc:modelAsJavascript model="${project.reports}"/>;
        var reportVM = new ProjectReportsViewModel({reports:reports});
        ko.applyBindings(reportVM, document.getElementById('report-status'));

        $(".risks-comparison td").prettyTextDiff({cleanup: true});

        var content = $('.outputs-without-targets');
        var columnized = content.find('.column').length > 0;
        if (!columnized){
            //content.columnize({ columns: 2, lastNeverTallest:true, accuracy: 10 });
        }

        // We need to reinitialise the popovers as the content has been moved by the columnizer.
        $('.helphover').data('popover', null);
        $('.helphover').popover({container:'body', animation: true, trigger:'hover'});
        });

</r:script>
</body>
</html>