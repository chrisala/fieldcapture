<%@ page contentType="text/html;charset=UTF-8" %>
<!DOCTYPE html>
<html>
<head>
    <meta name="layout" content="${hubConfig.skin}"/>
    <title>Edit | Blog Entry | Field Capture</title>
    <script type="text/javascript" src="${grailsApplication.config.google.maps.url}"></script>
    <r:script disposition="head">
        var fcConfig = {
            serverUrl: "${grailsApplication.config.grails.serverURL}",
            blogUpdateUrl: "${createLink(action:'update', id:blogEntry.blogEntryId)}",
            blogViewUrl: "${createLink(action:'index')}",
            documentUpdateUrl: "${createLink(controller:"document", action:"documentUpdate")}",
            returnTo: "${params.returnTo}"
            };
    </r:script>
    <r:require modules="knockout,jqueryValidationEngine,datepicker,jQueryFileUpload,amplify,wmd"/>

</head>
<body>
<div class="${containerType}">
    <ul class="breadcrumb">
        <li>
            <g:link controller="home">Home</g:link> <span class="divider">/</span>
        </li>
        <g:if test="${params.projectId}">
            <g:link controller="project" id="${params.projectId}">Project </g:link>  <span class="divider"> / </span></li>
        </g:if>
        <li class="active">Edit blog entry</li>
    </ul>

    <g:render template="editBlogEntry"/>

    <div class="form-actions">
        <button type="button" id="save" data-bind="click:save" class="btn btn-primary">Save</button>
        <button type="button" id="cancel" data-bind="click:cancel" class="btn">Cancel</button>
    </div>
</div>

<r:script>

    $(function () {
        var blogEntry = <fc:modelAsJavascript model="${blogEntry}" default="{}"/>;
        var blogEntryViewModel = new EditableBlogEntryViewModel(blogEntry, '.validationEngineContainer');

        ko.applyBindings(blogEntryViewModel);
        $('.helphover').popover({animation: true, trigger:'hover'});
    });


</r:script>

</body>


</html>